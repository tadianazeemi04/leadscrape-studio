class EmailRecord {
  final String email;
  final String contractorType;
  final String city;
  final String state;
  final String websiteUrl;
  final String? facebookUrl;
  final String source;
  final DateTime discoveredAt;

  EmailRecord({
    required this.email,
    required this.contractorType,
    required this.city,
    required this.state,
    required this.websiteUrl,
    this.facebookUrl,
    required this.source,
    DateTime? discoveredAt,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'contractorType': contractorType,
      'city': city,
      'state': state,
      'websiteUrl': websiteUrl,
      'facebookUrl': facebookUrl ?? '',
      'source': source,
      'discoveredAt': discoveredAt.toIso8601String(),
    };
  }

  factory EmailRecord.fromMap(Map<String, dynamic> map) {
    return EmailRecord(
      email: map['email'] ?? '',
      contractorType: map['contractorType'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      websiteUrl: map['websiteUrl'] ?? '',
      facebookUrl: map['facebookUrl'],
      source: map['source'] ?? 'Website',
      discoveredAt: map['discoveredAt'] != null
          ? DateTime.tryParse(map['discoveredAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailRecord &&
          runtimeType == other.runtimeType &&
          email.toLowerCase() == other.email.toLowerCase() &&
          contractorType.toLowerCase() == other.contractorType.toLowerCase() &&
          state.toLowerCase() == other.state.toLowerCase();

  @override
  int get hashCode =>
      email.toLowerCase().hashCode ^
      contractorType.toLowerCase().hashCode ^
      state.toLowerCase().hashCode;
}
