import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/src/colors/colors.dart';
import 'package:http/http.dart' as http; // 👈 IMPORTANTE

class DetalleCorreoDomiciliariaPage extends StatelessWidget {
  final String idDocumento;
  final String correoId;

  const DetalleCorreoDomiciliariaPage({
    super.key,
    required this.idDocumento,
    required this.correoId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
        title: const Text("Detalle del correo"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('domiciliaria_solicitados')
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
                style: TextStyle(fontSize: 14),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final to = (data['to'] as List?)?.join(', ') ??
              data['destinatario'] ??
              'Desconocido';
          final remitente = data['remitente'] ?? 'peticiones@tuprocesoya.com';
          final cc = (data['cc'] as List?)?.join(', ') ?? '';
          final subject = data['subject'] ?? data['asunto'] ?? 'Sin asunto';

          // 👇 Igual que en Redenciones: inline primero y, si falta, intentar URL
          final String htmlInline =
          (data['html'] ?? data['cuerpoHtml'] ?? '').toString().trim();
          final String htmlUrl =
          (data['htmlUrl'] ?? data['html_url'] ?? '').toString().trim();

          final archivos = data['archivos'] as List? ?? [];

          final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
          final fechaEnvio = timestamp != null
              ? DateFormat("dd MMM yyyy - hh:mm a", 'es').format(timestamp)
              : 'Fecha no disponible';

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: ListView(
                  children: [
                    Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("De: $remitente", style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text("Para: $to", style: const TextStyle(fontSize: 13)),
                    if (cc.isNotEmpty)
                      Text("CC: $cc", style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: Colors.deepPurple),
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

                    // ==== Render robusto: inline -> url -> fallback ====
                    if (htmlInline.isNotEmpty) ...[
                      Html(
                        data: _sanitizeInlineEmailHtml(
                          _stripEnvelopeHtml(htmlInline),
                        ),
                        style: {
                          "body": Style(
                            fontSize: FontSize(13),
                            color: Colors.black,
                            fontFamily: 'Arial',
                            padding: HtmlPaddings.zero,
                            margin: Margins.zero,
                          ),
                        },
                      ),
                    ] else if (htmlUrl.isNotEmpty) ...[
                      FutureBuilder<http.Response>(
                        future: http.get(Uri.parse(htmlUrl)),
                        builder: (context, resp) {
                          if (resp.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: LinearProgressIndicator(),
                            );
                          }
                          if (!resp.hasData ||
                              resp.data!.statusCode != 200 ||
                              resp.data!.body.trim().isEmpty) {
                            return const Text(
                              "No se pudo cargar el contenido del correo.",
                              style: TextStyle(fontSize: 13),
                            );
                          }
                          final body = _sanitizeInlineEmailHtml(
                            _stripEnvelopeHtml(resp.data!.body),
                          );
                          return Html(
                            data: body,
                            style: {
                              "body": Style(
                                fontSize: FontSize(13),
                                color: Colors.black,
                                fontFamily: 'Arial',
                                padding: HtmlPaddings.zero,
                                margin: Margins.zero,
                              ),
                            },
                          );
                        },
                      ),
                    ] else ...[
                      const Text(
                        "Este correo no tiene contenido HTML.",
                        style: TextStyle(fontSize: 13),
                      ),
                    ],

                    if (archivos.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const Text(
                        "Archivos adjuntos:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...archivos.map((a) {
                        final nombre =
                            (a is Map ? a['nombre'] : null)?.toString() ??
                                'Archivo';
                        final url =
                            (a is Map ? a['url'] : null)?.toString() ?? '';
                        return Text(
                          "- $nombre${url.isNotEmpty ? " ($url)" : ""}",
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
          );
        },
      ),
    );
  }
}

/// ========== Helpers (mismos que en Redenciones) ==========

bool _isPreviewWrapped(String html) => html.contains('TPY:ENV:PREVIEW');
bool _isSendWrapped(String html) => html.contains('TPY:ENV:SEND');

/// Quita el “sobre” de PREVIEW/SEND y devuelve el contenido real del correo.
String _stripEnvelopeHtml(String html) {
  var s = html;

  // 1) Si es PREVIEW, tomar después del <hr>
  if (_isPreviewWrapped(s)) {
    final m = RegExp(r'<hr[^>]*>(.*)$', caseSensitive: false, dotAll: true)
        .firstMatch(s);
    s = (m != null ? m.group(1)! : s);
  }

  // 2) Si es SEND, tomar después del divisor (línea gris) o, como fallback, el interior del <td>
  if (_isSendWrapped(s)) {
    final mDiv = RegExp(
      r'<div[^>]*?(height\s*:\s*1px|border-top\s*:\s*1px)[^>]*?></div>(.*)$',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(s);
    if (mDiv != null) {
      s = mDiv.group(2)!;
    } else {
      final mTd = RegExp(r'<td[^>]*>(.*)</td>',
          caseSensitive: false, dotAll: true)
          .firstMatch(s);
      if (mTd != null) s = mTd.group(1)!;
    }
  }

  // 3) Quitar <meta ...> sueltos
  s = s.replaceAll(RegExp(r'<meta[^>]*>', caseSensitive: false), '');

  return s.trim();
}

/// Limpia <html>, <head>, <body> y comentarios para incrustar de forma segura
String _sanitizeInlineEmailHtml(String html) {
  var s = html;
  s = s.replaceAll(RegExp(r'<!DOCTYPE[^>]*>', caseSensitive: false), '');
  s = s.replaceAll(
      RegExp(r'<\s*head[^>]*>.*?</\s*head\s*>',
          caseSensitive: false, dotAll: true),
      '');
  s = s.replaceAll(RegExp(r'<\s*html[^>]*>', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'</\s*html\s*>', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'<\s*body[^>]*>', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'</\s*body\s*>', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'<!--.*?-->', caseSensitive: false, dotAll: true),
      '');
  return s.trim();
}
