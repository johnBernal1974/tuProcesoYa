import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/Pages/administrador/historial_solicitudes_desistimiento_apelacion_admin/historial_solicitudes_desistimiento_apelacion_admin.dart';
import 'package:tuprocesoya/providers/ppl_provider.dart';
import '../../../commons/admin_provider.dart';
import '../../../commons/main_layaout.dart';
import '../../../controllers/tiempo_condena_controller.dart';
import '../../../helper/resumen_solicitudes_helper.dart';
import '../../../models/ppl.dart';
import '../../../plantillas/plantilla_desistimiento_apelacion.dart';
import '../../../src/colors/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as dart_convert;
import '../../../widgets/calculo_beneficios_penitenciarios-general.dart';
import '../../../widgets/datos_ejecucion_condena.dart';
import '../../../widgets/manager_correo_desistimiento_apelacion.dart';
import '../historial_solicitudes_redenciones_admin/historial_solicitudes_redenciones_admin.dart';
import 'atender_solicitud_desistimiento_apelacion_controller.dart';

class AtenderSolicitudDesistimientoApelacionPage extends StatefulWidget {
  final String status;
  final String idDocumento;
  final String numeroSeguimiento;
  final String fecha;
  final String idUser;

  const AtenderSolicitudDesistimientoApelacionPage({
    super.key,
    required this.status,
    required this.idDocumento,
    required this.numeroSeguimiento,
    required this.fecha,
    required this.idUser,
  });

  @override
  State<AtenderSolicitudDesistimientoApelacionPage> createState() =>
      _AtenderSolicitudDesistimientoApelacionPageState();
}


class _AtenderSolicitudDesistimientoApelacionPageState extends State<AtenderSolicitudDesistimientoApelacionPage> {
  late PplProvider _pplProvider;
  Ppl? userData;
  bool isLoading = true;
  int diasEjecutado = 0;
  int mesesEjecutado = 0;
  int diasEjecutadoExactos = 0;
  int diasRestante = 0;
  int mesesRestante = 0;
  int diasRestanteExactos = 0;
  double porcentajeEjecutado = 0;
  int tiempoCondena = 0;
  final AtenderSolicitudDesistimientoApelacionAdminController _controller = AtenderSolicitudDesistimientoApelacionAdminController();
  String sinopsis = "";
  String consideraciones = "";
  String fundamentosDeDerecho = "";
  String pretenciones = "";
  bool _mostrarVistaPrevia = false;
  Map<String, String> correosCentro = {};
  late DocumentReference userDoc;
  String? correoSeleccionado = ""; // Guarda el correo seleccionado
  String? nombreCorreoSeleccionado;
  String idDocumento = "";
  String adminFullName = "";
  String entidad = "";
  String diligencio = '';
  String reviso = '';
  String envio = '';
  DateTime? fechaEnvio;
  DateTime? fechaDiligenciamiento;
  DateTime? fechaRevision;
  String rol = AdminProvider().rol ?? "";
  late SolicitudDesistimientoApelacionTemplate desistimientoApelacion;
  String asignadoA_P2 = '';
  String asignadoNombreP2 = '';
  DateTime? fechaAsignadoP2;
  Map<String, dynamic>? solicitudData;
  late CalculoCondenaController _calculoCondenaController;
  String? ultimoHtmlEnviado;

  // --- CONTROLLERS NUEVOS que pediste ---
  final TextEditingController entidadController = TextEditingController();
  final TextEditingController numeroProcesoController = TextEditingController();
  final TextEditingController correoManualController = TextEditingController();
  DateTime? fechaApelacion;
  // --- fin controllers ---

  @override
  void initState() {
    super.initState();
    _pplProvider = PplProvider();
    _calculoCondenaController = CalculoCondenaController(_pplProvider);

    fetchDocumentoSolicitudDesistimientoApelacion();
    fetchUserData();
    calcularTiempo(widget.idUser);
    adminFullName = AdminProvider().adminFullName ?? "";
    if (adminFullName.isEmpty && kDebugMode) {
      print("❌ No se pudo obtener el nombre del administrador.");
    }
  }

  @override
  void dispose() {
    entidadController.dispose();
    numeroProcesoController.dispose();
    correoManualController.dispose();
    super.dispose();
  }

  String obtenerNombreArchivo(String url) {
    String decodedUrl = Uri.decodeFull(url);
    List<String> partes = decodedUrl.split('/');
    return partes.last.split('?').first;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 1000;
    return MainLayout(
      pageTitle: 'Atender solicitud Desistimiento de apelación',
      content: isWide
          ? Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildMainContent(),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height - 32,
                    ),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: _buildExtraWidget(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMainContent(),
            const SizedBox(height: 20),
            _buildExtraWidget(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Devuelve la fecha formateada o cadena vacía si es null.
  String _formatFecha(DateTime? fecha, {String formato = "dd 'de' MMMM 'de' yyyy - hh:mm a"}) {
    if (fecha == null) return "";
    try {
      return DateFormat(formato, 'es').format(fecha);
    } catch (e) {
      if (kDebugMode) print("❌ _formatFecha error: $e");
      return fecha.toString();
    }
  }

  /// Widget simple que muestra la fecha actual (usado en la cabecera).
  Widget _buildFechaHoy() {
    final hoy = DateTime.now();
    final texto = DateFormat("d 'de' MMMM 'de' y", 'es').format(hoy);
    return Text(
      'Hoy es: $texto',
      style: const TextStyle(fontSize: 12),
    );
  }


  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFechaHoy(),
        const SizedBox(height: 10),
        if (rol == "masterFull" || rol == "master" || rol == "coordinador 1") infoAccionesAdmin(),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _obtenerColorFondo(widget.status),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Solicitud desistimiento de apelación - ${widget.status}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 10),
              _buildSolicitadoPor(),
              const SizedBox(height: 15),
              _buildDetallesSolicitud(),
              const SizedBox(height: 20),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const Divider(color: gris),
        const SizedBox(height: 20),

        // Campos nuevos solicitados por ti: entidad manual, nro proceso, fecha apelación, correo manual
        Card(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Enviar solicitud al tribunal",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),

                // --- ENTIDAD ---
                TextField(
                  controller: entidadController,
                  decoration: const InputDecoration(
                    labelText: "Entidad (ej. Tribunal Superior de ...)",
                    hintText: "Ingresa la entidad manualmente si no aparece en opciones",
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1.3),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // --- NÚMERO DEL PROCESO ---
                TextField(
                  controller: numeroProcesoController,
                  decoration: const InputDecoration(
                    labelText: "Número del proceso",
                    hintText: "Ej: 12345-2024",
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1.3),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // --- FECHA DE APELACIÓN ---
                InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: fechaApelacion ?? now,
                      firstDate: DateTime(2000),
                      lastDate: now,
                    );
                    if (picked != null) setState(() => fechaApelacion = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de envío de la apelación',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 1.3),
                      ),
                    ),
                    child: Text(
                      fechaApelacion == null
                          ? 'Seleccionar fecha'
                          : DateFormat('yyyy-MM-dd').format(fechaApelacion!),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // --- CORREO MANUAL ---
                TextField(
                  controller: correoManualController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Correo destino (opcional)",
                    hintText: "Si lo completas, se usará este correo como destino principal",
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1.3),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  "O elige uno de los correos guardados abajo:",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                // Aquí van los botones de correos (correoConBoton)
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            side: BorderSide(width: 1, color: Theme.of(context).primaryColor),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          onPressed: () {
            setState(() {
              _mostrarVistaPrevia = !_mostrarVistaPrevia;
            });
          },
          child: const Text("Vista previa"),
        ),

        const SizedBox(height: 20),
        if (_mostrarVistaPrevia)
          vistaPreviaSolicitudDesistimientoApelacion(
            userData: userData,
          ),
        const SizedBox(height: 100),
      ],
    );
  }

  // --- Resto de métodos ya existentes (obtenerTituloCorreo, _obtenerColorStatus, etc.) ---
  String obtenerTituloCorreo(String? nombreCorreo) {
    switch (nombreCorreo) {
      case 'Director':
        return 'Señor\nDirector';
      case 'Jurídica':
        return 'Señores Oficina Jurídica';
      case 'Principal':
        return 'Señores';
      case 'Sanidad':
        return 'Señores Oficina de Sanidad';
      case 'Correo JEP':
        return 'Señor(a) Juez';
      case 'Correo JDC':
        return 'Señor(a) Juez';
      default:
        return '';
    }
  }

  Color _obtenerColorStatus(String status) {
    switch (status) {
      case "Solicitado":
        return Colors.red;
      case "Diligenciado":
        return Colors.amber;
      case "Revisado":
        return primary;
      default:
        return Colors.grey;
    }
  }

  Color _obtenerColorFondo(String status) {
    switch (status) {
      case "Solicitado":
        return const Color(0xFFFFF5F5);
      case "Diligenciado":
        return const Color(0xFFFFFBEA);
      case "Revisado":
        return const Color(0xFFF5EAFE);
      default:
        return const Color(0xFFFAFAFA);
    }
  }

  Widget _buildSolicitadoPor() {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    return isMobile
        ? Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Solicitado por:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text("${userData?.nombreAcudiente ?? "Sin información"} ${userData?.apellidoAcudiente ?? "Sin información"}", style: const TextStyle(fontSize: 12)),
        ],
      ),
    )
        : Row(
      children: [
        const Text("Solicitado por:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Text("${userData?.nombreAcudiente ?? "Sin información"} ${userData?.apellidoAcudiente ?? "Sin información"}", style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildDetallesSolicitud() {
    double fontSize = MediaQuery.of(context).size.width < 600 ? 10 : 12;
    bool isMobile = MediaQuery.of(context).size.width < 600;
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetalleItem("Número de seguimiento", widget.numeroSeguimiento, fontSize),
              const SizedBox(height: 5),
              _buildDetalleItem("Categoría", "Solicitudes varias", fontSize),
              const SizedBox(height: 5),
              _buildDetalleItem("Fecha de solicitud", _formatFecha(DateTime.tryParse(widget.fecha)), fontSize),
              const SizedBox(height: 5),
              _buildDetalleItem("Subcategoría", "Solicitud desistimiento de apelación", fontSize),
            ],
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetalleItem("Número de seguimiento", widget.numeroSeguimiento, fontSize),
                  const SizedBox(height: 5),
                  _buildDetalleItem("Categoría", "Solicitudes varias", fontSize),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetalleItem("Fecha de solicitud", _formatFecha(DateTime.tryParse(widget.fecha)), fontSize),
                  const SizedBox(height: 5),
                  _buildDetalleItem("Subcategoría", "Solicitud desistimiento de apelación", fontSize),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget infoAccionesAdmin() {
    if (asignadoA_P2.isEmpty && diligencio.isEmpty && reviso.isEmpty && envio.isEmpty) return const SizedBox();
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      width: double.infinity,
      padding: isMobile ? const EdgeInsets.symmetric(horizontal: 8) : EdgeInsets.zero,
      child: Card(
        color: blanco,
        surfaceTintColor: blanco,
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Historial de acciones", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (asignadoA_P2.isNotEmpty) _buildAccion("Asignado para revisar: ", asignadoNombreP2, fechaAsignadoP2, isMobile),
            if (widget.status == "Diligenciado" || widget.status == "Revisado" || widget.status == "Enviado")
              _buildAccion("Diligenció: ", diligencio, fechaDiligenciamiento, isMobile),
            if (widget.status == "Revisado" || widget.status == "Enviado") _buildAccion("Revisó: ", reviso, fechaRevision, isMobile),
            if (widget.status == "Enviado") _buildAccion("Envió: ", envio, fechaEnvio, isMobile),
            const SizedBox(height: 10),
            Text("ID del documento: ${widget.idDocumento}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ),
      ),
    );
  }

  Widget _buildAccion(String label, String usuario, DateTime? fecha, bool isMobile) {
    final fechaTexto = _formatFecha(fecha);
    if (isMobile) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.black87, fontSize: 13)),
        Text(usuario, style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
        Text(fechaTexto, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
      ]);
    } else {
      return Row(children: [
        Text(label, style: const TextStyle(color: Colors.black87, fontSize: 13)),
        Text(usuario, style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(width: 15),
        Text(fechaTexto, style: const TextStyle(fontSize: 12)),
      ]);
    }
  }

  Widget _buildDetalleItem(String title, String value, double fontSize) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: fontSize, color: Colors.black87)),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize + 2)),
    ]);
  }

  Widget _buildExtraWidget() {
    if (userData == null) {
      return const Center(child: CircularProgressIndicator()); // 🔹 Muestra un loader mientras `userData` se carga
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 1), // 🔹 Marco gris
        borderRadius: BorderRadius.circular(10), // 🔹 Bordes redondeados
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (userData!.situacion == "En Prisión domiciliaria" ||
              userData!.situacion == "En libertad condicional")
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black,
              ),
              child: Text(
                userData!.situacion ?? "",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
              ),
            ),
          const SizedBox(height: 20),
          const Text("Datos generales del PPL", style: TextStyle(
              fontWeight: FontWeight.w900, fontSize: 24
          ),),
          const SizedBox(height: 25),
          Row(
            children: [
              const Text('Nombre:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.nombrePpl, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            children: [
              const Text('Apellido:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.apellidoPpl, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
            ],
          ),
          Row(
            children: [
              const Text('Tipo Documento:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.tipoDocumentoPpl, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            children: [
              const Text('Número Documento:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.numeroDocumentoPpl, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 15),

          const Divider(color: primary, height: 1),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Juzgado Ejecución Penas:', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.juzgadoEjecucionPenas, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.1)),
            ],
          ),
          correoConBoton('Correo JEP', userData!.juzgadoEjecucionPenasEmail),
          const Divider(color: primary, height: 1),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Juzgado Que Condenó:', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.juzgadoQueCondeno, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.1)),
            ],
          ),
          correoConBoton('Correo JDC', userData!.juzgadoQueCondenoEmail),
          const Divider(color: primary, height: 1),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Delito:', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.delito, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Radicado:', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.radicado, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Fecha Captura:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(
                DateFormat('yyyy-MM-dd').format(userData!.fechaCaptura!),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            children: [
              const Text('Tiempo Condena:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(
                '${userData!.mesesCondena ?? 0} meses, ${userData!.diasCondena ?? 0} días',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if(userData!.situacion == "En Reclusión")
            Column(
              children: [
                Row(
                  children: [
                    const Text('TD:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
                    Text(userData!.td, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
                Row(
                  children: [
                    const Text('NUI:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
                    Text(userData!.nui, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
                Row(
                  children: [
                    const Text('Patio:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
                    Text(userData!.patio, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 15),
          const Text("Datos del Acudiente", style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.black
          )),
          const SizedBox(height: 5),
          Row(
            children: [
              const Text('Nombre:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.nombreAcudiente, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            children: [
              const Text('Apellido:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.apellidoAcudiente, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            children: [
              const Text('Parentesco:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.parentescoRepresentante, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            children: [
              const Text('Celular:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.celular, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            children: [
              const Text('WhatsApp:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.celularWhatsapp, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(color: Colors.grey, height: 1),
          const SizedBox(height: 15),

          FutureBuilder<double>(
            future: calcularTotalRedenciones(widget.idUser),
            builder: (context, snapshot) {
              final double totalRedimido = snapshot.data ?? 0.0;

              // 🔹 1) condena total en días
              final int totalDiasCondena =
                  (userData!.mesesCondena ?? 0) * 30 + (userData!.diasCondena ?? 0);

              // 🔹 2) días ejecutados reales desde captura hasta hoy
              final DateTime hoy = DateTime.now();
              final DateTime captura = userData!.fechaCaptura!;
              final int diasEjecutadosReales = hoy.difference(captura).inDays;

              // 🔹 3) total cumplido incluyendo redención
              final int totalDiasCumplidos =
                  diasEjecutadosReales + totalRedimido.round();

              // 🔹 4) porcentaje ejecutado REAL incluyendo redención
              final double porcentajeEjecutadoConRedencion =
              totalDiasCondena == 0
                  ? 0
                  : (totalDiasCumplidos / totalDiasCondena) * 100;

              // ✅ 5) tu widget de cuadritos (opcionalmente también puede usar este totalRedimido)
              return Column(
                children: [
                  _datosEjecucionCondena(totalRedimido),
                  const SizedBox(height: 20),
                  BeneficiosPenitenciariosWidget(
                    porcentajeEjecutado: porcentajeEjecutadoConRedencion,
                    totalDiasCondena: totalDiasCondena,
                    situacion: userData!.situacion,
                    cardColor: Colors.white,
                    borderColor: Colors.grey.shade300,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Future<double> calcularTotalRedenciones(String pplId) async {
    double totalDias = 0.0;
    try {
      QuerySnapshot redencionesSnapshot = await FirebaseFirestore.instance.collection('Ppl').doc(pplId).collection('redenciones').get();
      for (var doc in redencionesSnapshot.docs) {
        totalDias += (doc['dias_redimidos'] as num).toDouble();
      }
      if (kDebugMode) print("📌 Total días redimidos en el atender: $totalDias");
    } catch (e) {
      if (kDebugMode) print("❌ Error calculando redenciones: $e");
    }
    return totalDias;
  }

  String obtenerEntidad(String nombre) {
    if (["Principal", "Director", "Jurídica", "Sanidad"].contains(nombre)) {
      return userData?.centroReclusion ?? "";
    } else if (nombre == "Correo JEP") {
      return userData?.juzgadoEjecucionPenas ?? "";
    } else if (nombre == "Correo JDC") {
      return userData?.juzgadoQueCondeno ?? "";
    }
    return "";
  }

  Widget correoConBoton(String nombre, String? correo) {
    bool isSelected = nombre == nombreCorreoSeleccionado;
    return GestureDetector(
      onTap: () {
        setState(() {
          correoSeleccionado = correo;
          nombreCorreoSeleccionado = nombre;
          entidad = obtenerEntidad(nombre);
          // si el usuario hace clic en un correo guardado, dejamos en blanco el correoManual para evitar confusión
          correoManualController.clear();
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(color: isSelected ? Colors.green.withOpacity(0.3) : Colors.transparent, borderRadius: BorderRadius.circular(5)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text('$nombre: ${correo ?? 'Cargando...'}', style: const TextStyle(fontSize: 12, color: Colors.black), overflow: TextOverflow.ellipsis)),
          TextButton(onPressed: () => setState(() {
            correoSeleccionado = correo;
            nombreCorreoSeleccionado = nombre;
            entidad = obtenerEntidad(nombre);
            correoManualController.clear();
          }), child: Text(isSelected ? 'Elegido' : 'Elegir', style: TextStyle(fontSize: 12, color: isSelected ? Colors.black : Colors.blue, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)))
        ]),
      ),
    );
  }

  void fetchUserData() async {
    Ppl? fetchedData = await _pplProvider.getById(widget.idUser);

    // Leer documento de la solicitud (si existe) para precargar campos manuales
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('desistimiento_apelacion_solicitados')
        .doc(widget.idDocumento)
        .get();

    final Map<String, dynamic>? latestData = doc.data() as Map<String, dynamic>?;

    /// DEBUG: descomenta si quieres ver el orden de carga en consola
//  if (kDebugMode) {
//    print("fetchUserData: latestData = $latestData");
//    print("fetchUserData: controller values before load -> entidad=${entidadController.text}, nro=${numeroProcesoController.text}, correo=${correoManualController.text}");
//  }

    if (fetchedData != null && mounted) {
      // Calcular tiempos (si aplica)
      await calcularTiempo(widget.idUser);
      await _calculoCondenaController.calcularTiempo(widget.idUser);

      // Si el documento de solicitud tiene valores guardados, precargarlos en los controllers
      if (latestData != null) {
        // asignar solo si Firestore trae valor no vacío y el controller está vacío (evita sobreescritura)
        final entidadFromDoc = (latestData['entidad_manual'] ?? '').toString().trim();
        if (entidadFromDoc.isNotEmpty && entidadController.text.trim().isEmpty) {
          entidadController.text = entidadFromDoc;
        }

        final numeroProcesoFromDoc = (latestData['numero_proceso'] ?? '').toString().trim();
        if (numeroProcesoFromDoc.isNotEmpty && numeroProcesoController.text.trim().isEmpty) {
          numeroProcesoController.text = numeroProcesoFromDoc;
        }

        final correoManualFromDoc = (latestData['correo_manual'] ?? latestData['correo_manual_usado'] ?? '').toString().trim();
        if (correoManualFromDoc.isNotEmpty && correoManualController.text.trim().isEmpty) {
          correoManualController.text = correoManualFromDoc;
        }

        // fecha_apelacion: si no hay fecha seleccionada en el state, tomamos la del documento (si existe)
        if (fechaApelacion == null && latestData['fecha_apelacion'] != null) {
          try {
            // Si viene como Timestamp
            fechaApelacion = (latestData['fecha_apelacion'] as Timestamp).toDate();
          } catch (e) {
            // Intentar parsear string
            final s = (latestData['fecha_apelacion'] ?? '').toString();
            if (s.isNotEmpty) {
              try {
                fechaApelacion = DateTime.parse(s);
              } catch (_) {
                // dejar null si no se puede parsear
              }
            }
          }
        }
      }

      setState(() {
        userData = fetchedData;

        // Construir plantilla base: prioridad -> controller (si tiene texto) -> documento -> datos del PPL
        final entidadFinal = entidadController.text.trim().isNotEmpty
            ? entidadController.text.trim()
            : (latestData != null && (latestData['entidad_manual'] ?? '').toString().trim().isNotEmpty
            ? latestData['entidad_manual'].toString().trim()
            : (fetchedData.centroReclusion ?? ""));

        final radicadoFinal = numeroProcesoController.text.trim().isNotEmpty
            ? numeroProcesoController.text.trim()
            : (latestData != null && (latestData['numero_proceso'] ?? '').toString().trim().isNotEmpty
            ? latestData['numero_proceso'].toString().trim()
            : (fetchedData.radicado ?? ""));

        desistimientoApelacion = SolicitudDesistimientoApelacionTemplate(
          dirigido: "", // se asignará en la vista previa según selection o fallback
          entidad: entidadFinal,
          referencia: "Solicitudes varias - Solicitud desistimiento de apelación",
          nombrePpl: fetchedData.nombrePpl?.trim() ?? "",
          apellidoPpl: fetchedData.apellidoPpl?.trim() ?? "",
          identificacionPpl: fetchedData.numeroDocumentoPpl ?? "",
          centroPenitenciario: fetchedData.centroReclusion ?? "",
          emailUsuario: fetchedData.email?.trim() ?? "",
          emailAlternativo: "peticiones@tuprocesoya.com",
          radicado: radicadoFinal,
          numeroSeguimiento: widget.numeroSeguimiento,
          situacion: fetchedData.situacion ?? 'En Reclusión',
          nui: fetchedData.nui ?? "",
          td: fetchedData.td ?? "",
          patio: fetchedData.patio ?? "",
          fechaApelacion: fechaApelacion,
        );

        isLoading = false;
      });

    } else if (mounted) {
      // si no hay fetchedData, igual intentar cargar campos manuales del documento (para verlos)
      if (latestData != null) {
        final entidadFromDoc = (latestData['entidad_manual'] ?? '').toString().trim();
        if (entidadFromDoc.isNotEmpty && entidadController.text.trim().isEmpty) {
          entidadController.text = entidadFromDoc;
        }

        final nroFromDoc = (latestData['numero_proceso'] ?? '').toString().trim();
        if (nroFromDoc.isNotEmpty && numeroProcesoController.text.trim().isEmpty) {
          numeroProcesoController.text = nroFromDoc;
        }

        final correoFromDoc = (latestData['correo_manual'] ?? latestData['correo_manual_usado'] ?? '').toString().trim();
        if (correoFromDoc.isNotEmpty && correoManualController.text.trim().isEmpty) {
          correoManualController.text = correoFromDoc;
        }

        if (fechaApelacion == null && latestData['fecha_apelacion'] != null) {
          try {
            fechaApelacion = (latestData['fecha_apelacion'] as Timestamp).toDate();
          } catch (_) {}
        }
      }

      setState(() {
        userData = fetchedData;
        isLoading = false;
      });
    }
  }

  void fetchDocumentoSolicitudDesistimientoApelacion() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('desistimiento_apelacion_solicitados')
          .doc(widget.idDocumento);

      final documentSnapshot = await docRef.get();

      if (!documentSnapshot.exists) {
        if (kDebugMode) print("⚠️ Documento no encontrado en Firestore");
        return;
      }

      final data = documentSnapshot.data();

      solicitudData = data;

      if (data != null && mounted) {
        setState(() {
          diligencio = data['diligencio'] ?? 'No Diligenciado';
          reviso = data['reviso'] ?? 'No Revisado';
          envio = data['envió'] ?? 'No enviado';
          fechaEnvio = (data['fechaEnvio'] as Timestamp?)?.toDate();
          fechaDiligenciamiento = (data['fecha_diligenciamiento'] as Timestamp?)?.toDate();
          fechaRevision = (data['fecha_revision'] as Timestamp?)?.toDate();
          asignadoA_P2 = data['asignadoA_P2'] ?? '';
          asignadoNombreP2 = data['asignado_para_revisar'] ?? 'No asignado';
          fechaAsignadoP2 = (data['asignado_fecha_P2'] as Timestamp?)?.toDate();

          // --- Campos manuales guardados: asigna SOLO si Firestore trae valor no vacío
          final entidadManual = (data['entidad_manual'] ?? '').toString().trim();
          if (entidadManual.isNotEmpty && entidadController.text.trim().isEmpty) {
            entidadController.text = entidadManual;
          }

          final numeroProcesoManual = (data['numero_proceso_manual'] ?? '').toString().trim();
          if (numeroProcesoManual.isNotEmpty && numeroProcesoController.text.trim().isEmpty) {
            numeroProcesoController.text = numeroProcesoManual;
          }

          final correoManualGuardado = (data['correo_destino_manual'] ?? '').toString().trim();
          // Asignar si Firestore tiene valor y el controller está vacío (evita sobreescribir entrada del usuario)
          if (correoManualGuardado.isNotEmpty && correoManualController.text.trim().isEmpty) {
            correoManualController.text = correoManualGuardado;
          }

          // Fecha apelacion: solo asignar si no hay ya una seleccion en el controlador de UI
          if (data['fecha_apelacion'] != null && fechaApelacion == null) {
            try {
              fechaApelacion = (data['fecha_apelacion'] as Timestamp).toDate();
            } catch (_) {}
          }
        });
      }

    } catch (e) {
      if (kDebugMode) print("❌ Error al obtener datos de Firestore: $e");
    }
  }


  Future<void> calcularTiempo(String id) async {
    final pplData = await _pplProvider.getById(id);
    if (pplData != null) {
      final fechaCaptura = pplData.fechaCaptura;
      final meses = pplData.mesesCondena ?? 0;
      final dias = pplData.diasCondena ?? 0;
      final totalDiasCondena = (meses * 30) + dias;
      final fechaActual = DateTime.now();

      if (fechaCaptura == null || totalDiasCondena == 0) return;
      tiempoCondena = totalDiasCondena ~/ 30;
      final fechaFinCondena = fechaCaptura.add(Duration(days: totalDiasCondena));
      final diferenciaRestante = fechaFinCondena.difference(fechaActual);
      final diferenciaEjecutado = fechaActual.difference(fechaCaptura);

      mesesRestante = (diferenciaRestante.inDays ~/ 30);
      diasRestanteExactos = diferenciaRestante.inDays % 30;
      mesesEjecutado = diferenciaEjecutado.inDays ~/ 30;
      diasEjecutadoExactos = diferenciaEjecutado.inDays % 30;
      porcentajeEjecutado = (diferenciaEjecutado.inDays / totalDiasCondena) * 100;
      if (kDebugMode) print("Porcentaje de condena ejecutado: ${porcentajeEjecutado.toStringAsFixed(2)}%");
    } else {
      if (kDebugMode) print("❌ No hay datos");
    }
  }

  Widget _datosEjecucionCondena(double totalDiasRedimidos) {
    int totalDiasEjecutados = mesesEjecutado * 30 + diasEjecutadoExactos + totalDiasRedimidos.toInt();
    int totalDiasRestantes = (mesesRestante * 30 + diasRestanteExactos - totalDiasRedimidos).toInt();
    int mesesRestantesActualizados = totalDiasRestantes ~/ 30;
    int diasRestantesActualizados = totalDiasRestantes % 30;
    double nuevoPorcentajeEjecutado = ((totalDiasEjecutados) / (totalDiasEjecutados + totalDiasRestantes) * 100).clamp(0, 100);

    return DatosEjecucionCondena(
      mesesEjecutado: mesesEjecutado,
      diasEjecutadoExactos: diasEjecutadoExactos,
      mesesRestante: mesesRestantesActualizados,
      diasRestanteExactos: diasRestantesActualizados,
      totalDiasRedimidos: totalDiasRedimidos,
      porcentajeEjecutado: nuevoPorcentajeEjecutado,
      primary: Colors.grey,
      negroLetras: Colors.black,
    );
  }

  Widget vistaPreviaSolicitudDesistimientoApelacion({required Ppl? userData}) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('desistimiento_apelacion_solicitados')
          .doc(widget.idDocumento)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
        if (!snapshot.hasData || !snapshot.data!.exists) return const Text("No se encontró la solicitud desistimiento de apelación.");
        final data = snapshot.data!.data() as Map<String, dynamic>;

        // Determinamos entidad / radicado / correo destino (priorizando textfields)
        final entidadFinal = entidadController.text.isNotEmpty
            ? entidadController.text
            : (data['entidad_manual'] ?? userData?.centroReclusion ?? '');

        final radicadoFinal = numeroProcesoController.text.isNotEmpty
            ? numeroProcesoController.text
            : (data['numero_proceso'] ?? userData?.radicado ?? '');

        final dirigidoCalculado = (nombreCorreoSeleccionado != null && nombreCorreoSeleccionado!.isNotEmpty)
            ? obtenerTituloCorreo(nombreCorreoSeleccionado)
            : '';

        final plantilla = SolicitudDesistimientoApelacionTemplate(
          dirigido: dirigidoCalculado,
          entidad: entidadFinal,
          referencia: "Solicitudes varias - Solicitud desistimiento de apelación",
          nombrePpl: userData?.nombrePpl ?? "",
          apellidoPpl: userData?.apellidoPpl ?? "",
          identificacionPpl: userData?.numeroDocumentoPpl ?? "",
          centroPenitenciario: userData?.centroReclusion ?? "",
          emailUsuario: userData?.email ?? "",
          emailAlternativo: "peticiones@tuprocesoya.com",
          radicado: radicadoFinal,
          numeroSeguimiento: data['numero_seguimiento'] ?? widget.numeroSeguimiento,
          situacion: userData?.situacion ?? 'En Reclusión',
          nui: userData?.nui ?? "",
          td: userData?.td ?? "",
          patio: userData?.patio ?? "",
          fechaApelacion: fechaApelacion,
          motivoAdicional: data['motivo_adicional'] ?? '',
        );

        // Fragmento que devuelve la plantilla (puede ser fragmento <div>..)
        final fragmento = plantilla.generarTextoHtml();

        // Envolvemos en HTML completo para que flutter_html renderice EXACTAMENTE como en correo.
        final htmlParaPreview = '''
<html>
  <head>
    <meta charset="utf-8">
    <style>
      /* Fuerza alineación izquierda y espaciado similar al correo */
      body { font-family: Arial, Helvetica, sans-serif; color:#222; font-size:13px; line-height:1.6; text-align:left; margin:0; padding:12px; }
      .container { max-width:900px; margin:0 auto; }
      .dirigido { color: #222; font-weight: 600; font-size: 13px; margin-bottom:6px; }
      .entidad { color: #111; font-weight: 800; font-size: 18px; margin-bottom:12px; }
      .meta p { margin:4px 0; }
      .firma { margin-top:22px; line-height:1.1; }
    </style>
  </head>
  <body>
    <div class="container">
      $fragmento
    </div>
  </body>
</html>
''';

        if (kDebugMode) {
          print("DEBUG - HTML vista previa (long):\n$htmlParaPreview");
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Vista previa de la solicitud de desistimiento de apelación", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              child: Html(data: htmlParaPreview),
            ),
            const SizedBox(height: 50),
            Wrap(
              children: [
                if (widget.status == "Solicitado") guardarVistaPrevia(widget.idDocumento),
                if ((widget.status == "Diligenciado" || widget.status == "Revisado") && rol != "pasante 1") ...[
                  guardarRevisado(widget.idDocumento),
                  const SizedBox(width: 20),
                  botonEnviarCorreo(),
                ],
              ],
            ),
            const SizedBox(height: 150),
          ],
        );
      },
    );
  }


  String convertirSaltosDeLinea(String texto) => texto.replaceAll('\n', '<br>');

  Future<void> enviarCorreoResend({
    required String correoDestino,
    String? asuntoPersonalizado,
    String? prefacioHtml,
  }) async {
    final url = Uri.parse("https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/sendEmailWithResend");

    final doc = await FirebaseFirestore.instance.collection('desistimiento_apelacion_solicitados').doc(widget.idDocumento).get();
    final latestData = doc.data();
    if (latestData == null || userData == null) return;

    // Prioriza valores introducidos manualmente en los textfields
    final entidadSeleccionada = entidadController.text.isNotEmpty ? entidadController.text : obtenerEntidad(nombreCorreoSeleccionado ?? "");
    final radicadoManual = numeroProcesoController.text.isNotEmpty ? numeroProcesoController.text : (userData?.radicado ?? "");
    final fechaApelacionManual = fechaApelacion; // DateTime? (podría ser null)

    final fechaEnvioFormateada = DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now());
    final correoRemitente = FirebaseAuth.instance.currentUser?.email ?? adminFullName;
    final correoDestinatario = correoDestino;

    // Construimos la plantilla PASANDOLE los valores manuales (radicado, fechaApelacion, entidad)
    final desistimientoApelacion = SolicitudDesistimientoApelacionTemplate(
      dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado), // puede quedar vacío si quieres
      entidad: entidadSeleccionada,
      referencia: "Solicitudes varias - Solicitud desistimiento de apelación",
      nombrePpl: userData?.nombrePpl.trim() ?? "",
      apellidoPpl: userData?.apellidoPpl.trim() ?? "",
      identificacionPpl: userData?.numeroDocumentoPpl ?? "",
      centroPenitenciario: userData?.centroReclusion ?? "",
      emailUsuario: userData?.email.trim() ?? "",
      emailAlternativo: "peticiones@tuprocesoya.com",
      radicado: radicadoManual,
      numeroSeguimiento: widget.numeroSeguimiento,
      situacion: userData?.situacion ?? 'En Reclusión',
      nui: userData?.nui ?? "",
      td: userData?.td ?? "",
      patio: userData?.patio ?? "",
      fechaApelacion: fechaApelacionManual,
    );

    // Construimos el HTML final **SIN** prefacio manual fuera del template (evita duplicados)
    final htmlDelTemplate = desistimientoApelacion.generarTextoHtml();

    final mensajeHtml = """
<!doctype html>
<html>
  <head><meta charset="utf-8"></head>
  <body style="font-family: Arial, sans-serif; font-size: 12pt; color: #111; margin:0; padding:0;">
    <div style="padding:18px;">
      <p style="margin:2px 0; color:#333;"><strong>De:</strong> peticiones@tuprocesoya.com</p>
      <p style="margin:2px 0; color:#333;"><strong>Para:</strong> $correoDestinatario</p>
      <p style="margin:2px 0; color:#333;"><strong>Fecha de Envío:</strong> $fechaEnvioFormateada</p>
      <hr style="margin: 8px 0; border: 0; border-top: 1px solid #ccc;">
      $htmlDelTemplate
    </div>
  </body>
</html>
""";

    // Guardamos para referencias internas
    ultimoHtmlEnviado = mensajeHtml;

    final archivosBase64 = <Map<String, String>>[];
    final asuntoCorreo = asuntoPersonalizado ?? "Desistimiento de apelación – ${widget.numeroSeguimiento}";
    final enviadoPor = correoRemitente;

    final correosCC = <String>[];
    if (userData?.email != null && userData!.email.trim().isNotEmpty) correosCC.add(userData!.email.trim());

    final body = jsonEncode({
      "to": correoDestino,
      "cc": correosCC,
      "subject": asuntoCorreo,
      "html": mensajeHtml,
      "archivos": archivosBase64,
      "idDocumento": widget.idDocumento,
      "enviadoPor": enviadoPor,
      "tipo": "desistimiento_apelacion",
    });

    final response = await http.post(url, headers: {"Content-Type": "application/json"}, body: body);

    if (response.statusCode == 200) {
      await FirebaseFirestore.instance.collection('desistimiento_apelacion_solicitados').doc(widget.idDocumento).update({
        "status": "Enviado",
        "fechaEnvio": FieldValue.serverTimestamp(),
        "envió": adminFullName,
      });

      await ResumenSolicitudesHelper.actualizarResumen(idOriginal: widget.idDocumento, nuevoStatus: "Enviado", origen: "desistimiento_apelacion_solicitados");
    } else {
      if (kDebugMode) print("❌ Error al enviar el correo con Resend: ${response.body}");
    }
  }


  Widget botonEnviarCorreo() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        side: BorderSide(width: 1, color: Theme.of(context).primaryColor),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      onPressed: () async {
        // Validaciones básicas
        final correoManual = correoManualController.text.trim();
        final correoDestino = correoManual.isNotEmpty ? correoManual : (correoSeleccionado ?? "");
        if (correoDestino.isEmpty) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Text("Aviso"),
              content: const Text("No se ha indicado un correo destino. Ingresa uno manual o selecciona uno de la lista."),
              actions: [
                TextButton(child: const Text("OK"), onPressed: () => Navigator.of(ctx).pop()),
              ],
            ),
          );
          return;
        }

        // Confirmación final mostrando correo y datos del proceso
        final confirmar = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Confirmar envío"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Se enviará la solicitud a:"),
                const SizedBox(height: 8),
                SelectableText(correoDestino, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (entidadController.text.isNotEmpty) Text("Entidad: ${entidadController.text}"),
                if (numeroProcesoController.text.isNotEmpty) Text("No. proceso: ${numeroProcesoController.text}"),
                if (fechaApelacion != null) Text("Fecha apelación: ${DateFormat('yyyy-MM-dd').format(fechaApelacion!)}"),
                const SizedBox(height: 8),
                const Text("¿Deseas continuar?"),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancelar")),
              ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Enviar")),
            ],
          ),
        );

        if (confirmar != true) return;

        // Construir prefacio html con los datos manuales (solo para el manager si lo usa)
        final prefacioSb = StringBuffer();
        if (entidadController.text.isNotEmpty) prefacioSb.writeln('<p><strong>Entidad:</strong> ${entidadController.text}</p>');
        if (numeroProcesoController.text.isNotEmpty) prefacioSb.writeln('<p><strong>Número de proceso:</strong> ${numeroProcesoController.text}</p>');
        if (fechaApelacion != null) prefacioSb.writeln('<p><strong>Fecha de apelación:</strong> ${DateFormat('yyyy-MM-dd').format(fechaApelacion!)}</p>');
        final prefacioHtmlStr = prefacioSb.toString();

        // Preparar plantilla principal (cuerpo html)
        final plantilla = SolicitudDesistimientoApelacionTemplate(
          dirigido: 'Respetados Magistrados:',
          entidad: entidadController.text.isNotEmpty ? entidadController.text : entidad,
          referencia: "Solicitudes varias - Solicitud desistimiento de apelación",
          nombrePpl: userData?.nombrePpl ?? "",
          apellidoPpl: userData?.apellidoPpl ?? "",
          identificacionPpl: userData?.numeroDocumentoPpl ?? "",
          centroPenitenciario: userData?.centroReclusion ?? "",
          emailUsuario: userData?.email ?? "",
          emailAlternativo: "peticiones@tuprocesoya.com",
          radicado: userData?.radicado ?? "",
          numeroSeguimiento: widget.numeroSeguimiento,
          situacion: userData?.situacion ?? 'En Reclusión',
          nui: userData?.nui ?? "",
          td: userData?.td ?? "",
          patio: userData?.patio ?? "",
          fechaApelacion: fechaApelacion,
          motivoAdicional: solicitudData?['motivo_adicional'] ?? '',
        );

        // Cuerpo HTML (plantilla). IMPORTANTE: enviar un solo HTML completo (wrapper) para evitar duplicados/centrado.
        final cuerpoHtml = plantilla.generarTextoHtml();

        // Guardamos último HTML que se usará para copias / almacenamientos
        ultimoHtmlEnviado = cuerpoHtml;

        // Instanciar manager V7 (asegúrate de que tu clase exista y acepte estos parámetros)
        final manager = EnvioCorreoManagerV7();

        if (context.mounted) {
          await manager.enviarCorreoCompleto(
            context: context,
            correoDestinoPrincipal: correoDestino,
            html: cuerpoHtml, // cuerpo ya incluye encabezados / entidad / radicado en la plantilla
            numeroSeguimiento: widget.numeroSeguimiento,
            nombreAcudiente: userData?.nombreAcudiente ?? '',
            celularWhatsapp: userData?.celularWhatsapp,
            rutaHistorial: 'historial_solicitudes_redenciones_admin',
            nombreServicio: 'Desistimiento de apelación',
            idDocumentoSolicitud: widget.idDocumento,
            idDocumentoPpl: widget.idUser,
            centroPenitenciario: userData?.centroReclusion ?? '',
            nombrePpl: userData?.nombrePpl ?? '',
            apellidoPpl: userData?.apellidoPpl ?? '',
            identificacionPpl: userData?.numeroDocumentoPpl ?? '',
            nui: userData?.nui ?? '',
            td: userData?.td ?? '',
            patio: userData?.patio ?? '',
            beneficioPenitenciario: 'Desistimiento de apelación',
            juzgadoEp: userData?.juzgadoEjecucionPenas ?? '',
            parentescoAcudiente: userData?.parentescoRepresentante ?? '',
            apellidoAcudiente: userData?.apellidoAcudiente ?? '',
            identificacionAcudiente: (solicitudData?['cedula_responsable'] ?? '').toString(),
            celularAcudiente: userData?.celular,
            nombrePathStorage: "desistimientoApelacion",
            nombreColeccionFirestore: "desistimiento_apelacion_solicitados",

            // enviarCorreoResend: usamos el método que ya tienes; PASAR el prefacio que creaste (prefacioHtmlStr)
            enviarCorreoResend: ({required String correoDestino, String? asuntoPersonalizado, String? prefacioHtml}) async {
              // IMPORTANTE: aquí pasamos el prefacio recibido por el manager o el prefacio calculado
              await enviarCorreoResend(
                correoDestino: correoDestino,
                asuntoPersonalizado: asuntoPersonalizado,
                prefacioHtml: prefacioHtml ?? prefacioHtmlStr,
              );
            },

            // subirHtml: reusa tu método (asegúrate que el nombre y firma coincidan)
            subirHtml: ({required String tipoEnvio, required String htmlFinal, required String nombreColeccionFirestore, required String nombrePathStorage}) async {
              await subirHtmlCorreoADocumentoSolicitudRedenciones(
                idDocumento: widget.idDocumento,
                htmlFinal: htmlFinal,
                tipoEnvio: tipoEnvio,
              );
            },

            ultimoHtmlEnviado: ultimoHtmlEnviado,
          );
        }

        // Después del envío opcionalmente actualizar campos en doc con los datos manuales para trazabilidad
        try {
          final Map<String, dynamic> toSave = {
            'ultimo_envio_por': adminFullName,
            'ultimo_envio_fecha': FieldValue.serverTimestamp(),
          };
          if (entidadController.text.isNotEmpty) toSave['entidad_manual'] = entidadController.text;
          if (numeroProcesoController.text.isNotEmpty) toSave['numero_proceso'] = numeroProcesoController.text;
          if (fechaApelacion != null) toSave['fecha_apelacion'] = Timestamp.fromDate(fechaApelacion!);
          if (correoManual.isNotEmpty) toSave['correo_manual_usado'] = correoManual;

          await FirebaseFirestore.instance.collection('desistimiento_apelacion_solicitados').doc(widget.idDocumento).set(toSave, SetOptions(merge: true));
        } catch (e) {
          if (kDebugMode) print("❌ Error guardando metadatos post-envío: $e");
        }
      },
      child: const Text("Enviar por correo"),
    );
  }


  Future<void> subirHtmlCorreoADocumentoSolicitudRedenciones({
    required String idDocumento,
    required String htmlFinal,
    required String tipoEnvio,
  }) async {
    try {
      final contenidoFinal = htmlUtf8Compatible(htmlFinal);
      final bytes = utf8.encode(contenidoFinal);
      const fileName = "correo.html";
      final filePath = "desistimientoApelacion/$idDocumento/correos/$fileName";
      final ref = FirebaseStorage.instance.ref(filePath);
      final metadata = SettableMetadata(contentType: "text/html");
      await ref.putData(Uint8List.fromList(bytes), metadata);
      final downloadUrl = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection("desistimiento_apelacion_solicitados").doc(idDocumento).set({
        "correosGuardados.$tipoEnvio": downloadUrl,
        "fechaHtmlCorreo.$tipoEnvio": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (kDebugMode) print("✅ HTML $tipoEnvio guardado en: $downloadUrl");
    } catch (e) {
      if (kDebugMode) print("❌ Error al subir HTML $tipoEnvio: $e");
    }
  }

  String htmlUtf8Compatible(String html) {
    const headTag = "<head>";
    const metaCharset = '<meta charset="UTF-8">';
    if (html.contains(headTag)) {
      return html.replaceFirst(headTag, "$headTag\n  $metaCharset");
    } else {
      return "$metaCharset\n$html";
    }
  }

  void actualizarSolicitud(String docId, Map<String, dynamic> datosActualizar) {
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Error: ID del documento vacío")));
      return;
    }
    _controller.actualizarSolicitud(context, docId, datosActualizar);
  }

  Widget guardarVistaPrevia(String idDocumento) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(side: BorderSide(width: 1, color: Theme.of(context).primaryColor), backgroundColor: Colors.white, foregroundColor: Colors.black),
      onPressed: () async {
        adminFullName = AdminProvider().adminFullName ?? "";
        if (adminFullName.isEmpty && kDebugMode) {
          print("❌ No se pudo obtener el nombre del administrador.");
          return;
        }
        try {
          await FirebaseFirestore.instance.collection('desistimiento_apelacion_solicitados').doc(idDocumento).update({
            "status": "Diligenciado",
            "diligencio": adminFullName,
            "fecha_diligenciamiento": FieldValue.serverTimestamp(),
            "entidad_manual": entidadController.text.trim(),
            "numero_proceso_manual": numeroProcesoController.text.trim(),
            "correo_destino_manual": correoManualController.text.trim(),
            "fecha_apelacion": fechaApelacion != null ? Timestamp.fromDate(fechaApelacion!) : null,

          });
          await ResumenSolicitudesHelper.actualizarResumen(idOriginal: idDocumento, nuevoStatus: "Diligenciado", origen: "desistimiento_apelacion_solicitados");
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Solicitud marcada como diligenciada")));
            Navigator.of(context).pushReplacement(PageRouteBuilder(transitionDuration: const Duration(milliseconds: 300), transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final offsetAnimation = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(animation);
              return SlideTransition(position: offsetAnimation, child: child);
            }, pageBuilder: (context, animation, secondaryAnimation) {
              return const HistorialSolicitudesDesistimientoApelacionAdminPage();
            }));
          }
        } catch (e) {
          if (kDebugMode) print("❌ Error al actualizar la solicitud: $e");
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al actualizar la solicitud")));
        }
      },
      child: const Text("Marcar como Diligenciado"),
    );
  }

  Widget guardarRevisado(String idDocumento) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(side: BorderSide(width: 1, color: Theme.of(context).primaryColor), backgroundColor: Colors.white, foregroundColor: Colors.black),
      onPressed: () async {
        String adminFullNameLocal = AdminProvider().adminFullName ?? "";
        if (adminFullNameLocal.isEmpty) {
          if (kDebugMode) print("❌ No se pudo obtener el nombre del administrador.");
          return;
        }
        try {
          await FirebaseFirestore.instance.collection('desistimiento_apelacion_solicitados').doc(idDocumento).update({
            "status": "Revisado",
            "reviso": adminFullNameLocal,
            "fecha_revision": FieldValue.serverTimestamp(),
            "entidad_manual": entidadController.text.trim(),
            "numero_proceso_manual": numeroProcesoController.text.trim(),
            "correo_destino_manual": correoManualController.text.trim(),
            "fecha_apelacion": fechaApelacion != null ? Timestamp.fromDate(fechaApelacion!) : null,

          });
          await ResumenSolicitudesHelper.actualizarResumen(idOriginal: idDocumento, nuevoStatus: "Revisado", origen: "desistimiento_apelacion_solicitados");
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Solicitud guardada como 'Revisado'")));
            Navigator.of(context).pushReplacement(PageRouteBuilder(transitionDuration: const Duration(milliseconds: 300), transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final offsetAnimation = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(animation);
              return SlideTransition(position: offsetAnimation, child: child);
            }, pageBuilder: (context, animation, secondaryAnimation) {
              return const HistorialSolicitudesDesistimientoApelacionAdminPage();
            }));
          }
        } catch (e) {
          if (kDebugMode) print("❌ Error al actualizar la solicitud: $e");
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al actualizar la solicitud")));
        }
      },
      child: const Text("Marcar como Revisado"),
    );
  }
}
