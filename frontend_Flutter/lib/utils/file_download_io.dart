import 'dart:io';
import 'package:file_picker/file_picker.dart';

Future<void> downloadJsonFile({
  required String jsonStr,
  required String fileName,
}) async {
  final result = await FilePicker.platform.saveFile(
    dialogTitle: '保存备份文件',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  if (result != null) {
    final file = File(result);
    await file.writeAsString(jsonStr);
  }
}
