
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
import '../../../commons/archivoViewerWeb2.dart';
import '../../../commons/main_layaout.dart';
import '../../../controllers/tiempo_condena_controller.dart';
import '../../../helper/resumen_solicitudes_helper.dart';
import '../../../models/ppl.dart';
import '../../../plantillas/plantilla_domiciliaria.dart';
import '../../../src/colors/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../widgets/datos_ejecucion_condena.dart';
import '../../../widgets/envio_correo_manager.dart';
import '../../../widgets/envio_correo_managerV2.dart';
import '../../../widgets/seleccionar_correo_centro_copia_correo.dart';
import '../../../widgets/seleccionar_correo_centro_copia_correoV2.dart';
import '../../../widgets/selector_correo_manual.dart';
import '../historial_solicitudes_prision_domiciliaria_admin/historial_solicitudes_prision_domiciliaria_admin.dart';

class AtenderPrisionDomiciliariaPage extends StatefulWidget {
  final String status;
  final String idDocumento;
  final String numeroSeguimiento;
  final String direccion;
  final String departamento;
  final String municipio;
  final String nombreResponsable;
  final String cedulaResponsable;
  final String celularResponsable;
  final String fecha;
  final String idUser;
  final List<String> archivos;
  final String parentesco;
  final String reparacion;


  // 🔹 Nuevos campos opcionales
  final String? urlArchivoCedulaResponsable;
  final List<String> urlsArchivosHijos;

  const AtenderPrisionDomiciliariaPage({
    super.key,
    required this.status,
    required this.idDocumento,
    required this.numeroSeguimiento,
    required this.direccion,
    required this.departamento,
    required this.municipio,
    required this.nombreResponsable,
    required this.cedulaResponsable,
    required this.celularResponsable,
    required this.fecha,
    required this.idUser,
    required this.archivos,
    required this.parentesco,
    required this.reparacion,
    this.urlArchivoCedulaResponsable,
    this.urlsArchivosHijos = const [],
  });

  @override
  State<AtenderPrisionDomiciliariaPage> createState() => _AtenderPrisionDomiciliariaPageState();
}

class _AtenderPrisionDomiciliariaPageState extends State<AtenderPrisionDomiciliariaPage> {
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
  final TextEditingController _anexosController = TextEditingController();
  final TextEditingController _fundamentosDerechoController = TextEditingController();
  final AtenderDerechoPeticionAdminController _controller = AtenderDerechoPeticionAdminController();
  String sinopsis = "";
  String consideraciones = "";
  String fundamentosDeDerecho = "";
  String pretenciones = "";
  String anexos = "";
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
  bool _isAnexosLoaded = false; // Bandera para evitar sobrescribir
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
  late PrisionDomiciliariaTemplate prisionDomiciliaria;
  String asignadoA_P2 = '';
  String asignadoNombreP2 = '';
  DateTime? fechaAsignadoP2;
  String? textoGeneradoIA; // A nivel de clase (State)
  bool mostrarCardIA = false;
  late final String? urlArchivoCedulaResponsable;
  late final List<String> urlsArchivosHijos;
  Map<String, dynamic>? solicitudData;
  late CalculoCondenaController _calculoCondenaController;


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

// 🔹 Agregar la cédula del responsable si existe
    if (widget.urlArchivoCedulaResponsable != null && widget.urlArchivoCedulaResponsable!.isNotEmpty) {
      archivosAdjuntos.add({
        "nombre": obtenerNombreArchivo(widget.urlArchivoCedulaResponsable!),
        "contenido": widget.urlArchivoCedulaResponsable!,
      });
    }

// 🔹 Agregar los documentos de los hijos
    if (widget.urlsArchivosHijos.isNotEmpty) {
      for (var url in widget.urlsArchivosHijos) {
        archivosAdjuntos.add({
          "nombre": obtenerNombreArchivo(url),
          "contenido": url,
        });
      }
    }

    fetchUserData();
    fetchDocumentoPrisionDomiciliaria();
    calcularTiempo(widget.idUser);
    _sinopsisController.addListener(_actualizarAltura);
    _consideracionesController.addListener(_actualizarAltura);
    _fundamentosDerechoController.addListener(_actualizarAltura);
    _pretencionesController.addListener(_actualizarAltura);
    _anexosController.addListener(_actualizarAltura);


    WidgetsBinding.instance.addPostFrameCallback((_) {
      cargarSinopsis(widget.idDocumento);
      cargarConsideraciones(widget.idDocumento);
      cargarFundamentosDeDerecho(widget.idDocumento);
      cargarPretenciones(widget.idDocumento);
      cargarAnexos(widget.idDocumento);
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
      pageTitle: 'Atender solicitud PRISIÓN DOMICILIARIA',
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
                    "Prisión Domiciliaria ",
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
                    "Prisión Domiciliaria - ${widget.status}",
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
            ],
          ),

        ),
        const Row(
          children: [
            Icon(Icons.attach_file),
            Text("Archivos adjuntos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 30),

        /// 📂 **Mostramos los archivos aquí**
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.archivos.isNotEmpty) ...[
              const Text("📄 Recibo de servicios - 📝 Declaración extrajuicio - 📝 Insolvencia (Si aplica)",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ArchivoViewerWeb2(
                archivos: widget.archivos,
              ),
              const SizedBox(height: 20),
            ],
            if (widget.urlArchivoCedulaResponsable != null && widget.urlArchivoCedulaResponsable!.isNotEmpty) ...[
              const Text("🪪 Cédula del responsable", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ArchivoViewerWeb2(
                archivos: [widget.urlArchivoCedulaResponsable!],
              ),
              const SizedBox(height: 20),
            ],
            if (widget.urlsArchivosHijos.isNotEmpty) ...[
              const Text("👶 Documentos de identidad de los hijos",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ArchivoViewerWeb2(
                archivos: widget.urlsArchivosHijos,
              ),
              const SizedBox(height: 20),
            ],
            if (archivosAdjuntos.length > widget.archivos.length +
                (widget.urlArchivoCedulaResponsable != null ? 1 : 0) +
                widget.urlsArchivosHijos.length) ...[
              const Text("📎 Otros archivos adjuntos",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ArchivoViewerWeb2(
                archivos: archivosAdjuntos
                    .map((e) => e['contenido']!)
                    .toList()
                    .where((url) =>
                !widget.archivos.contains(url) &&
                    url != widget.urlArchivoCedulaResponsable &&
                    !widget.urlsArchivosHijos.contains(url))
                    .toList(),
              ),
            ],
            if (widget.archivos.isEmpty &&
                (widget.urlArchivoCedulaResponsable?.isEmpty ?? true) &&
                widget.urlsArchivosHijos.isEmpty)
              const Text(
                "El usuario no compartió ningún archivo",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red),
              ),
          ],
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
                    sinopsis = _sinopsisController.text.trim();
                    consideraciones = _consideracionesController.text.trim();
                    fundamentosDeDerecho = _fundamentosDerechoController.text.trim();
                    pretenciones = _pretencionesController.text.trim();
                    anexos = _anexosController.text.trim();
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
          vistaPreviaPrisionDomiciliaria(
            userData: userData,
            sinopsis: sinopsis,
            consideraciones: consideraciones,
            fundamentosDeDerecho: fundamentosDeDerecho,
            pretenciones: pretenciones,
            anexos: anexos,
            direccion: widget.direccion,
            municipio: widget.municipio,
            departamento: widget.departamento,
            nombreResponsable: widget.nombreResponsable,
            cedulaResponsable: widget.cedulaResponsable,
            celularResponsable: widget.celularResponsable,
            parentesco: widget.parentesco,
            hijos: solicitudData?.containsKey('hijos') == true
                ? List<Map<String, String>>.from(
              (solicitudData!['hijos'] as List).map(
                    (hijo) => Map<String, String>.from(
                  (hijo as Map),
                ),
              ),
            )
                : [],

            documentosHijos: solicitudData?.containsKey('documentos_hijos') == true
                ? List<String>.from(solicitudData!['documentos_hijos'])
                : [],
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


  void _actualizarAltura() {
    int lineas = '\n'.allMatches(_sinopsisController.text).length + 1;
    setState(() {
// Limita el crecimiento a 5 líneas
    });
  }

  void _guardarDatosEnVariables() {
    if ( _sinopsisController.text.isEmpty || _fundamentosDerechoController.text.isEmpty || _consideracionesController.text.isEmpty
        || _pretencionesController.text.isEmpty
    || _anexosController.text.isEmpty ) {
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
      anexos = _anexosController.text;
    });
    _mostrarBotonVistaPrevia = true;
  }

  @override
  void dispose() {
    _sinopsisController.removeListener(_actualizarAltura);
    _consideracionesController.removeListener(_actualizarAltura);
    _fundamentosDerechoController.removeListener(_actualizarAltura);
    _pretencionesController.removeListener(_actualizarAltura);
    _anexosController.removeListener(_actualizarAltura);
    _sinopsisController.dispose();
    _consideracionesController.dispose();
    _fundamentosDerechoController.dispose();
    _pretencionesController.dispose();
    _anexosController.dispose();
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
              _buildDetalleItem("Subcategoría", "Prisión domiciliaria", fontSize),
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
                  _buildDetalleItem("Subcategoría", "Prisión domiciliaria", fontSize),
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
              _pretencionesController.text.trim().isNotEmpty &&
              _anexosController.text.trim().isNotEmpty;
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
    String? situacion = userData?.situacion;

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
          FutureBuilder<double>(
            future: calcularTotalRedenciones(widget.idUser),
            builder: (context, snapshot) {
              double totalRedimido = snapshot.data ?? 0.0;
              return _datosEjecucionCondena(totalRedimido);
            },
          ),
          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              final esPantallaAncha = constraints.maxWidth > 700; // Ajusta el ancho según necesidad

              if (esPantallaAncha) {
                // ✅ En PC: todas en una fila
                return Card(
                  color: Colors.white,
                  surfaceTintColor: blanco,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (situacion == "En Reclusión") ...[
                          _buildBenefitMinimalSection(
                            titulo: "72 Horas",
                            condition: porcentajeEjecutado >= 33.33,
                            remainingTime: _calcularDias(33),
                          ),
                          const SizedBox(width: 16),
                          _buildBenefitMinimalSection(
                            titulo: "Domiciliaria",
                            condition: porcentajeEjecutado >= 50,
                            remainingTime: ((50 - porcentajeEjecutado) / 100 * tiempoCondena * 30).ceil(),
                          ),
                          const SizedBox(width: 16),
                        ],
                        _buildBenefitMinimalSection(
                          titulo: "Condicional",
                          condition: porcentajeEjecutado >= 60,
                          remainingTime: ((60 - porcentajeEjecutado) / 100 * tiempoCondena * 30).ceil(),
                        ),
                        const SizedBox(width: 16),
                        _buildBenefitMinimalSection(
                          titulo: "Extinción",
                          condition: porcentajeEjecutado >= 100,
                          remainingTime: ((100 - porcentajeEjecutado) / 100 * tiempoCondena * 30).ceil(),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                // ✅ En móvil: dos columnas como antes
                return Card(
                  color: Colors.white,
                  surfaceTintColor: blanco,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Primera columna
                        Expanded(
                          child: Column(
                            children: [
                              if (situacion == "En Reclusión")
                                _buildBenefitMinimalSection(
                                  titulo: "72 Horas",
                                  condition: porcentajeEjecutado >= 33.33,
                                  remainingTime: _calcularDias(33),
                                ),
                              _buildBenefitMinimalSection(
                                titulo: "Condicional",
                                condition: porcentajeEjecutado >= 60,
                                remainingTime: ((60 - porcentajeEjecutado) / 100 * tiempoCondena * 30).ceil(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Segunda columna
                        Expanded(
                          child: Column(
                            children: [
                              if (situacion == "En Reclusión" || situacion == "En Prisión domiciliaria")
                                if (situacion == "En Reclusión")
                                  _buildBenefitMinimalSection(
                                    titulo: "Domiciliaria",
                                    condition: porcentajeEjecutado >= 50,
                                    remainingTime: ((50 - porcentajeEjecutado) / 100 * tiempoCondena * 30).ceil(),
                                  ),
                              _buildBenefitMinimalSection(
                                titulo: "Extinción",
                                condition: porcentajeEjecutado >= 100,
                                remainingTime: ((100 - porcentajeEjecutado) / 100 * tiempoCondena * 30).ceil(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 50),
        ],
      ),
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
        .collection('domiciliaria_solicitados')
        .doc(widget.idDocumento)
        .get();

    final latestData = doc.data();

    if (fetchedData != null && latestData != null && mounted) {
      // 🔥 IMPORTANTE: Calcular primero el tiempo y los días redimidos
      await _calculoCondenaController.calcularTiempo(widget.idUser);

      if (!_isSinopsisLoaded) {
        _sinopsisController.text = generarTextoSinopsisDesdeDatos(
          fetchedData,
          fetchedData.situacion ?? 'En Reclusión',
          widget.reparacion,
          _calculoCondenaController.totalDiasRedimidos ?? 0,
        );
        _isSinopsisLoaded = true;
      }

      if (!_isFundamentosLoaded) {
        _fundamentosDerechoController.text =
            generarTextoFundamentosDesdeDatos(
              fetchedData,
              latestData,
              widget.parentesco,
              mesesEjecutado, // 🔥 Aquí pasas los meses ejecutados
              diasEjecutadoExactos, // 🔥 Aquí pasas los días ejecutados
            );
        _isFundamentosLoaded = true;
      }


      if (!_isPretencionesLoaded) {
        _pretencionesController.text = generarTextoPretencionesDesdeDatos(fetchedData);
        _isPretencionesLoaded = true;
      }

      if (!_isAnexosLoaded) {
        final tieneHijosYDocumentos = latestData.containsKey('hijos') &&
            latestData['hijos'] is List &&
            latestData['hijos'].isNotEmpty &&
            latestData.containsKey('documentos_hijos') &&
            latestData['documentos_hijos'] is List &&
            latestData['documentos_hijos'].isNotEmpty;

        final listaHijos = tieneHijosYDocumentos
            ? (latestData['hijos'] as List<dynamic>)
            .whereType<Map>() // 🔹 Asegura que cada ítem sea un Map
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
            : <Map<String, dynamic>>[];

        _anexosController.text = generarTextoAnexos(
          incluirPuntoHijos: tieneHijosYDocumentos,
          hijos: listaHijos,
          reparacion: widget.reparacion,
        );
        _isAnexosLoaded = true;
      }

      if (!_isConsideracionesLoaded) {
        final listaHijos = solicitudData?.containsKey('hijos') == true
            ? List<Map<String, String>>.from(
            solicitudData!['hijos'].map((h) => Map<String, String>.from(h)))
            : <Map<String, String>>[];

        final diasRedimidos = _calculoCondenaController.totalDiasRedimidos?.toInt() ?? 0;
        final totalDias = diasEjecutadoExactos + (mesesEjecutado * 30) + diasRedimidos;
        final mesesTotales = totalDias ~/ 30;
        final diasRestantes = totalDias % 30;

        _consideracionesController.text = generarTextoConsideracionesParaPrisionDomiciliaria(
          direccion: widget.direccion,
          municipio: widget.municipio,
          departamento: widget.departamento,
          nombreResponsable: widget.nombreResponsable,
          parentescoResponsable: widget.parentesco,
          mesesEjecutados: mesesTotales,
          diasEjecutados: diasRestantes,
          hijos: listaHijos,
        );
        _isConsideracionesLoaded = true;
      }


      setState(() {
        userData = fetchedData;

        prisionDomiciliaria = PrisionDomiciliariaTemplate(
          dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
          entidad: fetchedData.centroReclusion ?? "",
          referencia: "Beneficios penitenciarios - Prisión domiciliaria",
          nombrePpl: fetchedData.nombrePpl?.trim() ?? "",
          apellidoPpl: fetchedData.apellidoPpl?.trim() ?? "",
          identificacionPpl: fetchedData.numeroDocumentoPpl ?? "",
          centroPenitenciario: fetchedData.centroReclusion ?? "",
          sinopsis: _sinopsisController.text.trim(),
          consideraciones: _consideracionesController.text.trim(),
          fundamentosDeDerecho: _fundamentosDerechoController.text.trim(),
          pretenciones: _pretencionesController.text.trim(),
          anexos: _anexosController.text.trim(),
          direccionDomicilio: latestData['direccion'] ?? "",
          municipio: latestData['municipio'] ?? "",
          departamento: latestData['departamento'] ?? "",
          nombreResponsable: latestData['nombre_responsable'] ?? "",
          parentesco: widget.parentesco,
          cedulaResponsable: latestData['cedula_responsable'] ?? "",
          celularResponsable: latestData['celular_responsable'] ?? "",
          emailUsuario: fetchedData.email?.trim() ?? "",
          nui: fetchedData.nui ?? "",
          td: fetchedData.td ?? "",
          patio: fetchedData.patio ?? "",
          radicado: fetchedData.radicado ?? "",
          delito: fetchedData.delito ?? "",
          condena: userData?.diasCondena != null && userData!.diasCondena! > 0
              ? "${userData?.mesesCondena ?? 0} meses y ${userData?.diasCondena} días"
              : "${userData?.mesesCondena ?? 0} meses",
          purgado: "$mesesEjecutado",
          jdc: fetchedData.juzgadoQueCondeno ?? "",
          numeroSeguimiento: widget.numeroSeguimiento,
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
      String reparacion, // aunque no lo uses, lo dejamos para que no tengas que cambiar llamadas existentes
      double totalDiasRedimidos,
      ) {
    final jdc = userData.juzgadoQueCondeno ?? '';
    final meses = userData.mesesCondena ?? 0;
    final dias = userData.diasCondena ?? 0;
    final condena = (dias > 0) ? '$meses meses y $dias días' : '$meses meses';

    final captura = userData.fechaCaptura?.toString() ?? '';
    final delito = userData.delito ?? '';
    final fechaFormateada = formatearFechaCaptura(captura);

    if (situacion == "En Prisión domiciliaria") {
      return "Mi condena fue proferida mediante sentencia por el $jdc, imponiendo una pena de $condena de prisión por el delito de $delito. "
          "La captura fue el día $fechaFormateada. Actualmente me encuentro cumpliendo la condena bajo el beneficio de prisión domiciliaria.";
    } else {
      return "Mi condena fue proferida mediante sentencia por el $jdc, imponiendo una pena de $condena de prisión por el delito de $delito. "
          "La captura fue el día $fechaFormateada.";
    }
  }


  String generarTextoConsideracionesParaPrisionDomiciliaria({
    required String direccion,
    required String municipio,
    required String departamento,
    required String nombreResponsable,
    required String parentescoResponsable,
    required int mesesEjecutados,
    required int diasEjecutados,
    List<Map<String, String>> hijos = const [],
  }) {
    // 🔹 Construir el texto de los hijos si existen
    String textoHijos = "";
    if (hijos.isNotEmpty) {
      final esPlural = hijos.length > 1;
      final listaHijos = hijos.map((hijo) {
        final nombre = hijo['nombre'] ?? '';
        final edad = hijo['edad'] ?? '';
        return "$nombre, de $edad años";
      }).join("; ");

      textoHijos =
      "\n\nEn el mismo hogar también conviviré con ${esPlural ? "mis hijos" : "mi hijo"} $listaHijos, "
          "${esPlural ? "quienes son" : "quien es"} parte esencial de mi vida y ${esPlural ? "representan" : "representa"} mi principal motivación para avanzar en mi proceso de resocialización.";
    }

    // 🔹 Texto de cumplimiento de pena
    final textoCumplimientoPena =
        "A la fecha, he cumplido $mesesEjecutados meses y $diasEjecutados días de la pena impuesta, superando así el cincuenta por ciento (50%) del total de la condena, requisito previsto en el artículo 38G del Código Penal para acceder al beneficio de prisión domiciliaria.";


    return """
Honorable Juez, respetuosamente me permito solicitar que me sea concedido el beneficio de prisión domiciliaria, con el fin de continuar el cumplimiento de mi pena en un entorno familiar, bajo condiciones de vigilancia y responsabilidad.

Durante mi permanencia en el establecimiento penitenciario, he demostrado un comportamiento ejemplar, participando activamente en programas de resocialización, educación y trabajo, y manteniendo una conducta respetuosa frente a la autoridad y mis compañeros.

$textoCumplimientoPena

De ser concedido el beneficio, residiré en el domicilio ubicado en $direccion, en el municipio de $municipio, departamento de $departamento, bajo el cuidado y supervisión de $nombreResponsable, quien es mi $parentescoResponsable, y quien ha asumido el compromiso de garantizar que cumpla con todas las condiciones que se me impongan.$textoHijos

Su señoria, me dirijo a usted con profundo respeto y humildad, reconociendo el grave error que cometí y aceptando con entereza las consecuencias de mis actos. Pido perdón a Dios, a la sociedad colombiana, a la justicia y, sobre todo, a mi familia, quienes también han sufrido con el peso de mis decisiones.

Hoy me encuentro en un camino de reflexión y transformación personal. Cada día, desde mi lugar de reclusión, trabajo con honestidad por cambiar, crecer y reparar en lo posible el daño causado. Mi mayor anhelo es continuar este proceso desde el entorno familiar, rodeado del amor y el apoyo de mis seres queridos, quienes representan una fuente vital de contención emocional y motivación.

Solicito respetuosamente que sea estudiada la posibilidad de acceder al beneficio de prisión domiciliaria. Este paso no solo fortalecería mis vínculos familiares, sino que también sería un escenario más propicio para consolidar mi proceso de resocialización, permitiéndome avanzar con mayor responsabilidad hacia una reintegración efectiva a la sociedad.

Comprendo la importancia de las decisiones que se toman en estos procesos y agradezco profundamente la oportunidad de ser escuchado. Mi compromiso es seguir construyendo un futuro diferente, con respeto por la ley, por la vida y por la dignidad humana. Asimismo, manifiesto mi total disposición para acogerme a las condiciones que el despacho considere necesarias, incluyendo la realización de actividades de utilidad pública u obras sociales, como expresión concreta de mi voluntad de contribuir positivamente a la comunidad y reafirmar mi proceso de resocialización.
""";
  }




  String generarTextoPretencionesDesdeDatos(Ppl userData) {
    return """
PRIMERO: Que se tenga en cuenta la redención de pena que ya ha sido obtenida por el suscrito mediante actividades desarrolladas dentro del establecimiento penitenciario, y que se autorice, por parte del despacho, la verificación, validación y cómputo de las redenciones que aún se encuentren pendientes de aprobación, a fin de que sean sumadas al tiempo de reclusión efectiva para efectos del cálculo total del cumplimiento de la pena.

SEGUNDO: Que se conceda el beneficio de prisión domiciliaria, al cumplir con los requisitos del artículo 38G del Código Penal, demostrando arraigo familiar y social, así como cumplimiento parcial de la pena.

TERCERO: Que se autorice el traslado al lugar de residencia indicado en esta solicitud, bajo la supervisión de la persona responsable, quien ha aceptado formalmente asumir esta función.

""";
  }

  String generarTextoFundamentosDesdeDatos(
      Ppl userData,
      Map<String, dynamic> latestData,
      String parentesco,
      int mesesEjecutados,
      int diasEjecutados,
      ) {
    return """
1. Conforme a los artículos 97, 98 y 101 de la Ley 65 de 1993 (Código Penitenciario y Carcelario), las personas privadas de la libertad tienen derecho a redimir parte de su pena a través de actividades como el estudio, el trabajo y la participación en labores culturales o deportivas, previa autorización del centro penitenciario. Estos días redimidos deben ser sumados al tiempo efectivo de reclusión para efectos del cómputo del cumplimiento total de la pena y la evaluación de beneficios como la prisión domiciliaria.

2. Conforme a lo dispuesto en el artículo 38G del Código Penal, modificado por el artículo 4 de la Ley 1709 de 2014, el cumplimiento de la pena privativa de la libertad en lugar de residencia puede ser autorizado cuando se hayan cumplido los siguientes requisitos: haber purgado la mitad (½) de la pena impuesta, demostrar arraigo familiar y social, garantizar el cumplimiento de las obligaciones legales mediante caución, no pertenecer al núcleo familiar de la víctima y no haber sido condenado por delitos exceptuados.

3. Respecto al arraigo familiar y social exigido en los numerales 3° y 4° del artículo 38B del Código Penal, manifiesto que mantengo vínculos familiares y sociales sólidos, demostrando pertenencia e integración a un núcleo familiar en condiciones estables, conforme a la interpretación de la Corte Suprema de Justicia en las Sentencias de Casación Penal, Radicados 46647 de 2016 y 46930 de 2017.

4. No pertenezco al grupo familiar de la víctima, conforme a lo establecido en el numeral 5° del artículo 38G del Código Penal.

5. La sentencia dictada en mi contra no corresponde a ninguno de los delitos exceptuados para la concesión de este beneficio, de acuerdo con lo dispuesto en el mismo artículo 38G.

6. Esta fundamentación encuentra soporte adicional en el artículo 10 del Pacto Internacional de Derechos Civiles y Políticos, que establece el respeto de la dignidad humana y la finalidad de rehabilitación social de toda pena privativa de la libertad.
""";
  }


  String generarTextoAnexos(
      {
        required bool incluirPuntoHijos,
        required String reparacion,
        List<Map<String, dynamic>> hijos = const [],
        int cantidadDocumentos = 0,
      }) {
    final incluyeInsolvencia = reparacion == 'insolvencia';

    int contador = 1;

    final punto1 =
        "$contador. Declaración extrajuicio de la persona con la que conviviré durante el beneficio de prisión domiciliaria y quien asumirá la responsabilidad en caso de que me sea concedido dicho beneficio.";
    contador++;

    final punto2 = incluyeInsolvencia
        ? "${contador++}. Certificación de insolvencia económica."
        : null;

    final punto3 =
        "${contador++}. Fotocopia de la cédula de ciudadanía de la persona responsable.";

    final punto4 =
        "${contador++}. Fotocopia de un recibo de servicios públicos que demuestra la dirección de residencia.";

    String punto5 = '';
    if (incluirPuntoHijos && hijos.isNotEmpty) {
      final pluralDocs = cantidadDocumentos > 1;
      final pluralHijos = hijos.length > 1;
      final verboConvivir = pluralHijos ? 'conviven' : 'convive';

      final titulo =
          "$contador. Documento${pluralDocs ? 's' : ''} de mi ${pluralHijos ? 'hijos' : 'hijo'} que $verboConvivir conmigo durante el cumplimiento de la pena.";

      final listaHijos = hijos.map((h) {
        final nombre = h['nombre'] ?? 'Nombre no registrado';
        final edad = h['edad'] ?? 'Edad desconocida';
        return '• $nombre, de $edad años';
      }).join('\n');

      punto5 = "$titulo\n$listaHijos";
    }

    return [
      punto1,
      if (punto2 != null) punto2,
      punto3,
      punto4,
      if (punto5.isNotEmpty) punto5,
    ].join('\n\n');
  }

  void fetchDocumentoPrisionDomiciliaria() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('domiciliaria_solicitados')
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

  // corregido full
  Future<void> cargarSinopsis(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('domiciliaria_solicitados')
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
          .collection('domiciliaria_solicitados')
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
          .collection('domiciliaria_solicitados')
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
          .collection('domiciliaria_solicitados')
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
  //corregido full
  Future<void> cargarAnexos(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('domiciliaria_solicitados')
          .doc(docId)
          .get();

      if (doc.exists && !_isAnexosLoaded) {
        final data = doc.data() as Map<String, dynamic>?;

        final texto = data?['anexos'];
        if (texto != null && texto is String) {
          setState(() {
            _anexosController.text = texto;
            _isAnexosLoaded = true;
          });

          verificarVistaPrevia();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error cargando anexos: $e");
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

  Widget ingresarPruebas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ANEXOS",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _anexosController,
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


  Widget vistaPreviaPrisionDomiciliaria({
    required Ppl? userData,
    required String sinopsis,
    required String consideraciones,
    required String fundamentosDeDerecho,
    required String pretenciones,
    required String anexos,
    required String direccion,
    required String municipio,
    required String departamento,
    required String nombreResponsable,
    required String cedulaResponsable,
    required String celularResponsable,
    required String parentesco,
    required List<Map<String, String>>? hijos,
    required List<String>? documentosHijos,

  }) {
    final plantilla = PrisionDomiciliariaTemplate(
      dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
      entidad: entidad,
      referencia: "Beneficios penitenciarios - Prisión domiciliaria",
      nombrePpl: userData?.nombrePpl ?? "",
      apellidoPpl: userData?.apellidoPpl ?? "",
      identificacionPpl: userData?.numeroDocumentoPpl ?? "",
      centroPenitenciario: userData?.centroReclusion ?? "",
      sinopsis: convertirSaltosDeLinea(sinopsis),
      consideraciones: convertirSaltosDeLinea(consideraciones),
      fundamentosDeDerecho: convertirSaltosDeLinea(fundamentosDeDerecho),
      pretenciones: convertirSaltosDeLinea(pretenciones),
      anexos: convertirSaltosDeLinea(anexos),
      direccionDomicilio: direccion,
      municipio: municipio,
      departamento: departamento,
      nombreResponsable: nombreResponsable,
      parentesco: widget.parentesco,
      cedulaResponsable: cedulaResponsable,
      celularResponsable: celularResponsable,
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
      hijos:hijos,
      documentosHijos: documentosHijos,
    );


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vista previa de la solicitud de prisión domiciliaria",
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

  Future<void> enviarCorreoResend({required String correoDestino, String? asuntoPersonalizado, String? prefacioHtml}) async {
    final url = Uri.parse("https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/sendEmailWithResend");

    final doc = await FirebaseFirestore.instance
        .collection('domiciliaria_solicitados')
        .doc(widget.idDocumento)
        .get();

    final latestData = doc.data();
    if (latestData == null || userData == null) return;

      prisionDomiciliaria = PrisionDomiciliariaTemplate(
      dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
      entidad: entidad ?? "",
      referencia: "Beneficios penitenciarios - Prisión domiciliaria",
      nombrePpl: userData?.nombrePpl.trim() ?? "",
      apellidoPpl: userData?.apellidoPpl.trim() ?? "",
      identificacionPpl: userData?.numeroDocumentoPpl ?? "",
      centroPenitenciario: userData?.centroReclusion ?? "",
      sinopsis: sinopsis,
      consideraciones: consideraciones,
      fundamentosDeDerecho: fundamentosDeDerecho,
      pretenciones: pretenciones,
      anexos: anexos,
      direccionDomicilio: latestData['direccion'] ?? '',
      municipio: latestData['municipio'] ?? '',
      departamento: latestData['departamento'] ?? '',
      nombreResponsable: latestData['nombre_responsable'] ?? '',
      parentesco: widget.parentesco,
      cedulaResponsable: latestData['cedula_responsable'] ?? '',
      celularResponsable: latestData['celular_responsable'] ?? '',
      emailUsuario: userData?.email.trim() ?? '',
      nui: userData?.nui ?? '',
      td: userData?.td ?? '',
      patio: userData?.patio ?? '',
      radicado: userData?.radicado ?? '',
      delito: userData?.delito ?? '',
        condena: userData?.diasCondena != null && userData!.diasCondena! > 0
            ? "${userData?.mesesCondena ?? 0} meses y ${userData?.diasCondena} días"
            : "${userData?.mesesCondena ?? 0} meses",
      purgado: "${mesesEjecutado} meses y ${diasEjecutadoExactos} días",
      jdc: userData?.juzgadoQueCondeno ?? '',
      numeroSeguimiento: widget.numeroSeguimiento,
        hijos: solicitudData?.containsKey('hijos') == true
            ? List<Map<String, String>>.from(solicitudData!['hijos'].map((h) => Map<String, String>.from(h)))
            : [],
        documentosHijos: solicitudData?.containsKey('documentos_hijos') == true
            ? List<String>.from(solicitudData!['documentos_hijos'])
            : [],
    );


    String mensajeHtml = "${prefacioHtml ?? ''}${prisionDomiciliaria.generarTextoHtml()}";

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

    // 🔹 Archivos principales
    for (String archivoUrl in widget.archivos) {
      await procesarArchivo(archivoUrl);
    }

    // 🔹 Cédula del responsable
    if (widget.urlArchivoCedulaResponsable != null && widget.urlArchivoCedulaResponsable!.isNotEmpty) {
      await procesarArchivo(widget.urlArchivoCedulaResponsable!);
    }

    // 🔹 Documentos de los hijos
    for (String archivoHijo in widget.urlsArchivosHijos) {
      await procesarArchivo(archivoHijo);
    }

    final asuntoCorreo = asuntoPersonalizado ?? "Solicitud de Prisión Domiciliaria - ${widget.numeroSeguimiento}";
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
      "tipo": "domiciliaria",
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      await FirebaseFirestore.instance
          .collection('domiciliaria_solicitados')
          .doc(widget.idDocumento)
          .update({
        "status": "Enviado",
        "fechaEnvio": FieldValue.serverTimestamp(),
        "envió": adminFullName,
      });

      await ResumenSolicitudesHelper.actualizarResumen(
        idOriginal: widget.idDocumento,
        nuevoStatus: "Enviado",
        origen: "domiciliaria_solicitados",
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

        // Crear instancia de EnvioCorreoManager
        final envioCorreoManager = EnvioCorreoManagerV2();

        await envioCorreoManager.enviarCorreoCompleto(
          context: context,
          correoDestinoPrincipal: correoSeleccionado!,
          html: prisionDomiciliaria.generarTextoHtml(),
          numeroSeguimiento: prisionDomiciliaria.numeroSeguimiento,
          nombreAcudiente: userData?.nombreAcudiente ?? "Usuario",
          celularWhatsapp: userData?.celularWhatsapp,
          rutaHistorial: 'historial_solicitudes_prision_domiciliaria_admin',
          nombreServicio: "Prisión Domiciliaria",
          idDocumentoPpl: widget.idUser,

          // Nuevos campos requeridos
          centroPenitenciario: userData?.centroReclusion ?? 'Centro de reclusión',
          nombrePpl: userData?.nombrePpl ?? '',
          apellidoPpl: userData?.apellidoPpl ?? '',
          identificacionPpl: userData?.numeroDocumentoPpl ?? '',
          nui: userData?.nui ?? '',
          td: userData?.td ?? '',
          patio: userData?.patio ?? '',
          beneficioPenitenciario: "Prisión domiciliaria", // Puedes ajustar si se requiere algo más específico

          enviarCorreoResend: ({
            required String correoDestino,
            String? asuntoPersonalizado,
            String? prefacioHtml,
          }) async {
            await enviarCorreoResend(
              correoDestino: correoDestino,
              asuntoPersonalizado: asuntoPersonalizado,
              prefacioHtml: prefacioHtml,
            );
          },
          subirHtml: () async {
            await subirHtmlCorreoADocumentoDomiciliaria(
              idDocumento: widget.idDocumento,
              htmlContent: prisionDomiciliaria.generarTextoHtml(),
            );
          },
          buildSelectorCorreoCentroReclusion: ({
            required Function(String correo, String nombreCentro) onEnviarCorreo,
            required Function() onOmitir,
          }) {
            return SeleccionarCorreoCentroReclusionV2(
              idUser: widget.idUser,
              onEnviarCorreo: onEnviarCorreo,
              onOmitir: onOmitir,
            );
          },
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
              onOmitir: onOmitir,
            );
          },
        );
      },
      child: const Text("Enviar por correo"),
    );
  }

  Future<void> subirHtmlCorreoADocumentoDomiciliaria({
    required String idDocumento,
    required String htmlContent,
  }) async {
    try {
      // 🛠 Asegurar UTF-8 para que se vean bien las tildes y ñ
      final contenidoFinal = htmlUtf8Compatible(htmlContent);

      // 📁 Crear bytes
      final bytes = utf8.encode(contenidoFinal);
      const fileName = "correo.html";
      final filePath = "domiciliaria/$idDocumento/correos/$fileName"; // 🟣 Cambiar carpeta

      final ref = FirebaseStorage.instance.ref(filePath);
      final metadata = SettableMetadata(contentType: "text/html");

      // ⬆️ Subir archivo
      await ref.putData(Uint8List.fromList(bytes), metadata);

      // 🌐 Obtener URL
      final downloadUrl = await ref.getDownloadURL();

      // 🗃️ Guardar en Firestore
      await FirebaseFirestore.instance
          .collection("domiciliaria_solicitados") // 🟣 Cambiar colección
          .doc(idDocumento)
          .update({
        "correoHtmlUrl": downloadUrl,
        "fechaHtmlCorreo": FieldValue.serverTimestamp(),
      });

      print("✅ HTML de domiciliaria subido y guardado con URL: $downloadUrl");
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
              .collection('domiciliaria_solicitados')
              .doc(idDocumento)
              .update({
            "status": "Diligenciado",
            "diligencio": adminFullName,
            "fecha_diligenciamiento": FieldValue.serverTimestamp(),
            "sinopsis": _sinopsisController.text,
            "consideraciones": _consideracionesController.text,
            "fundamentos_de_derecho": _fundamentosDerechoController.text,
            "pretenciones": _pretencionesController.text,
            "anexos": _anexosController.text,
          });

          // 🔁 Actualizar también el resumen en solicitudes_usuario
          await ResumenSolicitudesHelper.actualizarResumen(
            idOriginal: idDocumento,
            nuevoStatus: "Diligenciado",
            origen: "domiciliaria_solicitados",
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
                  return const HistorialSolicitudesDomiciliariaAdminPage();
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
              .collection('domiciliaria_solicitados')
              .doc(idDocumento)
              .update({
            "status": "Revisado",
            "reviso": adminFullName,
            "fecha_revision": FieldValue.serverTimestamp(),
            "sinopsis": _sinopsisController.text,
            "consideraciones": _consideracionesController.text,
            "fundamentos_de_derecho": _fundamentosDerechoController.text,
            "pretenciones": _pretencionesController.text,
            "anexos": _anexosController.text,
          });

          await ResumenSolicitudesHelper.actualizarResumen(
            idOriginal: idDocumento,
            nuevoStatus: "Revisado",
            origen: "domiciliaria_solicitados",
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
                  return const HistorialSolicitudesDomiciliariaAdminPage();
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
