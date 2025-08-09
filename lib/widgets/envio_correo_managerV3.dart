import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/widgets/prefacio_centro_reclusionV2.dart';

import '../services/whatsapp_service.dart';

class EnvioCorreoManagerV3 {

  // 🔹 Función para guardar el HTML en Storage y registrar URL en Firestore
  Future<void> _guardarHtmlCorreo({
    required String idDocumento,
    required String htmlFinal,
    required String tipoEnvio,
    required String nombrePathStorage,         // para el path en Storage
    required String nombreColeccionFirestore,  // para la colección en Firestore
  }) async {
    try {
      final contenidoFinal = utf8.encode(htmlFinal);
      final fileName = "correo_$tipoEnvio.html";
      final filePath = "$nombrePathStorage/$idDocumento/correos/$fileName";

      final ref = FirebaseStorage.instance.ref(filePath);
      final metadata = SettableMetadata(contentType: "text/html");

      await ref.putData(Uint8List.fromList(contenidoFinal), metadata);
      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection(nombreColeccionFirestore)
          .doc(idDocumento)
          .set({
        "correosGuardados.$tipoEnvio": downloadUrl,
        "fechaHtmlCorreo.$tipoEnvio": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("✅ HTML de $tipoEnvio guardado en: $downloadUrl");
    } catch (e) {
      print("❌ Error guardando HTML de $tipoEnvio: $e");
    }
  }



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
    required String centroPenitenciario,
    required String nombrePpl,
    required String apellidoPpl,
    required String identificacionPpl,
    required String nui,
    required String td,
    required String patio,
    required String beneficioPenitenciario,
    required String nombrePathStorage, // nuevo
    required String nombreColeccionFirestore, // nuevo
    required String juzgadoEp,
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

    required String? ultimoHtmlEnviado, // 🔹 HTML del último correo enviado
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
    bool permitirOmitirPrincipal = true, // ← NUEVO
  })
  async {
    // 1️⃣ Confirmar envío principal con opción de omitir
    int? decision = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Confirmación"),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black, fontSize: 14),
            children: [
              const TextSpan(text: "Se enviará el correo principal a:\n\n"),
              TextSpan(
                text: correoDestinoPrincipal,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (permitirOmitirPrincipal)
                const TextSpan(
                  text: "\n\n¿Deseas enviarlo o continuar sin enviarlo?",
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(0),
            child: const Text("Cancelar"),
          ),
          if (permitirOmitirPrincipal)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(1),
              child: const Text("Omitir y continuar"),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(2),
            child: const Text("Enviar"),
          ),
        ],
      ),
    );

    if (decision == 0 || decision == null) return; // cancelar
    final bool omitirPrincipal = (decision == 1);

    if (!omitirPrincipal) {
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

      // 🔹 Envío principal
      try {
        await enviarCorreoResend(correoDestino: correoDestinoPrincipal);
        await subirHtml(
          tipoEnvio: "principal",
          htmlFinal: htmlUtf8Compatible(html),
          nombreColeccionFirestore: nombreColeccionFirestore,
          nombrePathStorage: nombrePathStorage,
        );

        if (ultimoHtmlEnviado != null && ultimoHtmlEnviado.isNotEmpty) {
          final htmlConEncabezado = _generarHtmlUniforme(
            correoDestino: correoDestinoPrincipal,
            contenidoHtml: ultimoHtmlEnviado,
          );

          await _guardarHtmlCorreo(
            idDocumento: idDocumentoSolicitud,
            htmlFinal: htmlConEncabezado,
            tipoEnvio: "principal",
            nombreColeccionFirestore: nombreColeccionFirestore,
            nombrePathStorage: nombrePathStorage,
          );
        }

        Navigator.of(loaderCtx!).pop();

        // ✅ Mostrar éxito principal
        if (context.mounted) {
          await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (ctx3) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Text("✅ Envío exitoso"),
              content: const Text("El correo principal fue enviado correctamente."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx3).pop(),
                  child: const Text("Continuar"),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(loaderCtx!).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error al enviar: $e"), backgroundColor: Colors.red),
          );
        }
        return;
      }
    }


// Esperar un frame antes de abrir otro dialog:
    await Future.delayed(Duration.zero);
    if (!context.mounted) return;

    // 2️⃣ Copia al centro de reclusión
    final enviarCopiaCentro = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Correo al centro de reclusión"),
        content: const Text("¿Deseas enviar este correo al centro de reclusión?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Omitir")),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Sí, enviar")),
        ],
      ),
    );

    if (enviarCopiaCentro == true && context.mounted) {
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
                if (context.mounted) {
                  await _enviarCopiaConLoader(
                    context: context,
                    correoDestino: correoCentro,
                    enviarCorreoResend: enviarCorreoResend,
                    asunto: "Solicitud de documentos para $nombreServicio - $numeroSeguimiento",
                    prefacio: generarPrefacioCentroReclusionV2(
                      centroPenitenciario: centroPenitenciario,
                      nombrePpl: nombrePpl,
                      apellidoPpl: apellidoPpl,
                      identificacionPpl: identificacionPpl,
                      nui: nui,
                      td: td,
                      patio: patio,
                      beneficioPenitenciario: beneficioPenitenciario,
                      juzgadoEp: juzgadoEp,
                    ),
                    mensajeExito: "El correo al centro de reclusión fue enviado correctamente.",
                    idDocumentoSolicitud: idDocumentoSolicitud,
                    tipoEnvio: "centro_reclusion",
                    htmlFinal: ultimoHtmlEnviado ?? "",
                    ultimoHtmlEnviado: ultimoHtmlEnviado,
                    nombreColeccionFirestore: nombreColeccionFirestore ,
                    nombrePathStorage: nombrePathStorage,
                  );

                }
                await Future.delayed(const Duration(milliseconds: 100));
              },
              onOmitir: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      );
    }

    if (!context.mounted) return;

    // 3️⃣ Copia a reparto
    final enviarCopiaReparto = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Copia a reparto"),
        content: const Text("¿Deseas enviar una copia al correo de reparto?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Omitir")),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Sí, enviar")),
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

                  if (context.mounted) {
                    // 1️⃣ Declaras el prefacio antes de llamar la función
                    final prefacioReparto = """
<p style="margin: 0;">
  <strong>Entidad reparto:</strong>
</p>
<p style="margin: 4px 0 12px 0; font-size: 16px; font-weight: bold;">
  $entidad
</p>

<p style="margin: 20px 0 0 0;">
  Estimados señores:
</p>
<p style="margin: 8px 0 0 0;">
  Solicitamos amablemente su importante gestión para que sea remitido a la autoridad competente.
</p>

<hr style="border: none; height: 1px; background-color: #ccc; margin-top: 20px; margin-bottom: 12px;">
""";


// 2️⃣ Lo pasas como parámetro en la función
                    await _enviarCopiaConLoader(
                      context: context,
                      correoDestino: correo,
                      enviarCorreoResend: enviarCorreoResend,
                      asunto: "Reparto - Solicitud de $nombreServicio - $numeroSeguimiento",
                      prefacio: prefacioReparto,
                      mensajeExito: "El correo al juzgado de reparto fue enviado correctamente.",
                      htmlFinal: ultimoHtmlEnviado ?? "",
                      idDocumentoSolicitud: idDocumentoSolicitud,
                      tipoEnvio: "reparto",
                      ultimoHtmlEnviado: ultimoHtmlEnviado,
                      nombreColeccionFirestore: nombreColeccionFirestore,
                      nombrePathStorage: nombrePathStorage
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
    required String htmlFinal,
    String? asunto,
    String? prefacio,
    required String mensajeExito,
    required String idDocumentoSolicitud,
    required String tipoEnvio,
    required String? ultimoHtmlEnviado,
    required String nombrePathStorage,
    required String nombreColeccionFirestore,
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
      // 🔹 Generar HTML que se guardará en Storage (prefacio + contenido original)
      final htmlConEncabezado = _generarHtmlUniforme(
        correoDestino: correoDestino,
        contenidoHtml: """
${prefacio ?? ''}
<hr style="margin: 12px 0; border: 0; border-top: 1px solid #ccc;">
${ultimoHtmlEnviado ?? htmlFinal}
""",
      );

      // 🔹 Enviar correo usando solo el prefacio como parte superior
      await enviarCorreoResend(
        correoDestino: correoDestino,
        asuntoPersonalizado: asunto,
        prefacioHtml: prefacio, // ✅ Solo el prefacio original (sin htmlFinal)
      );

      // 🔹 Guardar el HTML final en Storage
      await _guardarHtmlCorreo(
        idDocumento: idDocumentoSolicitud,
        htmlFinal: htmlConEncabezado,
        tipoEnvio: tipoEnvio,
        nombrePathStorage: nombrePathStorage, // usado solo en Firebase Storage
        nombreColeccionFirestore: nombreColeccionFirestore, // usado solo en Firestore
      );



      // 🔹 Cerrar el diálogo de carga
      Navigator.of(loaderCtx!).pop();

      // 🔹 Mostrar mensaje de éxito
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
          SnackBar(
            content: Text("Error al enviar copia: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



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
