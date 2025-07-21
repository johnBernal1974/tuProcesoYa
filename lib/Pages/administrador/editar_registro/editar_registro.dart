import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../commons/admin_provider.dart';
import '../../../commons/drop_delitos.dart';
import '../../../commons/drop_depatamentos_municipios.dart';
import '../../../commons/editar_beneficios_ppl.dart';
import '../../../commons/main_layaout.dart';
import '../../../controllers/tiempo_condena_controller.dart';
import '../../../models/ppl.dart';
import '../../../providers/ppl_provider.dart';
import '../../../src/colors/colors.dart';
import '../../../widgets/actualizar_nodo_30%.dart';
import '../../../widgets/admin_acceso_temporal.dart';
import '../../../widgets/agregar_agenda.dart';
import '../../../widgets/card_comuncar_con_el_usuario.dart';
import '../../../widgets/card_gestionar_descuento.dart';
import '../../../widgets/datos_ejecucion_condena.dart';
import '../../../widgets/estado_de_pago.dart';
import '../../../widgets/exento.dart';
import '../../../widgets/formulario_estadias_reclusion.dart';
import '../../../widgets/ingresar_juzgado_conocimiento.dart';
import '../../../widgets/ingresar_juzgado_ep.dart';
import '../../../widgets/tabla_vista_estadias_reclusion.dart';
import '../../seguimiento_solicitudes_page.dart';
import '../home_admin/home_admin.dart';
import 'package:http/http.dart' as http;


class EditarRegistroPage extends StatefulWidget {
  final DocumentSnapshot doc;

  const EditarRegistroPage({Key? key, required this.doc}) : super(key: key);

  @override
  _EditarRegistroPageState createState() => _EditarRegistroPageState();
}

class _EditarRegistroPageState extends State<EditarRegistroPage> {
  final _formKey = GlobalKey<FormState>();

  ///Controllers info PPL
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _numeroDocumentoController = TextEditingController();
  final _radicadoController = TextEditingController();
  final _tdController = TextEditingController();
  final _nuiController = TextEditingController();
  final _patioController = TextEditingController();
  final _direccionController = TextEditingController();



  /// controllers para el acudiente
  final _nombreAcudienteController = TextEditingController();
  final _apellidosAcudienteController = TextEditingController();
  final _parentescoAcudienteController = TextEditingController();
  final _celularAcudienteController = TextEditingController();
  final _celularWhatsappController = TextEditingController();
  final _emailAcudienteController = TextEditingController();

  /// nuevos controladores para la condena
  final _mesesCondenaController = TextEditingController();
  final _diasCondenaController = TextEditingController();

  double getCondenaEnMeses() {
    final meses = int.tryParse(_mesesCondenaController.text) ?? 0;
    final dias = int.tryParse(_diasCondenaController.text) ?? 0;
    return meses + (dias / 30);
  }


  ///Mapas de opciones traidas de firestore
  List<Map<String, dynamic>> regionales = [];
  List<Map<String, dynamic>> centrosReclusion = [];
  List<Map<String, dynamic>> juzgadosEjecucionPenas = [];
  List<Map<String, dynamic>> juzgadoQueCondeno = [];
  List<Map<String, dynamic>> juzgadosConocimiento = [];
  List<Map<String, dynamic>> delito = [];
  List<Map<String, Object>> centrosReclusionTodos = [];

  ///Para PPL que no estan en reclusion
  List<Map<String, dynamic>> situacion = [];

  /// variables para guardar opciones seleccionadas
  String? selectedRegional; // Regional seleccionada
  String? selectedCentro; // Centro de reclusión seleccionado
  String? selectedJuzgadoEjecucionPenas;
  String? selectedCiudad;
  String? selectedJuzgadoNombre;
  String? selectedDelito;
  String? categoriaDelito;

  String _juzgadoQueCondeno= "";
  String _juzgado= "";

  String? selectedJuzgadoEjecucionEmail;
  String? selectedJuzgadoConocimientoEmail;

  bool isLoading = true;
  /// variables para saber si se muestra los drops o no
  bool _mostrarDropdowns = false;
  bool _mostrarDropdownJuzgadoEjecucion = false;
  bool _mostrarDropdownJuzgadoCondeno = false;
  final TextEditingController _autocompleteController = TextEditingController();


  /// variables para calcular el tiempo de condena
  late CalculoCondenaController _calculoCondenaController;
  int tiempoCondena =0;
  int diasEjecutado = 0;
  int mesesEjecutado = 0;
  int diasEjecutadoExactos = 0;
  int diasRestante = 0;
  int mesesRestante = 0;
  int diasRestanteExactos = 0;
  double porcentajeEjecutado =0;
  late String _tipoDocumento;
  late PplProvider _pplProvider;
  int? _tiempoDePruebaDias;

  //fecha para redenciones
  final AdminProvider _adminProvider = AdminProvider();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _diasController = TextEditingController();
  DateTime? _fechaSeleccionada;
  bool _isLoading = false;

  String? departamentoSeleccionado;
  String? municipioSeleccionado;


  bool _isLoadingJuzgados = false; //
  late Ppl ppl;
  bool isExento = false;
  bool cargando = true;
  List<String> ciudades = [];
  Timestamp? _ultimaActualizacionRedenciones;
  late TextEditingController _centroController;
  bool centroValidado = false;
  late String adminFullName = "Desconocido"; // Valor por defecto
  bool mostrarBotonNotificar = false;
  int mesesCondena = 0;
  int diasCondena = 0;

  String? _statusActual;
  bool? _isNotificatedActivated;
  DocumentSnapshot? _docEditable;





  /// opciones de documento de identidad
  final List<String> _opciones = ['Cédula de Ciudadanía','Pasaporte', 'Tarjeta de Identidad'];

  @override
  void initState() {
    super.initState();
    _pplProvider = PplProvider();
    adminFullName = AdminProvider().adminFullName ?? "Desconocido";
    _calculoCondenaController = CalculoCondenaController(_pplProvider);
    _initCalculoCondena();
    _initFormFields();
    _centroController = TextEditingController();
    cargarCiudades();
    _cargarTiempoDePrueba();

    final data = widget.doc.data() as Map<String, dynamic>?;

    if (data != null) {
      // ✅ Verificación de centro_validado
      centroValidado = data.containsKey('centro_validado') &&
          data['centro_validado'] == true;

      // ✅ Asignaciones condicionales
      _ultimaActualizacionRedenciones = data['ultima_actualizacion_redenciones']; // Puede ser null
      _direccionController.text = data['direccion'] ?? '';

      departamentoSeleccionado = data['departamento'];
      municipioSeleccionado = data['municipio'];
      categoriaDelito = data['categoria_delito'];
      selectedDelito = data['delito'];

      if (categoriaDelito != null && categoriaDelito!.trim().isEmpty) {
        categoriaDelito = null;
      }
      if (selectedDelito != null && selectedDelito!.trim().isEmpty) {
        selectedDelito = null;
      }

      mesesCondena = data['meses_condena'];
      diasCondena = data['dias_condena'];

      if (mesesCondena != null &&
          diasCondena != null &&
          mesesCondena is num &&
          diasCondena is num) {
        cargarCondenaDesdeDocumento(mesesCondena.toInt(), diasCondena.toInt());
      }
    }

    Future.delayed(Duration.zero, () {
      setState(() {
        isLoading = false; // Cambia el estado después de verificar los valores
      });
    });

    ppl = Ppl.fromJson(widget.doc.data() as Map<String, dynamic>);
    _obtenerDatos();
    _cargarDatos();
    _asignarDocumento(); // Bloquea el documento al abrirlo
    _adminProvider.loadAdminData(); // 🔥 Cargar info del admin
    calcularTotalRedenciones(widget.doc.id); // 🔥 Llama la función aquí
    _statusActual = widget.doc["status"]?.toString();
    _isNotificatedActivated = widget.doc["isNotificatedActivated"] == true;
    _docEditable = widget.doc;
  }

  Future<void> _cargarTiempoDePrueba() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final valor = doc.get('tiempoDePrueba');
        setState(() {
          _tiempoDePruebaDias = valor is int ? valor : int.tryParse(valor.toString());
        });
      }
    } catch (e) {
      debugPrint('Error al cargar tiempoDePrueba: $e');
    }
  }


  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _numeroDocumentoController.dispose();
    _radicadoController.dispose();
    _tdController.dispose();
    _nuiController.dispose();
    _patioController.dispose();
    _direccionController.dispose();
    //_liberarDocumento(); // 🔥 Libera el documento al cerrar la pantalla
    super.dispose();
  }

  void cargarCiudades() async {
    final lista = await obtenerCiudadesDesdeFirestore();
    setState(() {
      ciudades = lista;
    });
  }

  Future<List<String>> obtenerCiudadesDesdeFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ciudades')
          .orderBy('nombre') // opcional, orden alfabético
          .get();

      return snapshot.docs.map((doc) => doc.get('nombre').toString()).toList();
    } catch (e) {
      debugPrint('Error al cargar ciudades: $e');
      return [];
    }
  }


  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return MainLayout(
      pageTitle: 'Datos generales',
      content: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: blanco,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                CardEstadoPruebaYPago(
                  doc: widget.doc,
                  tiempoDePruebaDias: _tiempoDePruebaDias,
                ),
              ],
            ),
            const SizedBox(height: 25),

            Form(
              key: _formKey,
              child: Center(
                child: isWide
                    ? Row( // escritorio
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: _buildMainContent()),
                    const SizedBox(width: 50),
                    Expanded(flex: 2, child: _buildExtraWidget()),
                  ],
                )
                    : Column( // móvil
                  children: [
                    _buildMainContent(),
                    const SizedBox(height: 30),
                    _buildExtraWidget(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Contenido principal (Información del PPL y Acudiente)
  Widget _buildMainContent() {
    final status = widget.doc["status"]?.toString().toLowerCase() ?? '';
    final situacion = widget.doc["situacion"] ?? '';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Información del PPL',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              if (widget.doc.get('situacion') == "En Prisión domiciliaria" ||
                  widget.doc.get('situacion') == "En libertad condicional")
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black,
                  ),
                  child: Text(
                    widget.doc.get('situacion') ?? "",
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
                  ),
                ),
            ],
          ),
          Text('ID: ${widget.doc.id}', style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 20),
          if (status == 'activado')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.comment),
                label: const Text("Comentarios (seguimiento)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _mostrarComentariosSeguimiento(context),
              ),
            ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20, // espacio horizontal entre widgets cuando caben en una fila
            runSpacing: 20, // espacio vertical entre widgets cuando se apilan
            children: [
              // Contenedor de beneficios
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                  color: blanco
                ),
                child: SizedBox(
                  width: 350,
                  child: Column(
                    children: [
                      if (mesesCondena <= 0 && diasCondena <= 0) ...[
                        Container(
                          width: 600,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'No se ha ingresado tiempo de condena. Por eso no se ha calculado el progreso.',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
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
                    ],
                  ),
                ),
              ),
              // Widget de resumen de solicitudes
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text("Solicitudes hechas por el PPL", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    SizedBox(
                      width: 280,
                      child: ResumenSolicitudesWidget(idPpl: ppl.id),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (status == 'pendiente' ||
              (status == 'activado' &&
                  (widget.doc.data() != null &&
                      (widget.doc.data() as Map<String, dynamic>).containsKey('requiere_actualizacion_datos') &&
                      widget.doc['requiere_actualizacion_datos'] == true))) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.comment),
                label: const Text("Ver comentarios"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _mostrarComentarios(context, widget.doc["status"]),
              ),
            ),
          ],

          LayoutBuilder(
            builder: (context, constraints) {
              bool esPantallaAncha = constraints.maxWidth > 600; // Puedes ajustar el ancho si deseas

              return esPantallaAncha
                  ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: FutureBuilder<double>(
                      future: calcularTotalRedenciones(widget.doc.id),
                      builder: (context, snapshot) {
                        double totalRedimido = snapshot.data ?? 0.0;
                        return _datosEjecucionCondena(totalRedimido, isExento);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  MostrarTiempoBeneficioCard(idPpl: ppl.id),
                ],
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<double>(
                    future: calcularTotalRedenciones(widget.doc.id),
                    builder: (context, snapshot) {
                      double totalRedimido = snapshot.data ?? 0.0;
                      return _datosEjecucionCondena(totalRedimido, isExento);
                    },
                  ),
                  MostrarTiempoBeneficioCard(idPpl: ppl.id),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          nombrePpl(),
          const SizedBox(height: 15),
          apellidoPpl(),
          const SizedBox(height: 15),
          tipoDocumentoPpl(),
          const SizedBox(height: 15),
          numeroDocumentoPpl(),
          const SizedBox(height: 25),
          seleccionarCentroReclusion(),
          const SizedBox(height: 25),
          seleccionarJuzgadoEjecucionPenas(),
          const SizedBox(height: 25),
          seleccionarJuzgadoQueCondeno(),
          const SizedBox(height: 15),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 900; // puedes ajustar este valor

              if (isWideScreen) {
                // 📺 Pantallas anchas: lado a lado
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: FormularioEstadiaAdmin(pplId: ppl.id),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: TablaEstadiasAdmin(pplId: ppl.id),
                    ),
                  ],
                );
              } else {
                // 📱 Pantallas angostas: uno debajo del otro
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FormularioEstadiaAdmin(pplId: ppl.id),
                    const SizedBox(height: 16),
                    TablaEstadiasAdmin(pplId: ppl.id),
                  ],
                );
              }
            },
          )
          ,
          const SizedBox(height: 15),
          DelitosAutocompleteWidget(
            categoriaSeleccionada: categoriaDelito,
            delitoSeleccionado: selectedDelito,
            onDelitoChanged: (categoria, delito) {
              setState(() {
                categoriaDelito = categoria;
                selectedDelito = delito;
              });
            },
          ),
          const SizedBox(height: 15),
          // fechaCapturaPpl(),
          // const SizedBox(height: 15),
          radicadoPpl(),
          const SizedBox(height: 15),
          condenaPpl(),
          const SizedBox(height: 15),

          if (widget.doc['situacion'] == "En Reclusión") ...[
            tdPpl(),
            const SizedBox(height: 15),
            nuiPpl(),
            const SizedBox(height: 15),
            patioPpl(),
          ],
          const SizedBox(height: 30),

          // 🔹 Información del Acudiente
          const Text(
            'Información del Acudiente',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 15),
          nombreAcudiente(),
          const SizedBox(height: 15),
          apellidosAcudiente(),
          const SizedBox(height: 15),
          parentescoAcudiente(),
          const SizedBox(height: 15),
          celularAcudiente(),
          const SizedBox(height: 15),
          celularWhatsappAcudiente(),
          const SizedBox(height: 15),

          if (widget.doc['email'] != null && widget.doc['email'].toString().trim().isNotEmpty) ...[
            emailAcudiente(),
            const SizedBox(height: 15),
          ],
          const SizedBox(height: 50),
          // 🔹 Contenedor de acciones
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
              color: Colors.white,
            ),
            child: Column(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Ppl')
                      .doc(widget.doc.id)
                      .collection('eventos')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();
                    if (!snapshot.hasData) return const SizedBox();

                    final eventos = snapshot.data!.docs.map((doc) => doc.id).toSet();
                    final List<Widget> mensajes = [];

                    if (eventos.contains('sin_juzgado_ejecucion')) {
                      mensajes.add(_mensajeAdvertencia(
                        "Este registro se puede guardar sin juzgado ni condena porque fue marcado como 'Juzgado EP sin asignar'.",
                      ));
                    }

                    if (eventos.contains('proceso_en_tribunal')) {
                      mensajes.add(_mensajeAdvertencia(
                        "Este registro tiene un proceso en tribunal. Se puede guardar, sin JEP ni condena. Revise cuidadosamente antes de continuar.",
                      ));
                    }
                    if (eventos.contains('sin_fecha_captura')) {
                      mensajes.add(_mensajeAdvertencia(
                        "Este registro no tiene fecha de captura. Se puede guardar sin fecha de captura. Revise cuidadosamente antes de continuar.",
                      ));
                    }

                    return Column(children: mensajes);
                  },
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 🔹 Tarjeta de Estado y Notificación
                    Card(
                      color: Colors.white,
                      surfaceTintColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          children: [
                            // Estado del usuario
                            estadoUsuarioWidget(widget.doc["status"]),

                            // Estado de notificación
                            estadoNotificacionWidget(
                              widget.doc["isNotificatedActivated"],
                              widget.doc["celularWhatsapp"],
                              widget.doc.id,
                            ),

                            // Tarjeta de activación (condicional)
                            if (_docEditable!["status"] == "registrado" || _docEditable!["status"] == "por_activar")
                              SizedBox(
                                width: 170, // Ajusta si deseas más ancho
                                child: Card(
                                  color: Colors.white,
                                  surfaceTintColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Colors.grey),
                                  ),
                                  elevation: 2,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () async {
                                      final docRef = _docEditable!.reference;
                                      final status = _docEditable!["status"];

                                      if (status == "registrado") {
                                        await docRef.update({"status": "por_activar"});
                                      } else if (status == "por_activar") {
                                        bool confirmar = await showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            backgroundColor: blanco,
                                            title: const Text("Confirmar activación"),
                                            content: const Text("¿Deseas activar este usuario?"),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
                                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Activar")),
                                            ],
                                          ),
                                        );
                                        if (confirmar == true) {
                                          await docRef.update({"status": "activado"});
                                        }
                                      }

                                      final nuevoSnapshot = await docRef.get();
                                      if (mounted) {
                                        setState(() {
                                          _docEditable = nuevoSnapshot;
                                        });
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _docEditable!["status"] == "registrado" ? Icons.arrow_upward : Icons.watch_later_outlined,
                                            color: _docEditable!["status"] == "registrado" ? Colors.deepPurple : Colors.amber,
                                            size: 30,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _docEditable!["status"] == "registrado"
                                                ? "Para activar"
                                                : "Pendiente\npara activar",
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      ),
                    ),

                    Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (_docEditable!["status"] != "bloqueado") ...[
                          botonGuardar(),
                          bloquearUsuario(),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            child: (_docEditable!["status"] == "activado" &&
                                (_isNotificatedActivated == false || _isNotificatedActivated == null))
                                ? botonEnviarWhatsappDesdeImagen(
                              widget.doc["celularWhatsapp"],
                              widget.doc.id,
                            )
                                : const SizedBox(), // Para ocultar si no se cumple
                          ),

                        ] else
                          FutureBuilder<bool>(
                            future: _adminPuedeDesbloquear(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox();
                              return snapshot.data == true
                                  ? desbloquearUsuario()
                                  : const SizedBox();
                            },
                          ),
                      ],
                    ),
                  ],
                )
              ],
            ),

          ),
        ],
      ),
    );
  }

  int _calcularDias(double porcentajeMeta) {
    final diasMeta = (porcentajeMeta / 100 * tiempoCondena * 30).ceil();
    final diasActuales = (_calculoCondenaController.mesesComputados ?? 0) * 30 +
        (_calculoCondenaController.diasComputados ?? 0);
    return diasMeta - diasActuales;
  }


  Widget botonEnviarWhatsappDesdeImagen(String celular, String docId) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: () async {
        await enviarMensajeWhatsAppApi(celular, docId);
      },
      icon: Image.asset(
        'assets/images/icono_whatsapp.png',
        height: 24,
        width: 24,
      ),
      label: const Text("Notificar activación"),
    );
  }



  Widget _buildBenefitMinimalSection({
    required String titulo,
    required bool condition,
    required int remainingTime,
  }) {
    final esPositivo = condition;
    final texto = esPositivo
        ? "Hace ${remainingTime.abs()} días"
        : "Faltan ${remainingTime.abs()} días";

    final color = esPositivo ? Colors.green : Colors.red;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titulo,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              texto,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  //FUNCION PARA CONFIGURAR TAMALO DE LETRA PARA MOBILES Y PC

  double responsiveFontSize(BuildContext context, double baseSize) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return baseSize * 0.85; // Para móviles
    if (screenWidth < 900) return baseSize * 0.95; // Para tablets
    return baseSize; // Para pantallas grandes
  }

  Widget _mensajeAdvertencia(String texto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        border: Border.all(color: Colors.amber, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Widgets adicionales (Historial y acciones)
  Widget _buildExtraWidget() {
    final data = widget.doc.data() as Map<String, dynamic>;
    final descuento = data.containsKey('descuento') ? data['descuento'] as Map<String, dynamic>? : null;
    final referidoPor = data.containsKey('referidoPor') ? data['referidoPor'] : null;
    final bool esReferido = referidoPor != null && referidoPor.toString().trim().isNotEmpty;


    return Container(
      decoration: BoxDecoration(
        color: blanco,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(-4, 0),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            if (esReferido)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '¡Usuario referido!',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),


            // ✅ Mostrar el botón solo si no fue referido por "355"
            if (FirebaseAuth.instance.currentUser != null &&
                referidoPor != "355" &&
                data['status'] == "activado" &&
                data['isPaid'] == false)
              CardGestionarDescuento(
                uidUsuario: ppl.id,
                uidAdmin: descuento?['otorgadoPor'],
              ),

            const SizedBox(height: 20),

            if (FirebaseAuth.instance.currentUser != null &&
                data['status'] == "activado" &&
                data['isPaid'] == false)
              AdminAccesoTemporal(uidPPL: ppl.id),

            const SizedBox(height: 20),

            if (data["situacion"] == "En Prisión domiciliaria" ||
                data["situacion"] == "En libertad condicional")
              infoPplNoRecluido(),

            const SizedBox(height: 20),
            EditarExclusionWidget(
              pplId: data['id'],
              exentoInicial: data['exento'] ?? false,
            ),
            const SizedBox(height: 20),
            EditarBeneficiosWidget(
              pplId: data["id"],
              beneficiosAdquiridosInicial: ppl.beneficiosAdquiridos,
              beneficiosNegadosInicial: ppl.beneficiosNegados,
            ),
            agregarRedenciones(),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Historial Acciones Administrativas",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  historialAccionUsuario(),
                ],
              ),
            ),

            const SizedBox(height: 50),
            WhatsAppCardWidget(
              celularWhatsApp: data['celularWhatsapp'] ?? '',
              docId: widget.doc.id,
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  //para seleccionar fecha redenciones
  /// 🔥 Mostrar un DatePicker para seleccionar la fecha de redención
  Future<void> _selectFechaRedencion(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _fechaController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  // para agregar rednciones
  Future<void> _guardarRedencion(String pplId) async {
    if (_fechaController.text.isEmpty || _diasController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    try {
      String fechaActual = DateTime.now().toIso8601String(); // Fecha de actualización
      String? adminNombre = _adminProvider.adminName;
      String? adminApellido = _adminProvider.adminApellido;

      await FirebaseFirestore.instance
          .collection('Ppl')
          .doc(pplId)
          .collection('redenciones') // Subcolección de redenciones
          .add({
        'fecha_redencion': _fechaController.text,
        'dias_redimidos': double.parse(_diasController.text),
        'fecha_actualizacion': fechaActual,
        'admin_nombre': adminNombre ?? "Desconocido",
        'admin_apellido': adminApellido ?? "Desconocido",
      });
      final ahora = Timestamp.now();

      await FirebaseFirestore.instance
          .collection('Ppl')
          .doc(pplId)
          .update({
        'ultima_actualizacion_redenciones': ahora,
      });
      setState(() {
        _ultimaActualizacionRedenciones = ahora;
      });

      if(context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Redención guardada exitosamente')),
        );
        // 🔥 **LIMPIAR los campos después de guardar**
        _fechaController.clear();
        _diasController.clear();
        setState(() {
          mostrarBotonNotificar = true; // 🔔 Mostrar botón de notificación
        });
      }

    } catch (e) {
      if (kDebugMode) {
        print("❌ Error guardando la redención: $e");
      }
      if(context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar la redención')),
        );
      }
    }
  }

  Widget agregarRedenciones() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: blancoCards,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Color de sombra sutil
            blurRadius: 8, // Difuminado
            offset: const Offset(2, 4), // Desplazamiento de la sombra
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Evita que el Column ocupe toda la altura
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Registrar Redención",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _mostrarHistorialRedenciones(context),
                  icon: const Icon(Icons.remove_red_eye, color: Colors.black87),
                  label: const Text("Ver Redenciones", style: TextStyle(color: negro)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                // 📅 Campo de fecha
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TextField(
                      controller: _fechaController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Fecha de Redención",
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: primary),
                        ),
                      ),
                      onTap: () => _selectFechaRedencion(context),
                    ),
                  ),
                ),

                // 🔢 Campo de días redimidos
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextField(
                      controller: _diasController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Cantidad de Días Redimidos",
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: primary),
                        ),
                      ),
                    ),
                  ),
                ),

                // 💾 Botón de guardar como ícono
                Row(
                  children: [
                    // 💾 Botón de guardar como ícono
                    IconButton(
                      onPressed: widget.doc["status"] == "bloqueado"
                          ? null
                          : () async {
                        await _guardarRedencion(widget.doc.id);
                        await calcularTotalRedenciones(widget.doc.id);
                        _initCalculoCondena();
                      },

                      icon: const Icon(Icons.save, size: 28),
                      tooltip: "Guardar redención",
                      color: widget.doc["status"] == "bloqueado" ? Colors.grey : Colors.green,
                    ),

                    const SizedBox(width: 12),

                    // 🛎️ Botón para notificar al usuario
                    if (mostrarBotonNotificar)
                      ElevatedButton.icon(
                        onPressed: widget.doc["status"] == "bloqueado"
                            ? null
                            : () async {
                          // 🔹 Mostrar confirmación
                          final confirmarEnvio = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: blanco,
                              title: const Text("Confirmar envío"),
                              content: const Text(
                                "¿Deseas enviar la notificación de nueva redención al acudiente por WhatsApp?",
                              ),
                              actions: [
                                TextButton(
                                  child: const Text("Cancelar"),
                                  onPressed: () => Navigator.of(context).pop(false),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text("Enviar"),
                                  onPressed: () => Navigator.of(context).pop(true),
                                ),
                              ],
                            ),
                          );

                          // 🔹 Si canceló, no hacer nada
                          if (confirmarEnvio != true) return;

                          // 🔹 Si confirmó, llamar tu función de envío
                          await _notificarRedencion(
                            widget.doc["nombre_acudiente"],
                            widget.doc["nombre_ppl"],
                            widget.doc["apellido_ppl"],
                            widget.doc["celularWhatsapp"],
                            widget.doc.id,
                          );
                        },
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: const Text("Notificar redención"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: gris),

              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1, color: gris),
            const SizedBox(height: 20),
            const Text("Botón para Guardar el usuario sin redenciones o para actualizarlas luego del tiempo programado", style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold
            )),
            const SizedBox(height: 20),

            SizedBox(
              width: 250,
              child: OutlinedButton.icon(
                onPressed: widget.doc["status"] == "bloqueado"
                    ? null
                    : () async {
                  final confirmado = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        backgroundColor: Colors.white,
                        title: const Text("Confirmar acción"),
                        content: const Text(
                          "Vas a guardar la fecha de la última revisión de redenciones sin agregar nueva información. ¿Deseas continuar?",
                          style: TextStyle(color: Colors.black87),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("Cancelar"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                            ),
                            child: const Text("Confirmar", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmado == true) {
                    await FirebaseFirestore.instance
                        .collection('Ppl')
                        .doc(widget.doc.id)
                        .update({
                      'ultima_actualizacion_redenciones': FieldValue.serverTimestamp(),
                    });

                    setState(() {
                      _ultimaActualizacionRedenciones = Timestamp.now();
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Fecha de revisión actualizada")),
                    );
                  }
                },

                icon: const Icon(Icons.check_circle_outline, color: Colors.deepPurple),
                label: const Text(
                  "Marcar como revisado",
                  style: TextStyle(color: Colors.deepPurple),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.deepPurple),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 10),

            if (_ultimaActualizacionRedenciones != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    iconoRevision(_ultimaActualizacionRedenciones!.toDate()),
                    const SizedBox(width: 8),
                    Text(
                      'Última revisión: ${DateFormat("d 'de' MMMM 'de' y", 'es_CO').format(_ultimaActualizacionRedenciones!.toDate())}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'No hay registro de revisión',
                  style: TextStyle(color: Colors.black45),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _notificarRedencion(
      String nombreAcudiente,
      String nombrePpl,
      String apellidoPpl,
      String celular,
      String docId,
      ) async {
    if (celular.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El número de WhatsApp no está disponible')),
      );
      return;
    }

    String numeroFormateado = celular.trim();
    if (!numeroFormateado.startsWith("57")) {
      numeroFormateado = "57$numeroFormateado";
    }

    // Mostrar loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        Uri.parse(
          "https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/sendNewRedencionMessage",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "to": numeroFormateado,
          "docId": docId,
        }),
      );

      Navigator.of(context).pop(); // Cerrar loader

      if (response.statusCode == 200) {
        // Alert de éxito
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: Colors.white,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/icono_whatsapp.png',
                      width: 48,
                      height: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'La notificación de redención fue enviada exitosamente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
      } else {
        print('Error: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error enviando mensaje (Código ${response.statusCode}): ${response.body}',
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Cerrar loader si hay error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error enviando mensaje: $e')),
      );
    }
  }

  Widget iconoRevision(DateTime? ultimaActualizacion) {
    if (ultimaActualizacion == null) {
      return const Tooltip(
        message: 'Aún no se ha hecho la primera revisión de las redenciones',
        child: Icon(Icons.help_outline, color: Colors.orange, size: 20),
      );
    }

    final diferencia = DateTime.now().difference(ultimaActualizacion).inDays;

    if (diferencia >= 30) {
      return const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20);
    } else {
      return const Icon(Icons.check_circle, color: Colors.green, size: 20);
    }
  }

  /// 🔥 Mostrar la pantalla superpuesta con el historial de redenciones
  void _mostrarHistorialRedenciones(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            color: blancoCards,
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 1,
            child: Column(
              children: [
                Container(
                  color: blancoCards,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Historial de Redenciones",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _obtenerRedenciones(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            "No tienes redenciones registradas.",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        );
                      }

                      double totalDiasRedimidos = snapshot.data!
                          .map((r) => r['dias_redimidos'] as double)
                          .fold(0, (prev, curr) => prev + curr);

                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 50,
                            headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey.shade300),
                            columns: const [
                              DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(
                                label: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text('Días Redimidos', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                numeric: true,
                              ),
                              DataColumn(label: Text('Cargó redención', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Fecha actualización', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('')),
                            ],
                            rows: [
                              ...snapshot.data!.map(
                                    (redencion) => DataRow(cells: [
                                  DataCell(Text(
                                  DateFormat('d \'de\' MMMM \'de\' yyyy', 'es').format(redencion['fecha']),

                                  style: const TextStyle(fontSize: 13),
                                  )),
                                  DataCell(
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        (redencion['dias_redimidos'] % 1 == 0
                                            ? (redencion['dias_redimidos'] as double).toStringAsFixed(0)
                                            : (redencion['dias_redimidos'] as double).toStringAsFixed(1)),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text("${redencion['admin_nombre']} ${redencion['admin_apellido']}",
                                      style: const TextStyle(fontSize: 13))),
                                  DataCell(
                                    Text(
                                      redencion['fecha_actualizacion'] != null
                                          ? DateFormat("d 'de' MMMM 'de' y - HH:mm", 'es')
                                          .format(redencion['fecha_actualizacion'])
                                          : "No disponible",
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: "Eliminar redención",
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor: blanco,
                                            title: const Text("Confirmar eliminación"),
                                            content: const Text("¿Estás seguro de que deseas eliminar esta redención?"),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
                                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Eliminar")),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await FirebaseFirestore.instance
                                              .collection('Ppl')
                                              .doc(widget.doc.id)
                                              .collection('redenciones')
                                              .doc(redencion['id'])
                                              .delete();

                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            _mostrarHistorialRedenciones(context);
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ]),
                              ),
                              DataRow(
                                color: MaterialStateColor.resolveWith((states) => Colors.grey.shade200),
                                cells: [
                                  const DataCell(Text("Total", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        (totalDiasRedimidos % 1 == 0
                                            ? totalDiasRedimidos.toStringAsFixed(0)
                                            : totalDiasRedimidos.toStringAsFixed(1)),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const DataCell(Text("")),
                                  const DataCell(Text("")),
                                  const DataCell(Text("")),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🔥 Método para obtener redenciones desde Firebase
  Future<List<Map<String, dynamic>>> _obtenerRedenciones() async {
    try {
      QuerySnapshot redencionesSnapshot = await FirebaseFirestore.instance
          .collection('Ppl')
          .doc(widget.doc.id)
          .collection('redenciones')
          .orderBy('fecha_redencion', descending: true)
          .get();

      // ✅ Establecer el locale en español
      Intl.defaultLocale = 'es';

      List<Map<String, dynamic>> redenciones = redencionesSnapshot.docs.map((doc) {
        String fechaStr = doc['fecha_redencion'] ?? "";
        DateTime fecha;
        DateTime? fechaActualizacion;

        try {
          fecha = DateFormat('d/M/yyyy').parse(fechaStr);
        } catch (e) {
          debugPrint("❌ Error al parsear fecha_redencion: $fechaStr - $e");
          fecha = DateTime(2000, 1, 1);
        }

        if (doc['fecha_actualizacion'] != null) {
          if (doc['fecha_actualizacion'] is Timestamp) {
            fechaActualizacion = (doc['fecha_actualizacion'] as Timestamp).toDate();
          } else if (doc['fecha_actualizacion'] is String) {
            try {
              fechaActualizacion = DateTime.parse(doc['fecha_actualizacion']);
            } catch (e) {
              debugPrint("❌ Error al parsear fecha_actualizacion: ${doc['fecha_actualizacion']} - $e");
            }
          }
        }

        return {
          'id': doc.id,
          'dias_redimidos': (doc['dias_redimidos'] ?? 0).toDouble(),
          'fecha': fecha,
          'admin_nombre': doc['admin_nombre'] ?? "Desconocido",
          'admin_apellido': doc['admin_apellido'] ?? "",
          'fecha_actualizacion': fechaActualizacion,
        };
      }).toList();

      // 🔁 Aseguramos orden descendente por si el campo 'fecha_redencion' era inconsistente
      redenciones.sort((a, b) => b['fecha'].compareTo(a['fecha']));

      return redenciones;
    } catch (e) {
      debugPrint("❌ Error al obtener redenciones: $e");
      return [];
    }
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

      print("📌 Total días redimidos: $totalDias"); // 🔥 Mostrar en consola
    } catch (e) {
      print("❌ Error calculando redenciones: $e");
    }

    return totalDias;
  }

  Future<void> _fetchTodosCentrosReclusion() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collectionGroup('centros_reclusion')
          .get();

      List<Map<String, Object>> fetchedTodosCentros = querySnapshot.docs.map((doc) {
        final regionalId = doc.reference.parent.parent?.id ?? "";
        final data = doc.data() as Map<String, dynamic>; // Convertir a Map<String, dynamic>

        return {
          'id': doc.id,
          'nombre': data.containsKey('nombre') ? data['nombre'].toString() : '',
          'regional': regionalId,
          'correos': {
            'correo_direccion': data.containsKey('correo_direccion') ? data['correo_direccion'] ?? '' : '',
            'correo_juridica': data.containsKey('correo_juridica') ? data['correo_juridica'] ?? '' : '',
            'correo_principal': data.containsKey('correo_principal') ? data['correo_principal'] ?? '' : '',
            'correo_sanidad': data.containsKey('correo_sanidad') ? data['correo_sanidad'] ?? '' : '',
          }
        };
      }).toList();

      setState(() {
        centrosReclusionTodos = fetchedTodosCentros;
      });

    } catch (e) {
      if (kDebugMode) {
        print("Error al obtener centros de reclusión: $e");
      }
    }
  }

  Future<void> _fetchJuzgadosEjecucion() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('ejecucion_penas').get();

      List<Map<String, String>> fetchedEjecucionPenas = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'juzgadoEP': doc.get('juzgadoEP').toString(),
          'email': doc.get('email').toString(),
        };

      }).toList();

      setState(() {
        juzgadosEjecucionPenas = fetchedEjecucionPenas;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error al obtener los juzgados de ejecucion: $e");
      }
    }
  }

  Future<void> _fetchTodosJuzgadosConocimiento({bool forzar = false}) async {
    if (!forzar && juzgadosConocimiento.isNotEmpty) return;

    if (_isLoadingJuzgados) return; // Si ya está cargando, evitar múltiples llamadas
    _isLoadingJuzgados = true;

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collectionGroup('juzgados')
          .get();

      List<Map<String, String>> fetchedJuzgados = querySnapshot.docs.map((doc) {
        final ciudadId = doc.reference.parent.parent?.id ?? ""; // Obtener la ciudad (juzgado_condeno)
        final data = doc.data() as Map<String, dynamic>; // Convertir a Map

        return {
          'id': doc.id,
          'nombre': data['nombre'].toString(),
          'correo': data.containsKey('correo') ? data['correo'].toString() : '',
          'ciudad': ciudadId, // Asociar la ciudad del juzgado
        };
      }).toList();

      setState(() {
        juzgadosConocimiento = fetchedJuzgados;
      });

      debugPrint("✅ Juzgados de conocimiento cargados correctamente.");
    } catch (e) {
      debugPrint("❌ Error al obtener los juzgados de conocimiento: $e");
    } finally {
      _isLoadingJuzgados = false;
    }
  }


  // 🔹 Asigna el documento al operador actual para que solo él pueda verlo y editarlo
  Future<void> _asignarDocumento() async {
    String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    try {
      // 🔹 Obtener datos del usuario desde Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('admin').doc(currentUserUid).get();

      if (!userDoc.exists || userDoc.data() == null) {
        print("❌ No se encontró información del usuario en Firestore.");
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String nombreAdmin = userData['name'] ?? "Desconocido";
      String apellidoAdmin = userData['apellidos'] ?? "Desconocido";
      String nombreCompleto = "$nombreAdmin $apellidoAdmin";
      String userRole = userData['rol']?.toLowerCase() ?? "";

      // 🔥 Solo los operadores pueden asignar documentos
      List<String> rolesPermitidos = ["operador 1", "operador 2", "operador 3"];
      if (!rolesPermitidos.contains(userRole)) {
        print("🚫 El usuario $nombreCompleto con rol '$userRole' NO tiene permisos para asignar documentos.");
        return;
      }
      print("✅ Usuario $nombreCompleto tiene permisos para asignar documentos.");

      // 🔍 Verificar el estado del documento antes de asignarlo
      DocumentSnapshot documentoSnapshot = widget.doc;
      if (!documentoSnapshot.exists || documentoSnapshot.data() == null) {
        print("❌ No se encontró el documento.");
        return;
      }

      Map<String, dynamic> documentoData = documentoSnapshot.data() as Map<String, dynamic>;
      String statusDocumento = documentoData['status']?.toLowerCase() ?? "";
      String assignedTo = documentoData['assignedTo'] ?? "";

      if (statusDocumento != "registrado") {
        print("🚫 El documento no está en estado 'registrado'. No se realizará la asignación.");
        return;
      }

      if (assignedTo.isNotEmpty) {
        if (assignedTo == currentUserUid) {
          print("🔹 El documento ya está asignado a este usuario. No se creará otra acción de asignación.");
        } else {
          print("⚠️ El documento ya fue asignado a otro usuario ($assignedTo). No se puede asignar nuevamente.");
        }
        return;
      }

      // 🔹 Actualizar el campo `assignedTo` con el ID del operador
      await widget.doc.reference.update({
        'assignedTo': currentUserUid,
      });

      // 🔹 Guardar asignación en historial con el nombre completo
      await widget.doc.reference.collection('historial_acciones').add({
        'accion': 'asignación',
        'asignado_a': nombreCompleto,
        'admin_id': currentUserUid,
        'fecha': DateTime.now().toString(),
      });

      print("✅ Documento asignado a $nombreCompleto correctamente.");
    } catch (e) {
      print("❌ Error al asignar el documento: $e");
    }
  }

// 🔹 Libera el documento cuando se cierra la pantalla- temporalmente desactivado
  Future<void> _liberarDocumento() async {
    try {
      await widget.doc.reference.update({'lockedBy': ""});
    } catch (e) {
      if (kDebugMode) {
        print("Error al liberar el documento: $e");
      }
    }
  }

  Future<String> obtenerRolActual() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return ""; // Si no hay usuario autenticado, retorna vacío
      }

      // Instancia del provider para obtener el rol
      AdminProvider adminProvider = AdminProvider();
      await adminProvider.loadAdminData(); // Cargar los datos del admin

      return adminProvider.rol ?? ""; // Retorna el rol si existe, sino retorna vacío
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error obteniendo el rol: $e");
      }
      return "";
    }
  }

  Widget infoPplNoRecluido() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: blanco,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            "Información de residencia del PPL",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.1),
          ),
          const SizedBox(height: 20),
          direccionPpl(),
          const SizedBox(height: 20),
          _buildSeleccionDepartamentoMunicipioPplForm(),
          const SizedBox(height: 20),
          guardarInfoResidenciaButton(
            docId: widget.doc.id,
            departamentoActual: departamentoSeleccionado ?? '',
            municipioActual: municipioSeleccionado ?? '',
          ),

        ],
      ),
    );
  }

  Widget direccionPpl() {
    _direccionController.text = widget.doc['direccion'] ?? ''; // ✅ Asegura valor inicial
    return TextFormField(
      controller: _direccionController,
      decoration: InputDecoration(
        labelText: 'Dirección',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

  Widget _buildSeleccionDepartamentoMunicipioPplForm() {
    return DepartamentosMunicipiosWidget(
      departamentoSeleccionado: departamentoSeleccionado,
      municipioSeleccionado: municipioSeleccionado,
      onSelectionChanged: (String dpto, String muni) {
        setState(() {
          departamentoSeleccionado = dpto;
          municipioSeleccionado = muni;
        });
      },
    );
  }

  Widget guardarInfoResidenciaButton({
    required String docId,
    required String departamentoActual,
    required String municipioActual,
  }) {
    return SizedBox(
      width: 250,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.save),
        label: const Text("Guardar información"),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        onPressed: () async {
          final confirmar = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: blanco,
              title: const Text("¿Confirmar cambios?"),
              content: const Text("¿Está seguro de editar esta información de residencia?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Sí, guardar"),
                ),
              ],
            ),
          );

          if (confirmar != true) return;

          final direccionActual = _direccionController.text.trim();

          try {
            await FirebaseFirestore.instance.collection('Ppl').doc(docId).update({
              'direccion': direccionActual,
              'departamento': departamentoActual,
              'municipio': municipioActual,
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Información actualizada correctamente."),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Error al guardar: $e"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget seleccionarCentroReclusion() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: (widget.doc["situacion"] == "En Prisión domiciliaria" ||
                  widget.doc["situacion"] == "En libertad condicional")
                  ? Colors.black
                  : primary,
              width: (widget.doc["situacion"] == "En Prisión domiciliaria" ||
                  widget.doc["situacion"] == "En libertad condicional")
                  ? 3
                  : 1.5,
            ),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16), // Espacio extra para que no tape el contenido
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(), // El título ahora está en la pestañita
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _mostrarDropdowns = true;
                        selectedCentro = null;
                      });
                      _fetchTodosCentrosReclusion();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: centroValidado ? Colors.green : primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    child: Text(centroValidado ? "Validado" : "Validar centro"),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(widget.doc['regional'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, height: 1)),
              const SizedBox(height: 6),
              Text(widget.doc['centro_reclusion'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, height: 1)),
              const SizedBox(height: 12),
              if (_mostrarDropdowns) ...[
                const SizedBox(height: 18),
                Autocomplete<Map<String, dynamic>>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<Map<String, dynamic>>.empty();
                    }
                    return centrosReclusionTodos.where((option) =>
                        option['nombre']
                            .toString()
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()));
                  },
                  displayStringForOption: (option) => option['nombre'],
                  fieldViewBuilder:
                      (context, controller, focusNode, onEditingComplete) {
                    _centroController = controller;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: "Busca ingresando la ciudad",
                        labelText: "Centro de reclusión",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.grey, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.grey, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.grey, width: 1),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                    );
                  },
                  onSelected: (Map<String, dynamic> option) {
                    setState(() {
                      selectedCentro = option['id']?.toString();
                      selectedRegional = option['regional']?.toString();
                    });
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        color: Colors.amber.shade50,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          constraints: const BoxConstraints(
                            maxHeight: 250,
                            minWidth: 100,
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(option['nombre']),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    final nombreCentro =
                        widget.doc['centro_reclusion']?.toString() ?? '';
                    if (nombreCentro.isNotEmpty) {
                      setState(() {
                        _centroController.text = nombreCentro;
                      });
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text("Cargar centro guardado"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 10),
                if (selectedCentro != null)
                  Text(
                    "Centro seleccionado: ${centrosReclusionTodos.firstWhere(
                          (centro) => centro['id'].toString() == selectedCentro,
                      orElse: () => {'nombre': 'No encontrado'},
                    )['nombre']}",
                    style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                  ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _mostrarDropdowns = false;
                        selectedCentro = null;
                      });
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cancel, size: 15),
                        Text("Cancelar", style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // 🔲 Pestañita negra superior izquierda
        Positioned(
          top: -10,
          left: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: const Text(
              "Centro de reclusión",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget seleccionarJuzgadoEjecucionPenas() {
    if (!_mostrarDropdownJuzgadoEjecucion &&
        widget.doc['juzgado_ejecucion_penas'] != null &&
        widget.doc['juzgado_ejecucion_penas'].toString().trim().isNotEmpty) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16), // espacio para que la pestaña no tape
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _mostrarDropdownJuzgadoEjecucion = true;
                      selectedJuzgadoEjecucionPenas = null;
                      selectedJuzgadoEjecucionEmail = null;
                      selectedCiudad = null;
                    });
                    _fetchJuzgadosEjecucion();
                  },
                  child: const Row(
                    children: [
                      Text("Juzgado de Ejecución de Penas", style: TextStyle(fontSize: 11)),
                      Icon(Icons.edit, size: 15),
                    ],
                  ),
                ),
                Text(
                  widget.doc['juzgado_ejecucion_penas'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, height: 1),
                ),
                const SizedBox(height: 10),
                Text(
                  "correo: ${widget.doc['juzgado_ejecucion_penas_email'] ?? 'No disponible'}",
                  style: const TextStyle(fontSize: 12, height: 1),
                ),
              ],
            ),
          ),
          // 🟣 Pestañita negra arriba a la izquierda
          Positioned(
            top: -10,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: const Text(
                "Juzgado de Ejecución de Penas",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (juzgadosEjecucionPenas.isEmpty) {
      Future.microtask(() => _fetchJuzgadosEjecucion());
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: primary),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Buscar Juzgado de Ejecución de Penas",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),

          Autocomplete<Map<String, String>>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<Map<String, String>>.empty();
              }
              return juzgadosEjecucionPenas
                  .where((juzgado) => (juzgado['juzgadoEP'] ?? '')
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase()))
                  .map((juzgado) {
                final nombre = juzgado['juzgadoEP'] ?? '';
                final ciudad = nombre.contains(' - ') ? nombre.split(' - ')[0].trim() : '';
                return {
                  'juzgadoEP': nombre,
                  'email': juzgado['email'] ?? '',
                  'ciudad': ciudad,
                };
              });
            },
            displayStringForOption: (option) => option['juzgadoEP']!,
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: "Busca ingresando el nombre",
                      labelText: "Juzgado de Ejecución de Penas",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      suffixIcon: selectedJuzgadoEjecucionPenas != null
                          ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            selectedJuzgadoEjecucionPenas = null;
                            selectedJuzgadoEjecucionEmail = null;
                            selectedCiudad = null;
                            textEditingController.clear();
                          });
                        },
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (selectedCiudad != null || selectedJuzgadoEjecucionEmail != null) ...[
                    if (selectedCiudad != null) ...[
                      const Text("Ciudad del Juzgado", style: TextStyle(fontSize: 11)),
                      Text(
                        selectedCiudad!,
                        style: const TextStyle(fontWeight: FontWeight.bold, height: 1),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (selectedJuzgadoEjecucionEmail != null) ...[
                      Text(
                        'Correo: ${selectedJuzgadoEjecucionEmail ?? 'No disponible'}',
                        style: const TextStyle(fontSize: 12, height: 1.3),
                      ),
                    ]
                  ],
                ],
              );
            },
            onSelected: (Map<String, String> option) {
              setState(() {
                selectedJuzgadoEjecucionPenas = option['juzgadoEP'];
                selectedJuzgadoEjecucionEmail = option['email'];
                selectedCiudad = option['ciudad'];
              });
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: blanco,
                  elevation: 4.0,
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(option['juzgadoEP']!),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Ciudad: ${option['ciudad']}"),
                            Text("Correo: ${option['email'] ?? 'No disponible'}"),
                          ],
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 25),
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _mostrarDropdownJuzgadoEjecucion = false;
                  selectedJuzgadoEjecucionPenas = widget.doc['juzgado_ejecucion_penas'];
                  selectedJuzgadoEjecucionEmail = widget.doc['juzgado_ejecucion_penas_email'];
                  selectedCiudad = null;
                });
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.cancel, size: 15),
                  Text("Cancelar", style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          Align(
            alignment: Alignment.topRight,
            child: ElevatedButton.icon(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const SizedBox(
                      width: 600,
                      child: IngresarJuzgadoEjecucionWidget(),
                    ),
                  ),
                ).then((_) async {
                  await _fetchJuzgadosEjecucion();
                  setState(() {});
                });
              },
              icon: const Icon(Icons.add),
              label: const Text("Crear nuevo juzgado de Ejecución"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget seleccionarJuzgadoQueCondeno() {
    if (!_mostrarDropdownJuzgadoCondeno &&
        widget.doc['juzgado_que_condeno'] != null &&
        widget.doc['juzgado_que_condeno'].toString().trim().isNotEmpty) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16), // Espacio para que la pestaña no tape
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _mostrarDropdownJuzgadoCondeno = true;
                      selectedJuzgadoNombre = null;
                      selectedCiudad = null;
                      selectedJuzgadoConocimientoEmail = null;
                    });
                    _fetchTodosJuzgadosConocimiento();
                  },
                  child: const Row(
                    children: [
                      Text("Ciudad del Juzgado", style: TextStyle(fontSize: 11)),
                      Icon(Icons.edit, size: 15),
                    ],
                  ),
                ),
                Text(
                  widget.doc['ciudad'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, height: 1),
                ),
                const SizedBox(height: 10),
                const Text("Juzgado de Conocimiento", style: TextStyle(fontSize: 11)),
                Text(
                  widget.doc['juzgado_que_condeno'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, height: 1),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("correo: ", style: TextStyle(fontSize: 12)),
                    Text(
                      widget.doc['juzgado_que_condeno_email'] ?? 'No disponible',
                      style: const TextStyle(fontSize: 12, height: 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 🟣 Pestañita negra arriba a la izquierda
          Positioned(
            top: -10,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: const Text(
                "Juzgado de conocimiento",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (juzgadosConocimiento.isEmpty) {
      Future.microtask(() => _fetchTodosJuzgadosConocimiento());
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: primary),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Buscar Juzgado de Conocimiento",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Autocomplete<Map<String, String>>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<Map<String, String>>.empty();
              }
              return juzgadosConocimiento
                  .map((juzgado) => {
                'nombre': juzgado['nombre'].toString(),
                'correo': juzgado['correo'].toString(),
                'ciudad': juzgado['ciudad'].toString(),
              })
                  .where((juzgado) => juzgado['nombre']!
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase()));
            },
            displayStringForOption: (option) => option['nombre']!,
            fieldViewBuilder:
                (context, textEditingController, focusNode, onFieldSubmitted) {
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: "Busca ingresando el nombre",
                  labelText: "Juzgado de conocimiento",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  suffixIcon: selectedJuzgadoNombre != null
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        selectedJuzgadoNombre = null;
                        selectedCiudad = null;
                        selectedJuzgadoConocimientoEmail = null;
                        textEditingController.clear();
                      });
                    },
                  )
                      : null,
                ),
              );
            },
            onSelected: (option) {
              setState(() {
                selectedJuzgadoNombre = option['nombre'];
                selectedCiudad = option['ciudad'];
                selectedJuzgadoConocimientoEmail = option['correo'];
              });
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.grey[200],
                  elevation: 4.0,
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(option['nombre']!),
                        subtitle: Text("Ciudad: ${option['ciudad']!}"),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          if (selectedJuzgadoNombre != null && selectedCiudad != null) ...[
            const Text("Ciudad del Juzgado", style: TextStyle(fontSize: 11)),
            Text(
              selectedCiudad!,
              style: const TextStyle(fontWeight: FontWeight.bold, height: 1),
            ),
            const SizedBox(height: 8),
            Text(
              'Correo: ${selectedJuzgadoConocimientoEmail ?? 'No disponible'}',
              style: const TextStyle(fontSize: 12, height: 1.3),
            ),
          ],
          const SizedBox(height: 25),
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _mostrarDropdownJuzgadoCondeno = false;
                  selectedJuzgadoNombre = null;
                  selectedCiudad = null;
                  selectedJuzgadoConocimientoEmail = null;
                });
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.cancel, size: 15),
                  Text("Cancelar", style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          Align(
            alignment: Alignment.topRight,
            child: ElevatedButton.icon(
              onPressed: () async {
                final textoAnterior = _autocompleteController.text;
                await showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: const SizedBox(
                      width: 600,
                      child: Padding(
                        padding: EdgeInsets.all(0),
                        child: IngresarJuzgadoCondenoWidget(),
                      ),
                    ),
                  ),
                ).then((_) async {
                  await _fetchTodosJuzgadosConocimiento(forzar: true);
                  setState(() {
                    _autocompleteController.text = '';
                  });
                  Future.delayed(const Duration(milliseconds: 50), () {
                    setState(() {
                      _autocompleteController.text = textoAnterior;
                      _autocompleteController.selection =
                          TextSelection.fromPosition(
                            TextPosition(
                                offset: _autocompleteController.text.length),
                          );
                    });
                  });
                });
              },
              icon: const Icon(Icons.add),
              label: const Text("Crear nuevo juzgado de conocimiento"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _obtenerDatos() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentSnapshot document = await firestore.collection('Ppl').doc(widget.doc.id).get();
    if (document.exists) {
      final Map<String, dynamic> data = document.data() as Map<String, dynamic>;
      final String juzgado = data['juzgado_que_condeno'];
      final String juzgadoQueCondeno = data['ciudad'];
      setState(() {
        _juzgado = juzgado;
        _juzgadoQueCondeno = juzgadoQueCondeno;
      });
    } else {
      if (kDebugMode) {
        print('El documento no existe');
      }
    }
  }

  Future<void> _cargarDatos() async {
    final doc = await FirebaseFirestore.instance.collection('Ppl').doc(widget.doc.id).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        isExento = data['exento'] ?? false;
        cargando = false;
      });
    }
  }

  void _initCalculoCondena() async {
    try {
      await _calculoCondenaController.calcularTiempo(widget.doc.id);

      setState(() {
        mesesRestante = _calculoCondenaController.mesesRestante ?? 0;
        diasRestanteExactos = _calculoCondenaController.diasRestanteExactos ?? 0;
        mesesEjecutado = _calculoCondenaController.mesesEjecutado ?? 0;
        diasEjecutadoExactos = _calculoCondenaController.diasEjecutadoExactos ?? 0;
        porcentajeEjecutado = _calculoCondenaController.porcentajeEjecutado ?? 0.0;
        tiempoCondena = _calculoCondenaController.tiempoCondena ?? 0;

      });

      debugPrint("✅ Cálculo actualizado (desde controller): Meses ejecutados=$mesesEjecutado, Días ejecutados=$diasEjecutadoExactos, Porcentaje ejecutado=${porcentajeEjecutado.toStringAsFixed(1)}%");
    } catch (e) {
      debugPrint("❌ Error en _initCalculoCondena: $e");
    }
  }


  void _initFormFields() {
    final data = widget.doc.data() as Map<String, dynamic>;

    _nombreController.text = data['nombre_ppl'] ?? "";
    _apellidoController.text = data['apellido_ppl'] ?? "";
    _numeroDocumentoController.text = data['numero_documento_ppl']?.toString() ?? "";
    _tipoDocumento = data['tipo_documento_ppl'] ?? "";
    _radicadoController.text = data['radicado'] ?? "";
    _tdController.text = data['td'] ?? "";
    _nuiController.text = data['nui'] ?? "";
    _patioController.text = data['patio'] ?? "";
    _nombreAcudienteController.text = data['nombre_acudiente'] ?? "";
    _apellidosAcudienteController.text = data['apellido_acudiente'] ?? "";
    _parentescoAcudienteController.text = data['parentesco_representante'] ?? "";
    _celularAcudienteController.text = data['celular'] ?? "";

    // 🔒 Este campo puede no existir en registros antiguos
    _celularWhatsappController.text = data.containsKey('celularWhatsapp') ? data['celularWhatsapp'] ?? "" : "";

    _emailAcudienteController.text = data['email'] ?? "";
    _direccionController.text = data['direccion'] ?? "";
  }

  Widget _datosEjecucionCondena(double totalDiasRedimidos, bool isExento) {
    final meses = _calculoCondenaController.mesesEjecutado ?? 0;
    final dias = _calculoCondenaController.diasEjecutadoExactos ?? 0;
    final mesesRestantes = _calculoCondenaController.mesesRestante ?? 0;
    final diasRestantes = _calculoCondenaController.diasRestanteExactos ?? 0;
    final porcentaje = _calculoCondenaController.porcentajeEjecutado ?? 0.0;

    return Column(
      children: [
        if (isExento)
          Card(
            color: Colors.amber.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.red, width: 2),
            ),
            elevation: 3,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Esta persona ha sido determinada como EXENTA según el Artículo 68A. Imposibilidad de solicitud de beneficios penitenciarios',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        DatosEjecucionCondena(
          mesesEjecutado: meses,
          diasEjecutadoExactos: dias,
          mesesRestante: mesesRestantes,
          diasRestanteExactos: diasRestantes,
          totalDiasRedimidos: totalDiasRedimidos,
          porcentajeEjecutado: porcentaje,
          primary: Colors.grey,
          negroLetras: Colors.black,
        ),
      ],
    );
  }

  Widget nombrePpl() {
    return textFormField(
      controller: _nombreController,
      labelText: 'Nombre',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese el nombre del ppl';
        }
        return null;
      },
    );
  }

  Widget apellidoPpl(){
    return textFormField(
      controller: _apellidoController,
      labelText: 'Apellidos',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese los apellidos del ppl';
        }
        return null;
      },
    );
  }

  Widget numeroDocumentoPpl(){
    return textFormField(
      controller: _numeroDocumentoController,
      labelText: 'Número de documento',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese el número de documento del ppl';
        }
        return null;
      },
    );
  }

  // Método auxiliar para formatear números con dos dígitos
  String _formatDosDigitos(int n) => n.toString().padLeft(2, '0');

  // Método para seleccionar la fecha
  Future<void> _seleccionarFechaCaptura(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.deepPurple,
            hintColor: Colors.deepPurple,
            colorScheme: const ColorScheme.light(primary: Colors.deepPurple),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
  }

  Widget radicadoPpl(){
    return textFormField(
      controller: _radicadoController,
      labelText: 'Radicado No.',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese el número de radicado';
        }
        return null;
      },
    );
  }

  Widget condenaPpl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Tiempo de condena", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _mesesCondenaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Meses de condena',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey, width: 2),
                  ),
                ),
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed < 0) return 'Ingrese meses válidos';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _diasCondenaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Días',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey, width: 2),
                  ),
                ),
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed < 0 || parsed >= 30) {
                    return '0 a 29';
                  }
                  return null;
                },
              ),
            ),
          ],
        )
      ],
    );
  }

  void cargarCondenaDesdeDocumento(int meses, int dias) {
    _mesesCondenaController.text = meses.toString();
    _diasCondenaController.text = dias.toString();
  }

  Widget tdPpl(){
    return textFormField(
      controller: _tdController,
      labelText: 'TD',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese el TD';
        }
        return null;
      },
    );
  }

  Widget nuiPpl(){
    return textFormField(
      controller: _nuiController,
      labelText: 'NUI',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese el NUI';
        }
        return null;
      },
    );
  }

  Widget patioPpl(){
    return textFormField(
      controller: _patioController,
      labelText: 'Patio No.',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese el patio';
        }
        return null;
      },
    );
  }

  Widget nombreAcudiente(){
    return textFormField(
      controller: _nombreAcudienteController,
      labelText: 'Nombre acudiente',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese el nombre de acudiente';
        }
        return null;
      },
    );
  }

  Widget apellidosAcudiente(){
    return textFormField(
      controller: _apellidosAcudienteController,
      labelText: 'Apellidos acudiente',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese los apellidos de acudiente';
        }
        return null;
      },
    );
  }

  Widget parentescoAcudiente(){
    return textFormField(
      controller: _parentescoAcudienteController,
      labelText: 'Parentesco',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese el parentesco';
        }
        return null;
      },
    );
  }

  Widget celularAcudiente(){
    return textFormField(
      controller: _celularAcudienteController,
      labelText: 'Celular',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese el celular';
        }
        return null;
      },
    );
  }

  Widget celularWhatsappAcudiente() {
    return textFormField(
      controller: _celularWhatsappController,
      labelText: 'WhatsApp',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese el celular de WhatsApp';
        }
        return null;
      },
    );
  }


  Widget emailAcudiente(){
    return textFormField(
      controller: _emailAcudienteController,
      labelText: 'Email',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese el email';
        }
        return null;
      },
    );
  }

  Widget textFormField({
    required TextEditingController controller,
    required String labelText,
    String? initialValue,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isFieldEmpty = controller.text.trim().isEmpty;
        bool hasFocus = false;

        return Focus(
          onFocusChange: (focus) {
            setState(() {
              hasFocus = focus;
              isFieldEmpty = controller.text.trim().isEmpty;
            });
          },
          child: TextFormField(
            controller: controller,
            initialValue: initialValue,
            style: const TextStyle(fontWeight: FontWeight.bold, height: 1),
            decoration: InputDecoration(
              labelText: labelText, // 🔹 Se mantiene el label arriba
              labelStyle: TextStyle(
                color: isFieldEmpty ? Colors.red.shade900 : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isFieldEmpty ? Colors.red.shade900 : Colors.grey,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isFieldEmpty ? Colors.red.shade900 : primary,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isFieldEmpty ? Colors.red.shade900 : Colors.grey,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.red.shade900,
                  width: 2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.red.shade900,
                  width: 2,
                ),
              ),
              hintText: hasFocus ? '' : labelText, // 🔥 Oculta el hint al enfocar
              hintStyle: const TextStyle(color: Colors.transparent), // 🔥 Hace invisible el hint
            ),
            validator: (value) {
              bool empty = value == null || value.trim().isEmpty;
              setState(() => isFieldEmpty = empty);
              return empty ? 'Por favor ingrese $labelText' : null;
            },
            keyboardType: keyboardType,
          ),
        );
      },
    );
  }

  Widget bloquearUsuario() {
    return SizedBox(
      width: 220,
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () async {
            bool confirmacion = await _mostrarConfirmacionBloqueo();
            if (!confirmacion) return;

            try {
              User? user = FirebaseAuth.instance.currentUser;
              String adminName = "Desconocido";
              String adminId = user?.uid ?? "Desconocido";

              DocumentSnapshot adminDoc = await FirebaseFirestore.instance.collection('admin').doc(adminId).get();
              if (adminDoc.exists) {
                adminName = "${adminDoc['name']} ${adminDoc['apellidos']}";
              }

              // Guardar en Firestore
              await widget.doc.reference.update({
                'status': 'bloqueado',
              });

              // Guardar la acción en la subcolección historial_acciones
              await widget.doc.reference.collection('historial_acciones').add({
                'admin': adminName,
                'accion': 'bloqueo',
                'fecha': DateTime.now().toString(),
              });

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usuario bloqueado con éxito.'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.red,
                  ),
                );
              }

              Future.delayed(const Duration(seconds: 1), () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeAdministradorPage()),
                );
              });
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al bloquear el usuario: $error'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'BLOQUEAR USUARIO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  /// 🔹 Función para mostrar la confirmación antes de bloquear al usuario
  Future<bool> _mostrarConfirmacionBloqueo() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: blancoCards,
          title: const Text("Confirmar bloqueo"),
          content: const Text("¿Estás seguro de que deseas bloquear a este usuario?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // ❌ Devuelve "false" si cancela
              },
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // ✅ Devuelve "true" si confirma
              },
              child: const Text("Bloquear", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    ) ??
        false; // Si el usuario cierra el diálogo sin elegir, retorna "false"
  }

  Future<bool> _adminPuedeDesbloquear() async {
    String adminRole = await obtenerRolActual(); // Ahora se obtiene el rol real desde Firebase

    List<String> rolesPermitidos = ["master", "masterFull", "coordinador 1", "coordinador 2"];

    return rolesPermitidos.contains(adminRole);
  }

  Widget desbloquearUsuario() {
    return SizedBox(
      width: 200,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () async {
            bool confirmacion = await _mostrarConfirmacionDesbloqueo();
            if (!confirmacion) return;

            try {
              User? user = FirebaseAuth.instance.currentUser;
              String adminName = "Desconocido";
              String adminId = user?.uid ?? "Desconocido";

              DocumentSnapshot adminDoc = await FirebaseFirestore.instance.collection('admin').doc(adminId).get();
              if (adminDoc.exists) {
                adminName = "${adminDoc['name']} ${adminDoc['apellidos']}";
              }

              // Guardar en Firestore
              await widget.doc.reference.update({
                'status': 'activado',
              });

              // Guardar la acción en la subcolección historial_acciones
              await widget.doc.reference.collection('historial_acciones').add({
                'admin': adminName,
                'accion': 'desbloqueo',
                'fecha': DateTime.now().toString(),
              });
              if(context.mounted){
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usuario desbloqueado con éxito.'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              Future.delayed(const Duration(seconds: 1), () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeAdministradorPage()),
                );
              });
            } catch (error) {
              if(context.mounted){
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al desbloquear el usuario: $error'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Desbloquear Usuario'),
        ),
      ),
    );
  }

  Future<bool> _mostrarConfirmacionDesbloqueo() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: blancoCards,
          title: const Text('Confirmar Desbloqueo'),
          content: const Text('¿Estás seguro de que deseas desbloquear a este usuario?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Desbloquear'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Widget historialAccionUsuario() {
    return StreamBuilder<QuerySnapshot>(
      stream: widget.doc.reference
          .collection('historial_acciones')
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Text("No hay historial de acciones.");
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: snapshot.data!.docs.map((doc) {
            Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;

            // 🔥 Corrección aquí
            String admin = docData['admin'] ?? docData['asignado_a'] ?? "Desconocido";
            String accion = docData['accion'] ?? "Ninguna";

            // ✅ Safe null check for 'assignedTo'
            String? assignedTo = docData.containsKey('assignedTo') ? docData['assignedTo'] : null;

            dynamic fechaRaw = docData['fecha']; // 🔥 Puede ser Timestamp o String
            DateTime? fecha = _convertirFecha(fechaRaw);
            String fechaFormateada = _formatFecha(fecha);

            // 🔹 Define color and icon based on action
            Color color;
            IconData icono;
            String textoAccion;

            if (accion == "bloqueo") {
              color = Colors.red;
              icono = Icons.lock;
              textoAccion = "Bloqueado por: ";
            } else if (accion == "desbloqueo") {
              color = Colors.blue;
              icono = Icons.lock_open;
              textoAccion = "Desbloqueado por: ";
            }else if (accion == "Cambio de celular") {
              color = Colors.blue;
              icono = Icons.call;
              textoAccion = "Cambio de celular";
            }
            else if (accion == "activado") {
              color = Colors.green;
              icono = Icons.check_circle;
              textoAccion = "Activado por: ";
            } else if (accion == "actualización") {
              color = Colors.orange;
              icono = Icons.edit_note_outlined;
              textoAccion = "Actualizado por: ";
            } else if (accion == "asignación") {
              color = Colors.purple;
              icono = Icons.assignment_ind;
              textoAccion = "Asignado a: ";
            } else {
              color = Colors.grey;
              icono = Icons.info;
              textoAccion = "Acción realizada por: ";
            }

            return ListTile(
              leading: Icon(icono, color: color),
              title: Text(
                (accion == "asignación" && assignedTo != null)
                    ? "$textoAccion $assignedTo" // ✅ Usa `assignedTo` si es una asignación
                    : "$textoAccion $admin", // ✅ Usa `admin` o `asignado_a`
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Fecha: $fechaFormateada",
                style: const TextStyle(fontSize: 11),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// 📆 Convierte un String o Timestamp a DateTime
  DateTime? _convertirFecha(dynamic fechaRaw) {
    if (fechaRaw == null) return null;

    if (fechaRaw is Timestamp) {
      return fechaRaw.toDate(); // ✅ Convierte Timestamp a DateTime
    } else if (fechaRaw is String) {
      try {
        return DateTime.parse(fechaRaw); // ✅ Intenta convertir String a DateTime
      } catch (e) {
        debugPrint("❌ Error al convertir String a DateTime: $e");
        return null;
      }
    }
    return null; // ❌ Si el tipo no es compatible, retorna null
  }

  /// 📆 Función para manejar errores en la conversión de fechas
  String _formatFecha(DateTime? fecha, {String formato = "dd 'de' MMMM 'de' yyyy - hh:mm a"}) {
    if (fecha == null) return "Fecha no disponible";
    return DateFormat(formato, 'es').format(fecha);
  }

  Widget botonGuardar() {
    bool marcarParaSeguimiento = false;
    return SizedBox(
      width: 180,
      child: Align(
        alignment: Alignment.center,
        child: GestureDetector(
            onTap: () async {
              bool confirmar = await _mostrarDialogoConfirmacionBotonGuardar();
              if (!confirmar) return;

              final docSnapshot = await widget.doc.reference.get();
              final data = docSnapshot.data() as Map<String, dynamic>?;

              // Validaciones iniciales...
              final centroValidado = data?['centro_validado'] == true;
              final centroFinal = selectedCentro ?? widget.doc['centro_reclusion'] ?? '';
              final situacion = data?['situacion']?.toString().trim() ?? '';

              if (situacion == 'En Reclusión' && !centroValidado && _centroController.text.trim().isEmpty) {
                if (context.mounted) {
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.white,
                      title: const Text("Centro de reclusión requerido"),
                      content: const Text("Debes validar el centro de reclusión antes de guardar."),
                      actions: [
                        TextButton(
                          child: const Text("Cerrar"),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  );
                }
                return;
              }

              final rawFechaCaptura = data?['fecha_captura'];
              final tieneFechaCaptura = rawFechaCaptura != null && rawFechaCaptura.toString().trim().isNotEmpty;

              final eventoSinFechaCaptura = await widget.doc.reference
                  .collection('eventos')
                  .doc('sin_fecha_captura')
                  .get();
              final tieneEventoSinFechaCaptura = eventoSinFechaCaptura.exists;

              if (!tieneFechaCaptura && !tieneEventoSinFechaCaptura) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("⚠️ Este PPL no tiene fecha de captura registrada."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              List<String> camposFaltantes = [];

              if (situacion == 'En Reclusión') {
                String? centro = selectedCentro ?? widget.doc['centro_reclusion'];
                if (centro == null || centro.trim().isEmpty) camposFaltantes.add("Centro de Reclusión");
                if (_tdController.text.trim().isEmpty) camposFaltantes.add("TD");
                if (_nuiController.text.trim().isEmpty) camposFaltantes.add("NUI");
                if (_patioController.text.trim().isEmpty) camposFaltantes.add("Patio");
              }

              if ((selectedRegional ?? widget.doc['regional'])?.toString().trim().isEmpty ?? true)
                camposFaltantes.add("Regional");
              if ((selectedCiudad ?? widget.doc['ciudad'])?.toString().trim().isEmpty ?? true)
                camposFaltantes.add("Ciudad");
              if ((selectedDelito ?? widget.doc['delito'])?.toString().trim().isEmpty ?? true)
                camposFaltantes.add("Delito");
              if ((selectedJuzgadoEjecucionPenas ?? widget.doc['juzgado_ejecucion_penas'])?.toString().trim().isEmpty ?? true)
                camposFaltantes.add("Juzgado de Ejecución de Penas");
              if ((selectedJuzgadoNombre ?? widget.doc['juzgado_que_condeno'])?.toString().trim().isEmpty ?? true)
                camposFaltantes.add("Juzgado que Condenó");
              if (_radicadoController.text.trim().isEmpty) camposFaltantes.add("Radicado");
              if (_nombreController.text.trim().isEmpty) camposFaltantes.add("Nombre");
              if (_apellidoController.text.trim().isEmpty) camposFaltantes.add("Apellido");
              if (_numeroDocumentoController.text.trim().isEmpty) camposFaltantes.add("Número de Documento");
              if ((int.tryParse(_mesesCondenaController.text) ?? 0) <= 0)
                camposFaltantes.add("Meses de condena (debe ser mayor a 0)");
              if (_celularWhatsappController.text.trim().isEmpty) camposFaltantes.add("Número de WhatsApp");

              bool tieneEvento = await tieneEventoEspecial(widget.doc.reference);
              String comentario = "";
              bool tieneProcesoEnTribunal = false;

              try {
                final eventoDoc = await widget.doc.reference
                    .collection('eventos')
                    .doc('proceso_en_tribunal')
                    .get();
                tieneProcesoEnTribunal = eventoDoc.exists;
              } catch (e) {
                tieneProcesoEnTribunal = false;
              }

              if (camposFaltantes.isNotEmpty) {
                if (tieneEvento || tieneProcesoEnTribunal) {
                  if (context.mounted) {
                    comentario = await _mostrarDialogoActivacionConDatosIncompletos(
                      context,
                      camposFaltantes.join(", "),
                    );
                  }
                  if (comentario.trim().isEmpty) return;
                } else {
                  if (context.mounted) {
                    comentario = await _mostrarDialogoComentarioPendiente(
                      context,
                      camposFaltantes.join(", "),
                    );
                  }
                  if (comentario.trim().isEmpty) return;
                }
              } else if (tieneProcesoEnTribunal) {
                if (context.mounted) {
                  comentario = await _mostrarDialogoActivacionConDatosIncompletos(
                    context,
                    "Proceso en tribunal",
                  );
                }
                if (comentario.trim().isEmpty) return;
              } else if (tieneEventoSinFechaCaptura) {
                if (context.mounted) {
                  comentario = await _mostrarDialogoActivacionConDatosIncompletos(
                    context,
                    "Sin fecha de captura (evento activado)",
                  );
                }
                if (comentario.trim().isEmpty) return;
              } else {
                if (context.mounted) {
                  final resultadoComentario = await _mostrarDialogoComentarioObligatorio(
                    context,
                    FirebaseFirestore.instance.collection('Ppl').doc(ppl.id),
                    widget.doc.reference.collection('seguimiento'),
                    adminFullName,
                  );

                  comentario = resultadoComentario['comentario'] ?? '';
                  marcarParaSeguimiento = resultadoComentario['seguimiento'] ?? false;
                }

                if (comentario.trim().isEmpty && !marcarParaSeguimiento) return;
              }

              if (marcarParaSeguimiento) {
                await widget.doc.reference.collection('seguimiento').add({
                  'fecha_inicio': DateTime.now(),
                  'creado_por': adminFullName,
                  'comentario': comentario,
                  'activo': true,
                });

                await widget.doc.reference.update({
                  'tiene_seguimiento_activo': true,
                });
              }

              // Correos del centro
              Map<String, String> correosCentro = {
                'correo_direccion': '',
                'correo_juridica': '',
                'correo_principal': '',
                'correo_sanidad': '',
              };

              if (situacion == 'En Reclusión' && !centroValidado && centroFinal.isNotEmpty) {
                final centroEncontrado = centrosReclusionTodos.firstWhere(
                      (centro) => centro['id'] == centroFinal,
                  orElse: () => <String, Object>{},
                );

                if (centroEncontrado.containsKey('correos')) {
                  final correosMap = centroEncontrado['correos'] as Map<String, dynamic>;
                  correosCentro = {
                    'correo_direccion': correosMap['correo_direccion']?.toString() ?? '',
                    'correo_juridica': correosMap['correo_juridica']?.toString() ?? '',
                    'correo_principal': correosMap['correo_principal']?.toString() ?? '',
                    'correo_sanidad': correosMap['correo_sanidad']?.toString() ?? '',
                  };
                }
              }

              try {
                final Map<String, dynamic> datosActualizados = {
                  'nombre_ppl': _nombreController.text,
                  'apellido_ppl': _apellidoController.text,
                  'numero_documento_ppl': _numeroDocumentoController.text,
                  'tipo_documento_ppl': _tipoDocumento,
                  'centro_reclusion': centroFinal,
                  'regional': selectedRegional ?? widget.doc['regional'],
                  'ciudad': selectedCiudad ?? widget.doc['ciudad'],
                  'juzgado_ejecucion_penas': selectedJuzgadoEjecucionPenas ?? widget.doc['juzgado_ejecucion_penas'],
                  'juzgado_ejecucion_penas_email': selectedJuzgadoEjecucionEmail ?? widget.doc['juzgado_ejecucion_penas_email'],
                  'juzgado_que_condeno': selectedJuzgadoNombre ?? widget.doc['juzgado_que_condeno'],
                  'juzgado_que_condeno_email': selectedJuzgadoConocimientoEmail ?? widget.doc['juzgado_que_condeno_email'],
                  'delito': selectedDelito ?? widget.doc['delito'],
                  'categoria_delito': categoriaDelito ?? widget.doc['categoria_delito'],
                  'radicado': _radicadoController.text,
                  'meses_condena': int.tryParse(_mesesCondenaController.text) ?? 0,
                  'dias_condena': int.tryParse(_diasCondenaController.text) ?? 0,
                  'td': _tdController.text,
                  'nui': _nuiController.text,
                  'patio': _patioController.text,
                  'nombre_acudiente': _nombreAcudienteController.text,
                  'apellido_acudiente': _apellidosAcudienteController.text,
                  'parentesco_representante': _parentescoAcudienteController.text,
                  'celular': _celularAcudienteController.text,
                  'celularWhatsapp': _celularWhatsappController.text,
                  'email': _emailAcudienteController.text,
                };

                await widget.doc.reference.update(datosActualizados);

                if (!centroValidado) {
                  await widget.doc.reference
                      .collection('correos_centro_reclusion')
                      .doc('emails')
                      .set(correosCentro);
                }

                if (situacion == 'En Reclusión') {
                  await FirebaseFirestore.instance
                      .collection('Ppl')
                      .doc(widget.doc.id)
                      .update({'centro_validado': true});
                }

                if (comentario.isNotEmpty) {
                  await widget.doc.reference.collection('comentarios').add({
                    'comentario': comentario,
                    'autor': adminFullName,
                    'fecha': DateTime.now(),
                  });
                }

                if (situacion != 'En Reclusión') {
                  await widget.doc.reference.update({
                    'centro_reclusion': "",
                    'td': "",
                    'nui': "",
                    'patio': "",
                  });
                }

                await widget.doc.reference.collection('historial_acciones').add({
                  'admin': adminFullName,
                  'accion': 'guardado',
                  'fecha': DateTime.now().toString(),
                });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Información guardada correctamente.'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.white,
                      title: const Text("Error"),
                      content: const Text("Ocurrió un error al guardar los datos."),
                      actions: [
                        TextButton(
                          child: const Text("Cerrar"),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'GUARDAR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Future<Map<String, dynamic>> _mostrarDialogoComentarioObligatorio(
      BuildContext context,
      DocumentReference pplDocRef, // 🔹 documento del PPL
      CollectionReference seguimientoCollection, // 🔹 colección donde se guardan los comentarios
      String adminFullName, // 🔹 nombre del admin que crea el comentario
      ) async {
    TextEditingController comentarioController = TextEditingController();
    bool requiereSeguimiento = false;

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> _handleGuardar() async {
              final comentario = comentarioController.text.trim();

              if (comentario.isEmpty && requiereSeguimiento) {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: blanco,
                    title: const Text("Guardar solo seguimiento"),
                    content: const Text("No has escrito ningún comentario. ¿Deseas guardar únicamente el check de seguimiento?"),
                    actions: [
                      TextButton(
                        child: const Text("Cancelar"),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
                        child: const Text("Sí, guardar"),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  ),
                );

                if (confirmar == true && context.mounted) {
                  // ✅ 1. Actualizar nodo del PPL
                  await pplDocRef.update({
                    'ultimo_seguimiento': Timestamp.now(),
                  });

                  Navigator.of(context).pop({
                    'comentario': '',
                    'seguimiento': true,
                  });
                }

                return;
              }

              if (comentario.isNotEmpty || requiereSeguimiento) {
                // ✅ 1. Guardar comentario en subcolección
                await seguimientoCollection.add({
                  'comentario': comentario,
                  'fecha_inicio': Timestamp.now(),
                  'creado_por': adminFullName,
                  'activo': true,
                });

                // ✅ 2. Actualizar nodo del PPL
                await pplDocRef.update({
                  'ultimo_seguimiento': Timestamp.now(),
                });

                Navigator.of(context).pop({
                  'comentario': comentario,
                  'seguimiento': requiereSeguimiento,
                });
              }
            }

            return AlertDialog(
              backgroundColor: blanco, // 🎨 Fondo gris claro
              title: const Text(
                "Comentario obligatorio para seguimiento de Usuario Activado",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: SingleChildScrollView( // Para evitar desbordamientos
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Card(
                      color: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text("Por favor, deja un comentario de seguimiento."),
                            const SizedBox(height: 12),
                            TextField(
                              controller: comentarioController,
                              maxLines: 4,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: "Escribe el comentario aquí",
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey, width: 2),
                                ),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            CheckboxListTile(
                              title: const Text("Marcar este caso para seguimiento periódico"),
                              value: requiereSeguimiento,
                              onChanged: (value) => setState(() => requiereSeguimiento = value ?? false),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const AgregarAgendaSimple(), // Ya es una Card blanca, según tu captura
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: (comentarioController.text.trim().isNotEmpty || requiereSeguimiento)
                      ? _handleGuardar
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Guardar comentario"),
                ),
              ],
            );

          },
        );
      },
    );

    comentarioController.dispose();
    return resultado ?? {};
  }


  Future<bool> tieneEventoEspecial(DocumentReference docRef) async {
    try {
      final snapshot1 = await docRef.collection('eventos').doc('proceso_en_tribunal').get();
      final snapshot2 = await docRef.collection('eventos').doc('sin_juzgado_ejecucion').get();
      final snapshot3 = await docRef.collection('eventos').doc('sin_fecha_captura').get();

      return snapshot1.exists || snapshot2.exists || snapshot3.exists;
    } catch (e) {
      return false;
    }
  }

  /// para guardar los usuarios y quedar en estado pendiente
  Future<String> _mostrarDialogoComentarioPendiente(BuildContext context, String faltantes) async {
    final TextEditingController _comentarioController = TextEditingController();
    String comentario = "";

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blanco,
        title: const Text("Campos incompletos"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Faltan los siguientes campos:\n$faltantes"),
            const SizedBox(height: 10),
            TextField(
              controller: _comentarioController,
              decoration: const InputDecoration(
                labelText: "Agrega un comentario para seguimiento",
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              comentario = _comentarioController.text.trim();
              Navigator.pop(context);
            },
            child: const Text("Guardar como pendiente"),
          ),
        ],
      ),
    );

    return comentario;
  }

  /// para guardar los usuarios y quedar en estado activado pero con campos incompletos

  Future<String> _mostrarDialogoActivacionConDatosIncompletos(BuildContext context, String camposFaltantes) async {
    final TextEditingController _comentarioController = TextEditingController( );

    String comentario = "";

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blanco,
        title: const Text(
          "Activación con datos incompletos",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Este usuario será activado, con los siguientes campos incompletos:\n\n$camposFaltantes",
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _comentarioController,
              decoration: const InputDecoration(
                labelText: "Agrega un comentario para hacer seguimiento",
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              comentario = _comentarioController.text.trim();
              Navigator.pop(context);
            },
            child: const Text("Confirmar y activar"),
          ),
        ],
      ),
    );

    return comentario;
  }

  bool _camposCompletos(String situacion) {
    bool camposValidos(dynamic valor) => valor != null && valor.toString().trim().isNotEmpty;

    final bool esEnReclusion = situacion == 'En Reclusión';

    return
      // Datos del PPL
      camposValidos(_nombreController.text) &&
          camposValidos(_apellidoController.text) &&
          camposValidos(_numeroDocumentoController.text) &&
          camposValidos(_radicadoController.text) &&
          camposValidos(selectedRegional ?? getCampoSeguro('regional')) &&
          camposValidos(selectedCiudad ?? getCampoSeguro('ciudad')) &&
          camposValidos(selectedDelito ?? getCampoSeguro('delito')) &&
          camposValidos(selectedJuzgadoEjecucionPenas ?? getCampoSeguro('juzgado_ejecucion_penas')) &&
          camposValidos(selectedJuzgadoNombre ?? getCampoSeguro('juzgado_que_condeno')) &&
          camposValidos(_mesesCondenaController.text) &&
          camposValidos(_diasCondenaController.text) &&
          camposValidos(_nombreAcudienteController.text) &&
          camposValidos(_apellidosAcudienteController.text) &&
          camposValidos(parentescoAcudiente ?? getCampoSeguro('parentesco')) &&
          camposValidos(_celularAcudienteController.text) &&
          (!esEnReclusion || (
              camposValidos(selectedCentro ?? getCampoSeguro('centro_reclusion')) &&
                  camposValidos(_tdController.text) &&
                  camposValidos(_nuiController.text) &&
                  camposValidos(_patioController.text)
          ));
  }


  dynamic getCampoSeguro(String key) {
    return widget.doc.data().toString().contains(key) ? widget.doc[key] : null;
  }

  void _mostrarComentarios(BuildContext context, String status) async {
    final comentariosSnapshot = await FirebaseFirestore.instance
        .collection('Ppl')
        .doc(widget.doc.id)
        .collection('comentarios')
        .orderBy('fecha', descending: true)
        .get();

    final comentarios = comentariosSnapshot.docs;

    // 🏷️ Título dinámico
    String titulo = "Comentarios del caso";
    if (status == 'pendiente') {
      titulo = "NO ACTIVADO EN ESTADO PENDIENTE";
    } else if ((widget.doc['requiere_actualizacion_datos'] ?? false) == true) {
      titulo = "ACTIVADO CON DATOS INCOMPLETOS";
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: blanco,
            title: Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: 400,
              child: comentarios.isEmpty
                  ? const Text("No hay comentarios registrados.")
                  : ListView.separated(
                shrinkWrap: true,
                itemCount: comentarios.length,
                separatorBuilder: (context, index) => const Divider(
                  color: Colors.grey,
                  height: 10,
                ),
                itemBuilder: (context, index) {
                  final comentario = comentarios[index].data();
                  return ListTile(
                    title: Text(comentario['comentario'] ?? ''),
                    subtitle: Text(
                      "${comentario['autor'] ?? 'Desconocido'} — ${DateFormat("dd/MM/yyyy hh:mm a").format(
                        (comentario['fecha'] as Timestamp).toDate(),
                      )}",
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Cerrar"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _mostrarComentariosSeguimiento(BuildContext context) async {
    final snapshot = await widget.doc.reference.collection('seguimiento').orderBy('fecha_inicio', descending: true).get();

    if (snapshot.docs.isEmpty) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: blanco,
            title: const Text("Sin comentarios"),
            content: const Text("Este usuario activado no tiene comentarios de seguimiento registrados."),
            actions: [
              TextButton(
                child: const Text("Cerrar"),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text("Agregar comentario"),
                onPressed: () {
                  Navigator.of(context).pop();
                  _agregarComentarioSeguimiento(context); // 🔁 Método que agregaremos abajo
                },
              ),
            ],
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: blanco,
          title: const Text("Comentarios de seguimiento"),
          content: SizedBox(
            width: 700,
            height: 300, // Añade esta línea para evitar el error
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: snapshot.docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: gris),
              itemBuilder: (context, index) {
                final doc = snapshot.docs[index];
                final comentario = doc['comentario'] ?? '';
                const SizedBox(height: 12);
                final creadoPor = doc['creado_por'] ?? 'Desconocido';
                final fecha = (doc['fecha_inicio'] as Timestamp?)?.toDate();
                final fechaStr = fecha != null
                    ? '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}'
                    : 'Sin fecha';

                return ListTile(
                  title: Text(comentario),
                  subtitle: Text("Por $creadoPor - $fechaStr", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  isThreeLine: true,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cerrar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Agregar comentario"),
              onPressed: () {
                Navigator.of(context).pop();
                _agregarComentarioSeguimiento(context);
              },
            ),
          ],
        ),
      );
    }
  }

  Future<void> _agregarComentarioSeguimiento(BuildContext context) async {
    final TextEditingController controller = TextEditingController();

    final resultado = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: blanco,
        title: const Text("Nuevo comentario de seguimiento"),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "Escribe el comentario aquí",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              final texto = controller.text.trim();
              if (texto.isNotEmpty) Navigator.of(context).pop(texto);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );

    if (resultado != null && resultado.isNotEmpty) {
      // 🔹 Guarda el comentario en la subcolección
      await widget.doc.reference.collection('seguimiento').add({
        'comentario': resultado,
        'fecha_inicio': Timestamp.now(),
        'creado_por': adminFullName, // Asegúrate de que esta variable esté disponible
        'activo': true,
      });

      // 🔹 Actualiza el campo 'ultimo_seguimiento' en el documento principal
      await widget.doc.reference.update({
        'ultimo_seguimiento': Timestamp.now(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Comentario guardado con éxito.")),
        );
      }
    }
  }


  /// 🔹 Función para mostrar un AlertDialog de confirmación antes de guardar
  Future<bool> _mostrarDialogoConfirmacionBotonGuardar() async {
    return await showDialog(
      context: context,
      barrierDismissible: false, // No permitir cerrar tocando fuera
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: blanco,
          title: const Text("Confirmación"),
          content: const Text("¿Está seguro de que desea guardar los cambios?"),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: const Text("Guardar"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false; // En caso de error, devuelve `false` por defecto
  }

  Widget tipoDocumentoPpl(){
    return DropdownButtonFormField(
      value: _tipoDocumento,
      onChanged: (String? newValue) {
        setState(() {
          _tipoDocumento = newValue!;
        });
      },
      items: _opciones.map((String option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option, style: const TextStyle(fontWeight: FontWeight.bold),),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: 'Tipo de Documento',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
      ),
    );
  }

  Future<void> enviarMensajeWhatsApp(String whatsApp, String docId) async {
    if (whatsApp.isEmpty) {
      if (kDebugMode) {
        print('El número de WhatsApp es inválido');
      }
      return;
    }

    // Asegurar que el número tenga el prefijo +57 (Colombia)
    if (!whatsApp.startsWith("+57")) {
      whatsApp = "+57$whatsApp";
    }

    // Obtener el nombre del acudiente desde Firestore
    String nombreAcudiente = "Estimado usuario";
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('Ppl').doc(docId).get();
      if (doc.exists && doc.data() != null) {
        nombreAcudiente = doc['nombre_acudiente'] ?? "Estimado usuario";
      }
    } catch (e) {
      if (kDebugMode) print("Error obteniendo nombre del acudiente: $e");
    }

    // Obtener días de prueba y valor de suscripción desde configuración
    int diasPrueba = 1;
    int valorSuscripcion = 49900; // Valor por defecto
    try {
      final configSnap = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
      if (configSnap.docs.isNotEmpty) {
        final data = configSnap.docs.first.data();
        diasPrueba = data['tiempoDePrueba'] ?? 1;
        valorSuscripcion = data['valor_subscripcion']?? 0 ;
      }
    } catch (e) {
      if (kDebugMode) print("Error obteniendo configuración: $e");
    }

    // Construir el mensaje
    String mensaje = Uri.encodeComponent(
        "Hola *$nombreAcudiente*,\n\n"
            "¡Bienvenido a *Tu Proceso Ya*!\n\n"
            "Tu cuenta ha sido activada exitosamente. Ahora puedes gestionar solicitudes y hacer seguimiento a la situación jurídica de tu ser querido PPL de forma ágil y segura.\n\n"
            "Tendrás *$diasPrueba día${diasPrueba > 1 ? 's' : ''} completamente gratuito${diasPrueba > 1 ? 's' : ''}* para explorar todas las funciones de nuestra plataforma.\n\n"
            "*Importante:* Este acceso especial es temporal. Para seguir disfrutando del servicio y obtener *6 meses de acceso completo*, activa tu suscripción por solo *${formatoPesos.format(valorSuscripcion)}*.\n\n"
            "No dejes pasar esta oportunidad de acompañar a tu ser querido con las herramientas adecuadas.\n\n"
            "Accede ahora desde aquí: https://www.tuprocesoya.com\n\n"
            "Estamos aquí para apoyarte.\n\n"
            "*El equipo de soporte de Tu Proceso Ya*"
    );

    String whatsappBusinessUri = "whatsapp://send?phone=$whatsApp&text=$mensaje";
    String webUrl = "https://wa.me/$whatsApp?text=$mensaje";

    if (await canLaunchUrl(Uri.parse(whatsappBusinessUri))) {
      await launchUrl(Uri.parse(whatsappBusinessUri));
    } else {
      await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
    }
  }

  final NumberFormat formatoPesos = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
    customPattern: '\u00A4#,##0',
  );


  Future<void> validarYEnviarMensaje() async{
    String whatsApp = widget.doc['celularWhatsapp'] ?? '';
    String docId = widget.doc['id'] ?? '';

    if (whatsApp.isEmpty || docId.isEmpty) {
      if (kDebugMode) {
        print("Error: Datos insuficientes para enviar el mensaje.");
      }
      return;
    }

    DocumentReference docRef = FirebaseFirestore.instance.collection('Ppl').doc(docId);

    try {
      DocumentSnapshot docSnapshot = await docRef.get();

      // Verificar si el nodo isNotificated existe y es true
      if (docSnapshot.exists && docSnapshot.data() != null) {
        bool isNotificated = docSnapshot['isNotificatedActivated'] ?? false;
        if (isNotificated) {
          if (kDebugMode) {
            print("El usuario ya ha sido notificado. No se enviará el mensaje.");
          }
          return;
        }
      }

      // Enviar mensaje de WhatsApp
      await enviarMensajeWhatsApp(whatsApp, docId);

      // Crear o actualizar isNotificated a true
      await docRef.set({'isNotificatedActivated': true}, SetOptions(merge: true));

      if (kDebugMode) {
        print("Mensaje enviado y estado actualizado.");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error al verificar o actualizar la notificación: $e");
      }
    }
  }

  Widget estadoUsuarioWidget(String status) {
    Color color;
    IconData icono;
    String mensaje;

    if (status == "activado") {
      color = Colors.green;
      icono = Icons.check_circle;
      mensaje = "Cuenta\nActivada";
    } else if (status == "bloqueado") {
      color = Colors.red;
      icono = Icons.lock;
      mensaje = "Cuenta\nBloqueada";
    } else {
      color = Colors.blue;
      icono = Icons.error_outline;
      mensaje = "Activación\nPendiente";
    }

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.grey),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icono,
              color: color,
              size: 30, // Mismo tamaño que notificación
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget estadoNotificacionWidget(
      bool isNotificatedActivated, String celularWhatsapp, String docId) {
    Color iconColor = isNotificatedActivated ? Colors.green : Colors.red;
    String mensaje = isNotificatedActivated ? "Activación\nnotificada" : "Activación\nsin notificar";

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.grey),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_active_outlined,
              color: iconColor,
              size: 30, // Ícono grande
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> enviarMensajeWhatsAppApi(String numero, String docId) async {
    if (numero.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El número de WhatsApp no está disponible')),
      );
      return;
    }

    String numeroFormateado = numero.trim();
    if (!numeroFormateado.startsWith("57")) {
      numeroFormateado = "57$numeroFormateado";
    }

    print("Número a enviar: $numeroFormateado");
    print("Documento Firestore a usar: $docId");

    try {
      // Mostrar el loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final response = await http.post(
        Uri.parse(
          "https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/sendActivationMessage",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "to": numeroFormateado,
          "docId": docId,
        }),
      );

      Navigator.of(context).pop(); // Cerrar el loader

      if (response.statusCode == 200) {
        // 🔄 Actualizar Firestore
        try {
          await FirebaseFirestore.instance.collection('Ppl').doc(docId).update({
            'isNotificatedActivated': true,
          });

          setState(() {
            _isNotificatedActivated = true;
          });
        } catch (e) {
          print('Error actualizando isNotificatedActivated: $e');
        }

        // Mostrar el AlertDialog de éxito
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: Colors.white,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/icono_whatsapp.png',
                      width: 48,
                      height: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'El mensaje de activación por WhatsApp fue enviado exitosamente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const HomeAdministradorPage()),
                                (route) => false,
                          );
                        },
                        child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        }
      }
      else {
        print('Error: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error enviando mensaje (Código ${response.statusCode}): ${response.body}',
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error enviando mensaje: $e')),
      );
    }
  }
}


class MostrarTiempoBeneficioCard extends StatelessWidget {
  final String idPpl;

  const MostrarTiempoBeneficioCard({super.key, required this.idPpl});

  Future<bool> _debeMostrarCard() async {
    final doc = await FirebaseFirestore.instance.collection('Ppl').doc(idPpl).get();
    final data = doc.data();

    // Mostrar solo si no existe el campo o el nivel es distinto de 'superado'
    if (data == null) return false;
    final nivel = data['nivel_tiempo_beneficio'];
    return nivel == null || nivel != 'superado';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _debeMostrarCard(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(); // También puedes poner CircularProgressIndicator si prefieres
        }

        if (snapshot.data == true) {
          return TiempoBeneficioCard(idPpl: idPpl);
        } else {
          return const SizedBox(); // No mostrar nada si ya es 'superado'
        }
      },
    );
  }
}


