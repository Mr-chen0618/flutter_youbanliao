enum HomeMockScenarioEnum {
  success('success'),
  empty('empty'),
  failOnce('failOnce');

  const HomeMockScenarioEnum(this.value);
  final String value;

  static HomeMockScenarioEnum fromValue(String? value) => values.firstWhere(
    (scenario) => scenario.value == value,
    orElse: () => success,
  );
}
