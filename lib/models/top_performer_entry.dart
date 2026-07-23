class TopPerformerEntry {
  final String name;
  final String subtitle;
  final double value;
  final String? imageUrl;

  TopPerformerEntry({
    required this.name,
    required this.subtitle,
    required this.value,
    this.imageUrl,
  });

  factory TopPerformerEntry.fromMap(Map<String, dynamic> map) {
    return TopPerformerEntry(
      name: map['name'] ?? 'Unknown',
      subtitle: map['subtitle'] ?? '',
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'subtitle': subtitle,
      'value': value,
      'imageUrl': imageUrl,
    };
  }
}