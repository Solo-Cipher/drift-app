import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/expense_service.dart';
import '../screens/expense_group_screen.dart';

/// Entry point for expense sharing — create a new group or join existing
class CreateOrJoinGroupScreen extends StatefulWidget {
  const CreateOrJoinGroupScreen({super.key});

  @override
  State<CreateOrJoinGroupScreen> createState() =>
      _CreateOrJoinGroupScreenState();
}

class _CreateOrJoinGroupScreenState extends State<CreateOrJoinGroupScreen> {
  final _service = ExpenseService();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _memberNameController = TextEditingController();
  String _currency = 'USD';
  bool _isLoading = false;
  bool _isCreating = true; // true = create, false = join

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _memberNameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (_nameController.text.isEmpty || _memberNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tripId = await _service.createGroup(
        name: _nameController.text,
        currency: _currency,
        creatorName: _memberNameController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ExpenseGroupScreen(
              tripId: tripId,
              tripName: _nameController.text,
              currency: _currency,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating group: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinGroup() async {
    if (_codeController.text.isEmpty || _memberNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the group code and your name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tripId = await _service.joinGroup(
        tripCode: _codeController.text.trim(),
        memberName: _memberNameController.text,
      );

      if (tripId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group not found. Check the code.')),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ExpenseGroupScreen(
              tripId: tripId,
              tripName: 'Trip Group',
              currency: _currency,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining group: $e')),
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
        title: Text('Expense Sharing',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header
          const Icon(Icons.groups, size: 48, color: Color(0xFF6C63FF)),
          const SizedBox(height: 16),
          Text(
            'Share trip expenses',
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Create a group or join friends to track shared expenses',
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF888888)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Toggle: Create or Join
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isCreating = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isCreating ? const Color(0xFF6C63FF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Create Group',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: _isCreating ? Colors.white : const Color(0xFF666666),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isCreating = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isCreating ? const Color(0xFF6C63FF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Join Group',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: !_isCreating ? Colors.white : const Color(0xFF666666),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Your name (always shown)
          TextField(
            controller: _memberNameController,
            decoration: InputDecoration(
              labelText: 'Your name',
              hintText: 'e.g., Solo',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.person, size: 18),
            ),
          ),
          const SizedBox(height: 16),

          // Conditional fields
          if (_isCreating) ...[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Trip name',
                hintText: 'e.g., Vietnam 2026',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.card_travel, size: 18),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _currency,
              decoration: InputDecoration(
                labelText: 'Currency',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.attach_money, size: 18),
              ),
              items: ['USD', 'EUR', 'GBP', 'OMR', 'VND', 'LKR', 'IDR', 'THB', 'JPY', 'TRY', 'MAD', 'MUR']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _currency = v ?? 'USD'),
            ),
          ] else ...[
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Group code',
                hintText: 'e.g., DRIFT-A7X9K2',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.tag, size: 18),
              ),
            ),
          ],
          const SizedBox(height: 32),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : (_isCreating ? _createGroup : _joinGroup),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _isCreating ? 'Create Group' : 'Join Group',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
