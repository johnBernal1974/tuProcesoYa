// lib/services/log_correos_manual.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Crea manualmente un registro en `log_correos` para CENTRO DE RECLUSIÓN
/// y sincroniza los campos espejo del documento principal.
/// NO envía correo; solo escribe en Firestore.
///
/// - [coleccion] p.ej. 'domiciliaria_solicitados' o 'redenciones_solicitados'
/// - [docId] id de la solicitud
/// - [correo] destinatario que se usó
/// - [asunto] asunto que se usó al enviar
/// - [htmlUrl] URL pública del HTML en Storage (si no la pasas, intenta leer del doc)
/// - [fecha] si quieres backdatear el tiempo real; si es null, usa serverTimestamp
Future<void> registrarLogCentroReclusionManual({
  required String coleccion,
  required String docId,
  required String correo,
  required String asunto,
  String? htmlUrl,
  DateTime? fecha,
}) async {
  final docRef = FirebaseFirestore.instance.collection(coleccion).doc(docId);

  // Si no me pasan htmlUrl intento leerla del doc:
  String? url = htmlUrl;
  if (url == null || url.isEmpty) {
    final snap = await docRef.get();
    final data = snap.data() as Map<String, dynamic>?;
    url = (data?['correosGuardados']?['centro_reclusion'] as String?) ??
        (data?['correoHtmlCorreo']?['centro_reclusion'] as String?);
  }

  final ts = fecha != null ? Timestamp.fromDate(fecha) : FieldValue.serverTimestamp();

  // 1) Crear entrada en subcolección log_correos
  await docRef.collection('log_correos').add({
    'to': [correo],
    'subject': asunto,
    if (url != null) 'htmlUrl': url,
    'timestamp': ts,
    'tipo': 'centro_reclusion',
    'esRespuesta': false,
    'destinatario': correo,
  });

  // 2) Sincronizar campos del doc principal
  await docRef.set({
    if (url != null) 'correosGuardados.centro_reclusion': url,
    'fechaHtmlCorreo.centro_reclusion': ts,
    'correoHtmlCorreo.centro_reclusion': correo,
    'correoHtmlCorreo_historial.centro_reclusion': FieldValue.arrayUnion([correo]),
    'ultimoEnvio': ts,
  }, SetOptions(merge: true));
}
