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
import '../../../widgets/datos_ejecucion_condena.dart';
import '../home_admin/home_admin.dart';

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
  final _tiempoCondenaController = TextEditingController();
  final _fechaDeCapturaController = TextEditingController();
  final _tdController = TextEditingController();
  final _nuiController = TextEditingController();
  final _patioController = TextEditingController();
  final _direccionController = TextEditingController();



  /// controllers para el acudiente
  final _nombreAcudienteController = TextEditingController();
  final _apellidosAcudienteController = TextEditingController();
  final _parentescoAcudienteController = TextEditingController();
  final _celularAcudienteController = TextEditingController();
  final _emailAcudienteController = TextEditingController();


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
  bool _mostrarDropdownDelito = false;

  /// variables para calcular el tiempo de condena
  final CalculoCondenaController _calculoCondenaController = CalculoCondenaController(PplProvider());
  int diasEjecutado = 0;
  int mesesEjecutado = 0;
  int diasEjecutadoExactos = 0;
  int diasRestante = 0;
  int mesesRestante = 0;
  int diasRestanteExactos = 0;
  double porcentajeEjecutado =0;
  int tiempoCondena =0;
  late String _tipoDocumento;

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


  /// opciones de documento de identidad
  final List<String> _opciones = ['Cédula de Ciudadanía','Pasaporte', 'Tarjeta de Identidad'];

  @override
  void initState() {
    super.initState();
    _initCalculoCondena();
    _initFormFields();
    Future.delayed(Duration.zero, () {
      setState(() {
        isLoading = false; // Cambia el estado después de que se verifiquen los valores
      });
    });
    ppl = Ppl.fromJson(widget.doc.data() as Map<String, dynamic>);
    _obtenerDatos();
    _asignarDocumento(); // Bloquea el documento al abrirlo
    _adminProvider.loadAdminData(); // 🔥 Cargar info del admin
    calcularTotalRedenciones(widget.doc.id); // 🔥 Llama la función aquí
    _direccionController.text = widget.doc['direccion'] ?? '';

    departamentoSeleccionado = widget.doc['departamento'];
    municipioSeleccionado = widget.doc['municipio'];
    categoriaDelito = widget.doc['categoria_delito'];
    selectedDelito = widget.doc['delito'];
    if (categoriaDelito != null && categoriaDelito!.trim().isEmpty) {
      categoriaDelito = null;
    }
    if (selectedDelito != null && selectedDelito!.trim().isEmpty) {
      selectedDelito = null;
    }


  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _numeroDocumentoController.dispose();
    _radicadoController.dispose();
    _tiempoCondenaController.dispose();
    _fechaDeCapturaController.dispose();
    _tdController.dispose();
    _nuiController.dispose();
    _patioController.dispose();
    _direccionController.dispose();
    //_liberarDocumento(); // 🔥 Libera el documento al cerrar la pantalla
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return MainLayout(
      pageTitle: 'Datos generales',
      content: SingleChildScrollView(
        child: Form(
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
      ),
    );
  }


  /// 🔹 Contenido principal (Información del PPL y Acudiente)
  Widget _buildMainContent() {
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

          FutureBuilder<double>(
            future: calcularTotalRedenciones(widget.doc.id),
            builder: (context, snapshot) {
              double totalRedimido = snapshot.data ?? 0.0;
              return _datosEjecucionCondena(totalRedimido);
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
          const SizedBox(height: 15),
          seleccionarCentroReclusion(),
          const SizedBox(height: 15),
          seleccionarJuzgadoEjecucionPenas(),
          const SizedBox(height: 15),
          seleccionarJuzgadoQueCondeno(),
          const SizedBox(height: 15),
          DelitosDropdownWidget(
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
          fechaCapturaPpl(),
          const SizedBox(height: 15),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (widget.doc["status"] != "bloqueado") ...[
                  botonGuardar(),
                  bloquearUsuario(),
                ] else
                  FutureBuilder<bool>(
                    future: _adminPuedeDesbloquear(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      return snapshot.data == true ? desbloquearUsuario() : const SizedBox();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  /// 🔹 Widgets adicionales (Historial y acciones)
  Widget _buildExtraWidget() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.doc["situacion"] == "En Prisión domiciliaria" ||
              widget.doc["situacion"] == "En libertad condicional")
            infoPplNoRecluido(),
          const SizedBox(height: 20),
          EditarBeneficiosWidget(
            pplId: widget.doc["id"],
            beneficiosAdquiridosInicial: ppl.beneficiosAdquiridos,
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
                estadoNotificacionWidget(widget.doc["isNotificatedActivated"]),
                const SizedBox(height: 20),
                const Text(
                  "Historial Acciones Administrativas",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                historialAccionUsuario(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
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

      if(context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Redención guardada exitosamente')),
        );
        // 🔥 **LIMPIAR los campos después de guardar**
        _fechaController.clear();
        _diasController.clear();
        setState(() {}); // 🔄 Refrescar UI después de limpiar
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(8), // 🔹 Bordes suavemente redondeados
        border: Border.all(color: Colors.grey.shade400, width: 1), // 🔹 Borde gris
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Evita que el Column ocupe toda la altura
          children: [
            // 🔥 Botón para ver redenciones
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _mostrarHistorialRedenciones(context),
                icon: const Icon(Icons.remove_red_eye, color: Colors.black87),
                label: const Text("Ver Redenciones", style: TextStyle(color: negro)),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Registrar Redención",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 📅 Selección de fecha de redención
            // 📅 Selección de fecha de redención
            TextField(
              controller: _fechaController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Fecha de Redención",
                floatingLabelBehavior: FloatingLabelBehavior.always,
                suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Colors.grey), // 🔹 Borde gris
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Colors.grey), // 🔹 Borde gris en estado normal
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: primary), // 🔹 Borde gris en estado activo
                ),
              ),
              onTap: () => _selectFechaRedencion(context),
            ),
            const SizedBox(height: 15),

// ⏳ Cantidad de días redimidos
            TextField(
              controller: _diasController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Cantidad de Días Redimidos",
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Colors.grey), // 🔹 Borde gris
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Colors.grey), // 🔹 Borde gris en estado normal
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: primary), // 🔹 Borde gris en estado activo
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 📌 Botón para guardar la redención
            SizedBox(
              width: 250,
              child: ElevatedButton(
                onPressed: widget.doc["status"] == "bloqueado"
                    ? null // 🔹 Desactiva el botón si el usuario está bloqueado
                    : () async {
                  await _guardarRedencion(widget.doc.id);
                  await calcularTotalRedenciones(widget.doc.id);
                  _initCalculoCondena();
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.doc["status"] == "bloqueado"
                      ? Colors.black // 🔹 Cambia el color del botón cuando está deshabilitado
                      : Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  "Guardar Redención",
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.doc["status"] == "bloqueado" ? Colors.black54 : Colors.white,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
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
            width: MediaQuery.of(context).size.width * 0.8, // 🔥 Usa el 80% del ancho de la pantalla
            height: MediaQuery.of(context).size.height * 1, // 🔹 Ocupa el 80% de la altura
            child: Column(
              children: [
                // 🔥 Encabezado
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
                          onPressed: () => Navigator.pop(context), // 🔹 Cerrar el modal
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),

                // 🔥 Contenedor con desplazamiento
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

                      // 🔹 Calcular sumatoria
                      double totalDiasRedimidos = snapshot.data!
                          .map((r) => r['dias_redimidos'] as double)
                          .fold(0, (prev, curr) => prev + curr);

                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical, // 🔥 Scroll vertical para ver toda la tabla
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal, // 🔥 Scroll horizontal si la tabla es ancha
                          child: DataTable(
                            columnSpacing: 50, // 🔥 Ajusta el espacio entre columnas
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
                            ],
                            rows: [
                              // 🔹 Redenciones
                              ...snapshot.data!.map(
                                    (redencion) => DataRow(cells: [
                                  DataCell(Text(
                                    DateFormat("d 'de' MMMM 'de' y").format(redencion['fecha']),
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
                                ]),
                              ),

                              // 🔹 Fila de sumatoria al final
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
                                  const DataCell(Text("")), // Espacio vacío
                                  const DataCell(Text("")), // Espacio vacío
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
          .doc(widget.doc.id) // 🔹 Asegurar que el ID es correcto
          .collection('redenciones')
          .orderBy('fecha_redencion', descending: true) // 🔥 Ordenar en Firestore
          .get();

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

        // 🔹 Verificar `fecha_actualizacion` (Timestamp o String)
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
          'dias_redimidos': (doc['dias_redimidos'] ?? 0).toDouble(), // 🔹 Asegurar que sea un double
          'fecha': fecha,
          'admin_nombre': doc['admin_nombre'] ?? "Desconocido",
          'admin_apellido': doc['admin_apellido'] ?? "",
          'fecha_actualizacion': fechaActualizacion, // 🔥 Ahora incluye la fecha de actualización
        };
      }).toList();

      // 🔹 Validar que esté ordenado correctamente (por si Firestore falla)
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

  Future<void> _fetchTodosJuzgadosConocimiento() async {
    if (juzgadosConocimiento.isNotEmpty) return; // Si ya se cargaron, no volver a hacer la petición

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

  //*********para los no recluidos

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
    // Si ya existe información guardada en el documento y no estamos en modo edición,
    // se muestra el contenedor con la info.
    if (!_mostrarDropdowns &&
        widget.doc['centro_reclusion'] != null &&
        widget.doc['centro_reclusion'].toString().trim().isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _mostrarDropdowns = true;
                  // Opcional: puedes limpiar selectedCentro si deseas forzar una nueva selección.
                  selectedCentro = null;
                });
                _fetchTodosCentrosReclusion();
              },
              child: const Row(
                children: [
                  Text("Regional", style: TextStyle(fontSize: 11)),
                  Icon(Icons.edit, size: 15),
                ],
              ),
            ),
            Text(
              widget.doc['regional'],
              style: const TextStyle(fontWeight: FontWeight.bold, height: 1),
            ),
            const SizedBox(height: 10),
            const Text("Centro de reclusión", style: TextStyle(fontSize: 11)),
            Text(
              widget.doc['centro_reclusion'],
              style: const TextStyle(fontWeight: FontWeight.bold, height: 1),
            ),

          ],
        ),
      );
    } else {
      // Si la lista de centros está vacía, disparamos la carga.
      if (centrosReclusionTodos.isEmpty) {
        Future.microtask(() => _fetchTodosCentrosReclusion());
      }
      return Container(
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
            Row(
              children: [
                const Text(
                  "Buscar centro de reclusión",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (widget.doc["situacion"] == "En Prisión domiciliaria" ||
                    widget.doc["situacion"] == "En libertad condicional") ...[
                  const SizedBox(width: 10), // Espacio entre textos
                  Text(
                    "El PPL se encuentra ${widget.doc["situacion"]}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),
            Autocomplete<Map<String, String>>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Map<String, String>>.empty();
                }
                return centrosReclusionTodos
                    .map((option) => option.map((key, value) => MapEntry(key, value.toString()))) // Convierte todo a String
                    .where((Map<String, String> option) =>
                    option['nombre']!.toLowerCase().contains(textEditingValue.text.toLowerCase()));

              },
              displayStringForOption: (Map<String, String> option) =>
              option['nombre']!,
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: "Busca ingresando la ciudad",
                    labelText: "Centro de reclusión",
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
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                if (options.isEmpty) {
                  return Material(
                    elevation: 4.0,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: const Text("No se encontraron centros"),
                    ),
                  );
                }
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    child: Container(
                      color: blancoCards,
                      padding: const EdgeInsets.all(10),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final Map<String, String> option = options.elementAt(index);
                          return ListTile(
                            title: Text(option['nombre']!),
                            onTap: () {
                              onSelected(option);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              onSelected: (Map<String, String> selection) {
                setState(() {
                  selectedCentro = selection['id'];
                  // Actualizamos _centroReclusion para que muestre el nombre del centro seleccionado.
                  // Guardamos también el ID de la regional asociada
                  selectedRegional = selection['regional'];
                });
                if (kDebugMode) {
                  print("Valor a actualizar en ***** 'regional': ${selectedRegional ?? widget.doc['regional']}");
                }
              },

            ),
            const SizedBox(height: 10),
            if (selectedCentro != null)
              Text(
                "Centro seleccionado: ${centrosReclusionTodos.firstWhere(
                      (centro) => centro['id'] == selectedCentro,
                  orElse: () => <String, String>{},
                )['nombre']!}",
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _mostrarDropdowns = false;
                    // Restaura el valor original del documento, si es que existe.
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
        ),
      );
    }
  }

  Widget seleccionarJuzgadoEjecucionPenas() {
    if (!_mostrarDropdownJuzgadoEjecucion &&
        widget.doc['juzgado_ejecucion_penas'] != null &&
        widget.doc['juzgado_ejecucion_penas'].toString().trim().isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _mostrarDropdownJuzgadoEjecucion = true;
                  selectedJuzgadoEjecucionPenas = null;
                  selectedJuzgadoEjecucionEmail = null;
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
                  .where((juzgado) =>
                  (juzgado['juzgadoEP'] ?? '')
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()))

                  .map((juzgado) => {
                'juzgadoEP': juzgado['juzgadoEP'] ?? '',
                'email': juzgado['email'] ?? ''
              });

            },
            displayStringForOption: (option) => option['juzgadoEP']!,
            fieldViewBuilder:
                (context, textEditingController, focusNode, onFieldSubmitted) {
              return TextField(
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
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  suffixIcon: selectedJuzgadoEjecucionPenas != null
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        selectedJuzgadoEjecucionPenas = null;
                        selectedJuzgadoEjecucionEmail = null;
                        textEditingController.clear();
                      });
                    },
                  )
                      : null,
                ),
              );
            },
            onSelected: (Map<String, String> option) {
              setState(() {
                selectedJuzgadoEjecucionPenas = option['juzgadoEP'];
                selectedJuzgadoEjecucionEmail = option['email'];
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
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // 🔹 Botón cancelar
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _mostrarDropdownJuzgadoEjecucion = false;
                  selectedJuzgadoEjecucionPenas = widget.doc['juzgado_ejecucion_penas'];
                  selectedJuzgadoEjecucionEmail = widget.doc['juzgado_ejecucion_penas_email'];
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
      ),
    );
  }

  Widget seleccionarJuzgadoQueCondeno() {
    // Si ya existe información guardada en el documento y no estamos en modo edición,
    // se muestra el contenedor con la información almacenada.
    if (!_mostrarDropdownJuzgadoCondeno &&
        widget.doc['juzgado_que_condeno'] != null &&
        widget.doc['juzgado_que_condeno'].toString().trim().isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
      );
    } else {
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

            // 🔹 AUTOCOMPLETE 🔹
            Autocomplete<Map<String, String>>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Map<String, String>>.empty();
                }
                return juzgadosConocimiento
                    .map((juzgado) => {
                  'id': juzgado['id'].toString(),
                  'nombre': juzgado['nombre'].toString(),
                  'correo': juzgado['correo'].toString(),
                  'ciudad': juzgado['ciudad'].toString(),
                })
                    .where(
                      (juzgado) =>
                      juzgado['nombre']!
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()),
                );
              },
              displayStringForOption: (Map<String, String> option) => option['nombre']!,
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
                          textEditingController.clear(); // 🔥 Limpiar el campo del Autocomplete
                        });
                        debugPrint("❌ Selección de juzgado eliminada.");
                      },
                    )
                        : null,
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200], // 🔹 Cambia este color según lo que necesites
                        borderRadius: BorderRadius.circular(10), // Opcional: Bordes redondeados
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final Map<String, String> option = options.elementAt(index);
                          return ListTile(
                            title: Text(option['nombre']!),
                            subtitle: Text("Ciudad: ${option['ciudad']!}"),
                            onTap: () {
                              onSelected(option);
                              setState(() {
                                selectedJuzgadoNombre = option['nombre'];
                                selectedCiudad = option['ciudad'];
                                selectedJuzgadoConocimientoEmail = option['correo'];
                              });
                              debugPrint("📌 Juzgado seleccionado: ${option['nombre']}");
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // 🔹 Botón para cancelar 🔹
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cancel, size: 15),
                    Text("Cancelar", style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
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

  void _initCalculoCondena() async {
    try {
      final fechaCapturaRaw = widget.doc.get('fecha_captura');
      DateTime? fechaCaptura = _convertirFecha(fechaCapturaRaw);

      if (fechaCaptura == null) {
        debugPrint("❌ Error: No se pudo convertir la fecha de captura");
        return;
      }

      debugPrint("📌 Fecha de captura convertida correctamente: $fechaCaptura");

      // 🔥 Llamar directamente al cálculo sin necesidad de obtener días redimidos aquí
      await _calculoCondenaController.calcularTiempo(widget.doc.id);

      // 🔥 Actualizar los valores obtenidos del controlador
      setState(() {
        mesesRestante = _calculoCondenaController.mesesRestante ?? 0;
        diasRestanteExactos = _calculoCondenaController.diasRestanteExactos ?? 0;
        mesesEjecutado = _calculoCondenaController.mesesEjecutado ?? 0;
        diasEjecutadoExactos = _calculoCondenaController.diasEjecutadoExactos ?? 0;
        porcentajeEjecutado = _calculoCondenaController.porcentajeEjecutado ?? 0;
      });

      debugPrint("✅ Cálculo de condena con redenciones actualizado:");
      debugPrint("   - Meses ejecutados: $mesesEjecutado");
      debugPrint("   - Días ejecutados: $diasEjecutadoExactos");
      debugPrint("   - Meses restantes: $mesesRestante");
      debugPrint("   - Días restantes: $diasRestanteExactos");
      debugPrint("   - Porcentaje ejecutado: ${porcentajeEjecutado.toStringAsFixed(1)}%");
    } catch (e) {
      debugPrint("❌ Error en _initCalculoCondena: $e");
    }
  }

  void _initFormFields() {
    _nombreController.text = widget.doc.get('nombre_ppl') ?? "";
    _apellidoController.text = widget.doc.get('apellido_ppl') ?? "";
    _numeroDocumentoController.text = widget.doc.get('numero_documento_ppl').toString();
    _tipoDocumento = widget.doc.get('tipo_documento_ppl') ?? "";
    _radicadoController.text = widget.doc.get('radicado') ?? "";
    _tiempoCondenaController.text = widget.doc.get('tiempo_condena')?.toString() ?? "";

    // 🔍 Verifica si tiempo_condena se obtiene correctamente
    debugPrint("📌 Tiempo de condena obtenido: ${_tiempoCondenaController.text}");

    _fechaDeCapturaController.text = widget.doc.get('fecha_captura') ?? "";
    _tdController.text = widget.doc.get('td') ?? "";
    _nuiController.text = widget.doc.get('nui') ?? "";
    _patioController.text = widget.doc.get('patio') ?? "";
    _nombreAcudienteController.text = widget.doc.get('nombre_acudiente') ?? "";
    _apellidosAcudienteController.text = widget.doc.get('apellido_acudiente') ?? "";
    _parentescoAcudienteController.text = widget.doc.get('parentesco_representante') ?? "";
    _celularAcudienteController.text = widget.doc.get('celular') ?? "";
    _emailAcudienteController.text = widget.doc.get('email') ?? "";
    _direccionController.text = widget.doc['direccion'] ?? '';
  }

  Widget _datosEjecucionCondena(double totalDiasRedimidos){
    return  DatosEjecucionCondena(
      mesesEjecutado: mesesEjecutado,
      diasEjecutadoExactos: diasEjecutadoExactos,
      mesesRestante: mesesRestante,
      diasRestanteExactos: diasRestanteExactos,
      totalDiasRedimidos: totalDiasRedimidos,
      porcentajeEjecutado: porcentajeEjecutado,
      primary: Colors.grey,
      negroLetras: Colors.black,
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

  Widget fechaCapturaPpl() {
    return TextFormField(
      controller: _fechaDeCapturaController,
      readOnly: true, // Evita que el usuario escriba manualmente
      decoration: InputDecoration(
        labelText: 'Fecha de captura (YYYY-MM-DD)',
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
          borderSide: const BorderSide(color: Colors.grey, width: 2),
        ),
        // 👇 Agrega estas 2 líneas para quitar el borde rojo de error
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 2),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today, color: Colors.deepPurple),
          onPressed: () => _seleccionarFechaCaptura(context),
        ),
      ),

      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese la fecha de captura';
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

    if (pickedDate != null) {
      setState(() {
        _fechaDeCapturaController.text = "${pickedDate.year}-${_formatDosDigitos(pickedDate.month)}-${_formatDosDigitos(pickedDate.day)}";
      });
      debugPrint("📅 Fecha de captura seleccionada: ${_fechaDeCapturaController.text}");
    }
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
    return TextFormField(
      controller: _tiempoCondenaController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Tiempo de condena',
        floatingLabelStyle: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.bold,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade900, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade900, width: 2),
        ),
      ),
      validator: (value) {
        final parsed = int.tryParse(value ?? '');
        if (parsed == null || parsed <= 0) {
          return 'Por favor, ingrese un valor válido mayor a 0';
        }
        return null;
      },
    );
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
      width: 200,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          onPressed: () async {
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

              if(context.mounted){
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
              if(context.mounted){
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
          child: const Text('Bloquear Usuario', style: TextStyle(fontSize: 12),),
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
            } else if (accion == "activado") {
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
    return SizedBox(
      width: 180,
      child: Align(
        alignment: Alignment.center,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () async {
            String adminFullName = await obtenerNombreAdmin();
            bool confirmar = await _mostrarDialogoConfirmacionBotonGuardar();
            if (!confirmar) return;

            if (!_formKey.currentState!.validate()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.red,
                  content: Text(
                    'No se puede guardar hasta que todos los campos estén llenos',
                    style: TextStyle(color: Colors.white),
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }

            List<String> camposFaltantes = [];

            if ((selectedCentro ?? widget.doc['centro_reclusion']) == null) camposFaltantes.add("Centro de Reclusión");
            if ((selectedRegional ?? widget.doc['regional']) == null) camposFaltantes.add("Regional");
            if ((selectedCiudad ?? widget.doc['ciudad']) == null) camposFaltantes.add("Ciudad");
            if ((selectedJuzgadoEjecucionPenas ?? widget.doc['juzgado_ejecucion_penas']) == null) camposFaltantes.add("Juzgado de Ejecución de Penas");
            if ((selectedJuzgadoNombre ?? widget.doc['juzgado_que_condeno']) == null) camposFaltantes.add("Juzgado que Condenó");
            if ((selectedDelito == null || selectedDelito!.trim().isEmpty) && (widget.doc['delito'] == null || widget.doc['delito'].toString().trim().isEmpty)) {
              camposFaltantes.add("Delito");
            }

            if (_nombreController.text.trim().isEmpty) camposFaltantes.add("Nombre");
            if (_apellidoController.text.trim().isEmpty) camposFaltantes.add("Apellido");
            if (_numeroDocumentoController.text.trim().isEmpty) camposFaltantes.add("Número de Documento");
            int tiempoCondena = int.tryParse(_tiempoCondenaController.text) ?? 0;
            if (tiempoCondena == 0) camposFaltantes.add("Tiempo de condena");

            if (camposFaltantes.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.red,
                  content: Text("Faltan los siguientes campos:\n${camposFaltantes.join('\n')}"),
                  duration: const Duration(seconds: 3),
                ),
              );
              return;
            }

            Map<String, String> correosCentro = {
              'correo_direccion': '',
              'correo_juridica': '',
              'correo_principal': '',
              'correo_sanidad': '',
            };

            String centroFinal = selectedCentro ?? widget.doc['centro_reclusion'];
            if (centroFinal.isNotEmpty) {
              var centroEncontrado = centrosReclusionTodos.firstWhere(
                    (centro) => centro['id'] == centroFinal,
                orElse: () => <String, Object>{},
              );

              if (centroEncontrado.isNotEmpty && centroEncontrado.containsKey('correos')) {
                var correosMap = centroEncontrado['correos'] as Map<String, dynamic>;
                correosCentro = {
                  'correo_direccion': correosMap['correo_direccion']?.toString() ?? '',
                  'correo_juridica': correosMap['correo_juridica']?.toString() ?? '',
                  'correo_principal': correosMap['correo_principal']?.toString() ?? '',
                  'correo_sanidad': correosMap['correo_sanidad']?.toString() ?? '',
                };
              }
            }

            SystemChannels.textInput.invokeMethod('TextInput.hide');

            try {
              await widget.doc.reference.update({
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
                'tiempo_condena': tiempoCondena,
                'fecha_captura': _fechaDeCapturaController.text,
                'td': _tdController.text.isNotEmpty ? _tdController.text : '',
                'nui': _nuiController.text.isNotEmpty ? _nuiController.text : '',
                'patio': _patioController.text.isNotEmpty ? _patioController.text : '',
                'nombre_acudiente': _nombreAcudienteController.text,
                'apellido_acudiente': _apellidosAcudienteController.text,
                'parentesco_representante': _parentescoAcudienteController.text,
                'celular': _celularAcudienteController.text,
                'email': _emailAcudienteController.text,
                'status': 'activado',
              });

              await widget.doc.reference.collection('correos_centro_reclusion').doc('emails').set(correosCentro);

              String accion = widget.doc['status'] == 'registrado' ? 'activado' : 'actualización';
              await widget.doc.reference.collection('historial_acciones').add({
                'admin': adminFullName,
                'accion': accion,
                'fecha': DateTime.now().toString(),
              });

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Datos guardados con éxito. Correos actualizados.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }

              Future.delayed(const Duration(seconds: 1), () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeAdministradorPage()),
                );
              });

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Se guardó la información de manera exitosa'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              }

              validarYEnviarMensaje();
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al guardar: $error'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Guardar Cambios'),
        ),
      ),
    );
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

  Future<String> obtenerNombreAdmin() async {
    AdminProvider adminProvider = AdminProvider();

    // Si ya tiene datos cargados, los devuelve directamente
    if (adminProvider.adminFullName != null && adminProvider.adminFullName!.isNotEmpty) {
      return adminProvider.adminFullName!;
    }

    // Cargar datos si no están disponibles
    await adminProvider.loadAdminData();

    return adminProvider.adminFullName ?? "Desconocido";
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

  Future<void> enviarMensajeWhatsApp(String celular, String docId) async {
    if (celular.isEmpty) {
      if (kDebugMode) {
        print('El número de celular es inválido');
      }
      return;
    }

    // Asegurar que el número tenga el prefijo +57 (Colombia)
    if (!celular.startsWith("+57")) {
      celular = "+57$celular";
    }

    // Obtener el nombre del acudiente desde Firestore
    String nombreAcudiente = "Estimado usuario"; // Valor por defecto si no se encuentra
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('Ppl').doc(docId).get();
      if (doc.exists && doc.data() != null) {
        nombreAcudiente = doc['nombre_acudiente'] ?? "Estimado usuario";
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error obteniendo nombre del acudiente: $e");
      }
    }

    // Obtener días de prueba desde configuración
    int diasPrueba = 7; // Valor por defecto
    try {
      final configSnap = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
      if (configSnap.docs.isNotEmpty) {
        diasPrueba = configSnap.docs.first.data()['tiempoDePrueba'] ?? 7;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error obteniendo configuración: $e");
      }
    }

    // Construir el mensaje
    String mensaje = Uri.encodeComponent(
        "Hola *$nombreAcudiente*,\n\n"
            "¡Nos alegra darte la bienvenida a *Tu Proceso Ya*! \n\n"
            "Tu cuenta ha sido activada exitosamente. Desde ahora podrás gestionar solicitudes y hacer seguimiento a la situación de tu ser querido PPL de forma rápida y sencilla.\n\n"
            "Contarás con *$diasPrueba días completamente gratis* para explorar todas las funcionalidades de nuestra plataforma.\n\n"
            "Pasado ese tiempo, deberás activar tu suscripción para seguir disfrutando de nuestros servicios y de los *precios especiales* diseñados para ti.\n\n"
            "Ingresa a la aplicación aquí: https://www.tuprocesoya.com\n\n"
            "Gracias por confiar en nosotros.\n\n"
            "Cordialmente,\n*El equipo de soporte de Tu Proceso Ya*"
    );

    String whatsappBusinessUri = "whatsapp://send?phone=$celular&text=$mensaje"; // WhatsApp Business
    String webUrl = "https://wa.me/$celular?text=$mensaje"; // WhatsApp Web

    // Intenta abrir WhatsApp Business o normal
    if (await canLaunchUrl(Uri.parse(whatsappBusinessUri))) {
      await launchUrl(Uri.parse(whatsappBusinessUri));
    } else {
      // Si no está instalado, abrir WhatsApp Web o enviar al usuario a instalarlo
      await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
    }
  }


  Future<void> validarYEnviarMensaje() async
  {
    String celular = widget.doc['celular'] ?? '';
    String docId = widget.doc['id'] ?? '';

    if (celular.isEmpty || docId.isEmpty) {
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
      await enviarMensajeWhatsApp(celular, docId);

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
      mensaje = "El usuario ya está activado";
    } else if (status == "bloqueado") {
      color = Colors.red;
      icono = Icons.lock;
      mensaje = "Este usuario se encuentra bloqueado";
    }
    else {
      color = Colors.blue;
      icono = Icons.error;
      mensaje = "El usuario aún no está activado";
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(icono, color: color, size: 20),
        const SizedBox(width: 8), // Espacio entre icono y texto
        Text(
          mensaje,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget estadoNotificacionWidget(bool isNotificatedActivated) {
    Color color = isNotificatedActivated ? Colors.green : Colors.red;
    IconData icono = isNotificatedActivated ? Icons.notifications_active_outlined : Icons.error;
    String mensaje = isNotificatedActivated
        ? "Ya se notificó al usuario de la activación de la cuenta"
        : "El usuario aún no ha sido notificado de la activación";

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey, width: 1), // 🔹 Borde gris de 1px
      ),
      padding: const EdgeInsets.all(10), // 🔹 Padding de 10px alrededor
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: Column(
          children: [
            estadoUsuarioWidget(widget.doc["status"]),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icono, color: color, size: 20),
                const SizedBox(width: 8), // Espacio entre icono y texto
                Expanded( // Permite que el texto se ajuste dentro del espacio disponible
                  child: Text(
                    mensaje,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis, // Evita desbordamientos
                    maxLines: 1, // Mantiene el texto en una sola línea
                    softWrap: false, // Evita saltos de línea
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}