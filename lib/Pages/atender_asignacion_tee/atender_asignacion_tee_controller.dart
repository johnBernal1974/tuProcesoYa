
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AtenderSolicitudAsignacionTEEAdminController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> actualizarSolicitud(
      BuildContext context,
      String docId,
      Map<String, dynamic> nuevosDatos,
      ) async {
    try {
      await _firestore
          .collection('asignacionTEE_solicitados')
          .doc(docId)
          .update(nuevosDatos);

      print("✅ Solicitud actualizada correctamente");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Solicitud actualizada exitosamente"),
        ),
      );
    } catch (e) {
      print("❌ Error al actualizar la solicitud: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al actualizar la solicitud"),
        ),
      );
    }
  }
}
