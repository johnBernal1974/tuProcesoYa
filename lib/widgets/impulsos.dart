import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../src/colors/colors.dart';

class CorreoDestino {
  final String email;
  final String etiqueta; // ej: "Juzgado", "INPEC", "Centro"
  CorreoDestino(this.email, this.etiqueta);
}

class ImpulsoProcesalBanner extends StatefulWidget {
  final DateTime fechaUltimoEnvio;            // p.ej. fecha del radicado inicial
  final int diasPlazo;                        // p.ej. 10, 15 o 30
  final List<CorreoDestino> correos;          // 1 a 3 correos
  final Future<String> Function(String correoSeleccionado) buildPreviewHtml;
  final Future<void> Function({
  required String correoDestino,
  required String html,
  }) enviarImpulso;
  final VoidCallback? onEnviado;              // opcional: para refrescar UI
  final bool yaSeEnvioImpulso;                // si ya existe un impulso enviado y confirmado

  const ImpulsoProcesalBanner({
    super.key,
    required this.fechaUltimoEnvio,
    required this.diasPlazo,
    required this.correos,
    required this.buildPreviewHtml,
    required this.enviarImpulso,
    this.onEnviado,
    this.yaSeEnvioImpulso = false,
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
    final limite = baseDia.add(Duration(days: widget.diasPlazo));
    final hoy = DateTime.now();
    return hoy.isAfter(limite);
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
    final diffDays = DateTime.now().difference(widget.fechaUltimoEnvio).inDays;
    debugPrint('[ImpulsoBanner] ult=${widget.fechaUltimoEnvio} '
        'diasPlazo=${widget.diasPlazo} diffDays=$diffDays '
        'plazoCumplido=${_plazoCumplido} yaSeEnvio=${widget.yaSeEnvioImpulso}');

    // No mostrar nada si aún no se cumple el plazo o si ya se envió el impulso.
    if (!_plazoCumplido || widget.yaSeEnvioImpulso) {
      return const SizedBox.shrink();
    }

    return Card(
      color: const Color(0xFFFFF8E1), // un ámbar suave tipo "aviso"
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.campaign, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Plazo vencido: puedes enviar un impulso procesal.",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _abrirDialogoImpulso,
              child: const Text("Revisar impulso"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirDialogoImpulso() async {
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
                );
                if (mounted) Navigator.of(context).pop(); // cerrar diálogo
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
              title: const Text("Impulso procesal"),
              scrollable: false, // evita que el AlertDialog envuelva con un SingleChildScrollView
              content: SizedBox(
                width: 900,
                height: 560, // altura fija -> ahora Expanded tiene límites
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Selector de correo
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Destinatario", style: Theme.of(context).textTheme.labelMedium),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _correoSeleccionado,
                      items: widget.correos.map((c) {
                        final label = "${c.etiqueta} • ${c.email}";
                        return DropdownMenuItem(value: c.email, child: Text(label));
                      }).toList(),
                      onChanged: _enviando ? null : (v) {
                        setState(() {
                          _correoSeleccionado = v;
                          _htmlPreview = null;
                        });
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Botón generar vista previa
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        onPressed: (_correoSeleccionado == null || _cargandoPreview || _enviando)
                            ? null
                            : generarPreview,
                        icon: const Icon(Icons.visibility),
                        label: const Text("Generar vista previa"),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Vista previa (ahora sí puede usar Expanded)
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
                          "Genera la vista previa para revisar el contenido del impulso antes de enviarlo.",
                          style: TextStyle(color: Colors.grey),
                        )
                            : SingleChildScrollView(
                          child: Html(
                            data: _htmlPreview!,
                            style: {
                              "body": Style(
                                margin: Margins.zero,
                                padding: HtmlPaddings.zero,
                                fontSize: FontSize(14),
                                lineHeight: LineHeight.number(1.5),
                                fontFamily: 'Arial',
                              ),
                            },
                          ),
                        )),
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
