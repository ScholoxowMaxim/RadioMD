class Station {
  final String id;
  final String name;
  final String streamUrl;
  final String imageUrl;
  final String genre;
  final String description;
  final bool isHidden;  // Добавляем поле
  bool isFavorite;
  int listenCount;

  Station({
    required this.id,
    required this.name,
    required this.streamUrl,
    required this.imageUrl,
    this.genre = 'pop',
    this.description = '',
    this.isHidden = false,  // По умолчанию false
    this.isFavorite = false,
    this.listenCount = 0,
  });
}