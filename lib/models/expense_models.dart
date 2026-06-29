import 'package:flutter/material.dart';

/// How an expense is split among members
enum SplitMethod { equal, exact, percentage, shares }

/// Categories for expenses — matches DRIFT's visual language
class ExpenseCategory {
  static const String food = 'Food & Drinks';
  static const String transport = 'Transport';
  static const String accommodation = 'Accommodation';
  static const String activity = 'Activities';
  static const String shopping = 'Shopping';
  static const String other = 'Other';

  static const List<String> all = [
    food, transport, accommodation, activity, shopping, other,
  ];

  static String iconName(String category) {
    switch (category) {
      case food: return 'restaurant';
      case transport: return 'directions_car';
      case accommodation: return 'hotel';
      case activity: return 'local_activity';
      case shopping: return 'shopping_bag';
      default: return 'attach_money';
    }
  }
}

/// A member of a shared expense group
class TripMember {
  final String id;
  final String name;
  final String? email;
  final DateTime joinedAt;
  final Color avatarColor;

  TripMember({
    required this.id,
    required this.name,
    this.email,
    DateTime? joinedAt,
    Color? avatarColor,
  }) : joinedAt = joinedAt ?? DateTime.now(),
        avatarColor = avatarColor ?? const Color(0xFF6C63FF);

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    if (email != null) 'email': email,
    'joinedAt': joinedAt.toIso8601String(),
    'avatarColor': avatarColor.value,
  };

  factory TripMember.fromMap(Map<String, dynamic> map) => TripMember(
    id: map['id'] as String,
    name: map['name'] as String,
    email: map['email'] as String?,
    joinedAt: DateTime.parse(map['joinedAt'] as String),
    avatarColor: Color(map['avatarColor'] as int? ?? 0xFF6C63FF),
  );
}

/// A shared expense within a trip group
class SharedExpense {
  final String id;
  final String description;
  final double amount;
  final String currency;
  final double amountInBase;
  final String category;
  final String paidByMemberId;
  final Map<String, double> splits; // memberId -> amount they owe
  final SplitMethod splitMethod;
  final DateTime date;
  final int dayNumber;
  final String? note;
  final DateTime createdAt;
  final String createdByMemberId;

  SharedExpense({
    required this.id,
    required this.description,
    required this.amount,
    required this.currency,
    required this.amountInBase,
    required this.category,
    required this.paidByMemberId,
    required this.splits,
    this.splitMethod = SplitMethod.equal,
    required this.date,
    this.dayNumber = 1,
    this.note,
    DateTime? createdAt,
    required this.createdByMemberId,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'description': description,
    'amount': amount,
    'currency': currency,
    'amountInBase': amountInBase,
    'category': category,
    'paidByMemberId': paidByMemberId,
    'splits': splits,
    'splitMethod': splitMethod.name,
    'date': date.toIso8601String(),
    'dayNumber': dayNumber,
    if (note != null) 'note': note,
    'createdAt': createdAt.toIso8601String(),
    'createdByMemberId': createdByMemberId,
  };

  factory SharedExpense.fromMap(Map<String, dynamic> map) => SharedExpense(
    id: map['id'] as String,
    description: map['description'] as String,
    amount: (map['amount'] as num).toDouble(),
    currency: map['currency'] as String,
    amountInBase: (map['amountInBase'] as num).toDouble(),
    category: map['category'] as String,
    paidByMemberId: map['paidByMemberId'] as String,
    splits: Map<String, double>.from(
      (map['splits'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
    ),
    splitMethod: SplitMethod.values.firstWhere(
      (m) => m.name == map['splitMethod'],
      orElse: () => SplitMethod.equal,
    ),
    date: DateTime.parse(map['date']),
    dayNumber: map['dayNumber'] as int? ?? 1,
    note: map['note'] as String?,
    createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    createdByMemberId: map['createdByMemberId'] as String,
  );
}

/// A recorded settlement (payment between members)
class Settlement {
  final String id;
  final String fromMemberId;
  final String toMemberId;
  final double amount;
  final String currency;
  final DateTime date;
  final String? note;

  Settlement({
    required this.id,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
    required this.currency,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'fromMemberId': fromMemberId,
    'toMemberId': toMemberId,
    'amount': amount,
    'currency': currency,
    'date': date.toIso8601String(),
    if (note != null) 'note': note,
  };

  factory Settlement.fromMap(Map<String, dynamic> map) => Settlement(
    id: map['id'] as String,
    fromMemberId: map['fromMemberId'] as String,
    toMemberId: map['toMemberId'] as String,
    amount: (map['amount'] as num).toDouble(),
    currency: map['currency'] as String,
    date: DateTime.parse(map['date']),
    note: map['note'] as String?,
  );
}

/// Simplified debt suggestion from the algorithm
class SettlementSuggestion {
  final String fromMemberId;
  final String toMemberId;
  final double amount;

  SettlementSuggestion({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
  });

  String get amountStr => amount.toStringAsFixed(2);
}
