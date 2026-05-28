class Station {
  final String id;           // Уникальный идентификатор станции
  final String name;         // Название радиостанции
  final String streamUrl;    // URL для аудиопотока
  final String imageUrl;     // URL логотипа/обложки
  bool isFavorite;           // Статус избранного (может меняться)

  Station({
    required this.id,
    required this.name,
    required this.streamUrl,
    required this.imageUrl,
    this.isFavorite = false,  // По умолчанию станция не в избранном
  });
}