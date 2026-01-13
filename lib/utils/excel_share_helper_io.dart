
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareExcelBytes(Uint8List bytes, String filename, {String? text}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);

  await Share.shareXFiles(
    [XFile(file.path)],
    text: text,
  );
}
