import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart';

Future<void> downloadJsonFile({
  required String jsonStr,
  required String fileName,
}) async {
  final bytes = utf8.encode(jsonStr);
  final blob = Blob(
    [bytes.toJS].toJS,
    BlobPropertyBag(type: 'application/json'),
  );
  final url = URL.createObjectURL(blob);
  final anchor =
      document.createElement('a') as HTMLAnchorElement
        ..href = url
        ..download = fileName;
  document.body!.appendChild(anchor);
  anchor.click();
  document.body!.removeChild(anchor);
  URL.revokeObjectURL(url);
}
