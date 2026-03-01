import '../domain/station.dart';

final List<Station> mockStations = [
  Station(
    id: '1',
    name: 'France Info',
    streamUrl: 'https://stream-ssl.radiofrance.fr/franceinfo.mp3',
    imageUrl: 'https://picsum.photos/200?1',
  ),
  Station(
    id: '2',
    name: 'BBC World Service',
    streamUrl: 'https://stream.live.vc.bbcmedia.co.uk/bbc_world_service',
    imageUrl: 'https://picsum.photos/200?2',
  ),
  Station(
    id: '3',
    name: 'NRJ France',
    streamUrl: 'https://cdn.nrjaudio.fm/audio1/fr/30001/mp3_128.mp3',
    imageUrl: 'https://picsum.photos/200?3',
  ),
];