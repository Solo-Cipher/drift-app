import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/expense_models.dart';
import '../services/expense_service.dart';

/// Screen for recording settlements between members
class SettleUpScreen extends StatefulWidget {
  final String tripId;
  final String currency;
  final List<TripMember> members;
  final List<SettlementSuggestion> suggestions;

  const SettleUpScreen({
    super.key,
    required this.tripId,
    required this.currency,
    required this.members,
    required this.suggestions,
  });

  @override
  State<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends State<SettleUpScreen> {
  final _service = ExpenseService();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _fromMemberId;
  String? _toMemberId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from first suggestion if available
    if (widget.suggestions.isNotEmpty) {
      _fromMemberId = widget.suggestions.first.fromMemberId;
      _toMemberId = widget.suggestions.first.toMemberId;
      _amountController.text = widget.suggestions.first.amountStr;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _memberName(String id) {
    return widget.members
        .firstWhere((m) => m.id == id, orElse: () => TripMember(id: '', name: 'Unknown'))
        .name;
  }

  Future<void> _recordSettlement() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    if (_fromMemberId == null || _toMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select who paid whom')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _service.recordSettlement(
        tripId: widget.tripId,
        fromMemberId: _fromMemberId!,
        toMemberId: _toMemberId!,
        amount: amount,
        currency: widget.currency,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settlement recorded!')),
        );
        Navigator.pop(context);
      }
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
        title: Text('Settle Up',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Suggestion chips
          if (widget.suggestions.isNotEmpty) ...[
            Text('Suggested settlements',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...widget.suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() {
                      _fromMemberId = s.fromMemberId;
                      _toMemberId = s.toMemberId;
                      _amountController.text = s.amountStr;
                    }),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF6C63FF)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${_memberName(s.fromMemberId)} → ${_memberName(s.toMemberId)}',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Text(
                            '${s.amountStr} ${widget.currency}',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF6C63FF)),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 24),
          ],

          // From
          Text('Who paid?',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _fromMemberId,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: widget.members
                .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
                .toList(),
            onChanged: (v) => setState(() => _fromMemberId = v),
          ),
          const SizedBox(height: 16),

          // To
          Text('Who received?',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _toMemberId,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: widget.members
                .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
                .toList(),
            onChanged: (v) => setState(() => _toMemberId = v),
          ),
          const SizedBox(height: 16),

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

          // Note
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'e.g., Venmo transfer',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.note, size: 18),
            ),
          ),
          const SizedBox(height: 32),

          // Record button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _recordSettlement,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Record Settlement',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
