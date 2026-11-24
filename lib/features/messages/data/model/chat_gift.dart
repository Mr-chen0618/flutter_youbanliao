class ChatGift {
  const ChatGift({
    required this.id,
    required this.name,
    required this.coins,
    required this.asset,
  });
  final String id, name, asset;
  final int coins;
  factory ChatGift.fromJson(Map<String, dynamic> json) => ChatGift(
    id: json['id'] as String,
    name: json['name'] as String,
    coins: json['coins'] as int,
    asset: json['asset'] as String,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'coins': coins,
    'asset': asset,
  };
}
