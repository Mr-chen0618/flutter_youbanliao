class HomeActivityModel {
  const HomeActivityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.location,
    required this.image,
    required this.categoryId,
    this.category = '',
  });
  final String id;
  final String title;
  final String description;
  final String time;
  final String location;
  final String image;
  final String categoryId;
  final String category;
  factory HomeActivityModel.fromJson(Map<String, dynamic> json) =>
      HomeActivityModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        time: json['time'] as String,
        location: json['location'] as String,
        image: json['image'] as String,
        categoryId: json['categoryId'] as String,
        category: json['category'] as String? ?? '',
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'time': time,
    'location': location,
    'image': image,
    'categoryId': categoryId,
    'category': category,
  };
}
