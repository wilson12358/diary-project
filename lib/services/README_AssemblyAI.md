# AssemblyAI Speech-to-Text Integration

## 🎯 **Overview**

This implementation replaces Vosk with AssemblyAI for speech-to-text conversion in the diary app. AssemblyAI provides high-accuracy transcription with cloud processing and supports multiple languages.

## 🔧 **Implementation Details**

### **1. AssemblyAI Service (`assemblyai_service.dart`)**

**Core Features:**
- File-based audio transcription
- Real-time streaming (future expansion)
- Multi-language support
- Status monitoring
- Error handling

**API Flow:**
1. **Upload**: Audio file uploaded to AssemblyAI
2. **Request**: Transcription job submitted
3. **Poll**: Check status until completion
4. **Result**: Retrieve transcribed text

**Key Methods:**
```dart
// Main transcription method
Future<String?> transcribeAudioFile(String filePath)

// Test API connection
Future<bool> testConnection()

// Real-time streaming (for future use)
Future<bool> connectRealTimeStreaming()
```

### **2. Voice Service Integration (`voice_service.dart`)**

**Enhanced Features:**
- AssemblyAI integration
- Automatic transcription after recording
- Stream-based event handling
- Error propagation

**New Streams:**
```dart
Stream<String> onTranscription           // Transcription results
Stream<TranscriptionStatus> onTranscriptionStatusChanged  // Status updates
```

### **3. UI Integration (`voice_recorder_button.dart`)**

**New Features:**
- Transcription progress feedback
- Success/error notifications
- Status indicator updates
- Callback for transcription completion

**Updated Interface:**
```dart
VoiceRecorderButton(
  onRecordingComplete: (path) => {...},
  onTranscriptionComplete: (text) => {...},  // New callback
  voiceService: _voiceService,
)
```

## 🚀 **Usage**

### **Basic Recording & Transcription**

```dart
// 1. Initialize voice service
final voiceService = VoiceService();
await voiceService.initialize();

// 2. Listen to transcription results
voiceService.onTranscription.listen((transcription) {
  print('Transcribed: $transcription');
});

// 3. Start recording
await voiceService.startRecording();

// 4. Stop recording (auto-triggers transcription)
await voiceService.stopRecording();
```

### **Manual Transcription**

```dart
// Transcribe an existing audio file
final result = await voiceService.transcribeAudioFile('/path/to/audio.m4a');
if (result != null) {
  print('Transcription: $result');
}
```

### **Status Monitoring**

```dart
voiceService.onTranscriptionStatusChanged.listen((status) {
  switch (status) {
    case TranscriptionStatus.uploading:
      showLoadingIndicator('Uploading audio...');
      break;
    case TranscriptionStatus.processing:
      showLoadingIndicator('Processing transcription...');
      break;
    case TranscriptionStatus.completed:
      hideLoadingIndicator();
      break;
    case TranscriptionStatus.error:
      showError('Transcription failed');
      break;
  }
});
```

## 🔧 **Configuration**

### **API Key**
The AssemblyAI API key is configured in `assemblyai_service.dart`:
```dart
static const String _apiKey = '54dc223b6bc341bcad6bdd894928e82f';
```

### **Audio Format**
Recording configuration for optimal compatibility:
```dart
RecordConfig(
  encoder: AudioEncoder.aacLc,  // AAC-LC format (recommended)
  bitRate: 128000,             // 128 kbps
  sampleRate: 44100,           // 44.1 kHz
)
```

### **Language Support**
Supported languages (configurable):
- English (en) - Default
- Spanish (es)
- French (fr)
- German (de)
- Italian (it)
- Portuguese (pt)
- Japanese (ja)
- Chinese (zh)
- Korean (ko)
- Arabic (ar)
- Hindi (hi)
- Russian (ru)
- Dutch (nl)

## 🧪 **Testing**

### **Connection Test**
```dart
import 'lib/utils/assemblyai_test.dart';

// Test API connection
final connected = await AssemblyAITest.testConnection();
if (connected) {
  print('AssemblyAI is ready!');
}
```

### **Full Test Suite**
```dart
// Run all tests
final results = await AssemblyAITest.runAllTests();
print('Tests passed: ${results.values.where((v) => v).length}/${results.length}');
```

### **Manual Testing Steps**

1. **Test Connection:**
   - Run the app in debug mode
   - Check console for "AssemblyAI connection test successful"

2. **Test Recording:**
   - Navigate to new entry screen
   - Tap voice recorder button
   - Record a short voice note
   - Verify transcription appears in text field

3. **Test Error Handling:**
   - Disconnect internet
   - Try recording and verify error messages

## 📱 **User Experience**

### **Recording Flow**
1. User taps voice recorder button
2. Red recording indicator shows
3. User speaks their diary entry
4. User taps stop
5. "Uploading audio..." notification appears
6. "Processing transcription..." notification appears
7. "Transcription completed: [preview]" notification appears
8. Text is automatically added to diary entry

### **Error Scenarios**
- **No Internet**: "Transcription error: Network error"
- **API Failure**: "Transcription error: Service unavailable"
- **Invalid Audio**: "Transcription error: Audio format not supported"
- **Timeout**: "Transcription error: Processing timeout"

## 🔄 **Migration from Vosk**

### **What Changed**
- ✅ Removed Vosk dependency
- ✅ Added HTTP and WebSocket dependencies
- ✅ Cloud-based processing (vs local)
- ✅ Better accuracy for multiple languages
- ✅ Automatic punctuation and formatting
- ✅ Real-time status updates

### **What Stayed the Same**
- ✅ Voice recorder button interface
- ✅ Audio recording functionality
- ✅ File-based workflow
- ✅ Error handling patterns
- ✅ Stream-based architecture

## 🚨 **Troubleshooting**

### **Common Issues**

**1. "Connection test failed"**
- Check internet connectivity
- Verify API key is correct
- Check if AssemblyAI service is available

**2. "Transcription failed"**
- Verify audio file exists and is readable
- Check audio format is supported (AAC-LC recommended)
- Ensure file size is reasonable (< 100MB recommended)

**3. "Upload failed"**
- Check network stability
- Verify file permissions
- Try with shorter audio clip

**4. "Processing timeout"**
- Normal for very long audio files (> 5 minutes)
- Check AssemblyAI service status
- Retry with shorter clips

### **Debug Commands**

```dart
// Enable detailed logging
import 'package:flutter/foundation.dart';
debugPrint('Current transcription status: ${voiceService.transcriptionStatus}');

// Test individual components
final apiTest = await voiceService.testAssemblyAIConnection();
print('API connection: $apiTest');
```

## 📊 **Performance Considerations**

### **Advantages**
- ✅ Higher accuracy than local processing
- ✅ No device storage requirements
- ✅ Supports more languages
- ✅ Better handling of accents/dialects
- ✅ Automatic punctuation
- ✅ No battery drain from local processing

### **Considerations**
- 🔄 Requires internet connection
- 🔄 Small latency for cloud processing (2-10 seconds typical)
- 🔄 Uses mobile data if not on WiFi
- 🔄 Dependent on AssemblyAI service availability

### **Optimization**
- Audio files are automatically compressed
- Polling interval optimized for responsiveness
- Connection reuse for multiple requests
- Proper error handling and retry logic

## 🔐 **Privacy & Security**

- Audio files are temporarily uploaded to AssemblyAI
- Files are deleted from AssemblyAI servers after processing
- API communication uses HTTPS encryption
- No audio data is stored permanently by AssemblyAI
- API key is embedded in app (consider environment variables for production)

## 🔮 **Future Enhancements**

### **Planned Features**
- Real-time transcription during recording
- Multiple language selection in UI
- Custom vocabulary/dictionary support
- Speaker identification for multi-person recordings
- Confidence scores for transcription quality
- Offline fallback with local speech recognition

### **Possible Improvements**
- Chunk large audio files for faster processing
- Add transcription caching for repeated audio
- Implement audio pre-processing for better quality
- Add voice activity detection to reduce processing time

---

## 📞 **Support**

For issues with this integration:
1. Check the troubleshooting section above
2. Run the test suite to identify specific problems
3. Check console logs for detailed error messages
4. Verify AssemblyAI service status at status.assemblyai.com
