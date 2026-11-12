@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:emam_admin_web_app/features/units/utils/browser_files.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

web.HTMLInputElement? _fileInput() =>
    web.document.querySelector('input[type=file]') as web.HTMLInputElement?;

void main() {
  test('a chosen file is read into bytes', () async {
    final picked = pickFile(accept: '.apk');
    final input = _fileInput()!;
    expect(input.accept, '.apk');

    final transfer = web.DataTransfer();
    transfer.items.add(
      web.File(
        <JSAny>[
          Uint8List.fromList([1, 2, 3]).toJS,
        ].toJS,
        'emam.apk',
      ),
    );
    input.files = transfer.files;
    input.dispatchEvent(web.Event('change'));

    final file = await picked;
    expect(file!.name, 'emam.apk');
    expect(file.bytes, [1, 2, 3]);
    expect(_fileInput(), isNull);
  });

  test('closing the chooser without a file gives null', () async {
    final picked = pickFile();
    _fileInput()!.dispatchEvent(web.Event('cancel'));

    expect(await picked, isNull);
    expect(_fileInput(), isNull);
  });

  test('bytes are handed to the browser as a download', () {
    String? downloaded;
    final onClick = ((web.Event event) {
      final target = event.target;
      if (target != null && target.isA<web.HTMLAnchorElement>()) {
        downloaded = (target as web.HTMLAnchorElement).download;
      }
      // Keep the test from saving a real file.
      event.preventDefault();
    }).toJS;
    web.document.addEventListener('click', onClick, true.toJS);
    addTearDown(
      () => web.document.removeEventListener('click', onClick, true.toJS),
    );

    saveBytes(Uint8List(44), 'recording.wav', 'audio/wav');

    expect(downloaded, 'recording.wav');
    expect(web.document.querySelector('a[download]'), isNull);
  });
}
