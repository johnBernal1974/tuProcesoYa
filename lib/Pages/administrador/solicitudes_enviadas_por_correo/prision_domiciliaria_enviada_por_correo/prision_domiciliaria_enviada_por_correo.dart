
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/providers/ppl_provider.dart';
import 'dart:io'; // Necesario para manejar archivos en almacenamiento local
import 'package:universal_html/html.dart' as html;

import '../../../../commons/admin_provider.dart';
import '../../../../commons/archivoViewerWeb2.dart';
import '../../../../commons/main_layaout.dart';
import '../../../../models/ppl.dart';
import '../../../../plantillas/plantilla_impulso_procesal.dart';
import '../../../../src/colors/colors.dart';
import '../../../../widgets/boton_notificar_respuesta_correo.dart';
import '../../../../widgets/email_status_widget.dart';
import 'package:tuprocesoya/widgets/impulsos.dart' as imp;
import 'package:http/http.dart' as http;
import '../../../../widgets/seleccionar_correo_centro_copia_correo.dart';


class SolicitudesPrisionDomiciliariaEnviadasPorCorreoPage extends StatefulWidget {
  final String status;
  final String idDocumento;
  final String numeroSeguimiento;
  final String categoria;
  final String subcategoria;
  final String fecha;
  final String idUser;
  final String direccion;
  final String municipio;
  final String departamento;
  final String nombreResponsable;
  final String cedulaResponsable;
  final String celularResponsable;
  final String reparacion;

  // Archivos adjuntos generales
  final List<String> archivos;

  // Nuevos campos específicos de prisión domiciliaria
  final String? urlArchivoCedulaResponsable;
  final List<String> urlsArchivosHijos;
  final bool sinRespuesta;

  const SolicitudesPrisionDomiciliariaEnviadasPorCorreoPage({
    super.key,
    required this.status,
    required this.idDocumento,
    required this.numeroSeguimiento,
    required this.categoria,
    required this.subcategoria,
    required this.fecha,
    required this.idUser,
    required this.archivos,
    this.urlArchivoCedulaResponsable,
    this.urlsArchivosHijos = const [],
    required this.direccion,
    required this.municipio,
    required this.departamento,
    required this.nombreResponsable,
    required this.cedulaResponsable,
    required this.celularResponsable,
    required this.sinRespuesta,
    required this.reparacion,

  });


  @override
  State<SolicitudesPrisionDomiciliariaEnviadasPorCorreoPage> createState() => _SolicitudesPrisionDomiciliariaEnviadasPorCorreoPageState();
}

class _SolicitudesPrisionDomiciliariaEnviadasPorCorreoPageState extends State<SolicitudesPrisionDomiciliariaEnviadasPorCorreoPage> {
  late PplProvider _pplProvider;
  Ppl? userData;
  bool isLoading = true; // Bandera para controlar la carga
  int diasEjecutado = 0;
  int mesesEjecutado = 0;
  int diasEjecutadoExactos = 0;
  int diasRestante = 0;
  int mesesRestante = 0;
  int diasRestanteExactos = 0;
  double porcentajeEjecutado =0;
  int tiempoCondena =0;
  List<String> archivos = [];
  String consideraciones = "";
  String fundamentosDeDerecho = "";
  String peticionConcreta = "";
  String diligencio = '';
  String reviso = '';
  String envio = '';
  DateTime? fechaEnvio;
  DateTime? fechaDiligenciamiento;
  DateTime? fechaRevision;
  String rol = AdminProvider().rol ?? "";
  Map<String, dynamic>? solicitudData;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _pplProvider = PplProvider();
    archivos = List<String>.from(widget.archivos); // Copia los archivos una vez
    fetchUserData();

  }


  @override
  Widget build(BuildContext context) {
    final normalizedStatus = widget.status.trim().toLowerCase();
    return MainLayout(
      pageTitle: 'Prisión Domiciliaria Enviada - ${normalizedStatus == "enviado"
          ? "Enviado"
          : normalizedStatus == "concedido"
          ? "Concedido"
          : normalizedStatus == "negado"
          ? "Negado"
          : widget.status}',
      content: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width >= 1000
                ? 1500
                : double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isWide = constraints.maxWidth > 800;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                            builder: (context, constraints) {
                              bool isMobile = constraints.maxWidth < 800; // Detectar si es móvil

                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: isMobile
                                        ? Column( // En móviles, disposición en columna
                                      children: [
                                        if (widget.sinRespuesta && widget.status == 'Enviado')
                                          _buildWarningMessage(),
                                        const SizedBox(height: 10),
                                        //if (widget.sinRespuesta && rol != "pasante 1") _buildTutelaButton(context),
                                        const SizedBox(height: 15)
                                      ],
                                    )

                                        : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        if (widget.sinRespuesta && widget.status == 'Enviado')
                                          Flexible(child: _buildWarningMessage()),

                                        const SizedBox(width: 50),

                                        // if (widget.sinRespuesta && rol != "pasante 1")
                                        //   SizedBox(width: 200, child: _buildTutelaButton(context)),
                                        const Divider(color: Colors.red, height: 1),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                      const SizedBox(height: 30),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 4, child: _buildMainContent()),
                            const SizedBox(width: 50),
                            Expanded(
                              flex: 3,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 30),
                                    const Text(
                                      "📡 Estado del envío",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    ListaCorreosWidget(
                                      solicitudId: widget.idDocumento,
                                      nombreColeccion: "domiciliaria_solicitados",
                                      onTapCorreo: _mostrarDetalleCorreo,
                                    ),
                                    const SizedBox(height: 20),
                                    BotonNotificarRespuestaWhatsApp(
                                      docId: widget.idDocumento,
                                      servicio: "Prisión domiciliaría",
                                      seguimiento: widget.numeroSeguimiento,
                                      seccionHistorial: "Prisión domiciliaria",
                                    ),
                                    const SizedBox(height: 20),
                                    _buildImpulsoBanner(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildMainContent(),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 30),
                                  const Text(
                                    "📡 Estado del envío",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  ListaCorreosWidget(
                                    solicitudId: widget.idDocumento,
                                    nombreColeccion: "domiciliaria_solicitados",
                                    onTapCorreo: _mostrarDetalleCorreo,
                                  ),
                                  const SizedBox(height: 20),
                                  BotonNotificarRespuestaWhatsApp(
                                    docId: widget.idDocumento,
                                    servicio: "Prisión domiciliaría",
                                    seguimiento: widget.numeroSeguimiento,
                                    seccionHistorial: "Prisión domiciliaria",
                                  ),
                                  const SizedBox(height: 20),
                                  _buildImpulsoBanner(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }


  ///PARA IMPULSO


  Widget _fallbackAbrirEnPestana(String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("No se pudo cargar el cuerpo del correo.", style: TextStyle(color: Colors.red)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => abrirHtmlParaImprimir(url),
          child: Text(
            "Abrir contenido en una pestaña",
            style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }

  List<imp.CorreoDestino> _obtenerCorreosDestinatarios() {
    final list = <imp.CorreoDestino>[];
    final seen = <String>{};

    void add(String? e, String tag) {
      final s = (e ?? '').trim();
      if (s.isEmpty || !s.contains('@')) return;
      if (seen.add(s)) list.add(imp.CorreoDestino(s, tag));
    }

    // 1) Leer el mapa canónico normalizado por fetchUserData()
    final raw = solicitudData?['__correosImpulso'];
    Map<String, String> m = {};
    if (raw is Map) {
      // fuerza a String->String de forma segura
      m = raw.map((k, v) => MapEntry(k.toString(), (v ?? '').toString()));
    }

    debugPrint('[Impulso] __correosImpulso (tipo=${raw.runtimeType}): $raw');

    add(m['principal'], 'Principal');
    add(m['centro_reclusion'], 'Centro reclusión');
    add(m['reparto'], 'Reparto');

    // 2) Fallback: si por cualquier razón sigue vacío, intenta desde otros nodos
    if (list.isEmpty) {
      // a) destinatarios.*
      final dest = solicitudData?['destinatarios'];
      if (dest is Map) {
        add(dest['principal']?.toString(), 'Principal');
        add(dest['centro_reclusion']?.toString(), 'Centro reclusión');
        add(dest['reparto']?.toString(), 'Reparto');
      }

      // b) correoHtmlCorreo.*
      final chc = solicitudData?['correoHtmlCorreo'];
      if (chc is Map) {
        add(chc['principal']?.toString(), 'Principal');
        add(chc['centro_reclusion']?.toString(), 'Centro reclusión');
        add(chc['reparto']?.toString(), 'Reparto');
      }

      // c) historial (toma el último de cada array)
      String? lastOf(List? arr) =>
          (arr != null && arr.isNotEmpty) ? arr.last?.toString() : null;

      final histP = lastOf(solicitudData?['correoHtmlCorreo_historial.principal'] as List?);
      final histC = lastOf(solicitudData?['correoHtmlCorreo_historial.centro_reclusion'] as List?);
      final histR = lastOf(solicitudData?['correoHtmlCorreo_historial.reparto'] as List?);

      add(histP, 'Principal');
      add(histC, 'Centro reclusión');
      add(histR, 'Reparto');
    }

    debugPrint('[Impulso] correos extraídos: '
        '${list.map((c) => '${c.etiqueta}:${c.email}').join(', ')}');
    return list;
  }

  // Helper: convierte la etiqueta visible a la key estándar del documento
  String _etiquetaToKey(String etq) {
    final e = etq.toLowerCase();
    if (e.contains('centro')) return 'centro_reclusion';
    if (e.contains('reparto')) return 'reparto';
    return 'principal';
  }

  Widget _buildImpulsoBanner() {
    // 🔎 LOG 1: entrada
    debugPrint('[Gate] entra _buildImpulsoBanner '
        'status=${widget.status} sinResp=${widget.sinRespuesta} fechaEnvio=$fechaEnvio');

    // 1) Debe estar Enviado + sinRespuesta
    final estEnviado = widget.status.trim().toLowerCase() == 'enviado';
    if (!(estEnviado && widget.sinRespuesta)) {
      debugPrint('[Gate] oculto: condiciones estado/sinRespuesta no cumplen '
          '(estEnviado=$estEnviado sinResp=${widget.sinRespuesta})');
      return const SizedBox.shrink();
    }

    // 2) Debe existir fechaEnvio
    if (fechaEnvio == null) {
      debugPrint('[Gate] oculto: fechaEnvio == null');
      return const SizedBox.shrink();
    }

    // 3) Correos disponibles
    final correos = _obtenerCorreosDestinatarios();
    if (correos.isEmpty) {
      debugPrint('[Gate] oculto: correos vacíos');
      return const SizedBox.shrink();
    }

    // 4) Plazo
    final int diasPlazo = (solicitudData?['plazoImpulsoDias'] as int?) ?? 15;
    final int diasTranscurridos = DateTime.now().difference(fechaEnvio!).inDays;

    // 5) NUEVO: Estado por correo leído del mapa estable por ETIQUETA
    final Map<String, dynamic> impulsoMap =
        (solicitudData?['impulso'] as Map?)
            ?.map((k, v) => MapEntry(k.toString(), v)) ?? {};

    final estadoPorCorreo = <String, dynamic>{};
    for (final c in correos) {
      final key = _etiquetaToKey(c.etiqueta);
      estadoPorCorreo[c.email] = impulsoMap[key]; // será null si está pendiente
    }

    debugPrint('[Gate] listo para montar banner: '
        'fechaEnvio=$fechaEnvio diasTranscurridos=$diasTranscurridos '
        'diasPlazo=$diasPlazo correos=${correos.length}');

    // 6) Montar el banner
    return imp.ImpulsoProcesalBanner(
      fechaUltimoEnvio: fechaEnvio!.toLocal(),
      diasPlazo: diasPlazo,
      correos: correos,
      estadoPorCorreo: estadoPorCorreo,

      // ---------- PREVIEW HTML ----------
      buildPreviewHtml: (correoSeleccionado) async {
        final c = correos.firstWhere((x) => x.email == correoSeleccionado);

        final dirigido = _resolverSaludo(c);
        final entidad  = _resolverEntidad(c);

        // Traer el correo anterior de ese mismo destinatario
        final htmlAnterior = await _buscarHtmlAnteriorPorDestino(correoSeleccionado);

        // Plantilla tal cual la tienes
        final tpl = ImpulsoProcesalTemplate(
          dirigido: dirigido,
          entidad: entidad,
          servicio: widget.subcategoria,
          numeroSeguimiento: widget.numeroSeguimiento,
          fechaEnvioInicial: fechaEnvio,
          diasPlazo: diasPlazo,
          nombrePpl: userData?.nombrePpl ?? '',
          apellidoPpl: userData?.apellidoPpl ?? '',
          identificacionPpl: userData?.numeroDocumentoPpl ?? '',
          centroPenitenciario: (userData?.centroReclusion ?? '').toString(),
          nui: userData?.nui ?? '',
          td: userData?.td ?? '',
          patio: userData?.patio ?? '',
          htmlAnterior: htmlAnterior,
          logoUrl: "https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635",
          ocultarSegundaLineaSiRedundante: true,
        );

        final htmlBase = tpl.generarHtml();
        // 👇 Envolvemos con De/Para/Fecha para la PREVIEW
        return _wrapEnvelopePreview(
          para: correoSeleccionado,
          contenidoHtml: htmlBase,
        );
      },

      // ---------- ENVÍO (Storage + Cloud Function) ----------
      enviarImpulso: ({
        required String correoDestino,
        required String html,
        required String etiqueta,
      }) async {
        final firestore = FirebaseFirestore.instance;
        final docRef = firestore
            .collection('domiciliaria_solicitados')
            .doc(widget.idDocumento);

        final now = DateTime.now();

        // Idempotencia simple (por día)
        final hoy0 = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
        final rawToken = '$correoDestino|$hoy0|${html.hashCode}';
        final idempotencyToken = rawToken.hashCode.toString();

        // Asunto
        final subject = 'Impulso procesal – ${widget.subcategoria} – ${widget.numeroSeguimiento}';

        // === Envoltorio ANCHO para ENVIAR (izquierda, sin centrar) ===
        // 1) Si viene de la PREVIEW, quitamos su wrapper y nos quedamos con el HTML real
        final String base = _extractInnerFromPreview(html);

        // 2) Si ya viene envuelto para enviar, lo respetamos; si no, lo envolvemos
        final String htmlParaEnviar = _isSendWrapped(base)
            ? base
            : _wrapEnvelopeSend(para: correoDestino, contenidoHtml: base);

        // 1) Llamar Cloud Function (NO crear log ni subir a Storage desde el cliente)
        final urlCF = Uri.parse(
          "https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/sendEmailWithResend",
        );

        final payload = {
          'to': [correoDestino],
          'subject': subject,
          'html': htmlParaEnviar,
          'archivos': [],
          'idDocumento': widget.idDocumento,
          'enviadoPor': FirebaseAuth.instance.currentUser?.phoneNumber
              ?? FirebaseAuth.instance.currentUser?.email
              ?? 'app',
          'tipo': 'domiciliaria',
          'idempotency': idempotencyToken,
        };

        final resp = await http.post(
          urlCF,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        if (resp.statusCode < 200 || resp.statusCode >= 300) {
          throw Exception('CF respondió ${resp.statusCode}: ${resp.body}');
        }

        // 2) Tomar urls devueltas por la CF (opcional, para mostrar en UI)
        String? htmlUrlFromCF;
        try {
          final m = jsonDecode(resp.body) as Map<String, dynamic>;
          htmlUrlFromCF = (m['htmlUrl'] ?? m['html_url'])?.toString();
        } catch (_) {}

        // 3) Guardar estado por EMAIL (solo el nodo impulso, SIN log cliente)
        final impulsoKey = _etiquetaToKey(etiqueta); // principal | centro_reclusion | reparto
        await docRef.update({
          'impulso.$impulsoKey': {
            'fechaEnvio': FieldValue.serverTimestamp(),
            'destinatario': correoDestino,
            'htmlUrl': htmlUrlFromCF,
            'subject': subject,
            'etiqueta': etiqueta,
            'idempotency': idempotencyToken,
          },
        });
      },

      onEnviado: () => fetchUserData(),
    );
  }

  Map<String, dynamic>? _findImpulsoLeaf(
      Map<String, dynamic> obj, {
        String? emailKey,
        String? subject,
      }) {
    for (final entry in obj.entries) {
      final v = entry.value;
      if (v is Map) {
        final hasPayload = v.containsKey('htmlUrl') ||
            v.containsKey('html_url') ||
            v.containsKey('destinatario');
        if (hasPayload) {
          final dest = (v['destinatario'] ?? '').toString();
          final subj = (v['subject'] ?? '').toString();
          if ((emailKey != null && dest == emailKey) ||
              (subject != null && subj == subject) ||
              (emailKey == null && subject == null)) {
            return Map<String, dynamic>.from(v);
          }
        }
        final r = _findImpulsoLeaf(
          Map<String, dynamic>.from(v),
          emailKey: emailKey,
          subject: subject,
        );
        if (r != null) return r;
      }
    }
    return null;
  }

  /// Quita <html>, <head>, <body> para poder incrustar el correo anterior
  String _sanitizeInlineEmailHtml(String html) {
    var s = html;

    // Elimina DOCTYPE si viene
    s = s.replaceAll(RegExp(r'<!DOCTYPE[^>]*>', caseSensitive: false), '');

    // Quita <head>...</head> (insensible a mayúsculas y abarca saltos de línea)
    s = s.replaceAll(
      RegExp(r'<\s*head[^>]*>.*?</\s*head\s*>', caseSensitive: false, dotAll: true),
      '',
    );

    // Quita <html ...> y </html>
    s = s.replaceAll(RegExp(r'<\s*html[^>]*>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'</\s*html\s*>', caseSensitive: false), '');

    // Quita <body ...> y </body>
    s = s.replaceAll(RegExp(r'<\s*body[^>]*>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'</\s*body\s*>', caseSensitive: false), '');

    // (Opcional) quitar comentarios HTML
    s = s.replaceAll(RegExp(r'<!--.*?-->', caseSensitive: false, dotAll: true), '');

    return s.trim();
  }

// SOLO PARA LA VISTA PREVIA (bonito, centrado y con ancho limitado)
  String _wrapEnvelopePreview({
    required String para,
    required String contenidoHtml,
    String de = 'peticiones@tuprocesoya.com',
  }) {
    final inner = _sanitizeInlineEmailHtml(contenidoHtml);
    final fecha = DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now());

    return '''
<!--TPY:ENV:PREVIEW-->
<meta charset="UTF-8">
<div style="width:100%;font-family:Arial,sans-serif;font-size:14px;line-height:1.5;color:#111;">
  <div style="max-width: 780px; margin: 0 auto; padding: 16px;">
    <p style="margin:0;"><strong>De:</strong> $de</p>
    <p style="margin:0;"><strong>Para:</strong> $para</p>
    <p style="margin:0 0 10px 0;"><strong>Fecha de Envío:</strong> $fecha</p>
    <hr style="margin:12px 0; border:0; border-top:1px solid #ccc;">
    $inner
  </div>
</div>
''';
  }

// SOLO PARA ENVIAR (ocupando todo el ancho, alineado a la izquierda)
  String _wrapEnvelopeSend({
    required String para,
    required String contenidoHtml,
    String de = 'peticiones@tuprocesoya.com',
  }) {
    final inner = _sanitizeInlineEmailHtml(contenidoHtml);
    final fecha = DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now());

    return '''
<!--TPY:ENV:SEND-->
<meta charset="UTF-8">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"
       style="font-family:Arial,sans-serif;font-size:14px;line-height:1.5;color:#111;background:#fff;">
  <tr>
    <td align="left" style="padding:12px 8px;">
      <p style="margin:0;"><strong>De:</strong> $de</p>
      <p style="margin:0;"><strong>Para:</strong> $para</p>
      <p style="margin:0 0 10px 0;"><strong>Fecha de Envío:</strong> $fecha</p>
      <div style="height:1px;background:#ccc;margin:12px 0;"></div>
      $inner
    </td>
  </tr>
</table>
''';
  }

  /// Prefiere `html` plano; si no hay, intenta descargar `html_url`.
  Future<String?> _buscarHtmlAnteriorPorDestino(String emailDestino) async {
    final col = FirebaseFirestore.instance
        .collection('domiciliaria_solicitados')
        .doc(widget.idDocumento)
        .collection('log_correos');

    try {
      final qs = await col
          .where('to', arrayContains: emailDestino)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      // 1) Preferir html plano
      for (final d in qs.docs) {
        final data = d.data();
        final tipo = (data['tipo'] ?? '').toString().trim();
        if (tipo == 'impulso_procesal') continue;
        final h = (data['html'] as String?)?.trim();
        if (h != null && h.isNotEmpty) return _sanitizeInlineEmailHtml(h);
      }

      // 2) Intentar descargar html_url
      for (final d in qs.docs) {
        final data = d.data();
        final tipo = (data['tipo'] ?? '').toString().trim();
        if (tipo == 'impulso_procesal') continue;
        final url = (data['htmlUrl'] ?? data['html_url'])?.toString().trim();
        if (url != null && url.isNotEmpty) {
          try {
            final r = await http.get(Uri.parse(url));
            if (r.statusCode == 200) {
              final body = r.body.trim();
              if (body.isNotEmpty) return _sanitizeInlineEmailHtml(body);
            }
          } catch (_) { /* seguimos */ }
          // Fallback: deja un link si no se pudo incrustar
          return """
<div style="font-size:13px;color:#555;">
  <p><b>Correo enviado inicialmente (ver en línea):</b></p>
  <p><a href="$url" target="_blank" rel="noopener noreferrer">$url</a></p>
</div>
""";
        }
      }

      // 3) Último recurso: cualquiera no-impulso
      final qs2 = await col.orderBy('timestamp', descending: true).limit(20).get();
      for (final d in qs2.docs) {
        final data = d.data();
        final tipo = (data['tipo'] ?? '').toString().trim();
        if (tipo == 'impulso_procesal') continue;
        final h = (data['html'] as String?)?.trim();
        if (h != null && h.isNotEmpty) return _sanitizeInlineEmailHtml(h);
        final url = (data['htmlUrl'] ?? data['html_url'])?.toString().trim();
        if (url != null && url.isNotEmpty) {
          try {
            final r = await http.get(Uri.parse(url));
            if (r.statusCode == 200 && r.body.trim().isNotEmpty) {
              return _sanitizeInlineEmailHtml(r.body);
            }
          } catch (_) {}
          return """
<div style="font-size:13px;color:#555;">
  <p><b>Correo enviado inicialmente (ver en línea):</b></p>
  <p><a href="$url" target="_blank" rel="noopener noreferrer">$url</a></p>
</div>
""";
        }
      }
    } catch (e) {
      debugPrint('[Impulso] _buscarHtmlAnteriorPorDestino error: $e');
    }
    return null;
  }

  ///helper para la entidad de los impulsos
  String? _soloDespuesDeGuion(String? s) {
    if (s == null) return null;
    final i = s.indexOf('-');
    return (i >= 0) ? s.substring(i + 1).trim() : s.trim();
  }

  String _resolverSaludo(imp.CorreoDestino c) {
    final etq = c.etiqueta.toLowerCase();
    if (etq.contains('centro')) return 'Señor(a) Director(a)';
    if (etq.contains('reparto')) return 'Señores Oficina de Reparto';
    return 'Señor(a) Juez';
  }

  String _resolverEntidad(imp.CorreoDestino c) {
    final etq = c.etiqueta.toLowerCase();

    if (etq.contains('centro')) {
      // desde userData
      return _soloDespuesDeGuion(userData?.centroReclusion)
          ?? 'Centro de reclusión';
    }

    if (etq.contains('reparto')) {
      // si guardas el nombre exacto cuando seleccionas reparto
      final repartoNombre = (solicitudData?['entidadRepartoNombre'] as String?)?.trim();
      return _soloDespuesDeGuion(repartoNombre) ?? 'Oficina de Reparto';
    }

    // principal / juez (EPMS) — desde userData
    return _soloDespuesDeGuion(userData?.juzgadoEjecucionPenas)
        ?? 'Juzgado de Ejecución de Penas';
  }

  // ==== Helpers de detección/extracción del wrapper ====
  bool _isPreviewWrapped(String html) => html.contains('TPY:ENV:PREVIEW');
  bool _isSendWrapped(String html) => html.contains('TPY:ENV:SEND');

  /// Extrae el contenido real:
  /// - de PREVIEW: lo que va después del <hr>
  /// - de SEND: lo que va después del divisor (la línea gris)
  String _stripEnvelopeHtml(String html) {
    var s = html;

    // 1) Si es PREVIEW, tomar después del <hr>
    if (_isPreviewWrapped(s)) {
      final m = RegExp(r'<hr[^>]*>(.*)$', caseSensitive: false, dotAll: true).firstMatch(s);
      s = (m != null ? m.group(1)! : s);
    }

    // 2) Si es SEND, tomar después del divisor (línea gris)
    if (_isSendWrapped(s)) {
      // a) Caso típico: <div style="height:1px;background:#ccc;..."></div>
      final mDiv = RegExp(
        r'<div[^>]*?(height\s*:\s*1px|border-top\s*:\s*1px)[^>]*?></div>(.*)$',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(s);

      if (mDiv != null) {
        s = mDiv.group(2)!;
      } else {
        // b) Fallback: si no encontramos el divisor, intenta tomar el contenido del <td>…</td>
        final mTd = RegExp(r'<td[^>]*>(.*)</td>', caseSensitive: false, dotAll: true).firstMatch(s);
        if (mTd != null) {
          s = mTd.group(1)!;
        }
      }
    }

    // 3) Quitar <meta ...> que puedan quedar sueltos
    s = s.replaceAll(RegExp(r'<meta[^>]*>', caseSensitive: false), '');

    return s.trim();
  }


// Extrae el contenido real del preview (lo que va después del <hr>)
  String _extractInnerFromPreview(String html) {
    if (!_isPreviewWrapped(html)) return html;
    final m = RegExp(r'<hr[^>]*>(.*)$', caseSensitive: false, dotAll: true).firstMatch(html);
    return (m != null ? m.group(1)! : html).trim();
  }

  /// ACA TERMINA ELM TEMA DE IMPULSOS



  Widget _buildTutelaButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        side: const BorderSide(width: 1, color: Colors.red),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      onPressed: () async {
        bool confirmarTutela = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              "Confirmación",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text("¿Está seguro de que desea enviar esta solicitud a Tutela?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar", style: TextStyle(color: Colors.black)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text("Sí, enviar", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        if (confirmarTutela) {
          print("📢 La solicitud ha sido enviada a Tutela.");
        }
      },
      child: const Text("hola"),
    );
  }

  // Widget para el mensaje de advertencia
  Widget _buildWarningMessage() {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red, width: 1.5),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning, color: Colors.red),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Sin obtener respuesta de la autoridad competente.",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }


  /// 🖥️📱 Widget de contenido principal (sección izquierda en PC)
  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFechaHoy(),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final fontSize = isMobile ? 20.0 : 28.0;

            return Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: widget.status == "Concedido"
                        ? Colors.green
                        : widget.status == "Negado"
                        ? Colors.red
                        : Colors.blue, // Azul para Enviado
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  "Prisión domiciliaria - ${widget.status == "Enviado"
                      ? "Enviado"
                      : widget.status == "Concedido"
                      ? "Concedido"
                      : widget.status == "Negado"
                      ? "Negado"
                      : widget.status}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                    color: widget.status == "Concedido"
                        ? Colors.green
                        : widget.status == "Negado"
                        ? Colors.red
                        : Colors.blue, // Mismo color del estado
                  ),
                ),
              ],
            );
          },
        ),
        Row(
          children: [
            Text(
              "Solicitado por: ${userData?.nombreAcudiente ?? "Sin información"} ${userData?.apellidoAcudiente ?? "Sin información"}",
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              "PPL: ${userData?.nombrePpl ?? "Sin información"} ${userData?.apellidoPpl ?? "Sin información"}",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildDetallesSolicitud(),
        const SizedBox(height: 15),
        _buildInformacionUsuarioWidget(
          direccion: widget.direccion,
          departamento: widget.departamento,
          municipio: widget.municipio,
          nombreResponsable: widget.nombreResponsable,
          cedulaResponsable: widget.cedulaResponsable,
          celularResponsable: widget.celularResponsable,
          hijos: solicitudData?.containsKey('hijos') == true
              ? List<Map<String, String>>.from(
              solicitudData!['hijos'].map((h) => Map<String, String>.from(h)))
              : [],
        ),
        const SizedBox(height: 30),
        const Row(
          children: [
            Icon(Icons.attach_file),
            Text("Archivos adjuntos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 30),

        /// 📂 **Mostramos los archivos aquí**
        archivos.isNotEmpty
            ? ArchivoViewerWeb2(archivos: archivos)
            : const Text(
          "El usuario no compartió ningún archivo",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red),
        ),
        const SizedBox(height: 30),
        if (widget.urlArchivoCedulaResponsable != null && widget.urlArchivoCedulaResponsable!.isNotEmpty) ...[
          const Text("🪪 Cédula del responsable", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ArchivoViewerWeb2(archivos: [widget.urlArchivoCedulaResponsable!]),
          const SizedBox(height: 20),
        ],

        if (widget.urlsArchivosHijos.isNotEmpty) ...[
          const Text("👶 Documentos de identidad de los hijos", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ArchivoViewerWeb2(archivos: widget.urlsArchivosHijos),
          const SizedBox(height: 20),
        ],

        const Divider(color: gris),
        const SizedBox(height: 50),
        datosDeLaborAdmin()
        //vistaPreviaDerechoPeticion(userData, consideraciones, fundamentosDeDerecho, peticionConcreta),
      ],
    );
  }

  Widget _buildInformacionUsuarioWidget({
    required String direccion,
    required String departamento,
    required String municipio,
    required String nombreResponsable,
    required String cedulaResponsable,
    required String celularResponsable,
    List<Map<String, String>> hijos = const [], // ← Añadido por defecto
  }) {
    TextStyle labelStyle = const TextStyle(fontSize: 12);
    TextStyle valueStyle = const TextStyle(fontSize: 12, fontWeight: FontWeight.bold);

    return Card(
      surfaceTintColor: blanco,
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Información suministrada por el Usuario",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            const Text("Lugar registrado para la prisión domiciliaria", style: TextStyle(fontSize: 12)),
            Row(
              children: [
                Text("Dirección: ", style: labelStyle),
                Expanded(
                  child: Text(
                    '$direccion, $municipio, $departamento',
                    style: valueStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: gris),
            const SizedBox(height: 12),
            const Text(
              "Persona que se hace responsable en el Domicilio",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text("Nombres y apellidos: ", style: labelStyle),
                Expanded(child: Text(nombreResponsable, style: valueStyle)),
              ],
            ),
            Row(
              children: [
                Text("Número de identificación: ", style: labelStyle),
                Expanded(child: Text(cedulaResponsable, style: valueStyle)),
              ],
            ),
            Row(
              children: [
                Text("Teléfono Celular: ", style: labelStyle),
                Expanded(child: Text(celularResponsable, style: valueStyle)),
              ],
            ),

            // 👶 Sección adicional si hay hijos
            if (hijos.isNotEmpty) ...[
              const Divider(height: 20, color: gris),
              const Text(
                "Hijos que convivirán en el domicilio",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ...hijos.map((hijo) {
                final nombre = hijo['nombre'] ?? '';
                final edad = hijo['edad'] ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text("$nombre - $edad años", style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1, color: gris),
            const SizedBox(height: 12),
            infoReparacionVictima(
                reparacion: widget.reparacion
            ),
          ],
        ),
      ),
    );
  }

  Widget infoReparacionVictima({required String reparacion}) {
    final descripciones = {
      "reparado": {
        "texto": "Se ha reparado a la víctima.",
        "icono": Icons.volunteer_activism,
        "color": Colors.green,
      },
      "garantia": {
        "texto": "Se ha asegurado el pago de la indemnización mediante garantía personal, real, bancaria o acuerdo de pago.",
        "icono": Icons.verified_user,
        "color": Colors.blue,
      },
      "insolvencia": {
        "texto": "No se ha reparado a la víctima ni asegurado el pago de la indemnización debido a estado de insolvencia.",
        "icono": Icons.warning_amber_rounded,
        "color": Colors.orange,
      },
    };

    final info = descripciones[reparacion];

    if (info == null) {
      return const ListTile(
        leading: Icon(Icons.help_outline, color: Colors.grey),
        title: Text("Información no disponible.", style: TextStyle(fontSize: 14)),
      );
    }

    return ListTile(
      leading: Icon(info["icono"] as IconData, color: info["color"] as Color),
      title: Text(
        info["texto"] as String,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 📅 Muestra la fecha de hoy en formato adecuado
  Widget _buildFechaHoy() {
    return Text(
      'Hoy es: ${DateFormat('d \'de\' MMMM \'de\' y', 'es').format(DateTime.now())}',
      style: const TextStyle(fontSize: 12),
    );
  }

  /// 📌 Muestra detalles de la solicitud (seguimiento, categoría, fecha, subcategoría)
  Widget _buildDetallesSolicitud() {
    double fontSize = MediaQuery.of(context).size.width < 600 ? 10 : 12; // Tamaño más pequeño en móviles
    bool isMobile = MediaQuery.of(context).size.width < 600; // Verifica si es móvil

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Asegurar alineación izquierda en móviles
        children: [
          isMobile
              ? Column( // En móviles, mostrar en columnas
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetalleItem("Número de seguimiento", widget.numeroSeguimiento, fontSize),
              const SizedBox(height: 5),
              _buildDetalleItem("Categoría", widget.categoria, fontSize),
              const SizedBox(height: 5),
              _buildDetalleItem("Fecha de solicitud", _formatFecha(DateTime.tryParse(widget.fecha)), fontSize),
              const SizedBox(height: 5),
              _buildDetalleItem("Subcategoría", widget.subcategoria, fontSize),
            ],
          )
              : Row( // En PC, mantener filas
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetalleItem("Número de seguimiento", widget.numeroSeguimiento, fontSize),
                  const SizedBox(height: 5),
                  _buildDetalleItem("Categoría", widget.categoria, fontSize),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetalleItem("Fecha de solicitud", _formatFecha(DateTime.tryParse(widget.fecha)), fontSize),
                  const SizedBox(height: 5),
                  _buildDetalleItem("Subcategoría", widget.subcategoria, fontSize),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Método auxiliar para evitar repetir código
  Widget _buildDetalleItem(String title, String value, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: fontSize, color: Colors.black87)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize + 2)),
      ],
    );
  }
  /// 🔹 Widget de fila con título y valor
  Widget _buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            flex: 4,
            child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget datosDeLaborAdmin() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📝 Datos de la gestión administrativa",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 15),

          _buildRow("Diligenció:", diligencio),
          _buildRow("Fecha de diligenciamiento:", _formatFecha(fechaDiligenciamiento)),
          const Divider(color: Colors.grey),

          _buildRow("Revisó:", reviso),
          _buildRow("Fecha de revisión:", _formatFecha(fechaRevision)),
          const Divider(color: Colors.grey),

          _buildRow("Envió:", envio),
          _buildRow("Fecha de envío:", _formatFecha(fechaEnvio)),
        ],
      ),
    );
  }

  /// 📆 Función para manejar errores en la conversión de fechas
  String _formatFecha(DateTime? fecha, {String formato = "dd 'de' MMMM 'de' yyyy - hh:mm a"}) {
    if (fecha == null) return "";
    return DateFormat(formato, 'es').format(fecha);
  }

  void fetchUserData() async {
    try {
      // 🧑‍💻 Obtener datos del usuario
      Ppl? fetchedData = await _pplProvider.getById(widget.idUser);

      // 🔥 Obtener documento de Firestore
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('domiciliaria_solicitados')
          .doc(widget.idDocumento)
          .get();

      // ✅ Verificar si el documento existe
      if (documentSnapshot.exists) {
        Map<String, dynamic>? data = documentSnapshot.data() as Map<String, dynamic>?;

        // 🔍 Verificar si `data` no es nulo
        if (data != null) {
          if (mounted) {
            setState(() {
              userData = fetchedData;
              solicitudData = data;
              isLoading = false;

              // ✅ Asignar valores de Firestore o definir valores por defecto si no existen
              consideraciones = data['consideraciones_revisado'] ?? 'Sin consideraciones';
              fundamentosDeDerecho = data['fundamentos_de_derecho_revisado'] ?? 'Sin fundamentos';
              peticionConcreta = data['peticion_concreta_revisado'] ?? 'Sin petición concreta';

              // 🆕 Cargar nuevos nodos
              diligencio = data['diligencio'] ?? 'No registrado';
              reviso = data['reviso'] ?? 'No registrado';
              envio = data['envió'] ?? 'No registrado';
              fechaEnvio = (data['fechaEnvio'] as Timestamp?)?.toDate();
              fechaDiligenciamiento = (data['fecha_diligenciamiento'] as Timestamp?)?.toDate();
              fechaRevision = (data['fecha_revision'] as Timestamp?)?.toDate();
            });
          } else {
            if (kDebugMode) {
              print("⚠️ El widget ya no está montado, no se actualizó el estado.");
            }
          }
        } else {
          if (kDebugMode) {
            print("⚠️ Los datos en Firestore son nulos.");
          }
        }
      } else {
        if (kDebugMode) {
          print("⚠️ Documento no encontrado en Firestore");
        }

        // Si no existe el documento, igualmente actualizamos `userData` y quitamos el loader
        if (mounted) {
          setState(() {
            userData = fetchedData;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error al obtener datos de Firestore: $e");
      }
    }
  }

  /// 📄 Abrir HTML en nueva pestaña para que el usuario pueda imprimir/guardar como PDF
  void abrirHtmlParaImprimir(String url) {
    html.window.open(url, '_blank');
  }

  void _mostrarDetalleCorreo(String correoId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return Container(
              color: blanco,
              width: isMobile ? double.infinity : 1000,
              padding: const EdgeInsets.all(20),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('domiciliaria_solicitados')
                    .doc(widget.idDocumento)
                    .collection('log_correos')
                    .doc(correoId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text("No se encontró información del correo.");
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;

                  // 📬 Para enviados
                  final toList = data['to'] is List ? List<String>.from(data['to']) : null;
                  final ccList = data['cc'] is List ? List<String>.from(data['cc']) : null;

                  // 📥 Para respuestas recibidas
                  final fromList = data['from'] is List ? List<String>.from(data['from']) : null;
                  final remitente = data['remitente'] as String?;

                  final esRespuesta = data['esRespuesta'] == true || data['EsRespuesta'] == true;

                  final subject = data['subject'] ?? '';
                  final archivos = data['archivos'] as List?;
                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                  final fechaEnvio = timestamp != null
                      ? DateFormat("dd MMM yyyy - hh:mm a", 'es').format(timestamp)
                      : 'Fecha no disponible';

                  // ✅ Cuerpo del mensaje: usar html o cuerpoHtml
                  final htmlInline = (data['html'] ?? data['cuerpoHtml'] ?? '').toString().trim();
                  final htmlUrl    = (data['htmlUrl'] ?? data['html_url'] ?? '').toString().trim();

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        if (!esRespuesta && toList != null)
                          Row(
                            children: [
                              const Text("Para: ", style: TextStyle(fontSize: 13)),
                              Flexible(
                                child: Text(toList.join(', '), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ],
                          ),

                        if (!esRespuesta && ccList != null && ccList.isNotEmpty)
                          Text("CC: ${ccList.join(', ')}", style: const TextStyle(fontSize: 13)),

                        if (esRespuesta) ...[
                          Row(
                            children: [
                              const Text("De: ", style: TextStyle(fontSize: 13)),
                              Flexible(
                                child: Text(
                                  fromList?.join(', ') ?? remitente ?? "Desconocido",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if ((data['destinatario'] ?? "").toString().trim().isNotEmpty)
                            Row(
                              children: [
                                const Text("Para: ", style: TextStyle(fontSize: 13)),
                                Flexible(
                                  child: Text(
                                    data['destinatario'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                        ],
                        const SizedBox(height: 10),
                        Text("Asunto: $subject", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("📅 Fecha: $fechaEnvio", style: const TextStyle(color: Colors.black87, fontSize: 12)),
                        const Divider(),

                        // Render robusto del cuerpo del correo (inline -> url -> PADRE.impulso -> fallback)
                        if (htmlInline.isNotEmpty) ...[
                          Html(data: _sanitizeInlineEmailHtml(_stripEnvelopeHtml(htmlInline))),
                        ] else if (htmlUrl.isNotEmpty) ...[
                          FutureBuilder<http.Response>(
                            future: http.get(Uri.parse(htmlUrl)),
                            builder: (context, respUrl) {
                              if (respUrl.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: LinearProgressIndicator(),
                                );
                              }
                              if (!respUrl.hasData ||
                                  respUrl.data!.statusCode != 200 ||
                                  respUrl.data!.body.trim().isEmpty) {
                                return _fallbackAbrirEnPestana(htmlUrl);
                              }
                              final body = _sanitizeInlineEmailHtml(_stripEnvelopeHtml(respUrl.data!.body));
                              return Html(data: body);
                            },
                          ),
                        ] else ...[
                          // 🔎 Fallback especial para IMPULSOS: tomar htmlUrl desde el nodo padre "impulso"
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('redenciones_solicitados')
                                .doc(widget.idDocumento)
                                .get(),
                            builder: (context, parentSnap) {
                              if (parentSnap.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: LinearProgressIndicator(),
                                );
                              }
                              if (!parentSnap.hasData || !parentSnap.data!.exists) {
                                return const Text("(Sin contenido disponible)");
                              }

                              final parent = parentSnap.data!.data() as Map<String, dynamic>?;
                              final imp = parent?['impulso'];

                              if (imp is! Map) {
                                return const Text("(Sin contenido disponible)");
                              }

                              // 1) Intentar por etiqueta (nuevo esquema recomendado)
                              final etiquetaDoc = (data['etiqueta'] ?? '').toString();
                              final keyByEtiqueta = etiquetaDoc.isNotEmpty ? _etiquetaToKey(etiquetaDoc) : null;

                              String? url2;
                              Map<String, dynamic>? nodo;

                              // A) Por etiqueta directa
                              if (keyByEtiqueta != null && imp[keyByEtiqueta] is Map) {
                                nodo = Map<String, dynamic>.from(imp[keyByEtiqueta]);
                              }

                              // B) Si no, búsqueda recursiva (soporta estructura anidada por email con '.')
                              nodo ??= _findImpulsoLeaf(
                                Map<String, dynamic>.from(imp),
                                emailKey: (toList != null && toList!.isNotEmpty)
                                    ? toList!.first
                                    : (data['destinatario']?.toString()),
                                subject: subject.toString(),
                              );

                              if (nodo != null) {
                                url2 = (nodo['htmlUrl'] ?? nodo['html_url'])?.toString();
                              }

                              if (url2 == null || url2!.isEmpty) {
                                return const Text("(Sin contenido disponible)");
                              }

                              return FutureBuilder<http.Response>(
                                future: http.get(Uri.parse(url2!)),
                                builder: (context, respImp) {
                                  if (respImp.connectionState == ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: LinearProgressIndicator(),
                                    );
                                  }
                                  if (!respImp.hasData ||
                                      respImp.data!.statusCode != 200 ||
                                      respImp.data!.body.trim().isEmpty) {
                                    return _fallbackAbrirEnPestana(url2!);
                                  }
                                  final body = _sanitizeInlineEmailHtml(_stripEnvelopeHtml(respImp.data!.body));
                                  return Html(data: body);
                                },
                              );
                            },
                          ),
                        ],
                        if (archivos != null && archivos.isNotEmpty) ...[
                          const Divider(),
                          const Text("Archivos adjuntos:", style: TextStyle(fontWeight: FontWeight.bold)),
                          ...archivos.map((a) => Text("- ${a['nombre']}")),
                        ],

                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            child: const Text("Cerrar"),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

}
