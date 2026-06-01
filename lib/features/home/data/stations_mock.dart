import 'package:flutter/material.dart';

import '../domain/station.dart';

final List<Station> mockStations = [
  Station(
    id: '1',
    name: 'Европа Плюс',
    streamUrl: 'https://ep256.hostingradio.ru:8052/europaplus256.mp3',
    imageUrl: 'https://static.wikia.nocookie.net/radiopedia/images/e/ea/%D0%95%D0%B2%D1%80%D0%BE%D0%BF%D0%B0_%D0%9F%D0%BB%D1%8E%D1%81_svg.svg/revision/latest/scale-to-width-down/200?cb=20250110154911&path-prefix=ru',
    genre: 'pop',
    description: 'Лучшая музыка Европы и мировые хиты',
  ),
  Station(
    id: '2',
    name: 'Русское Радио',
    streamUrl: 'https://rusradio.hostingradio.ru/rusradio96.aacp',
    imageUrl: 'https://static.wikia.nocookie.net/radiopedia/images/b/b3/%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%BE%D0%B5_%D1%80%D0%B0%D0%B4%D0%B8%D0%BE_%282016-%D0%BD.%D0%B2.%29.png/revision/latest/scale-to-width-down/200?cb=20171220064704&path-prefix=ru',
    genre: 'russian',
    description: 'Главные хиты русской эстрады',
  ),
  Station(
    id: '3',
    name: 'Наше Радио',
    streamUrl: 'https://nashe1.hostingradio.ru/nashe-256',
    imageUrl: 'https://static.wikia.nocookie.net/radiopedia/images/d/d4/%D0%9D%D0%B0%D1%88%D0%B5_%D1%80%D0%B0%D0%B4%D0%B8%D0%BE_2.png/revision/latest?cb=20150801063545&path-prefix=ru',
    genre: 'rock',
    description: 'Русский рок и альтернатива',
  ),
  Station(
    id: '4',
    name: 'Дорожное Радио',
    streamUrl: 'http://dorognoe.hostingradio.ru:8000/radio',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/ru/e/eb/Dorozhnoe_logo.jpg?_=20250514123329',
    genre: 'pop',
    description: 'Музыка для дороги и хорошего настроения',
  ),
  Station(
    id: '5',
    name: 'Relax FM Chillout',
    streamUrl: 'https://pub0201.101.ru/stream/trust/mp3/128/24',
    imageUrl: 'https://www.radiobells.com/stations/relaxfmchillout.webp',
    genre: 'chillout',
    description: 'Релакс и чилл-аут',
  ),
  Station(
    id: '6',
    name: 'Вести ФМ',
    streamUrl: 'http://icecast.vgtrk.cdnvideo.ru/vestifm_mp3_192kbps',
    imageUrl: 'https://static.wikia.nocookie.net/radiopedia/images/6/6f/Energy_FM_logo.png/revision/latest?cb=20180101123456',
    genre: 'news',
    description: 'Новости',
  ),
  Station(
    id: '7',
    name: 'РОУК ФМ',
    streamUrl: 'http://nashe1.hostingradio.ru/rock-128.mp3',
    imageUrl: 'https://lh3.googleusercontent.com/D3taObR7tfyhwDFY40VS8DIVri7iif5RuzI9C-mXxRwF41vGZ_dO_n6MWM57P-mZczFC=w300',
    genre: 'rock',
    description: 'классический рок, поп-рок, рок',
  ),
  Station(
    id: 'secret_69',
    name: '🎵 GACHI RADIO 🎵',
    streamUrl: 'http://gachiradio.com:8000/radio',
    imageUrl: 'https://i.pinimg.com/736x/06/0b/92/060b9279a44f4621aacfbf696a2e6e05.jpg',
    genre: 'secret',
    description: 'Секретная радиостанция',
    isHidden: true,
  ),
];

// Список жанров
final List<Genre> genres = [
  Genre(id: 'pop', name: 'Поп-музыка', icon: Icons.music_note, color: Colors.blue),
  Genre(id: 'rock', name: 'Рок', icon: Icons.music_video, color: Colors.red),
  Genre(id: 'russian', name: 'Русская', icon: Icons.mic, color: Colors.green),
  Genre(id: 'chillout', name: 'Чилл-аут', icon: Icons.spa, color: Colors.teal),
  Genre(id: 'news', name: 'Новости', icon: Icons.newspaper, color: Colors.blueGrey),
  Genre(id: 'secret', name: 'Секрет', icon: Icons.egg_alt, color: Colors.amber),
];

class Genre {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  
  Genre({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}