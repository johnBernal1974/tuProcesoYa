import 'package:cloud_firestore/cloud_firestore.dart';

class ResumenSolicitudesService {
  static Future<void> guardarResumen({
    required String idUser,
    required String nombrePpl,
    required String tipo,
    required String numeroSeguimiento,
    required String status,
    required String idOriginal,
    required String origen,
    required Timestamp fecha,
  }) async {
    await FirebaseFirestore.instance.collection('solicitudes_usuario').add({
      'idUser': idUser,
      'nombrePpl': nombrePpl,
      'tipo': tipo,
      'numeroSeguimiento': numeroSeguimiento,
      'status': status,
      'fecha': fecha,
      'origen': origen,
      'idOriginal': idOriginal,
    });
  }
}
