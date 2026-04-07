
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:tuprocesoya/Pages/administrador/atender_derecho_peticion_admin/atender_derecho_peticionAdmin_controler.dart';
import 'package:tuprocesoya/providers/ppl_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../commons/admin_provider.dart';
import '../../../commons/archivoViewerWeb.dart';
import '../../../commons/ia_backend_service/IASuggestionCard.dart';
import '../../../commons/ia_backend_service/ia_backend_service.dart';
import '../../../commons/main_layaout.dart';
import '../../../helper/resumen_solicitudes_helper.dart';
import '../../../models/ppl.dart';
import '../../../plantillas/plantilla_derecho_peticion.dart';
import '../../../services/whatsapp_service.dart';
import '../../../src/colors/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../widgets/calculo_beneficios_penitenciarios-general.dart';
import '../../../widgets/datos_ejecucion_condena.dart';
import '../../../widgets/selector_correo_manual.dart';

class AtenderDerechoPeticionPage extends StatefulWidget {
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

  const AtenderDerechoPeticionPage({
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
  State<AtenderDerechoPeticionPage> createState() => _AtenderDerechoPeticionPageState();
}


class _AtenderDerechoPeticionPageState extends State<AtenderDerechoPeticionPage> {
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
  final TextEditingController _consideracionesController = TextEditingController();
  final TextEditingController _fundamentosDerechoController = TextEditingController();
  final TextEditingController _peticionConcretaController = TextEditingController();
  final AtenderDerechoPeticionAdminController _controller = AtenderDerechoPeticionAdminController();
  String consideraciones = "";
  String fundamentosDeDerecho = "";
  String peticionConcreta = "";
  bool _mostrarVistaPrevia = false;
  bool _mostrarBotonVistaPrevia = false;
  Map<String, String> correosCentro = {};
  late DocumentReference userDoc;
  String? correoSeleccionado= ""; // Guarda el correo seleccionado
  String? nombreCorreoSeleccionado;
  String idDocumento="";
  bool _isConsideracionesLoaded = false; // Bandera para evitar sobrescribir
  bool _isFundamentosLoaded = false; // Bandera para evitar sobrescribir
  bool _isPeticionConcretaLoaded = false; // Bandera para evitar sobrescribir
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
  late DerechoPeticionTemplate derechoPeticion;
  String asignadoA_P2 = '';
  String asignadoNombreP2 = '';
  DateTime? fechaAsignadoP2;
  String? textoGeneradoIA; // A nivel de clase (State)
  bool mostrarCardIA = false;

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
    fetchDocumentoDerechoPeticion();
    calcularTiempo(widget.idUser);
    _consideracionesController.addListener(_actualizarAltura);
    _fundamentosDerechoController.addListener(_actualizarAltura);
    _peticionConcretaController.addListener(_actualizarAltura);
    DocumentReference userDoc = FirebaseFirestore.instance.collection('Ppl').doc(widget.idUser);
    obtenerCorreosCentro(userDoc).then((correos) {
      setState(() {
        correosCentro = correos;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cargarConsideraciones(widget.idDocumento);
      cargarFundamentosDeDerecho(widget.idDocumento);
      cargarPeticionConcreta(widget.idDocumento);
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
      pageTitle: 'Atender derecho de petición',
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
                      "Derecho de petición ",
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
                      "Derecho de petición - ${widget.status}",
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
              ? ArchivoViewerWeb(archivos: archivos)
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
              ingresarConsideraciones(),
              const SizedBox(height: 30),
              ingresarFundamentosDeDerecho(),
              const SizedBox(height: 30),
              ingresarPeticionConcreta(),
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
                      consideraciones = _consideracionesController.text.trim();
                      fundamentosDeDerecho = _fundamentosDerechoController.text.trim();
                      peticionConcreta = _peticionConcretaController.text.trim();
                      _mostrarVistaPrevia = !_mostrarVistaPrevia; // Alterna visibilidad
                    });
                  },
                  child: const Text("Vista previa"),
                ),

                // 🔹 Agregar espaciado SOLO cuando _mostrarVistaPrevia es true
                if (_mostrarVistaPrevia) const SizedBox(height: 50),
              ],
            ),

          if (_mostrarVistaPrevia)
            vistaPreviaDerechoPeticion(userData, consideraciones, fundamentosDeDerecho, peticionConcreta),
        ],
    );
  }

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
    int lineas = '\n'.allMatches(_consideracionesController.text).length + 1;
    setState(() {
// Limita el crecimiento a 5 líneas
    });
  }

  void _guardarDatosEnVariables() {
    if (_consideracionesController.text.isEmpty || _fundamentosDerechoController.text.isEmpty
        || _peticionConcretaController.text.isEmpty) {
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
      consideraciones = _consideracionesController.text;
      fundamentosDeDerecho = _fundamentosDerechoController.text;
      peticionConcreta = _peticionConcretaController.text;
    });
    _mostrarBotonVistaPrevia = true;
  }

  @override
  void dispose() {
    _consideracionesController.removeListener(_actualizarAltura);
    _fundamentosDerechoController.removeListener(_actualizarAltura);
    _consideracionesController.dispose();
    _fundamentosDerechoController.dispose();
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
          _consideracionesController.text.trim().isNotEmpty &&
              _fundamentosDerechoController.text.trim().isNotEmpty &&
              _peticionConcretaController.text.trim().isNotEmpty;
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

          const Divider(color: primary, height: 1),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Juzgado Que Condenó:', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.juzgadoQueCondeno, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.1)),
            ],
          ),

          const Divider(color: primary, height: 1),
          const SizedBox(height: 60),
          _selectorDestinoCorreo(),
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

  void fetchUserData() async {
    Ppl? fetchedData = await _pplProvider.getById(widget.idUser);

    if (fetchedData != null) {
      Map<String, String> correos = {};

      // 🔹 Solo obtenemos correos si está en reclusión
      if (fetchedData.situacion?.trim() == 'En Reclusión') {
        DocumentReference centroDoc = FirebaseFirestore.instance
            .collection('centros_reclusion')
            .doc(fetchedData.centroReclusion);

        correos = await obtenerCorreosCentro(centroDoc);
      }

      if (mounted) {
        setState(() {
          userData = fetchedData;

          if (correos.isNotEmpty && correos.values.any((correo) => correo != 'No disponible')) {
            correosCentro = correos;
          }

          derechoPeticion = DerechoPeticionTemplate(
            dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
            entidad: userData?.centroReclusion ?? "",
            referencia: '${widget.categoria} - ${widget.subcategoria}',
            nombrePpl: userData?.nombrePpl?.trim() ?? "",
            apellidoPpl: userData?.apellidoPpl?.trim() ?? "",
            identificacionPpl: userData?.numeroDocumentoPpl ?? "",
            centroPenitenciario: userData?.centroReclusion ?? "",
            consideraciones: consideraciones,
            fundamentosDeDerecho: fundamentosDeDerecho,
            peticionConcreta: peticionConcreta,
            emailUsuario: userData?.email?.trim() ?? "",
            td: userData?.td?.trim() ?? "",
            nui: userData?.nui?.trim() ?? "",
            patio: userData?.patio?.trim() ?? "",
            numeroSeguimiento: widget.numeroSeguimiento,
            nombreAcudiente: '${userData!.nombreAcudiente} ${userData!.apellidoAcudiente}'

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


  void fetchDocumentoDerechoPeticion() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('derechos_peticion_solicitados')
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

      print("🔹 Consideraciones: ${resultado['consideraciones']}");
      print("🔹 Fundamentos: ${resultado['fundamentos']}");
      print("🔹 Petición: ${resultado['peticion']}");

      setState(() {
        _consideracionesController.text = resultado['consideraciones'] ?? '';
        _fundamentosDerechoController.text = resultado['fundamentos'] ?? '';
        _peticionConcretaController.text = resultado['peticion'] ?? '';
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
  Future<void> cargarConsideraciones(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('derechos_peticion_solicitados')
          .doc(docId)
          .get();

      if (doc.exists && !_isConsideracionesLoaded) {
        final data = doc.data() as Map<String, dynamic>?;

        final texto = data?['consideraciones'];
        if (texto != null && texto is String) {
          setState(() {
            _consideracionesController.text = texto;
            _isConsideracionesLoaded = true;
          });

          verificarVistaPrevia();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error cargando consideraciones: $e");
      }
    }
  }
  //corregido full
  Future<void> cargarFundamentosDeDerecho(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('derechos_peticion_solicitados')
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
  //corregido full
  Future<void> cargarPeticionConcreta(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('derechos_peticion_solicitados')
          .doc(docId)
          .get();

      if (doc.exists && !_isPeticionConcretaLoaded) {
        final data = doc.data() as Map<String, dynamic>?;

        final texto = data?['peticion_concreta'];
        if (texto != null && texto is String) {
          setState(() {
            _peticionConcretaController.text = texto;
            _isPeticionConcretaLoaded = true;
          });

          verificarVistaPrevia();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error cargando petición concreta: $e");
      }
    }
  }

  // corregido full - autollenado por IA o se puede escribir igualmente
  Widget ingresarConsideraciones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IASuggestionCard(
          categoria: widget.categoria,
          subcategoria: widget.subcategoria,
          respuestasUsuario: widget.respuestas,
          consideracionesController: _consideracionesController,
          fundamentosController: _fundamentosDerechoController,
          peticionController: _peticionConcretaController,
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _consideracionesController,
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
  Widget ingresarFundamentosDeDerecho() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Fundamentos de derecho",
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
  Widget ingresarPeticionConcreta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Petición concreta",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _peticionConcretaController,
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

  Widget vistaPreviaDerechoPeticion(userData, String consideraciones, String fundamentosDeDerecho, String peticionConcreta) {
    var derechoPeticion = DerechoPeticionTemplate(
      dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
      entidad: entidad,
      referencia: '${widget.categoria} - ${widget.subcategoria}',
      nombrePpl: userData?.nombrePpl?.trim() ?? "",
      apellidoPpl: userData?.apellidoPpl?.trim() ?? "",
      identificacionPpl: userData?.numeroDocumentoPpl ?? "",
      centroPenitenciario: userData?.centroReclusion ?? "",
      consideraciones: consideraciones,
      fundamentosDeDerecho: fundamentosDeDerecho,
      peticionConcreta: peticionConcreta,
      emailUsuario: userData?.email?.trim() ?? "",
      td: userData?.td?.trim() ?? "",
      nui: userData?.nui?.trim() ?? "",
      patio: userData?.patio?.trim() ?? "",
      numeroSeguimiento: widget.numeroSeguimiento,
      nombreAcudiente: '${userData!.nombreAcudiente} ${userData!.apellidoAcudiente}'
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vista previa del derecho de petición",
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
            data: derechoPeticion.generarTextoHtml(),
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

    var derechoPeticion = DerechoPeticionTemplate(
        dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
        entidad: userData?.centroReclusion ?? "",
        referencia: '${widget.categoria} - ${widget.subcategoria}',
        nombrePpl: userData?.nombrePpl.trim() ?? "",
        apellidoPpl: userData?.apellidoPpl.trim() ?? "",
        identificacionPpl: userData?.numeroDocumentoPpl ?? "",
        centroPenitenciario: userData?.centroReclusion ?? "",
        consideraciones: consideraciones,
        fundamentosDeDerecho: fundamentosDeDerecho,
        peticionConcreta: peticionConcreta,
        emailUsuario: userData?.email.trim() ?? "",
        nui: userData?.nui.trim() ?? "",
        patio: userData?.patio?.trim() ?? "",
        td: userData?.td.trim() ?? "",
        numeroSeguimiento: widget.numeroSeguimiento,
        nombreAcudiente: '${userData!.nombreAcudiente} ${userData!.apellidoAcudiente}'
    );

    String mensajeHtml = derechoPeticion.generarTextoHtml();

    List<Map<String, String>> archivosBase64 = [];
    for (String archivoUrl in widget.archivos) {
      try {
        String nombreArchivo = obtenerNombreArchivo(archivoUrl);
        final response = await http.get(Uri.parse(archivoUrl));
        if (response.statusCode == 200) {
          String base64String = base64Encode(response.bodyBytes);
          archivosBase64.add({
            "nombre": nombreArchivo,
            "base64": base64String,
            "tipo": lookupMimeType(nombreArchivo) ?? "application/octet-stream",
          });
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

    String asuntoCorreo = "Derecho de Petición - ${widget.numeroSeguimiento}";
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
      "tipo": "derechos_peticion",
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      await FirebaseFirestore.instance
          .collection('derechos_peticion_solicitados')
          .doc(widget.idDocumento)
          .update({
        "status": "Enviado",
        "fechaEnvio": FieldValue.serverTimestamp(),
        "envió": adminFullName,
      });

      await ResumenSolicitudesHelper.actualizarResumen(
        idOriginal: widget.idDocumento,
        nuevoStatus: "Enviado",
        origen: "derechos_peticion_solicitados",
      );


    } else {
      if (kDebugMode) {
        print("❌ Error al enviar el correo con Resend: ${response.body}");
      }
    }
  }
  //***

  List<OpcionCorreo> _buildOpcionesCorreo() {
    final opciones = <OpcionCorreo>[];

    // ✅ JEP
    if ((userData?.juzgadoEjecucionPenasEmail ?? "").trim().isNotEmpty) {
      opciones.add(OpcionCorreo(
        nombre: "Correo JEP",
        correo: userData!.juzgadoEjecucionPenasEmail.trim(),
        entidad: userData?.juzgadoEjecucionPenas ?? "",
      ));
    }

    // ✅ JDC
    if ((userData?.juzgadoQueCondenoEmail ?? "").trim().isNotEmpty) {
      opciones.add(OpcionCorreo(
        nombre: "Correo JDC",
        correo: userData!.juzgadoQueCondenoEmail.trim(),
        entidad: userData?.juzgadoQueCondeno ?? "",
      ));
    }

    // ✅ Centro de reclusión (si tienes correos cargados)
    final centro = (userData?.centroReclusion ?? "").trim();

    // Tus keys: correo_direccion, correo_juridica, correo_principal, correo_sanidad
    final dir = (correosCentro['correo_direccion'] ?? '').trim();
    final jur = (correosCentro['correo_juridica'] ?? '').trim();
    final pri = (correosCentro['correo_principal'] ?? '').trim();
    final san = (correosCentro['correo_sanidad'] ?? '').trim();

    // Solo agrega si son reales
    if (dir.isNotEmpty && dir != "No disponible") {
      opciones.add(OpcionCorreo(nombre: "Director", correo: dir, entidad: centro));
    }
    if (jur.isNotEmpty && jur != "No disponible") {
      opciones.add(OpcionCorreo(nombre: "Jurídica", correo: jur, entidad: centro));
    }
    if (pri.isNotEmpty && pri != "No disponible") {
      opciones.add(OpcionCorreo(nombre: "Principal", correo: pri, entidad: centro));
    }
    if (san.isNotEmpty && san != "No disponible") {
      opciones.add(OpcionCorreo(nombre: "Sanidad", correo: san, entidad: centro));
    }

    return opciones;
  }

  Widget _selectorDestinoCorreo() {
    if (userData == null) return const SizedBox();

    final opciones = _buildOpcionesCorreo();

    if (opciones.isEmpty) {
      return const Text(
        "No hay correos disponibles para seleccionar.",
        style: TextStyle(color: Colors.red),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Seleccionar entidad y correo destino",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ...opciones.map((op) {
              final isSelected = nombreCorreoSeleccionado == op.nombre;

              return RadioListTile<String>(
                dense: true,
                value: op.nombre,
                groupValue: nombreCorreoSeleccionado,
                title: Text(op.nombre, style: const TextStyle(fontSize: 13)),
                subtitle: Text(
                  "${op.entidad}\n${op.correo}",
                  style: const TextStyle(fontSize: 12),
                ),
                onChanged: (_) {
                  setState(() {
                    nombreCorreoSeleccionado = op.nombre;
                    correoSeleccionado = op.correo;
                    entidad = op.entidad;
                  });
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }




  Widget botonEnviarCorreo() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        side: BorderSide(width: 1, color: Theme.of(context).primaryColor),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      onPressed: () async {
        if (correoSeleccionado?.isEmpty ?? true) {
          if (!context.mounted) return;
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

        if (confirmacion != true || !context.mounted) return;

        BuildContext? loaderCtx;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            loaderCtx = ctx;
            return const AlertDialog(
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
            );
          },
        );

        final html = derechoPeticion.generarTextoHtml();

        try {
          await enviarCorreoResend();
          await subirHtmlCorreoADocumento(
            idDocumento: widget.idDocumento,
            htmlContent: html,
          );
        } catch (e) {
          if (context.mounted) {
            Navigator.of(loaderCtx!).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error al enviar: $e"), backgroundColor: Colors.red),
            );
          }
          return;
        }

        if (!context.mounted) return;
        Navigator.of(loaderCtx!).pop();

        // Confirmar envío de WhatsApp
        final notificarWhatsapp = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: blanco,
            title: const Text("¿Enviar Notificación?"),
            content: const Text("¿Deseas notificar al usuario del envío por WhatsApp?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text("Sí, enviar"),
              ),
            ],
          ),
        );

        if (notificarWhatsapp == true && userData?.celularWhatsapp?.isNotEmpty == true) {
          BuildContext? whatsappCtx;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              whatsappCtx = ctx;
              return const AlertDialog(
                backgroundColor: blanco,
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

          try {
            print("🟣🟣🟣🟣🟣🟣 ID a enviar por WhatsApp: ${widget.idDocumento}");

            // 🟡 Leer el documento de derecho de petición y obtener idUser
            final docSolicitud = await FirebaseFirestore.instance
                .collection("derechos_peticion_solicitados")
                .doc(widget.idDocumento)
                .get();

            final idUser = docSolicitud.data()?["idUser"];
            if (idUser == null) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Error: idUser no encontrado en la solicitud")),
                );
              }
              return;
            }

// 🔵 Leer el usuario desde Ppl
            final docUsuario = await FirebaseFirestore.instance
                .collection("Ppl")
                .doc(idUser)
                .get();

            if (!docUsuario.exists) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Error: usuario no encontrado en Ppl")),
                );
              }
              return;
            }

            final celular = docUsuario.data()?["celularWhatsapp"];
            final nombreAcudiente = docUsuario.data()?["nombre_acudiente"];

            if (celular == null || celular.isEmpty) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Error: número de WhatsApp no registrado")),
                );
              }
              return;
            }

// 🔹 Enviar notificación con el idUser (este sí existe en Ppl)
            await WhatsappService.enviarNotificacion(
              numero: "+57$celular",
              docId: idUser,
              servicio: "Derecho de petición",
              seguimiento: widget.numeroSeguimiento,
            );


            if (context.mounted) {
              Navigator.of(whatsappCtx!).pop();

              await showDialog(
                barrierDismissible: false,
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: blanco,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Row(
                    children: [
                      Image.asset("assets/images/icono_whatsapp.png", height: 28),
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
                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed('historial_solicitudes_derecho_peticion_admin');
                        }
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
            if (context.mounted) {
              Navigator.of(whatsappCtx!).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error al enviar WhatsApp: $e"), backgroundColor: Colors.red),
              );
              return;
            }
          }
        } else {
          if (context.mounted) {
            Navigator.of(context).pushReplacementNamed('historial_solicitudes_derecho_peticion_admin');
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
      final filePath = "derechos_peticion/$idDocumento/correos/$fileName";

      final ref = FirebaseStorage.instance.ref(filePath);
      final metadata = SettableMetadata(contentType: "text/html");

      // ⬆️ Subir archivo
      await ref.putData(Uint8List.fromList(bytes), metadata);

      // 🌐 Obtener URL
      final downloadUrl = await ref.getDownloadURL();

      // 🗃️ Guardar en Firestore
      await FirebaseFirestore.instance
          .collection("derechos_peticion_solicitados")
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
              .collection('derechos_peticion_solicitados')
              .doc(idDocumento)
              .update({
            "status": "Diligenciado",
            "diligencio": adminFullName, // Guarda el nombre del admin
            "fecha_diligenciamiento": FieldValue.serverTimestamp(),
            "consideraciones": _consideracionesController.text,
            "fundamentos_de_derecho": _fundamentosDerechoController.text,
            "peticion_concreta": _peticionConcretaController.text
          });
          await ResumenSolicitudesHelper.actualizarResumen(
            idOriginal: idDocumento,
            nuevoStatus: "Diligenciado",
            origen: "derechos_peticion_solicitados",
          );


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
              .collection('derechos_peticion_solicitados')
              .doc(idDocumento)
              .update({
            "status": "Revisado",
            "reviso": adminFullName,
            "fecha_revision": FieldValue.serverTimestamp(),

            /// 🔥 GUARDAR LOS TEXTOS ACTUALIZADOS
            "consideraciones": _consideracionesController.text.trim(),
            "fundamentos_de_derecho": _fundamentosDerechoController.text.trim(),
            "peticion_concreta": _peticionConcretaController.text.trim(),
          });

          await ResumenSolicitudesHelper.actualizarResumen(
            idOriginal: idDocumento,
            nuevoStatus: "Revisado",
            origen: "derechos_peticion_solicitados",
          );

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
class OpcionCorreo {
  final String nombre;   // Ej: "Correo JEP", "Jurídica", "Director", etc.
  final String correo;   // email destino
  final String entidad;  // Ej: Juzgado..., CPMSBOG..., etc.

  OpcionCorreo({
    required this.nombre,
    required this.correo,
    required this.entidad,
  });
}

