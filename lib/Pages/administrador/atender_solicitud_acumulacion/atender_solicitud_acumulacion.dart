
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/Pages/administrador/atender_solicitud_acumulacion/atender_solicitud_acumulacion_controller.dart';
import 'package:tuprocesoya/providers/ppl_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../commons/admin_provider.dart';
import '../../../commons/main_layaout.dart';
import '../../../controllers/tiempo_condena_controller.dart';
import '../../../helper/resumen_solicitudes_helper.dart';
import '../../../models/ppl.dart';
import '../../../plantillas/plantilla_acumulacion.dart';
import '../../../src/colors/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../widgets/datos_ejecucion_condena.dart';
import '../../../widgets/envio_correo_manager.dart';
import '../../../widgets/manager_correo_sin_reclusion.dart';
import '../../../widgets/manager_correo_sin_reclusion2.dart';
import '../../../widgets/seleccionar_correo_centro_copia_correo.dart';
import '../../../widgets/seleccionar_correo_centro_copia_correoV2.dart';
import '../../../widgets/selector_correo_manual.dart';
import '../historial_solicitudes_acumulacion_admin/historial_solicitudes_acumulacion_admin.dart';

class AtenderSolicitudAcumulacionPage extends StatefulWidget {
  final String status;
  final String idDocumento;
  final String numeroSeguimiento;
  final String fecha;
  final String idUser;

  const AtenderSolicitudAcumulacionPage({
    super.key,
    required this.status,
    required this.idDocumento,
    required this.numeroSeguimiento,
    required this.fecha,
    required this.idUser,
  });

  @override
  State<AtenderSolicitudAcumulacionPage> createState() => _AtenderSolicitudAcumulacionPageState();
}


class _AtenderSolicitudAcumulacionPageState extends State<AtenderSolicitudAcumulacionPage> {
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
  final AtenderSolicitudAcumulacionAdminController _controller = AtenderSolicitudAcumulacionAdminController();
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
  late SolicitudAcumulacionTemplate acumulacion;
  String asignadoA_P2 = '';
  String asignadoNombreP2 = '';
  DateTime? fechaAsignadoP2;
  Map<String, dynamic>? solicitudData;
  late CalculoCondenaController _calculoCondenaController;
  final TextEditingController _radicadoAcumularController = TextEditingController();
  final TextEditingController _juzgadoAcumularController = TextEditingController();
  String? ultimoHtmlEnviado;
  final List<_ProcesoAcumular> _procesos = [];



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _pplProvider = PplProvider();
    _calculoCondenaController = CalculoCondenaController(_pplProvider);
    fetchUserData();
    fetchDocumentoSolicitudAcumulacion();
    calcularTiempo(widget.idUser);
    adminFullName = AdminProvider().adminFullName ?? ""; // Nombre completo
    if (adminFullName.isEmpty) {
      if (kDebugMode) {
        print("❌ No se pudo obtener el nombre del administrador.");
      }
    }
    _procesos.add(_ProcesoAcumular(
      radicado: _radicadoAcumularController.text,
      juzgado: _juzgadoAcumularController.text,
    ));
    _cargarProcesosGuardados();
  }

  Future<void> _cargarProcesosGuardados() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('acumulacion_solicitados')
          .doc(widget.idDocumento)
          .get();

      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;

      // Liberar controladores actuales
      for (final p in _procesos) { p.dispose(); }
      _procesos.clear();

      // Arreglo nuevo (recomendado)
      final List<dynamic>? arr = data['procesosAcumular'] as List?;
      if (arr != null && arr.isNotEmpty) {
        for (final e in arr) {
          final m = (e as Map).map(
                (k, v) => MapEntry(k.toString(), (v ?? '').toString()),
          );
          _procesos.add(
            _ProcesoAcumular(
              radicado: m['radicado'] ?? '',
              juzgado : m['juzgado']  ?? '',
            ),
          );
        }
      } else {
        // Compatibilidad con los campos antiguos singulares
        final r = (data['radicadoAcumular'] ?? '').toString();
        final j = (data['juzgadoAcumular']  ?? '').toString();
        _procesos.add(_ProcesoAcumular(radicado: r, juzgado: j));
      }

      if (_procesos.isEmpty) _procesos.add(_ProcesoAcumular());

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error cargando procesos guardados: $e');
    }
  }


  @override
  void dispose() {
    for (final p in _procesos) {
      p.dispose();
    }
    super.dispose();
  }


  String obtenerNombreArchivo(String url) {
    // Decodifica la URL para que %2F se convierta en "/"
    String decodedUrl = Uri.decodeFull(url);
    // Separa por "/" y toma la última parte
    List<String> partes = decodedUrl.split('/');
    // El nombre real del archivo es la última parte después de la última "/"
    return partes.last.split('?').first; // Quita cualquier parámetro después de "?"
  }

  // void _cargarProcesosDesdeDoc(Map<String, dynamic> data) {
  //   _procesos.clear();
  //   final list = data['procesosAcumular'];
  //   if (list is List) {
  //     for (final e in list) {
  //       if (e is Map) _procesos.add(_ProcesoAcumular.fromMap(e));
  //     }
  //   }
  //   if (_procesos.isEmpty) {
  //     _procesos.add(_ProcesoAcumular()); // al menos una fila
  //   }
  //   setState(() {});
  // }


  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 1000;
    return MainLayout(
      pageTitle: 'Atender solicitud ACUMULACIÓN DE PENAS',
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
                "Solicitud Acumulación - ${widget.status}",
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

              // ---------------- Procesos a acumular (dinámico) ----------------
              const Text("Procesos a acumular", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              Column(
                children: [
                  for (int i = 0; i < _procesos.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Radicado
                          Expanded(
                            child: TextField(
                              controller: _procesos[i].radicadoCtrl,
                              decoration: const InputDecoration(
                                labelText: "Radicado del proceso",
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Juzgado
                          Expanded(
                            child: TextField(
                              controller: _procesos[i].juzgadoCtrl,
                              decoration: const InputDecoration(
                                labelText: "Juzgado de conocimiento",
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Eliminar fila
                          IconButton(
                            tooltip: "Eliminar",
                            onPressed: () {
                              setState(() {
                                _procesos.removeAt(i);
                                if (_procesos.isEmpty) _procesos.add(_ProcesoAcumular());
                              });
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),

                  // Agregar fila
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _procesos.add(_ProcesoAcumular()));
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Agregar proceso"),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Guardar todos los procesos en Firestore
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: _guardarProcesosAcumular, // ← guarda array + compat del primero
                      icon: const Icon(Icons.save_outlined),
                      label: const Text("Guardar procesos"),
                      style: ElevatedButton.styleFrom(
                        side: BorderSide(width: 1, color: Theme.of(context).primaryColor),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              // ---------------- /Procesos a acumular ----------------
            ],
          ),
        ),

        const SizedBox(height: 30),
        const Divider(color: gris),
        const SizedBox(height: 20),

        // ✅ Botón de vista previa
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
          vistaPreviaSolicitudAcumulacion(
            userData: userData,
          ),

        const SizedBox(height: 100),
      ],
    );
  }


  Future<void> _guardarProcesosAcumular() async {
    // Construye la lista filtrando vacíos
    final items = _procesos
        .map((p) => p.toMap())
        .where((m) => (m['radicado']?.isNotEmpty ?? false) || (m['juzgado']?.isNotEmpty ?? false))
        .toList();

    // (Opcional) asegúrate de mantener compatibilidad con el template actual (toma el primero)
    final String? firstRadicado = items.isNotEmpty ? items.first['radicado'] : null;
    final String? firstJuzgado  = items.isNotEmpty ? items.first['juzgado']  : null;

    await FirebaseFirestore.instance
        .collection('acumulacion_solicitados')
        .doc(widget.idDocumento)
        .set({
      'procesosAcumular': items,                // ⬅️ TODOS los pares
      'radicadoAcumular': firstRadicado,        // ⬅️ compat (si tu template usa solo uno)
      'juzgadoAcumular':  firstJuzgado,         // ⬅️ compat
      'procesosAcumular_updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Procesos guardados")),
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
              _buildDetalleItem("Subcategoría", "Solicitud acumulación", fontSize),
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
                  _buildDetalleItem("Subcategoría", "Solicitud acumulación", fontSize),
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
        .collection('acumulacion_solicitados')
        .doc(widget.idDocumento)
        .get();

    final latestData = doc.data();

    if (fetchedData != null && latestData != null && mounted) {
      // Calcular tiempo si aplica
      await calcularTiempo(widget.idUser);
      await _calculoCondenaController.calcularTiempo(widget.idUser);

      setState(() {
        userData = fetchedData;
        acumulacion = SolicitudAcumulacionTemplate(
          dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
          entidad: fetchedData.centroReclusion ?? "",
          referencia: "Solicitudes varias - Solicitud acumulacion",
          nombrePpl: fetchedData.nombrePpl?.trim() ?? "",
          apellidoPpl: fetchedData.apellidoPpl?.trim() ?? "",
          identificacionPpl: fetchedData.numeroDocumentoPpl ?? "",
          centroPenitenciario: fetchedData.centroReclusion ?? "",
          emailUsuario: fetchedData.email?.trim() ?? "",
          emailAlternativo: "peticiones@tuprocesoya.com",
          radicado: fetchedData.radicado ?? "",
          jdc: fetchedData.juzgadoQueCondeno ?? "",
          juzgadoEjecucion: fetchedData.juzgadoEjecucionPenas ?? "",
          numeroSeguimiento: widget.numeroSeguimiento,
          situacion: fetchedData.situacion ?? 'En Reclusión',
          nui: fetchedData.nui ?? "",
          td: fetchedData.td ?? "",
          patio: fetchedData.patio ?? "",

          radicadoAcumular: _radicadoAcumularController.text.trim(), // 🆕
          juzgadoAcumular: _juzgadoAcumularController.text.trim(),   // 🆕
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

  void fetchDocumentoSolicitudAcumulacion() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance

          .collection('acumulacion_solicitados')
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

            _radicadoAcumularController.text = data['radicado_proceso_acumular'] ?? '';
            _juzgadoAcumularController.text = data['juzgado_proceso_acumular'] ?? '';
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

  Widget vistaPreviaSolicitudAcumulacion({required Ppl? userData}) {
    // Si usas filas dinámicas (_procesos), tomamos en caliente lo escrito.
    final List<Map<String, String>> procesosUI = (_procesos)
        .map((p) => {
      'radicado': p.radicadoCtrl.text.trim(),
      'juzgado' : p.juzgadoCtrl.text.trim(),
    })
        .where((m) => m['radicado']!.isNotEmpty || m['juzgado']!.isNotEmpty)
        .toList();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('acumulacion_solicitados')
          .doc(widget.idDocumento)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text("No se encontró la solicitud de acumulacion.");
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        final plantilla = SolicitudAcumulacionTemplate(
          dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
          entidad: entidad,
          referencia: "Solicitudes varias - Solicitud acumulación",
          nombrePpl: userData?.nombrePpl ?? "",
          apellidoPpl: userData?.apellidoPpl ?? "",
          identificacionPpl: userData?.numeroDocumentoPpl ?? "",
          centroPenitenciario: userData?.centroReclusion ?? "",
          emailUsuario: userData?.email ?? "",
          emailAlternativo: "peticiones@tuprocesoya.com",
          radicado: userData?.radicado ?? "",
          jdc: userData?.juzgadoQueCondeno ?? "",
          juzgadoEjecucion: userData?.juzgadoEjecucionPenas ?? "",
          numeroSeguimiento: data['numero_seguimiento'] ?? "",
          situacion: userData?.situacion ?? 'En Reclusión',
          nui: userData?.nui ?? "",
          td: userData?.td ?? "",
          patio: userData?.patio ?? "",
          // Singulares (compat)
          radicadoAcumular: _radicadoAcumularController.text.trim(),
          juzgadoAcumular : _juzgadoAcumularController.text.trim(),
          // Lista dinámica (si hay)
          procesosAcumular: procesosUI.isEmpty ? null : procesosUI,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Vista previa de la solicitud de acumulación",
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

            // 👇 Tus botones, sin cambios
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
      },
    );
  }


  String convertirSaltosDeLinea(String texto) {
    return texto.replaceAll('\n', '<br>');
  }

  Future<void> enviarCorreoResend({
    required String correoDestino,
    String? asuntoPersonalizado,
    String? prefacioHtml,
    String? htmlCuerpo, // viene de la vista previa
  }) async {
    final url = Uri.parse(
      "https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/sendEmailWithResend",
    );

    final doc = await FirebaseFirestore.instance
        .collection('acumulacion_solicitados')
        .doc(widget.idDocumento)
        .get();

    final latestData = doc.data();
    if (latestData == null || userData == null) return;

    final fechaEnvioFormateada =
    DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now());
    final correoRemitente =
        FirebaseAuth.instance.currentUser?.email ?? adminFullName;
    final correoDestinatario = correoDestino;

    // 👉 Lee lo escrito en las filas dinámicas (por si no viene htmlCuerpo)
    final List<Map<String, String>> procesosUI = _procesos
        .map((p) => {
      'radicado': p.radicadoCtrl.text.trim(),
      'juzgado':  p.juzgadoCtrl.text.trim(),
    })
        .where((m) => m['radicado']!.isNotEmpty || m['juzgado']!.isNotEmpty)
        .toList();
    final Map<String, String>? first = procesosUI.isNotEmpty ? procesosUI.first : null;

    // 👉 Resuelve la entidad destino con fallback
    final entidadSel = obtenerEntidad(nombreCorreoSeleccionado ?? "");
    final entidadFinal = entidadSel.isNotEmpty
        ? entidadSel
        : (userData?.juzgadoEjecucionPenas ?? "Juzgado de ejecución de penas");

    // ⚠️ Usa el HTML EXACTO de la vista previa si llega; si no, genera uno con la lista
    final String cuerpoBase = htmlCuerpo ??
        SolicitudAcumulacionTemplate(
          dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
          entidad: entidadFinal,
          referencia: "Solicitudes varias - Solicitud acumulación",
          nombrePpl: userData?.nombrePpl.trim() ?? "",
          apellidoPpl: userData?.apellidoPpl.trim() ?? "",
          identificacionPpl: userData?.numeroDocumentoPpl ?? "",
          centroPenitenciario: userData?.centroReclusion ?? "",
          emailUsuario: userData?.email.trim() ?? "",
          emailAlternativo: "peticiones@tuprocesoya.com",
          radicado: userData?.radicado ?? "",
          jdc: userData?.juzgadoQueCondeno ?? "",
          juzgadoEjecucion: userData?.juzgadoEjecucionPenas ?? "",
          numeroSeguimiento: widget.numeroSeguimiento,
          situacion: userData?.situacion ?? 'En Reclusión',
          nui: userData?.nui ?? "",
          td: userData?.td ?? "",
          patio: userData?.patio ?? "",
          // compat + lista dinámica
          radicadoAcumular: first?['radicado'] ?? _radicadoAcumularController.text.trim(),
          juzgadoAcumular:  first?['juzgado']  ?? _juzgadoAcumularController.text.trim(),
          procesosAcumular: procesosUI.isEmpty ? null : procesosUI,
        ).generarTextoHtml();

    final mensajeHtml = """
<html>
  <body style="font-family: Arial, sans-serif; font-size: 10pt; color: #000; text-align:left;">
    <p style="margin: 2px 0;">De: peticiones@tuprocesoya.com</p>
    <p style="margin: 2px 0;">Para: $correoDestinatario</p>
    <p style="margin: 2px 0;">Fecha de Envío: $fechaEnvioFormateada</p>
    <hr style="margin: 8px 0; border: 0; border-top: 1px solid #ccc;">
    ${prefacioHtml ?? ''}$cuerpoBase
  </body>
</html>
""";

    // Guarda para el manager (copias/Storage)
    ultimoHtmlEnviado = mensajeHtml;

    final archivosBase64 = <Map<String, String>>[];

    final asuntoCorreo = asuntoPersonalizado ??
        "Solicitud de Acumulación de penas – ${widget.numeroSeguimiento}";

    final body = jsonEncode({
      "to": correoDestino,
      "cc": (userData?.email?.trim().isNotEmpty ?? false)
          ? [userData!.email.trim()]
          : [],
      "subject": asuntoCorreo,
      "html": mensajeHtml,
      "archivos": archivosBase64,
      "idDocumento": widget.idDocumento,
      "enviadoPor": correoRemitente,
      "tipo": "acumulacion",
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      await FirebaseFirestore.instance
          .collection('acumulacion_solicitados')
          .doc(widget.idDocumento)
          .update({
        "status": "Enviado",
        "fechaEnvio": FieldValue.serverTimestamp(),
        "envió": adminFullName,
      });
      await ResumenSolicitudesHelper.actualizarResumen(
        idOriginal: widget.idDocumento,
        nuevoStatus: "Enviado",
        origen: "acumulacion_solicitados",
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

        // 1) Dirigido + Entidad (según chip/selector)
        final String dirigido = obtenerTituloCorreo(nombreCorreoSeleccionado);
        final String entidadDestino =
            obtenerEntidad(nombreCorreoSeleccionado ?? "") ??
                (userData?.juzgadoEjecucionPenas ?? "Juzgado de ejecución de penas");

        final procesosUI = _leerProcesosUI();
        final first = (procesosUI.isNotEmpty) ? procesosUI.first : null;

        // 2) Generar el HTML BASE (solo el cuerpo; el “sobre” lo añade enviarCorreoResend)
        final acumulacion = SolicitudAcumulacionTemplate(
          dirigido: dirigido,
          entidad: entidadDestino,
          referencia: "Solicitudes varias - Solicitud acumulación",
          nombrePpl: userData?.nombrePpl.trim() ?? "",
          apellidoPpl: userData?.apellidoPpl.trim() ?? "",
          identificacionPpl: userData?.numeroDocumentoPpl ?? "",
          centroPenitenciario: userData?.centroReclusion ?? "",
          emailUsuario: userData?.email.trim() ?? "",
          emailAlternativo: "peticiones@tuprocesoya.com",
          radicado: userData?.radicado ?? "",
          jdc: userData?.juzgadoQueCondeno ?? "",
          juzgadoEjecucion: userData?.juzgadoEjecucionPenas ?? "",
          numeroSeguimiento: widget.numeroSeguimiento,
          situacion: userData?.situacion ?? 'En Reclusión',
          nui: userData?.nui ?? "",
          td: userData?.td ?? "",
          patio: userData?.patio ?? "",
          // compat: si no hay lista, usa los singulares
          radicadoAcumular: first?['radicado'] ?? _radicadoAcumularController.text.trim(),
          juzgadoAcumular:  first?['juzgado']  ?? _juzgadoAcumularController.text.trim(),
          // lista dinámica
          procesosAcumular: procesosUI.isEmpty ? null : procesosUI,
        );

        final String htmlActual = acumulacion.generarTextoHtml();

        // 3) Manager V4
        final envioCorreoManager = EnvioCorreoManagerV5();

        await envioCorreoManager.enviarCorreoCompleto(
          context: context,
          correoDestinoPrincipal: correoSeleccionado!,
          html: htmlActual, // cuerpo base
          numeroSeguimiento: acumulacion.numeroSeguimiento,
          nombreAcudiente: userData?.nombreAcudiente ?? "Usuario",
          celularWhatsapp: userData?.celularWhatsapp,
          rutaHistorial: 'historial_solicitudes_acumulacion_admin',
          nombreServicio: "Acumulación de Penas",

          // IDs
          idDocumentoSolicitud: widget.idDocumento,
          idDocumentoPpl: widget.idUser,

          // Compat por firma (el V4 no los usa, se pasan vacíos o con defaults)
          centroPenitenciario: userData?.centroReclusion ?? '',
          nombrePpl: userData?.nombrePpl ?? '',
          apellidoPpl: userData?.apellidoPpl ?? '',
          identificacionPpl: userData?.numeroDocumentoPpl ?? '',
          nui: userData?.nui ?? '',
          td: userData?.td ?? '',
          patio: userData?.patio ?? '',
          beneficioPenitenciario: '',
          juzgadoEp: userData?.juzgadoEjecucionPenas ?? '',

          // Rutas/colecciones
          nombrePathStorage: "acumulacion",
          nombreColeccionFirestore: "acumulacion_solicitados",

          // ⬇️ Firma ACTUALIZADA: acepta htmlCuerpo y lo propaga
          enviarCorreoResend: ({
            required String correoDestino,
            String? asuntoPersonalizado,
            String? prefacioHtml,
            String? htmlCuerpo, // <-- NUEVO EN LA FIRMA
          }) async {
            await enviarCorreoResend(
              correoDestino: correoDestino,
              asuntoPersonalizado: asuntoPersonalizado ??
                  "Solicitud de Acumulación de penas – ${widget.numeroSeguimiento}",
              prefacioHtml: prefacioHtml,
              htmlCuerpo: htmlCuerpo ?? htmlActual, // usa el de vista previa por defecto
            );
          },

          // Guardado por tipo. OJO: tu helper usa "htmlContent"
          subirHtml: ({
            required String tipoEnvio,
            required String htmlFinal,
            required String nombreColeccionFirestore,
            required String nombrePathStorage,
          }) async {
            await subirHtmlCorreoADocumentoSolicitudAcumulacion(
              idDocumento: widget.idDocumento,
              htmlContent: htmlFinal,
              tipoEnvio: tipoEnvio, // "principal" | "reparto"
            );
          },

          // El manager puede citar esto en “reparto”
          ultimoHtmlEnviado: htmlActual,

          // Centro NO aplica aquí (el V4 no lo usa)
          buildSelectorCorreoCentroReclusion: ({
            required Function(String correo, String nombreCentro) onEnviarCorreo,
            required Function() onOmitir,
          }) {
            return const SizedBox.shrink();
          },

          // Reparto (selector manual flexible)
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


  Future<void> subirHtmlCorreoADocumentoSolicitudAcumulacion({
    required String idDocumento,
    required String htmlContent,
    required String tipoEnvio, // "principal" | "reparto"
  }) async {
    try {
      // ✅ Forzar UTF-8 (tildes/ñ)
      final contenidoFinal = htmlUtf8Compatible(htmlContent);
      final bytes = utf8.encode(contenidoFinal);

      // 📁 Mismo patrón que Redenciones: un único archivo "correo.html"
      const fileName = "correo.html";
      final filePath = "acumulacion/$idDocumento/correos/$fileName";

      final ref = FirebaseStorage.instance.ref(filePath);
      final metadata = SettableMetadata(contentType: "text/html");

      // ⬆️ Subir archivo
      await ref.putData(Uint8List.fromList(bytes), metadata);

      // 🔗 URL pública
      final downloadUrl = await ref.getDownloadURL();

      // 🗃️ Guardar URL + fecha por tipo en Firestore (igual que Redenciones)
      await FirebaseFirestore.instance
          .collection("acumulacion_solicitados")
          .doc(idDocumento)
          .set({
        "correosGuardados.$tipoEnvio": downloadUrl,
        "fechaHtmlCorreo.$tipoEnvio": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print("✅ HTML $tipoEnvio guardado en: $downloadUrl");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error al subir HTML $tipoEnvio: $e");
      }
    }
  }

  List<Map<String, String>> _leerProcesosUI() {
    return _procesos
        .map((p) => {
      'radicado': p.radicadoCtrl.text.trim(),
      'juzgado':  p.juzgadoCtrl.text.trim(),
    })
        .where((m) => m['radicado']!.isNotEmpty || m['juzgado']!.isNotEmpty)
        .toList();
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
              .collection('acumulacion_solicitados')
              .doc(idDocumento)
              .update({
            "status": "Diligenciado",
            "diligencio": adminFullName,
            "fecha_diligenciamiento": FieldValue.serverTimestamp(),
            "radicado_proceso_acumular": _radicadoAcumularController.text.trim(),
            "juzgado_proceso_acumular": _juzgadoAcumularController.text.trim(),
          });

          // 🔁 Actualizar también el resumen en solicitudes_usuario
          await ResumenSolicitudesHelper.actualizarResumen(
            idOriginal: idDocumento,
            nuevoStatus: "Diligenciado",
            origen: "acumulacion_solicitados",
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
                  return const HistorialSolicitudesAcumulacionAdminPage();
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
              .collection('acumulacion_solicitados')
              .doc(idDocumento)
              .update({
            "status": "Revisado",
            "reviso": adminFullName,
            "fecha_revision": FieldValue.serverTimestamp(),
          });

          await ResumenSolicitudesHelper.actualizarResumen(
            idOriginal: idDocumento,
            nuevoStatus: "Revisado",
            origen: "acumulacion_solicitados",
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
                  return const HistorialSolicitudesAcumulacionAdminPage();
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

class _ProcesoAcumular {
  final TextEditingController radicadoCtrl;
  final TextEditingController juzgadoCtrl;

  _ProcesoAcumular({String? radicado, String? juzgado})
      : radicadoCtrl = TextEditingController(text: radicado ?? ''),
        juzgadoCtrl = TextEditingController(text: juzgado ?? '');

  Map<String, String> toMap() => {
    'radicado': radicadoCtrl.text.trim(),
    'juzgado': juzgadoCtrl.text.trim(),
  };

  factory _ProcesoAcumular.fromMap(Map<String, dynamic> m) =>
      _ProcesoAcumular(
        radicado: m['radicado']?.toString(),
        juzgado: m['juzgado']?.toString(),
      );

  void dispose() {
    radicadoCtrl.dispose();
    juzgadoCtrl.dispose();
  }
}

