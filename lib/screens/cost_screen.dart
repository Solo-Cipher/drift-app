import 'package:flutter/material.dart';
import '../models/trip_data.dart';

class Expense {
  final String category;
  final String description;
  final double amount;
  final int day;
  final DateTime timestamp;

  Expense({required this.category, required this.description, required this.amount, required this.day, DateTime? timestamp}) : timestamp = timestamp ?? DateTime.now();
}

class CostScreen extends StatefulWidget {
  final TripData trip;
  const CostScreen({super.key, required this.trip});

  @override
  State<CostScreen> createState() => _CostScreenState();
}

class _CostScreenState extends State<CostScreen> {
  final List<Expense> _expenses = [];
  int _selectedTab = 0; // 0 = budget, 1 = expenses

  double get _totalBudget {
    double totalTransport = 0, totalAccommodation = 0, totalFood = 0;
    for (final day in widget.trip.days) {
      if (day.transportCost != null) totalTransport += double.tryParse(day.transportCost!.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      if (day.accommodationCost != null) totalAccommodation += double.tryParse(day.accommodationCost!.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      if (day.foodCost != null) totalFood += double.tryParse(day.foodCost!.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
    }
    return totalTransport + totalAccommodation + totalFood;
  }

  double get _totalSpent => _expenses.fold(0, (sum, e) => sum + e.amount);
  double get _remaining => _totalBudget - _totalSpent;
  double get _perPersonSpent => _totalSpent / 2;

  void _addExpense() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddExpenseSheet(
        trip: widget.trip,
        onAdd: (expense) => setState(() => _expenses.add(expense)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Budget & Expenses', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white, elevation: 0, scrolledUnderElevation: 0, surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              _buildTab('Budget', 0),
              _buildTab('Expenses', 1),
            ],
          ),
        ),
      ),
      body: _selectedTab == 0 ? _buildBudgetView() : _buildExpensesView(),
      floatingActionButton: _selectedTab == 1
          ? FloatingActionButton.extended(
              onPressed: _addExpense,
              icon: const Icon(Icons.add),
              label: const Text('Log Expense'),
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent, width: 2)),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400, color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF999999))),
        ),
      ),
    );
  }

  Widget _buildBudgetView() {
    double totalTransport = 0, totalAccommodation = 0, totalFood = 0;
    for (final day in widget.trip.days) {
      if (day.transportCost != null) totalTransport += double.tryParse(day.transportCost!.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      if (day.accommodationCost != null) totalAccommodation += double.tryParse(day.accommodationCost!.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      if (day.foodCost != null) totalFood += double.tryParse(day.foodCost!.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
    }
    final total = totalTransport + totalAccommodation + totalFood;
    final perPerson = total / 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF6C63FF), Color(0xFF4A42D0)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Budget', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                const SizedBox(height: 8),
                Text('${total.toStringAsFixed(0)} ${widget.trip.currency}', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('for ${widget.trip.totalDays} days · 2 travelers', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: Text('~${perPerson.toStringAsFixed(0)} ${widget.trip.currency}/person', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    if (_totalSpent > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: Text('${_totalSpent.toStringAsFixed(0)} spent', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Spending progress
          if (_totalSpent > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEEEEE))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Spending Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_totalSpent / total).clamp(0, 1),
                      backgroundColor: const Color(0xFFF0F0F0),
                      valueColor: AlwaysStoppedAnimation<Color>(_totalSpent > total ? const Color(0xFFFF6B6B) : const Color(0xFF6C63FF)),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_totalSpent.toStringAsFixed(0)} ${widget.trip.currency} spent', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6C63FF))),
                      Text('${_remaining.toStringAsFixed(0)} ${widget.trip.currency} ${_remaining >= 0 ? 'remaining' : 'over budget'}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _remaining >= 0 ? const Color(0xFF00BFA6) : const Color(0xFFFF6B6B))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          const Text('Cost by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 16),
          _buildCategoryCard(icon: Icons.flight, label: 'Transportation', amount: totalTransport, total: total, color: const Color(0xFF6C63FF), subtext: 'Flights, buses, boats, taxis'),
          const SizedBox(height: 12),
          _buildCategoryCard(icon: Icons.hotel, label: 'Accommodation', amount: totalAccommodation, total: total, color: const Color(0xFF00BFA6), subtext: 'Hotels, hostels, cruise'),
          const SizedBox(height: 12),
          _buildCategoryCard(icon: Icons.restaurant, label: 'Food & Drinks', amount: totalFood, total: total, color: const Color(0xFFFF6B6B), subtext: 'Street food, restaurants, coffee'),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Daily Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 16),
          ...widget.trip.days.map((day) {
            final dayTotal = day.totalCost;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEEEEEE))),
              child: Row(
                children: [
                  Container(width: 32, height: 32, decoration: BoxDecoration(color: day.color.withOpacity(0.1), shape: BoxShape.circle), child: Center(child: Text('${day.day}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: day.color)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(day.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))), Text(day.location, style: const TextStyle(fontSize: 11, color: Color(0xFF999999)))])),
                  Text(dayTotal > 0 ? '${dayTotal.toStringAsFixed(0)} ${widget.trip.currency}' : '—', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: dayTotal > 0 ? const Color(0xFF6C63FF) : const Color(0xFFCCCCCC))),
                ],
              ),
            );
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildExpensesView() {
    if (_expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No expenses logged yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF999999))),
            const SizedBox(height: 8),
            const Text('Tap the + button to log your first expense', style: TextStyle(fontSize: 13, color: Color(0xFFBBBBBB))),
          ],
        ),
      );
    }

    final grouped = <int, List<Expense>>{};
    for (final e in _expenses) {
      grouped.putIfAbsent(e.day, () => []).add(e);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final day = grouped.keys.elementAt(index);
        final dayExpenses = grouped[day]!;
        final dayTotal = dayExpenses.fold(0.0, (sum, e) => sum + e.amount);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEEEEE))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.1), shape: BoxShape.circle),
                      child: Center(child: Text('$day', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6C63FF)))),
                    ),
                    const SizedBox(width: 12),
                    Text('Day $day', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('${dayTotal.toStringAsFixed(1)} ${widget.trip.currency}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF6C63FF))),
                  ],
                ),
              ),
              ...dayExpenses.map((e) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Icon(_getCategoryIcon(e.category), size: 16, color: const Color(0xFF999999)),
                    const SizedBox(width: 8),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food': return Icons.restaurant;
      case 'Transport': return Icons.directions_car;
      case 'Accommodation': return Icons.hotel;
      case 'Activity': return Icons.local_activity;
      case 'Shopping': return Icons.shopping_bag;
      default: return Icons.attach_money;
    }
  }

  Widget _buildCategoryCard({required IconData icon, required String label, required double amount, required double total, required Color color, required String subtext}) {
    final percentage = total > 0 ? (amount / total * 100) : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEEEEE))),
      child: Column(
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20, color: color)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))), Text(subtext, style: const TextStyle(fontSize: 11, color: Color(0xFF999999)))])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${amount.toStringAsFixed(0)} ${widget.trip.currency}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
                Text('${percentage.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: percentage / 100, backgroundColor: const Color(0xFFF0F0F0), valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 6)),
        ],
      ),
    );
  }
}

class _AddExpenseSheet extends StatefulWidget {
  final TripData trip;
  final ValueChanged<Expense> onAdd;
  const _AddExpenseSheet({required this.trip, required this.onAdd});

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  String _category = 'Food';
  int _selectedDay = 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Log Expense', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF666666))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Food', 'Transport', 'Accommodation', 'Activity', 'Shopping', 'Other'].map((c) {
                final isSelected = _category == c;
                return ChoiceChip(
                  label: Text(c, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : const Color(0xFF666666))),
                  selected: isSelected,
                  selectedColor: const Color(0xFF6C63FF),
                  onSelected: (s) => setState(() => _category = c),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.description, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (${widget.trip.currency})',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.attach_money, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Day', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF666666))),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedDay,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              items: List.generate(widget.trip.totalDays, (i) => i + 1).map((d) => DropdownMenuItem(value: d, child: Text('Day $d'))).toList(),
              onChanged: (v) => setState(() => _selectedDay = v ?? 1),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(_amountController.text);
                  if (amount != null && _descController.text.isNotEmpty) {
                    widget.onAdd(Expense(category: _category, description: _descController.text, amount: amount, day: _selectedDay));
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Add Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
