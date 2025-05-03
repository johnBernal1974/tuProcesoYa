
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/Pages/administrador/atender_derecho_peticion_admin/atender_derecho_peticionAdmin_controler.dart';
import 'package:tuprocesoya/providers/ppl_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../commons/admin_provider.dart';
import '../../../commons/archivoViewerWeb.dart';
import '../../../commons/archivoViewerWeb2.dart';
import '../../../commons/ia_backend_service/IASuggestionCard.dart';
import '../../../commons/ia_backend_service/IASuggestionCardTutela.dart';
import '../../../commons/ia_backend_service/ia_backend_service.dart';
import '../../../commons/main_layaout.dart';
import '../../../helper/helpersTutela/derechos_vulnerados_helper.dart';
import '../../../helper/texto_tutela_helper.dart';
import '../../../models/ppl.dart';
import '../../../plantillas/plantilla_derecho_peticion.dart';
import '../../../plantillas/plantilla_tutela.dart';
import '../../../src/colors/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../widgets/datos_ejecucion_condena.dart';
import 'atender_tutela_controler.dart';

class AtenderTutelaPage extends StatefulWidget {
  final String status;
  final String idDocumento;
  final String numeroSeguimiento;
  final String categoria;
  final String subcategoria;
  final String fecha;
  final String idUser;
  final List<dynamic> archivos; // Lista de archivos
  final List<String> respuestas; // Lista de respuestas
  final List<String> preguntas; // Lista de preguntas

  const AtenderTutelaPage({
    super.key,
    required this.status,
    required this.idDocumento,
    required this.numeroSeguimiento,
    required this.categoria,
    required this.subcategoria,
    required this.fecha,
    required this.idUser,
    required this.archivos,
    required this.respuestas,
    required this.preguntas,// Nuevo parámetro agregado
  });

  @override
  State<AtenderTutelaPage> createState() => _AtenderDerechoPeticionPageState();
}


class _AtenderDerechoPeticionPageState extends State<AtenderTutelaPage> {
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
  final TextEditingController _hechosController = TextEditingController();
  final TextEditingController _derechosVulneradosController = TextEditingController();
  final TextEditingController _normasAplicablesController = TextEditingController();
  final TextEditingController _pretensionesController = TextEditingController();
  final TextEditingController _pruebasController = TextEditingController();
  final AtenderTutelaAdminController _controller = AtenderTutelaAdminController();

  String hechos = "";
  String derechosVulnerados = "";
  String normasAplicables = "";
  String pretensiones = "";
  String pruebas = "";
  String juramento = "";

  bool _mostrarVistaPrevia = false;
  bool _mostrarBotonVistaPrevia = false;
  Map<String, String> correosCentro = {};
  late DocumentReference userDoc;
  String? correoSeleccionado= ""; // Guarda el correo seleccionado
  String? nombreCorreoSeleccionado;
  String idDocumento="";
  bool _isHechosLoaded = false;
  bool _isDerechosVulneradosLoaded = false;
  bool _isPretensionesLoaded = false;
  bool _isPruebasLoaded = false;
  bool _isJuramentoLoaded = false;
  bool _isNomasAplicablesLoaded = false;
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
  late TutelaTemplate accionTutela;
  String asignadoA_P2 = '';
  String asignadoNombreP2 = '';
  DateTime? fechaAsignadoP2;
  String? textoGeneradoIA; // A nivel de clase (State)
  bool mostrarCardIA = false;
  bool _isFundamentosCargados = false;




  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _pplProvider = PplProvider();
    archivosAdjuntos = widget.archivos.map((archivo) {
      return {
        "nombre": obtenerNombreArchivo(archivo), // Asegura que es String
        "contenido": archivo as String, // Asegura que es String
      };
    }).toList();
    fetchUserData();
    fetchDocumentoTutela();
    calcularTiempo(widget.idUser);
    _hechosController.addListener(_actualizarAltura);
    _derechosVulneradosController.addListener(_actualizarAltura);
    _pretensionesController.addListener(_actualizarAltura);
    _normasAplicablesController.addListener(_actualizarAltura);
    _pruebasController.addListener(_actualizarAltura);
    DocumentReference userDoc = FirebaseFirestore.instance.collection('Ppl').doc(widget.idUser);
    obtenerCorreosCentro(userDoc).then((correos) {
      setState(() {
        correosCentro = correos;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cargarHechos(widget.idDocumento);
      cargarDerechosVulnerados(widget.idDocumento);
      cargarPretensiones(widget.idDocumento);
      cargarNormasAplicables(widget.idDocumento);
      cargarPruebas(widget.idDocumento);
    });
    if (!_isFundamentosCargados && _derechosVulneradosController.text.trim().isEmpty) {
      final textoCompleto = TextoDerechosVulneradosHelper.obtenerTexto(
        categoria: widget.categoria,
        subcategoria: widget.subcategoria,
      );

      final fund = TextoFundamentacionTutelaHelper.obtenerFundamentacion(
        categoria: widget.categoria,
        subcategoria: widget.subcategoria,
      );

      _derechosVulneradosController.text = textoCompleto;
      _normasAplicablesController.text = fund['normas_aplicables'] ?? '';
      _pretensionesController.text = fund['pretensiones'] ?? '';
      _pruebasController.text = fund['pruebas'] ?? '';

      _isFundamentosCargados = true;
    }

    adminFullName = AdminProvider().adminFullName ?? ""; // Nombre completo
    if (adminFullName.isEmpty) {
      if (kDebugMode) {
        print("❌ No se pudo obtener el nombre del administrador.");
      }
    }
    archivos = List<String>.from(widget.archivos);
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
      pageTitle: 'ATENDER ACCIÓN DE TUTELA',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFechaHoy(),
        const SizedBox(height: 10),
        if(rol == "masterFull" || rol == "master" || rol == "coordinador 1")
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
                  ? Column( // En móviles, cambia a columna
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Acción de tutela ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20, // Reduce tamaño en móviles
                    ),
                  ),
                  const SizedBox(height: 5), // Espaciado entre el texto y el círculo en móvil
                  Row(
                    children: [
                      Text(
                        widget.status,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16, // Reduce tamaño en móviles
                        ),
                      ),
                      const SizedBox(width: 15),
                      CircleAvatar(
                        radius: 6,
                        backgroundColor: _obtenerColorStatus(widget.status),
                      ),
                    ],
                  ),
                ],
              )
                  : Row( // En pantallas grandes, mantiene la fila
                children: [
                  Text(
                    "Acción de tutela - ${widget.status}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(width: 14), // Espacio entre el texto y el círculo
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: _obtenerColorStatus(widget.status),
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
        _buildSolicitudTexto(),
        const SizedBox(height: 30),
        const Row(
          children: [
            Icon(Icons.attach_file),
            Text("Archivos adjuntos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 30),

        /// 📂 **Mostramos los archivos aquí**
        archivosAdjuntos.isNotEmpty
            ? ArchivoViewerWeb2(archivos: archivos)
            : const Text(
          "El usuario no compartió ningún archivo",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red),
        ),
        const SizedBox(height: 30),
        const Divider(color: gris),
        if (((widget.status == "Diligenciado" ||
            widget.status == "Revisado" ||
            widget.status == "Enviado") &&
            rol != "pasante 1") || (widget.status == "Solicitado" && rol == "pasante 1")
            || (rol == "master" || rol == "masterFull" || rol == "coordinador 1"
                || rol == "coordinador 2"))

          Column(
            children: [
              Text(
                "Espacio de diligenciamiento",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.width < 600 ? 20 : 28, // Reduce el tamaño en móviles
                ),
              ),
              const SizedBox(height: 30),
              ingresarHechos(),
              const SizedBox(height: 30),
              ingresarDerechosVulnerados(),
              const SizedBox(height: 30),
              ingresarNormasAplicables(),
              const SizedBox(height: 30),
              ingresarPretensiones(),
              const SizedBox(height: 30),
              ingresarPruebas(),
              const SizedBox(height: 30),
            ],
          ),

        if (((widget.status == "Diligenciado" ||
            widget.status == "Revisado" ||
            widget.status == "Enviado") &&
            rol != "pasante 1") || (widget.status == "Solicitado" && rol == "pasante 1")
            || (rol == "master" || rol == "masterFull" || rol == "coordinador 1"
                || rol == "coordinador 2"))

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              side: BorderSide(width: 1, color: Theme.of(context).primaryColor), // Borde con color primario
              backgroundColor: Colors.white, // Fondo blanco
              foregroundColor: Colors.black, // Letra en negro
            ),
            onPressed: () {
              setState(() {
                _guardarDatosEnVariables();
              });
            },
            child: const Text("Guardar información"),
          ),
        const SizedBox(height: 10),
        // ✅ Solo muestra la vista previa si _mostrarVistaPrevia es true
        if (_mostrarBotonVistaPrevia)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  side: BorderSide(width: 1, color: Theme.of(context).primaryColor), // Borde con color primario
                  backgroundColor: Colors.white, // Fondo blanco
                  foregroundColor: Colors.black, // Letra en negro
                ),
                onPressed: () {
                  setState(() {
                    // Actualizar las variables con los valores de los controladores
                    hechos = _hechosController.text.trim();
                    derechosVulnerados = _derechosVulneradosController.text.trim();
                    pretensiones = _pretensionesController.text.trim();
                    normasAplicables = _normasAplicablesController.text.trim();
                    pruebas = _pruebasController.text.trim();
                    _mostrarVistaPrevia = !_mostrarVistaPrevia;
                  });
                },
                child: const Text("Vista previa"),
              ),

              // 🔹 Agregar espaciado SOLO cuando _mostrarVistaPrevia es true
              if (_mostrarVistaPrevia) const SizedBox(height: 50),
            ],
          ),

        if (_mostrarVistaPrevia)
          vistaPreviaTutela(userData, hechos, derechosVulnerados, pretensiones, normasAplicables, pruebas, juramento),
      ],
    );
  }

  // Future<void> cargarCamposDesdeFirestore(String docId, String categoria, String subcategoria) async {
  //   final doc = await FirebaseFirestore.instance
  //       .collection('solicitudes_tutela')
  //       .doc(docId)
  //       .get();
  //
  //   final data = doc.data();
  //
  //   if (data == null) return;
  //
  //   final valoresGenerados = TextoFundamentacionTutelaHelper.obtenerFundamentacion(
  //     categoria: categoria,
  //     subcategoria: subcategoria,
  //   );
  //
  //   if (!_isDerechosVulneradosLoaded) {
  //     _derechosVulneradosController.text = data['derechos_vulnerados'] ?? valoresGenerados['derechos_vulnerados'] ?? '';
  //     _isDerechosVulneradosLoaded = true;
  //   }
  //
  //   if (!_isNomasAplicablesLoaded) {
  //     _normasAplicablesController.text = data['normas_aplicables'] ?? valoresGenerados['normas_aplicables'] ?? '';
  //     _isNomasAplicablesLoaded = true;
  //   }
  //
  //   if (!_isPretensionesLoaded) {
  //     _pretensionesController.text = data['pretensiones'] ?? valoresGenerados['pretensiones'] ?? '';
  //     _isPretensionesLoaded = true;
  //   }
  //
  //   if (!_isPruebasLoaded) {
  //     _pruebasController.text = data['pruebas'] ?? valoresGenerados['pruebas'] ?? '';
  //     _isPruebasLoaded = true;
  //   }
  //
  //   if (!_isJuramentoLoaded) {
  //     _juramentoController.text = data['juramento'] ?? valoresGenerados['juramento'] ?? '';
  //     _isJuramentoLoaded = true;
  //   }
  // }
  //
  //

  Widget _buildSolicitudTexto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: gris),
        const Text(
          "Comentarios hechos por el usuario",
          style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w900),
        ),

        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade200,
          ),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          child: widget.preguntas.isNotEmpty && widget.respuestas.isNotEmpty
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              widget.preguntas.length,
                  (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.preguntas[index],
                      style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      index < widget.respuestas.length ? widget.respuestas[index] : 'No hay respuesta',
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    ),
                    const Divider(), // Separador entre preguntas
                  ],
                ),
              ),
            ),
          )
              : const Text(
            "No hay preguntas ni respuestas registradas.",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Future<void> cargarCorreos() async {
    Map<String, String> correos = await obtenerCorreosCentro(userDoc);
    if (mounted) {
      setState(() {
        correosCentro = correos;
      });
    }
  }

  void _actualizarAltura() {
    int lineas = '\n'.allMatches(_hechosController.text).length + 1;
    setState(() {
// Limita el crecimiento a 5 líneas
    });
  }

  void _guardarDatosEnVariables() {
    if (_hechosController.text.isEmpty || _derechosVulneradosController.text.isEmpty
        || _pretensionesController.text.isEmpty || _normasAplicablesController.text.isEmpty
        || _pruebasController.text.isEmpty) {
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
      hechos = _hechosController.text;
      derechosVulnerados = _derechosVulneradosController.text;
      pretensiones = _pretensionesController.text;
      normasAplicables = _normasAplicablesController.text;
      pruebas = _pruebasController.text;
    });
    _mostrarBotonVistaPrevia = true;
  }

  @override
  void dispose() {
    _hechosController.removeListener(_actualizarAltura);
    _derechosVulneradosController.removeListener(_actualizarAltura);
    _pretensionesController.removeListener(_actualizarAltura);
    _normasAplicablesController.removeListener(_actualizarAltura);
    _pruebasController.removeListener(_actualizarAltura);
    _hechosController.dispose();
    _derechosVulneradosController.dispose();
    _pretensionesController.dispose();
    _normasAplicablesController.dispose();
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
          _hechosController.text.trim().isNotEmpty &&
              _derechosVulneradosController.text.trim().isNotEmpty &&
              _pretensionesController.text.trim().isNotEmpty &&
              _normasAplicablesController.text.trim().isNotEmpty &&
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
    bool estaEnReclusion = userData?.situacion?.toLowerCase() == "en reclusión";

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
          const SizedBox(height: 10),
          if (userData!.situacion == "En Prisión domiciliaria" ||
              userData!.situacion == "En libertad condicional")
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Lugar donde se esta cumpliendo el beneficio", style: TextStyle( fontSize: 12, color: Colors.black87)),
              Text('${userData?.direccion}, ${userData?.municipio ?? "Sin info"}, '
                  '${userData?.departamento}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
              ),
              const Divider(color: primary, height: 1,)
            ],
          ),
          const SizedBox(height: 10),
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
          // if (estaEnReclusion) ...[
          //   const Divider(color: primary),
          //   const SizedBox(height: 10),
          //   const Text('Centro Reclusión:', style: TextStyle(fontSize: 12, color: Colors.black)),
          //   Text(userData!.centroReclusion, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.1)),
          //   const SizedBox(height: 10),
          //   const Text('Correos:', style: TextStyle(fontSize: 12, color: Colors.black)),
          //   correoConBoton('Principal', correosCentro['correo_principal']),
          //   correoConBoton('Director', correosCentro['correo_direccion']),
          //   correoConBoton('Jurídica', correosCentro['correo_juridica']),
          //   correoConBoton('Sanidad', correosCentro['correo_sanidad']),
          // ],

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
          const SizedBox(height: 10),
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
              Text('${userData!.tiempoCondena} meses', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          // if(userData!.situacion == "En Reclusión")
          //   Column(
          //     children: [
          //       Row(
          //         children: [
          //           const Text('TD:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
          //           Text(userData!.td, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          //         ],
          //       ),
          //       Row(
          //         children: [
          //           const Text('NUI:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
          //           Text(userData!.nui, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          //         ],
          //       ),
          //       Row(
          //         children: [
          //           const Text('Patio:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
          //           Text(userData!.patio, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          //         ],
          //       ),
          //     ],
          //   ),
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
              const Text('Email:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.email, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 15),
          FutureBuilder<double>(
            future: calcularTotalRedenciones(widget.idUser),
            builder: (context, snapshot) {
              double totalRedimido = snapshot.data ?? 0.0;
              return _datosEjecucionCondena(totalRedimido);
            },
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              if(userData!.situacion == "En Reclusión")
                _buildBenefitCard(
                  title: 'Permiso Administrativo de 72 horas',
                  condition: porcentajeEjecutado >= 33.33,
                  remainingTime: ((33.33 - porcentajeEjecutado) / 100 * tiempoCondena * 30).ceil(),
                ),
              if(userData!.situacion == "En Reclusión")
                _buildBenefitCard(
                  title: 'Prisión Domiciliaria',
                  condition: porcentajeEjecutado >= 50,
                  remainingTime: ((50 - porcentajeEjecutado) / 100 * tiempoCondena * 30).ceil(),
                ),
              if(userData!.situacion == "En Reclusión" || userData!.situacion == "En Prisión domiciliaria")
                _buildBenefitCard(
                  title: 'Libertad Condicional',
                  condition: porcentajeEjecutado >= 60,
                  remainingTime: ((60 - porcentajeEjecutado) / 100 * tiempoCondena * 30).ceil(),
                ),
              _buildBenefitCard(
                title: 'Extinción de la Pena',
                condition: porcentajeEjecutado >= 100,
                remainingTime: ((100 - porcentajeEjecutado) / 100 * tiempoCondena * 30).ceil(),
              ),
            ],
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
    Ppl? fetchedData = await _pplProvider.getById(widget.idUser);

    if (fetchedData != null) {
      DocumentReference centroDoc = FirebaseFirestore.instance
          .collection('centros_reclusion')
          .doc(fetchedData.centroReclusion);

      Map<String, String> correos = await obtenerCorreosCentro(centroDoc);

      if (mounted) {
        setState(() {
          userData = fetchedData;

          if (correos.isNotEmpty && correos.values.any((correo) => correo != 'No disponible')) {
            correosCentro = correos;
          }

          if (widget.archivos.isEmpty &&
              _pruebasController.text.trim().isEmpty &&
              !_isPruebasLoaded) {
            _pruebasController.text = "No se adjuntan documentos en esta solicitud.";
            _isPruebasLoaded = true;
          }

          // 🔹 Inicializamos el derechoPeticion
          accionTutela = TutelaTemplate(
            dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
            entidad: userData?.centroReclusion ?? "",
            referencia: '${widget.categoria} - ${widget.subcategoria}',
            nombrePpl: userData?.nombrePpl?.trim() ?? "",
            apellidoPpl: userData?.apellidoPpl?.trim() ?? "",
            identificacionPpl: userData?.numeroDocumentoPpl ?? "",
            centroPenitenciario: userData?.centroReclusion ?? "",
            hechos: hechos,
            derechosVulnerados: derechosVulnerados,
            normasAplicables: normasAplicables,
            pruebas: pruebas,
            juramento: juramento.trim().isEmpty ? null : juramento,
            pretensiones: pretensiones,
            emailUsuario: userData?.email?.trim() ?? "",
            td: userData?.td?.trim() ?? "",
            nui: userData?.nui?.trim() ?? "",
            numeroSeguimiento: widget.numeroSeguimiento, // 👈 asegúrate que esta variable exista
          );
          isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          userData = fetchedData;
          isLoading = false;
        });
      }
    }
  }

  void fetchDocumentoTutela() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('tutelas_solicitados')
          .doc(widget.idDocumento)
          .get();

      if (documentSnapshot.exists) {
        Map<String, dynamic>? data = documentSnapshot.data() as Map<String, dynamic>?;

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
          });
        }
      } else {
        if (kDebugMode) {
          print("⚠️ Documento no encontrado en Firestore");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error al obtener datos de Firestore: $e");
      }
    }
  }

  //Para los tiempos de los beneficios
  Future<void> calcularTiempo(String id) async {
    final pplData = await _pplProvider.getById(id);
    if (pplData != null) {
      final fechaCaptura = pplData.fechaCaptura;
      tiempoCondena = pplData.tiempoCondena;
      final fechaActual = DateTime.now();
      final fechaFinCondena = fechaCaptura?.add(Duration(days: tiempoCondena * 30));

      final diferenciaRestante = fechaFinCondena?.difference(fechaActual);
      final diferenciaEjecutado = fechaActual.difference(fechaCaptura!);

      setState(() {
        mesesRestante = (diferenciaRestante!.inDays ~/ 30);
        diasRestanteExactos = diferenciaRestante.inDays % 30;

        mesesEjecutado = diferenciaEjecutado.inDays ~/ 30;
        diasEjecutadoExactos = diferenciaEjecutado.inDays % 30;
      });

      // Validaciones para beneficios
      porcentajeEjecutado = (diferenciaEjecutado.inDays / (tiempoCondena * 30)) * 100;
      print("Porcentaje de condena ejecutado: $porcentajeEjecutado%");

      if (porcentajeEjecutado >= 33.33) {
        print("Se aplica el beneficio de permiso administrativo de 72 horas");
      } else {
        print("No se aplica el beneficio de permiso administrativo de 72 horas");
      }

      if (porcentajeEjecutado >= 50) {
        print("Se aplica el beneficio de prisión domiciliaria");
      } else {
        print("No se aplica el beneficio de prisión domiciliaria");
      }

      if (porcentajeEjecutado >= 60) {
        print("Se aplica el beneficio de libertad condicional");
      } else {
        print("No se aplica el beneficio de libertad condicional");
      }

      if (porcentajeEjecutado >= 100) {
        print("Se aplica el beneficio de extinción de la pena");
      } else {
        print("No se aplica el beneficio de extinción de la pena");
      }

      print("Tiempo restante: $mesesRestante meses y $diasRestanteExactos días");
      print("Tiempo ejecutado: $mesesEjecutado meses y $diasEjecutadoExactos días");
    } else {
      if (kDebugMode) {
        print("No hay datos");
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

  Widget _buildBenefitCard({required String title, required bool condition, required int remainingTime}) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: condition ? Colors.green : Colors.red, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      elevation: 3,
      color: condition ? Colors.green : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              condition ? Icons.notifications : Icons.access_time, // Cambia a reloj si la tarjeta es roja
              color: condition ? Colors.white : Colors.black, // Negro si la tarjeta es roja
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: condition
                          ? 'Se ha completado el tiempo establecido para acceder al beneficio de '
                          : 'Aún no se puede acceder a ',
                      style: TextStyle(
                        fontSize: 12,
                        color: condition ? Colors.white : Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: title, // Texto en negrilla
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold, // Negrilla
                        color: condition ? Colors.white : Colors.black,
                      ),
                    ),
                    if (!condition) // Solo agregar este texto si la condición es falsa
                      TextSpan(
                        text: '. Faltan $remainingTime días para completar el tiempo establecido.',
                        style: TextStyle(
                          fontSize: 12,
                          color: condition ? Colors.white : Colors.black,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> generarTextoIAExtendido() async {
    try {
      final resultado = await IABackendService.generarTextoExtendidoDesdeCloudFunction(
        categoria: widget.categoria,
        subcategoria: widget.subcategoria,
        respuestasUsuario: widget.respuestas,
      );

      print("🔹 Hechos: ${resultado['hechos']}");
      print("🔹 Derechos vulnerados: ${resultado['derechos_vulnerados']}");
      print("🔹 Pretensiones: ${resultado['pretensiones']}");

      setState(() {
        _hechosController.text = resultado['hechos'] ?? '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Texto IA insertado en todos los campos")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  // corregido full
  Future<void> cargarHechos(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tutelas_solicitados')
          .doc(docId)
          .get();

      if (doc.exists && !_isHechosLoaded) {
        final data = doc.data() as Map<String, dynamic>?;

        final texto = data?['hechos'];
        if (texto != null && texto is String) {
          setState(() {
            _hechosController.text = texto;
            _isHechosLoaded = true;
          });

          verificarVistaPrevia();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error cargando hechos: $e");
      }
    }
  }
  //corregido full
  Future<void> cargarDerechosVulnerados(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tutelas_solicitados')
          .doc(docId)
          .get();

      if (doc.exists && !_isDerechosVulneradosLoaded) {
        final data = doc.data() as Map<String, dynamic>?;

        final texto = data?['derechos_vulnerados'];

        setState(() {
          _derechosVulneradosController.text =
          (texto != null && texto is String && texto.trim().isNotEmpty)
              ? texto
              : TextoDerechosVulneradosHelper.obtenerTexto(
            categoria: widget.categoria,
            subcategoria: widget.subcategoria,
          );

          _isDerechosVulneradosLoaded = true;
        });

        verificarVistaPrevia();
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error cargando derechos vulnerados: $e");
      }
    }
  }



  Future<void> cargarNormasAplicables(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tutelas_solicitados')
          .doc(docId)
          .get();

      if (doc.exists && !_isNomasAplicablesLoaded) {
        final data = doc.data() as Map<String, dynamic>?;

        final texto = data?['normas_aplicables'];

        final textoGenerado = TextoFundamentacionTutelaHelper.obtenerFundamentacion(
          categoria: widget.categoria,
          subcategoria: widget.subcategoria,
        )['normas_aplicables'] ?? '';

        setState(() {
          _normasAplicablesController.text =
          (texto != null && texto is String && texto.trim().isNotEmpty)
              ? texto
              : textoGenerado;

          _isNomasAplicablesLoaded = true;
        });

        verificarVistaPrevia();
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error cargando normas aplicables: $e");
      }
    }
  }

  Future<void> cargarPretensiones(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tutelas_solicitados')
          .doc(docId)
          .get();

      if (doc.exists && !_isPretensionesLoaded) {
        final data = doc.data() as Map<String, dynamic>?;

        final texto = data?['pretensiones'];

        final textoGenerado = TextoFundamentacionTutelaHelper.obtenerFundamentacion(
          categoria: widget.categoria,
          subcategoria: widget.subcategoria,
        )['pretensiones'] ?? '';

        setState(() {
          _pretensionesController.text =
          (texto != null && texto is String && texto.trim().isNotEmpty)
              ? texto
              : textoGenerado;

          _isPretensionesLoaded = true;
        });

        verificarVistaPrevia();
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error cargando pretensiones: $e");
      }
    }
  }

  Future<void> cargarPruebas(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tutelas_solicitados')
          .doc(docId)
          .get();

      if (doc.exists && !_isPruebasLoaded) {
        final data = doc.data() as Map<String, dynamic>?;

        final texto = data?['pruebas'];

        setState(() {
          _pruebasController.text = (texto != null && texto is String && texto.trim().isNotEmpty)
              ? texto
              : "No se adjuntan documentos en esta solicitud."; // <-- Aquí el valor por defecto
          _isPruebasLoaded = true;
        });

        verificarVistaPrevia();
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error cargando pruebas: $e");
      }
    }
  }



  // corregido full - autollenado por IA o se puede escribir igualmente
  Widget ingresarHechos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IASuggestionHechosTutela(
          categoria: widget.categoria,
          subcategoria: widget.subcategoria,
          respuestasUsuario: widget.respuestas,
          hechosController: _hechosController,
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _hechosController,
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
  Widget ingresarDerechosVulnerados() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Derechos vulnerados",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _derechosVulneradosController,
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
  Widget ingresarPretensiones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pretensiones",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _pretensionesController,
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

  Widget ingresarNormasAplicables() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Normas aplicables",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _normasAplicablesController,
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
          "Pruebas",
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

  Widget vistaPreviaTutela(userData, String hechos, String derechosVulnerados, String pretensiones, String normasAplicables,
      String pruebas, String juramento) {
    var tutela = TutelaTemplate(
        dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
        entidad: entidad,
        referencia: '${widget.categoria} - ${widget.subcategoria}',
        nombrePpl: userData?.nombrePpl?.trim() ?? "",
        apellidoPpl: userData?.apellidoPpl?.trim() ?? "",
        identificacionPpl: userData?.numeroDocumentoPpl ?? "",
        centroPenitenciario: userData?.centroReclusion ?? "",
        hechos: hechos,
        derechosVulnerados: derechosVulnerados,
        pretensiones: pretensiones,
        normasAplicables: normasAplicables,
        pruebas: archivos.isEmpty && pruebas.trim().isEmpty
          ? "No se adjuntan documentos en esta solicitud."
          : pruebas,
      juramento: juramento.trim().isEmpty ? null : juramento,
        emailUsuario: userData?.email?.trim() ?? "",
        td: userData?.td?.trim() ?? "",
        nui: userData?.nui?.trim() ?? "",
        numeroSeguimiento: widget.numeroSeguimiento,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vista previa de la accion de tutela",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Html(
            data: tutela.generarTextoHtml(),
          ),
        ),
        const SizedBox(height: 50),
        Wrap(
          children: [
            if (widget.status == "Solicitado") ...[
              guardarVistaPrevia(widget.idDocumento),
            ],
            if ((widget.status == "Diligenciado" || widget.status == "Revisado") && rol != "pasante 1") ...[
              guardarRevisado(widget.idDocumento),
              const SizedBox(width: 20), // Espaciado entre botones
              botonEnviarCorreo(),
            ],
          ],
        ),
        const SizedBox(height: 150),
      ],
    );
  }

  Future<void> enviarCorreoResend() async {
    final url = Uri.parse("https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/sendEmailWithResend");

    var accionTutela = TutelaTemplate(
        dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
        entidad: userData?.centroReclusion ?? "",
        referencia: '${widget.categoria} - ${widget.subcategoria}',
        nombrePpl: userData?.nombrePpl.trim() ?? "",
        apellidoPpl: userData?.apellidoPpl.trim() ?? "",
        identificacionPpl: userData?.numeroDocumentoPpl ?? "",
        centroPenitenciario: userData?.centroReclusion ?? "",
        hechos: hechos,
        derechosVulnerados: derechosVulnerados,
        pretensiones: pretensiones,
        normasAplicables: normasAplicables,
        pruebas: widget.archivos.isEmpty && pruebas.trim().isEmpty
          ? "No se adjuntan documentos en esta solicitud."
          : pruebas,
        juramento: juramento.trim().isEmpty ? null : juramento,
        emailUsuario: userData?.email.trim() ?? "",
        nui: userData?.nui.trim() ?? "",
        td: userData?.td.trim() ?? "",
        numeroSeguimiento: widget.numeroSeguimiento,
    );

    String mensajeHtml = accionTutela.generarTextoHtml();

    List<Map<String, String>> archivosBase64 = [];
    for (String archivoUrl in widget.archivos) {
      try {
        String nombreArchivo = obtenerNombreArchivo(archivoUrl);
        final response = await http.get(Uri.parse(archivoUrl));
        if (response.statusCode == 200) {
          String base64String = base64Encode(response.bodyBytes);
          archivosBase64.add({"nombre": nombreArchivo, "base64": base64String});
        } else {
          if (kDebugMode) {
            print("❌ No se pudo descargar el archivo: $nombreArchivo (Error ${response.statusCode})");
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print("❌ Error al procesar archivo: $e");
        }
      }
    }

    String asuntoCorreo = "Acción de tutela - ${widget.numeroSeguimiento}";
    final currentUser = FirebaseAuth.instance.currentUser;
    final enviadoPor = currentUser?.email ?? adminFullName;

    List<String> correosCC = [];
    if (userData?.email != null && userData!.email.trim().isNotEmpty) {
      correosCC.add(userData!.email.trim());
    }

    final body = jsonEncode({
      "to": correoSeleccionado,
      "cc": correosCC,
      "subject": asuntoCorreo,
      "html": mensajeHtml,
      "archivos": archivosBase64,
      "idDocumento": widget.idDocumento,
      "enviadoPor": enviadoPor,
      "tipo": "tutelas",
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      await FirebaseFirestore.instance
          .collection('tutelas_solicitados')
          .doc(widget.idDocumento)
          .update({
        "status": "Enviado",
        "fechaEnvio": FieldValue.serverTimestamp(),
        "envió": adminFullName,
      });
    } else {
      if (kDebugMode) {
        print("❌ Error al enviar el correo con Mailersend: ${response.body}");
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
        if (correoSeleccionado!.isEmpty) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: blanco,
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

        final confirmacion = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: blanco,
            title: const Text("Confirmación"),
            content: Text("Se enviará el correo a:\n$correoSeleccionado"),
            actions: [
              TextButton(
                child: const Text("Cancelar"),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text("Enviar"),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );

        if (confirmacion ?? false) {
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const AlertDialog(
                backgroundColor: blanco,
                title: Text("Enviando correo..."),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Espere mientras se envía el correo."),
                    SizedBox(height: 20),
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            );
          }

          await enviarCorreoResend();

          final html = accionTutela.generarTextoHtml();
          await subirHtmlCorreoADocumento(
            idDocumento: widget.idDocumento,
            htmlContent: html,
          );

          const urlApp = "https://www.tuprocesoya.com";
          final numeroSeguimiento = widget.numeroSeguimiento;

          if (context.mounted) {
            Navigator.of(context).pop(); // Cierra "enviando..."

            final enviar = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: blanco,
                title: const Text("¿Enviar Notificación?"),
                content: const Text("¿Deseas notificar al usuario del envío por WhatsApp?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("No"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("Sí, enviar"),
                  ),
                ],
              ),
            );

            if (enviar == true) {
              final celular = "+57${userData!.celular}";
              final mensaje = Uri.encodeComponent(
                  "Hola *${userData!.nombreAcudiente}*,\n\n"
                      "Hemos enviado tu acción de tutela número *$numeroSeguimiento* a la autoridad correspondiente.\n\n"
                      "Recuerda que la autoridad tiene un plazo de hasta 10 días para dar respuesta. Te estaremos informando sobre cualquier novedad.\n\n"
                      "Puedes consultar el correo enviado en la aplicación desde el menú: Historiales > Tutelas:\n$urlApp\n\n"
                      "Gracias por confiar en nosotros.\n\nCordialmente,\n\n*El equipo de Tu Proceso Ya.*"
              );
              final link = "https://wa.me/$celular?text=$mensaje";
              await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
            }
            if(context.mounted){
              Navigator.pushReplacementNamed(context, 'historial_solicitudes_tutelas_admin');
            }
          }
        }
      },
      child: const Text("Enviar por correo"),
    );
  }


  Future<void> subirHtmlCorreoADocumento({
    required String idDocumento,
    required String htmlContent,
  }) async {
    try {
      // 🛠 Asegurar UTF-8 para que se vean bien las tildes y ñ
      final contenidoFinal = htmlUtf8Compatible(htmlContent);

      // 📁 Crear bytes
      final bytes = utf8.encode(contenidoFinal);
      const fileName = "correo.html";
      final filePath = "tutelas/$idDocumento/correos/$fileName";

      final ref = FirebaseStorage.instance.ref(filePath);
      final metadata = SettableMetadata(contentType: "text/html");

      // ⬆️ Subir archivo
      await ref.putData(Uint8List.fromList(bytes), metadata);

      // 🌐 Obtener URL
      final downloadUrl = await ref.getDownloadURL();

      // 🗃️ Guardar en Firestore
      await FirebaseFirestore.instance
          .collection("tutelas_solicitados")
          .doc(idDocumento)
          .update({
        "correoHtmlUrl": downloadUrl,
        "fechaHtmlCorreo": FieldValue.serverTimestamp(),
      });

      print("✅ HTML subido y guardado con URL: $downloadUrl");
    } catch (e) {
      print("❌ Error al subir HTML del correo: $e");
    }
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

  Future<Map<String, String>> obtenerCorreosCentro(DocumentReference userDoc) async {
    try {
      DocumentSnapshot correoDoc = await userDoc.collection('correos_centro_reclusion').doc('emails').get();

      if (correoDoc.exists && correoDoc.data() != null) {
        var data = correoDoc.data() as Map<String, dynamic>;

        Map<String, String> correos = {
          'correo_direccion': data['correo_direccion'] ?? 'No disponible',
          'correo_juridica': data['correo_juridica'] ?? 'No disponible',
          'correo_principal': data['correo_principal'] ?? 'No disponible',
          'correo_sanidad': data['correo_sanidad'] ?? 'No disponible',
        };

        // Obtener y mostrar los nombres de las claves
        List<String> nombresCorreos = correos.keys.toList();
        return correos;
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error obteniendo correos: $e");
      }
    }

    return {
      'correo_direccion': 'No disponible',
      'correo_juridica': 'No disponible',
      'correo_principal': 'No disponible',
      'correo_sanidad': 'No disponible',
    };
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
        side: BorderSide(width: 1, color: Theme.of(context).primaryColor), // Borde con color primario
        backgroundColor: Colors.white, // Fondo blanco
        foregroundColor: Colors.black, // Letra en negro
      ),
      onPressed: () async {
        adminFullName = AdminProvider().adminFullName ?? ""; // Nombre completo
        if (adminFullName.isEmpty) {
          if (kDebugMode) {
            print("❌ No se pudo obtener el nombre del administrador.");
          }
          return;
        }

        try {
          await FirebaseFirestore.instance
              .collection('tutelas_solicitados')
              .doc(idDocumento)
              .update({
            "status": "Diligenciado",
            "diligencio": adminFullName, // Guarda el nombre del admin
            "fecha_diligenciamiento": FieldValue.serverTimestamp(),
            "hechos": _hechosController.text,
            "derechos_vulnerados": _derechosVulneradosController.text,
            "pretensiones": _pretensionesController.text,
            "normas_aplicables": _normasAplicablesController.text,
            "pruebas": _pruebasController.text,
          });
          if(context.mounted){
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Solicitud marcada como diligenciada"))
            );

          }
        } catch (e) {
          if (kDebugMode) {
            print("❌ Error al actualizar la solicitud: $e");
          }
          if(context.mounted){
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Error al actualizar la solicitud"))
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
        side: BorderSide(width: 1, color: Theme.of(context).primaryColor), // Borde con color primario
        backgroundColor: Colors.white, // Fondo blanco
        foregroundColor: Colors.black, // Letra en negro
      ),
      onPressed: () async {
        String adminFullName = AdminProvider().adminFullName ?? ""; // Nombre completo
        if (adminFullName.isEmpty) {
          if (kDebugMode) {
            print("❌ No se pudo obtener el nombre del administrador.");
          }
          return;
        }

        try {
          await FirebaseFirestore.instance
              .collection('tutelas_solicitados')
              .doc(idDocumento)
              .update({
            "status": "Revisado",
            "reviso": adminFullName, // Guarda el nombre del admin
            "fecha_revision": FieldValue.serverTimestamp(),
            "hechos": _hechosController.text,
            "derechos_vulnerados": _derechosVulneradosController.text,
            "pretensiones": _pretensionesController.text,
            "normas_aplicables": _normasAplicablesController.text,
            "pruebas": _pruebasController.text,
          });
          if(context.mounted){
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Solicitud guardada como 'Revisado'"))
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print("❌ Error al actualizar la solicitud: $e");
          }
          if(context.mounted){
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Error al actualizar la solicitud"))
            );
          }
        }
      },
      child: const Text("Marcar como Revisado"),
    );
  }

}
