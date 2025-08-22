import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:tuprocesoya/widgets/prefacio_centro_reclusion.dart';

import '../services/whatsapp_service.dart';

class EnvioCorreoManagerV2 {

  Future<void> enviarCorreoCompleto({
    required BuildContext context,
    required String correoDestinoPrincipal,
    required String html,
    required String numeroSeguimiento,
    // 🔽 acudiente
    required String parentescoAcudiente,
    required String nombreAcudiente,
    required String apellidoAcudiente,
    required String celularAcudiente,
    required String? celularWhatsapp,
    // 🔼 acudiente
    required String rutaHistorial,
    required String nombreServicio,
    required String idDocumentoPpl,
    required String centroPenitenciario,
    required String nombrePpl,
    required String apellidoPpl,
    required String identificacionPpl,
    required String nui,
    required String td,
    required String patio,
    required String beneficioPenitenciario,
    required Future<void> Function({
    required String correoDestino,
    String? asuntoPersonalizado,
    String? prefacioHtml,
    }) enviarCorreoResend,
    required Future<void> Function() subirHtml,
    required Widget Function({
    required Function(String correo, String nombreCentro) onEnviarCorreo,
    required Function() onOmitir,
    }) buildSelectorCorreoCentroReclusion,
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
      if(context.mounted){
        Navigator.of(loaderCtx!).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al enviar: $e"), backgroundColor: Colors.red),
        );
      }
      return;
    }

    Navigator.of(loaderCtx!).pop();

// Esperar un frame antes de abrir otro dialog:
    await Future.delayed(Duration.zero);
    if (!context.mounted) return;

// 2️⃣ Copia al centro de reclusión
    final enviarCopiaCentro = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Copia al centro de reclusión"),
        content: const Text("¿Deseas enviar una copia de este correo al centro de reclusión?"),
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


    if (enviarCopiaCentro == true) {
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: buildSelectorCorreoCentroReclusion(
                onEnviarCorreo: (correoCentro, nombreCentro) async {
                  Navigator.of(context).pop();
                  // Esperar un frame
                  await Future.delayed(const Duration(milliseconds: 150));
                  if(context.mounted){
                    await _enviarCopiaConLoader(
                      context: context,
                      correoDestino: correoCentro,
                      enviarCorreoResend: enviarCorreoResend,
                      asunto: "Solicitud de documentos para $nombreServicio - $numeroSeguimiento",
                      prefacio: generarPrefacioCentroReclusionPorAcudiente(
                        centroPenitenciario: centroPenitenciario,
                        nombrePpl: nombrePpl,
                        apellidoPpl: apellidoPpl,
                        identificacionPpl: identificacionPpl,
                        nui: nui,
                        td: td,
                        patio: patio,
                        beneficioPenitenciario: beneficioPenitenciario,
                        // 🔽 datos del acudiente
                        parentescoAcudiente: parentescoAcudiente,
                        nombreAcudiente: nombreAcudiente,
                        apellidoAcudiente: apellidoAcudiente,
                        celularAcudiente: celularAcudiente,
                        whatsappAcudiente: celularWhatsapp ?? '',
                      ),

                      mensajeExito: "El correo al centro de reclusión fue enviado correctamente.",
                    );

                  }
                  // Esperar que el usuario cierre el popup
                  await Future.delayed(const Duration(milliseconds: 100));
                },
                onOmitir: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        );
      }
    }
    if (!context.mounted) return;

    // 3️⃣ Copia al reparto
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

      if(context.mounted){
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
                  // Confirmación con correo en negrita
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
                  if(context.mounted){
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


    if (!context.mounted) return;
    // 4️⃣ Notificación WhatsApp
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
      if(context.mounted){
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
        if(context.mounted){
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
      if(context.mounted){
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
      if(context.mounted){
        Navigator.of(loaderCtx!).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al enviar copia: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}
