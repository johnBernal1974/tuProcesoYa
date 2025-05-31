import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';

import '../src/colors/colors.dart';


class DetalleCorreoPage extends StatelessWidget {
  final Map<String, dynamic> correo;

  const DetalleCorreoPage({super.key, required this.correo});

  @override
  Widget build(BuildContext context) {
    final remitente = (correo['remitente'] ?? 'Desconocido').toString();
    final asunto = (correo['asunto'] ?? 'Sin asunto').toString();
    final para = (correo['destinatario'] ?? 'Desconocido').toString();
    final recibidoEnRaw = correo['recibidoEn'];
    DateTime? recibidoDateTime;

    if (recibidoEnRaw is String) {
      recibidoDateTime = DateTime.tryParse(recibidoEnRaw);
    } else if (recibidoEnRaw is Timestamp) {
      recibidoDateTime = recibidoEnRaw.toDate();
    }

    final recibidoEn = recibidoDateTime != null
        ? DateFormat("d 'de' MMMM 'de' yyyy - h:mm a", 'es')
        .format(recibidoDateTime)
        .replaceAll('a. m.', 'am')
        .replaceAll('p. m.', 'pm')
        : 'Fecha desconocida';

    final cuerpo = (correo['cuerpo'] ?? '').toString().trim();
    final cuerpoHtml = (correo['cuerpoHtml'] ?? '').toString().trim();

    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
        title: const Text('Detalle del correo'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ListView(
              children: [
                Text(asunto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('De: $remitente', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Text('Para: $para', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.deepPurple),
                    const SizedBox(width: 4),
                    Text('Recibido: $recibidoEn', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.black54, height: 1),
                const SizedBox(height: 12),
                cuerpoHtml.isNotEmpty
                    ? Html(
                  data: cuerpoHtml,
                  style: {
                    "body": Style(
                      fontSize: FontSize(13),
                      color: Colors.black,
                      padding: HtmlPaddings.zero,
                      margin: Margins.zero,
                      fontFamily: 'Arial',
                    ),
                  },
                )
                    : Text(
                  cuerpo,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),

    );
  }
}
