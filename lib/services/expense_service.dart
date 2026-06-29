import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_models.dart';

/// Result of debt simplification: who should pay whom
class BalanceResult {
  /// Net balance per member (positive = owed, negative = owes)
  final Map<String, double> netBalances;
  /// Simplified settlement suggestions
  final List<SettlementSuggestion> suggestions;

  BalanceResult(this.netBalances, this.suggestions);
}

/// Core service for expense group operations
class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current user's anonymous UID, creating one if needed
  Future<String> get currentUserId async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
    return _auth.currentUser!.uid;
  }

  /// Generate a human-friendly trip code from a UUID
  static String generateTripCode() {
    final random = math.Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no confusing chars
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  // ─── Trip Group CRUD ──────────────────────────────────────

  /// Create a new expense group
  Future<String> createGroup({
    required String name,
    required String currency,
    required String creatorName,
  }) async {
    final userId = await currentUserId;
    final tripId = _firestore.collection('trips').doc().id;
    final tripCode = generateTripCode();

    final member = TripMember(
      id: userId,
      name: creatorName,
    );

    await _firestore.collection('trips').doc(tripId).set({
      'id': tripId,
      'code': tripCode,
      'name': name,
      'currency': currency,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': userId,
      'memberUids': [userId],
    });

    // Add creator as first member
    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('members')
        .doc(userId)
        .set(member.toMap());

    return tripId;
  }

  /// Join an existing group by trip code
  Future<String?> joinGroup({
    required String tripCode,
    required String memberName,
  }) async {
    final userId = await currentUserId;

    // Find trip by code
    final query = await _firestore
        .collection('trips')
        .where('code', isEqualTo: tripCode.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final tripDoc = query.docs.first;
    final tripId = tripDoc.id;

    // Add member
    final member = TripMember(id: userId, name: memberName);
    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('members')
        .doc(userId)
        .set(member.toMap());

    // Add to memberUids array
    await tripDoc.reference.update({
      'memberUids': FieldValue.arrayUnion([userId]),
    });

    return tripId;
  }

  /// Get trip group document stream
  Stream<DocumentSnapshot> tripStream(String tripId) =>
      _firestore.collection('trips').doc(tripId).snapshots();

  /// Get all members of a trip
  Stream<List<TripMember>> membersStream(String tripId) =>
      _firestore
          .collection('trips')
          .doc(tripId)
          .collection('members')
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => TripMember.fromMap(d.data()))
              .toList());

  /// Get all expenses for a trip, ordered by date
  Stream<List<SharedExpense>> expensesStream(String tripId) =>
      _firestore
          .collection('trips')
          .doc(tripId)
          .collection('expenses')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => SharedExpense.fromMap(d.data()))
              .toList());

  /// Get all settlements for a trip
  Stream<List<Settlement>> settlementsStream(String tripId) =>
      _firestore
          .collection('trips')
          .doc(tripId)
          .collection('settlements')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => Settlement.fromMap(d.data()))
              .toList());

  // ─── Expense CRUD ────────────────────────────────────────

  /// Add a new expense to the group
  Future<void> addExpense({
    required String tripId,
    required String description,
    required double amount,
    required String currency,
    required double amountInBase,
    required String category,
    required String paidByMemberId,
    required Map<String, double> splits,
    required SplitMethod splitMethod,
    required DateTime date,
    int dayNumber = 1,
    String? note,
  }) async {
    final userId = await currentUserId;
    final expenseId = _firestore
        .collection('trips')
        .doc(tripId)
        .collection('expenses')
        .doc()
        .id;

    final expense = SharedExpense(
      id: expenseId,
      description: description,
      amount: amount,
      currency: currency,
      amountInBase: amountInBase,
      category: category,
      paidByMemberId: paidByMemberId,
      splits: splits,
      splitMethod: splitMethod,
      date: date,
      dayNumber: dayNumber,
      note: note,
      createdByMemberId: userId,
    );

    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('expenses')
        .doc(expenseId)
        .set(expense.toMap());
  }

  /// Delete an expense
  Future<void> deleteExpense(String tripId, String expenseId) async {
    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }

  // ─── Settlements ─────────────────────────────────────────

  /// Record a settlement (payment between members)
  Future<void> recordSettlement({
    required String tripId,
    required String fromMemberId,
    required String toMemberId,
    required double amount,
    required String currency,
    String? note,
  }) async {
    final settlementId = _firestore
        .collection('trips')
        .doc(tripId)
        .collection('settlements')
        .doc()
        .id;

    final settlement = Settlement(
      id: settlementId,
      fromMemberId: fromMemberId,
      toMemberId: toMemberId,
      amount: amount,
      currency: currency,
      date: DateTime.now(),
      note: note,
    );

    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('settlements')
        .doc(settlementId)
        .set(settlement.toMap());
  }

  // ─── Balance Calculation ─────────────────────────────────

  /// Calculate net balances and simplified settlements
  static BalanceResult calculateBalances({
    required List<TripMember> members,
    required List<SharedExpense> expenses,
    required List<Settlement> settlements,
  }) {
    // Start with zero for everyone
    final balances = <String, double>{};
    for (final m in members) {
      balances[m.id] = 0.0;
    }

    // Process each expense
    for (final expense in expenses) {
      // Payer gets credited the full amount (in base currency)
      balances[expense.paidByMemberId] =
          (balances[expense.paidByMemberId] ?? 0) + expense.amountInBase;

      // Each person's share is debited
      for (final entry in expense.splits.entries) {
        balances[entry.key] = (balances[entry.key] ?? 0) - entry.value;
      }
    }

    // Process settlements (recorded payments)
    for (final settlement in settlements) {
      // The payer already "paid" via expenses, so we reverse:
      // fromMemberId paid toMemberId, so fromMemberId's balance decreases
      // and toMemberId's balance increases
      balances[settlement.fromMemberId] =
          (balances[settlement.fromMemberId] ?? 0) - settlement.amount;
      balances[settlement.toMemberId] =
          (balances[settlement.toMemberId] ?? 0) + settlement.amount;
    }

    // Simplify debts
    final suggestions = _simplifyDebts(balances);

    return BalanceResult(balances, suggestions);
  }

  /// Greedy debt simplification algorithm
  /// 
  /// Algorithm:
  /// 1. Separate people into debtors (owe money) and creditors (owed money)
  /// 2. Sort both lists by absolute amount (biggest first)
  /// 3. Match biggest debtor with biggest creditor
  /// 4. Settle the minimum of the two amounts
  /// 5. Repeat until all balances are zero
  /// 
  /// Properties:
  /// - At most N-1 transactions for N people
  /// - O(n log n) time complexity
  /// - Produces intuitive results
  static List<SettlementSuggestion> _simplifyDebts(
    Map<String, double> netBalances,
  ) {
    final debtors = <_Balance>[]; // people who owe (negative balance)
    final creditors = <_Balance>[]; // people who are owed (positive balance)

    for (final entry in netBalances.entries) {
      if (entry.value < -0.01) {
        debtors.add(_Balance(entry.key, -entry.value)); // store as positive
      } else if (entry.value > 0.01) {
        creditors.add(_Balance(entry.key, entry.value));
      }
    }

    // Sort: biggest amounts first
    debtors.sort((a, b) => b.amount.compareTo(a.amount));
    creditors.sort((a, b) => b.amount.compareTo(a.amount));

    final suggestions = <SettlementSuggestion>[];
    var i = 0, j = 0;

    while (i < debtors.length && j < creditors.length) {
      final amount = math.min(debtors[i].amount, creditors[j].amount);

      if (amount > 0.01) {
        suggestions.add(SettlementSuggestion(
          fromMemberId: debtors[i].memberId,
          toMemberId: creditors[j].memberId,
          amount: double.parse(amount.toStringAsFixed(2)),
        ));
      }

      debtors[i] = _Balance(debtors[i].memberId, debtors[i].amount - amount);
      creditors[j] = _Balance(creditors[j].memberId, creditors[j].amount - amount);

      if (debtors[i].amount < 0.01) i++;
      if (creditors[j].amount < 0.01) j++;
    }

    return suggestions;
  }

  /// Calculate equal splits for a list of members
  static Map<String, double> calculateEqualSplits({
    required double totalAmount,
    required List<String> participantIds,
  }) {
    if (participantIds.isEmpty) return {};
    final share = double.parse(
      (totalAmount / participantIds.length).toStringAsFixed(2),
    );
    return {for (final id in participantIds) id: share};
  }
}

/// Internal helper for the simplification algorithm
class _Balance {
  final String memberId;
  final double amount;
  _Balance(this.memberId, this.amount);
}
