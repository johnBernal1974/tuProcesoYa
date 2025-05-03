
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:tuprocesoya/providers/ppl_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../commons/admin_provider.dart';
import '../../../commons/main_layaout.dart';
import '../../../controllers/tiempo_condena_controller.dart';
import '../../../models/ppl.dart';
import '../../../plantillas/plantilla_extincion_pena.dart';
import '../../../src/colors/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../widgets/datos_ejecucion_condena.dart';
import '../historial_solicitudes_extincion_pena_admin/historial_solicitudes_extincion_pena_admin.dart';
import '../historial_solicitudes_libertad_condicional_admin/historial_solicitudes_libertad_condicional_admin.dart';
import 'atender_extincion_pena_controller.dart';

class AtenderExtincionPenaPage extends StatefulWidget {
  final String status;
  final String idDocumento;
  final String numeroSeguimiento;
  final String fecha;
  final String idUser;

  const AtenderExtincionPenaPage({
    super.key,
    required this.status,
    required this.idDocumento,
    required this.numeroSeguimiento,
    required this.fecha,
    required this.idUser,
  });

  @override
  State<AtenderExtincionPenaPage> createState() => _AtenderExtincionPenaPageState();
}

class _AtenderExtincionPenaPageState extends State<AtenderExtincionPenaPage> {
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
  final TextEditingController _sinopsisController = TextEditingController();
  final TextEditingController _consideracionesController = TextEditingController();
  final TextEditingController _pretencionesController = TextEditingController();
  final TextEditingController _fundamentosDerechoController = TextEditingController();
  final AtenderExtincionPenaAdminController _controller = AtenderExtincionPenaAdminController();
  String sinopsis = "";
  String consideraciones = "";
  String fundamentosDeDerecho = "";
  String pretenciones = "";
  bool _mostrarVistaPrevia = false;
  bool _mostrarBotonVistaPrevia = false;
  Map<String, String> correosCentro = {};
  late DocumentReference userDoc;
  String? correoSeleccionado= ""; // Guarda el correo seleccionado
  String? nombreCorreoSeleccionado;
  String idDocumento="";
  bool _isSinopsisLoaded = false; // Bandera para evitar sobrescribir
  bool _isFundamentosLoaded = false; // Bandera para evitar sobrescribir
  bool _isConsideracionesLoaded = false; // Bandera para evitar sobrescribir
  bool _isPretencionesLoaded = false; // Bandera para evitar sobrescribir
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
  late ExtincionPenaTemplate extincionPena;
  String asignadoA_P2 = '';
  String asignadoNombreP2 = '';
  DateTime? fechaAsignadoP2;
  String? textoGeneradoIA; // A nivel de clase (State)
  bool mostrarCardIA = false;
  late final String? urlArchivoCedulaResponsable;
  late final List<String> urlsArchivosHijos;
  Map<String, dynamic>? solicitudData;
  String? _opcionReparacionSeleccionada;
  late CalculoCondenaController _calculoCondenaController;



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _pplProvider = PplProvider();
    _calculoCondenaController = CalculoCondenaController(_pplProvider);
    fetchUserData();
    fetchDocumentoExtincionPena();
    calcularTiempo(widget.idUser);
    _sinopsisController.addListener(_actualizarAltura);
    _consideracionesController.addListener(_actualizarAltura);
    _fundamentosDerechoController.addListener(_actualizarAltura);
    _pretencionesController.addListener(_actualizarAltura);


    WidgetsBinding.instance.addPostFrameCallback((_) {
      cargarSinopsis(widget.idDocumento);
      cargarConsideraciones(widget.idDocumento);
      cargarFundamentosDeDerecho(widget.idDocumento);
      cargarPretenciones(widget.idDocumento);
    });
    adminFullName = AdminProvider().adminFullName ?? ""; // Nombre completo
    if (adminFullName.isEmpty) {
      if (kDebugMode) {
        print("❌ No se pudo obtener el nombre del administrador.");
      }
    }
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
      pageTitle: 'Atender solicitud EXTINCION DE LA PENA',
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
                    "Extinción de la pena",
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
                    "Extinción de la pena - ${widget.status}",
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
              ingresarSinopsis(),
              const SizedBox(height: 30),
              ingresarConsideraciones(),
              const SizedBox(height: 30),
              ingresarFundamentosDeDerecho(),
              const SizedBox(height: 30),
              ingresarPretenciones(),
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
                    sinopsis = _sinopsisController.text.trim();
                    consideraciones = _consideracionesController.text.trim();
                    fundamentosDeDerecho = _fundamentosDerechoController.text.trim();
                    pretenciones = _pretencionesController.text.trim();
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
          vistaPreviaExtincionPena(
            userData: userData,
            sinopsis: _sinopsisController.text,
            consideraciones: _consideracionesController.text,
            fundamentosDeDerecho: _fundamentosDerechoController.text,
            pretenciones: _pretencionesController.text,
          )
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





  void _actualizarAltura() {
    int lineas = '\n'.allMatches(_sinopsisController.text).length + 1;
    setState(() {
// Limita el crecimiento a 5 líneas
    });
  }

  void _guardarDatosEnVariables() {
    if ( _sinopsisController.text.isEmpty || _fundamentosDerechoController.text.isEmpty || _consideracionesController.text.isEmpty
        || _pretencionesController.text.isEmpty) {
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
      sinopsis = _sinopsisController.text;
      consideraciones = _consideracionesController.text;
      fundamentosDeDerecho = _fundamentosDerechoController.text;
      pretenciones = _pretencionesController.text;
    });
    _mostrarBotonVistaPrevia = true;
  }

  @override
  void dispose() {
    _sinopsisController.removeListener(_actualizarAltura);
    _consideracionesController.removeListener(_actualizarAltura);
    _fundamentosDerechoController.removeListener(_actualizarAltura);
    _pretencionesController.removeListener(_actualizarAltura);
    _sinopsisController.dispose();
    _consideracionesController.dispose();
    _fundamentosDerechoController.dispose();
    _pretencionesController.dispose();
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
              _buildDetalleItem("Categoría", "Beneficios penitenciarios", fontSize),
              const SizedBox(height: 5),
              _buildDetalleItem("Fecha de solicitud", _formatFecha(DateTime.tryParse(widget.fecha)), fontSize),
              const SizedBox(height: 5),
              _buildDetalleItem("Subcategoría", "Extinción de la pena", fontSize),
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
                  _buildDetalleItem("Categoría", "Beneficios penitenciarios", fontSize),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetalleItem("Fecha de solicitud", _formatFecha(DateTime.tryParse(widget.fecha)), fontSize),
                  const SizedBox(height: 5),
                  _buildDetalleItem("Subcategoría", "Extinción de la pena", fontSize),
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
          _sinopsisController.text.trim().isNotEmpty && _consideracionesController.text.trim().isNotEmpty &&
              _fundamentosDerechoController.text.trim().isNotEmpty &&
              _pretencionesController.text.trim().isNotEmpty;
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

    final doc = await FirebaseFirestore.instance
        .collection('extincion_pena_solicitados')
        .doc(widget.idDocumento)
        .get();

    final latestData = doc.data();

    if (fetchedData != null && latestData != null && mounted) {
      // 🔥 Primero calcular correctamente los tiempos
      await calcularTiempo(widget.idUser);
      await _calculoCondenaController.calcularTiempo(widget.idUser);
      final diasRedimidos = _calculoCondenaController.totalDiasRedimidos?.toInt() ?? 0;

      // 🔥 Precargar campos
      _sinopsisController.text = generarTextoSinopsisDesdeDatos(
        fetchedData,
        fetchedData.situacion ?? 'En Reclusión',
        diasRedimidos.toDouble(),
      );

      if (!_isFundamentosLoaded) {
        _fundamentosDerechoController.text =
            generarTextoFundamentosDesdeDatos(fetchedData, latestData);
        _isFundamentosLoaded = true;
      }

      if (!_isPretencionesLoaded) {
        _pretencionesController.text =
            generarTextoPretencionesDesdeDatos(fetchedData.situacion ?? 'En Reclusión');
        _isPretencionesLoaded = true;
      }

      if (!_isConsideracionesLoaded) {
        final totalDias = (mesesEjecutado * 30) + diasEjecutadoExactos + diasRedimidos;
        final mesesEjecutadosFinal = totalDias ~/ 30;
        final diasEjecutadosFinal = totalDias % 30;

        _consideracionesController.text = generarTextoConsideracionesParaExtincionPena(
          situacion: fetchedData.situacion ?? 'En Reclusión',
          mesesEjecutados: mesesEjecutadosFinal,
          diasEjecutados: diasEjecutadosFinal,
        );

        _isConsideracionesLoaded = true;
      }

      setState(() {
        userData = fetchedData;
        extincionPena = ExtincionPenaTemplate(
          dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
          entidad: fetchedData.centroReclusion ?? "",
          referencia: "Beneficios penitenciarios - Extinción de la pena",
          nombrePpl: fetchedData.nombrePpl?.trim() ?? "",
          apellidoPpl: fetchedData.apellidoPpl?.trim() ?? "",
          identificacionPpl: fetchedData.numeroDocumentoPpl ?? "",
          centroPenitenciario: fetchedData.centroReclusion ?? "",
          sinopsis: _sinopsisController.text.trim(),
          consideraciones: _consideracionesController.text.trim(),
          fundamentosDeDerecho: _fundamentosDerechoController.text.trim(),
          pretenciones: _pretencionesController.text.trim(),
          emailUsuario: fetchedData.email?.trim() ?? "",
          nui: fetchedData.nui ?? "",
          td: fetchedData.td ?? "",
          patio: fetchedData.patio ?? "",
          radicado: fetchedData.radicado ?? "",
          delito: fetchedData.delito ?? "",
          condena: "${fetchedData.tiempoCondena ?? 0}",
          purgado: "$mesesEjecutado",
          jdc: fetchedData.juzgadoQueCondeno ?? "",
          numeroSeguimiento: widget.numeroSeguimiento,
          situacion: fetchedData.situacion,
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

  String generarTextoSinopsisDesdeDatos(
      Ppl userData,
      String situacion,
      double totalDiasRedimidos,
      ) {
    final jdc = userData.juzgadoQueCondeno ?? '';
    final condena = userData.tiempoCondena?.toString() ?? '';
    final captura = userData.fechaCaptura?.toString() ?? '';
    final delito = userData.delito ?? '';
    final fechaFormateada = formatearFechaCaptura(captura);

    return "Mi condena fue proferida mediante sentencia por el $jdc, imponiendo una pena de $condena meses de prisión por el delito de $delito. "
        "La captura fue el día $fechaFormateada.";

  }

  String generarTextoConsideracionesParaExtincionPena({
    required String situacion,
    required int mesesEjecutados,
    required int diasEjecutados,
  }) {
    final textoComportamiento = (situacion == "En libertad condicional")
        ? "Durante el tiempo que he permanecido en libertad condicional, he observado un comportamiento ejemplar, cumpliendo con las condiciones impuestas por la autoridad judicial y demostrando mi compromiso con la reintegración social."
        : "Durante mi tiempo de reclusión, he mantenido una conducta intachable, cumpliendo con las normas del establecimiento, participando activamente en programas de resocialización y demostrando responsabilidad y disciplina.";

    final textoCumplimiento =
        "A la fecha, he cumplido $mesesEjecutados meses y $diasEjecutados días de la condena, incluyendo el tiempo efectivo de reclusión y las redenciones obtenidas conforme a la ley. Con ello, he satisfecho en su totalidad la pena privativa de la libertad impuesta.";

    return """
Honorable Juez, me permito solicitar la extinción de la pena privativa de la libertad que me fue impuesta, en virtud del cumplimiento total de la misma, conforme a lo establecido en el artículo 147 de la Ley 65 de 1993.

$textoComportamiento

$textoCumplimiento

Con esta solicitud busco formalizar el cierre de una etapa jurídica que he asumido con responsabilidad, y continuar mi vida con plena integración a la sociedad, dentro del marco de la legalidad y el respeto por los valores ciudadanos.
""";
  }

  String generarTextoPretencionesDesdeDatos(String situacion) {
    if (situacion == "En libertad condicional") {
      return """
PRIMERO: Que se reconozca que actualmente me encuentro en libertad condicional y que, habiendo cumplido la totalidad de la pena impuesta, se declare la extinción de la misma conforme a lo dispuesto en la Ley 65 de 1993.

SEGUNDO: Solicitar a la autoridad competente que emita la resolución correspondiente en la que se formalice la extinción de la pena privativa de la libertad que me fue impuesta.
""";
    }

    // Default: En Reclusión
    return """
PRIMERO: Solicitar al establecimiento penitenciario y carcelario que certifique el cumplimiento total de la pena, incluyendo el tiempo efectivo y los redimidos conforme a la ley.

SEGUNDO: Solicitar a la autoridad judicial competente que, con base en la certificación y el cumplimiento íntegro de la pena, declare formalmente la extinción de la misma conforme al artículo 147 de la Ley 65 de 1993.
""";
  }


  String generarTextoFundamentosDesdeDatos(
      Ppl userData,
      Map<String, dynamic> latestData,
      ) {
    final situacion = userData.situacion ?? 'En Reclusión';

    if (situacion == "En libertad condicional") {
      return """
1. El artículo 147 de la Ley 65 de 1993 establece que la pena privativa de la libertad se extingue cuando ha sido cumplida en su totalidad, incluyendo el tiempo ejecutado efectivamente, los redimidos y los otorgados mediante beneficios administrativos o judiciales.

2. Actualmente me encuentro en libertad condicional, lo cual indica que he cumplido una parte sustancial de la pena con conducta favorable y bajo supervisión, contribuyendo activamente a mi proceso de resocialización.

3. El artículo 29 de la Constitución Política garantiza el debido proceso, y el cumplimiento total de la pena constituye una condición suficiente para solicitar su extinción.

4. La Corte Constitucional ha reiterado en múltiples pronunciamientos que la finalidad de la pena no es solo sancionadora sino también resocializadora, y una vez esta se ha cumplido en su integridad, se debe reconocer el derecho a extinguirla legalmente.

5. En virtud del principio de legalidad y del respeto por los derechos fundamentales, solicito se declare la extinción de la pena privativa de la libertad que me fue impuesta, toda vez que he satisfecho íntegramente su duración conforme a la ley.
""";
    }

    // 🔹 Situación por defecto: En Reclusión
    return """
1. Conforme al artículo 147 del Código Penitenciario y Carcelario (Ley 65 de 1993), la pena privativa de la libertad se extingue cuando el condenado ha cumplido la totalidad de la misma, incluyendo los tiempos redimidos por trabajo, estudio u otras actividades reconocidas por la ley.

2. Actualmente me encuentro privado de la libertad en centro de reclusión, donde he cumplido efectivamente la pena impuesta, teniendo en cuenta los tiempos de reclusión y las redenciones legalmente reconocidas.

3. La Corte Constitucional ha sostenido que una vez se ha cumplido con la totalidad de la pena, el Estado tiene la obligación de reconocer la extinción de la misma, como expresión del respeto a los derechos fundamentales y al principio de legalidad.

4. El artículo 29 de la Constitución Política de Colombia, que consagra el debido proceso, y el artículo 10 del Pacto Internacional de Derechos Civiles y Políticos, ratificado por Colombia, respaldan que la pena no debe prolongarse más allá del límite legalmente establecido.

5. En razón de lo anterior, y habiéndose cumplido todos los requisitos temporales y sustanciales, solicito formalmente la extinción de la pena impuesta, en los términos del ordenamiento jurídico colombiano.
""";
  }


  void fetchDocumentoExtincionPena() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('extincion_pena_solicitados')
          .doc(widget.idDocumento)
          .get();

      if (documentSnapshot.exists) {
        Map<String, dynamic>? data = documentSnapshot.data() as Map<String, dynamic>?;

        solicitudData = data; // ✅ Ahora sí podemos asignarla

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

  // 🔹 Cloud Function para generar texto automático para prisión domiciliaria
  // Future<void> generarTextoIAParaDomiciliaria() async {
  //   try {
  //     final resultado = await IABackendService.generarTextoPrisionDomiciliaria(); // ✅ Nombre correcto del método
  //
  //     setState(() {
  //       _consideracionesController.text = resultado['consideraciones'] ?? '';
  //       _fundamentosDerechoController.text = resultado['fundamentos'] ?? '';
  //       _peticionConcretaController.text = resultado['peticion'] ?? '';
  //     });
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("✅ Texto IA insertado en todos los campos")),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("❌ Error: $e")),
  //     );
  //   }
  // }

  // corregido full
  Future<void> cargarSinopsis(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('extincion_pena_solicitados')
          .doc(docId)
          .get();

      if (doc.exists && !_isSinopsisLoaded) {
        final data = doc.data() as Map<String, dynamic>?;

        final texto = data?['sinopsis'];
        if (texto != null && texto is String) {
          setState(() {
            _sinopsisController.text = texto;
            _isSinopsisLoaded = true;
          });

          verificarVistaPrevia();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error cargando sinopsis: $e");
      }
    }
  }

  Future<void> cargarConsideraciones(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('extincion_pena_solicitados')
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
          .collection('extincion_pena_solicitados')
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
  Future<void> cargarPretenciones(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('extincion_pena_solicitados')
          .doc(docId)
          .get();

      if (doc.exists && !_isPretencionesLoaded) {
        final data = doc.data() as Map<String, dynamic>?;

        final texto = data?['pretenciones'];
        if (texto != null && texto is String) {
          setState(() {
            _pretencionesController.text = texto;
            _isPretencionesLoaded = true;
          });

          verificarVistaPrevia();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error cargando pretenciones: $e");
      }
    }
  }

  //corregido full - autollenado por IA o se puede escribir igualmente
  Widget ingresarSinopsis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "SINOPSIS",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _sinopsisController,
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
  Widget ingresarPretenciones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "PRETENCIONES",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _pretencionesController,
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

  Widget ingresarConsideraciones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "CONSIDERACIONES",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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


  Widget vistaPreviaExtincionPena({
    required Ppl? userData,
    required String sinopsis,
    required String consideraciones,
    required String fundamentosDeDerecho,
    required String pretenciones,

  }) {
    //usamos la misma plantilla que domiciliaria ya que es igual**
    final plantilla = ExtincionPenaTemplate(
      dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
      entidad: entidad,
      referencia: "Beneficios penitenciarios - Extinción de la pena",
      nombrePpl: userData?.nombrePpl ?? "",
      apellidoPpl: userData?.apellidoPpl ?? "",
      identificacionPpl: userData?.numeroDocumentoPpl ?? "",
      centroPenitenciario: userData?.centroReclusion ?? "",
      sinopsis: convertirSaltosDeLinea(_sinopsisController.text),
      consideraciones: convertirSaltosDeLinea(_consideracionesController.text),
      fundamentosDeDerecho: convertirSaltosDeLinea(_fundamentosDerechoController.text),
      pretenciones: convertirSaltosDeLinea(_pretencionesController.text),
      emailUsuario: userData?.email ?? "",
      nui: userData?.nui ?? "",
      td: userData?.td ?? "",
      patio: userData?.patio ?? "",
      radicado: userData?.radicado ?? "",
      delito: userData?.delito ?? "",
      condena: "${userData?.tiempoCondena ?? ''}",
      purgado: "$mesesEjecutado",
      jdc: userData?.juzgadoQueCondeno ?? "",
      numeroSeguimiento: widget.numeroSeguimiento,
      situacion: userData?.situacion ?? 'En Reclusión',
    );


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vista previa de la solicitud de extinción de la pena",
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
              const SizedBox(width: 20), // Espaciado entre botones
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

  Future<void> enviarCorreoResend() async {
    final url = Uri.parse("https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/sendEmailWithResend");

    final doc = await FirebaseFirestore.instance
        .collection('extincion_pena_solicitados')
        .doc(widget.idDocumento)
        .get();

    final latestData = doc.data();
    if (latestData == null || userData == null) return;

      extincionPena = ExtincionPenaTemplate(
      dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
      entidad: entidad ?? "",
      referencia: "Beneficios penitenciarios - Extinción de la pena",
      nombrePpl: userData?.nombrePpl.trim() ?? "",
      apellidoPpl: userData?.apellidoPpl.trim() ?? "",
      identificacionPpl: userData?.numeroDocumentoPpl ?? "",
      centroPenitenciario: userData?.centroReclusion ?? "",
      sinopsis: sinopsis,
      consideraciones: consideraciones,
      fundamentosDeDerecho: fundamentosDeDerecho,
      pretenciones: pretenciones,
      emailUsuario: userData?.email.trim() ?? '',
      nui: userData?.nui ?? '',
      td: userData?.td ?? '',
      patio: userData?.patio ?? '',
      radicado: userData?.radicado ?? '',
      delito: userData?.delito ?? '',
      condena: "${userData?.tiempoCondena ?? 0}",
      purgado: "$mesesEjecutado meses y $diasEjecutadoExactos días",
      jdc: userData?.juzgadoQueCondeno ?? '',
      numeroSeguimiento: widget.numeroSeguimiento,
      situacion: userData?.situacion ?? 'En Reclusión', // ✅ Campo agregado
    );


    String mensajeHtml = extincionPena.generarTextoHtml();

    List<Map<String, String>> archivosBase64 = [];



    final asuntoCorreo = "Solicitud de Extinción de la pena - ${widget.numeroSeguimiento}";
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
      "tipo": "extincion",
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      await FirebaseFirestore.instance
          .collection('extincion_pena_solicitados')
          .doc(widget.idDocumento)
          .update({
        "status": "Enviado",
        "fechaEnvio": FieldValue.serverTimestamp(),
        "envió": adminFullName,
      });
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
          // 🔄 Sincronizar los datos actualizados antes de enviar
          setState(() {
            sinopsis = _sinopsisController.text.trim();
            consideraciones = _consideracionesController.text.trim();
            fundamentosDeDerecho = _fundamentosDerechoController.text.trim();
            pretenciones = _pretencionesController.text.trim();
          });

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

          final html = extincionPena.generarTextoHtml();
          await subirHtmlCorreoADocumentoExtincionPena(
            idDocumento: widget.idDocumento,
            htmlContent: html,
          );

          const urlApp = "https://www.tuprocesoya.com";
          final numeroSeguimiento = extincionPena.numeroSeguimiento;

          if (context.mounted) {
            Navigator.of(context).pop(); // Cerrar loading

            final enviar = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: blanco,
                title: const Text("¿Enviar Notificación?"),
                content: const Text("¿Deseas notificar al usuario del envío del correo por WhatsApp?"),
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
                      "Hemos enviado tu solicitud de extinción de la pena número *$numeroSeguimiento* a la autoridad competente.\n\n"
                      "Recuerda que la entidad tiene un tiempo aproximado de 20 días hábiles para responder a la presente solicitud. Te estaremos informando el resultado de la diligencia.\n\n"
                      "Ingresa a la aplicación / menú / Historiales/ Tus Solicitudes extinción de la pena. Allí podrás ver el correo enviado:\n$urlApp\n\n"
                      "Gracias por confiar en nosotros.\n\nCordialmente,\n\n*El equipo de Tu Proceso Ya.*"
              );
              final link = "https://wa.me/$celular?text=$mensaje";
              await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
            }
            if(context.mounted){
              Navigator.pushReplacementNamed(context, 'historial_solicitudes_extincion_pena_admin');
            }
          }
        }
      },
      child: const Text("Enviar por correo"),
    );
  }


  Future<void> subirHtmlCorreoADocumentoExtincionPena({
    required String idDocumento,
    required String htmlContent,
  }) async {
    try {
      // 🛠 Asegurar UTF-8 para que se vean bien las tildes y ñ
      final contenidoFinal = htmlUtf8Compatible(htmlContent);

      // 📁 Crear bytes
      final bytes = utf8.encode(contenidoFinal);
      const fileName = "correo.html";
      final filePath = "extincion/$idDocumento/correos/$fileName"; // 🟣 Cambiar carpeta

      final ref = FirebaseStorage.instance.ref(filePath);
      final metadata = SettableMetadata(contentType: "text/html");

      // ⬆️ Subir archivo
      await ref.putData(Uint8List.fromList(bytes), metadata);

      // 🌐 Obtener URL
      final downloadUrl = await ref.getDownloadURL();

      // 🗃️ Guardar en Firestore
      await FirebaseFirestore.instance
          .collection("extincion_pena_solicitados") // 🟣 Cambiar colección
          .doc(idDocumento)
          .update({
        "correoHtmlUrl": downloadUrl,
        "fechaHtmlCorreo": FieldValue.serverTimestamp(),
      });

      print("✅ HTML de extincion subido y guardado con URL: $downloadUrl");
    } catch (e) {
      print("❌ Error al subir HTML del correo de domiciliaria: $e");
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
              .collection('extincion_pena_solicitados')
              .doc(idDocumento)
              .update({
            "status": "Diligenciado",
            "diligencio": adminFullName,
            "fecha_diligenciamiento": FieldValue.serverTimestamp(),
            "sinopsis": _sinopsisController.text,
            "consideraciones": _consideracionesController.text,
            "fundamentos_de_derecho": _fundamentosDerechoController.text,
            "pretenciones": _pretencionesController.text,
          });

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
                  return const HistorialSolicitudesExtincionPenaAdminPage();
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
              .collection('extincion_pena_solicitados')
              .doc(idDocumento)
              .update({
            "status": "Revisado",
            "reviso": adminFullName,
            "fecha_revision": FieldValue.serverTimestamp(),
            "sinopsis": _sinopsisController.text,
            "consideraciones": _consideracionesController.text,
            "fundamentos_de_derecho": _fundamentosDerechoController.text,
            "pretenciones": _pretencionesController.text,
          });

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
                  return const HistorialSolicitudesExtincionPenaAdminPage();
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


}
