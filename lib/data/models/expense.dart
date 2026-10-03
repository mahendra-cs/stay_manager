import 'package:flutter/foundation.dart';

import '../../core/utils/map_utils.dart';
import 'payment_mode.dart';

/// An operating expense. [category] is a configurable label, not an enum.
@immutable
class Expense {
  const Expense({
    required this.id,
    required this.propertyId,
    required this.date,
    required this.amount,
    required this.category,
    this.paymentMode = PaymentMode.cash,
    this.description = '',
    this.createdAt,
    this.createdBy = '',
    this.updatedAt,
    this.updatedBy = '',
  });

  final String id;
  final String propertyId;
  final DateTime date;
  final double amount;
  final String category;
  final PaymentMode paymentMode;
  final String description;
  final DateTime? createdAt;
  final String createdBy;
  final DateTime? updatedAt;
  final String updatedBy;

  Expense copyWith({
    String? id,
    String? propertyId,
    DateTime? date,
    double? amount,
    String? category,
    PaymentMode? paymentMode,
    String? description,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return Expense(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMode: paymentMode ?? this.paymentMode,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  factory Expense.fromMap(String id, Map<String, dynamic> map) {
    return Expense(
      id: id,
      propertyId: MapUtils.asString(map['propertyId']),
      date: MapUtils.asDateTime(map['date']) ?? DateTime.now(),
      amount: MapUtils.asDouble(map['amount']),
      category: MapUtils.asString(map['category']),
      paymentMode: PaymentMode.fromWire(map['paymentMode']),
      description: MapUtils.asString(map['description']),
      createdAt: MapUtils.asDateTime(map['createdAt']),
      createdBy: MapUtils.asString(map['createdBy']),
      updatedAt: MapUtils.asDateTime(map['updatedAt']),
      updatedBy: MapUtils.asString(map['updatedBy']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'propertyId': propertyId,
      'date': date,
      'amount': amount,
      'category': category,
      'paymentMode': paymentMode.wireValue,
      'description': description,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
    };
  }

  @override
  bool operator ==(Object other) => other is Expense && other.id == id;

  @override
  int get hashCode => id.hashCode;
}