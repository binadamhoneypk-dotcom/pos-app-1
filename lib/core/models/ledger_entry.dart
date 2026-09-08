/// One balance-changing event for a `customers` row (customer OR
/// supplier — see [Customer.type]). This is what the Phase 3 "statement"
/// screen lists date-wise; `customers.current_balance` alone can only
/// ever show the running total, never how it was reached.
class LedgerEntry {
  static const typeSale = 'sale'; // bill given on credit (from Billing)
  static const typePaymentReceived = 'payment_received'; // customer paid us
  static const typePaymentMade = 'payment_made'; // we paid a supplier
  static const typeAdjustment = 'adjustment'; // manual correction
  static const typeOpeningBalance = 'opening_balance';

  final String uuid;
  final String businessUuid;
  final String contactUuid; // customers.uuid
  final String type;
  final double amount; // signed — same convention as Customer.currentBalance
  final String? note;
  final String? relatedSaleUuid;
  final int createdAt;
  final int lastUpdated;
  final bool isDeleted;
  final bool isSynced;

  LedgerEntry({
    required this.uuid,
    required this.businessUuid,
    required this.contactUuid,
    required this.type,
    required this.amount,
    this.note,
    this.relatedSaleUuid,
    required this.createdAt,
    required this.lastUpdated,
    this.isDeleted = false,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() => {
        'uuid': uuid,
        'business_uuid': businessUuid,
        'contact_uuid': contactUuid,
        'type': type,
        'amount': amount,
        'note': note,
        'related_sale_uuid': relatedSaleUuid,
        'created_at': createdAt,
        'last_updated': lastUpdated,
        'is_deleted': isDeleted ? 1 : 0,
        'is_synced': isSynced ? 1 : 0,
      };

  factory LedgerEntry.fromMap(Map<String, dynamic> map) => LedgerEntry(
        uuid: map['uuid'] as String,
        businessUuid: map['business_uuid'] as String,
        contactUuid: map['contact_uuid'] as String,
        type: map['type'] as String,
        amount: (map['amount'] as num).toDouble(),
        note: map['note'] as String?,
        relatedSaleUuid: map['related_sale_uuid'] as String?,
        createdAt: map['created_at'] as int,
        lastUpdated: map['last_updated'] as int,
        isDeleted: (map['is_deleted'] as int) == 1,
        isSynced: (map['is_synced'] as int) == 1,
      );
}
