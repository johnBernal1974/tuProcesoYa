import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../src/colors/colors.dart';

/// ✅ Helper para lógica de descuentos
class DescuentoHelper {
  /// Verifica si el usuario tiene derecho a descuento por referido
  static Future<bool> tieneDescuento(String uid) async {
    final doc = await FirebaseFirestore.instance.collection("Ppl").doc(uid).get();
    if (!doc.exists) return false;

    final referidoPor = doc.data()?["referidoPor"];
    return referidoPor == "355";
  }

  /// Verifica si se puede asignar un descuento personalizado
  static Future<bool> puedeAsignarDescuento(String uid) async {
    final doc = await FirebaseFirestore.instance.collection("Ppl").doc(uid).get();
    if (!doc.exists) return false;

    final referidoPor = doc.data()?["referidoPor"];
    return referidoPor != "355";
  }

  /// Aplica el descuento del 20% si corresponde
  static Future<int> obtenerValorConDescuento(String uid, int valorOriginal) async {
    final tiene = await tieneDescuento(uid);

    if (tiene) {
      final descuento = (valorOriginal * 0.20).round();
      return valorOriginal - descuento;
    }

    // ✅ Si tiene descuento personalizado
    final datos = await obtenerDescuentoPersonalizado(uid);
    if (datos != null && datos.containsKey("porcentaje")) {
      final porcentaje = datos["porcentaje"] as int;
      final descuento = (valorOriginal * (porcentaje / 100)).round();
      return valorOriginal - descuento;
    }

    return valorOriginal;
  }

  /// Guarda un descuento personalizado otorgado por un admin
  static Future<void> otorgarDescuento({
    required String uidUsuario,
    required int porcentaje,
    required String uidAdmin,
  }) async {
    await FirebaseFirestore.instance.collection('Ppl').doc(uidUsuario).set({
      "descuento": {
        "porcentaje": porcentaje,
        "fecha": FieldValue.serverTimestamp(),
        "otorgadoPor": uidAdmin,
      }
    }, SetOptions(merge: true));
  }

  /// Obtiene los datos de descuento personalizado (si existen)
  static Future<Map<String, dynamic>?> obtenerDescuentoPersonalizado(String uid) async {
    final doc = await FirebaseFirestore.instance.collection("Ppl").doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?["descuento"];
  }
}

/// ✅ Card visual que muestra el descuento aplicado (solo visual)
class CardDescuento extends StatelessWidget {
  final int valorDescuento;

  const CardDescuento({super.key, required this.valorDescuento});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,###", "es_CO");

    return Card(
      color: blanco,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Image.asset(
              'assets/images/regalo.png',
              width: 50,
              height: 50,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Tienes un 20% de descuento en tu suscripción.\n\nAhorrarás \$${formatter.format(valorDescuento)} en este pago.",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
