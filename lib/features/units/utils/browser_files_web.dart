import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:emam_admin_web_app/features/units/utils/picked_file.dart';
import 'package:web/web.dart' as web;

/// Opens the browser's file chooser; null when the user cancels.
Future<PickedFile?> pickFile({String accept = ''}) {
  final completer = Completer<PickedFile?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = accept;
  input.style.display = 'none';
  web.document.body?.appendChild(input);

  void finish(PickedFile? file) {
    input.remove();
    if (!completer.isCompleted) completer.complete(file);
  }

  input.onChange.first.then((_) async {
    final file = input.files?.item(0);
    if (file == null) {
      finish(null);
      return;
    }
    try {
      final buffer = await file.arrayBuffer().toDart;
      finish(PickedFile(name: file.name, bytes: buffer.toDart.asUint8List()));
    } catch (error, stack) {
      input.remove();
      if (!completer.isCompleted) completer.completeError(error, stack);
    }
  });
  web.EventStreamProviders.cancelEvent
      .forTarget(input)
      .first
      .then((_) => finish(null));
  input.click();
  return completer.future;
}

/// Hands [bytes] to the browser as a download named [fileName].
void saveBytes(Uint8List bytes, String fileName, String mimeType) {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  Timer(const Duration(minutes: 1), () => web.URL.revokeObjectURL(url));
}
