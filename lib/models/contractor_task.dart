class ContractorTask {
  String manualState;
  List<String> activeCities;
  List<String> contractorTypes;
  Map<String, List<String>> statesAndCities;

  ContractorTask({
    this.manualState = 'Texas',
    List<String>? activeCities,
    required this.contractorTypes,
    required this.statesAndCities,
  }) : activeCities = activeCities ?? (statesAndCities['Texas'] ?? ['Houston', 'Dallas', 'Austin', 'San Antonio', 'Fort Worth']);

  factory ContractorTask.defaultData() {
    return ContractorTask(
      manualState: 'Texas',
      activeCities: ['Houston', 'Dallas', 'Austin', 'San Antonio', 'Fort Worth'],
      contractorTypes: [
        'Roofing',
        'Plumbing',
        'HVAC',
        'Electrician',
        'Painting',
      ],
      statesAndCities: {
        'Texas': ['Houston', 'Dallas', 'Austin', 'San Antonio', 'Fort Worth'],
        'Florida': ['Miami', 'Orlando', 'Tampa', 'Jacksonville'],
        'California': ['Los Angeles', 'San Diego', 'San Jose', 'San Francisco'],
      },
    );
  }

  /// Calculates total queries based on manualState and activeCities
  int get totalQueries {
    return contractorTypes.length * activeCities.length;
  }
}
