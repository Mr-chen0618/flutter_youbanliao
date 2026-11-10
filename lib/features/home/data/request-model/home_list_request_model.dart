/// Current feed contract. Adapt API field names in the server implementation.
class HomeListRequestModel {
  const HomeListRequestModel({required this.city});

  final String city;

  Map<String, dynamic> toJson() => {'city': city};
}
