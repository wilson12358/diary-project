import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Debug utility specifically for iOS Simulator text input issues
class SimulatorDebug {
  
  /// Check for iOS Simulator specific issues
  static void checkSimulatorTextInput() {
    debugPrint('=== iOS SIMULATOR TEXT INPUT CHECK ===');
    
    // Check if running on simulator
    debugPrint('Platform: ${defaultTargetPlatform}');
    debugPrint('Debug mode: ${kDebugMode}');
    debugPrint('Profile mode: ${kProfileMode}');
    debugPrint('Release mode: ${kReleaseMode}');
    
    // Check text input configuration
    debugPrint('Text input channel available: ${ServicesBinding.instance.defaultBinaryMessenger != null}');
    
    debugPrint('==========================================');
  }
  
  /// Force enable hardware keyboard for simulator
  static void enableHardwareKeyboard() {
    debugPrint('=== ENABLING HARDWARE KEYBOARD ===');
    debugPrint('For iOS Simulator:');
    debugPrint('1. In Simulator menu: Device > Keyboard > Connect Hardware Keyboard');
    debugPrint('2. Or press Cmd+Shift+K');
    debugPrint('3. Make sure "Software Keyboard" is also enabled');
    debugPrint('===================================');
  }
  
  /// Check focus and text editing service
  static void checkTextEditingService() {
    debugPrint('=== TEXT EDITING SERVICE CHECK ===');
    
    try {
      // Check if text input is available
      final textInput = ServicesBinding.instance.defaultBinaryMessenger;
      debugPrint('✅ Binary messenger available: ${textInput != null}');
      
      // Check focus manager
      final focusManager = WidgetsBinding.instance.focusManager;
      debugPrint('✅ Focus manager available: ${focusManager != null}');
      debugPrint('   Primary focus: ${focusManager.primaryFocus}');
      debugPrint('   Highlight mode: ${focusManager.highlightMode}');
      
    } catch (e) {
      debugPrint('❌ Error checking text editing service: $e');
    }
    
    debugPrint('==================================');
  }
  
  /// Test direct text input
  static void testDirectTextInput(TextEditingController controller) {
    debugPrint('=== DIRECT TEXT INPUT TEST ===');
    
    try {
      // Test setting text directly
      final testText = 'Test from simulator debug';
      controller.text = testText;
      debugPrint('✅ Direct text setting: "${controller.text}"');
      
      // Test selection
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
      debugPrint('✅ Selection set: ${controller.selection}');
      
    } catch (e) {
      debugPrint('❌ Error in direct text test: $e');
    }
    
    debugPrint('==============================');
  }
  
  /// Create a simple test text field widget
  static Widget createTestTextField() {
    final controller = TextEditingController();
    
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SIMULATOR DEBUG TEST FIELD',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Test typing here...',
              border: OutlineInputBorder(),
              fillColor: Colors.yellow.withOpacity(0.3),
              filled: true,
            ),
            onTap: () {
              debugPrint('🔥 TEST FIELD TAPPED');
              SimulatorDebug.checkTextEditingService();
            },
            onChanged: (text) {
              debugPrint('🔥 TEST FIELD CHANGED: "$text"');
            },
            autofocus: false,
            enableSuggestions: true,
            autocorrect: true,
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              SimulatorDebug.testDirectTextInput(controller);
            },
            child: Text('Test Direct Input'),
          ),
          ElevatedButton(
            onPressed: () {
              SimulatorDebug.enableHardwareKeyboard();
            },
            child: Text('Show Keyboard Help'),
          ),
        ],
      ),
    );
  }
  
  /// Complete simulator debugging
  static void runSimulatorDiagnostics() {
    debugPrint('🔍 Starting iOS Simulator Diagnostics...\n');
    
    checkSimulatorTextInput();
    checkTextEditingService();
    enableHardwareKeyboard();
    
    debugPrint('\n📱 Simulator Text Input Troubleshooting:');
    debugPrint('1. Check if hardware keyboard is connected (Cmd+Shift+K)');
    debugPrint('2. Try toggling software keyboard on/off');
    debugPrint('3. Check if simulator has focus (click on simulator window)');
    debugPrint('4. Try restarting simulator');
    debugPrint('5. Check macOS keyboard settings');
    
    debugPrint('\n🔧 Quick Fixes:');
    debugPrint('• Simulator > Device > Keyboard > Connect Hardware Keyboard');
    debugPrint('• Simulator > Device > Keyboard > Toggle Software Keyboard');
    debugPrint('• Make sure simulator window has focus');
    debugPrint('• Try Cmd+K to toggle keyboard');
  }
  
  /// Monitor for simulator-specific text input issues
  static void monitorSimulatorTextInput(String fieldName, TextEditingController controller) {
    debugPrint('📱 Monitoring simulator text input for: $fieldName');
    
    controller.addListener(() {
      debugPrint('📱 SIMULATOR $fieldName changed: "${controller.text}" (${controller.text.length} chars)');
      debugPrint('   Selection: ${controller.selection}');
      debugPrint('   Has focus: ${controller.selection.isValid}');
    });
  }
}
