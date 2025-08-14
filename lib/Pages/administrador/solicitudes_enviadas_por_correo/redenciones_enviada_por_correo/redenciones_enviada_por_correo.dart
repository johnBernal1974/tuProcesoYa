
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
import '../../../../commons/main_layaout.dart';
import '../../../../models/ppl.dart';
import '../../../../plantillas/plantilla_impulso_procesal.dart';
import '../../../../src/colors/colors.dart';
import '../../../../widgets/boton_notificar_respuesta_correo.dart';
import '../../../../widgets/email_status_widget.dart';
import 'package:tuprocesoya/widgets/impulsos.dart' as imp;

import '../../../../widgets/impulso_correo_managerV1.dart';
import 'package:http/http.dart' as http;



class SolicitudesRedencionPenaPorCorreoPage extends StatefulWidget {
  final String status;
  final String idDocumento;
  final String numeroSeguimiento;
  final String categoria;
  final String subcategoria;
  final String fecha;
  final String idUser;
  final bool sinRespuesta;

  const SolicitudesRedencionPenaPorCorreoPage({
    super.key,
    required this.status,
    required this.idDocumento,
    required this.numeroSeguimiento,
    required this.categoria,
    required this.subcategoria,
    required this.fecha,
    required this.idUser,
    required this.sinRespuesta,
  });


  @override
  State<SolicitudesRedencionPenaPorCorreoPage> createState() => _SolicitudesRedencionPenaPorCorreoPageState();
}

class _SolicitudesRedencionPenaPorCorreoPageState extends State<SolicitudesRedencionPenaPorCorreoPage> {
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

  List<PlatformFile> _selectedFiles = [];
  Map<String, dynamic>? solicitudData;

  String? pplNui;
  String? pplTd;
  String? pplDocumento;
  String? pplCentro;
  String? pplPatio;
  String? pplJuzgadoEP;

  final _impMgr = ImpulsoCorreoManagerV1();



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _pplProvider = PplProvider();
    fetchUserData();

  }


  @override
  Widget build(BuildContext context) {
    final normalizedStatus = widget.status.trim().toLowerCase();
    return MainLayout(
      pageTitle: 'Redención de penas - ${normalizedStatus == "enviado"
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
                                      nombreColeccion: "redenciones_solicitados",
                                      onTapCorreo: _mostrarDetalleCorreo,
                                    ),
                                    const SizedBox(height: 30),
                                    BotonNotificarRespuestaWhatsApp(
                                      docId: widget.idDocumento,
                                      servicio: "Redención",
                                      seguimiento: widget.numeroSeguimiento,
                                      seccionHistorial: "Solicitud redenciones",
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
                                    nombreColeccion: "redenciones_solicitados",
                                    onTapCorreo: _mostrarDetalleCorreo,
                                  ),
                                  BotonNotificarRespuestaWhatsApp(
                                    docId: widget.idDocumento,
                                    servicio: "Redención",
                                    seguimiento: widget.numeroSeguimiento,
                                    seccionHistorial: "Solicitud redenciones",
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

  List<imp.CorreoDestino> _obtenerCorreosDestinatarios() {
    final list = <imp.CorreoDestino>[];
    final seen = <String>{};
    void add(String? e, String tag) {
      final s = (e ?? '').trim();
      if (s.isEmpty || !s.contains('@')) return;
      if (seen.add(s)) list.add(imp.CorreoDestino(s, tag));
    }

    // ✅ leemos del mapa normalizado por fetchUserData()
    final m = solicitudData?['__correosImpulso'];
    if (m is Map) {
      add(m['principal']?.toString(), 'Principal');
      add(m['centro_reclusion']?.toString(), 'Centro reclusión');
      add(m['reparto']?.toString(), 'Reparto');
    }

    debugPrint('[Impulso] correos extraídos: '
        '${list.map((c) => '${c.etiqueta}:${c.email}').join(', ')}');
    return list;
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

    // 4) Plazo y flag de impulso ya enviado
    final int diasPlazo = (solicitudData?['plazoImpulsoDias'] as int?) ?? 15;
    final bool yaSeEnvioImpulso = (solicitudData?['yaSeEnvioImpulso'] == true);
    final int diasTranscurridos = DateTime.now().difference(fechaEnvio!).inDays;

    debugPrint('[Gate] listo para montar banner: '
        'fechaEnvio=$fechaEnvio diasTranscurridos=$diasTranscurridos '
        'diasPlazo=$diasPlazo correos=${correos.length} yaSeEnvio=$yaSeEnvioImpulso');

    // 5) Montar el banner
    return imp.ImpulsoProcesalBanner(
      fechaUltimoEnvio: fechaEnvio!.toLocal(),
      diasPlazo: diasPlazo,
      correos: correos,
      yaSeEnvioImpulso: yaSeEnvioImpulso,

      // ---------- PREVIEW HTML ----------
      buildPreviewHtml: (correoSeleccionado) async {
        // 1) Resolución de saludo y entidad según el correo destino
        final c = _obtenerCorreosDestinatarios()
            .firstWhere((x) => x.email == correoSeleccionado);

        final dirigido = _resolverSaludo(c);
        final entidad  = _resolverEntidad(c);

        // 2) Traer "el correo anterior" exactamente para ese destinatario
        String? htmlAnterior = await _buscarHtmlAnteriorPorDestino(correoSeleccionado);

        // 3) Construir la plantilla con el htmlAnterior incrustado
        final tpl = ImpulsoProcesalTemplate(
          dirigido: dirigido,
          entidad: entidad,
          servicio: widget.subcategoria,
          numeroSeguimiento: widget.numeroSeguimiento,
          fechaEnvioInicial: fechaEnvio,
          diasPlazo: (solicitudData?['plazoImpulsoDias'] as int?) ?? 15,
          nombrePpl: userData?.nombrePpl ?? '',
          apellidoPpl: userData?.apellidoPpl ?? '',
          identificacionPpl: userData?.numeroDocumentoPpl ?? '',
          centroPenitenciario: (userData?.centroReclusion ?? '').toString(),
          nui: userData?.nui ?? '',
          td: userData?.td ?? '',
          patio: userData?.patio ?? '',
          htmlAnterior: htmlAnterior, // ⬅️ aquí va el correo anterior (en texto o fallback con link)
          logoUrl: "https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635",
        );

        return tpl.generarHtml();
      },


      // ---------- ENVÍO (Storage + Cloud Function) ----------
      enviarImpulso: ({required String correoDestino, required String html}) async {
        final firestore = FirebaseFirestore.instance;
        final docRef = firestore
            .collection('redenciones_solicitados')
            .doc(widget.idDocumento);

        final now = DateTime.now();
        final ts = now.millisecondsSinceEpoch;

        // 1) Subir HTML a Storage
        final storage = FirebaseStorage.instance;
        final pathHtml = 'redenciones_solicitados/${widget.idDocumento}/impulsos/$ts.html';
        final refHtml  = storage.ref().child(pathHtml);

        await refHtml.putString(
          html,
          format: PutStringFormat.raw,
          metadata: SettableMetadata(
            contentType: 'text/html; charset=utf-8',
            cacheControl: 'public, max-age=31536000',
          ),
        );
        final htmlUrl = await refHtml.getDownloadURL();

        // 2) Log preliminar en Firestore
        final subject = 'Impulso procesal – ${widget.subcategoria} – ${widget.numeroSeguimiento}';
        final logRef = await docRef.collection('log_correos').add({
          'to': [correoDestino],
          'subject': subject,
          'html_url': htmlUrl,
          'html_len': html.length,
          'timestamp': FieldValue.serverTimestamp(),
          'tipo': 'impulso_procesal',
        });

        // 3) Llamar Cloud Function (Resend)
        final urlCF = Uri.parse(
          "https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/sendEmailWithResend",
        );

        final cc = ['peticiones@tuprocesoya.com']; // opcional

        final payload = {
          'to': [correoDestino],
          'cc': cc,
          'subject': subject,
          'html': html, // enviamos el mismo HTML que subimos
          'archivos': [], // si adjuntas, usa [{'name': '...', 'url': '...'}]
          'idDocumento': widget.idDocumento,
          'enviadoPor': FirebaseAuth.instance.currentUser?.phoneNumber ??
              FirebaseAuth.instance.currentUser?.email ??
              'app',
          'tipo': 'impulso_procesal',
          'extras': {
            'logId': logRef.id,
            'htmlUrl': htmlUrl,
            'collection': 'redenciones_solicitados',
          }
        };

        final resp = await http.post(
          urlCF,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        if (resp.statusCode < 200 || resp.statusCode >= 300) {
          await logRef.update({
            'envio_error': true,
            'envio_status': resp.statusCode,
            'envio_body': resp.body,
            'envio_at': FieldValue.serverTimestamp(),
          });
          throw Exception('CF respondió ${resp.statusCode}: ${resp.body}');
        }

        // 4) Marcar solicitud
        await docRef.update({
          'yaSeEnvioImpulso': true,
          'impulso': {
            'fechaEnvio': FieldValue.serverTimestamp(),
            'destinatario': correoDestino,
            'htmlUrl': htmlUrl,
            'subject': subject,
            'logId': logRef.id,
          }
        });

        // 5) Confirmar log
        await logRef.update({
          'enviado_ok': true,
          'enviado_at': FieldValue.serverTimestamp(),
        });
      },

      onEnviado: () => fetchUserData(),
    );
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

  /// Busca en log_correos el último correo NO-impulso enviado al `emailDestino`.
  /// Devuelve el HTML en texto, o si no existe, intenta devolver un fallback con el `html_url`.
  Future<String?> _buscarHtmlAnteriorPorDestino(String emailDestino) async {
    final col = FirebaseFirestore.instance
        .collection('redenciones_solicitados')
        .doc(widget.idDocumento)
        .collection('log_correos');

    try {
      // Trae los 20 más recientes dirigidos a ese email
      final qs = await col
          .where('to', arrayContains: emailDestino)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      // 1) preferimos el último que NO sea impulso y que tenga 'html' en texto
      for (final d in qs.docs) {
        final data = d.data();
        final tipo = (data['tipo'] ?? '').toString().trim();
        if (tipo == 'impulso_procesal') continue; // saltamos impulsos

        final h = (data['html'] as String?)?.trim();
        if (h != null && h.isNotEmpty) return h;
      }

      // 2) si no hubo 'html' en texto, intentamos con 'html_url' para armar un fallback (enlace)
      for (final d in qs.docs) {
        final data = d.data();
        final tipo = (data['tipo'] ?? '').toString().trim();
        if (tipo == 'impulso_procesal') continue;

        final htmlUrl = (data['html_url'] as String?)?.trim();
        if (htmlUrl != null && htmlUrl.isNotEmpty) {
          // Fallback: muchos clientes bloquean iframes, así que dejamos un link claro
          return """
<div style="font-size:13px;color:#555;">
  <p><b>Correo enviado inicialmente (ver en línea):</b></p>
  <p>
    <a href="$htmlUrl" target="_blank" rel="noopener noreferrer">$htmlUrl</a>
  </p>
  <p style="margin-top:8px;">
    <i>(Nota: para poder incrustar aquí el contenido completo, guarda también el campo <code>html</code> plano en log_correos al momento del primer envío.)</i>
  </p>
</div>
""";
        }
      }

      // 3) si no hay nada dirigido a ese correo, intentamos el último no-impulso cualquiera
      final qs2 = await col.orderBy('timestamp', descending: true).limit(20).get();
      for (final d in qs2.docs) {
        final data = d.data();
        final tipo = (data['tipo'] ?? '').toString().trim();
        if (tipo == 'impulso_procesal') continue;

        final h = (data['html'] as String?)?.trim();
        if (h != null && h.isNotEmpty) return h;

        final htmlUrl = (data['html_url'] as String?)?.trim();
        if (htmlUrl != null && htmlUrl.isNotEmpty) {
          return """
<div style="font-size:13px;color:#555;">
  <p><b>Correo enviado inicialmente (ver en línea):</b></p>
  <p>
    <a href="$htmlUrl" target="_blank" rel="noopener noreferrer">$htmlUrl</a>
  </p>
  <p style="margin-top:8px;">
    <i>(Nota: para poder incrustar aquí el contenido completo, guarda también el campo <code>html</code> plano en log_correos al momento del primer envío.)</i>
  </p>
</div>
""";
        }
      }
    } catch (e) {
      // Si Firestore te pide índice por el where+orderBy, verás un link en la consola.
      debugPrint('[Impulso] _buscarHtmlAnteriorPorDestino error: $e');
    }
    return null;
  }



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
      child: const Text("Iniciar Tutela"),
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
                  "Redención de penas - ${widget.status == "Enviado"
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
        const Divider(color: gris),
        const SizedBox(height: 50),
        datosDeLaborAdmin()
        //vistaPreviaDerechoPeticion(userData, consideraciones, fundamentosDeDerecho, peticionConcreta),
      ],
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
      // 1) PPL por provider
      final fetchedData = await _pplProvider.getById(widget.idUser);

      // 2) Documento de la solicitud
      final docRef = FirebaseFirestore.instance
          .collection('redenciones_solicitados')
          .doc(widget.idDocumento);
      final snap = await docRef.get();
      if (!snap.exists) {
        if (mounted) {
          setState(() {
            userData = fetchedData;
            isLoading = false;
          });
        }
        debugPrint('⚠️ Documento no encontrado');
        return;
      }
      final data = (snap.data() as Map<String, dynamic>?) ?? {};

      // 3) (Opcional) Trae el doc de Ppl directo por si el modelo no trae todos los campos
      final pplSnap = await FirebaseFirestore.instance
          .collection('Ppl') // <- usa el nombre exacto de tu colección
          .doc(widget.idUser)
          .get();
      final pplMap = (pplSnap.data() as Map<String, dynamic>?) ?? {};

      // 4) Toma de PplProvider si existe; si no, cae al mapa de Firestore
      String? getStr(dynamic v) =>
          (v is String && v.trim().isNotEmpty) ? v.trim() : null;

      final _nui = getStr(fetchedData?.nui) ?? getStr(pplMap['nui']);
      final _td  = getStr(fetchedData?.td) ??
          getStr(pplMap['td']) ??
          getStr(pplMap['tipo_documento']) ?? getStr(pplMap['tipoDocumento']);
      final _doc = getStr(fetchedData?.numeroDocumentoPpl) ??
          getStr(pplMap['documento']) ?? getStr(pplMap['cedula']);
      final _jep = getStr(fetchedData?.juzgadoEjecucionPenas) ??
          getStr(pplMap['juzgado_ejecucion_penas']) ?? getStr(pplMap['Juzgado de ejecución de penas']);
      final _centro = getStr(fetchedData?.centroReclusion) ??
          getStr(pplMap['centro_penitenciario']) ??
          getStr(pplMap['establecimiento']);
      final _patio = getStr(fetchedData?.patio) ?? getStr(pplMap['patio']);

      // ---- (tu normalización de correos como ya la tienes) ----
      String? _getStrKey(String dottedPath) {
        try {
          final v = snap.get(dottedPath);
          if (v is String && v.trim().isNotEmpty) return v.trim();
        } catch (_) {}
        final raw = data[dottedPath];
        if (raw is String && raw.trim().isNotEmpty) return raw.trim();
        return null;
      }

      final principal = _getStrKey('correoHtmlCorreo.principal') ??
          _getStrKey('destinatarios.principal');
      final centro   = _getStrKey('correoHtmlCorreo.centro_reclusion') ??
          _getStrKey('destinatarios.centro_reclusion');
      final reparto  = _getStrKey('correoHtmlCorreo.reparto') ??
          _getStrKey('destinatarios.reparto');

      final correosImpulso = <String, String>{};
      if (principal != null) correosImpulso['principal'] = principal;
      if (centro != null)    correosImpulso['centro_reclusion'] = centro;
      if (reparto != null)   correosImpulso['reparto'] = reparto;

      final dataMerged = {...data, '__correosImpulso': correosImpulso};

      final DateTime? _fechaEnvio = (data['fechaEnvio'] as Timestamp?)?.toDate();

      if (!mounted) return;
      setState(() {
        userData = fetchedData;
        solicitudData = dataMerged;
        isLoading = false;

        // lo que ya tenías
        consideraciones      = data['consideraciones_revisado'] ?? 'Sin consideraciones';
        fundamentosDeDerecho = data['fundamentos_de_derecho_revisado'] ?? 'Sin fundamentos';
        peticionConcreta     = data['peticion_concreta_revisado'] ?? 'Sin petición concreta';
        diligencio           = data['diligencio'] ?? 'No registrado';
        reviso               = data['reviso'] ?? 'No registrado';
        envio                = data['envió'] ?? 'No registrado';
        fechaEnvio           = _fechaEnvio;
        fechaDiligenciamiento= (data['fecha_diligenciamiento'] as Timestamp?)?.toDate();
        fechaRevision        = (data['fecha_revision'] as Timestamp?)?.toDate();

        // ✅ guarda los campos del PPL en estado
        pplNui        = _nui;
        pplTd         = _td;
        pplDocumento  = _doc;
        pplCentro     = _centro;
        pplPatio      = _patio;
        pplJuzgadoEP      = _jep;
      });

      debugPrint('✅ PPL nui=$_nui td=$_td doc=$_doc centro=$_centro patio=$_patio');
    } catch (e) {
      debugPrint('❌ Error Firestore: $e');
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
                    .collection('redenciones_solicitados')
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
                  final htmlContent = data['html'] ?? data['cuerpoHtml'] ?? '<p>(Sin contenido disponible)</p>';

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

                        Html(data: htmlContent),

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


