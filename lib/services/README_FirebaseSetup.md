# 🔥 Firebase Configuration Fix Guide

## 🚨 **Critical Issues Identified**

Based on the error messages, you have **two major Firebase problems**:

### **1. Firebase Storage Error**
```
[firebase_storage/object-not-found] No object exists at the desired reference
```

### **2. Firestore Database Missing**
```
The database (default) does not exist for project diaryproject-f6b60
```

## 🔧 **Step-by-Step Fixes**

### **Fix 1: Set Up Firestore Database**

#### **Step 1.1: Go to Firebase Console**
1. **Open** [Firebase Console](https://console.firebase.google.com/)
2. **Select** your project: `diaryproject-f6b60`
3. **Click** on the project

#### **Step 1.2: Create Firestore Database**
1. **In the left sidebar**, click **"Firestore Database"**
2. **Click** "Create database"
3. **Choose** "Start in test mode" (for development)
4. **Select** a location (choose closest to your users)
5. **Click** "Done"

#### **Step 1.3: Set Firestore Rules**
1. **Go to** "Rules" tab in Firestore
2. **Replace** the rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow users to read/write their own diary entries
      match /entries/{entryId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Allow authenticated users to read/write diary entries
    match /diary_entries/{entryId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
  }
}
```

3. **Click** "Publish"

### **Fix 2: Configure Firebase Storage**

#### **Step 2.1: Enable Storage**
1. **In Firebase Console**, click **"Storage"** in the left sidebar
2. **Click** "Get started"
3. **Choose** "Start in test mode" (for development)
4. **Select** a location (same as Firestore)
5. **Click** "Done"

#### **Step 2.2: Set Storage Rules**
1. **Go to** "Rules" tab in Storage
2. **Replace** the rules with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow authenticated users to upload files
    match /audio_files/{userId}/{entryId}/{fileName} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }
    
    // Allow authenticated users to upload media files
    match /media_files/{userId}/{entryId}/{fileName} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }
    
    // Allow authenticated users to upload profile images
    match /profile_images/{userId}/{fileName} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }
  }
}
```

3. **Click** "Publish"

### **Fix 3: Update Firebase Configuration**

#### **Step 3.1: Check Android Configuration**
Your `android/app/google-services.json` looks correct, but verify:

```json
{
  "project_info": {
    "project_number": "534607967199",
    "project_id": "diaryproject-f6b60",
    "storage_bucket": "diaryproject-f6b60.firebasestorage.app"
  }
}
```

#### **Step 3.2: Check iOS Configuration**
If you have iOS, ensure `ios/Runner/GoogleService-Info.plist` exists and contains:

```xml
<key>STORAGE_BUCKET</key>
<string>diaryproject-f6b60.firebasestorage.app</string>
<key>PROJECT_ID</key>
<string>diaryproject-f6b60</string>
```

### **Fix 4: Update App Code**

#### **Step 4.1: Enhanced Storage Service**
The storage service has been updated with:
- ✅ **Better error handling**
- ✅ **Simplified storage paths**
- ✅ **Comprehensive logging**
- ✅ **Connection testing**

#### **Step 4.2: Improved Upload Process**
The upload process now:
- ✅ **Uses StorageService** instead of direct Firebase calls
- ✅ **Validates files** before upload
- ✅ **Provides detailed logging**
- ✅ **Handles errors gracefully**

## 🧪 **Testing the Fixes**

### **Test 1: Firebase Connection**
1. **Run the app** with debug mode
2. **Open New Entry** screen
3. **Watch console** for Firebase connection test

**Expected Output:**
```
NewEntryScreen: Testing Firebase Storage connection...
StorageService: Testing Firebase Storage connection...
StorageService: App name: [DEFAULT]
StorageService: Storage bucket: diaryproject-f6b60.firebasestorage.app
StorageService: Root reference created successfully
NewEntryScreen: Firebase Storage connection test: ✅ SUCCESS
```

### **Test 2: Voice Recording**
1. **Tap microphone** button
2. **Record 10-15 seconds** of speech
3. **Stop recording**

**Expected Output:**
```
VoiceService: Recording to path: /path/to/voice_notes/voice_note_1234567890.m4a
VoiceService: Validating recorded audio file...
VoiceService: File path: /path/to/voice_notes/voice_note_1234567890.m4a
VoiceService: File exists: true
VoiceService: File size: 45.2 KB
VoiceService: ✅ Audio file ready: /path/to/voice_notes/voice_note_1234567890.m4a (45.2 KB)
VoiceService: Notifying NewEntryScreen about ready audio file...
VoiceService: ✅ Audio file notification sent successfully
```

### **Test 3: File Upload**
1. **Save the entry** with the voice recording
2. **Watch console** for upload process

**Expected Output:**
```
=== AUDIO UPLOAD DEBUG ===
Starting upload of 1 audio files
Audio file paths: [/path/to/voice_notes/voice_note_1234567890.m4a]
User ID: [actual-user-id]
Entry ID: [actual-entry-id]

--- Checking audio file 0 ---
Audio path: /path/to/voice_notes/voice_note_1234567890.m4a
File exists: true
File size: 45.2 KB
File path type: String
File absolute path: [absolute-path]
✅ File validated successfully: /path/to/voice_notes/voice_note_1234567890.m4a
Added audio file to upload queue: /path/to/voice_notes/voice_note_1234567890.m4a

--- Upload Summary ---
Valid audio files to upload: 1
Upload futures count: 1
Starting parallel upload of 1 files...

NewEntryScreen: Starting file upload via StorageService...
NewEntryScreen: File: /path/to/voice_notes/voice_note_1234567890.m4a
NewEntryScreen: User ID: [actual-user-id], Entry ID: [actual-entry-id]

StorageService: Starting file upload...
StorageService: File path: /path/to/voice_notes/voice_note_1234567890.m4a
StorageService: User ID: [actual-user-id]
StorageService: Entry ID: [actual-entry-id]
StorageService: File size: 45.2 KB
StorageService: Storage path: audio_files/[user-id]/[entry-id]/[timestamp]_voice_note_1234567890.m4a
StorageService: Storage bucket: diaryproject-f6b60.firebasestorage.app
StorageService: Upload task created, waiting for completion...
StorageService: ✅ Upload successful!
StorageService: Download URL: https://firebasestorage.googleapis.com/...

NewEntryScreen: ✅ File upload completed successfully
NewEntryScreen: Download URL: https://firebasestorage.googleapis.com/...

✅ Successfully uploaded 1 audio files
Audio URLs: [https://firebasestorage.googleapis.com/...]
```

## 🚨 **If Issues Persist**

### **Check 1: Firebase Console**
1. **Verify** Firestore database exists
2. **Verify** Storage is enabled
3. **Check** storage rules are published
4. **Verify** project ID matches in config files

### **Check 2: Network & Permissions**
1. **Ensure** device has internet access
2. **Check** app has storage permissions
3. **Verify** Firebase API keys are valid
4. **Check** if using VPN or proxy

### **Check 3: App Configuration**
1. **Verify** `google-services.json` is in `android/app/`
2. **Verify** `GoogleService-Info.plist` is in `ios/Runner/` (if iOS)
3. **Check** Firebase dependencies in `pubspec.yaml`
4. **Ensure** app is signed with correct keystore

## 📱 **Manual Verification Steps**

### **Step 1: Check Firebase Console**
1. **Go to** [Firebase Console](https://console.firebase.google.com/)
2. **Select** project `diaryproject-f6b60`
3. **Verify** both Firestore and Storage are enabled
4. **Check** that rules are published

### **Step 2: Test Storage Rules**
1. **In Storage Rules**, temporarily set to test mode:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true; // WARNING: Only for testing!
    }
  }
}
```

2. **Test upload** - if it works, the issue is in rules
3. **Restore** proper rules after testing

### **Step 3: Check Project Settings**
1. **In Firebase Console**, go to **Project Settings**
2. **Verify** project ID: `diaryproject-f6b60`
3. **Check** storage bucket: `diaryproject-f6b60.firebasestorage.app`
4. **Ensure** app is registered for your platform

## 🎯 **Expected Results After Fixes**

After implementing these fixes:

1. ✅ **Firebase Storage connection** will work
2. ✅ **Voice recordings** will upload successfully
3. ✅ **Audio files** will be accessible in saved entries
4. ✅ **No more** "object-not-found" errors
5. ✅ **No more** "database does not exist" errors

## 📞 **Getting Help**

If you still encounter issues:

1. **Share** the complete console output
2. **Confirm** Firestore database is created
3. **Confirm** Storage is enabled
4. **Share** any new error messages
5. **Test** with the simplified storage rules first

The fixes implemented should resolve both the Firebase Storage and Firestore database issues, allowing your audio files to upload successfully to diary entries.
