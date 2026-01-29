import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/widgets/prefacio_centro%20_reclusionV3.dart';
// ⬇️ Usar el prefacio V3 (acudiente)
import '../services/whatsapp_service.dart';

class EnvioCorreoManagerV6 {
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

    // Datos PPL / Centro
    required String centroPenitenciario,
    required String nombrePpl,
    required String apellidoPpl,
    required String identificacionPpl,
    required String nui,
    required String td,
    required String patio,
    required String beneficioPenitenciario,
    required String juzgadoEp,

    // 📌 NUEVOS: datos del acudiente para prefacio V3
    required String parentescoAcudiente,
    required String apellidoAcudiente,
    required String identificacionAcudiente,
    String? celularAcudiente,

    DateTime? periodoDesde,
    DateTime? periodoHasta,


    // rutas de guardado
    required String nombrePathStorage,
    required String nombreColeccionFirestore,

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

    required String? ultimoHtmlEnviado, // HTML del último correo enviado

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
    bool permitirOmitirPrincipal = true,
  }) async {
    // 1️⃣ Confirmación envío principal (igual)
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
                const TextSpan(text: "\n\n¿Deseas enviarlo o continuar sin enviarlo?"),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(0), child: const Text("Cancelar")),
          if (permitirOmitirPrincipal)
            TextButton(onPressed: () => Navigator.of(ctx).pop(1), child: const Text("Omitir y continuar")),
          TextButton(onPressed: () => Navigator.of(ctx).pop(2), child: const Text("Enviar")),
        ],
      ),
    );

    if (decision == 0 || decision == null) return;
    final bool omitirPrincipal = (decision == 1);

    if (!omitirPrincipal) {
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

        await _guardarCorreoDestinoEnDoc(
          nombreColeccionFirestore: nombreColeccionFirestore,
          idDocumentoSolicitud: idDocumentoSolicitud,
          tipoEnvio: "principal",
          correoDestino: correoDestinoPrincipal,
          esPrimerEnvioPosible: true,
        );

        Navigator.of(loaderCtx!).pop();

        if (context.mounted) {
          await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (ctx3) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Text("✅ Envío exitoso"),
              content: const Text("El correo principal fue enviado correctamente."),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx3).pop(), child: const Text("Continuar")),
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

    // 2️⃣ Centro de reclusión (usa prefacio V3 con acudiente)
    await Future.delayed(Duration.zero);
    if (!context.mounted) return;

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
                await Future.delayed(const Duration(milliseconds: 150));
                if (context.mounted) {
                  await _enviarCopiaConLoader(
                    context: context,
                    correoDestino: correoCentro,
                    enviarCorreoResend: enviarCorreoResend,
                    asunto: "Solicitud de documentos para $nombreServicio - $numeroSeguimiento",
                    // ⬇️ Prefacio V3 con datos del acudiente
                    prefacio: generarPrefacioCentroReclusionV3(
                      centroPenitenciario: centroPenitenciario,
                      nombrePpl: nombrePpl,
                      apellidoPpl: apellidoPpl,
                      identificacionPpl: identificacionPpl,
                      nui: nui,
                      td: td,
                      patio: patio,
                      beneficioPenitenciario: beneficioPenitenciario,
                      juzgadoEp: juzgadoEp,
                      parentescoAcudiente: parentescoAcudiente,
                      nombreAcudiente: nombreAcudiente,
                      apellidoAcudiente: apellidoAcudiente,
                      identificacionAcudiente: identificacionAcudiente,
                      celularAcudiente: celularAcudiente,
                      celularWhatsapp: celularWhatsapp,
                      periodoDesde: periodoDesde,
                      periodoHasta: periodoHasta,

                    ),
                    mensajeExito: "El correo al centro de reclusión fue enviado correctamente.",
                    idDocumentoSolicitud: idDocumentoSolicitud,
                    tipoEnvio: "centro_reclusion",
                    htmlFinal: ultimoHtmlEnviado ?? "",
                    ultimoHtmlEnviado: ultimoHtmlEnviado,
                    nombreColeccionFirestore: nombreColeccionFirestore,
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

    // 3️⃣ Reparto (igual que V3)
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
                            TextSpan(text: correo, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(child: const Text("Cancelar"), onPressed: () => Navigator.of(ctx2).pop(false)),
                        TextButton(child: const Text("Enviar"), onPressed: () => Navigator.of(ctx2).pop(true)),
                      ],
                    ),
                  );

                  if (confirmarEnvio != true) return;

                  if (context.mounted) {
                    final prefacioReparto = """
<p style="margin: 0;"><strong>Entidad reparto:</strong></p>
<p style="margin: 4px 0 12px 0; font-size: 16px; font-weight: bold;">$entidad</p>
<p style="margin: 20px 0 0 0;">Estimados señores:</p>
<p style="margin: 8px 0 0 0;">Solicitamos amablemente su importante gestión para que sea remitido a la autoridad competente.</p>
<hr style="border: none; height: 1px; background-color: #ccc; margin-top: 20px; margin-bottom: 12px;">
""";

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
                      nombrePathStorage: nombrePathStorage,
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

    // 4️⃣ WhatsApp (igual)
    final notificarWhatsapp = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("¿Enviar Notificación?"),
        content: const Text("¿Deseas notificar al usuario del envío por WhatsApp?"),
        actions: [
          TextButton(child: const Text("No"), onPressed: () => Navigator.of(ctx).pop(false)),
          TextButton(child: const Text("Sí, enviar"), onPressed: () => Navigator.of(ctx).pop(true)),
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
      final htmlConEncabezado = _generarHtmlUniforme(
        correoDestino: correoDestino,
        contenidoHtml: """
${prefacio ?? ''}
<hr style="margin: 12px 0; border: 0; border-top: 1px solid #ccc;">
${ultimoHtmlEnviado ?? htmlFinal}
""",
      );

      await enviarCorreoResend(
        correoDestino: correoDestino,
        asuntoPersonalizado: asunto,
        prefacioHtml: prefacio,
      );

      await _guardarHtmlCorreo(
        idDocumento: idDocumentoSolicitud,
        htmlFinal: htmlConEncabezado,
        tipoEnvio: tipoEnvio,
        nombrePathStorage: nombrePathStorage,
        nombreColeccionFirestore: nombreColeccionFirestore,
      );

      await _guardarCorreoDestinoEnDoc(
        nombreColeccionFirestore: nombreColeccionFirestore,
        idDocumentoSolicitud: idDocumentoSolicitud,
        tipoEnvio: tipoEnvio,
        correoDestino: correoDestino,
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
              TextButton(onPressed: () => Navigator.of(ctx3).pop(), child: const Text("Cerrar")),
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

  Future<void> _guardarCorreoDestinoEnDoc({
    required String nombreColeccionFirestore,
    required String idDocumentoSolicitud,
    required String tipoEnvio,
    required String correoDestino,
    bool esPrimerEnvioPosible = false,
  }) async {
    String? keyDest;
    switch (tipoEnvio) {
      case 'principal':
        keyDest = 'principal';
        break;
      case 'centro_reclusion':
        keyDest = 'centro_reclusion';
        break;
      case 'reparto':
        keyDest = 'reparto';
        break;
    }

    final docRef = FirebaseFirestore.instance
        .collection(nombreColeccionFirestore)
        .doc(idDocumentoSolicitud);

    final update = <String, dynamic>{
      'correoHtmlCorreo.$tipoEnvio': correoDestino,
      if (keyDest != null) 'destinatarios.$keyDest': correoDestino,
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
