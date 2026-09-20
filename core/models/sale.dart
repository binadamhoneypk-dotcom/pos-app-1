/// One completed bill. Line items live in [SaleItem] rows referencing
/// this sale's `uuid`.
class Sale {
  final String uuid;
  final String businessUuid;
  final String? customerUuid; // null = walk-in customer
  final double subtotal;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount; // totalAmount - paidAmount, kept for fast reads
  final int createdAt;
  final int lastUpdated;
  final bool isDeleted;
  final bool isSynced;

  Sale({
    required this.uuid,
    required this.businessUuid,
    this.customerUuid,
    required this.subtotal,
    required this.totalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.createdAt,
    required this.lastUpdated,
    this.isDeleted = false,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() => {
        'uuid': uuid,
        'business_uuid': businessUuid,
        'customer_uuid': customerUuid,
        'subtotal': subtotal,
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'due_amount': dueAmount,
        'created_at': createdAt,
        'last_updated': lastUpdated,
        'is_deleted': isDeleted ? 1 : 0,
        'is_synced': isSynced ? 1 : 0,
      };

  factory Sale.fromMap(Map<String, dynamic> map) => Sale(
        uuid: map['uuid'] as String,
        businessUuid: map['business_uuid'] as String,
        customerUuid: map['customer_uuid'] as String?,
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
        totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
        paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
        dueAmount: (map['due_amount'] as num?)?.toDouble() ?? 0,
        createdAt: map['created_at'] as int,
        lastUpdated: map['last_updated'] as int,
        isDeleted: (map['is_deleted'] as int) == 1,
        isSynced: (map['is_synced'] as int) == 1,
      );
}
