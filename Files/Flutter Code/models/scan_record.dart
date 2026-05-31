class ScanRecord {
  final String id;
  final DateTime createdAt;
  final String resultStatus;
  final double ripePercent;
  final double yellowPercent;
  final double brownPercent;
  final String? imageName;

  const ScanRecord({
    required this.id,
    required this.createdAt,
    required this.resultStatus,
    required this.ripePercent,
    required this.yellowPercent,
    required this.brownPercent,
    this.imageName,
  });

  factory ScanRecord.fromMap(Map<String, dynamic> map) {
    return ScanRecord(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      resultStatus: map['result_status'] as String,
      ripePercent: (map['ripe_percent'] as num).toDouble(),
      yellowPercent: (map['yellow_percent'] as num).toDouble(),
      brownPercent: (map['brown_percent'] as num).toDouble(),
      imageName: map['image_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'result_status': resultStatus,
      'ripe_percent': ripePercent,
      'yellow_percent': yellowPercent,
      'brown_percent': brownPercent,
      'image_name': imageName,
    };
  }
}
