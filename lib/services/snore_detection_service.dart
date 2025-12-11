import 'dart:async';
import 'dart:io';
import 'package:tflite_audio/tflite_audio.dart';
import 'package:record/record.dart'; 
import 'package:path_provider/path_provider.dart'; 

class SnoreDetectionService {
  final String _model = 'assets/soundclassifier_with_metadata.tflite';
  final String _label = 'assets/labels.txt';
  
  // UI로 데이터 전달용 스트림
  final StreamController<Map<dynamic, dynamic>> _streamController = StreamController.broadcast();
  
  // 녹음기 인스턴스
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  // 상태 플래그
  bool _isAnalysisRunning = false; 
  bool _isRecordingHighlight = false; // 현재 녹음 중인지 체크

  // 1. 모델 로딩
  Future<void> loadModel() async {
    try {
      await TfliteAudio.loadModel(
        model: _model,
        label: _label,
        inputType: 'rawAudio', // rawAudio 유지 (에뮬레이터 호환성)
        numThreads: 1,
        isAsset: true,
      );
      print("✅ AI 모델 로드 완료");
    } catch (e) {
      print("❌ AI 모델 로드 실패: $e");
    }
  }

  // 2. 외부에서 분석 시작 요청
  Stream<Map<dynamic, dynamic>> startRecognition() {
    if (_isAnalysisRunning) return _streamController.stream;
    _startTfliteLoop();
    return _streamController.stream;
  }

  // 3. [핵심 로직] AI 듣기 루프
  void _startTfliteLoop() {
    if (_isRecordingHighlight) return; 

    try {
      print("👂 AI 듣기 시작 (44302)...");
      
      final stream = TfliteAudio.startAudioRecognition(
        sampleRate: 44032, 
        bufferSize: 44032, 
        numOfInferences: 99999,
        detectionThreshold: 0.7,
        averageWindowDuration: 1000,
        minimumTimeBetweenSamples: 1000,
        suppressionTime: 1500,
      );

      _isAnalysisRunning = true;

      stream.listen((event) {
        // 🚨 [수정] 컨트롤러가 닫혀있으면 데이터 전송 중단 (Bad state 에러 방지)
        if (_streamController.isClosed) return;
        
        _streamController.add(event);

        String result = event['recognitionResult'].toString();
        
        // -----------------------------------------------------------
        // 🎯 감지 로직: 1번 인덱스(잠꼬대)가 뜨면 녹음 전환
        // -----------------------------------------------------------
        if ((result.startsWith('1') || result.contains('잠꼬대')) && !_isRecordingHighlight) {
          print("🗣️ 잠꼬대 감지됨! ($result) -> 녹음 모드로 전환");
          _switchModeToRecording(); 
        }

      }, onError: (e) {
        print("❌ AI 스트림 에러: $e");
        _isAnalysisRunning = false;
      }, onDone: () {
        _isAnalysisRunning = false;
      });

    } catch (e) {
      print("❌ 인식 시작 실패: $e");
    }
  }

  // 4. 녹음 모드 전환 (침묵 녹음 방지 설정 적용)
  Future<void> _switchModeToRecording() async {
    print("🛑 [Step 1] 녹음 진입");
    _isRecordingHighlight = true; 

    try {
      // (1) AI 종료
      try {
        await TfliteAudio.stopAudioRecognition().timeout(const Duration(seconds: 2));
      } catch (e) {
        print("⚠️ AI 종료 지연 (무시)");
      }
      _isAnalysisRunning = false;
      
      // (2) 마이크 해제 대기 (충분히 김)
      await Future.delayed(const Duration(milliseconds: 1500));

      // (3) 경로 생성
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${dir.path}/${timestamp}_highlight.m4a'; 

      // (4) 녹음 시작
      if (await _audioRecorder.hasPermission()) {
        if (await _audioRecorder.isRecording()) await _audioRecorder.stop();
        
        // 🚨 [핵심 수정] AI와 주파수를 44100으로 똑같이 맞춰야 에뮬레이터 침묵 버그가 해결됨!
        const config = RecordConfig(
          encoder: AudioEncoder.aacLc, // 용량 절약 위해 AAC 사용
          sampleRate: 44032,           // 
          numChannels: 1,              // 모노
        ); 
        
        await _audioRecorder.start(config, path: filePath);
        print("🎙️ 녹음 시작 (44032Hz, .m4a)");
        
      } else {
        return;
      }

      // (5) 5초 녹음
      await Future.delayed(const Duration(seconds: 5));

      // (6) 녹음 종료 및 파일 확인
      String? savedPath = await _audioRecorder.stop();
      
      // 파일 크기 체크
      if (savedPath != null) {
        final file = File(savedPath);
        if (await file.exists()) {
            final size = await file.length();
            print("💾 저장 완료: $savedPath");
            print("📏 파일 크기: $size bytes"); 
            
            if (size < 1000) print("⚠️ 경고: 파일이 너무 작습니다.");
        }
      }

    } catch (e) {
      print("❌ 녹음 오류: $e");
    } finally {
      // (7) AI 복귀
      _isRecordingHighlight = false;
      await Future.delayed(const Duration(milliseconds: 1000));
      _startTfliteLoop();
    }
  }

  void stopRecognition() {
    _isAnalysisRunning = false;
    _isRecordingHighlight = false;
    try {
      TfliteAudio.stopAudioRecognition();
      _audioRecorder.stop();
    } catch (e) {}
  }
  
  void dispose() {
    // 🚨 [수정] 닫혀있는지 확인하고 닫음
    if (!_streamController.isClosed) {
      _streamController.close();
    }
    _audioRecorder.dispose();
  }
}