class HomeCategoryModel {
  const HomeCategoryModel({required this.id, required this.label});
  final String id;
  final String label;
  factory HomeCategoryModel.fromJson(Map<String, dynamic> json) =>
      HomeCategoryModel(
        id: json['id'] as String,
        label: json['label'] as String,
      );
  Map<String, dynamic> toJson() => {'id': id, 'label': label};
}
