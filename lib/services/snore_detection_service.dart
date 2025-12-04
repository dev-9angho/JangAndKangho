import 'package:tflite_audio/tflite_audio.dart';

class SnoreDetectionService {
  // 모델 파일 경로 (assets 폴더에 있어야 함)
  final String _model = 'assets/soundclassifier_with_metadata.tflite';
  final String _label = 'assets/labels.txt';
  
  Stream<Map<dynamic, dynamic>>? _recognitionStream;
  bool _isRecording = false;

  // 1. 모델 로딩
  Future<void> loadModel() async {
    try {
      await TfliteAudio.loadModel(
        model: _model,
        label: _label,
        inputType: 'rawAudio', // 마이크 스트림 직접 입력
        numThreads: 1,
        isAsset: true,
      );
      print("✅ AI 모델 로드 완료");
    } catch (e) {
      print("❌ AI 모델 로드 실패: $e");
    }
  }

  // 2. 분석 시작 (스트림 반환)
  Stream<Map<dynamic, dynamic>> startRecognition() {
    if (_isRecording) return _recognitionStream!;

    try {
      // 1초(1000ms)마다 소리를 분석하여 결과 반환
      _recognitionStream = TfliteAudio.startAudioRecognition(
        sampleRate: 44100,
        bufferSize: 44100,
        numOfInferences: 99999,
        detectionThreshold: 0.5, // 80% 이상 확실할 때만 결과 인정
        averageWindowDuration: 1000,
        minimumTimeBetweenSamples: 1000,
        suppressionTime: 1500,
      );
      _isRecording = true;
      return _recognitionStream!;
    } catch (e) {
      print("❌ 인식 시작 실패: $e");
      return const Stream.empty();
    }
  }

  // 3. 분석 종료
  void stopRecognition() {
    if (!_isRecording) return;
    TfliteAudio.stopAudioRecognition();
    _isRecording = false;
  }
}