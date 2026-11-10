enum HomeFeedKindEnum {
  activities('activities'),
  companions('companions');

  const HomeFeedKindEnum(this.value);
  final String value;

  static HomeFeedKindEnum fromValue(String? value) => values.firstWhere(
    (kind) => kind.value == value,
    orElse: () => companions,
  );
}
