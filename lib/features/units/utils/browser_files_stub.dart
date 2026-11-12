import 'dart:typed_data';

import 'package:emam_admin_web_app/features/units/utils/picked_file.dart';

Future<PickedFile?> pickFile({String accept = ''}) =>
    throw UnsupportedError('Choosing files works in the web build only.');

void saveBytes(Uint8List bytes, String fileName, String mimeType) =>
    throw UnsupportedError('Saving files works in the web build only.');
