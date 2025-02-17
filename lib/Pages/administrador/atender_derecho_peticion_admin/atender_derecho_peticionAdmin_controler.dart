import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AtenderDerechoPeticionAdminController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> actualizarSolicitud(BuildContext context, String docId, Map<String, dynamic> nuevosDatos) async {
    try {
      await _firestore.collection('derechos_peticion_solicitados').doc(docId).update(nuevosDatos);
      print("✅ Solicitud actualizada correctamente");

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Solicitud actualizada exitosamente"))
      );
    } catch (e) {
      print("❌ Error al actualizar la solicitud: $e");

      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al actualizar la solicitud"))
      );
    }
  }
}
