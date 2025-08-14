import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class ImpulsoCorreoManagerV1 {
  ImpulsoCorreoManagerV1({this.ccSoporte = 'peticiones@tuprocesoya.com'});

  final String ccSoporte;

  /// Sube el HTML a Storage y retorna la URL
  Future<String?> _subirHtmlAStorage({
    required String nombrePathStorage, // ej: "redenciones"
    required String docId,             // id de la solicitud
    required String tipoEnvio,         // "principal" | "centro_reclusion" | "reparto"
    required String htmlFinal,
    String nombreArchivo = '',
  }) async {
    final bytes = utf8.encode(htmlFinal);
    final fileName = (nombreArchivo.isNotEmpty)
        ? nombreArchivo
        : 'impulso_$tipoEnvio.html';
    final filePath = '$nombrePathStorage/$docId/correos/$fileName';

    final ref = FirebaseStorage.instance.ref(filePath);
    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: 'text/html'),
    );
    return await ref.getDownloadURL();
  }

  /// Guarda en el doc principal los metadatos del impulso (URL, fechas, destinatarios, flags)
  Future<void> _registrarImpulsoEnDoc({
    required String coleccion,
    required String docId,
    required String tipoEnvio,
    required String correoDestino,
    String? htmlUrl,
  }) async {
    final docRef = FirebaseFirestore.instance.collection(coleccion).doc(docId);

    final update = <String, dynamic>{
      // URL y fecha del HTML del impulso
      if (htmlUrl != null) 'impulsosGuardados.$tipoEnvio': htmlUrl,
      'fechaHtmlImpulso.$tipoEnvio': FieldValue.serverTimestamp(),

      // destinatario actual e historial
      'impulsoDestinatarios.$tipoEnvio': correoDestino,
      'impulso_historial.$tipoEnvio': FieldValue.arrayUnion([correoDestino]),

      // banderas y últimos tiempos
      'yaSeEnvioImpulso': true,
      'ultimoImpulso': FieldValue.serverTimestamp(),

      // último impulso (snapshot rápido)
      'impulso': {
        'fechaEnvio': FieldValue.serverTimestamp(),
        'destinatario': correoDestino,
        'tipo': tipoEnvio,
      },
    };

    await docRef.set(update, SetOptions(merge: true));
  }

  /// Log en subcolección `log_correos`
  Future<void> _logCorreo({
    required String coleccion,
    required String docId,
    required String correoDestino,
    required String html,
    required String subject,
    required String tipoEnvio, // lo guardamos como subtipo para auditoría
  }) async {
    final docRef = FirebaseFirestore.instance.collection(coleccion).doc(docId);
    await docRef.collection('log_correos').add({
      'to': [correoDestino],
      'cc': [ccSoporte],
      'subject': subject,
      'html': html,
      'timestamp': FieldValue.serverTimestamp(),
      'tipo': 'impulso_procesal',
      'subtipo': tipoEnvio, // "principal" | "centro_reclusion" | "reparto"
    });
  }

  /// API principal: envía y registra TODO para un impulso
  ///
  /// - `enviarCorreoFn` debe enviar el correo real (tu CF/Resend) con el `html` provisto.
  /// - Sube HTML a Storage (si `subirAStorage = true`) y deja URL en el doc.
  Future<void> enviarYRegistrarImpulso({
    required String coleccion,             // ej: "redenciones_solicitados"
    required String docId,                 // id del documento
    required String tipoEnvio,             // "principal" | "centro_reclusion" | "reparto"
    required String correoDestino,
    required String html,                  // HTML FINAL del impulso
    required String subject,               // ej: "Impulso procesal – 123456"
    required String nombrePathStorage,     // ej: "redenciones"

    // tu función real de envío (CF/Resend). Debe enviar el HTML tal cual.
    required Future<void> Function({
    required String correoDestino,
    required String html,
    String? subject,
    String? cc,
    }) enviarCorreoFn,

    bool subirAStorage = true,
    String nombreArchivo = '',             // opcional: nombre fijo del archivo
  }) async {
    // 1) Enviar el correo real
    await enviarCorreoFn(
      correoDestino: correoDestino,
      html: html,
      subject: subject,
      cc: ccSoporte,
    );

    // 2) Log en subcolección
    await _logCorreo(
      coleccion: coleccion,
      docId: docId,
      correoDestino: correoDestino,
      html: html,
      subject: subject,
      tipoEnvio: tipoEnvio,
    );

    // 3) Subir HTML a Storage
    String? url;
    if (subirAStorage) {
      url = await _subirHtmlAStorage(
        nombrePathStorage: nombrePathStorage,
        docId: docId,
        tipoEnvio: tipoEnvio,
        htmlFinal: html,
        nombreArchivo: nombreArchivo.isEmpty
            ? 'impulso_$tipoEnvio.html'
            : nombreArchivo,
      );
    }

    // 4) Registrar en el documento principal (URL, fechas, flags, etc.)
    await _registrarImpulsoEnDoc(
      coleccion: coleccion,
      docId: docId,
      tipoEnvio: tipoEnvio,
      correoDestino: correoDestino,
      htmlUrl: url,
    );
  }

  /// Por si quieres un wrapper de HTML con encabezado estándar (opcional)
  String wrapHtmlConEncabezado({
    required String correoDestino,
    required String contenidoHtml,
  }) {
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    return """
<meta charset="UTF-8">
<div style="max-width:750px;margin:auto;padding:20px;font-family:Arial,sans-serif;font-size:12px;line-height:1.5">
  <p style="margin:0"><b>De:</b> peticiones@tuprocesoya.com</p>
  <p style="margin:0"><b>Para:</b> $correoDestino</p>
  <p style="margin:0 0 10px 0"><b>Fecha de Envío:</b> $fecha</p>
  <hr style="border:none;height:1px;background:#ccc;margin:12px 0">
  $contenidoHtml
</div>
""";
  }
}
