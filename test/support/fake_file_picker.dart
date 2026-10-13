import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Stands in for the system file dialogs, which cannot open in a test.
class FakeFilePicker extends FilePicker {
  FakeFilePicker({
    this.savePath,
    this.openFile,
    this.throwOnSave = false,
    this.hang = false,
  });

  /// What the save dialog returns; null means the user cancelled.
  final String? savePath;

  /// What the open dialog returns.
  final PlatformFile? openFile;

  /// Whether the save dialog fails, as it does with no file manager.
  final bool throwOnSave;

  /// Whether the dialog never answers, as it does with no dialog service.
  final bool hang;

  /// The bytes the save dialog was handed, if any. A backup must never be
  /// passed this way, because the zip does not fit in memory.
  Uint8List? savedBytes;
  bool exported = false;

  /// A future that never completes, to stand in for a dialog that hangs.
  Future<T> _never<T>() => Completer<T>().future;

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    if (hang) return _never();
    if (throwOnSave) throw Exception('no file manager');
    exported = true;
    savedBytes = bytes;
    return savePath;
  }

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    int compressionQuality = 0,
  }) async {
    if (hang) return _never();
    if (openFile == null) return null;
    return FilePickerResult([openFile!]);
  }
}
