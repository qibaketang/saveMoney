class ExpenseRecord {
  final String id;
  final String category;
  final double amount;
  final String note;
  final List<String> tags;
  final DateTime time;
  final String? location;
  final String? receiptPath;

  const ExpenseRecord({
    required this.id,
    required this.category,
    required this.amount,
    required this.note,
    required this.tags,
    required this.time,
    this.location,
    this.receiptPath,
  });

  static DateTime _parseLocalDateTime(String raw) {
    return DateTime.parse(raw).toLocal();
  }

  static String _serializeUtcDateTime(DateTime value) {
    return value.toUtc().toIso8601String();
  }

  factory ExpenseRecord.fromJson(Map<String, dynamic> json) => ExpenseRecord(
        id: json['id'] as String,
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
        note: json['note'] as String? ?? '',
        tags: List<String>.from(json['tags'] as List? ?? const []),
        time: _parseLocalDateTime(json['time'] as String),
        location: json['location'] as String?,
        receiptPath: json['receiptPath'] as String?,
      );

  factory ExpenseRecord.fromApi(Map<String, dynamic> json) => ExpenseRecord(
        id: (json['_id'] ?? json['id']).toString(),
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
        note: json['note'] as String? ?? '',
        tags: List<String>.from(json['tags'] as List? ?? const []),
        time: _parseLocalDateTime((json['spentAt'] ?? json['time']) as String),
        location: json['location'] as String?,
        receiptPath: json['receiptUrl'] as String?,
      );

  Map<String, dynamic> toApiJson() => {
        'category': category,
        'amount': amount,
        'note': note,
        'tags': tags,
        'spentAt': _serializeUtcDateTime(time),
        'location': location,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'amount': amount,
        'note': note,
        'tags': tags,
        'time': _serializeUtcDateTime(time),
        'location': location,
        'receiptPath': receiptPath,
      };
}
