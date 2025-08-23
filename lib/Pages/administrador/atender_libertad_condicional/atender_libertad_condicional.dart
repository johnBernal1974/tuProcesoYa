
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
import '../../../plantillas/plantilla_condicional.dart';
import '../../../src/colors/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../widgets/datos_ejecucion_condena.dart';
import '../../../widgets/envio_correo_managerV6.dart';
import '../../../widgets/seleccionar_correo_centro_copia_correoV2.dart';
import '../../../widgets/selector_correo_manual.dart';
import '../historial_solicitudes_libertad_condicional_admin/historial_solicitudes_libertad_condicional_admin.dart';
import 'atender_libertad_condicional_admin_controller.dart';

class AtenderLibertadCondicionalPage extends StatefulWidget {
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

  const AtenderLibertadCondicionalPage({
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
  State<AtenderLibertadCondicionalPage> createState() => _AtenderLibertadCondicionalPageState();
}

class _AtenderLibertadCondicionalPageState extends State<AtenderLibertadCondicionalPage> {
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
  final AtenderLibertadCondicionalAdminController _controller = AtenderLibertadCondicionalAdminController();
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
  late LibertadCondicionalTemplate libertadCondicional;
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

  ///NUEVOS PARA TODAS LAS PANTALLAS DE ATENDER
  String? correoManual;
  String? entidadSeleccionada;
  String? nombreCiudadSeleccionada;

  String? ultimoHtmlEnviado;



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
    fetchDocumentoLibertadCondicional();
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
      pageTitle: 'Atender solicitud LIBERTAD CONDICIONAL',
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
                    "Libertad Condicional",
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
                    "Libertad Condicional - ${widget.status}",
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
              ingresarAnexos(),
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
          vistaPreviaLibertadCondicional(
            userData: userData,
            sinopsis: _sinopsisController.text,
            consideraciones: _consideracionesController.text,
            fundamentosDeDerecho: _fundamentosDerechoController.text,
            pretenciones: _pretencionesController.text,
            anexos: _anexosController.text,
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
            const Text("Lugar registrado para la libertad condicional", style: TextStyle(fontSize: 12)),
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
              _buildDetalleItem("Subcategoría", "Libertad condicional", fontSize),
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
                  _buildDetalleItem("Subcategoría", "Libertad condicional", fontSize),
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
        .collection('condicional_solicitados')
        .doc(widget.idDocumento)
        .get();

    final latestData = doc.data();

    if (fetchedData != null && latestData != null && mounted) {
      // 🔥 Primero calcular correctamente los tiempos
      await _calculoCondenaController.calcularTiempo(widget.idUser);
      final diasRedimidos = _calculoCondenaController.totalDiasRedimidos ?? 0;

      // 🔥 Precargar campos
      _sinopsisController.text = generarTextoSinopsisDesdeDatos(
        fetchedData,
        fetchedData.situacion ?? 'En Reclusión',
        widget.reparacion,
        diasRedimidos,
      );

      if (!_isFundamentosLoaded) {
        _fundamentosDerechoController.text =
            generarTextoFundamentosDesdeDatos(fetchedData, latestData, widget.parentesco);
        _isFundamentosLoaded = true;
      }

      if (!_isPretencionesLoaded) {
        _pretencionesController.text =
            generarTextoPretencionesDesdeDatos(fetchedData.situacion ?? 'En Reclusión');
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
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
            : <Map<String, dynamic>>[];

        _anexosController.text = generarTextoAnexos(
          fetchedData.situacion ?? 'En Reclusión',
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

        _consideracionesController.text = generarTextoConsideracionesParaLibertadCondicional(
          direccion: widget.direccion,
          municipio: widget.municipio,
          departamento: widget.departamento,
          nombreResponsable: widget.nombreResponsable,
          parentescoResponsable: widget.parentesco,
          situacion: fetchedData?.situacion ?? 'En Reclusión',
          diasEjecutados: diasEjecutadoExactos + (mesesEjecutado * 30),
          diasRedimidos: diasRedimidos,
          hijos: listaHijos,
        );

        _isConsideracionesLoaded = true;
      }


      setState(() {
        userData = fetchedData;
        libertadCondicional = LibertadCondicionalTemplate(
          dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
          entidad: fetchedData.centroReclusion ?? "",
          referencia: "Beneficios penitenciarios - Libertad condicional",
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
      String reparacion,
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

  String generarTextoConsideracionesParaLibertadCondicional({
    required String direccion,
    required String municipio,
    required String departamento,
    required String nombreResponsable,
    required String parentescoResponsable,
    required String situacion,
    required int diasEjecutados,
    required int diasRedimidos,
    List<Map<String, String>> hijos = const [],
  }) {
    final totalDias = diasEjecutados + diasRedimidos;
    final mesesEjecutados = totalDias ~/ 30;
    final diasRestantes = totalDias % 30;

    // 🔹 Hijos
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
          "${esPlural ? "quienes son" : "quien es"} parte esencial de mi vida y ${esPlural ? "representan" : "representa"} mi principal motivación para continuar avanzando de manera positiva en mi proceso de resocialización.";
    }

    // 🔹 Texto para prisión domiciliaria
    if (situacion == "En Prisión domiciliaria") {
      return """
Honorable Juez, respetuosamente me permito solicitar la concesión del beneficio de libertad condicional, como una oportunidad para continuar con mi proceso de resocialización y reintegración a la sociedad en un entorno familiar estable y de apoyo.

Durante el tiempo que he permanecido en prisión domiciliaria, he mantenido un comportamiento ejemplar, cumpliendo con las condiciones impuestas, y participando activamente en mi proceso de resocialización y fortalecimiento familiar.

A la fecha, he cumplido $mesesEjecutados meses y $diasRestantes días de la condena, incluyendo el tiempo efectivo de reclusión y las redenciones obtenidas conforme a la ley. Con la aplicación del <b>Artículo 19 de la Ley 2466 de 2025</b>, se ha logrado avanzar de manera sustancial en el cómputo total de la pena, superando ampliamente el mínimo requerido para acceder al beneficio, y quedando muy cerca del cumplimiento total.

De ser concedido el beneficio, residiré en el domicilio ubicado en $direccion, en el municipio de $municipio, departamento de $departamento, bajo el cuidado y supervisión de $nombreResponsable, quien es mi $parentescoResponsable, y quien ha asumido el compromiso de acompañarme y garantizar que cumpla con todas las condiciones que se me impongan.$textoHijos

Esta solicitud representa para mí una oportunidad de inmenso valor para consolidar mi proceso de reintegración social y familiar, contribuyendo activamente a la construcción de un proyecto de vida digno y en libertad.
""";
    }

    // 🔹 Texto para reclusión
    return """
Honorable Juez.

Respetuosamente me permito solicitar que me sea reconocido y redimido el tiempo que se encuentra pendiente a mi favor, correspondiente a las actividades de trabajo, estudio o enseñanza que he desarrollado durante mi permanencia en el centro de reclusión.

A la fecha, he cumplido un total de $mesesEjecutados meses y $diasRestantes días de la pena impuesta, incluyendo el tiempo redimido que ya ha sido debidamente reconocido. Con la aplicación del <b>Artículo 19 de la Ley 2466 de 2025</b>, que establece la fórmula tres por dos (3x2) para redención, el cómputo total de pena ejecutada se incrementa significativamente, permitiendo superar ampliamente el sesenta por ciento (60%) exigido por la ley y quedando muy cerca del cumplimiento total.

En virtud de lo anterior, y conforme a los principios de legalidad y resocialización, solicito de manera respetuosa que me sea concedido el beneficio de libertad condicional, al considerar que cumplo con los requisitos establecidos en la normativa penal vigente. Esta solicitud se fundamenta en el avance efectivo del cumplimiento de la pena, así como en mi conducta, actitud frente al proceso de resocialización y compromiso con la reintegración social.

De ser concedido el beneficio, residiré en el domicilio ubicado en $direccion, en el municipio de $municipio, departamento de $departamento, bajo el cuidado y supervisión de $nombreResponsable, quien es mi $parentescoResponsable, y quien ha asumido el compromiso de acompañarme y garantizar que cumpla con todas las condiciones que se me impongan.$textoHijos

Su señoría, me dirijo a usted con profundo respeto y humildad, reconociendo el grave error que cometí y aceptando con entereza las consecuencias de mis actos. Pido perdón a Dios, a la sociedad colombiana, a la justicia y, sobre todo, a mi familia, quienes también han sufrido con el peso de mis decisiones.

Hoy me encuentro en un camino de reflexión y transformación personal. Cada día, desde mi reclusión, trabajo con honestidad por cambiar, crecer y reparar en lo posible el daño causado. Mi mayor anhelo es continuar este proceso desde el entorno familiar, rodeado del amor y el apoyo de mis seres queridos, quienes han sido mi principal contención emocional y motivación.

Solicito respetuosamente que sea estudiada la posibilidad de acceder al beneficio de libertad condicional, entendiendo que este paso no solo fortalecería mis vínculos familiares, sino que también sería un escenario más propicio para avanzar en mi proceso de resocialización, permitiéndome asumir con mayor responsabilidad mi reintegración efectiva a la sociedad.

Comprendo la importancia de las decisiones que se toman en estos procesos y agradezco profundamente la oportunidad de ser escuchado. Mi compromiso es seguir construyendo un futuro con libertad, con respeto por la ley y por la dignidad humana. Asimismo, manifiesto mi total disposición para acogerme a las condiciones que se estimen necesarias, incluyendo la realización de actividades de utilidad pública u obras sociales, como expresión concreta de voluntad de contribuir positivamente a la comunidad y reafirmar mi proceso de resocialización.
""";
  }



  String generarTextoPretencionesDesdeDatos(String situacion) {
    if (situacion == "En Prisión domiciliaria") {
      return """
PRIMERO: Que se reconozca que actualmente me encuentro cumpliendo mi condena bajo el beneficio de prisión domiciliaria, y que dicha situación refleja un proceso de resocialización anticipada, disciplina y arraigo familiar.

SEGUNDO: Que se autorice, conforme al artículo 19 de la Ley 2466 de 2025, el cómputo y aplicación de la redención de pena bajo la fórmula tres por dos (3x2), de acuerdo con los certificados laborales, educativos o de enseñanza debidamente emitidos por la autoridad penitenciaria.

TERCERO: Que se aplique el principio de favorabilidad penal consagrado en el artículo 29 de la Constitución Política, para la adopción inmediata de la normativa más beneficiosa contenida en la Ley 2466 de 2025, conforme al parágrafo segundo de su artículo 19, al artículo 6º del Código Penal y al artículo 38 numeral 7º de la Ley 906 de 2004.

CUARTO: Que, en virtud del cumplimiento de los requisitos establecidos en el artículo 64 de la Ley 65 de 1993 y del Código de Procedimiento Penal, se conceda el beneficio de libertad condicional.
""";
    }

    // Caso por defecto: En Reclusión
    return """
PRIMERO: Que se tenga en cuenta la redención de pena obtenida mediante actividades desarrolladas dentro del establecimiento penitenciario, y que se autorice por parte del despacho la verificación, validación y cómputo de las redenciones pendientes de aprobación, para que sean sumadas al tiempo de reclusión efectiva con el fin de completar el porcentaje requerido.

SEGUNDO: Que se aplique el artículo 19 de la Ley 2466 de 2025, autorizando el cómputo de redención conforme a la nueva fórmula tres por dos (3x2), reconociendo dichas actividades como experiencia laboral válida, en aplicación del principio de favorabilidad previsto en la Constitución, la ley penal y tratados internacionales.

TERCERO: Que se ordene al establecimiento penitenciario y carcelario, área jurídica, emitir la documentación correspondiente para el trámite de libertad condicional, conforme al artículo 471 del Código de Procedimiento Penal.

CUARTO: Que se conceda el beneficio de libertad condicional, por cumplir los requisitos legales establecidos en el artículo 64 de la Ley 65 de 1993, incluyendo el tiempo purgado, la conducta ejemplar y el arraigo familiar y social demostrado durante la ejecución de la pena.
""";
  }



  String generarTextoFundamentosDesdeDatos(
      Ppl userData,
      Map<String, dynamic> latestData,
      String parentesco,
      ) {
    final situacion = userData.situacion ?? 'En Reclusión';

    if (situacion == "En Prisión domiciliaria") {
      return """
1. Conforme al <b>Artículo 19 de la Ley 2466 de 2025</b>, incorporado mediante la Reforma Laboral, se establece que por cada <b>tres (3) días de trabajo</b> realizados por una persona privada de la libertad, se podrán redimir <b>dos (2) días de pena</b>. Esta norma reconoce además dichas actividades como <b>experiencia laboral válida</b>, siempre que sean certificadas por el INPEC o la autoridad penitenciaria correspondiente.

Esta modificación legislativa implica un cambio sustancial y favorable respecto al régimen anterior de redención, previsto en el artículo 82-2 de la Ley 65 de 1993. Por tanto, conforme al <b>parágrafo segundo del artículo 19 de la Ley 2466 de 2025</b>, y de acuerdo con el <b>numeral 7º del artículo 38 de la Ley 906 de 2004</b>, solicito que el Juez de Ejecución de Penas aplique el <b>principio de favorabilidad</b> contenido en el <b>artículo 29 de la Constitución</b>, en el <b>artículo 6º del Código Penal</b> y en tratados internacionales como el <b>Pacto Internacional de Derechos Civiles y Políticos</b> y la <b>Convención Americana sobre Derechos Humanos</b>.

La Corte Suprema de Justicia ha reiterado que la favorabilidad no es un problema de creación legislativa, sino de aplicación judicial frente a normas sucesivas. Por tanto, en este caso, corresponde aplicar de manera inmediata y retroactiva la fórmula 3x2, como más beneficiosa, al cómputo de pena ejecutada para acceder a la libertad condicional.

2. Conforme al artículo 64 del Código Penitenciario y Carcelario (Ley 65 de 1993), la libertad condicional es una forma de cumplimiento de la pena privativa de la libertad fuera del establecimiento carcelario, bajo vigilancia del Estado, cuando el condenado haya cumplido las tres quintas partes de la pena y demostrado buena conducta.

3. Actualmente me encuentro cumpliendo la condena bajo el beneficio de prisión domiciliaria, evidencia de mi proceso de resocialización anticipada, del arraigo demostrado en el entorno familiar y del cumplimiento disciplinado de las condiciones impuestas.

4. De acuerdo con los artículos 21 y 42 de la Constitución Política, el respeto a la dignidad humana y la protección de la familia respaldan la importancia de continuar con mi proceso de integración social en un ambiente de apoyo familiar.

5. El artículo 145 de la Ley 65 de 1993 establece que, cumplidos los requisitos de porcentaje de pena ejecutada, buena conducta y plan de resocialización, procede la concesión de la libertad condicional, requisitos que he satisfecho.

6. No pertenezco al núcleo familiar de la víctima y no he sido condenado por delitos excluidos para la procedencia del beneficio.

7. El artículo 10 del Pacto Internacional de Derechos Civiles y Políticos, ratificado por Colombia, dispone que las penas privativas de libertad deben tener como finalidad esencial la rehabilitación social, principio que respaldo mediante esta solicitud.
""";
    }

    // 🔹 Situación por defecto: En Reclusión
    return """
1. Conforme al <b>Artículo 19 de la Ley 2466 de 2025</b>, incluido en la Reforma Laboral, se establece que por cada <b>tres (3) días de trabajo</b> realizados por personas privadas de la libertad, se redimirán <b>dos (2) días de pena</b>. Esta medida, además de fortalecer el valor resocializador de dichas actividades, las reconoce como <b>experiencia laboral válida</b> siempre que estén certificadas por la autoridad penitenciaria competente.

Solicito que dicha norma sea aplicada conforme al <b>principio de favorabilidad</b>, previsto en el <b>artículo 29 de la Constitución Política</b>, el <b>artículo 6º del Código Penal (Ley 599 de 2000)</b>, el <b>numeral 7º del artículo 38 de la Ley 906 de 2004</b>, y en tratados internacionales como el <b>Pacto Internacional de Derechos Civiles y Políticos</b> y la <b>Convención Americana sobre Derechos Humanos</b>. 

La Corte Suprema de Justicia ha sostenido que el juez está facultado para aplicar retroactivamente normas más benéficas, incluso si son posteriores, siempre que impliquen una reducción, modificación o sustitución de la sanción penal. En consecuencia, se solicita la aplicación de la fórmula 3x2 de redención de pena establecida en la Ley 2466 de 2025 como parte del cómputo total para el beneficio de libertad condicional.

2. Conforme a los artículos 97, 98 y 101 de la Ley 65 de 1993 (Código Penitenciario y Carcelario), las personas privadas de la libertad tienen derecho a redimir parte de su pena a través de actividades como el estudio, el trabajo y la participación en labores culturales o deportivas, previa autorización del centro penitenciario. Estos días redimidos deben ser sumados al tiempo efectivo de reclusión para efectos de la evaluación de beneficios como la libertad condicional.

3. Conforme al artículo 64 del Código Penitenciario y Carcelario (Ley 65 de 1993), la libertad condicional es un mecanismo de cumplimiento de la pena bajo vigilancia estatal, aplicable a quienes hayan cumplido las tres quintas partes de la pena y demuestren buena conducta.

4. Durante mi permanencia en el centro de reclusión, he cumplido más del 60% de la pena impuesta, observando una conducta ejemplar, compromiso constante con procesos de resocialización, educación y trabajo, y respeto por las normas internas.

5. En atención a los artículos 21 y 42 de la Constitución Política, solicito el beneficio como medio para fortalecer el derecho fundamental a la dignidad humana y la importancia de la familia como núcleo esencial de la sociedad.

6. El artículo 145 de la Ley 65 de 1993 señala que cumplidos los requisitos de tiempo, comportamiento y plan de resocialización, es procedente acceder a la libertad condicional, condiciones que se reflejan en mi trayectoria penitenciaria.

7. No pertenezco al núcleo familiar de la víctima y no he sido condenado por delitos excluidos de este beneficio.

8. El artículo 10 del Pacto Internacional de Derechos Civiles y Políticos, ratificado por Colombia, resalta la necesidad de que la privación de la libertad tenga como fin principal la rehabilitación social, principio que oriento en mi solicitud.
""";
  }



  String generarTextoAnexos(
      String situacion, {
        required bool incluirPuntoHijos,
        required String reparacion,
        List<Map<String, dynamic>> hijos = const [],
        int cantidadDocumentos = 0,
      }) {
    final incluyeInsolvencia = reparacion == 'insolvencia';

    int contador = 1;

    final punto1 = "$contador. ${situacion == 'En Prisión domiciliaria'
        ? "Declaración extrajuicio de la persona con la que convivo actualmente durante el beneficio de prisión domiciliaria, y quien continuará como responsable en caso de otorgarse la libertad condicional."
        : "Declaración extrajuicio de la persona que me acogerá en el sitio de domicilio durante el beneficio de libertad condicional."}";
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
      final verboConvivir = situacion == 'En Prisión domiciliaria'
          ? (pluralHijos ? 'conviven' : 'convive')
          : (pluralHijos ? 'convivirán' : 'convivirá');

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
      if (punto5.isNotEmpty) punto5
    ].join('\n\n');
  }



  void fetchDocumentoLibertadCondicional() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('condicional_solicitados')
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
          .collection('condicional_solicitados')
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
          .collection('condicional_solicitados')
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
          .collection('condicional_solicitados')
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
          .collection('condicional_solicitados')
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
          .collection('condicional_solicitados')
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

  Widget ingresarAnexos() {
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


  Widget vistaPreviaLibertadCondicional({
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
    //usamos la misma plantilla que domiciliaria ya que es igual**
    final plantilla = LibertadCondicionalTemplate(
      dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
      entidad: entidad,
      referencia: "Beneficios penitenciarios - Libertad condicional",
      nombrePpl: userData?.nombrePpl ?? "",
      apellidoPpl: userData?.apellidoPpl ?? "",
      identificacionPpl: userData?.numeroDocumentoPpl ?? "",
      centroPenitenciario: userData?.centroReclusion ?? "",
      sinopsis: convertirSaltosDeLinea(_sinopsisController.text),
      consideraciones: convertirSaltosDeLinea(_consideracionesController.text),
      fundamentosDeDerecho: convertirSaltosDeLinea(_fundamentosDerechoController.text),
      pretenciones: convertirSaltosDeLinea(_pretencionesController.text),
      anexos: convertirSaltosDeLinea(_anexosController.text),
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
      situacion: userData?.situacion ?? 'En Reclusión',
    );


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vista previa de la solicitud de libertad condicional",
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

  Future<void> enviarCorreoResend({
    required String correoDestino,
    String? asuntoPersonalizado,
    String? prefacioHtml,
  }) async {
    final url = Uri.parse(
      "https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/sendEmailWithResend",
    );

    final doc = await FirebaseFirestore.instance
        .collection('condicional_solicitados')
        .doc(widget.idDocumento)
        .get();

    final latestData = doc.data();
    if (latestData == null || userData == null) return;

    final entidadSeleccionada = obtenerEntidad(nombreCorreoSeleccionado ?? "");
    final fechaEnvioFormateada =
    DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now());
    final correoRemitente =
        FirebaseAuth.instance.currentUser?.email ?? adminFullName;
    final correoDestinatario = correoDestino;

    // 🔹 Reconstituye la plantilla actualizando dirigido/entidad
    libertadCondicional = LibertadCondicionalTemplate(
      dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
      entidad: entidadSeleccionada,
      referencia: "Beneficios penitenciarios - Libertad condicional",
      nombrePpl: userData?.nombrePpl.trim() ?? "",
      apellidoPpl: userData?.apellidoPpl.trim() ?? "",
      identificacionPpl: userData?.numeroDocumentoPpl ?? "",
      centroPenitenciario: userData?.centroReclusion ?? "",
      sinopsis: sinopsis,
      consideraciones: consideraciones,
      fundamentosDeDerecho: fundamentosDeDerecho,
      pretenciones: pretenciones,
      anexos: anexos,

      // Domicilio / responsable desde la solicitud
      direccionDomicilio: latestData['direccion'] ?? '',
      municipio: latestData['municipio'] ?? '',
      departamento: latestData['departamento'] ?? '',
      nombreResponsable: latestData['nombre_responsable'] ?? '',
      parentesco: widget.parentesco,
      cedulaResponsable: latestData['cedula_responsable'] ?? '',
      celularResponsable: latestData['celular_responsable'] ?? '',

      emailUsuario: userData?.email.trim() ?? '',
      // emailAlternativo queda por defecto en la plantilla (si aplica)

      nui: userData?.nui ?? '',
      td: userData?.td ?? '',
      patio: userData?.patio ?? '',
      radicado: userData?.radicado ?? '',
      delito: userData?.delito ?? '',
      condena: (userData?.diasCondena != null && (userData!.diasCondena!) > 0)
          ? "${userData?.mesesCondena ?? 0} meses y ${userData?.diasCondena} días"
          : "${userData?.mesesCondena ?? 0} meses",
      purgado: "$mesesEjecutado meses y $diasEjecutadoExactos días",
      jdc: userData?.juzgadoQueCondeno ?? '',
      numeroSeguimiento: widget.numeroSeguimiento,

      hijos: solicitudData?.containsKey('hijos') == true
          ? List<Map<String, String>>.from(
        solicitudData!['hijos'].map((h) => Map<String, String>.from(h)),
      )
          : [],
      documentosHijos: solicitudData?.containsKey('documentos_hijos') == true
          ? List<String>.from(solicitudData!['documentos_hijos'])
          : [],
      situacion: userData?.situacion ?? 'En Reclusión',
    );

    // 🔹 HTML con encabezado unificado (De / Para / Fecha) + prefacio opcional + contenido
    final mensajeHtml = """
<html>
  <body style="font-family: Arial, sans-serif; font-size: 10pt; color: #000;">
    <p style="margin: 2px 0;">De: peticiones@tuprocesoya.com</p>
    <p style="margin: 2px 0;">Para: $correoDestinatario</p>
    <p style="margin: 2px 0;">Fecha de Envío: $fechaEnvioFormateada</p>
    <hr style="margin: 8px 0; border: 0; border-top: 1px solid #ccc;">
    ${prefacioHtml ?? ''}${libertadCondicional.generarTextoHtml()}
  </body>
</html>
""";

    // 🔹 Exponer el último HTML al manager V3
    ultimoHtmlEnviado = mensajeHtml;

    // 🔹 Adjuntos en base64
    final archivosBase64 = <Map<String, String>>[];

    Future<void> procesarArchivo(String urlArchivo) async {
      try {
        final nombreArchivo = obtenerNombreArchivo(urlArchivo);
        final response = await http.get(Uri.parse(urlArchivo));
        if (response.statusCode == 200) {
          final base64String = base64Encode(response.bodyBytes);
          archivosBase64.add({
            "nombre": nombreArchivo,
            "base64": base64String,
            "tipo": lookupMimeType(nombreArchivo) ?? "application/octet-stream",
          });
        }
      } catch (e) {
        if (kDebugMode) {
          print("❌ Error al procesar archivo $urlArchivo: $e");
        }
      }
    }

    // 🔹 Archivos principales
    for (final archivoUrl in widget.archivos) {
      await procesarArchivo(archivoUrl);
    }

    // 🔹 Cédula del responsable
    if ((widget.urlArchivoCedulaResponsable ?? '').isNotEmpty) {
      await procesarArchivo(widget.urlArchivoCedulaResponsable!);
    }

    // 🔹 Documentos de los hijos
    for (final archivoHijo in widget.urlsArchivosHijos) {
      await procesarArchivo(archivoHijo);
    }

    // 🔹 Enviar correo
    final asuntoCorreo = asuntoPersonalizado ??
        "Solicitud de Libertad Condicional - ${widget.numeroSeguimiento}";
    final enviadoPor = correoRemitente;

    final correosCC = <String>[];
    final correoUsuario = userData?.email?.trim();
    if (correoUsuario != null && correoUsuario.isNotEmpty) {
      correosCC.add(correoUsuario);
    }

    final body = jsonEncode({
      "to": correoDestino,
      "cc": correosCC,
      "subject": asuntoCorreo,
      "html": mensajeHtml,
      "archivos": archivosBase64,
      "idDocumento": widget.idDocumento,
      "enviadoPor": enviadoPor,
      "tipo": "condicional",
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      await FirebaseFirestore.instance
          .collection('condicional_solicitados')
          .doc(widget.idDocumento)
          .update({
        "status": "Enviado",
        "fechaEnvio": FieldValue.serverTimestamp(),
        "envió": adminFullName,
      });

      await ResumenSolicitudesHelper.actualizarResumen(
        idOriginal: widget.idDocumento,
        nuevoStatus: "Enviado",
        origen: "condicional_solicitados",
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

        // 🔹 Antes de generar el HTML, actualizamos dirigido y entidad
        libertadCondicional = LibertadCondicionalTemplate(
          dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
          entidad:  obtenerEntidad(nombreCorreoSeleccionado ?? ""),
          // 👇 el resto de campos los tomamos del objeto actual para no perder nada
          referencia:          libertadCondicional.referencia,
          nombrePpl:           libertadCondicional.nombrePpl,
          apellidoPpl:         libertadCondicional.apellidoPpl,
          identificacionPpl:   libertadCondicional.identificacionPpl,
          centroPenitenciario: libertadCondicional.centroPenitenciario,
          sinopsis:            libertadCondicional.sinopsis,
          consideraciones:     libertadCondicional.consideraciones,
          fundamentosDeDerecho:libertadCondicional.fundamentosDeDerecho,
          pretenciones:        libertadCondicional.pretenciones,
          anexos:              libertadCondicional.anexos,
          direccionDomicilio: libertadCondicional.direccionDomicilio,
          municipio: libertadCondicional.municipio,
          departamento: libertadCondicional.departamento,
          nombreResponsable: libertadCondicional.nombreResponsable,
          parentesco: libertadCondicional.parentesco,
          cedulaResponsable: libertadCondicional.cedulaResponsable,
          celularResponsable: libertadCondicional.celularResponsable,
          emailUsuario:        libertadCondicional.emailUsuario,
          emailAlternativo:    libertadCondicional.emailAlternativo,
          nui:                 libertadCondicional.nui,
          td:                  libertadCondicional.td,
          patio:               libertadCondicional.patio,
          radicado:            libertadCondicional.radicado,
          delito:              libertadCondicional.delito,
          condena:             libertadCondicional.condena,
          purgado:             libertadCondicional.purgado,
          jdc:                 libertadCondicional.jdc,
          numeroSeguimiento:   libertadCondicional.numeroSeguimiento,
          situacion:             userData?.situacion ?? 'EN RECLUSIÓN',
          hijos: libertadCondicional.hijos,
          documentosHijos: libertadCondicional.documentosHijos,
        );

        // ✅ HTML actualizado con entidad/dirigido correctos
        final ultimoHtmlEnviado = libertadCondicional.generarTextoHtml();

        final envioCorreoManager = EnvioCorreoManagerV6();

        // Lee la solicitud para obtener la cédula del acudiente
        final snap = await FirebaseFirestore.instance
            .collection("condicional_solicitados")        // usa la colección que corresponda a esa página
            .doc(widget.idDocumento)
            .get();

        final dataSol = snap.data() ?? {};
        final String identificacionAcudiente =
        (dataSol['cedula_responsable'] ?? '').toString().trim();


        if(context.mounted){
          await envioCorreoManager.enviarCorreoCompleto(
            context: context,
            correoDestinoPrincipal: correoSeleccionado!,
            html: ultimoHtmlEnviado,
            numeroSeguimiento: libertadCondicional.numeroSeguimiento,

            // 👤 Acudiente
            nombreAcudiente: userData?.nombreAcudiente ?? "Usuario",
            apellidoAcudiente: userData?.apellidoAcudiente ?? "",
            parentescoAcudiente: userData?.parentescoRepresentante ?? "Familiar",
            identificacionAcudiente: identificacionAcudiente,
            celularAcudiente: userData?.celular,

            // 📲 Notificación
            celularWhatsapp: userData?.celularWhatsapp,

            // 🧭 Navegación / etiquetas
            rutaHistorial: 'historial_solicitudes_libertad_condicional_admin',
            nombreServicio: "Libertad Condicional",

            // IDs
            idDocumentoSolicitud: widget.idDocumento,
            idDocumentoPpl: widget.idUser,

            // 🔹 nombres dinámicos (Firestore y Storage)
            nombreColeccionFirestore: "condicional_solicitados",
            nombrePathStorage: "condicional",

            // 🏛️ Datos PPL / Centro
            centroPenitenciario: userData?.centroReclusion ?? 'Centro de reclusión',
            nombrePpl: userData?.nombrePpl ?? '',
            apellidoPpl: userData?.apellidoPpl ?? '',
            identificacionPpl: userData?.numeroDocumentoPpl ?? '',
            nui: userData?.nui ?? '',
            td: userData?.td ?? '',
            patio: userData?.patio ?? '',
            beneficioPenitenciario: "Libertad condicional",
            juzgadoEp: userData?.juzgadoEjecucionPenas ?? "JUZGADO DE EJECUCIÓN DE PENAS",

            // ✉️ Envío (Resend)
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

            // 💾 Guardado HTML por tipo
            subirHtml: ({
              required String tipoEnvio,
              required String htmlFinal,
              required String nombreColeccionFirestore,
              required String nombrePathStorage,
            }) async {
              await subirHtmlCorreoADocumentoCondicional(
                idDocumento: widget.idDocumento,
                htmlFinal: htmlFinal,
                tipoEnvio: tipoEnvio, // "principal" | "centro_reclusion" | "reparto"
              );
            },

            // 🏢 Selector centro reclusión
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

            // 📨 Selector reparto
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

            // 🧾 El manager usará esto para citar/guardar
            ultimoHtmlEnviado: ultimoHtmlEnviado,
          );
        }
      },
      child: const Text("Enviar por correo"),
    );
  }


  Future<void> subirHtmlCorreoADocumentoCondicional({
    required String idDocumento,
    required String htmlFinal,
    required String tipoEnvio, // "principal", "centro_reclusion", "reparto"
  }) async {
    try {
      final contenidoFinal = htmlUtf8Compatible(htmlFinal);
      final bytes = utf8.encode(contenidoFinal);

      const fileName = "correo.html";
      final filePath = "condicional/$idDocumento/correos/$fileName"; // 🟣 Cambiar carpeta

      final ref = FirebaseStorage.instance.ref(filePath);
      final metadata = SettableMetadata(contentType: "text/html");


      await ref.putData(Uint8List.fromList(bytes), metadata);
      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection("condicional_solicitados")
          .doc(idDocumento)
          .set({
        "correosGuardados.$tipoEnvio": downloadUrl,
        "fechaHtmlCorreo.$tipoEnvio": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("✅ HTML $tipoEnvio guardado en: $downloadUrl");
    } catch (e) {
      print("❌ Error al subir HTML $tipoEnvio: $e");
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
              .collection('condicional_solicitados')
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
            origen: "condicional_solicitados",
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
                  return const HistorialSolicitudesCondicionalAdminPage();
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
              .collection('condicional_solicitados')
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
            origen: "condicional_solicitados",
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
                  return const HistorialSolicitudesCondicionalAdminPage();
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
