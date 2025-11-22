
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:tuprocesoya/providers/ppl_provider.dart';
import '../../../commons/admin_provider.dart';
import '../../../commons/archivoViewerWeb2.dart';
import '../../../commons/main_layaout.dart';
import '../../../controllers/tiempo_condena_controller.dart';
import '../../../helper/resumen_solicitudes_helper.dart';
import '../../../models/ppl.dart';
import '../../../plantillas/plantilla_apelacion.dart';
import '../../../src/colors/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../widgets/calculo_beneficios_penitenciarios-general.dart';
import '../../../widgets/datos_ejecucion_condena.dart';
import '../../../widgets/envio_correo_manager.dart';
import '../../../widgets/manager_correo_sin_reclusion.dart';
import '../../../widgets/seleccionar_correo_centro_copia_correoV2.dart';
import '../../../widgets/selector_correo_manual.dart';
import '../historial_solicitudes_apelacion_admin/historial_solicitudes_apelacion_admin.dart';
import 'atender_solicitud_apelacion_controller.dart';

class AtenderApelacionPage extends StatefulWidget {
  final String status;
  final String idDocumento;
  final String numeroSeguimiento;
  final String fecha;
  final String idUser;
  final List<String> archivos;

  const AtenderApelacionPage({
    super.key,
    required this.status,
    required this.idDocumento,
    required this.numeroSeguimiento,
    required this.fecha,
    required this.idUser,
    required this.archivos,
  });

  @override
  State<AtenderApelacionPage> createState() => _AtenderApelacionPageState();
}

class _AtenderApelacionPageState extends State<AtenderApelacionPage> {
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
  List<Map<String, String>> archivosAdjuntos = [];

  final TextEditingController _fundamentosDerechoController = TextEditingController();
  final TextEditingController _fundamentosHechoController = TextEditingController();
  final TextEditingController _manifestacionPerdonController = TextEditingController();
  final TextEditingController _peticionController = TextEditingController();
  final TextEditingController _pruebasController = TextEditingController();
  final AtenderSolicitudApelacionAdminController _controller = AtenderSolicitudApelacionAdminController();
  String fundamentosDeHecho = "";
  String fundamentosDeDerecho = "";
  String manifestacionPerdon = "";
  String peticion = "";
  String pruebas = "";
  bool _mostrarVistaPrevia = false;
  bool _mostrarBotonVistaPrevia = false;
  Map<String, String> correosCentro = {};
  late DocumentReference userDoc;
  String? correoSeleccionado= ""; // Guarda el correo seleccionado
  String? nombreCorreoSeleccionado;
  String idDocumento="";
  bool _isFundamentosDeHechoLoaded = false;
  bool _isFundamentosLoaded = false;
  bool _isManifestacionPerdonLoaded = false;
  bool _isPeticionLoaded = false; // Bandera para evitar sobrescribir
  bool _isPruebasLoaded = false; // Bandera para evitar sobrescribir
  String adminFullName="";
  String entidad= "";
  String diligencio = '';
  String reviso = '';
  String envio = '';
  DateTime? fechaEnvio;
  DateTime? fechaDiligenciamiento;
  DateTime? fechaRevision;
  List<String> archivos = [];
  String rol = AdminProvider().rol ?? "";
  late ApelacionTemplate apelacionTemplate;
  String asignadoA_P2 = '';
  String asignadoNombreP2 = '';
  DateTime? fechaAsignadoP2;
  String? textoGeneradoIA; // A nivel de clase (State)
  bool mostrarCardIA = false;
  Map<String, dynamic>? solicitudData;
  late CalculoCondenaController _calculoCondenaController;

  ///NUEVOS PARA TODAS LAS PANTALLAS DE ATENDER
  String? correoManual;
  String? entidadSeleccionada;
  String? nombreCiudadSeleccionada;

  DateTime? _fechaAutoSeleccionada;
  final TextEditingController _beneficioController = TextEditingController();
  List<String> archivosFirestore = [];



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _pplProvider = PplProvider();
    archivosAdjuntos = widget.archivos.map((archivo) {
      return {
        "nombre": obtenerNombreArchivo(archivo),
        "contenido": archivo,
      };
    }).toList();
    _calculoCondenaController = CalculoCondenaController(_pplProvider);

    fetchUserData();
    fetchDocumentoApelacion();
    calcularTiempo(widget.idUser);

    _fundamentosHechoController.addListener(_actualizarAltura);
    _fundamentosDerechoController.addListener(_actualizarAltura);
    _manifestacionPerdonController.addListener(_actualizarAltura);
    _peticionController.addListener(_actualizarAltura);
    _pruebasController.addListener(_actualizarAltura);


    WidgetsBinding.instance.addPostFrameCallback((_) {
      cargarFundamentodHecho(widget.idDocumento);
      cargarFundamentosDeDerecho(widget.idDocumento);
      cargarManifestacionPerdon(widget.idDocumento);
      cargarPeticion(widget.idDocumento);
      cargarPruebas(widget.idDocumento);
    });
    adminFullName = AdminProvider().adminFullName ?? ""; // Nombre completo
    if (adminFullName.isEmpty) {
      if (kDebugMode) {
        print("❌ No se pudo obtener el nombre del administrador.");
      }
    }
    archivos = List<String>.from(widget.archivos); // Copia los archivos una vez
  }

  String obtenerNombreArchivo(String url) {
    // Decodifica la URL para que %2F se convierta en "/"
    String decodedUrl = Uri.decodeFull(url);
    // Separa por "/" y toma la última parte
    List<String> partes = decodedUrl.split('/');
    // El nombre real del archivo es la última parte después de la última "/"
    return partes.last.split('?').first; // Quita cualquier parámetro después de "?"
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 1000;
    return MainLayout(
      pageTitle: 'Atender solicitud Apelación',
      content: isWide
          ? Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scroll SOLO en contenido principal
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildMainContent(),
            ),
          ),
          const SizedBox(width: 24),
          // Extra widget sticky (NO se mueve)
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

  /// 🖥️📱 Widget de contenido principal (sección izquierda en PC)
  Widget _buildMainContent() {
    // 🔹 Aquí declaras tus variables antes de devolver la Column
    final String fechaAuto = _fechaAutoSeleccionada != null
        ? DateFormat("d 'de' MMMM 'de' yyyy", 'es').format(_fechaAutoSeleccionada!)
        : "Fecha no seleccionada";

    final String beneficioSolicitado = _beneficioController.text.isNotEmpty
        ? _beneficioController.text
        : "Beneficio no especificado";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFechaHoy(),
        const SizedBox(height: 10),
        if (rol == "masterFull" || rol == "master" || rol == "coordinador 1")
          infoAccionesAdmin(),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _obtenerColorFondo(widget.status),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            children: [
              MediaQuery.of(context).size.width < 600
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Apelación",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        widget.status,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 15),
                      CircleAvatar(
                        radius: 6,
                        backgroundColor:
                        _obtenerColorStatus(widget.status),
                      ),
                    ],
                  ),
                ],
              )
                  : Row(
                children: [
                  Text(
                    "Apelación - ${widget.status}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  CircleAvatar(
                    radius: 12,
                    backgroundColor:
                    _obtenerColorStatus(widget.status),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildSolicitadoPor(),
              const SizedBox(height: 15),
              _buildDetallesSolicitud(),
              const SizedBox(height: 20),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📎 Auto (archivo_decision)
            _buildArchivoSimple(
              titulo: "📎 Auto que se va a apelar",
              url: solicitudData?['archivo_decision']?.toString(),
            ),

            // 📎 Anexo (url único en el campo 'anexos')
            _buildArchivoSimple(
              titulo: "📎 Anexo",
              url: solicitudData?['anexos']?.toString(),
            ),

            // 📄 Otros adjuntos que vienen desde widget.archivos (si los usas)
            if (widget.archivos.isNotEmpty) ...[
              const Text("📄 Otros archivos adjuntos",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ArchivoViewerWeb2(archivos: widget.archivos),
              const SizedBox(height: 20),
            ],

            // Si no hay ninguno
            if ((solicitudData?['archivo_decision'] == null ||
                solicitudData!['archivo_decision'].toString().isEmpty) &&
                (solicitudData?['anexos'] == null ||
                    solicitudData!['anexos'].toString().isEmpty) &&
                widget.archivos.isEmpty)
              const Text(
                "El usuario no compartió ningún archivo",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red),
              ),
          ],
        ),

        const SizedBox(height: 30),
        buildFechaYBeneficioSelector(),
        const SizedBox(height: 20),

        const SizedBox(height: 30),
        const Divider(color: gris),
        if (((widget.status == "Diligenciado" ||
            widget.status == "Revisado" ||
            widget.status == "Enviado") &&
            rol != "pasante 1") ||
            (widget.status == "Solicitado" && rol == "pasante 1") ||
            (rol == "master" ||
                rol == "masterFull" ||
                rol == "coordinador 1" ||
                rol == "coordinador 2"))
          Column(
            children: [
              Text(
                "Espacio de diligenciamiento",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.width < 600 ? 20 : 28,
                ),
              ),
              const SizedBox(height: 30),
              ingresarFundamentosDeHecho(),
              const SizedBox(height: 30),
              ingresarFundamentosDeDerecho(),
              const SizedBox(height: 30),
              ingresarManifestacionPerdon(),
              const SizedBox(height: 30),
              ingresarPeticion(),
              const SizedBox(height: 30),
              ingresarPruebas(),
              const SizedBox(height: 30),
            ],
          ),
        if (((widget.status == "Diligenciado" ||
            widget.status == "Revisado" ||
            widget.status == "Enviado") &&
            rol != "pasante 1") ||
            (widget.status == "Solicitado" && rol == "pasante 1") ||
            (rol == "master" ||
                rol == "masterFull" ||
                rol == "coordinador 1" ||
                rol == "coordinador 2"))
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              side: BorderSide(
                  width: 1, color: Theme.of(context).primaryColor),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              setState(() {
                _guardarDatosEnVariables();
              });
            },
            child: const Text("Guardar información"),
          ),
        const SizedBox(height: 10),
        if (_mostrarBotonVistaPrevia)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  side: BorderSide(
                      width: 1, color: Theme.of(context).primaryColor),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    fundamentosDeHecho = _fundamentosHechoController.text.trim();
                    fundamentosDeDerecho =
                        _fundamentosDerechoController.text.trim();
                    manifestacionPerdon =
                        _manifestacionPerdonController.text.trim();
                    peticion = _peticionController.text.trim();
                    pruebas = _pruebasController.text.trim();
                    _mostrarVistaPrevia = !_mostrarVistaPrevia;
                  });
                },
                child: const Text("Vista previa"),
              ),
              if (_mostrarVistaPrevia) const SizedBox(height: 50),
            ],
          ),
        if (_mostrarVistaPrevia)
          vistaPreviaApelacion(
            userData: userData,
            fundamentosDeHecho: _fundamentosHechoController.text,
            fundamentosDeDerecho: _fundamentosDerechoController.text,
            manifestacionPerdon: _manifestacionPerdonController.text,
            peticion: _peticionController.text,
            pruebas: _pruebasController.text,
            fechaAuto: fechaAuto,
            beneficioSolicitado: beneficioSolicitado,
          ),
      ],
    );
  }

  Widget _buildArchivoSimple({required String titulo, String? url}) {
    final u = url?.trim();
    if (u == null || u.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ArchivoViewerWeb2(archivos: [u]),
        const SizedBox(height: 20),
      ],
    );
  }


  Widget buildFechaYBeneficioSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🌟 Selector de fecha
        const Text(
          "Fecha del auto que negó el beneficio",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _fechaAutoSeleccionada ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                _fechaAutoSeleccionada = picked;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fechaAutoSeleccionada != null
                      ? "${_fechaAutoSeleccionada!.day.toString().padLeft(2, '0')}/${_fechaAutoSeleccionada!.month.toString().padLeft(2, '0')}/${_fechaAutoSeleccionada!.year}"
                      : "Seleccionar fecha",
                  style: const TextStyle(fontSize: 14),
                ),
                const Icon(Icons.calendar_today, size: 18),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 🌟 Dropdown de beneficios
        const Text(
          "Beneficio que fue negado",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          value: _beneficioController.text.isNotEmpty ? _beneficioController.text : null,
          hint: const Text("Seleccionar beneficio"),
          items: const [
            DropdownMenuItem(value: "Permiso de 72 horas", child: Text("Permiso de 72 horas")),
            DropdownMenuItem(value: "Prisión domiciliaria", child: Text("Prisión domiciliaria")),
            DropdownMenuItem(value: "Libertad Condicional", child: Text("Libertad Condicional")),
            DropdownMenuItem(value: "Extinción de la pena", child: Text("Extinción de la pena")),
          ],
          onChanged: (value) {
            setState(() {
              _beneficioController.text = value ?? "";
            });
          },
        ),
      ],
    );
  }

  void _actualizarAltura() {
    int lineas = '\n'.allMatches(_fundamentosHechoController.text).length + 1;
    setState(() {
// Limita el crecimiento a 5 líneas
    });
  }

  void _guardarDatosEnVariables() {
    if ( _fundamentosHechoController.text.isEmpty || _fundamentosDerechoController.text.isEmpty || _manifestacionPerdonController.text.isEmpty
        || _peticionController.text.isEmpty || _pruebasController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Todos los campos deben estar llenos."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      _mostrarBotonVistaPrevia = false;
      _mostrarVistaPrevia = false;
      return; // Detiene la ejecución si hay campos vacíos
    }

    setState(() {
      fundamentosDeHecho = _fundamentosHechoController.text;
      fundamentosDeDerecho = _fundamentosDerechoController.text;
      manifestacionPerdon = _manifestacionPerdonController.text;
      peticion = _peticionController.text;
      pruebas = _pruebasController.text;

    });
    _mostrarBotonVistaPrevia = true;
  }

  @override
  void dispose() {

    _fundamentosHechoController.removeListener(_actualizarAltura);
    _fundamentosDerechoController.removeListener(_actualizarAltura);
    _manifestacionPerdonController.removeListener(_actualizarAltura);
    _peticionController.removeListener(_actualizarAltura);
    _pruebasController.removeListener(_actualizarAltura);
    _fundamentosHechoController.dispose();
    _fundamentosDerechoController.dispose();
    _manifestacionPerdonController.dispose();
    _peticionController.dispose();
    _pruebasController.dispose();
    super.dispose();
  }

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
        return primary; // Puedes usar Colors.blue o Theme.of(context).primaryColor
      default:
        return Colors.grey; // Color por defecto
    }
  }

  Color _obtenerColorFondo(String status) {
    switch (status) {
      case "Solicitado":
        return const Color(0xFFFFF5F5); // Rojo extra claro
      case "Diligenciado":
        return const Color(0xFFFFFBEA); // Ámbar extra claro
      case "Revisado":
        return const Color(0xFFF5EAFE); // primary extra claro
      default:
        return const Color(0xFFFAFAFA); // Gris casi blanco
    }
  }

  Widget _buildSolicitadoPor() {
    bool isMobile = MediaQuery.of(context).size.width < 600; // Detectar si es móvil

    return isMobile
        ? Align(
      alignment: Alignment.centerLeft, // Asegura que todo el contenido esté alineado a la izquierda
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Solicitado por:",
            style: TextStyle(
              fontSize: 12, // Tamaño reducido en móviles
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2), // Espaciado entre las líneas en móvil
          Text(
            "${userData?.nombreAcudiente ?? "Sin información"} ${userData?.apellidoAcudiente ?? "Sin información"}",
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    )

        : Row( // En PC, mantener en una fila
      children: [
        const Text(
          "Solicitado por:",
          style: TextStyle(
            fontSize: 14, // Tamaño normal en PC
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8), // Espacio entre los textos en PC
        Text(
          "${userData?.nombreAcudiente ?? "Sin información"} ${userData?.apellidoAcudiente ?? "Sin información"}",
          style: const TextStyle(fontSize: 14),
        ),
      ],
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
              _buildDetalleItem("Categoría", "Solicitdes varias", fontSize),
              const SizedBox(height: 5),
              _buildDetalleItem("Fecha de solicitud", _formatFecha(DateTime.tryParse(widget.fecha)), fontSize),
              const SizedBox(height: 5),
              _buildDetalleItem("Subcategoría", "Apelación", fontSize),
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
                  _buildDetalleItem("Categoría", "Solicitudes varias", fontSize),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetalleItem("Fecha de solicitud", _formatFecha(DateTime.tryParse(widget.fecha)), fontSize),
                  const SizedBox(height: 5),
                  _buildDetalleItem("Subcategoría", "Apelación", fontSize),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget infoAccionesAdmin() {
    if (asignadoA_P2.isEmpty && diligencio.isEmpty && reviso.isEmpty && envio.isEmpty) {
      return const SizedBox();
    }

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Historial de acciones", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (asignadoA_P2.isNotEmpty)
                _buildAccion("Asignado para revisar: ", asignadoNombreP2, fechaAsignadoP2, isMobile),
              if (widget.status == "Diligenciado" || widget.status == "Revisado" || widget.status == "Enviado")
                _buildAccion("Diligenció: ", diligencio, fechaDiligenciamiento, isMobile),
              if (widget.status == "Revisado" || widget.status == "Enviado")
                _buildAccion("Revisó: ", reviso, fechaRevision, isMobile),
              if (widget.status == "Enviado")
                _buildAccion("Envió: ", envio, fechaEnvio, isMobile),
              const SizedBox(height: 10),
              Text("ID del documento: ${widget.idDocumento}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccion(String label, String usuario, DateTime? fecha, bool isMobile) {
    final fechaTexto = _formatFecha(fecha);
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black87, fontSize: 13)),
          Text(usuario, style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
          Text(fechaTexto, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
        ],
      );
    } else {
      return Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.black87, fontSize: 13)),
          Text(usuario, style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(width: 15),
          Text(fechaTexto, style: const TextStyle(fontSize: 12)),
        ],
      );
    }
  }

  void verificarVistaPrevia() {
    setState(() {
      _mostrarBotonVistaPrevia =
          _fundamentosHechoController.text.trim().isNotEmpty &&
              _fundamentosDerechoController.text.trim().isNotEmpty &&
              _manifestacionPerdonController.text.trim().isNotEmpty &&
              _peticionController.text.trim().isNotEmpty &&
              _pruebasController.text.trim().isNotEmpty;
    });
  }

  /// 📅 Muestra la fecha de hoy en formato adecuado
  Widget _buildFechaHoy() {
    return Text(
      'Hoy es: ${DateFormat('d \'de\' MMMM \'de\' y', 'es').format(DateTime.now())}',
      style: const TextStyle(fontSize: 12),
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

  /// 📆 Función para manejar errores en la conversión de fechas
  String _formatFecha(DateTime? fecha, {String formato = "dd 'de' MMMM 'de' yyyy - hh:mm a"}) {
    if (fecha == null) return "";
    return DateFormat(formato, 'es').format(fecha);
  }

  /// 🎉 Nuevo Widget (Columna extra en PC, o debajo en móvil)
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
      QuerySnapshot redencionesSnapshot = await FirebaseFirestore.instance
          .collection('Ppl')
          .doc(pplId)
          .collection('redenciones')
          .get();

      for (var doc in redencionesSnapshot.docs) {
        totalDias += (doc['dias_redimidos'] as num).toDouble();
      }

      print("📌 Total días redimidos en el atender: $totalDias"); // 🔥 Mostrar en consola
    } catch (e) {
      print("❌ Error calculando redenciones: $e");
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

  // Función para generar cada fila con el botón "Elegir"
  Widget correoConBoton(String nombre, String? correo) {
    bool isSelected = nombre == nombreCorreoSeleccionado; // Verifica si es el seleccionado
    return GestureDetector(
      onTap: () {
        setState(() {
          correoSeleccionado = correo;
          nombreCorreoSeleccionado = nombre;
          entidad = obtenerEntidad(nombre);
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '$nombre: ${correo ?? 'Cargando...'}',
                style: const TextStyle(fontSize: 12, color: Colors.black),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  correoSeleccionado = correo;
                  nombreCorreoSeleccionado = nombre;
                  entidad = obtenerEntidad(nombre);
                });
              },
              child: Text(
                isSelected ? 'Elegido' : 'Elegir',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.black : Colors.blue,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void fetchUserData() async {
    // 🔹 Obtener datos del usuario
    Ppl? fetchedData = await _pplProvider.getById(widget.idUser);

    // 🔹 Obtener el documento en Firestore
    final doc = await FirebaseFirestore.instance
        .collection('apelacion_solicitados')
        .doc(widget.idDocumento)
        .get();

    final latestData = doc.data();

    if (fetchedData != null && latestData != null && mounted) {
      // 🔹 Primero calcular correctamente los tiempos
      await _calculoCondenaController.calcularTiempo(widget.idUser);

      // 🔹 FUNDAMENTOS DE HECHO
      _fundamentosHechoController.text = generarTextoFundamentosDeHechoDesdeDatos(
        fetchedData,
        "En Reclusión", // Usa fijo si no tienes situacion en Ppl
      );

      // 🔹 FUNDAMENTOS DE DERECHO
      if (!_isFundamentosLoaded) {
        _fundamentosDerechoController.text = generarTextoFundamentosDeDerechoApelacion();
        _isFundamentosLoaded = true;
      }

      // 🔹 MANIFESTACION PERDÓN
      if (!_isManifestacionPerdonLoaded) {
        _manifestacionPerdonController.text = generarTextoManifestacionPerdonYCompromiso();
        _isManifestacionPerdonLoaded = true;
      }

      // 🔹 PETICION
      if (!_isPeticionLoaded) {
        _peticionController.text = generarTextoPeticion();
        _isPeticionLoaded = true;
      }

      // 🔹 PRUEBAS
      if (!_isPruebasLoaded) {
        _pruebasController.text = generarTextoPruebas();
        _isPruebasLoaded = true;
      }

      setState(() {
        userData = fetchedData;

        // 🔹 Primero generas los valores de fecha y beneficio
        final String fechaAuto = _fechaAutoSeleccionada != null
            ? DateFormat("d 'de' MMMM 'de' y", 'es').format(_fechaAutoSeleccionada!)
            : "Fecha no seleccionada";

        final String beneficioSolicitado = _beneficioController.text.isNotEmpty
            ? _beneficioController.text
            : "Beneficio no especificado";

        apelacionTemplate = ApelacionTemplate(
          dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
          entidad: fetchedData.centroReclusion ?? "",
          referencia: "Solicitudes varias - Apelación",
          nombrePpl: fetchedData.nombrePpl?.trim() ?? "",
          apellidoPpl: fetchedData.apellidoPpl?.trim() ?? "",
          identificacionPpl: fetchedData.numeroDocumentoPpl ?? "",
          centroPenitenciario: fetchedData.centroReclusion ?? "",
          fundamentosDeHecho: _fundamentosHechoController.text.trim(),
          fundamentosDeDerecho: _fundamentosDerechoController.text.trim(),
          manifestacionPerdon: _manifestacionPerdonController.text.trim(),
          peticion: _peticionController.text.trim(),
          pruebas: _pruebasController.text.trim(),
          emailUsuario: fetchedData.email?.trim() ?? "",
          nui: fetchedData.nui ?? "",
          td: fetchedData.td ?? "",
          patio: fetchedData.patio ?? "",
          radicado: fetchedData.radicado ?? "",
          delito: fetchedData.delito ?? "",
          condena: fetchedData.diasCondena != null && fetchedData.diasCondena! > 0
              ? "${fetchedData.mesesCondena ?? 0} meses y ${fetchedData.diasCondena} días"
              : "${fetchedData.mesesCondena ?? 0} meses",
          purgado: "$mesesEjecutado",
          jdc: fetchedData.juzgadoQueCondeno ?? "",
          numeroSeguimiento: widget.numeroSeguimiento,
          fechaAuto: fechaAuto,
          beneficioSolicitado: beneficioSolicitado,
        );

        isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        userData = fetchedData;
        isLoading = false;
      });
    }
  }


  String formatearFechaCaptura(String fechaString) {
    try {
      final fecha = DateTime.parse(fechaString); // convierte el string en DateTime
      final formato = DateFormat("d 'de' MMMM 'de' y", 'es'); // formato en español
      return formato.format(fecha);
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  String generarTextoFundamentosDeHechoDesdeDatos(
      Ppl userData,
      String situacion,
      ) {
    final jdc = userData.juzgadoQueCondeno ?? '';
    final meses = userData.mesesCondena ?? 0;
    final dias = userData.diasCondena ?? 0;
    final condena = (dias > 0) ? '$meses meses y $dias días' : '$meses meses';

    final captura = userData.fechaCaptura?.toString() ?? '';
    final delito = userData.delito ?? '';
    final fechaFormateada = formatearFechaCaptura(captura);

    String texto =
        "Mediante sentencia proferida por el $jdc, se impuso una condena de $condena de prisión por el delito de $delito. "
        "Me encuentro privado de la libertad desde el $fechaFormateada, cumpliendo un periodo sustancial de la pena impuesta.\n\n";

    if (situacion == "En Prisión domiciliaria") {
      texto +=
      "Actualmente, me encuentro cumpliendo dicha condena bajo la modalidad de prisión domiciliaria.\n\n";
    }

    texto += """
He cumplido las tres quintas (3/5) partes de la pena —hecho reconocido por el despacho— y mantengo conducta intramuros buena/ejemplar con concepto disciplinario favorable.

La negativa se basó, esencialmente, en la revocatoria de mi prisión domiciliaria por una salida del domicilio el 20/07/2024. Dicha salida obedeció a <b>una necesidad familiar inmediata y comprobable</b>: la compra de medicamentos para mi madre, BLANCA CECILIA MONTENEGRO (72 años), quien cursa patología ginecológica oncológica en control (resección de masas anexiales; informe de patología con cistoadenofibroma seroso y seguimientos de oncología). El desplazamiento fue a pocas cuadras de mi domicilio.

Lejos de sustraerme de la autoridad, <b>me presenté voluntariamente</b> en la Penitenciaría el 12/11/2024 a las 11:30 a. m., en compañía de mi esposa Marcela Ramírez y de mi madre, siendo atendidos hasta las 2:00 p. m. por un funcionario del INPEC de apellido Rodríguez, quien me entregó la boleta de citación.

Cuento con arraigo familiar reforzado: además del cuidado de mi madre adulta mayor, tengo un hijo de 13 años a mi cargo.

No existen nuevos incumplimientos ni anotaciones negativas posteriores por mi parte; por el contrario, mantengo buen desempeño, disposición a reparar y someterme a condiciones estrictas.
""";

    return texto;
  }


  String generarTextoManifestacionPerdonYCompromiso() {
    return """
Quiero expresar con humildad y profundo arrepentimiento mi sincero perdón a las personas que resultaron afectadas por mis acciones. Reconozco que mis actos causaron dolor y perjuicio, y asumo plena responsabilidad por ellos.

Durante el tiempo que he permanecido privado de la libertad he reflexionado con honestidad sobre las consecuencias de mis decisiones y sobre el compromiso que tengo conmigo mismo, con mi familia y con la sociedad de no volver a transitar caminos que vulneren la ley ni los derechos de los demás.

Hoy manifiesto mi firme voluntad de reparar, en la medida de lo posible, el daño ocasionado y de demostrar con hechos mi transformación personal. Mi propósito es continuar construyendo un proyecto de vida digno, basado en el respeto, la honestidad y la responsabilidad.

Como muestra de este compromiso, me ofrezco voluntariamente a realizar actividades de trabajo social o servicio comunitario que contribuyan de manera positiva al bienestar de mi comunidad y que permitan redignificar mi rol como ciudadano.

Ruego a su señoría recibir estas palabras como testimonio auténtico de mi arrepentimiento y de mi determinación de no reincidir, con la esperanza de que mi petición sea valorada con la comprensión que merece todo ser humano que lucha por una segunda oportunidad.
""";
  }


  String generarTextoFundamentosDeDerechoApelacion() {
    return """
<b>I. El recurso de apelación y su fundamento constitucional y legal</b>

El recurso de apelación se encuentra consagrado en los artículos 176 y siguientes del Código de Procedimiento Penal (Ley 906 de 2004), como un medio ordinario de impugnación que permite al procesado solicitar la revisión integral de la decisión ante el superior jerárquico.

El artículo 29 de la Constitución Política de Colombia garantiza el debido proceso, el derecho a la defensa, el acceso a la doble instancia y la posibilidad de controvertir las decisiones judiciales.

<i>La Corte Constitucional, en Sentencia C-591 de 2005, precisó que la apelación constituye una garantía esencial para la protección de los derechos fundamentales de las personas condenadas, en tanto posibilita un nuevo examen de los aspectos de hecho y de derecho que sustentan la decisión recurrida.</i>

El artículo 177 de la Ley 906 de 2004 establece que el recurso debe interponerse y sustentarse en los términos legales, especificando los motivos de inconformidad y las pretensiones del recurrente.

<b>II. Finalidad resocializadora de la pena</b>

El artículo 4 del Código Penal señala que:

“La pena tiene como finalidad la prevención general, la retribución justa, la prevención especial, la reinserción social y la protección al condenado.”

<i>La Corte Constitucional, en Sentencia C-646 de 2001, estableció que el proceso penal debe propender por la resocialización y no por la venganza estatal. La negación automática del beneficio solicitado desconoce esta finalidad humanizadora y la dimensión pedagógica de la pena.</i>

<b>III. Control de convencionalidad y estándares internacionales</b>

La Convención Americana sobre Derechos Humanos (artículo 5) y el Pacto Internacional de Derechos Civiles y Políticos (artículo 10) disponen que toda pena privativa de libertad debe ejecutarse con respeto a la dignidad humana y con la posibilidad efectiva de reinserción social.

<i>La Corte Interamericana de Derechos Humanos, en la Opinión Consultiva OC-21/14, indicó que todo sistema penal debe garantizar mecanismos de revisión periódica de la ejecución de la sanción.</i>

<i>La aplicación de restricciones absolutas y automáticas, sin análisis individualizado, resulta contraria a estos estándares internacionales.</i>

<b>IV. Interpretación restrictiva y principio de proporcionalidad</b>

<i>La Sentencia C-250 de 2011 ordena que las limitaciones a los derechos fundamentales deben ser interpretadas de manera restrictiva.</i>

<i>La Sentencia SU-159 de 2002 precisa que cualquier restricción debe fundarse en criterios de proporcionalidad, razonabilidad y necesidad, motivados expresamente en cada caso concreto.</i>

En la decisión impugnada no se valoraron de manera suficiente mi evolución personal, el contexto que rodeó la conducta punible ni las circunstancias actuales que sustentan la viabilidad del beneficio.

<b>V. Consideración de circunstancias personales y sociales</b>

El artículo 64 del Código Penal dispone que:

“Para decidir sobre la concesión de la libertad condicional, el juez valorará las condiciones personales, familiares, sociales y económicas del condenado…”

Provengo de un contexto de significativas limitaciones económicas y sociales que, si bien no justifican el hecho cometido, marcaron mi historia de vida y mi vulnerabilidad frente a factores de riesgo. Esta circunstancia debe ponderarse en la evaluación de mi proceso de resocialización y de la proporcionalidad de la negativa.

<b>VI. Responsabilidad individualizada</b>

<i>La Corte Constitucional ha señalado que la responsabilidad penal es esencialmente individual y exige un análisis detallado de la conducta y la participación específica de cada persona.</i>

La aplicación indiscriminada de la restricción legal, sin individualizar mi grado de participación y las particularidades de mi situación, genera incertidumbre jurídica y afecta la motivación de la decisión.

Con fundamento en las disposiciones normativas y jurisprudenciales expuestas, solicito que se revoque o modifique la decisión apelada, en garantía de los derechos fundamentales que amparan mi situación jurídica.
""";
  }





  String generarTextoPeticion() {
    return """
Por lo expuesto, solicito muy respetuosamente al despacho superior:

I. Revocar la decisión recurrida

Que se revoque el auto recurrido dentro del proceso de la referencia y, en su lugar, se emita un pronunciamiento que conceda la libertad condicional, en atención a mi conducta resocializadora, al principio de proporcionalidad, al control de convencionalidad y a los estándares internacionales aplicables.

II. Subsidiariamente

Que, de manera subsidiaria, se declare la inaplicación del numeral 5º del artículo 199 de la Ley 1098 de 2006, en tanto resulta contrario al bloque de constitucionalidad, a la finalidad resocializadora de la pena y a la exigencia de motivación individualizada de las decisiones judiciales.

III. En su defecto

Que se ordene la emisión de una nueva decisión debidamente motivada, que valore de manera completa y ponderada las circunstancias personales, familiares, sociales y económicas que rodean mi situación, así como mi evolución penitenciaria, mi compromiso de resocialización y las manifestaciones de arrepentimiento consignadas.

IV. Compulsa de copias

Así mismo, solicito se ordene la compulsa de copias del presente escrito al despacho judicial correspondiente y a la Oficina Jurídica del establecimiento de reclusión en el que me encuentro privado de la libertad, con el fin de garantizar la publicidad del trámite, el respeto de los derechos fundamentales y el cumplimiento de las etapas procesales pertinentes.

Ruego a su señoría tener en consideración mi situación personal y las razones de hecho y derecho que sustentan esta solicitud.
""";
  }


  String generarTextoPruebas() {
    return """
Para efectos probatorios y de conformidad con la ley procesal, aporto como único anexo el documento que contiene la decisión que se impugna mediante este recurso de apelación.

Igualmente, solicito al despacho que, de oficio, se requieran y alleguen al expediente los siguientes documentos:

- Informes del Equipo Interdisciplinario que acrediten mi evolución personal, social y familiar.
- Certificados de participación en programas de formación y trabajo desarrollados durante mi condena.
- Declaraciones o conceptos obrantes en el expediente relacionados con mi comportamiento y progreso.

Lo anterior con el fin de valorar de manera integral mi situación y sustentar la procedencia de la petición elevada.
""";
  }

  void fetchDocumentoApelacion() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('apelacion_solicitados')
          .doc(widget.idDocumento)
          .get();

      if (!snap.exists) {
        if (kDebugMode) print("⚠️ Documento no encontrado en Firestore");
        return;
      }

      final data = snap.data() as Map<String, dynamic>?;
      solicitudData = data;

      if (data != null && mounted) {
        // --- datos cabecera ---
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

          // --- adjuntos ---
          final List<String> adjuntos = [];

          final archDecision = data['archivo_decision']?.toString().trim();
          if (archDecision != null && archDecision.isNotEmpty) adjuntos.add(archDecision);

          final anexoUnico = data['anexos']?.toString().trim(); // ← un solo URL
          if (anexoUnico != null && anexoUnico.isNotEmpty) adjuntos.add(anexoUnico);

          archivosFirestore = adjuntos; // para tu UI
        });
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error al obtener datos de Firestore: $e");
    }
  }


  //Para los tiempos de los beneficios
  Future<void> calcularTiempo(String id) async {
    final pplData = await _pplProvider.getById(id);
    if (pplData != null) {
      final fechaCaptura = pplData.fechaCaptura;
      final meses = pplData.mesesCondena ?? 0;
      final dias = pplData.diasCondena ?? 0;

      final totalDiasCondena = (meses * 30) + dias;
      final fechaActual = DateTime.now();

      if (fechaCaptura == null || totalDiasCondena == 0) {
        print("❌ Fecha de captura o condena no válida.");
        return;
      }

      /// ✅ Esta línea es la que te faltaba
      tiempoCondena = totalDiasCondena ~/ 30;

      final fechaFinCondena = fechaCaptura.add(Duration(days: totalDiasCondena));
      final diferenciaRestante = fechaFinCondena.difference(fechaActual);
      final diferenciaEjecutado = fechaActual.difference(fechaCaptura);

      mesesRestante = (diferenciaRestante.inDays ~/ 30);
      diasRestanteExactos = diferenciaRestante.inDays % 30;

      mesesEjecutado = diferenciaEjecutado.inDays ~/ 30;
      diasEjecutadoExactos = diferenciaEjecutado.inDays % 30;

      porcentajeEjecutado = (diferenciaEjecutado.inDays / totalDiasCondena) * 100;

      print("Porcentaje de condena ejecutado: ${porcentajeEjecutado!.toStringAsFixed(2)}%");

      if (porcentajeEjecutado! >= 33.33) {
        print("✅ Aplica permiso administrativo de 72 horas");
      } else {
        print("❌ No aplica permiso administrativo de 72 horas");
      }

      if (porcentajeEjecutado! >= 50) {
        print("✅ Aplica prisión domiciliaria");
      } else {
        print("❌ No aplica prisión domiciliaria");
      }

      if (porcentajeEjecutado! >= 60) {
        print("✅ Aplica libertad condicional");
      } else {
        print("❌ No aplica libertad condicional");
      }

      if (porcentajeEjecutado! >= 100) {
        print("✅ Aplica extinción de la pena");
      } else {
        print("❌ No aplica extinción de la pena");
      }

      print("Tiempo restante: $mesesRestante meses y $diasRestanteExactos días");
      print("Tiempo ejecutado: $mesesEjecutado meses y $diasEjecutadoExactos días");
    } else {
      if (kDebugMode) {
        print("❌ No hay datos");
      }
    }
  }

  Widget _datosEjecucionCondena(double totalDiasRedimidos) {
    // 🔹 Asegurar que los cálculos usen `totalDiasRedimidos`
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

  // corregido full
  Future<void> cargarFundamentodHecho(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('apelacion_solicitados')
          .doc(docId)
          .get();

      if (doc.exists && !_isFundamentosDeHechoLoaded) {
        final data = doc.data() as Map<String, dynamic>?;

        final texto = data?['fundamentos_de_hecho'];
        if (texto != null && texto is String) {
          setState(() {
            _fundamentosHechoController.text = texto;
            _isFundamentosDeHechoLoaded = true;
          });

          verificarVistaPrevia();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error cargando fundamentos de hecho: $e");
      }
    }
  }
  //corregido full
  Future<void> cargarFundamentosDeDerecho(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('apelacion_solicitados')
          .doc(docId)
          .get();

      if (doc.exists && !_isFundamentosLoaded) {
        final data = doc.data() as Map<String, dynamic>?;

        final texto = data?['fundamentos_de_derecho'];
        if (texto != null && texto is String) {
          setState(() {
            _fundamentosDerechoController.text = texto;
            _isFundamentosLoaded = true;
          });

          verificarVistaPrevia();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error cargando fundamentos de derecho: $e");
      }
    }
  }

  Future<void> cargarManifestacionPerdon(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('apelacion_solicitados')
          .doc(docId)
          .get();

      if (doc.exists && !_isManifestacionPerdonLoaded) {
        final data = doc.data() as Map<String, dynamic>?;

        final texto = data?['manifestacion_perdon'];
        if (texto != null && texto is String) {
          setState(() {
            _manifestacionPerdonController.text = texto;
            _isManifestacionPerdonLoaded = true;
          });

          verificarVistaPrevia();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error cargando manifestacion perdon: $e");
      }
    }
  }


  //corregido full
  Future<void> cargarPeticion(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('apelacion_solicitados')
          .doc(docId)
          .get();

      if (doc.exists && !_isPeticionLoaded) {
        final data = doc.data() as Map<String, dynamic>?;

        final texto = data?['peticion'];
        if (texto != null && texto is String) {
          setState(() {
            _peticionController.text = texto;
            _isPeticionLoaded = true;
          });

          verificarVistaPrevia();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error cargando peticion: $e");
      }
    }
  }

  //corregido full
  Future<void> cargarPruebas(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('apelacion_solicitados')
          .doc(docId)
          .get();

      if (doc.exists && !_isPruebasLoaded) {
        final data = doc.data() as Map<String, dynamic>?;

        final texto = data?['pruebas'];
        if (texto != null && texto is String) {
          setState(() {
            _pruebasController.text = texto;
            _isPruebasLoaded = true;
          });

          verificarVistaPrevia();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error cargando pruebas: $e");
      }
    }
  }


  Widget ingresarFundamentosDeHecho() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "FUNDAMENTOS DE HECHO",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _fundamentosHechoController,
          minLines: 1,
          maxLines: null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade600),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: const TextStyle(fontSize: 14),
          onChanged: (_) => verificarVistaPrevia(),
        )
      ],
    );
  }

  Widget ingresarFundamentosDeDerecho() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "FUNDAMENTOS DE DERECHO",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _fundamentosDerechoController,
          minLines:1,
          maxLines: null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100, // Fondo gris claro
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400), // Borde gris cuando no está enfocado
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade600), // Borde gris oscuro cuando se enfoca
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: const TextStyle(fontSize: 14),
          onChanged: (_) => verificarVistaPrevia(),
        )
      ],
    );
  }
  // corregido full - autollenado por IA o se puede escribir igualmente
  Widget ingresarManifestacionPerdon() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "MANIFESTACIÓN DE PERDÓN",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _manifestacionPerdonController,
          minLines:1,
          maxLines: null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100, // Fondo gris claro
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400), // Borde gris cuando no está enfocado
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade600), // Borde gris oscuro cuando se enfoca
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: const TextStyle(fontSize: 14),
          onChanged: (_) => verificarVistaPrevia(),
        )
      ],
    );
  }

  Widget ingresarPeticion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "PETICIÓN",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _peticionController,
          minLines:1,
          maxLines: null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100, // Fondo gris claro
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400), // Borde gris cuando no está enfocado
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade600), // Borde gris oscuro cuando se enfoca
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: const TextStyle(fontSize: 14),
          onChanged: (_) => verificarVistaPrevia(),
        )
      ],
    );
  }

  Widget ingresarPruebas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "PRUEBAS",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _pruebasController,
          minLines:1,
          maxLines: null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100, // Fondo gris claro
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400), // Borde gris cuando no está enfocado
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade600), // Borde gris oscuro cuando se enfoca
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: const TextStyle(fontSize: 14),
          onChanged: (_) => verificarVistaPrevia(),
        )
      ],
    );
  }


  Widget vistaPreviaApelacion({
    required Ppl? userData,
    required String fundamentosDeHecho,
    required String fundamentosDeDerecho,
    required String manifestacionPerdon,
    required String peticion,
    required String pruebas,
    required String fechaAuto,
    required String beneficioSolicitado,
  }) {
    final plantilla = ApelacionTemplate(
      dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
      entidad: entidad,
      referencia: "Solicitudes varias - Apelación",
      nombrePpl: userData?.nombrePpl ?? "",
      apellidoPpl: userData?.apellidoPpl ?? "",
      identificacionPpl: userData?.numeroDocumentoPpl ?? "",
      centroPenitenciario: userData?.centroReclusion ?? "",
      fundamentosDeHecho: convertirSaltosDeLinea(fundamentosDeHecho),
      fundamentosDeDerecho: convertirSaltosDeLinea(fundamentosDeDerecho),
      manifestacionPerdon: convertirSaltosDeLinea(manifestacionPerdon),
      peticion: convertirSaltosDeLinea(peticion),
      pruebas: convertirSaltosDeLinea(pruebas),
      emailUsuario: userData?.email ?? "",
      nui: userData?.nui ?? "",
      td: userData?.td ?? "",
      patio: userData?.patio ?? "",
      radicado: userData?.radicado ?? "",
      delito: userData?.delito ?? "",
      condena: userData?.diasCondena != null && userData!.diasCondena! > 0
          ? "${userData?.mesesCondena ?? 0} meses y ${userData?.diasCondena} días"
          : "${userData?.mesesCondena ?? 0} meses",
      purgado: "$mesesEjecutado",
      jdc: userData?.juzgadoQueCondeno ?? "",
      numeroSeguimiento: widget.numeroSeguimiento,
      fechaAuto: fechaAuto,
      beneficioSolicitado: beneficioSolicitado,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vista previa de la solicitud Apelación",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Html(data: plantilla.generarTextoHtml()),
        ),
        const SizedBox(height: 50),
        Wrap(
          children: [
            if (widget.status == "Solicitado") ...[
              guardarVistaPrevia(widget.idDocumento),
            ],
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
  }



  String convertirSaltosDeLinea(String texto) {
    return texto.replaceAll('\n', '<br>');
  }

  Future<void> enviarCorreoResend({
    required String correoDestino,
    String? asuntoPersonalizado,
    String? prefacioHtml}) async {
    final url = Uri.parse("https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/sendEmailWithResend");

    final doc = await FirebaseFirestore.instance
        .collection('apelacion_solicitados')
        .doc(widget.idDocumento)
        .get();

    final latestData = doc.data();
    if (latestData == null || userData == null) return;

    final String fechaAuto = _fechaAutoSeleccionada != null
        ? DateFormat('d \'de\' MMMM \'de\' yyyy', 'es').format(_fechaAutoSeleccionada!)
        : "Fecha no seleccionada";

    final String beneficioSolicitado = _beneficioController.text.isNotEmpty
        ? _beneficioController.text
        : "Beneficio no especificado";

    final entidadSeleccionada = obtenerEntidad(nombreCorreoSeleccionado ?? "");

    apelacionTemplate = ApelacionTemplate(
      dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
      entidad: entidadSeleccionada,
      referencia: "Solitudes varias - Apelación",
      nombrePpl: userData?.nombrePpl.trim() ?? "",
      apellidoPpl: userData?.apellidoPpl.trim() ?? "",
      identificacionPpl: userData?.numeroDocumentoPpl ?? "",
      centroPenitenciario: userData?.centroReclusion ?? "",
      fundamentosDeHecho: fundamentosDeHecho,
      fundamentosDeDerecho: fundamentosDeDerecho,
      manifestacionPerdon: manifestacionPerdon,
      peticion: peticion,
      pruebas: pruebas,
      emailUsuario: userData?.email.trim() ?? '',
      nui: userData?.nui ?? '',
      td: userData?.td ?? '',
      patio: userData?.patio ?? '',
      radicado: userData?.radicado ?? '',
      delito: userData?.delito ?? '',condena: userData?.diasCondena != null && userData!.diasCondena! > 0
        ? "${userData?.mesesCondena ?? 0} meses y ${userData?.diasCondena} días"
        : "${userData?.mesesCondena ?? 0} meses",
      purgado: "$mesesEjecutado meses y $diasEjecutadoExactos días",
      jdc: userData?.juzgadoQueCondeno ?? '',
      numeroSeguimiento: widget.numeroSeguimiento,
      fechaAuto: fechaAuto,
      beneficioSolicitado: beneficioSolicitado);


    String mensajeHtml = "${prefacioHtml ?? ''}${apelacionTemplate.generarTextoHtml()}";

    List<Map<String, String>> archivosBase64 = [];

    // Función auxiliar para procesar cualquier archivo por URL
    Future<void> procesarArchivo(String urlArchivo) async {
      try {
        String nombreArchivo = obtenerNombreArchivo(urlArchivo);
        final response = await http.get(Uri.parse(urlArchivo));
        if (response.statusCode == 200) {
          String base64String = base64Encode(response.bodyBytes);
          archivosBase64.add({
            "nombre": nombreArchivo,
            "base64": base64String,
            "tipo": lookupMimeType(nombreArchivo) ?? "application/octet-stream",
          });
        }
      } catch (e) {
        if (kDebugMode) print("❌ Error al procesar archivo $urlArchivo: $e");
      }
    }

    // 🔹 Reunir TODAS las URLs de adjuntos (UI + Firestore) y deduplicar
    final Set<String> urlsAdjuntas = {};

// 1) Lo que llegó a esta pantalla (posibles adjuntos del flujo)
    urlsAdjuntas.addAll(
      widget.archivos.where((e) => e.trim().isNotEmpty),
    );

// 2) Lo que cargaste desde el doc (archivo_decision y anexos ya unidos en fetchDocumentoApelacion)
    urlsAdjuntas.addAll(
      archivosFirestore.where((e) => e.trim().isNotEmpty),
    );

// 3) Fallback directo por si archivosFirestore aún no estaba poblado en este instante
    final dec = solicitudData?['archivo_decision']?.toString().trim();
    if (dec != null && dec.isNotEmpty) urlsAdjuntas.add(dec);

    final anex = solicitudData?['anexos']?.toString().trim();
    if (anex != null && anex.isNotEmpty) urlsAdjuntas.add(anex);

// 4) Descargar y adjuntar cada URL
    for (final urlAdj in urlsAdjuntas) {
      await procesarArchivo(urlAdj);
    }


    final asuntoCorreo = asuntoPersonalizado ?? "Solicitud Apelación - ${widget.numeroSeguimiento}";
    final currentUser = FirebaseAuth.instance.currentUser;
    final enviadoPor = currentUser?.email ?? adminFullName;

    List<String> correosCC = [];
    if (userData?.email != null && userData!.email.trim().isNotEmpty) {
      correosCC.add(userData!.email.trim());
    }

    final body = jsonEncode({
      "to": correoDestino,
      "cc": correosCC,
      "subject": asuntoCorreo,
      "html": mensajeHtml,
      "archivos": archivosBase64,
      "idDocumento": widget.idDocumento,
      "enviadoPor": enviadoPor,
      "tipo": "apelacion",
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      await FirebaseFirestore.instance
          .collection('apelacion_solicitados')
          .doc(widget.idDocumento)
          .update({
        "status": "Enviado",
        "fechaEnvio": FieldValue.serverTimestamp(),
        "envió": adminFullName,
      });

      await ResumenSolicitudesHelper.actualizarResumen(
        idOriginal: widget.idDocumento,
        nuevoStatus: "Enviado",
        origen: "apelacion_solicitados",
      );
    } else {
      if (kDebugMode) {
        print("❌ Error al enviar el correo con Resend: ${response.body}");
      }
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
        if (correoSeleccionado == null || correoSeleccionado!.isEmpty) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Text("Aviso"),
              content: const Text("No se ha seleccionado un correo electrónico."),
              actions: [
                TextButton(
                  child: const Text("OK"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
          return;
        }

        // 1) Calcula dirigido + entidad a partir del correo seleccionado
        final String dirigido = obtenerTituloCorreo(nombreCorreoSeleccionado);
        final String entidadDestino =
            obtenerEntidad(nombreCorreoSeleccionado ?? "") ??
                (userData?.juzgadoEjecucionPenas ?? "Juzgado de ejecución de penas");

        // 2) Refresca el template ANTES de generar el HTML (igual que en Readecuación)
        apelacionTemplate = ApelacionTemplate(
          dirigido: dirigido,
          entidad: entidadDestino,
          referencia: apelacionTemplate.referencia,
          nombrePpl: apelacionTemplate.nombrePpl,
          apellidoPpl: apelacionTemplate.apellidoPpl,
          identificacionPpl: apelacionTemplate.identificacionPpl,
          centroPenitenciario: apelacionTemplate.centroPenitenciario,
          fundamentosDeHecho: apelacionTemplate.fundamentosDeHecho,
          fundamentosDeDerecho: apelacionTemplate.fundamentosDeDerecho,
          manifestacionPerdon: apelacionTemplate.manifestacionPerdon,
          peticion: apelacionTemplate.peticion,
          pruebas: apelacionTemplate.pruebas,
          emailUsuario: apelacionTemplate.emailUsuario,
          nui: apelacionTemplate.nui,
          td: apelacionTemplate.td,
          patio: apelacionTemplate.patio,
          radicado: apelacionTemplate.radicado,
          delito: apelacionTemplate.delito,
          condena: apelacionTemplate.condena,
          purgado: apelacionTemplate.purgado,
          jdc: apelacionTemplate.jdc,
          numeroSeguimiento: apelacionTemplate.numeroSeguimiento,
          fechaAuto: apelacionTemplate.fechaAuto,
          beneficioSolicitado: apelacionTemplate.beneficioSolicitado,
        );

        // 3) Genera el HTML del cuerpo ya con dirigido + entidad correctos (sin prefacio arriba)
        final String htmlActual = apelacionTemplate.generarTextoHtml();

        // 4) Usa el Manager V4 (sin centro)
        final envioCorreoManager = EnvioCorreoManagerV4();

        await envioCorreoManager.enviarCorreoCompleto(
          context: context,
          correoDestinoPrincipal: correoSeleccionado!,
          html: htmlActual, // body puro
          numeroSeguimiento: apelacionTemplate.numeroSeguimiento,
          nombreAcudiente: userData?.nombreAcudiente ?? "Usuario",
          celularWhatsapp: userData?.celularWhatsapp,
          rutaHistorial: 'historial_solicitudes_apelacion_admin',
          nombreServicio: "Apelación",

          // IDs
          idDocumentoSolicitud: widget.idDocumento,
          idDocumentoPpl: widget.idUser,

          // Compat (se piden por firma; el manager V4 los ignora internamente)
          centroPenitenciario: userData?.centroReclusion ?? '',
          nombrePpl: userData?.nombrePpl ?? '',
          apellidoPpl: userData?.apellidoPpl ?? '',
          identificacionPpl: userData?.numeroDocumentoPpl ?? '',
          nui: userData?.nui ?? '',
          td: userData?.td ?? '',
          patio: userData?.patio ?? '',
          beneficioPenitenciario: '',
          juzgadoEp: userData?.juzgadoEjecucionPenas ?? '',

          // OJO: coincide con tu helper (usas "apelacion" en singular en el path)
          nombrePathStorage: "apelacion",
          nombreColeccionFirestore: "apelacion_solicitados",

          // Envío real del principal: SIN prefacio
          enviarCorreoResend: ({
            required String correoDestino,
            String? asuntoPersonalizado,
            String? prefacioHtml,
          }) async {
            await enviarCorreoResend(
              correoDestino: correoDestino,
              asuntoPersonalizado: asuntoPersonalizado,
              prefacioHtml: prefacioHtml
            );
          },

          // Guardado: usa htmlFinal que manda el manager (para "principal" será el body)
          subirHtml: ({
            required String tipoEnvio,
            required String htmlFinal,
            required String nombreColeccionFirestore,
            required String nombrePathStorage,
          }) async {
            await subirHtmlCorreoADocumentoApelacion(
              idDocumento: widget.idDocumento,
              htmlContent: htmlFinal,
              tipoEnvio: tipoEnvio, // "principal" o "reparto"
            );
          },

          // El manager lo usará para el encabezado uniforme en copias
          ultimoHtmlEnviado: htmlActual,

          // Compat: centro (no se usa en V4)
          buildSelectorCorreoCentroReclusion: ({
            required Function(String correo, String nombreCentro) onEnviarCorreo,
            required Function() onOmitir,
          }) {
            return const SizedBox.shrink();
          },

          // Reparto (igual que antes)
          buildSelectorCorreoReparto: ({
            required Function(String correo, String entidad) onCorreoValidado,
            required Function(String nombreCiudad) onCiudadNombreSeleccionada,
            required Function(String correo, String entidad) onEnviarCorreoManual,
            required Function() onOmitir,
          }) {
            return SelectorCorreoManualFlexible(
              entidadSeleccionada: userData?.juzgadoEjecucionPenas ?? "Juzgado de ejecución de penas",
              onCorreoValidado: onCorreoValidado,
              onCiudadNombreSeleccionada: onCiudadNombreSeleccionada,
              onEnviarCorreoManual: onEnviarCorreoManual,
              onOmitir: () => Navigator.of(context).pop(),
            );
          },
        );
      },
      child: const Text("Enviar por correo"),
    );
  }


  Future<void> subirHtmlCorreoADocumentoApelacion({
    required String idDocumento,
    required String htmlContent,
    required String tipoEnvio, // "principal" | "reparto" (etc.)
  }) async {
    final contenidoFinal = htmlUtf8Compatible(htmlContent);
    final bytes = utf8.encode(contenidoFinal);
    final fileName = "correo_$tipoEnvio.html";
    final filePath = "apelacion/$idDocumento/correos/$fileName";

    final ref = FirebaseStorage.instance.ref(filePath);
    final metadata = SettableMetadata(contentType: "text/html");
    await ref.putData(Uint8List.fromList(bytes), metadata);

    final downloadUrl = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection("apelacion_solicitados")
        .doc(idDocumento)
        .set({
      "correosGuardados.$tipoEnvio": downloadUrl,          // ⬅️ igual que readecuación
      "fechaHtmlCorreo.$tipoEnvio": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }



  /// 💡 Corrige el HTML para asegurar que tenga codificación UTF-8
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Error: ID del documento vacío"))
      );
      return;
    }
    _controller.actualizarSolicitud(context, docId, datosActualizar);
  }

  Widget guardarVistaPrevia(String idDocumento) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        side: BorderSide(width: 1, color: Theme.of(context).primaryColor),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      onPressed: () async {
        adminFullName = AdminProvider().adminFullName ?? "";
        if (adminFullName.isEmpty) {
          if (kDebugMode) {
            print("❌ No se pudo obtener el nombre del administrador.");
          }
          return;
        }

        try {
          await FirebaseFirestore.instance
              .collection('apelacion_solicitados')
              .doc(idDocumento)
              .update({
            "status": "Diligenciado",
            "diligencio": adminFullName,
            "fecha_diligenciamiento": FieldValue.serverTimestamp(),
            "fundamentos_de_hecho": _fundamentosHechoController.text,
            "fundamentos_de_derecho": _fundamentosDerechoController.text,
            "manifestacion_perdon": _manifestacionPerdonController.text,
            "peticion": _peticionController.text,
            "pruebas": _pruebasController.text,
          });

          // 🔁 Actualizar también el resumen en solicitudes_usuario
          await ResumenSolicitudesHelper.actualizarResumen(
            idOriginal: idDocumento,
            nuevoStatus: "Diligenciado",
            origen: "apelacion_solicitados",
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Solicitud marcada como diligenciada")),
            );

            // ✅ Transición deslizante hacia la página de historial
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(1.0, 0.0), // Desde la derecha
                    end: Offset.zero,
                  ).animate(animation);

                  return SlideTransition(position: offsetAnimation, child: child);
                },
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const HistorialSolicitudesApelacionAdminPage();
                },
              ),
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print("❌ Error al actualizar la solicitud: $e");
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Error al actualizar la solicitud")),
            );
          }
        }
      },
      child: const Text("Marcar como Diligenciado"),
    );
  }


  Widget guardarRevisado(String idDocumento) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        side: BorderSide(width: 1, color: Theme.of(context).primaryColor),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      onPressed: () async {
        String adminFullName = AdminProvider().adminFullName ?? "";
        if (adminFullName.isEmpty) {
          if (kDebugMode) {
            print("❌ No se pudo obtener el nombre del administrador.");
          }
          return;
        }

        try {
          await FirebaseFirestore.instance
              .collection('apelacion_solicitados')
              .doc(idDocumento)
              .update({
            "status": "Revisado",
            "reviso": adminFullName,
            "fecha_revision": FieldValue.serverTimestamp(),
            "fundamentos_de_hecho": _fundamentosHechoController.text,
            "fundamentos_de_derecho": _fundamentosDerechoController.text,
            "manifestacion_perdon": _manifestacionPerdonController.text,
            "peticion": _peticionController.text,
            "pruebas": _pruebasController.text,
          });

          await ResumenSolicitudesHelper.actualizarResumen(
            idOriginal: idDocumento,
            nuevoStatus: "Revisado",
            origen: "apelacion_solicitados",
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Solicitud guardada como 'Revisado'")),
            );

            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation);
                  return SlideTransition(position: offsetAnimation, child: child);
                },
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const HistorialSolicitudesApelacionAdminPage();
                },
              ),
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print("❌ Error al actualizar la solicitud: $e");
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Error al actualizar la solicitud")),
            );
          }
        }
      },
      child: const Text("Marcar como Revisado"),
    );
  }

  int _calcularDias(int metaPorcentaje) {
    final diferencia = porcentajeEjecutado - metaPorcentaje;
    return (diferencia.abs() / 100 * tiempoCondena * 30).round();
  }

  Widget _buildBenefitMinimalSection({
    required String titulo,
    required bool condition,
    required int remainingTime,
  }) {
    return Card(
      color: Colors.white,
      surfaceTintColor: blanco,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: condition ? Colors.green.shade700 : Colors.red.shade700, // Borde dinámico
          width: 2.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              condition
                  ? "Hace $remainingTime días"
                  : "Faltan $remainingTime días",
              style: TextStyle(
                color: condition ? Colors.green.shade700 : Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
