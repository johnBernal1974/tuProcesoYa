import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/src/colors/colors.dart';
import 'package:flutter_html/flutter_html.dart';

class DetalleCorreoAcumulacionPage extends StatelessWidget {
  final String idDocumento;
  final String correoId;

  const DetalleCorreoAcumulacionPage({
    super.key,
    required this.idDocumento,
    required this.correoId,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final horizontalPadding = isMobile ? 8.0 : 24.0;
    final textScale = isMobile ? 0.9 : 1.0;

    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
        title: const Text("Detalle del correo", style: TextStyle(color: blanco)),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('acumulacion_solicitados')
            .doc(idDocumento)
            .collection('log_correos')
            .doc(correoId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No se encontró información del correo."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final to = (data['to'] as List?)?.join(', ') ?? '';
          final cc = (data['cc'] as List?)?.join(', ') ?? '';
          final contenido = data['html'] ?? '';
          final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
          final fechaEnvio = timestamp != null
              ? DateFormat("d 'de' MMMM 'de' y hh:mm a", 'es').format(timestamp)
              : 'Fecha no disponible';

          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: textScale),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("De: peticiones@tuprocesoya.com", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  if (to.isNotEmpty) Text("Para: $to", style: const TextStyle(fontSize: 13)),
                  if (cc.isNotEmpty) Text("CC: $cc", style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Text("\uD83D\uDCC5 Enviado: $fechaEnvio", style: const TextStyle(fontSize: 12)),
                  const Divider(color: gris),
                  const SizedBox(height: 12),
                  Html(
                    data: contenido,
                    style: {
                      "body": Style(
                        fontSize: FontSize(14),
                        textAlign: TextAlign.start,
                        color: Colors.black,
                      ),
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
