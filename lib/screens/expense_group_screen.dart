import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/expense_models.dart';
import '../services/expense_service.dart';
import '../screens/add_expense_screen.dart';

/// Main expense group dashboard — shows balances, activity, and settlements
class ExpenseGroupScreen extends StatefulWidget {
  final String tripId;
  final String tripName;
  final String currency;

  const ExpenseGroupScreen({
    super.key,
    required this.tripId,
    required this.tripName,
    this.currency = 'USD',
  });

  @override
  State<ExpenseGroupScreen> createState() => _ExpenseGroupScreenState();
}

class _ExpenseGroupScreenState extends State<ExpenseGroupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = ExpenseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tripName,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            Text('Expense Sharing',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF999999))),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            tooltip: 'Copy group code',
            onPressed: () async {
              // TODO: Get trip code from trip document
              // For now placeholder
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Group code copied!')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6C63FF),
          unselectedLabelColor: const Color(0xFF999999),
          indicatorColor: const Color(0xFF6C63FF),
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Balances'),
            Tab(text: 'Activity'),
            Tab(text: 'Members'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBalancesTab(),
          _buildActivityTab(),
          _buildMembersTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddExpenseScreen(
              tripId: widget.tripId,
              currency: widget.currency,
            ),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
    );
  }

  // ─── BALANCES TAB ─────────────────────────────────────────

  Widget _buildBalancesTab() {
    return StreamBuilder<List<TripMember>>(
      stream: _service.membersStream(widget.tripId),
      builder: (context, membersSnap) {
        if (!membersSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final members = membersSnap.data!;

        return StreamBuilder<List<SharedExpense>>(
          stream: _service.expensesStream(widget.tripId),
          builder: (context, expensesSnap) {
            if (!expensesSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final expenses = expensesSnap.data!;

            return StreamBuilder<List<Settlement>>(
              stream: _service.settlementsStream(widget.tripId),
              builder: (context, settlementsSnap) {
                final settlements = settlementsSnap.data ?? [];

                final result = ExpenseService.calculateBalances(
                  members: members,
                  expenses: expenses,
                  settlements: settlements,
                );

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Total spending card
                    _buildTotalSpendingCard(expenses),
                    const SizedBox(height: 16),

                    // Simplified settlements
                    if (result.suggestions.isNotEmpty) ...[
                      Text('Settle Up',
                          style: GoogleFonts.inter(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      ...result.suggestions.map((s) => _buildSettlementCard(
                          s, members)),
                      const SizedBox(height: 16),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BFA6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.check_circle,
                                color: Color(0xFF00BFA6), size: 32),
                            SizedBox(height: 8),
                            Text('All settled up!',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Per-member balances
                    Text('Individual Balances',
                        style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...members.map((m) {
                      final balance = result.netBalances[m.id] ?? 0;
                      return _buildMemberBalanceCard(m, balance);
                    }),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ─── ACTIVITY TAB ─────────────────────────────────────────

  Widget _buildActivityTab() {
    return StreamBuilder<List<SharedExpense>>(
      stream: _service.expensesStream(widget.tripId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final expenses = snapshot.data!;

        if (expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('No expenses yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Tap + to log the first expense',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400])),
              ],
            ),
          );
        }

        return StreamBuilder<List<TripMember>>(
          stream: _service.membersStream(widget.tripId),
          builder: (context, membersSnap) {
            final members = membersSnap.data ?? [];
            final memberMap = {for (final m in members) m.id: m.name};

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: expenses.length,
              itemBuilder: (_, i) {
                final e = expenses[i];
                final payerName = memberMap[e.paidByMemberId] ?? 'Unknown';
                return _buildExpenseCard(e, payerName);
              },
            );
          },
        );
      },
    );
  }

  // ─── MEMBERS TAB ──────────────────────────────────────────

  Widget _buildMembersTab() {
    return StreamBuilder<List<TripMember>>(
      stream: _service.membersStream(widget.tripId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final members = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('${members.length} members',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...members.map((m) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: m.avatarColor,
                    child: Text(
                      m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  title: Text(m.name,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      'Joined ${_formatDate(m.joinedAt)}',
                      style: const TextStyle(fontSize: 12)),
                )),
          ],
        );
      },
    );
  }

  // ─── HELPER WIDGETS ───────────────────────────────────────

  Widget _buildTotalSpendingCard(List<SharedExpense> expenses) {
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amountInBase);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF4A42D0)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Spent',
              style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.8), fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            '${total.toStringAsFixed(2)} ${widget.currency}',
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${expenses.length} expenses',
            style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.7), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementCard(SettlementSuggestion s, List<TripMember> members) {
    final fromName = members.firstWhere((m) => m.id == s.fromMemberId,
        orElse: () => TripMember(id: '', name: 'Unknown')).name;
    final toName = members.firstWhere((m) => m.id == s.toMemberId,
        orElse: () => TripMember(id: '', name: 'Unknown')).name;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFFF6B6B).withOpacity(0.1),
              child: const Icon(Icons.arrow_forward,
                  size: 16, color: Color(0xFFFF6B6B))),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(color: const Color(0xFF1A1A2E)),
                children: [
                  TextSpan(
                      text: fromName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const TextSpan(text: ' pays '),
                  TextSpan(
                      text: toName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          Text(
            '${s.amountStr} ${widget.currency}',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w800, color: const Color(0xFF6C63FF)),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberBalanceCard(TripMember member, double balance) {
    final isPositive = balance >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: member.avatarColor,
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(member.name,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          Text(
            isPositive
                ? '+${balance.toStringAsFixed(2)}'
                : balance.toStringAsFixed(2),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              color: isPositive ? const Color(0xFF00BFA6) : const Color(0xFFFF6B6B),
            ),
          ),
          Text(' ${widget.currency}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(SharedExpense e, String payerName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
            child: const Icon(Icons.receipt, size: 16, color: Color(0xFF6C63FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.description,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text('Paid by $payerName • ${e.category}',
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF999999))),
              ],
            ),
          ),
          Text(
            '${e.amount.toStringAsFixed(2)} ${e.currency}',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
