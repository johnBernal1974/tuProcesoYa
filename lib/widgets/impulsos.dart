import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../src/colors/colors.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' as ui; // para platformViewRegistry (web)
import 'package:universal_html/html.dart' as html; // iframe


class CorreoDestino {
  final String email;
  final String etiqueta;
  CorreoDestino(this.email, this.etiqueta);
}

class ImpulsoProcesalBanner extends StatefulWidget {
  final DateTime fechaUltimoEnvio;
  final int diasPlazo;
  final List<CorreoDestino> correos;

  // estado por correo: { email: {fechaEnvio, ...} } o null si pendiente
  final Map<String, dynamic> estadoPorCorreo;

  final Future<String> Function(String correoSeleccionado) buildPreviewHtml;
  final Future<void> Function({
  required String correoDestino,
  required String html,
  required String etiqueta,
  }) enviarImpulso;

  final VoidCallback? onEnviado;

  const ImpulsoProcesalBanner({
    super.key,
    required this.fechaUltimoEnvio,
    required this.diasPlazo,
    required this.correos,
    required this.estadoPorCorreo,
    required this.buildPreviewHtml,
    required this.enviarImpulso,
    this.onEnviado,
  });

  @override
  State<ImpulsoProcesalBanner> createState() => _ImpulsoProcesalBannerState();
}

class _ImpulsoProcesalBannerState extends State<ImpulsoProcesalBanner> {
  String? _correoSeleccionado;
  String? _htmlPreview;
  bool _cargandoPreview = false;
  bool _enviando = false;

  bool get _plazoCumplido {
    final base = widget.fechaUltimoEnvio.toLocal();
    final baseDia = DateTime(base.year, base.month, base.day);
    final hoy = DateTime.now();
    final hoyDia = DateTime(hoy.year, hoy.month, hoy.day);
    final dias = hoyDia.difference(baseDia).inDays;
    return dias >= widget.diasPlazo;
  }

  @override
  void initState() {
    super.initState();
    if (widget.correos.isNotEmpty) {
      _correoSeleccionado = widget.correos.first.email;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_plazoCumplido) return const SizedBox.shrink();

    final pendientes = widget.correos.where((c) => widget.estadoPorCorreo[c.email] == null).toList();
    final enviados = widget.correos.where((c) => widget.estadoPorCorreo[c.email] != null).toList();

    return Card(
      color: const Color(0xFFFFF8E1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.campaign, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Plazo vencido: puedes enviar un impulso procesal.",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Chips de estado (enviados)
            if (enviados.isNotEmpty) Wrap(
              spacing: 8,
              runSpacing: 8,
              children: enviados.map((c) {
                final estado = widget.estadoPorCorreo[c.email] as Map?;
                final fecha = (estado?['fechaEnvio'] as Timestamp?)?.toDate();
                final label = "${c.etiqueta} • ${c.email}";
                return Chip(
                  avatar: const Icon(Icons.check, size: 18),
                  label: Text(
                    fecha == null ? "$label (enviado)" : "$label (enviado ${_fmtFechaCorta(fecha)})",
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.green.shade50,
                );
              }).toList(),
            ),

            if (pendientes.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text("Enviar impulso a:", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: pendientes.map((c) {
                  return FilledButton.icon(
                    onPressed: _enviando ? null : () => _abrirDialogoImpulso(c),
                    icon: const Icon(Icons.mail),
                    label: Text("${c.etiqueta} • ${c.email}", overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtFechaCorta(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  Future<void> _abrirDialogoImpulso(CorreoDestino destino) async {
    _correoSeleccionado = destino.email;
    _htmlPreview = null;

    await showDialog(
      context: context,
      barrierDismissible: !_enviando,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> generarPreview() async {
              if (_correoSeleccionado == null) return;
              setState(() => _cargandoPreview = true);
              try {
                final html = await widget.buildPreviewHtml(_correoSeleccionado!);
                setState(() => _htmlPreview = html);
              } finally {
                setState(() => _cargandoPreview = false);
              }
            }

            Future<void> enviar() async {
              if (_correoSeleccionado == null || _htmlPreview == null) return;
              setState(() => _enviando = true);
              try {
                await widget.enviarImpulso(
                  correoDestino: _correoSeleccionado!,
                  html: _htmlPreview!,
                  etiqueta: destino.etiqueta,
                );
                if (mounted) Navigator.of(context).pop();
                widget.onEnviado?.call();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Impulso enviado correctamente")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error al enviar: $e")),
                );
              } finally {
                if (mounted) setState(() => _enviando = false);
              }
            }

            return AlertDialog(
              backgroundColor: blanco,
              title: Text("Impulso procesal a ${destino.etiqueta}"),
              content: SizedBox(
                width: 900,
                height: 560,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Botón generar vista previa
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        onPressed: (_cargandoPreview || _enviando) ? null : generarPreview,
                        icon: const Icon(Icons.visibility),
                        label: const Text("Generar vista previa"),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Vista previa
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _cargandoPreview
                            ? const Center(child: CircularProgressIndicator())
                            : (_htmlPreview == null
                            ? const Text(
                          "Genera la vista previa para revisar el contenido antes de enviar.",
                          style: TextStyle(color: Colors.grey),
                        )
                            : (kIsWeb
                            ? _WebHtmlPreview(html: _htmlPreview!)
                            : SingleChildScrollView(
                          child: Html(
                            data: _htmlPreview!,
                            style: {
                              // Mantén tus resets si ya compilan:
                              "html": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
                              "body": Style(margin: Margins.zero, padding: HtmlPaddings.zero),

                              // 👇 CORREGIDO para tu versión de flutter_html
                              "img": Style(
                                width: Width(100, Unit.percent), // en lugar de Width.percentage(...)
                                height: Height.auto(),
                                display: Display.block,          // en lugar de Display.BLOCK
                              ),
                            },
                          ),
                        ))),
                      ),
                    ),

                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _enviando ? null : () => Navigator.of(context).pop(),
                  child: const Text("Cerrar"),
                ),
                FilledButton.icon(
                  onPressed: (_htmlPreview != null && !_enviando) ? enviar : null,
                  icon: const Icon(Icons.send),
                  label: _enviando ? const Text("Enviando...") : const Text("Confirmar envío"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _WebHtmlPreview extends StatefulWidget {
  final String html;
  const _WebHtmlPreview({required this.html});

  @override
  State<_WebHtmlPreview> createState() => _WebHtmlPreviewState();
}

class _WebHtmlPreviewState extends State<_WebHtmlPreview> {
  late final String _viewType;
  late final html.IFrameElement _iframe;

  String _wrapDoc(String body) => '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <style>
    html,body{margin:0;padding:0;width:100%;height:100%;}
  </style>
</head>
<body>$body</body>
</html>
''';

  @override
  void initState() {
    super.initState();
    _viewType = 'tpy-html-preview-${DateTime.now().microsecondsSinceEpoch}';
    _iframe = html.IFrameElement()
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..srcdoc = _wrapDoc(widget.html);
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) => _iframe);
  }

  @override
  void didUpdateWidget(covariant _WebHtmlPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      _iframe.srcdoc = _wrapDoc(widget.html);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}

