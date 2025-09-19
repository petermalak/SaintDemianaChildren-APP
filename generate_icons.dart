import 'dart:io';

void main() async {
  print('🎨 Generating app icons...');
  
  try {
    // Run flutter_launcher_icons
    final result = await Process.run(
      'flutter',
      ['pub', 'get'],
      workingDirectory: Directory.current.path,
    );
    
    if (result.exitCode == 0) {
      print('✅ Dependencies installed successfully');
      
      final iconResult = await Process.run(
        'flutter',
        ['pub', 'run', 'flutter_launcher_icons:main'],
        workingDirectory: Directory.current.path,
      );
      
      if (iconResult.exitCode == 0) {
        print('✅ App icons generated successfully!');
        print('📱 Icons are now available for Android, iOS, Web, Windows, and macOS');
      } else {
        print('❌ Error generating icons: ${iconResult.stderr}');
      }
    } else {
      print('❌ Error installing dependencies: ${result.stderr}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
