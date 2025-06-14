import 'package:cloud_firestore/cloud_firestore.dart';

class ResumenSolicitudesHelper {
  /// Actualiza el resumen correspondiente al ID de solicitud y origen
  static Future<void> actualizarResumen({
    required String idOriginal,
    required String nuevoStatus,
    required String origen,
  }) async {
    try {
      final resumenSnapshot = await FirebaseFirestore.instance
          .collection('solicitudes_usuario')
          .where('idOriginal', isEqualTo: idOriginal)
          .where('origen', isEqualTo: origen)
          .limit(1)
          .get();

      if (resumenSnapshot.docs.isNotEmpty) {
        final resumenDocId = resumenSnapshot.docs.first.id;
        await FirebaseFirestore.instance
            .collection('solicitudes_usuario')
            .doc(resumenDocId)
            .update({
          'status': nuevoStatus,
          'fecha': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("❌ Error al actualizar el resumen de solicitud: $e");
    }
  }
}
