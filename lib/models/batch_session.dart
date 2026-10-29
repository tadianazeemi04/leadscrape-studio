class BatchSession {
  final String id;
  final String state;
  final List<String> cities;
  final List<String> contractors;
  final List<String> completedQueryKeys; // e.g. ["Roofing|Houston", "HVAC|Houston"]
  final String? currentCity;
  final String? currentContractor;
  final String masterTxtPath;
  final String masterCsvPath;
  final int emailsCount;
  final int websitesVisited;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted;

  const BatchSession({
    required this.id,
    required this.state,
    required this.cities,
    required this.contractors,
    required this.completedQueryKeys,
    this.currentCity,
    this.currentContractor,
    required this.masterTxtPath,
    required this.masterCsvPath,
    required this.emailsCount,
    required this.websitesVisited,
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
  });

  int get totalQueries => cities.length * contractors.length;
  int get completedQueries => completedQueryKeys.length;
  double get progressRatio =>
      totalQueries == 0 ? 0.0 : (completedQueries / totalQueries).clamp(0.0, 1.0);

  BatchSession copyWith({
    String? id,
    String? state,
    List<String>? cities,
    List<String>? contractors,
    List<String>? completedQueryKeys,
    String? currentCity,
    String? currentContractor,
    String? masterTxtPath,
    String? masterCsvPath,
    int? emailsCount,
    int? websitesVisited,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
  }) {
    return BatchSession(
      id: id ?? this.id,
      state: state ?? this.state,
      cities: cities ?? this.cities,
      contractors: contractors ?? this.contractors,
      completedQueryKeys: completedQueryKeys ?? this.completedQueryKeys,
      currentCity: currentCity ?? this.currentCity,
      currentContractor: currentContractor ?? this.currentContractor,
      masterTxtPath: masterTxtPath ?? this.masterTxtPath,
      masterCsvPath: masterCsvPath ?? this.masterCsvPath,
      emailsCount: emailsCount ?? this.emailsCount,
      websitesVisited: websitesVisited ?? this.websitesVisited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'state': state,
      'cities': cities,
      'contractors': contractors,
      'completedQueryKeys': completedQueryKeys,
      'currentCity': currentCity,
      'currentContractor': currentContractor,
      'masterTxtPath': masterTxtPath,
      'masterCsvPath': masterCsvPath,
      'emailsCount': emailsCount,
      'websitesVisited': websitesVisited,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory BatchSession.fromJson(Map<String, dynamic> json) {
    return BatchSession(
      id: json['id'] as String? ?? '',
      state: json['state'] as String? ?? '',
      cities: (json['cities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      contractors: (json['contractors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      completedQueryKeys: (json['completedQueryKeys'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      currentCity: json['currentCity'] as String?,
      currentContractor: json['currentContractor'] as String?,
      masterTxtPath: json['masterTxtPath'] as String? ?? '',
      masterCsvPath: json['masterCsvPath'] as String? ?? '',
      emailsCount: (json['emailsCount'] as num?)?.toInt() ?? 0,
      websitesVisited: (json['websitesVisited'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
