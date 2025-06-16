import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CardEstadoPruebaYPago extends StatelessWidget {
  final DocumentSnapshot doc;
  final int? tiempoDePruebaDias;

  const CardEstadoPruebaYPago({
    super.key,
    required this.doc,
    required this.tiempoDePruebaDias,
  });

  DateTime? _convertirTimestampADateTime(dynamic ts) {
    if (ts is Timestamp) return ts.toDate();
    if (ts is DateTime) return ts;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final isPaid = data['isPaid'] == true;

    Icon icono = const Icon(Icons.help_outline, color: Colors.grey, size: 20);
    String descripcion = "Usuario aún no ha sido activado";

    if (!data.containsKey('fechaActivacion')) {
      icono = const Icon(Icons.help_outline, color: Colors.grey, size: 20);
      descripcion = "Aún no ha sido activado";
    } else if (tiempoDePruebaDias == null) {
      icono = const Icon(Icons.hourglass_top, color: Colors.grey, size: 20);
      descripcion = "Cargando configuración de prueba...";
    } else {
      final fechaActivacion = _convertirTimestampADateTime(data['fechaActivacion']);
      if (fechaActivacion == null) {
        icono = const Icon(Icons.error_outline, color: Colors.red, size: 20);
        descripcion = "Fecha de activación inválida";
      } else {
        final diasDesdeActivacion = DateTime.now().difference(fechaActivacion).inDays;

        if (isPaid) {
          icono = const Icon(Icons.verified_user, color: Colors.green, size: 20);
          descripcion = "Pago realizado";
        } else if (diasDesdeActivacion < tiempoDePruebaDias!) {
          final diasRestantes = tiempoDePruebaDias! - diasDesdeActivacion;
          icono = const Icon(Icons.lock_clock, color: Colors.orange, size: 20);
          descripcion = "En prueba ($diasRestantes días restantes)";
        } else {
          icono = const Icon(Icons.lock_outline, color: Colors.red, size: 20);
          descripcion = "Prueba vencida sin pago";
        }
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end, // 🔹 Alinea a la derecha
      children: [
        Card(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.grey),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                icono,
                const SizedBox(width: 12),
                Text(
                  descripcion,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );


  }

}
