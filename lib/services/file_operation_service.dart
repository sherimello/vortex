import 'dart:io';
import 'package:logger/logger.dart';
import '../models/response_model.dart';

class FileOperationService {
  final Logger _logger = Logger();

  Future<CommandExecution> executeCommand(String command) async {
    try {
      _logger.i('Executing command: $command');

      final result = await Process.run(
        'cmd.exe',
        ['/c', command],
        runInShell: true,
        includeParentEnvironment: true,
      );

      final output = result.stdout.toString();
      final error = result.stderr.toString();

      _logger.i('Command output: $output');
      if (error.isNotEmpty) {
        _logger.w('Command error: $error');
      }

      return CommandExecution(
        command: command,
        output: output,
        error: error.isNotEmpty ? error : null,
        exitCode: result.exitCode,
        executedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.e('Error executing command: $e');
      return CommandExecution(
        command: command,
        output: '',
        error: e.toString(),
        exitCode: 1,
        executedAt: DateTime.now(),
      );
    }
  }

  // Writes script to a temp .ps1 file and runs it so PowerShell here-strings
  // and multi-line constructs work correctly.
  Future<CommandExecution> executePowerShellScript(String script) async {
    final tempPath =
        '${Directory.systemTemp.path}\\vortex_${DateTime.now().millisecondsSinceEpoch}.ps1';
    final tempFile = File(tempPath);
    try {
      await tempFile.writeAsString(script);
      _logger.i('Running PowerShell script: $tempPath');

      final result = await Process.run(
        'powershell.exe',
        [
          '-NonInteractive',
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-File',
          tempPath,
        ],
        includeParentEnvironment: true,
      );

      final output = result.stdout.toString();
      final error = result.stderr.toString();

      _logger.i('Script output: $output');
      if (error.isNotEmpty) _logger.w('Script error: $error');

      return CommandExecution(
        command: script,
        output: output,
        error: error.isNotEmpty ? error : null,
        exitCode: result.exitCode,
        executedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.e('Error running PowerShell script: $e');
      return CommandExecution(
        command: script,
        output: '',
        error: e.toString(),
        exitCode: 1,
        executedAt: DateTime.now(),
      );
    } finally {
      try {
        await tempFile.delete();
      } catch (_) {}
    }
  }

  Future<bool> fileExists(String path) async {
    try {
      return await File(path).exists();
    } catch (e) {
      _logger.e('Error checking file: $e');
      return false;
    }
  }

  Future<bool> dirExists(String path) async {
    try {
      return await Directory(path).exists();
    } catch (e) {
      _logger.e('Error checking directory: $e');
      return false;
    }
  }

  Future<String> readFile(String path) async {
    try {
      return await File(path).readAsString();
    } catch (e) {
      _logger.e('Error reading file: $e');
      return 'Error: $e';
    }
  }

  Future<void> writeFile(String path, String content) async {
    try {
      await File(path).writeAsString(content);
      _logger.i('File written: $path');
    } catch (e) {
      _logger.e('Error writing file: $e');
      rethrow;
    }
  }

  Future<void> createDirectory(String path) async {
    try {
      await Directory(path).create(recursive: true);
      _logger.i('Directory created: $path');
    } catch (e) {
      _logger.e('Error creating directory: $e');
      rethrow;
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      await File(path).delete();
      _logger.i('File deleted: $path');
    } catch (e) {
      _logger.e('Error deleting file: $e');
      rethrow;
    }
  }

  Future<void> deleteDirectory(String path) async {
    try {
      await Directory(path).delete(recursive: true);
      _logger.i('Directory deleted: $path');
    } catch (e) {
      _logger.e('Error deleting directory: $e');
      rethrow;
    }
  }

  Future<List<FileSystemEntity>> listDirectory(String path) async {
    try {
      return await Directory(path).list().toList();
    } catch (e) {
      _logger.e('Error listing directory: $e');
      return [];
    }
  }

  Future<void> openApplication(String appPath) async {
    try {
      await Process.start(
        appPath,
        [],
        runInShell: true,
        includeParentEnvironment: true,
      );
      _logger.i('Application opened: $appPath');
    } catch (e) {
      _logger.e('Error opening application: $e');
      rethrow;
    }
  }
}
