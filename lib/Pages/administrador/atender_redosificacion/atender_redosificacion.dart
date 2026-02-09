
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
import '../../../helper/resumen_solicitudes_helper.dart';
import '../../../models/ppl.dart';
import '../../../plantillas/plantilla_redosificacion.dart';
import '../../../src/colors/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../widgets/calculo_beneficios_penitenciarios-general.dart';
import '../../../widgets/datos_ejecucion_condena.dart';
import '../../../widgets/envio_correo_managerV3.dart';
import '../../../widgets/seleccionar_correo_centro_copia_correoV2.dart';
import '../../../widgets/selector_correo_manual.dart';
import '../historial_solicitudes_redosificacion_admin/historial_solicitudes_redosificacion_admin.dart';
import 'atender_redosificacion_controller.dart';

class AtenderSolicitudRedosificacionRedencionesPage extends StatefulWidget {
  final String status;
  final String idDocumento;
  final String numeroSeguimiento;
  final String fecha;
  final String idUser;
  final List<String> archivos; // 👈 CAMBIO: ahora es una lista

  const AtenderSolicitudRedosificacionRedencionesPage({
    super.key,
    required this.status,
    required this.idDocumento,
    required this.numeroSeguimiento,
    required this.fecha,
    required this.idUser,
    this.archivos = const [], // 👈 ya NO es required, y tiene valor por defecto
  });

  @override
  State<AtenderSolicitudRedosificacionRedencionesPage> createState() =>
      _AtenderSolicitudRedosificacionRedencionesPageState();
}



class _AtenderSolicitudRedosificacionRedencionesPageState extends State<AtenderSolicitudRedosificacionRedencionesPage> {
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
  final AtenderSolicitudRedosificacionRedencionesAdminController _controller = AtenderSolicitudRedosificacionRedencionesAdminController();
  String sinopsis = "";
  String consideraciones = "";
  String fundamentosDeDerecho = "";
  String pretenciones = "";
  bool _mostrarVistaPrevia = false;
  Map<String, String> correosCentro = {};
  late DocumentReference userDoc;
  String? correoSeleccionado= ""; // Guarda el correo seleccionado
  String? nombreCorreoSeleccionado;
  String idDocumento="";
  String adminFullName="";
  String entidad= "";
  String diligencio = '';
  String reviso = '';
  String envio = '';
  DateTime? fechaEnvio;
  DateTime? fechaDiligenciamiento;
  DateTime? fechaRevision;
  String rol = AdminProvider().rol ?? "";
  late SolicitudRedosificacionRedencionTemplate redosificacion;
  String asignadoA_P2 = '';
  String asignadoNombreP2 = '';
  DateTime? fechaAsignadoP2;
  Map<String, dynamic>? solicitudData;
  late CalculoCondenaController _calculoCondenaController;
  String? centroOrigenNombre;
  String? ciudadCentroOrigen;
  String? centroDestinoNombre;
  String? ciudadCentroDestino;

  String? ultimoHtmlEnviado;

  final TextEditingController consideracionesController = TextEditingController();
  final TextEditingController fundamentosController = TextEditingController();
  final TextEditingController pretencionesController = TextEditingController();
  bool _textoInicialPlantillaCargado = false;

  List<String> archivos = []; // URLs crudas desde Firestore
  List<Map<String, String>> archivosAdjuntos = []; // nombre + contenido (URL)



  static const String defaultConsideraciones = """
Solicito la aplicación del principio de favorabilidad conforme al artículo 19, parágrafo segundo, de la Ley 2466 de 2025, por tratarse de una norma posterior más beneficiosa en materia de redención de pena.

La nueva fórmula redentoria mejora de manera objetiva el régimen anterior y debe aplicarse tanto a las redenciones ya reconocidas, como a aquellas derivadas de actividades desarrolladas por la persona condenada que, siendo legalmente susceptibles de redención, aún no han sido objeto de reconocimiento.

En virtud del numeral 7 del artículo 38 de la Ley 906 de 2004, corresponde al Juez de Ejecución de Penas efectuar el cómputo integral de la redención conforme a la Ley 2466 de 2025, procediendo a la redosificación o al reconocimiento inicial del beneficio, según corresponda.
""";

  static const String defaultFundamentos = """
Conforme a lo dispuesto en el artículo 103A de la Ley 1709 de 2014, en armonía con el artículo 64 y el numeral 7 del artículo 38 de la Ley 906 de 2004, la persona condenada tiene derecho a solicitar la aplicación retroactiva de la Ley 2466 de 2025, en cuanto resulte más favorable a su situación jurídica.

El artículo 19 de la Ley 2466 de 2025 regula la redención de pena por trabajo, estableciendo que por cada tres (3) días de actividad se redimen dos (2) días de pena, lo cual representa una mejora sustancial frente al régimen anterior de redención.

No obstante, una interpretación constitucional, sistemática y jurisprudencial del ordenamiento penitenciario permite concluir que la redención de pena no se limita exclusivamente al trabajo, sino que comprende igualmente las actividades de estudio y enseñanza, en tanto todas ellas responden a la misma finalidad resocializadora y de reintegración social reconocida por la Constitución y la ley.

En ese sentido, el Tribunal Superior de Medellín – Sala Penal, en providencia con radicado 05-001-60-00000-2019-00867, de fecha 4 de septiembre de 2025, precisó que no puede existir trato desigual en materia de redención de pena, al reconocer que el trabajo, el estudio y la enseñanza generan la misma consecuencia jurídica, por lo cual los beneficios más favorables introducidos por el legislador deben extenderse a todas estas modalidades de redención.

Negar la aplicación del nuevo factor de redención a las actividades de estudio y enseñanza implicaría un trato discriminatorio injustificado y contrario al principio de igualdad, así como una vulneración directa del principio de favorabilidad, consagrado en el artículo 29 de la Constitución Política, desarrollado en el artículo 6 de la Ley 599 de 2000 y reforzado por instrumentos internacionales ratificados por Colombia, como el Pacto Internacional de Derechos Civiles y Políticos y la Convención Americana sobre Derechos Humanos.

En concordancia con lo anterior, la Corte Suprema de Justicia ha sostenido que el juez de ejecución de penas debe aplicar sin excepción la ley posterior más favorable a la persona condenada, atendiendo al análisis concreto del caso y al impacto real del beneficio en su situación jurídica, sin que dicha aplicación dependa de interpretaciones restrictivas o formales (CSJ, Sala Penal, Rad. 16837, M.P. Jorge Aníbal Gómez Gallego, 3 de septiembre de 2011).

En consecuencia, el factor de redención previsto en el artículo 19 de la Ley 2466 de 2025 debe aplicarse de manera extensiva y favorable a las actividades de trabajo, estudio y enseñanza, procediendo la redosificación de la pena conforme a dicho criterio.
""";


  static const String defaultPretenciones = """
PRIMERO:
Que se redosifique la redención de pena reconocida, dejando sin efecto los autos anteriores, y aplicando el artículo 19 de la Ley 2466 de 2025 bajo el principio de favorabilidad.

SEGUNDO:
Que se requiera al establecimiento penitenciario para la remisión de los certificados de trabajo, estudio y/o enseñanza desde el inicio de la condena.

TERCERO:
Que, con base en dichos certificados, se realice el cómputo conforme a la nueva fórmula legal de redención.
""";




  @override
  void initState() {
    super.initState();
    _pplProvider = PplProvider();
    _calculoCondenaController = CalculoCondenaController(_pplProvider);

    fetchUserData();
    fetchDocumentoSolicitudRedosificacionRedenciones();
    calcularTiempo(widget.idUser);

    adminFullName = AdminProvider().adminFullName ?? ""; // Nombre completo
    if (adminFullName.isEmpty) {
      if (kDebugMode) {
        print("❌ No se pudo obtener el nombre del administrador.");
      }
    }

    // 🔹 Cargar el nodo `archivos` de Firestore
    cargarArchivosDesdeFirestore();
  }

  Future<void> cargarArchivosDesdeFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('readecuacion_solicitados')
          .doc(widget.idDocumento)
          .get();

      if (!doc.exists) {
        if (kDebugMode) print("⚠️ Documento sin nodo 'archivos'");
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      if (data['archivos'] != null && data['archivos'] is List) {
        final List<dynamic> lista = data['archivos'];

        // Guarda las URLs puras
        archivos = lista.whereType<String>().toList();

        // Construye la lista para usar en adjuntos
        archivosAdjuntos = archivos.map((url) {
          return {
            "nombre": obtenerNombreArchivo(url),
            "contenido": url,
          };
        }).toList();

        if (mounted) setState(() {});
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error cargando archivos desde readecuacion_solicitados: $e");
      }
    }
  }

  Widget _buildArchivosAdjuntos() {
    if (archivos.isEmpty) {
      return const Text(
        "No hay archivos adjuntos",
        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Archivos Adjuntos",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        for (final url in archivos)
          GestureDetector(
            onTap: () => abrirArchivo(url),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade100,
              ),
              child: Row(
                children: [
                  Icon(
                    _iconoSegunArchivo(url),
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      obtenerNombreArchivo(url),
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.open_in_new, size: 18, color: Colors.black54),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void abrirArchivo(String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  IconData _iconoSegunArchivo(String url) {
    final ext = url.toLowerCase();

    if (ext.endsWith(".pdf")) return Icons.picture_as_pdf;
    if (ext.endsWith(".jpg") || ext.endsWith(".jpeg") || ext.endsWith(".png")) {
      return Icons.image;
    }
    if (ext.endsWith(".doc") || ext.endsWith(".docx")) return Icons.description;
    if (ext.endsWith(".xls") || ext.endsWith(".xlsx")) return Icons.grid_on;

    return Icons.attach_file;
  }






  // void cargarDatos() async {
  //   final doc = await FirebaseFirestore.instance
  //       .collection('readecuacion_solicitados')
  //       .doc(widget.numeroSeguimiento)
  //       .get();
  //
  //   if (doc.exists) {
  //     final data = doc.data() as Map<String, dynamic>;
  //
  //     consideracionesController.text =
  //     data['consideraciones']?.toString().trim().isNotEmpty == true
  //         ? data['consideraciones']
  //         : defaultConsideraciones;
  //
  //     fundamentosController.text =
  //     data['fundamentos']?.toString().trim().isNotEmpty == true
  //         ? data['fundamentos']
  //         : defaultFundamentos;
  //
  //     pretencionesController.text =
  //     data['pretenciones']?.toString().trim().isNotEmpty == true
  //         ? data['pretenciones']
  //         : defaultPretenciones;
  //   } else {
  //     // Si no existe el doc, llenar todo con los defaults
  //     consideracionesController.text = defaultConsideraciones;
  //     fundamentosController.text = defaultFundamentos;
  //     pretencionesController.text = defaultPretenciones;
  //   }
  //
  //   setState(() {});
  // }


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
      pageTitle: 'Atender solicitud REDOSIFICACIÓN DE REDENCION',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Solicitud Redosificación de redencion - ${widget.status}",
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
              _buildArchivosAdjuntos(),

            ],
          ),
        ),
        const SizedBox(height: 30),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Consideraciones",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: consideracionesController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "Escribe las consideraciones...",
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                disabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 20),
            const Text(
              "Fundamentos de Derecho",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: fundamentosController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "Escribe los fundamentos de derecho...",
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                disabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 20),
            const Text(
              "Pretenciones",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: pretencionesController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "Escribe las pretenciones...",
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                disabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 30),
          ],
        ),
        const SizedBox(height: 30),

        const Divider(color: gris),
        const SizedBox(height: 20),

        Row(
          children: [
            // 🔍 Botón Vista previa
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

            const SizedBox(width: 12),

            // 💾 Botón Guardar cambios (idéntico en estilo)
            ElevatedButton.icon(
              icon: Icon(Icons.save, color: Theme.of(context).primaryColor),
              label: const Text("Guardar cambios"),
              style: ElevatedButton.styleFrom(
                side: BorderSide(width: 1, color: Theme.of(context).primaryColor),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              onPressed: guardarCambios,
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (_mostrarVistaPrevia)
          vistaPreviaSolicitudRedosificacionRedenciones(
            userData: userData,
          ),

        const SizedBox(height: 100),
      ],
    );
  }

  void guardarCambios() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('readecuacion_solicitados') // ✅ Colección correcta
          .doc(widget.idDocumento);              // ✅ El ID de la solicitud

      await docRef.set({
        "consideraciones": consideracionesController.text.trim(),
        "fundamentos_derecho": fundamentosController.text.trim(), // 👈 nombre de campo correcto
        "pretenciones": pretencionesController.text.trim(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {}); // 🔁 refresca la UI (y la vista previa)

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cambios guardados correctamente"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al guardar: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
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
              _buildDetalleItem("Categoría", "Solicitudes varias", fontSize),
              const SizedBox(height: 5),
              _buildDetalleItem("Fecha de solicitud", _formatFecha(DateTime.tryParse(widget.fecha)), fontSize),
              const SizedBox(height: 5),
              _buildDetalleItem("Subcategoría", "Redosificación de redencion", fontSize),
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
                  _buildDetalleItem("Subcategoría", "Redosificación de redencion", fontSize),
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
    Ppl? fetchedData = await _pplProvider.getById(widget.idUser);

    final doc = await FirebaseFirestore.instance
        .collection('readecuacion_solicitados')
        .doc(widget.idDocumento)
        .get();

    final latestData = doc.data();

    if (fetchedData != null && latestData != null && mounted) {
      await calcularTiempo(widget.idUser);
      await _calculoCondenaController.calcularTiempo(widget.idUser);

      setState(() {
        userData = fetchedData;
        redosificacion = SolicitudRedosificacionRedencionTemplate(
          dirigido: "", // Se llenará al elegir correo
          entidad: "",  // Se llenará al elegir correo
          referencia: "Solicitudes varias - Solicitud Redosificación de redención",
          nombrePpl: fetchedData.nombrePpl?.trim() ?? "",
          apellidoPpl: fetchedData.apellidoPpl?.trim() ?? "",
          identificacionPpl: fetchedData.numeroDocumentoPpl ?? "",
          centroPenitenciario: fetchedData.centroReclusion ?? "",
          emailUsuario: fetchedData.email?.trim() ?? "",
          emailAlternativo: "peticiones@tuprocesoya.com",
          radicado: fetchedData.radicado ?? "",
          jdc: fetchedData.juzgadoQueCondeno ?? "",
          numeroSeguimiento: widget.numeroSeguimiento,
          situacion: fetchedData.situacion ?? 'En Reclusión',
          nui: fetchedData.nui ?? "",
          td: fetchedData.td ?? "",
          patio: fetchedData.patio ?? "",
          consideraciones: consideracionesController.text,
          fundamentosDeDerecho: fundamentosController.text,
          pretenciones: pretencionesController.text,
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

  void fetchDocumentoSolicitudRedosificacionRedenciones() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('readecuacion_solicitados') // ✅ Colección correcta
          .doc(widget.idDocumento)
          .get();

      if (documentSnapshot.exists) {
        Map<String, dynamic>? data = documentSnapshot.data() as Map<String, dynamic>?;

        solicitudData = data;

        if (data != null) {
          // ✅ Si el campo existe y no está vacío, se usa; si no, se usa el default
          final cons = data['consideraciones']?.toString().trim() ?? "";
          consideracionesController.text =
          cons.isNotEmpty ? cons : defaultConsideraciones;

          final fund = data['fundamentos_derecho']?.toString().trim() ?? "";
          fundamentosController.text =
          fund.isNotEmpty ? fund : defaultFundamentos;

          final pret = data['pretenciones']?.toString().trim() ?? "";
          pretencionesController.text =
          pret.isNotEmpty ? pret : defaultPretenciones;
        }

        if (data != null && mounted) {
          setState(() {
            diligencio = data['diligencio'] ?? 'No Diligenciado';
            reviso = data['reviso'] ?? 'No Revisado';
            envio = data['envió'] ?? 'No enviado';
            fechaEnvio = (data['fechaEnvio'] as Timestamp?)?.toDate();
            fechaDiligenciamiento =
                (data['fecha_diligenciamiento'] as Timestamp?)?.toDate();
            fechaRevision =
                (data['fecha_revision'] as Timestamp?)?.toDate();
            asignadoA_P2 = data['asignadoA_P2'] ?? '';
            asignadoNombreP2 = data['asignado_para_revisar'] ?? 'No asignado';
            fechaAsignadoP2 =
                (data['asignado_fecha_P2'] as Timestamp?)?.toDate();
          });
        }
      } else {
        if (kDebugMode) print("⚠️ Documento no encontrado en Firestore");

        // ✅ Si no existe el doc, usar siempre los defaults
        consideracionesController.text = defaultConsideraciones;
        fundamentosController.text = defaultFundamentos;
        pretencionesController.text = defaultPretenciones;

        setState(() {});
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

  Widget vistaPreviaSolicitudRedosificacionRedenciones({required Ppl? userData}) {
    if (userData == null) {
      return const Text("Cargando datos del usuario...");
    }

    final plantilla = SolicitudRedosificacionRedencionTemplate(
      dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
      entidad: entidad,
      referencia: "Solicitudes varias - Solicitud Readecuación redención",
      nombrePpl: userData.nombrePpl ?? "",
      apellidoPpl: userData.apellidoPpl ?? "",
      identificacionPpl: userData.numeroDocumentoPpl ?? "",
      centroPenitenciario: userData.centroReclusion ?? "",
      emailUsuario: userData.email ?? "",
      emailAlternativo: "peticiones@tuprocesoya.com",
      radicado: userData.radicado ?? "",
      jdc: userData.juzgadoQueCondeno ?? "",
      numeroSeguimiento: widget.numeroSeguimiento,
      situacion: userData.situacion ?? 'En Reclusión',
      nui: userData.nui ?? "",
      td: userData.td ?? "",
      patio: userData.patio ?? "",
      consideraciones: consideracionesController.text,       // 👈 SIEMPRE controllers
      fundamentosDeDerecho: fundamentosController.text,      // 👈
      pretenciones: pretencionesController.text,             // 👈
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vista previa de la solicitud de readecuación de redención",
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
            if (widget.status == "Solicitado")
              guardarVistaPrevia(widget.idDocumento),
            if ((widget.status == "Diligenciado" || widget.status == "Revisado") &&
                rol != "pasante 1") ...[
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
    String? prefacioHtml,
  }) async {
    final url = Uri.parse(
      "https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/sendEmailWithResend",
    );

    final doc = await FirebaseFirestore.instance
        .collection('readecuacion_solicitados')
        .doc(widget.idDocumento) // 🔹 ID de solicitud, no PPL
        .get();

    final latestData = doc.data();
    if (latestData == null || userData == null) return;

    final entidadSeleccionada = obtenerEntidad(nombreCorreoSeleccionado ?? "");
    final fechaEnvioFormateada = DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now());
    final correoRemitente = FirebaseAuth.instance.currentUser?.email ?? adminFullName;
    final correoDestinatario = correoDestino;

    final redosificacion = SolicitudRedosificacionRedencionTemplate(
      dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
      entidad: entidadSeleccionada,
      referencia: "Solicitudes varias - Solicitud redosificación redención",
      nombrePpl: userData?.nombrePpl.trim() ?? "",
      apellidoPpl: userData?.apellidoPpl.trim() ?? "",
      identificacionPpl: userData?.numeroDocumentoPpl ?? "",
      centroPenitenciario: userData?.centroReclusion ?? "",
      emailUsuario: userData?.email.trim() ?? "",
      emailAlternativo: "peticiones@tuprocesoya.com",
      radicado: userData?.radicado ?? "",
      jdc: userData?.juzgadoQueCondeno ?? "",
      numeroSeguimiento: widget.numeroSeguimiento,
      situacion: userData?.situacion ?? 'En Reclusión',
      nui: userData?.nui ?? "",
      td: userData?.td ?? "",
      patio: userData?.patio ?? "",
      consideraciones: consideracionesController.text,
      fundamentosDeDerecho: fundamentosController.text,
      pretenciones: pretencionesController.text,
    );

    // 🔹 Generar HTML final
    final mensajeHtml = """
<html>
  <body style="font-family: Arial, sans-serif; font-size: 10pt; color: #000;">
    <p style="margin: 2px 0;">De: peticiones@tuprocesoya.com</p>
    <p style="margin: 2px 0;">Para: $correoDestinatario</p>
    <p style="margin: 2px 0;">Fecha de Envío: $fechaEnvioFormateada</p>
    <hr style="margin: 8px 0; border: 0; border-top: 1px solid #ccc;">
    ${prefacioHtml ?? ''}${redosificacion.generarTextoHtml()}
  </body>
</html>
""";

    // 🔹 Guardar HTML en variable global/local para enviarlo al manager
    ultimoHtmlEnviado = mensajeHtml;

    // -----------------------------------------
    // 🧩 Adjuntar archivos desde el nodo `archivos`
    // -----------------------------------------
    final archivosBase64 = <Map<String, String>>[];

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
        } else {
          if (kDebugMode) {
            print("❌ Error HTTP al descargar archivo $urlArchivo: ${response.statusCode}");
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print("❌ Error al procesar archivo $urlArchivo: $e");
        }
      }
    }

    // 🔹 `archivos` debe ser una List<String> cargada en initState desde Firestore
    for (final url in archivos) {
      await procesarArchivo(url);
    }

    // -----------------------------------------
    // ✉️ Envío del correo
    // -----------------------------------------
    final asuntoCorreo = asuntoPersonalizado ??
        "Solicitud de Redosificación de Redención - ${widget.numeroSeguimiento}";
    final enviadoPor = correoRemitente;

    final correosCC = <String>[];
    if (userData?.email != null && userData!.email.trim().isNotEmpty) {
      correosCC.add(userData!.email.trim());
    }

    final body = jsonEncode({
      "to": correoDestino,
      "cc": correosCC,
      "subject": asuntoCorreo,
      "html": mensajeHtml,
      "archivos": archivosBase64,                 // 👈 Aquí van adjuntos
      "idDocumento": widget.idDocumento,          // 🔹 ID de solicitud
      "enviadoPor": enviadoPor,
      "tipo": "readecuacion",
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      await FirebaseFirestore.instance
          .collection('readecuacion_solicitados')
          .doc(widget.idDocumento)
          .update({
        "status": "Enviado",
        "fechaEnvio": FieldValue.serverTimestamp(),
        "envió": adminFullName,
        "consideraciones": consideracionesController.text,
        "fundamentos_derecho": fundamentosController.text,
        "pretenciones":  pretencionesController.text,
      });

      await ResumenSolicitudesHelper.actualizarResumen(
        idOriginal: widget.idDocumento,
        nuevoStatus: "Enviado",
        origen: "readecuacion_solicitados",
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
        redosificacion = SolicitudRedosificacionRedencionTemplate(
          dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
          entidad: obtenerEntidad(nombreCorreoSeleccionado ?? ""),
          referencia: redosificacion.referencia,
          nombrePpl: redosificacion.nombrePpl,
          apellidoPpl: redosificacion.apellidoPpl,
          identificacionPpl: redosificacion.identificacionPpl,
          centroPenitenciario: redosificacion.centroPenitenciario,
          emailUsuario: redosificacion.emailUsuario,
          emailAlternativo: redosificacion.emailAlternativo,
          radicado: redosificacion.radicado,
          jdc: redosificacion.jdc,
          numeroSeguimiento: redosificacion.numeroSeguimiento,
          situacion: redosificacion.situacion,
          nui: redosificacion.nui,
          td: redosificacion.td,
          patio: redosificacion.patio,
          consideraciones: consideracionesController.text,
          fundamentosDeDerecho: fundamentosController.text,
          pretenciones: pretencionesController.text,
        );

        // ✅ Ahora generas el HTML con la entidad y dirigido correctos
        final ultimoHtmlEnviado = redosificacion.generarTextoHtml();

        final envioCorreoManager = EnvioCorreoManagerV3();

        await envioCorreoManager.enviarCorreoCompleto(
          context: context,
          correoDestinoPrincipal: correoSeleccionado!,
          html: ultimoHtmlEnviado,
          numeroSeguimiento: redosificacion.numeroSeguimiento,
          nombreAcudiente: userData?.nombreAcudiente ?? "Usuario",
          celularWhatsapp: userData?.celularWhatsapp,
          rutaHistorial: 'historial_solicitudes_readecuacion_redenciones_admin',
          nombreServicio: "Redosificación de Redención",
          idDocumentoSolicitud: widget.idDocumento,
          idDocumentoPpl: userData!.id,
          nombreColeccionFirestore: "readecuacion_solicitados",
          nombrePathStorage: "readecuacion",

          centroPenitenciario: userData?.centroReclusion ?? 'Centro de reclusión',
          nombrePpl: userData?.nombrePpl ?? '',
          apellidoPpl: userData?.apellidoPpl ?? '',
          identificacionPpl: userData?.numeroDocumentoPpl ?? '',
          nui: userData?.nui ?? '',
          td: userData?.td ?? '',
          patio: userData?.patio ?? '',
          beneficioPenitenciario: "Redosificación de Redención",
          juzgadoEp: userData?.juzgadoEjecucionPenas ?? "JUZGADO DE EJECUCIÓN DE PENAS",

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

          subirHtml: ({
            required String tipoEnvio,
            required String htmlFinal,
            required String nombreColeccionFirestore,
            required String nombrePathStorage,
          }) async {
            await subirHtmlCorreoADocumentoSolicitudRedosificacion(
              idDocumento: widget.idDocumento,
              htmlFinal: htmlFinal,
              tipoEnvio: tipoEnvio,
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
              onOmitir: () => Navigator.of(context).pop(),
            );
          },

          ultimoHtmlEnviado: ultimoHtmlEnviado,
        );
      },
      child: const Text("Enviar por correo"),
    );
  }



  Future<void> subirHtmlCorreoADocumentoSolicitudRedosificacion({
    required String idDocumento,
    required String htmlFinal,
    required String tipoEnvio, // 🔹 "principal", "centro_reclusion", "reparto"
  }) async {
    try {
      final contenidoFinal = htmlUtf8Compatible(htmlFinal);
      final bytes = utf8.encode(contenidoFinal);

      final fileName = "correo_$tipoEnvio.html"; // 🔹 nombre distinto
      final filePath = "readecuacion/$idDocumento/correos/$fileName";

      final ref = FirebaseStorage.instance.ref(filePath);
      final metadata = SettableMetadata(contentType: "text/html");


      await ref.putData(Uint8List.fromList(bytes), metadata);

      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection("readecuacion_solicitados")
          .doc(idDocumento)
          .set({
        "correosGuardados.$tipoEnvio": downloadUrl, // 🔹 guarda por tipo
        "fechaHtmlCorreo.$tipoEnvio": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // 🔹 no sobreescribe todo el doc

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
              .collection('readecuacion_solicitados')
              .doc(idDocumento)
              .update({
            "status": "Diligenciado",
            "diligencio": adminFullName,
            "fecha_diligenciamiento": FieldValue.serverTimestamp(),
            "consideraciones": consideracionesController.text,
            "fundamentos_derecho": fundamentosController.text,
            "pretenciones": pretencionesController.text,

          });

          // 🔁 Actualizar también el resumen en solicitudes_usuario
          await ResumenSolicitudesHelper.actualizarResumen(
            idOriginal: idDocumento,
            nuevoStatus: "Diligenciado",
            origen: "readecuacion_solicitados",
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Solicitud marcada como diligenciada")),
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
                  return const HistorialSolicitudesRedosificacionRedencionesAdminPage();
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
              .collection('readecuacion_solicitados')
              .doc(idDocumento)
              .update({
            "status": "Revisado",
            "reviso": adminFullName,
            "fecha_revision": FieldValue.serverTimestamp(),
            "consideraciones": consideracionesController.text,
            "fundamentos_derecho": fundamentosController.text,
            "pretenciones": pretencionesController.text,


          });

          await ResumenSolicitudesHelper.actualizarResumen(
            idOriginal: idDocumento,
            nuevoStatus: "Revisado",
            origen: "readecuacion_solicitados",
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
                  return const HistorialSolicitudesRedosificacionRedencionesAdminPage();
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
