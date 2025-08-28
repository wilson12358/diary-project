# Login Troubleshooting Guide

## 🔍 **Common Login Issues and Solutions**

### **1. Login Button Not Responding**
**Symptoms:** Tapping login button does nothing
**Solutions:**
- Check if Firebase is properly initialized in `main.dart`
- Verify internet connection
- Check Firebase project configuration
- Enable debug mode to see console logs

### **2. "User Not Found" Error**
**Symptoms:** Error message: "No user found with this email address"
**Solutions:**
- Verify the email address is correct
- Check if user account exists in Firebase Console
- Try creating a new account first
- Ensure Firebase Authentication is enabled

### **3. "Wrong Password" Error**
**Symptoms:** Error message: "Incorrect password"
**Solutions:**
- Double-check password spelling and case sensitivity
- Use password reset if forgotten
- Check for extra spaces in password field

### **4. "Operation Not Allowed" Error**
**Symptoms:** Error message: "Email/password sign-in is not enabled"
**Solutions:**
- Enable Email/Password authentication in Firebase Console
- Go to Firebase Console > Authentication > Sign-in method
- Enable Email/Password provider

### **5. Loading State Stuck**
**Symptoms:** Loading indicator shows indefinitely
**Solutions:**
- Check network connectivity
- Verify Firebase configuration
- Check console for error messages
- Force close and restart the app

## 🛠️ **Debugging Steps**

### **Step 1: Enable Debug Logging**
```dart
// In main.dart, add this before runApp():
AuthDebugHelper.setDebugMode(true);
```

### **Step 2: Check Firebase Configuration**
1. Verify `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in the correct location
2. Check Firebase project ID matches your app
3. Ensure API keys are valid

### **Step 3: Test with Console Logs**
Look for these debug messages in the console:
- "AuthService initialized"
- "Attempting sign in"
- "Sign in successful" or error messages

### **Step 4: Firebase Console Verification**
1. Go to Firebase Console
2. Check Authentication > Users tab
3. Verify if test users exist
4. Check Authentication > Settings for configuration

## 📋 **Testing Checklist**

- [ ] Firebase project is properly configured
- [ ] Internet connection is stable
- [ ] Email/Password authentication is enabled in Firebase
- [ ] Test user account exists in Firebase
- [ ] App has latest Firebase configuration files
- [ ] No console errors during login attempt
- [ ] Form validation passes (valid email format, password length)

## 🔧 **Quick Fixes**

### **Fix 1: Restart Firebase Connection**
```bash
flutter clean
flutter pub get
```

### **Fix 2: Re-download Firebase Config**
1. Go to Firebase Console > Project Settings
2. Download latest `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)
3. Replace the existing file in your project

### **Fix 3: Test with Known Working Credentials**
Create a test account in Firebase Console and try logging in with those credentials.

## 📱 **App-Specific Debug Features**

The app now includes enhanced debugging:

1. **AuthDebugHelper**: Logs all authentication events
2. **Better Error Messages**: User-friendly error descriptions
3. **Mounted Checks**: Prevents setState errors
4. **Comprehensive Logging**: Tracks sign-in attempts and failures

## 🚨 **If Nothing Works**

1. Check if Firebase services are down: https://status.firebase.google.com/
2. Try logging in with Firebase SDK directly in a test project
3. Contact Firebase support if configuration issues persist
4. Check for any regional restrictions or firewall issues

## 📞 **Getting Help**

When asking for help, provide:
1. Exact error messages from console
2. Firebase project ID (without sensitive info)
3. Steps you've already tried
4. Platform (iOS/Android) and device info
5. Debug logs from AuthDebugHelper
