class Station {
  final String id;
  final String name;
  final String streamUrl;
  final String imageUrl;
  final String genre;
  final String description;
  final bool isHidden;  
  bool isFavorite;
  int listenCount;

  Station({
    required this.id,
    required this.name,
    required this.streamUrl,
    required this.imageUrl,
    this.genre = 'pop',
    this.description = '',
    this.isHidden = false,  
    this.isFavorite = false,
    this.listenCount = 0,
  });
}