class ContractorTask {
  List<String> contractorTypes;
  Map<String, List<String>> statesAndCities;

  ContractorTask({
    required this.contractorTypes,
    required this.statesAndCities,
  });

  /// Factory for default starter data
  factory ContractorTask.defaultData() {
    return ContractorTask(
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
      },
    );
  }

  int get totalQueries {
    int totalCities = 0;
    for (var cities in statesAndCities.values) {
      totalCities += cities.length;
    }
    return contractorTypes.length * totalCities;
  }
}
