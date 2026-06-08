import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static bool enableSound = true;

  static Future<void> playSuccess() async {
    if (!enableSound) return;
    try {
      await _player.play(AssetSource('sounds/beep.mp3'));
    } catch (e) {
      print("Error playing sound: $e");
    }
  }
}
