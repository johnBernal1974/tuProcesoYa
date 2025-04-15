import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class ArchivoUploader {
  static Future<String?> subirArchivo({
    required PlatformFile file,
    required String rutaDestino,
  }) async {
    try {
      Reference storageRef = FirebaseStorage.instance.ref(rutaDestino);

      final metadata = SettableMetadata(
        contentType: _getContentType(file.name),
        contentDisposition: 'inline', // 👈 evita descarga automática
      );

      UploadTask uploadTask = kIsWeb
          ? storageRef.putData(file.bytes!, metadata)
          : storageRef.putFile(File(file.path!), metadata);

      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error subiendo archivo: $e');
      }
      return null;
    }
  }

  static String _getContentType(String fileName) {
    final ext = fileName.toLowerCase();
    if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) return 'image/jpeg';
    if (ext.endsWith('.png')) return 'image/png';
    if (ext.endsWith('.gif')) return 'image/gif';
    if (ext.endsWith('.webp')) return 'image/webp';
    if (ext.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream'; // por defecto
  }
}
