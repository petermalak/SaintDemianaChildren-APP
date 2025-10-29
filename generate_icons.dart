import 'dart:io';

void main() async {


    final result = await Process.run(
      'flutter',
      ['pub', 'get'],
      workingDirectory: Directory.current.path,
    );
    
    if (result.exitCode == 0) {
      await Process.run(
        'flutter',
        ['pub', 'run', 'flutter_launcher_icons:main'],
        workingDirectory: Directory.current.path,
      );
    }
}
