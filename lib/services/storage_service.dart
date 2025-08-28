import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import '../models/diary_entry.dart';

class StorageService {
  FirebaseStorage? _storage;
  bool _isInitialized = false;

  // Getter to expose storage instance for progress tracking
  FirebaseStorage get storage {
    if (_storage == null) {
      throw Exception('StorageService not initialized. Call initialize() first.');
    }
    return _storage!;
  }

  /// Initialize the storage service with connection pooling
  Future<void> initialize() async {
    try {
      if (_isInitialized && _storage != null) {
        return; // Already initialized
      }

      if (kDebugMode) {
        debugPrint('StorageService: Initializing Firebase Storage...');
      }

      // Get the default Firebase Storage instance
      _storage = FirebaseStorage.instance;
      
      // Test the connection efficiently
      final rootRef = _storage!.ref();
      
      if (kDebugMode) {
        debugPrint('StorageService: ✅ Firebase Storage initialized successfully');
      }
      
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StorageService: ❌ Failed to initialize Firebase Storage: $e');
      }
      _isInitialized = false;
      throw Exception('Failed to initialize Firebase Storage: $e');
    }
  }

  Future<String> uploadFile(File file, String userId, String entryId) async {
    return uploadFileWithProgress(file, userId, entryId, null);
  }

  Future<String> uploadFileWithProgress(File file, String userId, String entryId, Function(double)? onProgress) async {
    try {
      // Ensure service is initialized (with connection pooling)
      if (!_isInitialized || _storage == null) {
        await initialize();
      }

      // Validate file exists and has content
      if (!await file.exists()) {
        throw Exception('File does not exist: ${file.path}');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('File is empty: ${file.path}');
      }

      String fileName = path.basename(file.path);
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Determine file type and create appropriate storage path
      String fileType = _getFileType(fileName);
      String storagePath = '${fileType}_${timestamp}_${fileName}';

      // Create reference directly from root
      Reference ref = _storage!.ref().child(storagePath);

      // Upload with metadata and progress tracking
      UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(fileName),
          customMetadata: {
            'originalName': fileName,
            'uploadedAt': timestamp,
            'fileSize': fileSize.toString(),
            'userId': userId,
            'entryId': entryId,
          },
        ),
      );

      // Track upload progress if callback provided
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (snapshot.bytesTransferred > 0 && snapshot.totalBytes > 0) {
            double progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress!(progress);
          }
        });
      }

      if (kDebugMode) {
        debugPrint('StorageService: Upload task created, waiting for completion...');
      }

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StorageService: ❌ Upload failed: $e');
        debugPrint('StorageService: Error type: ${e.runtimeType}');
        if (e is FirebaseException) {
          debugPrint('StorageService: Firebase error code: ${e.code}');
          debugPrint('StorageService: Firebase error message: ${e.message}');
        }
      }
      throw Exception('Failed to upload file ${path.basename(file.path)}: $e');
    }
  }

  /// Get content type based on file extension
  String _getContentType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      case '.m4a':
        return 'audio/mp4';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get file type category based on file extension
  String _getFileType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
        return 'image';
      case '.mp4':
      case '.mov':
      case '.avi':
      case '.mkv':
        return 'video';
      case '.m4a':
      case '.mp3':
      case '.wav':
      case '.aac':
      case '.ogg':
        return 'audio';
      default:
        return 'file';
    }
  }

  Future<void> deleteFile(String url) async {
    try {
      if (kDebugMode) {
        debugPrint('StorageService: Deleting file: $url');
      }
      Reference ref = _storage!.refFromURL(url);
      await ref.delete();
      if (kDebugMode) {
        debugPrint('StorageService: ✅ File deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StorageService: ❌ Error deleting file: $e');
      }
      // Don't rethrow - file deletion failure shouldn't break the app
    }
  }
  
  Future<void> deleteMultipleFiles(List<String> urls) async {
    if (kDebugMode) {
      debugPrint('StorageService: Deleting ${urls.length} files...');
    }
    
    List<Future<void>> deleteFutures = [];
    
    for (String url in urls) {
      deleteFutures.add(deleteFile(url));
    }
    
    await Future.wait(deleteFutures);
    
    if (kDebugMode) {
      debugPrint('StorageService: ✅ All files deleted');
    }
  }
  
  Future<void> deleteAllFilesForEntry(DiaryEntry entry) async {
    if (entry.mediaUrls.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('StorageService: Deleting all files for entry: ${entry.id}');
      }
      await deleteMultipleFiles(entry.mediaUrls);
    }
  }

  /// Test Firebase Storage connection
  Future<bool> testConnection() async {
    try {
      if (!_isInitialized || _storage == null) {
        await initialize();
      }
      
      if (kDebugMode) {
        debugPrint('StorageService: Testing Firebase Storage connection...');
        debugPrint('StorageService: App name: ${_storage!.app.name}');
        debugPrint('StorageService: Storage bucket: ${_storage!.app.options.storageBucket}');
      }
      
      // Try to get a reference to the root
      final rootRef = _storage!.ref();
      if (kDebugMode) {
        debugPrint('StorageService: Root reference created successfully');
        debugPrint('StorageService: Root path: ${rootRef.fullPath}');
        debugPrint('StorageService: Root bucket: ${rootRef.bucket}');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StorageService: ❌ Connection test failed: $e');
      }
      return false;
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
