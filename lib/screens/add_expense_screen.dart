import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/expense_models.dart';
import '../services/expense_service.dart';

/// Screen for adding a new shared expense
class AddExpenseScreen extends StatefulWidget {
  final String tripId;
  final String currency;

  const AddExpenseScreen({
    super.key,
    required this.tripId,
    this.currency = 'USD',
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _service = ExpenseService();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _category = ExpenseCategory.food;
  String _splitMethod = 'Equal';
  int _selectedDay = 1;
  bool _isLoading = false;

  // Dynamic member selection
  List<TripMember> _members = [];
  Map<String, bool> _includedMembers = {};
  Map<String, double> _customSplits = {};
  String? _selectedPayerId;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    _service.membersStream(widget.tripId).first.then((members) {
      if (mounted) {
        setState(() {
          _members = members;
          _selectedPayerId = _members.isNotEmpty ? _members.first.id : null;
          _includedMembers = {for (final m in members) m.id: true};
          // Default: equal split among all members
          if (members.isNotEmpty) {
            final perPerson = double.parse(
                (100 / members.length).toStringAsFixed(2));
            _customSplits = {for (final m in members) m.id: perPerson};
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Build the splits map based on selected method
  Map<String, double> _buildSplits(double total) {
    final included = _includedMembers.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (included.isEmpty) return {};

    switch (_splitMethod) {
      case 'Equal':
        return ExpenseService.calculateEqualSplits(
          totalAmount: total,
          participantIds: included,
        );
      case 'Exact amounts':
        // Use customSplits as absolute values
        return Map.fromEntries(
          included.map((id) => MapEntry(id, _customSplits[id] ?? 0)),
        );
      case 'Percentage':
        // customSplits are percentages, convert to amounts
        return Map.fromEntries(
          included.map((id) {
            final pct = _customSplits[id] ?? 0;
            return MapEntry(id, total * pct / 100);
          }),
        );
      default:
        return ExpenseService.calculateEqualSplits(
          totalAmount: total,
          participantIds: included,
        );
    }
  }

  Future<void> _saveExpense() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    if (_descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }
    if (_selectedPayerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select who paid')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final splits = _buildSplits(amount);

      // Convert to base currency if needed
      double amountInBase = amount;
      // TODO: Use actual expense currency different from base
      amountInBase = amount;

      await _service.addExpense(
        tripId: widget.tripId,
        description: _descController.text,
        amount: amount,
        currency: widget.currency,
        amountInBase: amountInBase,
        category: _category,
        paidByMemberId: _selectedPayerId!,
        splits: splits,
        splitMethod: _splitMethod == 'Equal'
            ? SplitMethod.equal
            : _splitMethod == 'Exact amounts'
                ? SplitMethod.exact
                : _splitMethod == 'Percentage'
                    ? SplitMethod.percentage
                    : SplitMethod.equal,
        date: DateTime.now(),
        dayNumber: _selectedDay,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('Add Expense',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Who paid
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: 'What was this for?',
              hintText: 'e.g., Dinner at local restaurant',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.description, size: 18),
            ),
          ),
          const SizedBox(height: 12),

          // Amount
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount (${widget.currency})',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.attach_money, size: 18),
            ),
          ),
          const SizedBox(height: 16),

          // Category selection
          Text('Category',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExpenseCategory.all.map((c) {
              final isSelected = _category == c;
              return ChoiceChip(
                label: Text(c, style: GoogleFonts.inter(fontSize: 13)),
                selected: isSelected,
                selectedColor: const Color(0xFF6C63FF),
                labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF666666)),
                onSelected: (_) => setState(() => _category = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Who paid dropdown
          Text('Who paid?',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPayerId,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: _members
                .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
                .toList(),
            onChanged: (v) => setState(() => _selectedPayerId = v),
          ),
          const SizedBox(height: 16),

          // Split method
          Text('Split method',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Equal', label: Text('Equal')),
              ButtonSegment(value: 'Exact amounts', label: Text('Exact')),
              ButtonSegment(value: 'Percentage', label: Text('%')),
            ],
            selected: {_splitMethod == 'Exact amounts' ? 'Exact amounts' : _splitMethod == 'Percentage' ? 'Percentage' : 'Equal'},
            onSelectionChanged: (set) {
              setState(() => _splitMethod = set.first);
            },
          ),
          const SizedBox(height: 16),

          // Member inclusion (for equal splits)
          if (_splitMethod == 'Equal') ...[
            Text('Include in split',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._members.map(_buildMemberToggle),
            const SizedBox(height: 16),
          ],

          // Day number
          TextField(
            controller: TextEditingController(text: '$_selectedDay'),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Day of trip',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.calendar_today, size: 18),
            ),
            onChanged: (v) => _selectedDay = int.tryParse(v) ?? 1,
          ),
          const SizedBox(height: 12),

          // Optional note
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.note, size: 18),
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveExpense,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Expense',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberToggle(TripMember m) {
    final included = _includedMembers[m.id] ?? false;
    return CheckboxListTile(
      value: included,
      onChanged: (v) =>
          setState(() => _includedMembers[m.id] = v ?? false),
      title: Text(m.name, style: GoogleFonts.inter()),
      secondary: CircleAvatar(
        radius: 14,
        backgroundColor: m.avatarColor,
        child: Text(
          m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      ),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
