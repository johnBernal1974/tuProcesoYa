import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../src/colors/colors.dart';
import '../widgets/email_status_widget.dart';

class ResumenSolicitudesWidget extends StatefulWidget {
  final String idPpl;
  final bool mostrarCorreos;

  const ResumenSolicitudesWidget({
    super.key,
    required this.idPpl,
    this.mostrarCorreos = false,
  });

  @override
  State<ResumenSolicitudesWidget> createState() => _ResumenSolicitudesWidgetState();
}

class _ResumenSolicitudesWidgetState extends State<ResumenSolicitudesWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('solicitudes_usuario')
          .where('idUser', isEqualTo: widget.idPpl)
          .orderBy('fecha', descending: true)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("No hay solicitudes registradas.");
        }

        final solicitudes = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: solicitudes.length,
          itemBuilder: (context, index) {
            final doc = solicitudes[index];
            final tipo = doc['tipo'] ?? 'Sin tipo';
            final numero = doc['numeroSeguimiento'] ?? '—';
            final estadoRaw = doc['status'] ?? '—';
            final estilo = _obtenerEstiloEstado(estadoRaw);
            final origen = doc['origen'] ?? '';
            final idOriginal = doc['idOriginal'] ?? '';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  surfaceTintColor: blanco,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: estilo['color'],
                      child: Icon(estilo['icon'], color: Colors.white),
                    ),
                    title: Text(
                      tipo,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Seguimiento: $numero", style: const TextStyle(fontSize: 11)),
                        Text("Estado: ${estilo['texto']}", style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: blanco,
                          title: const Text("Correos de la solicitud"),
                          content: SizedBox(
                            width: 600,
                            height: 300,
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                child: ListaCorreosWidget(
                                  solicitudId: idOriginal,
                                  nombreColeccion: origen,
                                  onTapCorreo: (correoId) {
                                    Navigator.of(context).pop(); // Cierra el diálogo
                                    _mostrarDetalleCorreo(
                                      correoId: correoId,
                                      solicitudId: idOriginal,
                                      nombreColeccion: origen,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: const Text("Cerrar"),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                if (widget.mostrarCorreos)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 12.0),
                    child: ListaCorreosWidget(
                      nombreColeccion: origen,
                      solicitudId: idOriginal,
                      onTapCorreo: (correoHtmlUrl) async {
                        final url = Uri.parse(correoHtmlUrl);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("No se pudo abrir el correo.")),
                          );
                        }
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // Requiere: import 'package:http/http.dart' as http;
  void _mostrarDetalleCorreo({
    required String correoId,
    required String solicitudId,
    required String nombreColeccion,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return Container(
              color: Colors.white,
              width: isMobile ? double.infinity : 1000,
              padding: const EdgeInsets.all(20),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection(nombreColeccion)
                    .doc(solicitudId)
                    .collection('log_correos')
                    .doc(correoId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text("No se encontró información del correo.");
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;

                  // Para / CC / De
                  final toList = (data['to'] as List?)?.whereType<String>().toList();
                  final destinatario = (data['destinatario'] as String?)?.trim();
                  final to = (toList != null && toList.isNotEmpty)
                      ? toList.join(', ')
                      : (destinatario?.isNotEmpty == true ? destinatario! : '(sin destinatario)');

                  final cc = (data['cc'] as List?)?.whereType<String>().join(', ') ?? '';

                  final fromList = (data['from'] as List?)?.whereType<String>().toList();
                  final remitente = (data['remitente'] as String?)?.trim();
                  final from = (fromList != null && fromList.isNotEmpty)
                      ? fromList.join(', ')
                      : (remitente?.isNotEmpty == true ? remitente! : 'peticiones@tuprocesoya.com');

                  final subject = (data['subject'] ?? data['asunto'] ?? '(sin asunto)').toString();

                  final archivos = data['archivos'] as List? ?? [];

                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                  final fechaEnvio = timestamp != null
                      ? DateFormat("dd MMM yyyy - hh:mm a", 'es').format(timestamp)
                      : 'Fecha no disponible';

                  // 👇 Cuerpo: inline / url
                  final String htmlInline =
                  (data['html'] ?? data['cuerpoHtml'] ?? data['mensajeHtml'] ?? data['text'] ?? '').toString().trim();
                  final String htmlUrl =
                  (data['htmlUrl'] ?? data['html_url'] ?? '').toString().trim();

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text("📤 De: $from", style: const TextStyle(fontSize: 13)),
                        Text("📥 Para: $to", style: const TextStyle(fontSize: 13)),
                        if (cc.isNotEmpty) Text("📋 CC: $cc", style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 10),
                        Text("📌 Asunto: $subject", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("📅 Fecha de envío: $fechaEnvio", style: const TextStyle(color: Colors.black87, fontSize: 12)),
                        const Divider(),

                        // ====== Render robusto del cuerpo ======
                        if (htmlInline.isNotEmpty) ...[
                          Html(
                            data: _buildProcessedHtml(htmlInline),
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
                                return _fallbackAbrirEnPestana(htmlUrl);
                              }
                              final bodyProcessed = _buildProcessedHtml(resp.data!.body);
                              return Html(data: bodyProcessed);
                            },
                          ),
                        ] else ...[
                          // 🔎 Fallback: buscar en el nodo padre "impulso" del mismo nombreColeccion
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection(nombreColeccion).doc(solicitudId).get(),
                            builder: (context, parentSnap) {
                              if (parentSnap.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: LinearProgressIndicator(),
                                );
                              }
                              if (!parentSnap.hasData || !parentSnap.data!.exists) {
                                return const Text("(Sin contenido disponible)");
                              }

                              final parent = parentSnap.data!.data() as Map<String, dynamic>?;
                              final imp = parent?['impulso'];

                              if (imp is! Map) {
                                return const Text("(Sin contenido disponible)");
                              }

                              // Etiqueta registrada en el log
                              final etiquetaDoc = (data['etiqueta'] ?? '').toString();
                              final keyByEtiqueta = etiquetaDoc.isNotEmpty ? _etiquetaToKey(etiquetaDoc) : null;

                              String? url2;
                              Map<String, dynamic>? nodo;

                              // A) Si coincide por etiqueta directa
                              if (keyByEtiqueta != null && imp[keyByEtiqueta] is Map) {
                                nodo = Map<String, dynamic>.from(imp[keyByEtiqueta]);
                              }

                              // B) Búsqueda recursiva por email/subject si no hubo suerte
                              nodo ??= _findImpulsoLeaf(
                                Map<String, dynamic>.from(imp),
                                emailKey: (toList != null && toList.isNotEmpty) ? toList.first : destinatario,
                                subject: subject,
                              );

                              if (nodo != null) {
                                url2 = (nodo['htmlUrl'] ?? nodo['html_url'])?.toString();
                              }

                              if (url2 == null || url2!.isEmpty) {
                                return const Text("(Sin contenido disponible)");
                              }

                              return FutureBuilder<http.Response>(
                                future: http.get(Uri.parse(url2!)),
                                builder: (context, respImp) {
                                  if (respImp.connectionState == ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: LinearProgressIndicator(),
                                    );
                                  }
                                  if (!respImp.hasData || respImp.data!.statusCode != 200 || respImp.data!.body.trim().isEmpty) {
                                    return _fallbackAbrirEnPestana(url2!);
                                  }
                                  final bodyProcessed = _buildProcessedHtml(respImp.data!.body);
                                  return Html(data: bodyProcessed);
                                },
                              );
                            },
                          ),
                        ],
                        // ====== /Render cuerpo ======

                        if (archivos.isNotEmpty) ...[
                          const Divider(),
                          const Text("📎 Archivos adjuntos:", style: TextStyle(fontWeight: FontWeight.bold)),
                          ...archivos.map((a) {
                            final nombre = (a is Map ? a['nombre'] : null)?.toString() ?? 'Archivo';
                            final url = (a is Map ? a['url'] : null)?.toString() ?? '';
                            return Text("- $nombre${url.isNotEmpty ? " ($url)" : ""}");
                          }),
                        ],
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            child: const Text("Cerrar"),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _fallbackAbrirEnPestana(String url) {
    return Html(
      data:
      '<p style="color:#b00020;margin:0 0 6px 0;">No se pudo cargar el cuerpo del correo.</p>'
          '<p><a href="$url" target="_blank" rel="noopener noreferrer">Abrir contenido en una pestaña</a></p>',
    );
  }

  bool _isPreviewWrapped(String html) => html.contains('TPY:ENV:PREVIEW');
  bool _isSendWrapped(String html) => html.contains('TPY:ENV:SEND');

  /// Quita el “sobre” de PREVIEW/SEND y devuelve solo el contenido del correo.
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

  /// Quita header de respuesta tipo "El ... escribió:" (sin tragar el blockquote)
  String _removeReplyHeader(String raw) {
    var s = raw ?? '';
    try {
      s = s.replaceAll(
        RegExp(
          r'<div[^>]*class=["\"]?gmail_attr[^>]*>[\s\S]*?escribi[oó]\s*:\s*<br\s*/?>\s*</div>\s*',
        caseSensitive: false,
          dotAll: true,
        ),
        '',
      );

      s = s.replaceAll(
        RegExp(
          r'<[^>]+?>[^<]{0,200}?escribi[oó]\s*:\s*</[^>]+?>',
          caseSensitive: false,
          dotAll: true,
        ),
        '',
      );

      s = s.replaceAll(
        RegExp(
          r'(^|\r?\n)[^\n]{0,250}?\bEl\s+\w{1,12}[^\n\r]{0,200}?escribi[oó]\s*:\s*(?=\r?\n|<blockquote|<div|$)',
          caseSensitive: false,
          dotAll: true,
        ),
        '\n',
      );

      s = s.replaceAll(
        RegExp(
          r'(^|\r?\n)[^\n]{0,250}?wrote\s*:\s*(?=\r?\n|<blockquote|<div|$)',
          caseSensitive: false,
          dotAll: true,
        ),
        '\n',
      );

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

    s = s.replaceAll(RegExp(r'<!DOCTYPE[^>]*>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<\s*head[^>]*>.*?</\s*head\s*>', caseSensitive: false, dotAll: true), '');
    s = s.replaceAll(RegExp(r'<\s*html[^>]*>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'</\s*html\s*>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<\s*body[^>]*>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'</\s*body\s*>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<!--[\s\S]*?-->', caseSensitive: false), '');

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

  /// Busca de forma recursiva un "leaf" de impulso que contenga payload (htmlUrl/html_url/destinatario)
  Map<String, dynamic>? _findImpulsoLeaf(
      Map<String, dynamic> obj, {
        String? emailKey,
        String? subject,
      }) {
    for (final entry in obj.entries) {
      final v = entry.value;
      if (v is Map) {
        final hasPayload = v.containsKey('htmlUrl') || v.containsKey('html_url') || v.containsKey('destinatario');
        if (hasPayload) {
          final dest = (v['destinatario'] ?? '').toString();
          final subj = (v['subject'] ?? '').toString();
          if ((emailKey != null && dest == emailKey) ||
              (subject != null && subj == subject) ||
              (emailKey == null && subject == null)) {
            return Map<String, dynamic>.from(v);
          }
        }
        final r = _findImpulsoLeaf(Map<String, dynamic>.from(v), emailKey: emailKey, subject: subject);
        if (r != null) return r;
      }
    }
    return null;
  }

  /// Convierte la etiqueta visible a la key estándar usada en el doc
  String _etiquetaToKey(String etq) {
    final e = etq.toLowerCase();
    if (e.contains('centro')) return 'centro_reclusion';
    if (e.contains('reparto')) return 'reparto';
    return 'principal';
  }

  Map<String, dynamic> _obtenerEstiloEstado(String status) {
    switch (status.toLowerCase()) {
      case 'solicitado':
        return {'icon': Icons.schedule, 'color': Colors.amber, 'texto': 'Solicitado'};
      case 'diligenciado':
        return {'icon': Icons.edit_document, 'color': Colors.blueGrey, 'texto': 'Diligenciado'};
      case 'revisado':
        return {'icon': Icons.search, 'color': Colors.blue, 'texto': 'Revisado'};
      case 'enviado':
        return {'icon': Icons.send, 'color': Colors.green, 'texto': 'Enviado'};
      case 'negado':
        return {'icon': Icons.cancel, 'color': Colors.red, 'texto': 'Negado'};
      case 'concedido':
        return {'icon': Icons.verified, 'color': Colors.green, 'texto': 'Concedido'};
      default:
        return {'icon': Icons.help_outline, 'color': Colors.grey, 'texto': status};
    }
  }
}
