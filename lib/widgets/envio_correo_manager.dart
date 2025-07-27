import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/whatsapp_service.dart';

class EnvioCorreoManager {
  Future<void> enviarCorreoCompleto({
    required BuildContext context,
    required String correoDestinoPrincipal,
    required String html,
    required String numeroSeguimiento,
    required String nombreAcudiente,
    required String? celularWhatsapp,
    required String rutaHistorial,
    required String nombreServicio,
    required String idDocumentoPpl,
    required Future<void> Function({
    required String correoDestino,
    String? asuntoPersonalizado,
    String? prefacioHtml,
    }) enviarCorreoResend,
    required Future<void> Function() subirHtml,
    required Widget Function({
    required Function(String correo, String entidad) onCorreoValidado,
    required Function(String nombreCiudad) onCiudadNombreSeleccionada,
    required Function(String correo, String entidad) onEnviarCorreoManual,
    required Function() onOmitir,
    }) buildSelectorCorreoReparto,
  }) async {
    // 1️⃣ Confirmar envío principal
    final confirmacion = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Confirmación"),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black, fontSize: 14),
            children: [
              const TextSpan(text: "Se enviará el correo a:\n\n"),
              TextSpan(
                text: correoDestinoPrincipal,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text("Enviar"),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmacion != true) return;

    // Loader principal
    BuildContext? loaderCtx;
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          loaderCtx = ctx;
          return const AlertDialog(
            backgroundColor: Colors.white,
            title: Text("Enviando correo..."),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Espere mientras se envía el correo."),
                SizedBox(height: 20),
                CircularProgressIndicator(),
              ],
            ),
          );
        },
      );
    }

    try {
      await enviarCorreoResend(correoDestino: correoDestinoPrincipal);
      await subirHtml();
    } catch (e) {
      if (context.mounted) {
        Navigator.of(loaderCtx!).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al enviar: $e"), backgroundColor: Colors.red),
        );
      }
      return;
    }

    Navigator.of(loaderCtx!).pop();
    await Future.delayed(Duration.zero);
    if (!context.mounted) return;

    // 2️⃣ Copia a reparto
    final enviarCopiaReparto = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Copia a reparto"),
        content: const Text("¿Deseas enviar una copia al correo de reparto?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Omitir"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Sí, enviar"),
          ),
        ],
      ),
    );

    if (enviarCopiaReparto == true) {
      await Future.delayed(const Duration(milliseconds: 200));

      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: buildSelectorCorreoReparto(
                onCorreoValidado: (correo, entidad) {},
                onCiudadNombreSeleccionada: (_) {},
                onEnviarCorreoManual: (correo, entidad) async {
                  final confirmarEnvio = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx2) => AlertDialog(
                      backgroundColor: Colors.white,
                      title: const Text("Confirmar envío"),
                      content: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black, fontSize: 14),
                          children: [
                            const TextSpan(text: "Se enviará el correo a:\n\n"),
                            TextSpan(
                              text: correo,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          child: const Text("Cancelar"),
                          onPressed: () => Navigator.of(ctx2).pop(false),
                        ),
                        TextButton(
                          child: const Text("Enviar"),
                          onPressed: () => Navigator.of(ctx2).pop(true),
                        ),
                      ],
                    ),
                  );

                  if (confirmarEnvio != true) return;
                  if (context.mounted) {
                    await _enviarCopiaConLoader(
                      context: context,
                      correoDestino: correo,
                      enviarCorreoResend: enviarCorreoResend,
                      asunto: "Reparto - Solicitud de $nombreServicio - $numeroSeguimiento",
                      prefacio: "<p><strong>Entidad reparto:</strong> $entidad</p><hr>",
                      mensajeExito: "El correo al juzgado de reparto fue enviado correctamente.",
                    );
                  }
                  Navigator.of(context).pop();
                },
                onOmitir: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        );
      }
    }

    // 3️⃣ WhatsApp
    final notificarWhatsapp = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("¿Enviar Notificación?"),
        content: const Text("¿Deseas notificar al usuario del envío por WhatsApp?"),
        actions: [
          TextButton(
            child: const Text("No"),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text("Sí, enviar"),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (notificarWhatsapp == true && celularWhatsapp != null && celularWhatsapp.isNotEmpty) {
      BuildContext? loaderCtx;
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            loaderCtx = ctx;
            return const AlertDialog(
              backgroundColor: Colors.white,
              title: Text("Enviando WhatsApp..."),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Por favor espera mientras se envía la notificación."),
                  SizedBox(height: 20),
                  CircularProgressIndicator(),
                ],
              ),
            );
          },
        );
      }
      try {
        await WhatsappService.enviarNotificacion(
          numero: celularWhatsapp,
          docId: idDocumentoPpl,
          servicio: nombreServicio,
          seguimiento: numeroSeguimiento,
        );

        Navigator.of(loaderCtx!).pop();

        if (context.mounted) {
          await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  Image.asset(
                    "assets/images/icono_whatsapp.png",
                    height: 28,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "WhatsApp enviado",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: const Text(
                "La notificación de activación fue enviada con éxito.",
                style: TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushReplacementNamed(rutaHistorial);
                  },
                  child: const Text(
                    "Ir al historial",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(loaderCtx!).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error al enviar WhatsApp: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _enviarCopiaConLoader({
    required BuildContext context,
    required String correoDestino,
    required Future<void> Function({
    required String correoDestino,
    String? asuntoPersonalizado,
    String? prefacioHtml,
    }) enviarCorreoResend,
    String? asunto,
    String? prefacio,
    required String mensajeExito,
  }) async {
    BuildContext? loaderCtx;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        loaderCtx = ctx;
        return const AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Enviando copia..."),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Por favor espera mientras se envía el correo."),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        );
      },
    );

    try {
      await enviarCorreoResend(
        correoDestino: correoDestino,
        asuntoPersonalizado: asunto,
        prefacioHtml: prefacio,
      );
      Navigator.of(loaderCtx!).pop();
      if (context.mounted) {
        await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (ctx3) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text("✅ Envío exitoso"),
            content: Text(mensajeExito),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx3).pop(),
                child: const Text("Cerrar"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(loaderCtx!).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al enviar copia: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}
