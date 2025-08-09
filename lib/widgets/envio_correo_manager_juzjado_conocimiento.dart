import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/whatsapp_service.dart';

class EnvioCorreoManagerUnico {
  // ✅ Guarda HTML en Storage y registra URL + fecha en Firestore
  Future<void> _guardarHtmlCorreo({
    required String idDocumento,
    required String htmlFinal,
    required String tipoEnvio, // "principal"
    required String nombrePathStorage,         // p.ej. "asignacion_jep"
    required String nombreColeccionFirestore,  // p.ej. "asignacionJEP_solicitados"
  }) async {
    try {
      final bytes = utf8.encode(htmlFinal);
      final fileName = "correo_$tipoEnvio.html";
      final filePath = "$nombrePathStorage/$idDocumento/correos/$fileName";

      final ref = FirebaseStorage.instance.ref(filePath);
      final metadata = SettableMetadata(contentType: "text/html");

      await ref.putData(Uint8List.fromList(bytes), metadata);
      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection(nombreColeccionFirestore)
          .doc(idDocumento)
          .set({
        "correosGuardados.$tipoEnvio": downloadUrl,
        "fechaHtmlCorreo.$tipoEnvio": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Debug
      // print("✅ HTML $tipoEnvio guardado en: $downloadUrl");
    } catch (e) {
      // print("❌ Error al subir HTML $tipoEnvio: $e");
      rethrow;
    }
  }

  /// Envío simple: un solo correo (principal) + guardado de HTML + (opcional) WhatsApp
  Future<void> enviarCorreoUnico({
    required BuildContext context,

    // ✉️ envío
    required String correoDestinoPrincipal,
    String? asuntoPersonalizado,
    String? prefacioHtml, // si quieres anteponer un prefacio opcional

    // contenido original (el HTML de tu plantilla)
    required String html,
    required String? ultimoHtmlEnviado, // si lo generas justo antes (para guardar exactamente lo enviado)

    // metadatos
    required String numeroSeguimiento,
    required String nombreServicio, // p.ej. "Asignación de JEP"
    required String rutaHistorial,
    required String idDocumentoSolicitud, // doc de la colección del servicio
    required String idDocumentoPpl,

    // storage / firestore destino
    required String nombrePathStorage,         // p.ej. "asignacion_jep"
    required String nombreColeccionFirestore,  // p.ej. "asignacionJEP_solicitados"

    // callbacks externos
    required Future<void> Function({
    required String correoDestino,
    String? asuntoPersonalizado,
    String? prefacioHtml,
    }) enviarCorreoResend,

    required Future<void> Function({
    required String tipoEnvio,
    required String htmlFinal,
    required String nombreColeccionFirestore,
    required String nombrePathStorage,
    }) subirHtml,

    // WhatsApp (opcional)
    String? celularWhatsapp,
    String nombreAcudiente = "Usuario",
  }) async {
    // 1) Confirmación
    final confirmar = await showDialog<bool>(
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
              TextSpan(text: correoDestinoPrincipal, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Enviar")),
        ],
      ),
    );

    if (confirmar != true) return;

    // 2) Loader
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
      // 3) Enviar correo
      await enviarCorreoResend(
        correoDestino: correoDestinoPrincipal,
        asuntoPersonalizado: asuntoPersonalizado ?? "$nombreServicio - $numeroSeguimiento",
        prefacioHtml: prefacioHtml,
      );

      // 4) Guardar HTML (primero vía tu callback si lo usas para otra cosa)
      await subirHtml(
        tipoEnvio: "principal",
        htmlFinal: htmlUtf8Compatible(html),
        nombreColeccionFirestore: nombreColeccionFirestore,
        nombrePathStorage: nombrePathStorage,
      );

      // Construir el HTML final con encabezado uniforme (para historizar exactamente lo enviado)
      final htmlConEncabezado = _generarHtmlUniforme(
        correoDestino: correoDestinoPrincipal,
        contenidoHtml: "${prefacioHtml ?? ''}${ultimoHtmlEnviado ?? html}",
      );

      // Guardar HTML “bonito” en Storage y URL en Firestore
      await _guardarHtmlCorreo(
        idDocumento: idDocumentoSolicitud,
        htmlFinal: htmlConEncabezado,
        tipoEnvio: "principal",
        nombrePathStorage: nombrePathStorage,
        nombreColeccionFirestore: nombreColeccionFirestore,
      );

      // 5) Cerrar loader
      if (loaderCtx != null && context.mounted) Navigator.of(loaderCtx!).pop();

      // 6) Éxito
      if (context.mounted) {
        await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (ctx3) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text("✅ Envío exitoso"),
            content: Text("El correo de $nombreServicio fue enviado correctamente."),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx3).pop(), child: const Text("Continuar")),
            ],
          ),
        );
      }

      // 7) WhatsApp (opcional) — PREGUNTAR ANTES DE ENVIAR
      if (celularWhatsapp != null && celularWhatsapp.isNotEmpty && context.mounted) {
        final deseaEnviar = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text("¿Enviar notificación por WhatsApp?"),
            content: Text(
              "Se enviará un mensaje a $celularWhatsapp con el estado de la solicitud.",
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("No")),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Sí, enviar")),
            ],
          ),
        );


        if (deseaEnviar == true) {
          BuildContext? wLoader;
          if(context.mounted){
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) {
                wLoader = ctx;
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

            if (wLoader != null && context.mounted) Navigator.of(wLoader!).pop();

            if (context.mounted) {
              await showDialog(
                barrierDismissible: false,
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: const Text("WhatsApp enviado"),
                  content: const Text("La notificación fue enviada con éxito."),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pushReplacementNamed(rutaHistorial);
                      },
                      child: const Text("Ir al historial", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }
          } catch (e) {
            if (wLoader != null && context.mounted) Navigator.of(wLoader!).pop();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error al enviar WhatsApp: $e"), backgroundColor: Colors.red),
              );
            }
          }
        } else {
          // Si el usuario NO quiere enviar WhatsApp, llévalo al historial si así lo deseas.
          if (context.mounted) {
            Navigator.of(context).pushReplacementNamed(rutaHistorial);
          }
        }
      }
    } catch (e) {
      if (loaderCtx != null && context.mounted) Navigator.of(loaderCtx!).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al enviar: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }


  // ---------- Helpers ----------
  String _generarHtmlUniforme({
    required String correoDestino,
    required String contenidoHtml,
  }) {
    final fechaEnvioFormateada = DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now());
    return """
<meta charset="UTF-8">
<div style="max-width: 750px; margin: auto; padding: 20px;
            font-family: Arial, sans-serif; font-size: 11px; line-height: 1.5;">
  <p style="margin: 0;"><strong>De:</strong> peticiones@tuprocesoya.com</p>
  <p style="margin: 0;"><strong>Para:</strong> $correoDestino</p>
  <p style="margin: 0 0 10px 0;"><strong>Fecha de Envío:</strong> $fechaEnvioFormateada</p>
  <hr style="margin: 12px 0; border: 0; border-top: 1px solid #ccc;">
  $contenidoHtml
</div>
""";
  }

  String htmlUtf8Compatible(String html) {
    final bytes = utf8.encode(html);
    return utf8.decode(bytes, allowMalformed: true);
  }
}
