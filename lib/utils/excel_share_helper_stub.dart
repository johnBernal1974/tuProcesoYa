
import 'dart:typed_data';

Future<void> shareExcelBytes(Uint8List bytes, String filename, {String? text}) async {
  // En Web no se comparte como archivo con File.
  // Aquí no hacemos nada (en web usas downloadExcel()).
}
