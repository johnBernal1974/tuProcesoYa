import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:tuprocesoya/src/colors/colors.dart';

class DetalleCorreoTrasladoProcesoPage extends StatelessWidget {
  final String idDocumento;
  final String correoId;

  const DetalleCorreoTrasladoProcesoPage({
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
        title: const Text(
          "Detalle del correo",
          style: TextStyle(color: blanco),
        ),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('trasladoProceso_solicitados')
            .doc(idDocumento)
            .collection('log_correos')
            .doc(correoId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "No se encontró información del correo.",
                style: TextStyle(fontSize: 13),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final to = (data['to'] as List?)?.join(', ') ?? data['destinatario'] ?? 'Desconocido';
          final remitente = data['remitente'] ?? 'peticiones@tuprocesoya.com';
          final cc = (data['cc'] as List?)?.join(', ') ?? '';
          final subject = data['subject'] ?? data['asunto'] ?? 'Sin asunto';
          final htmlContent = data['html'] ?? data['cuerpoHtml'] ?? '';
          final archivos = data['archivos'] as List? ?? [];

          final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
          final fechaEnvio = timestamp != null
              ? DateFormat("dd MMM yyyy - hh:mm a", 'es').format(timestamp)
              : 'Fecha no disponible';

          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: textScale),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: ListView(
                    children: [
                      Text(
                        subject,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "De: $remitente",
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Para: $to",
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (cc.isNotEmpty)
                        Text(
                          "CC: $cc",
                          style: const TextStyle(fontSize: 13),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Fecha de envío: $fechaEnvio",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Colors.black54),
                      const SizedBox(height: 12),
                      htmlContent.isNotEmpty
                          ? Html(
                        data: htmlContent,
                        style: {
                          "body": Style(
                            fontSize: FontSize(13),
                            color: Colors.black,
                            fontFamily: 'Arial',
                            padding: HtmlPaddings.zero,
                            margin: Margins.zero,
                          ),
                        },
                      )
                          : const Text(
                        "Este correo no tiene contenido HTML.",
                        style: TextStyle(fontSize: 13),
                      ),
                      if (archivos.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const Text(
                          "Archivos adjuntos:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...archivos.map((a) {
                          final nombre = a['nombre'] ?? 'Archivo';
                          final url = a['url'] ?? '';
                          return Text(
                            "- $nombre ($url)",
                            style: const TextStyle(fontSize: 12),
                          );
                        }),
                      ],
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          child: const Text("Cerrar"),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
