import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:file_picker/file_picker.dart';

class FilePickerHelper {
  static Future<String?> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
      );

      if (result != null) {
        return result.files.single.name; // Retorna el nombre del archivo
      }
    } catch (e) {
      print("Error al seleccionar archivo: $e");
    }
    return null;
  }
}
