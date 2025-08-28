// Stub implementation for web platform

// Record class stub for web
class Record {
  Future<bool> hasPermission() async => false;
  Future<bool> isEncoderSupported(AudioEncoder encoder) async => false;
  Future<void> start({required String path, AudioEncoder? encoder, int? bitRate, int? samplingRate}) async {}
  Future<String?> stop() async => null;
  Future<void> dispose() async {}
  Future<AmplitudeResult> getAmplitude() async => AmplitudeResult(current: 0, max: 0);
}

// AudioEncoder enum stub for web
enum AudioEncoder {
  aacLc,
  aacEld,
  aacHe,
  amrNb,
  amrWb,
  opus,
  flac,
  pcm16bits,
  pcm8bits,
  wav
}

// AmplitudeResult class stub for web
class AmplitudeResult {
  final double current;
  final double max;
  
  const AmplitudeResult({required this.current, required this.max});
}