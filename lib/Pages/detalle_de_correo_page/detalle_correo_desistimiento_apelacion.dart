import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/src/colors/colors.dart';
import 'package:http/http.dart' as http;


class DetalleCorreoDesistimientoPage extends StatelessWidget {
  final String idDocumento;
  final String correoId;

  const DetalleCorreoDesistimientoPage({
    super.key,
    required this.idDocumento,
    required this.correoId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
        title: const Text("Detalle del correo (Desistimiento)"),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('desistimiento_apelacion_solicitados')
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
              child: Text("No se encontró información del correo.", style: TextStyle(fontSize: 14)),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final to = (data['to'] as List?)?.join(', ') ?? data['destinatario'] ?? 'Desconocido';
          final remitente = data['remitente'] ?? 'peticiones@tuprocesoya.com';
          final cc = (data['cc'] as List?)?.join(', ') ?? '';
          final subject = data['subject'] ?? data['asunto'] ?? 'Sin asunto';

          // HTML inline y URL (si existe)
          final String htmlInline = (data['html'] ?? data['cuerpoHtml'] ?? data['mensajeHtml'] ?? '').toString().trim();
          final String htmlUrl = (data['htmlUrl'] ?? data['html_url'] ?? '').toString().trim();

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
                    Text(subject, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("De: $remitente", style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text("Para: $to", style: const TextStyle(fontSize: 13)),
                    if (cc.isNotEmpty) Text("CC: $cc", style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: primary),
                        const SizedBox(width: 4),
                        Text("Fecha de envío: $fechaEnvio", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Colors.black54),
                    const SizedBox(height: 12),

                    // Render robusto: inline -> url -> texto plano -> fallback
                    if (htmlInline.isNotEmpty) ...[
                      Html(
                        data: _buildProcessedHtml(htmlInline),
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
                          if (!resp.hasData || resp.data!.statusCode != 200 || resp.data!.body.trim().isEmpty) {
                            return const Text("No se pudo cargar el contenido del correo.");
                          }
                          final bodyRaw = resp.data!.body;
                          final bodyProcessed = _buildProcessedHtml(bodyRaw);
                          return Html(
                            data: bodyProcessed,
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
                      // Si no hay HTML, mostrar texto plano si existe
                      if ((data['textPlain'] ?? data['text'] ?? data['plain'] ?? data['bodyText'] ?? data['snippet']) != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            (data['textPlain'] ?? data['text'] ?? data['plain'] ?? data['bodyText'] ?? data['snippet']).toString(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        )
                      else
                        const Text("Este correo no tiene contenido HTML.", style: TextStyle(fontSize: 13)),
                    ],

                    if (archivos.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const Text("Archivos adjuntos:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...archivos.map((a) {
                        final nombre = (a is Map ? a['nombre'] : null)?.toString() ?? 'Archivo';
                        final url = (a is Map ? a['url'] : null)?.toString() ?? '';
                        return Text("- $nombre${url.isNotEmpty ? " ($url)" : ""}", style: const TextStyle(fontSize: 12));
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

/// ----------------- Helpers (fuera de la clase) -----------------

bool _isPreviewWrapped(String html) => html.contains('TPY:ENV:PREVIEW');
bool _isSendWrapped(String html) => html.contains('TPY:ENV:SEND');

/// Extrae la parte útil si el HTML viene envuelto en PREVIEW/SEND
String _stripEnvelopeHtml(String html) {
  var s = html ?? '';
  if (s.trim().isEmpty) return '';
  if (_isPreviewWrapped(s)) {
    final m = RegExp(r'<hr[^>]*>(.*)$', caseSensitive: false, dotAll: true).firstMatch(s);
    s = (m != null ? m.group(1)! : s);
  }
  if (_isSendWrapped(s)) {
    final mDiv = RegExp(
      r'<div[^>]*?(height\s*:\s*1px|border-top\s*:\s*1px)[^>]*?></div>(.*)$',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(s);
    if (mDiv != null) {
      s = mDiv.group(2)!;
    } else {
      final mTd = RegExp(r'<td[^>]*>(.*)</td>', caseSensitive: false, dotAll: true).firstMatch(s);
      if (mTd != null) s = mTd.group(1)!;
    }
  }
  s = s.replaceAll(RegExp(r'<meta[^>]*>', caseSensitive: false), '');
  return s.trim();
}

/// Limpieza básica de etiquetas de documento y comentarios
String _sanitizeInlineEmailHtml(String html) {
  var s = html ?? '';
  s = s.replaceAll(RegExp(r'<!DOCTYPE[^>]*>', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'<\s*head[^>]*>.*?</\s*head\s*>', caseSensitive: false, dotAll: true), '');
  s = s.replaceAll(RegExp(r'<\s*html[^>]*>', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'</\s*html\s*>', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'<\s*body[^>]*>', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'</\s*body\s*>', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'<!--[\s\S]*?-->', caseSensitive: false), '');
  return s.trim();
}

/// Quita header de respuesta tipo "El jue, 25 sept ... escribió:" (sin tragar el blockquote)
String _removeReplyHeader(String raw) {
  var s = raw ?? '';
  try {
    // 1) <div class="gmail_attr"> ... escribió: <br></div>
    s = s.replaceAll(
      RegExp(
        r'<div[^>]*class=["\"]?gmail_attr[^>]*>[\s\S]*?escribi[oó]\s*:\s*<br\s*/?>\s*</div>\s*',
        caseSensitive: false,
        dotAll: true,
      ),
      '',
    );

    // 2) etiquetas que contienen "escribió:" (elimina solo la etiqueta contenedora)
    s = s.replaceAll(
      RegExp(
        r'<[^>]+?>[^<]{0,200}?escribi[oó]\s*:\s*</[^>]+?>',
        caseSensitive: false,
        dotAll: true,
      ),
      '',
    );

    // 3) Texto plano: eliminar solo la línea "El ... escribió:" conservando lo posterior
    s = s.replaceAll(
      RegExp(
        r'(^|\r?\n)[^\n]{0,250}?\bEl\s+\w{1,12}[^\n\r]{0,200}?escribi[oó]\s*:\s*(?=\r?\n|<blockquote|<div|$)',
        caseSensitive: false,
        dotAll: true,
      ),
      '\n',
    );

    // 4) Inglés "wrote:"
    s = s.replaceAll(
      RegExp(
        r'(^|\r?\n)[^\n]{0,250}?wrote\s*:\s*(?=\r?\n|<blockquote|<div|$)',
        caseSensitive: false,
        dotAll: true,
      ),
      '\n',
    );

    // 5) quitar líneas tipo "Enviado el ..." residuales
    s = s.replaceAll(RegExp(r'(^|\r?\n).{0,200}?Enviado\s+el\s+.*', caseSensitive: false), '');
  } catch (e) {
    debugPrint('⚠️ _removeReplyHeader error: $e');
    return raw ?? '';
  }
  return s;
}

/// Quita reglas CSS problemáticas para flutter_html
String _cleanForFlutterHtml(String html) {
  if (html == null || html.trim().isEmpty) return '';
  String s = html;

  // Quitar tags de documento y comentarios
  s = s.replaceAll(RegExp(r'<!DOCTYPE[^>]*>', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'<\s*head[^>]*>.*?</\s*head\s*>', caseSensitive: false, dotAll: true), '');
  s = s.replaceAll(RegExp(r'<\s*html[^>]*>', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'</\s*html\s*>', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'<\s*body[^>]*>', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'</\s*body\s*>', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'<!--[\s\S]*?-->', caseSensitive: false), '');

  // Patrones CSS problemáticos (sin usar flags inline)
  final cssPatterns = [
    r'font-feature-settings\s*:\s*[^;>]+;?',
    r'font-variation-settings\s*:\s*[^;>]+;?',
    r'@font-face\s*{[^}]*}',
    r'style\s*=\s*"(?:[^"]*font-feature-settings[^"]*)"',
    r"style\s*=\s*'(?:[^']*font-feature-settings[^']*)'",
  ];
  for (final p in cssPatterns) {
    try {
      s = s.replaceAll(RegExp(p, caseSensitive: false, dotAll: true), '');
    } catch (e) {
      debugPrint('⚠️ cleanForFlutterHtml regex fail $p -> $e');
    }
  }

  // Quitar flags regex si aparecieron incrustadas
  s = s.replaceAll(RegExp(r'\(\?[imsux-]+\)'), '');
  s = s.replaceAll(RegExp(r'font-feature-settings\s*:\s*[^;>]+;?', caseSensitive: false), '');

  return s.trim();
}

/// Pipeline completa para procesar HTML antes de pasarlo a flutter_html
String _buildProcessedHtml(String raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final stripped = _stripEnvelopeHtml(raw);
  final withoutHeader = _removeReplyHeader(stripped);
  final sanitized = _sanitizeInlineEmailHtml(withoutHeader);
  final cleaned = _cleanForFlutterHtml(sanitized);
  return cleaned;
}
