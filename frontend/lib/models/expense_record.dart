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

  factory ExpenseRecord.fromJson(Map<String, dynamic> json) => ExpenseRecord(
        id: json['id'] as String,
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
        note: json['note'] as String? ?? '',
        tags: List<String>.from(json['tags'] as List? ?? const []),
        time: DateTime.parse(json['time'] as String),
        location: json['location'] as String?,
        receiptPath: json['receiptPath'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'amount': amount,
        'note': note,
        'tags': tags,
        'time': time.toIso8601String(),
        'location': location,
        'receiptPath': receiptPath,
      };
}
