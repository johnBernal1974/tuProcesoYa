
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';

import '../../../commons/admin_provider.dart';
import '../../../commons/main_layaout.dart';
import '../../../helper/resumen_solicitudes_helper.dart';
import '../../../models/ppl.dart';
import '../../../plantillas/plantilla_asignacionTEE.dart';
import '../../../providers/ppl_provider.dart';
import '../../../widgets/email_status_widget.dart';
import 'atender_asignacion_tee_controller.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../widgets/envio_correo_manager_juzjado_conocimiento.dart';

import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class AtenderSolicitudAsignacionTEEPage extends StatefulWidget {
  final String status;
  final String idDocumento;
  final String numeroSeguimiento;
  final String fecha;
  final String idUser;

  const AtenderSolicitudAsignacionTEEPage({
    super.key,
    required this.status,
    required this.idDocumento,
    required this.numeroSeguimiento,
    required this.fecha,
    required this.idUser,
  });

  @override
  State<AtenderSolicitudAsignacionTEEPage> createState() =>
      _AtenderSolicitudAsignacionTEEPageState();
}

class _AtenderSolicitudAsignacionTEEPageState
    extends State<AtenderSolicitudAsignacionTEEPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PplProvider _pplProvider = PplProvider();

  final AtenderSolicitudAsignacionTEEAdminController _controller =
  AtenderSolicitudAsignacionTEEAdminController();

  Ppl? userData;
  Map<String, dynamic>? solicitudData;

  bool isLoading = true;
  bool _mostrarVistaPrevia = false;
  bool _procesando = false;

  String correoSeleccionado = '';
  String nombreCorreoSeleccionado = '';
  String entidad = '';
  String adminFullName = '';
  String rol = '';

  String statusActual = '';
  String diligencio = '';
  String reviso = '';
  String envio = '';
  String asignadoNombreP2 = '';

  DateTime? fechaDiligenciamiento;
  DateTime? fechaRevision;
  DateTime? fechaEnvio;
  DateTime? fechaAsignadoP2;

  Map<String, String> correosCentro = {};

  bool _solicitudPorAbogado = false;

  final TextEditingController _nombreAbogadoController =
  TextEditingController();

  final TextEditingController _tarjetaAbogadoController =
  TextEditingController();

  final TextEditingController _cedulaAbogadoController =
  TextEditingController();

  Uint8List? _poderPdfBytes;
  String? _poderPdfNombre;

  Uint8List? _documentosAbogadoPdfBytes;
  String? _documentosAbogadoPdfNombre;

  String? _poderGuardadoNombre;
  String? _poderGuardadoPath;
  String? _documentosAbogadoGuardadoNombre;
  String? _documentosAbogadoGuardadoPath;

  Future<void> _guardarPoderEnStorage() async {
    if (_poderPdfBytes == null || _poderPdfNombre == null) return;

    final path =
        'asignacionTEE/${widget.idDocumento}/adjuntos/poder_${DateTime.now().millisecondsSinceEpoch}.pdf';

    final ref = FirebaseStorage.instance.ref(path);

    await ref.putData(
      _poderPdfBytes!,
      SettableMetadata(contentType: 'application/pdf'),
    );

    await _firestore
        .collection('asignacionTEE_solicitados')
        .doc(widget.idDocumento)
        .update({
      'poderPdfNombre': _poderPdfNombre,
      'poderPdfPath': path,
      'poderPdfFecha': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      setState(() {
        _poderGuardadoNombre = _poderPdfNombre;
        _poderGuardadoPath = path;
      });
    }
  }

  Future<void> _abrirPoderGuardado() async {
    final path = _poderGuardadoPath;
    if (path == null || path.isEmpty) return;

    try {
      final url = await FirebaseStorage.instance
          .ref(path)
          .getDownloadURL();

      final abierto = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      if (!abierto) {
        throw Exception('No se pudo abrir el documento.');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir el poder: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _mostrarDocumentosAdjuntos() {
    final documentos = <Map<String, String>>[];

    if (_poderGuardadoPath != null &&
        _poderGuardadoPath!.isNotEmpty) {
      documentos.add({
        'titulo': 'Poder',
        'nombre': _poderGuardadoNombre ?? 'Poder.pdf',
        'path': _poderGuardadoPath!,
      });
    }

    if (_documentosAbogadoGuardadoPath != null &&
        _documentosAbogadoGuardadoPath!.isNotEmpty) {
      documentos.add({
        'titulo': 'Documentos del abogado',
        'nombre': _documentosAbogadoGuardadoNombre ??
            'Documentos_abogado.pdf',
        'path': _documentosAbogadoGuardadoPath!,
      });
    }

    if (documentos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Documentos adjuntos al correo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            ...documentos.map((documento) {
              return ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red,
                  size: 32,
                ),
                title: Text(documento['titulo']!),
                subtitle: Text(documento['nombre']!),
                trailing: const Icon(Icons.visibility_outlined),
                onTap: () async {
                  try {
                    final url = await FirebaseStorage.instance
                        .ref(documento['path']!)
                        .getDownloadURL();

                    final abierto = await launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    );

                    if (!abierto) {
                      throw Exception('No se pudo abrir el PDF.');
                    }
                  } catch (e) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al abrir el PDF: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarPoderPdf() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (resultado == null) return;

    final archivo = resultado.files.single;

    if (archivo.bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo leer el archivo PDF.'),
        ),
      );
      return;
    }

    setState(() {
      _poderPdfBytes = archivo.bytes;
      _poderPdfNombre = archivo.name;
    });
  }

  Future<void> _seleccionarDocumentosAbogadoPdf() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (resultado == null) return;

    final archivo = resultado.files.single;

    if (archivo.bytes == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo leer el PDF del abogado.'),
        ),
      );
      return;
    }

    setState(() {
      _documentosAbogadoPdfBytes = archivo.bytes;
      _documentosAbogadoPdfNombre = archivo.name;
    });
  }

  Widget botonAdjuntarPoderTEE() {
    if (!_solicitudPorAbogado) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _procesando ? null : _seleccionarPoderPdf,
          icon: const Icon(Icons.attach_file),
          label: const Text('Adjuntar poder (PDF)'),
        ),
        if (_poderPdfNombre != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf, color: Colors.red),
              const SizedBox(width: 6),
              Flexible(child: Text(_poderPdfNombre!)),
              IconButton(
                tooltip: 'Quitar poder',
                onPressed: _procesando
                    ? null
                    : () {
                  setState(() {
                    _poderPdfBytes = null;
                    _poderPdfNombre = null;
                  });
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),

        const SizedBox(height: 12),

        OutlinedButton.icon(
          onPressed: _procesando
              ? null
              : _seleccionarDocumentosAbogadoPdf,
          icon: const Icon(Icons.attach_file),
          label: const Text('Adjuntar documentos del abogado (PDF)'),
        ),

        if (_documentosAbogadoPdfNombre != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf, color: Colors.red),
              const SizedBox(width: 6),
              Flexible(
                child: Text(_documentosAbogadoPdfNombre!),
              ),
              IconButton(
                tooltip: 'Quitar documentos del abogado',
                onPressed: _procesando
                    ? null
                    : () {
                  setState(() {
                    _documentosAbogadoPdfBytes = null;
                    _documentosAbogadoPdfNombre = null;
                  });
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    adminFullName = AdminProvider().adminFullName ?? '';
    rol = AdminProvider().rol ?? '';
    statusActual = widget.status;

    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final resultados = await Future.wait([
        _pplProvider.getById(widget.idUser),

        _firestore
            .collection('asignacionTEE_solicitados')
            .doc(widget.idDocumento)
            .get(),

        _firestore
            .collection('Ppl')
            .doc(widget.idUser)
            .collection('correos_centro_reclusion')
            .doc('emails')
            .get(),
      ]);

      final ppl = resultados[0] as Ppl?;

      final documento =
      resultados[1] as DocumentSnapshot<Map<String, dynamic>>;

      final documentoCorreos =
      resultados[2] as DocumentSnapshot<Map<String, dynamic>>;

      final data = documento.data();
      final datosCorreos = documentoCorreos.data() ?? {};

      if (!mounted) return;

      setState(() {
        userData = ppl;
        solicitudData = data;

        _poderGuardadoNombre = data?['poderPdfNombre'] as String?;
        _poderGuardadoPath = data?['poderPdfPath'] as String?;

        _documentosAbogadoGuardadoNombre =
        data?['documentosAbogadoPdfNombre'] as String?;

        _documentosAbogadoGuardadoPath =
        data?['documentosAbogadoPdfPath'] as String?;

        // Correos institucionales del INPEC
        correosCentro = {
          'correo_direccion':
          (datosCorreos['correo_direccion'] ?? '').toString(),
          'correo_juridica':
          (datosCorreos['correo_juridica'] ?? '').toString(),
          'correo_principal':
          (datosCorreos['correo_principal'] ?? '').toString(),
          'correo_sanidad':
          (datosCorreos['correo_sanidad'] ?? '').toString(),
        };

        statusActual = data?['status'] ?? widget.status;
        diligencio = data?['diligencio'] ?? '';
        reviso = data?['reviso'] ?? '';
        envio = data?['envió'] ?? '';

        asignadoNombreP2 =
            data?['asignado_para_revisar'] ?? '';

        fechaDiligenciamiento =
            (data?['fecha_diligenciamiento'] as Timestamp?)?.toDate();

        fechaRevision =
            (data?['fecha_revision'] as Timestamp?)?.toDate();

        fechaEnvio =
            (data?['fechaEnvio'] as Timestamp?)?.toDate();

        fechaAsignadoP2 =
            (data?['asignado_fecha_P2'] as Timestamp?)?.toDate();

        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando solicitud TEE: $e');

      if (mounted) {
        setState(() => isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar la solicitud TEE'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nombreAbogadoController.dispose();
    _tarjetaAbogadoController.dispose();
    _cedulaAbogadoController.dispose();
    super.dispose();
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Sin registrar';

    return DateFormat(
      "dd 'de' MMMM 'de' yyyy - hh:mm a",
      'es',
    ).format(fecha);
  }

  String obtenerTituloCorreo(String nombre) {
    switch (nombre) {
      case 'Director':
        return 'Señor\nDirector';
      case 'Jurídica':
        return 'Señores Oficina Jurídica';
      case 'Principal':
        return 'Señores';
      default:
        return 'Señor\nDirector';
    }
  }

  String obtenerEntidad(String nombre) {
    return userData?.centroReclusion ?? '';
  }

  SolicitudAsignacionTEETemplate _crearPlantilla() {
    final ppl = userData!;

    return SolicitudAsignacionTEETemplate(
      solicitudPorAbogado: _solicitudPorAbogado,
      nombreAbogado: _nombreAbogadoController.text.trim(),
      cedulaAbogado: _cedulaAbogadoController.text.trim(),
      tarjetaProfesionalAbogado: _tarjetaAbogadoController.text.trim(),
      dirigido: obtenerTituloCorreo(nombreCorreoSeleccionado),
      entidad: entidad,
      referencia:
      'Solicitudes varias - Asignación de Trabajo, Estudio y Enseñanza',
      nombrePpl: ppl.nombrePpl,
      apellidoPpl: ppl.apellidoPpl,
      identificacionPpl: ppl.numeroDocumentoPpl,
      centroPenitenciario: ppl.centroReclusion,
      emailUsuario: ppl.email,
      emailAlternativo: 'peticiones@tuprocesoya.com',
      radicado: ppl.radicado,
      jdc: ppl.juzgadoQueCondeno,
      numeroSeguimiento: widget.numeroSeguimiento,
      situacion: ppl.situacion,
      nui: ppl.nui,
      td: ppl.td,
      patio: ppl.patio,
    );
  }

  Color _obtenerColorFondo(String status) {
    switch (status) {
      case 'Solicitado':
        return const Color(0xFFFFF5F5);

      case 'Diligenciado':
        return const Color(0xFFFFFBEA);

      case 'Revisado':
        return const Color(0xFFF5EAFE);

      default:
        return const Color(0xFFFAFAFA);
    }
  }

  Widget _detalle(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolicitadoPor() {
    return _detalle(
      'Solicitado por:',
      '${userData?.nombreAcudiente ?? ''} '
          '${userData?.apellidoAcudiente ?? ''}',
    );
  }

  Widget _buildDetallesSolicitud() {
    return Wrap(
      spacing: 35,
      runSpacing: 10,
      children: [
        _detalle(
          'Número de seguimiento',
          widget.numeroSeguimiento,
        ),
        _detalle(
          'Categoría',
          'Solicitudes varias',
        ),
        _detalle(
          'Subcategoría',
          'Asignación TEE',
        ),
        _detalle(
          'Fecha de solicitud',
          _formatearFecha(DateTime.tryParse(widget.fecha)),
        ),
      ],
    );
  }

  Widget infoAccionesAdmin() {
    if (diligencio.isEmpty &&
        reviso.isEmpty &&
        envio.isEmpty &&
        asignadoNombreP2.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historial de acciones',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (asignadoNombreP2.isNotEmpty)
              _detalle(
                'Asignado para revisar',
                '$asignadoNombreP2 - '
                    '${_formatearFecha(fechaAsignadoP2)}',
              ),

            if (diligencio.isNotEmpty)
              _detalle(
                'Diligenció',
                '$diligencio - '
                    '${_formatearFecha(fechaDiligenciamiento)}',
              ),

            if (reviso.isNotEmpty)
              _detalle(
                'Revisó',
                '$reviso - ${_formatearFecha(fechaRevision)}',
              ),

            if (envio.isNotEmpty)
              _detalle(
                'Envió',
                '$envio - ${_formatearFecha(fechaEnvio)}',
              ),

            _detalle(
              'ID del documento',
              widget.idDocumento,
            ),
          ],
        ),
      ),
    );
  }

  Widget correoConBoton(String nombre, String? correo) {
    final seleccionado = nombre == nombreCorreoSeleccionado;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: seleccionado
            ? Colors.green.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$nombre: ${correo ?? ''}',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                correoSeleccionado = correo ?? '';
                nombreCorreoSeleccionado = nombre;
                entidad = obtenerEntidad(nombre);
              });
            },
            child: Text(
              seleccionado ? 'Elegido' : 'Elegir',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraWidget() {
    // =====================================================
    // SOLICITUD ENVIADA: MOSTRAR SOLO ESTADO DEL CORREO
    // =====================================================
    if (statusActual == 'Enviado') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 21,
                  color: Colors.black87,
                ),
                SizedBox(width: 8),
                Text(
                  'Estado del envío',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            ListaCorreosWidget(
              solicitudId: widget.idDocumento,
              nombreColeccion: 'asignacionTEE_solicitados',
              onTapCorreo: (correoId) {
                _mostrarContenidoCorreo(correoId);
              },
            ),
          ],
        ),
      );
    }

    // =====================================================
    // SOLICITUD NO ENVIADA: MOSTRAR DATOS GENERALES
    // =====================================================
    final ppl = userData;

    if (ppl == null) {
      return const Text('No se encontraron datos del PPL.');
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos generales del PPL',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          _detalle('Nombre', ppl.nombrePpl),
          _detalle('Apellido', ppl.apellidoPpl),
          _detalle(
            'Documento',
            '${ppl.tipoDocumentoPpl} ${ppl.numeroDocumentoPpl}',
          ),
          _detalle(
            'Centro penitenciario',
            ppl.centroReclusion,
          ),
          _detalle('Situación', ppl.situacion),
          _detalle('Delito', ppl.delito),
          _detalle('Radicado', ppl.radicado),

          if (ppl.situacion == 'En Reclusión') ...[
            _detalle('TD', ppl.td),
            _detalle('NUI', ppl.nui),
            _detalle('Patio', ppl.patio),
          ],

          const Divider(),
          const SizedBox(height: 12),

          // =====================================================
          // CORREOS DEL INPEC
          // =====================================================
          const Text(
            'Correo del INPEC',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            ppl.centroReclusion,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          if (correosCentro.values.any(
                (correo) =>
            correo.trim().isNotEmpty &&
                correo.trim().toLowerCase() != 'no disponible',
          )) ...[
            if ((correosCentro['correo_direccion'] ?? '')
                .trim()
                .isNotEmpty)
              correoConBoton(
                'Director',
                correosCentro['correo_direccion'],
              ),

            if ((correosCentro['correo_juridica'] ?? '')
                .trim()
                .isNotEmpty)
              correoConBoton(
                'Jurídica',
                correosCentro['correo_juridica'],
              ),

            if ((correosCentro['correo_principal'] ?? '')
                .trim()
                .isNotEmpty)
              correoConBoton(
                'Principal',
                correosCentro['correo_principal'],
              ),

            if ((correosCentro['correo_sanidad'] ?? '')
                .trim()
                .isNotEmpty)
              correoConBoton(
                'Sanidad',
                correosCentro['correo_sanidad'],
              ),
          ] else
            const Text(
              'No hay correos del INPEC registrados para este establecimiento.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.redAccent,
              ),
            ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // =====================================================
          // DATOS DEL ACUDIENTE
          // =====================================================
          const Text(
            'Datos del acudiente',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _detalle(
            'Nombre',
            '${ppl.nombreAcudiente} ${ppl.apellidoAcudiente}',
          ),
          _detalle(
            'Parentesco',
            ppl.parentescoRepresentante,
          ),
          _detalle('Celular', ppl.celular),
          _detalle('WhatsApp', ppl.celularWhatsapp),
        ],
      ),
    );
  }

  Future<void> _mostrarContenidoCorreo(String correoId) async {
    try {
      final documento = await FirebaseFirestore.instance
          .collection('asignacionTEE_solicitados')
          .doc(widget.idDocumento)
          .collection('log_correos')
          .doc(correoId)
          .get();

      if (!mounted) return;

      if (!documento.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró el correo seleccionado.'),
          ),
        );
        return;
      }

      final datos = documento.data() ?? {};

      final String html = (datos['html'] ?? '').toString();
      final String asunto =
      (datos['subject'] ?? 'Contenido del correo').toString();

      if (html.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este correo no tiene contenido disponible.'),
          ),
        );
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,

            title: Text(asunto),

            content: SizedBox(
              width: 700,
              height: MediaQuery.of(dialogContext).size.height * 0.7,
              child: SingleChildScrollView(
                child: Html(
                  data: html,
                ),
              ),
            ),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir el correo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _actualizarEstado(String nuevoEstado) async {
    if (_procesando) return;

    final nombreAdmin = AdminProvider().adminFullName ?? '';

    if (nombreAdmin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo identificar al administrador.',
          ),
        ),
      );
      return;
    }

    setState(() => _procesando = true);

    try {
      final datos = <String, dynamic>{
        'status': nuevoEstado,
      };

      if (nuevoEstado == 'Diligenciado') {
        datos['diligencio'] = nombreAdmin;
        datos['fecha_diligenciamiento'] =
            FieldValue.serverTimestamp();
      }

      if (nuevoEstado == 'Revisado') {
        datos['reviso'] = nombreAdmin;
        datos['fecha_revision'] =
            FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('asignacionTEE_solicitados')
          .doc(widget.idDocumento)
          .update(datos);

      await ResumenSolicitudesHelper.actualizarResumen(
        idOriginal: widget.idDocumento,
        nuevoStatus: nuevoEstado,
        origen: 'asignacionTEE_solicitados',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Solicitud marcada como $nuevoEstado',
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error actualizando solicitud TEE: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error al actualizar la solicitud.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  Future<void> enviarCorreoResendTEE({
    required String correoDestino,
    String? asuntoPersonalizado,
    String? prefacioHtml,
  }) async {
    if (userData == null) {
      throw StateError('No se encontraron los datos del PPL.');
    }

    final url = Uri.parse(
      'https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/sendEmailWithResend',
    );

    final plantilla = _crearPlantilla();

    final fechaEnvioFormateada =
    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final htmlFinal = """
<html>
<body style="font-family: Arial, sans-serif; font-size: 10pt; color: #000;">
  <p>De: peticiones@tuprocesoya.com</p>
  <p>Para: $correoDestino</p>
  <p>Fecha de envío: $fechaEnvioFormateada</p>
  <hr>
  ${prefacioHtml ?? ''}
  ${plantilla.generarTextoHtml()}
</body>
</html>
""";

    final correoUsuario = userData!.email.trim();

    final List<Map<String, String>> archivosAdjuntos = [];

    if (_solicitudPorAbogado) {
      if (_poderPdfBytes == null || _poderPdfNombre == null) {
        throw StateError(
          'Debes adjuntar el poder en PDF antes de enviar la solicitud.',
        );
      }

      archivosAdjuntos.add({
        'nombre': _poderPdfNombre!,
        'base64': base64Encode(_poderPdfBytes!),
        'tipo': 'application/pdf',
      });

      if (_documentosAbogadoPdfBytes == null ||
          _documentosAbogadoPdfNombre == null) {
        throw StateError(
          'Debes adjuntar los documentos del abogado en PDF.',
        );
      }

      archivosAdjuntos.add({
        'nombre': _documentosAbogadoPdfNombre!,
        'base64': base64Encode(_documentosAbogadoPdfBytes!),
        'tipo': 'application/pdf',
      });
    }

    final body = jsonEncode({
      'to': correoDestino,
      'cc': correoUsuario.isNotEmpty ? [correoUsuario] : <String>[],
      'subject': asuntoPersonalizado ??
          'Solicitud de Asignación TEE - ${widget.numeroSeguimiento}',
      'html': htmlFinal,
      'archivos': archivosAdjuntos,
      'idDocumento': widget.idDocumento,
      'enviadoPor':
      FirebaseAuth.instance.currentUser?.email ?? adminFullName,
      'tipo': 'asignacionTEE',
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al enviar correo TEE: ${response.statusCode} - ${response.body}',
      );
    }
    if (_solicitudPorAbogado && _poderPdfBytes != null) {
      try {
        await _guardarPoderEnStorage();
        await _guardarDocumentosAbogadoEnStorage();
      } catch (e) {
        debugPrint('No se pudo guardar la copia del poder: $e');
      }
    }

    await _firestore
        .collection('asignacionTEE_solicitados')
        .doc(widget.idDocumento)
        .update({
      'status': 'Enviado',
      'fechaEnvio': FieldValue.serverTimestamp(),
      'envió': AdminProvider().adminFullName ?? '',
    });

    await ResumenSolicitudesHelper.actualizarResumen(
      idOriginal: widget.idDocumento,
      nuevoStatus: 'Enviado',
      origen: 'asignacionTEE_solicitados',
    );
  }

  Future<void> subirHtmlCorreoTEE({
    required String tipoEnvio,
    required String htmlFinal,
    required String nombreColeccionFirestore,
    required String nombrePathStorage,
  }) async {
    final bytes = utf8.encode(htmlFinal);

    final filePath =
        '$nombrePathStorage/${widget.idDocumento}/correos/correo_$tipoEnvio.html';

    final ref = FirebaseStorage.instance.ref(filePath);

    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: 'text/html'),
    );

    final downloadUrl = await ref.getDownloadURL();

    await _firestore
        .collection(nombreColeccionFirestore)
        .doc(widget.idDocumento)
        .set({
      'correosGuardados.$tipoEnvio': downloadUrl,
      'fechaHtmlCorreo.$tipoEnvio': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Widget botonEnviarCorreoTEE() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        side: BorderSide(
          width: 1,
          color: Theme.of(context).primaryColor,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      onPressed: _procesando
          ? null
          : () async {
        if (correoSeleccionado.trim().isEmpty ||
            correoSeleccionado.trim().toLowerCase() ==
                'no disponible') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Primero selecciona un correo válido del INPEC.',
              ),
            ),
          );
          return;
        }

        if (_solicitudPorAbogado &&
            (_nombreAbogadoController.text.trim().isEmpty ||
                _cedulaAbogadoController.text.trim().isEmpty ||
                _tarjetaAbogadoController.text.trim().isEmpty)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Completa el nombre, cédula y tarjeta profesional del abogado.',
              ),
            ),
          );
          return;
        }

        if (_solicitudPorAbogado && _poderPdfBytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Debes adjuntar el poder en PDF antes de enviar el correo.',
              ),
            ),
          );
          return;
        }

        if (_solicitudPorAbogado &&
            _documentosAbogadoPdfBytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Debes adjuntar los documentos del abogado en PDF antes de enviar.',
              ),
            ),
          );
          return;
        }

        if (userData == null) return;

        final plantilla = _crearPlantilla();
        final html = plantilla.generarTextoHtml();

        final manager = EnvioCorreoManagerUnico();

        await manager.enviarCorreoUnico(
          context: context,
          correoDestinoPrincipal: correoSeleccionado.trim(),
          asuntoPersonalizado:
          'Solicitud de Asignación TEE - ${widget.numeroSeguimiento}',
          prefacioHtml: null,
          html: html,
          ultimoHtmlEnviado: html,
          numeroSeguimiento: widget.numeroSeguimiento,
          nombreServicio: 'Asignación TEE',
          rutaHistorial:
          'historial_solicitudes_asignacionTEE_admin',
          idDocumentoSolicitud: widget.idDocumento,
          idDocumentoPpl: userData!.id,
          nombreColeccionFirestore: 'asignacionTEE_solicitados',
          nombrePathStorage: 'asignacionTEE',
          enviarCorreoResend: ({
            required String correoDestino,
            String? asuntoPersonalizado,
            String? prefacioHtml,
          }) async {
            await enviarCorreoResendTEE(
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
            await subirHtmlCorreoTEE(
              tipoEnvio: tipoEnvio,
              htmlFinal: htmlFinal,
              nombreColeccionFirestore: nombreColeccionFirestore,
              nombrePathStorage: nombrePathStorage,
            );
          },
          celularWhatsapp: userData?.celularWhatsapp,
          nombreAcudiente:
          userData?.nombreAcudiente ?? 'Usuario',
        );
      },
      child: const Text('Enviar por correo'),
    );
  }

  Future<void> _guardarDocumentosAbogadoEnStorage() async {
    if (_documentosAbogadoPdfBytes == null ||
        _documentosAbogadoPdfNombre == null) {
      return;
    }

    final path =
        'asignacionTEE/${widget.idDocumento}/adjuntos/documentos_abogado_${DateTime.now().millisecondsSinceEpoch}.pdf';

    final ref = FirebaseStorage.instance.ref(path);

    await ref.putData(
      _documentosAbogadoPdfBytes!,
      SettableMetadata(contentType: 'application/pdf'),
    );

    await _firestore
        .collection('asignacionTEE_solicitados')
        .doc(widget.idDocumento)
        .update({
      'documentosAbogadoPdfNombre': _documentosAbogadoPdfNombre,
      'documentosAbogadoPdfPath': path,
      'documentosAbogadoPdfFecha': FieldValue.serverTimestamp(),
    });
  }

  Widget _buildVistaPrevia() {
    if (userData == null) {
      return const Text(
        'No se pueden generar los datos de la solicitud.',
      );
    }

    final plantilla = _crearPlantilla();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vista previa de la solicitud de Asignación TEE',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Html(
            data: plantilla.generarTextoHtml(),
          ),
        ),

        const SizedBox(height: 30),

        if (statusActual == 'Solicitado')
          ElevatedButton(
            onPressed: _procesando
                ? null
                : () => _actualizarEstado('Diligenciado'),
            child: const Text('Marcar como Diligenciado'),
          ),

        if ((statusActual == 'Diligenciado' ||
            statusActual == 'Revisado') &&
            rol != 'pasante 1')
          Wrap(
            spacing: 15,
            runSpacing: 10,
            children: [
              if (statusActual == 'Diligenciado')
                ElevatedButton(
                  onPressed: _procesando
                      ? null
                      : () => _actualizarEstado('Revisado'),
                  child: const Text('Marcar como Revisado'),
                ),

              if (statusActual == 'Revisado')
                botonAdjuntarPoderTEE(),
                botonEnviarCorreoTEE(),
            ],
          ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hoy es: ${DateFormat("d 'de' MMMM 'de' y", 'es').format(DateTime.now())}',
          style: const TextStyle(fontSize: 12),
        ),

        const SizedBox(height: 15),

        if (rol == 'masterFull' ||
            rol == 'master' ||
            rol == 'coordinador 1')
          infoAccionesAdmin(),

        const SizedBox(height: 15),

        _mostrarDocumentosAdjuntos(),

        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _obtenerColorFondo(statusActual),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Solicitud Asignación TEE - $statusActual',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              _buildSolicitadoPor(),
              _buildDetallesSolicitud(),
            ],
          ),
        ),

        const SizedBox(height: 30),
        const Divider(),
        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: () {
            setState(() {
              _mostrarVistaPrevia = !_mostrarVistaPrevia;
            });
          },
          child: Text(
            _mostrarVistaPrevia
                ? 'Ocultar vista previa'
                : 'Vista previa',
          ),
        ),

        const SizedBox(height: 20),

        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Solicitud presentada mediante abogado',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          subtitle: const Text(
            'Al activarlo, la solicitud se redactará en tercera persona, '
                'como una petición presentada por el abogado en representación del PPL.',
          ),
          value: _solicitudPorAbogado,

          // Colores visibles en ambos estados
          activeColor: Colors.white,
          activeTrackColor: Colors.green,
          inactiveThumbColor: Colors.grey.shade600,
          inactiveTrackColor: Colors.grey.shade400,

          onChanged: (valor) {
            setState(() {
              _solicitudPorAbogado = valor;
            });
          },
        ),

// DATOS DEL ABOGADO
        if (_solicitudPorAbogado) ...[
          const SizedBox(height: 15),

          TextField(
            controller: _nombreAbogadoController,
            decoration: InputDecoration(
              labelText: 'Nombre completo del abogado',
              labelStyle: const TextStyle(color: Colors.black87),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.grey.shade500,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.grey.shade700,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: _cedulaAbogadoController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Cédula de ciudadanía del abogado',
              labelStyle: const TextStyle(color: Colors.black87),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.grey.shade500,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.grey.shade700,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: _tarjetaAbogadoController,
            decoration: InputDecoration(
              labelText: 'Tarjeta profesional del abogado',
              labelStyle: const TextStyle(color: Colors.black87),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.grey.shade500,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.grey.shade700,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],

        const SizedBox(height: 20),

        if (_mostrarVistaPrevia) _buildVistaPrevia(),

        const SizedBox(height: 100),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 1000;

    return MainLayout(
      pageTitle: 'Atender solicitud Asignación TEE',
      content: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : isWide
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildExtraWidget(),
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
          ],
        ),
      ),
    );
  }
}
