// EnvioCorreoManagerV7.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/whatsapp_service.dart';

class EnvioCorreoManagerV7 {
  // 🔹 Función para guardar el HTML en Storage y registrar URL en Firestore
  Future<void> _guardarHtmlCorreo({
    required String idDocumento,
    required String htmlFinal,
    required String tipoEnvio,
    required String nombrePathStorage,
    required String nombreColeccionFirestore,
  }) async {
    try {
      final contenidoFinal = utf8.encode(htmlFinal);
      final fileName = "correo_$tipoEnvio.html";
      final filePath = "$nombrePathStorage/$idDocumento/correos/$fileName";

      final ref = FirebaseStorage.instance.ref(filePath);
      final metadata = SettableMetadata(contentType: "text/html");

      await ref.putData(Uint8List.fromList(contenidoFinal), metadata);
      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection(nombreColeccionFirestore).doc(idDocumento).set({
        "correosGuardados.$tipoEnvio": downloadUrl,
        "fechaHtmlCorreo.$tipoEnvio": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) print("✅ HTML de $tipoEnvio guardado en: $downloadUrl");
    } catch (e) {
      if (kDebugMode) print("❌ Error guardando HTML de $tipoEnvio: $e");
    }
  }

  /// Envío principal simplificado para Desistimiento de apelación.
  /// Recibe:
  /// - correoDestinoPrincipal: dirección a la que se debe enviar (puede ser manual)
  /// - html: cuerpo HTML (plantilla)
  /// - ultimoHtmlEnviado: HTML para guardar/trazabilidad (opcional)
  /// - enviarCorreoResend: función que realiza el POST al servicio de envío (Resend)
  /// - subirHtml: función que sube el HTML (ya usada en tu código)
  Future<void> enviarCorreoCompleto({
    required BuildContext context,
    required String correoDestinoPrincipal,
    required String html,
    required String numeroSeguimiento,
    required String nombreAcudiente,
    required String? celularWhatsapp,
    required String rutaHistorial,
    required String nombreServicio,
    required String idDocumentoSolicitud,
    required String idDocumentoPpl,

    // Datos PPL / Centro (por si los usas en prefacios)
    required String centroPenitenciario,
    required String nombrePpl,
    required String apellidoPpl,
    required String identificacionPpl,
    required String nui,
    required String td,
    required String patio,
    required String beneficioPenitenciario,
    required String juzgadoEp,

    // Datos acudiente (prefacio)
    required String parentescoAcudiente,
    required String apellidoAcudiente,
    required String identificacionAcudiente,
    String? celularAcudiente,

    // Rutas de guardado
    required String nombrePathStorage,
    required String nombreColeccionFirestore,

    // Funciones externas (ya existentes en tu infra)
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

    required String? ultimoHtmlEnviado,
  }) async {
    // Confirmación al usuario mostrando el correo destino
    final confirm = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Confirmación de envío"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Se enviará el correo principal a:"),
            const SizedBox(height: 8),
            SelectableText(correoDestinoPrincipal, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text("¿Deseas continuar con el envío?"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(0), child: const Text("Cancelar")),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(1), child: const Text("Enviar")),
        ],
      ),
    );

    if (confirm != 1) return;

    // Mostrar dialog loader
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
      // 1) Llamar al servicio que hace el POST (Resend)
      await enviarCorreoResend(correoDestino: correoDestinoPrincipal);

      // 2) Subir HTML principal (si la UI pide subir)
      await subirHtml(
        tipoEnvio: "principal",
        htmlFinal: htmlUtf8Compatible(html),
        nombreColeccionFirestore: nombreColeccionFirestore,
        nombrePathStorage: nombrePathStorage,
      );

      // 3) Guardar versión "uniforme" en Storage para trazabilidad
      final htmlConEncabezado = _generarHtmlUniforme(
        correoDestino: correoDestinoPrincipal,
        contenidoHtml: ultimoHtmlEnviado ?? html,
      );

      await _guardarHtmlCorreo(
        idDocumento: idDocumentoSolicitud,
        htmlFinal: htmlConEncabezado,
        tipoEnvio: "principal",
        nombreColeccionFirestore: nombreColeccionFirestore,
        nombrePathStorage: nombrePathStorage,
      );

      // 4) Registrar destinatario en el documento Firestore
      await _guardarCorreoDestinoEnDoc(
        nombreColeccionFirestore: nombreColeccionFirestore,
        idDocumentoSolicitud: idDocumentoSolicitud,
        tipoEnvio: "principal",
        correoDestino: correoDestinoPrincipal,
        esPrimerEnvioPosible: true,
      );

      // Cerrar loader
      if (loaderCtx != null) Navigator.of(loaderCtx!).pop();

      // Mostrar dialog de éxito
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text("✅ Envío exitoso"),
            content: const Text("El correo principal fue enviado correctamente."),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Continuar")),
            ],
          ),
        );
      }
    } catch (e) {
      if (loaderCtx != null) {
        try {
          Navigator.of(loaderCtx!).pop();
        } catch (_) {}
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al enviar: $e"), backgroundColor: Colors.red));
      }
      return;
    }

    // Opcional: notificar por WhatsApp al acudiente
    final notificarWhatsapp = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("¿Enviar Notificación?"),
        content: const Text("¿Deseas notificar al usuario del envío por WhatsApp?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Sí, enviar")),
        ],
      ),
    );

    if (notificarWhatsapp == true && celularWhatsapp != null && celularWhatsapp.isNotEmpty) {
      BuildContext? loaderCtx2;
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            loaderCtx2 = ctx;
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

        if (loaderCtx2 != null && loaderCtx2!.mounted) Navigator.of(loaderCtx2!).pop();

        if (context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Row(
                children: [
                  Image.asset("assets/images/icono_whatsapp.png", height: 28),
                  const SizedBox(width: 8),
                  const Expanded(child: Text("WhatsApp enviado", style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
              content: const Text("La notificación de activación fue enviada con éxito.", style: TextStyle(fontSize: 14)),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cerrar")),
              ],
            ),
          );
        }
      } catch (e) {
        if (loaderCtx2 != null && loaderCtx2!.mounted) Navigator.of(loaderCtx2!).pop();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al enviar WhatsApp: $e"), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _guardarCorreoDestinoEnDoc({
    required String nombreColeccionFirestore,
    required String idDocumentoSolicitud,
    required String tipoEnvio,
    required String correoDestino,
    bool esPrimerEnvioPosible = false,
  }) async {
    final docRef = FirebaseFirestore.instance.collection(nombreColeccionFirestore).doc(idDocumentoSolicitud);

    final update = <String, dynamic>{
      'correoHtmlCorreo.$tipoEnvio': correoDestino,
      'destinatarios.$tipoEnvio': correoDestino,
      'ultimoEnvio': FieldValue.serverTimestamp(),
      'correoHtmlCorreo_historial.$tipoEnvio': FieldValue.arrayUnion([correoDestino]),
    };

    if (esPrimerEnvioPosible && tipoEnvio == 'principal') {
      update['fechaEnvioInicial'] = FieldValue.serverTimestamp();
    }

    await docRef.set(update, SetOptions(merge: true));
  }

  String _generarHtmlUniforme({
    required String correoDestino,
    required String contenidoHtml,
  }) {
    final fechaEnvioFormateada = DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now());

    return """
<meta charset="UTF-8">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="border-collapse:collapse;">
  <tr>
    <td align="left" style="padding:20px; font-family:Arial, sans-serif; font-size:13px; line-height:1.5; color:#333;">
      <p style="margin:0;"><strong>De:</strong> peticiones@tuprocesoya.com</p>
      <p style="margin:0;"><strong>Para:</strong> $correoDestino</p>
      <p style="margin:0 0 10px 0;"><strong>Fecha de Envío:</strong> $fechaEnvioFormateada</p>

      <div style="border-top:1px solid #ccc; margin:12px 0;"></div>

      $contenidoHtml
    </td>
  </tr>
</table>
""";
  }

  String htmlUtf8Compatible(String html) {
    final bytes = utf8.encode(html);
    return utf8.decode(bytes, allowMalformed: true);
  }
}
