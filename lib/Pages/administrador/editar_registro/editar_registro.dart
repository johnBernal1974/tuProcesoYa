import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../commons/main_layaout.dart';
import '../../../controllers/tiempo_condena_controller.dart';
import '../../../providers/ppl_provider.dart';
import '../../../src/colors/colors.dart';

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
  final _laborDescuentoController = TextEditingController();
  final _fechaInicioDescuentoController = TextEditingController();

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



  /// variables para guardar opciones seleccionadas
  String? selectedRegional; // Regional seleccionada
  String? selectedCentro; // Centro de reclusión seleccionado
  String? selectedJuzgadoEjecucionPenas;
  String? selectedCiudad;
  String? selectedJuzgadoNombre;
  String? selectedDelito;

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


  /// opciones de documento de identidad
  final List<String> _opciones = ['Cédula de Ciudadanía','Pasaporte'];

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
    _obtenerDatos();

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

  Future<void> _fetchJuzgadoCondenoPorCiudad() async {
    try {
      // Obtener la colección 'juzgado_condeno'
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('juzgado_condeno')
          .get();

      // Crear una lista para almacenar las "regionales" y sus "juzgados"
      List<Map<String, dynamic>> fetchedJuzgadoCondeno = [];

      // Iterar sobre los documentos de la colección 'juzgado_condeno'
      for (var doc in querySnapshot.docs) {
        // Obtener el nombre de la "regional" desde el campo 'name'
        String juzgadoCondenoName = doc['name'] ?? 'Nombre no disponible';

        // Acceder a la subcolección 'juzgados'
        QuerySnapshot juzgadosSnapshot = await doc.reference
            .collection('juzgados')
            .get();
        // Crear una lista con los juzgados usando el campo 'nombre' de cada documento
        List<String> juzgados = juzgadosSnapshot.docs.map<String>((centerDoc) {
          // Devuelve el campo 'nombre' convertido a String o, si es null, el id convertido a String
          return (centerDoc['nombre'] ?? centerDoc.id).toString();
        }).toList();


        // Armar el mapa con la información de la "regional" y sus "juzgados"
        Map<String, dynamic> regionalData = {
          'id': doc.id,                 // ID del documento de la "regional"
          'nombre': juzgadoCondenoName,   // Nombre obtenido
          'juzgados': juzgados,           // Lista de nombres de los juzgados
        };
        // Agregar la información a la lista final
        fetchedJuzgadoCondeno.add(regionalData);
      }

      // Actualizar el estado con las regionales y sus juzgados
      setState(() {
        juzgadoQueCondeno = fetchedJuzgadoCondeno;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error al cargar las ciudades: $e');
      }
    }
  }
  Future<void> _fetchJuzgadosConocimiento(String juzgadoCondenoId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('juzgado_condeno')
          .doc(juzgadoCondenoId)
          .collection('juzgados')
          .get();

      List<Map<String, String>> fetchedJuzgadoConocimiento = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'nombre': doc.get('nombre').toString(),  // Castear a String
          'correo': doc.get('correo').toString(),  // Castear a String
        };
      }).toList();

      setState(() {
        juzgadosConocimiento = fetchedJuzgadoConocimiento;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error al obtener los juzgado de conocimiento: $e");
      }
    }
  }

  Future<void> _fetchDelitos() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('delitos').get();

      List<Map<String, String>> fetchedDelitos = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'delito': doc.get('delito').toString(),
        };
      }).toList();

      setState(() {
        delito = fetchedDelitos;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error al obtener los delitos: $e");
      }
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
    _laborDescuentoController.dispose();
    _fechaInicioDescuentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Datos generales',
      content: Form(
        key: _formKey,
        child: Center(
          child: SizedBox(
            // Si el ancho de la pantalla es mayor o igual a 800, usa 800, de lo contrario ocupa todo el ancho disponible
            width: MediaQuery.of(context).size.width >= 1000 ? 1000 : double.infinity,
            child: ListView(
              children: [
                const Text(
                  'Información del PPL',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                // Puedes mostrar el id en pantalla si lo deseas
                Text('ID: ${widget.doc.id}', style: const TextStyle(fontSize: 11)),
                const SizedBox(height: 20),
                datosEjecucionCondena(),
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
                seleccionarDelito(),
                const SizedBox(height: 15),
                fechaCapturaPpl(),
                const SizedBox(height: 15),
                radicadoPpl(),
                const SizedBox(height: 15),
                condenaPpl(),
                const SizedBox(height: 15),
                tdPpl(),
                const SizedBox(height: 15),
                nuiPpl(),
                const SizedBox(height: 15),
                patioPpl(),
                const SizedBox(height: 15),
                laborDescuentoPpl(),
                const SizedBox(height: 15),
                fechaInicioDescuentoPpl(),
                const SizedBox(height: 30),
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
                emailAcudiente(),
                const SizedBox(height: 50),
                estadoUsuarioWidget(widget.doc["status"]),
                estadoNotificacionWidget(widget.doc["isNotificatedActivated"]),
                const SizedBox(height: 50),
                botonGuardar(),
                const SizedBox(height: 150),
              ],
            ),
          ),
        ),
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
          border: Border.all(color: primary),
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Buscar centro de reclusión",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_mostrarDropdownJuzgadoEjecucion)
          if (widget.doc['juzgado_ejecucion_penas'] != null && widget.doc['juzgado_ejecucion_penas'].isNotEmpty)
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
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _mostrarDropdownJuzgadoEjecucion = true;
                        selectedJuzgadoEjecucionPenas = null;
                      });
                      _fetchJuzgadosEjecucion(); // 🔥 Llamar al método aquí también
                    },
                    child: const Row(
                      children: [
                        Text("Juzgado de Ejecución de Penas", style: TextStyle(fontSize: 11)),
                        Icon(Icons.edit, size: 15),
                      ],
                    ),
                  ),
                  Text(widget.doc['juzgado_ejecucion_penas']!, style: const TextStyle(fontWeight: FontWeight.bold, height: 1)),
                  const SizedBox(height: 10),
                  Text(
                    "correo: ${widget.doc['juzgado_ejecucion_penas_email']!}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      height: 1,
                    ),
                  )

                ],
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft, // Botón alineado a la izquierda
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  side: BorderSide(width: 1, color: Theme.of(context).primaryColor), // Borde con color primario
                  backgroundColor: Colors.white, // Fondo blanco
                  foregroundColor: Colors.black, // Letra en negro
                ),
                onPressed: () {
                  setState(() {
                    _mostrarDropdownJuzgadoEjecucion = true;
                  });
                  _fetchJuzgadosEjecucion(); // 🔥 Cargar los juzgados aquí también
                },
                child: const Text("Seleccionar Juzgado de Ejecución de Penas"),
              ),

            )
        else
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: primary),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                ),
                  child: DropdownButton<String>(
                    value: selectedJuzgadoEjecucionPenas,
                    hint: const Text('Selecciona un Juzgado de Ejecución de Penas'),
                    onChanged: (value) {
                      setState(() {
                        selectedJuzgadoEjecucionPenas = value;
                        // Buscar el email correspondiente en la lista de juzgados
                        final selected = juzgadosEjecucionPenas.firstWhere(
                              (element) => element['juzgadoEP'] == value,
                          orElse: () => <String, String>{}, // Especifica explícitamente el tipo
                        );
                        selectedJuzgadoEjecucionEmail = selected['email'];
                      });
                    },
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black),
                    items: (List<Map<String, String>>.from(juzgadosEjecucionPenas)
                      ..sort((a, b) => a['juzgadoEP']!.compareTo(b['juzgadoEP']!))) // Ordena alfabéticamente
                        .map((juzgado) {
                      return DropdownMenuItem<String>(
                        value: juzgado['juzgadoEP'],
                        child: Text(
                          juzgado['juzgadoEP']!,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  )
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _mostrarDropdownJuzgadoEjecucion = false;
                    selectedJuzgadoEjecucionPenas = widget.doc['juzgado_ejecucion_penas'];
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
            ],
          ),
      ],
    );
  }

  Widget seleccionarJuzgadoQueCondeno() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Si ya hay información guardada, mostrarla con opción a editar
        if (!_mostrarDropdownJuzgadoCondeno &&
            _juzgadoQueCondeno != "" &&
            _juzgado != "")
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
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _mostrarDropdownJuzgadoCondeno = true;
                      // Limpiar los valores para forzar la nueva selección
                      _juzgadoQueCondeno = "";
                      _juzgado = "";
                    });
                    _fetchJuzgadoCondenoPorCiudad();
                    // No es necesario llamar a  aquí;
                    // se llamará cuando se seleccione la ciudad en el dropdown.
                  },
                  child: const Row(
                    children: [
                      Text("Ciudad juzgado de conocimiento", style: TextStyle(fontSize: 11)),
                      Icon(Icons.edit, size: 15),
                    ],
                  ),
                ),
                Text(widget.doc['ciudad'], style: const TextStyle(fontWeight: FontWeight.bold, height: 1)),
                const SizedBox(height: 5),
                const Text("Juzgado de conocimiento", style: TextStyle(fontSize: 11)),
                Text(widget.doc['juzgado_que_condeno'], style: const TextStyle(fontWeight: FontWeight.bold, height: 1)),
                const SizedBox(height: 10),
                Text(
                  "correo: ${widget.doc['juzgado_que_condeno_email']!}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          )
        // Si no hay información (o se pulsa editar) se muestra el botón de selección o los dropdowns
        else if (!_mostrarDropdownJuzgadoCondeno)
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                side: BorderSide(width: 1, color: Theme.of(context).primaryColor), // Borde con color primario
                backgroundColor: Colors.white, // Fondo blanco
                foregroundColor: Colors.black, // Letra en negro
              ),
              onPressed: () {
                setState(() {
                  _mostrarDropdownJuzgadoCondeno = true;
                });
                _fetchJuzgadoCondenoPorCiudad();
              },
              child: const Text("Seleccionar Juzgado de Conocimiento"),
            ),
          )
        // Modo edición: se muestran los dropdowns para seleccionar ciudad y luego el juzgado
        else
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: primary),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            child: Column(
              children: [
                // Dropdown para seleccionar la ciudad (documentos de la colección juzgado_condeno)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white,
                  ),
                  child: DropdownButton<String>(
                    value: selectedCiudad,
                    hint: const Text('Selecciona una ciudad'),
                    onChanged: (value) {
                      setState(() {
                        selectedCiudad = value;
                        // Limpiar la selección previa del juzgado
                        selectedJuzgadoNombre = null;
                      });
                      // Cargar los juzgados de conocimiento correspondientes a la ciudad seleccionada
                      _fetchJuzgadosConocimiento(value!);
                    },
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black),
                    items: juzgadoQueCondeno.map((ciudad) {
                      return DropdownMenuItem<String>(
                        value: ciudad['id'],
                        child: Text(
                          ciudad['nombre']!,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                // Botón para cancelar y restaurar los valores originales
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _mostrarDropdownJuzgadoCondeno = false;
                      _juzgadoQueCondeno = widget.doc['juzgado_que_condeno'];
                      _juzgado = widget.doc['juzgado_que_condeno'];
                      selectedCiudad = null; // 🔥 Evita que la ciudad anterior se muestre en el dropdown

                      // Verificar que el juzgado existe en la lista antes de asignarlo
                      if (juzgadosConocimiento.any((j) => j['nombre'] == widget.doc['juzgado_que_condeno'])) {
                        selectedJuzgadoNombre = widget.doc['juzgado_que_condeno'];
                      } else {
                        selectedJuzgadoNombre = null;
                      }

                      selectedJuzgadoConocimientoEmail = widget.doc['juzgado_que_condeno_email'];
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

                const SizedBox(height: 20),
                // Dropdown para seleccionar el juzgado de conocimiento (solo si se ha seleccionado la ciudad)
                if (selectedCiudad != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white,
                    ),
                    child: DropdownButton<String>(
                      value: selectedJuzgadoNombre,
                      hint: const Text('Selecciona un juzgado de conocimiento'),
                      onChanged: (value) {
                        setState(() {
                          selectedJuzgadoNombre = value;
                        });
                        setState(() {
                          selectedJuzgadoNombre = value;
                          // Buscar el email correspondiente en la lista de juzgados
                          final selected = juzgadosConocimiento.firstWhere(
                                (element) => element['nombre'] == value,
                            orElse: () => <String, String>{},  // Especifica explícitamente el tipo
                          );
                          selectedJuzgadoConocimientoEmail = selected['correo'];
                        });
                      },
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black),
                      items: juzgadosConocimiento.map((juzgado) {
                        return DropdownMenuItem<String>(
                          value: juzgado['nombre'], // Usamos el nombre como valor
                          child: Text(
                            juzgado['nombre']!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget seleccionarDelito() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Si NO estamos en modo edición
        if (!_mostrarDropdownDelito)
        // Si ya existe un delito guardado en el documento
          if (widget.doc['delito'] != null &&
              widget.doc['delito'].toString().trim().isNotEmpty)
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
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _mostrarDropdownDelito = true;
                        selectedDelito = null;
                      });
                      _fetchDelitos();
                    },
                    child: const Row(
                      children: [
                        Text("Delito", style: TextStyle(fontSize: 11)),
                        Icon(Icons.edit, size: 15),
                      ],
                    ),
                  ),
                  Text(
                    widget.doc['delito'],
                    style: const TextStyle(fontWeight: FontWeight.bold, height: 1),
                  ),
                ],
              ),
            )
          else
          // Si no existe información, se muestra un botón para seleccionar
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  side: BorderSide(
                      width: 1, color: Theme.of(context).primaryColor),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    _mostrarDropdownDelito = true;
                  });
                  _fetchDelitos();
                },
                child: const Text("Seleccionar Delito"),
              ),
            )
        else
        // Modo edición: se muestran los dropdowns para seleccionar el delito
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: primary),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                ),
                child: DropdownButton<String>(
                  value: selectedDelito,
                  hint: const Text('Selecciona un delito'),
                  onChanged: (value) {
                    setState(() {
                      selectedDelito = value;
                    });
                  },
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black),
                  items: delito.map((delitoDoc) {
                    return DropdownMenuItem<String>(
                      value: delitoDoc['delito'],
                      child: Text(
                        delitoDoc['delito']!,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _mostrarDropdownDelito = false;
                    // Se restaura el valor original del documento
                    // (podrías asignarlo a una variable _delito si la usas)
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
            ],
          ),
      ],
    );
  }

  Future<void> _obtenerDatos() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentSnapshot document = await firestore.collection('Ppl').doc(widget.doc.id).get();

    if (document.exists) {
      final Map<String, dynamic> data = document.data() as Map<String, dynamic>;
      //final String regional = data['regional'];
      //final String centroReclusion = data['centro_reclusion'];
      //final String juzgadoEjecucionPenas = data['juzgado_ejecucion_penas'];
      final String juzgado = data['juzgado_que_condeno'];
      final String juzgadoQueCondeno = data['ciudad'];
      //final String delito = data['delito'];

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
      await _calculoCondenaController.calcularTiempo(widget.doc.id);
      mesesRestante = _calculoCondenaController.mesesRestante ?? 0;
      diasRestanteExactos = _calculoCondenaController.diasRestanteExactos ?? 0;
      mesesEjecutado = _calculoCondenaController.mesesEjecutado ?? 0;
      diasEjecutadoExactos = _calculoCondenaController.diasEjecutadoExactos ?? 0;
      porcentajeEjecutado = _calculoCondenaController.porcentajeEjecutado ?? 0;
    } catch (e) {
      // Maneja la excepción
    }
  }
  void _initFormFields() {
    _nombreController.text = widget.doc.get('nombre_ppl') ?? "";
    _apellidoController.text = widget.doc.get('apellido_ppl') ?? "";
    _numeroDocumentoController.text = widget.doc.get('numero_documento_ppl').toString();
    _tipoDocumento = widget.doc.get('tipo_documento_ppl') ?? "";
    _radicadoController.text = widget.doc.get('radicado') ?? "";
    _tiempoCondenaController.text = widget.doc.get('tiempo_condena').toString();
    _fechaDeCapturaController.text = widget.doc.get('fecha_captura') ?? "";
    _tdController.text = widget.doc.get('td') ?? "";
    _nuiController.text = widget.doc.get('nui') ?? "";
    _patioController.text = widget.doc.get('patio') ?? "";
    String laborDescuento = widget.doc.get('labor_descuento') as String;
    if(laborDescuento.trim().isEmpty) {
      _laborDescuentoController.text = "Ningúna informada";
    } else {
      _laborDescuentoController.text = laborDescuento;
    }

    String fechaInicioDescuento = widget.doc.get('fecha_inicio_descuento') ?? "";
    if (fechaInicioDescuento.trim().isEmpty) {
      _fechaInicioDescuentoController.text = "Sin información"; // Solo para mostrarlo en UI
    } else {
      _fechaInicioDescuentoController.text = fechaInicioDescuento; // Mantiene el valor real
    }

    _nombreAcudienteController.text = widget.doc.get('nombre_acudiente') ?? "";
    _apellidosAcudienteController.text = widget.doc.get('apellido_acudiente') ?? "";
    _parentescoAcudienteController.text = widget.doc.get('parentesco_representante') ?? "";
    _celularAcudienteController.text = widget.doc.get('celular') ?? "";
    _emailAcudienteController.text = widget.doc.get('email') ?? "";
  }

  Widget datosEjecucionCondena() {
    double screenWidth = MediaQuery.of(context).size.width;
    // Cajón para "Condena transcurrida"
    Widget boxCondenaTranscurrida = Container(
      width: 150,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: primary,width: 3),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Condena\ntranscurrida',
            style: TextStyle(
              fontSize: screenWidth > 600 ? 14 : 12,
              color: negroLetras,
              height: 1
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            mesesEjecutado == 1
                ? diasEjecutadoExactos == 1
                ? '$mesesEjecutado mes : $diasEjecutadoExactos día'
                : '$mesesEjecutado mes : $diasEjecutadoExactos días'
                : diasEjecutadoExactos == 1
                ? '$mesesEjecutado meses : $diasEjecutadoExactos día'
                : '$mesesEjecutado meses : $diasEjecutadoExactos días',
            style: TextStyle(
              fontSize: screenWidth > 600 ? 14 : 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    // Cajón para "Condena restante"
    Widget boxCondenaRestante = Container(
      width: 150,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: primary,width: 3),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Condena\nrestante',
            style: TextStyle(
              fontSize: screenWidth > 600 ? 14 : 12,
              color: negroLetras,
              height: 1
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            mesesRestante == 1
                ? diasRestanteExactos == 1
                ? '$mesesRestante mes : $diasRestanteExactos día'
                : '$mesesRestante mes : $diasRestanteExactos días'
                : mesesRestante > 0
                ? diasRestanteExactos == 1
                ? '$mesesRestante meses : $diasRestanteExactos día'
                : '$mesesRestante meses : $diasRestanteExactos días'
                : diasRestanteExactos == 1
                ? '$diasRestanteExactos día'
                : '$diasRestanteExactos días',
            style: TextStyle(
              fontSize: screenWidth > 600 ? 14 : 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    // Cajón para "Porcentaje ejecutado"
    Widget boxPorcentajeEjecutado = Container(
      width: 150,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: primary,width: 3),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Porcentaje\nejecutado: ',
            style: TextStyle(
              fontSize: screenWidth > 600 ? 14 : 12,
              color: negroLetras,
              height: 1
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${porcentajeEjecutado.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: screenWidth > 600 ? 14 : 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    // Utiliza un Wrap para que los cajones se organicen en filas en dispositivos móviles
    return Wrap(
      spacing: 10,  // Espacio horizontal entre cajones
      runSpacing: 10,  // Espacio vertical entre filas
      children: [
        boxCondenaTranscurrida,
        boxCondenaRestante,
        boxPorcentajeEjecutado,
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

  Widget fechaCapturaPpl(){
    return textFormField(
      controller: _fechaDeCapturaController,
      labelText: 'Fecha de captura (YYYY-MM-DD)',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese la fecha de captura';
        }
        return null;
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

  Widget condenaPpl(){
    return textFormField(
      controller: _tiempoCondenaController,
      labelText: 'Condena en meses',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese la condena en meses';
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

  Widget laborDescuentoPpl(){
    return textFormField(
      controller: _laborDescuentoController,
      labelText: 'labor de descuento',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese la labor de descuento';
        }
        return null;
      },
    );
  }

  Widget fechaInicioDescuentoPpl(){
    return textFormField(
      controller: _fechaInicioDescuentoController,
      labelText: 'Fecha inicio descuento (YYYY-MM-DD)',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese la fecha de inicio de descuento';
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
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      style: const TextStyle(fontWeight: FontWeight.bold, height: 1),
      decoration: InputDecoration(
        labelText: labelText,
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
      validator: validator,
      keyboardType: keyboardType,
    );  }

  Widget botonGuardar() {
    bool isCentroValid = (selectedCentro != null && selectedCentro!.trim().isNotEmpty) ||
        (widget.doc['centro_reclusion'] != null && widget.doc['centro_reclusion'].toString().trim().isNotEmpty);

    bool isRegionalValid = (selectedRegional != null && selectedRegional!.trim().isNotEmpty) ||
        (widget.doc['regional'] != null && widget.doc['regional'].toString().trim().isNotEmpty);

    bool isCiudadValid = (selectedCiudad != null && selectedCiudad!.trim().isNotEmpty) ||
        (widget.doc['ciudad'] != null && widget.doc['ciudad'].toString().trim().isNotEmpty);

    bool isJuzgadoEjValid = (selectedJuzgadoEjecucionPenas != null && selectedJuzgadoEjecucionPenas!.trim().isNotEmpty) ||
        (widget.doc['juzgado_ejecucion_penas'] != null && widget.doc['juzgado_ejecucion_penas'].toString().trim().isNotEmpty);

    bool isJuzgadoQueValid = (selectedJuzgadoNombre != null && selectedJuzgadoNombre!.trim().isNotEmpty) ||
        (widget.doc['juzgado_que_condeno'] != null && widget.doc['juzgado_que_condeno'].toString().trim().isNotEmpty);

    bool isDelitoValid = (selectedDelito != null && selectedDelito!.trim().isNotEmpty) ||
        (widget.doc['delito'] != null && widget.doc['delito'].toString().trim().isNotEmpty);
    return SizedBox(
      width: 120,
      child: Align(
        alignment: Alignment.center, // Centra horizontalmente
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () {
            // Primero validamos el formulario
            if (!_formKey.currentState!.validate()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.red,
                  content: Text(
                    'No se puede guardar hasta que estén todos los campos llenos',
                    style: TextStyle(color: Colors.white),
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
        
            // Validaciones adicionales para campos que no forman parte del Form
            // (por ejemplo, dropdowns u otros controles)
            if (!isCentroValid || !isRegionalValid || !isCiudadValid || !isJuzgadoEjValid || !isJuzgadoQueValid || !isDelitoValid ||
                _nombreController.text.trim().isEmpty ||
                _apellidoController.text.trim().isEmpty ||
                _numeroDocumentoController.text.trim().isEmpty ||
                _tipoDocumento.trim().isEmpty ||
                _radicadoController.text.trim().isEmpty ||
                _fechaDeCapturaController.text.trim().isEmpty ||
                _tdController.text.trim().isEmpty ||
                _nuiController.text.trim().isEmpty ||
                _patioController.text.trim().isEmpty ||
                _nombreAcudienteController.text.trim().isEmpty ||
                _apellidosAcudienteController.text.trim().isEmpty ||
                _parentescoAcudienteController.text.trim().isEmpty ||
                _celularAcudienteController.text.trim().isEmpty ||
                _emailAcudienteController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.red,
                  content: Text(
                    'No se puede guardar hasta que estén todos los campos llenos',
                    style: TextStyle(color: Colors.white),
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
        
            // Si todo está bien, parseamos los datos necesarios
            int tiempoCondena = int.parse(_tiempoCondenaController.text);
        
            // Oculta el teclado
            SystemChannels.textInput.invokeMethod('TextInput.hide');

            Map<String, String> correosCentro = {
              'correo_direccion': '',
              'correo_juridica': '',
              'correo_principal': '',
              'correo_sanidad': '',
            };

            // Verificar si hay un centro de reclusión seleccionado y obtener sus correos
            if (selectedCentro != null) {
              var centroEncontrado = centrosReclusionTodos.firstWhere(
                    (centro) => centro['id'] == selectedCentro,
                orElse: () => <String, Object>{},  // Asegúrate de que esto sea Map<String, dynamic>
              );


              if (centroEncontrado.isNotEmpty && centroEncontrado.containsKey('correos')) {
                var correosMap = centroEncontrado['correos'] as Map<String, dynamic>;  // Convertir a Map<String, dynamic>

                correosCentro = {
                  'correo_direccion': correosMap['correo_direccion']?.toString() ?? '',
                  'correo_juridica': correosMap['correo_juridica']?.toString() ?? '',
                  'correo_principal': correosMap['correo_principal']?.toString() ?? '',
                  'correo_sanidad': correosMap['correo_sanidad']?.toString() ?? '',
                };
              }
            }

            // Actualiza el documento en Firestore
            widget.doc.reference.update({
              'nombre_ppl': _nombreController.text,
              'apellido_ppl': _apellidoController.text,
              'numero_documento_ppl': _numeroDocumentoController.text,
              'tipo_documento_ppl': _tipoDocumento,
              'centro_reclusion': selectedCentro ?? widget.doc['centro_reclusion'],
              'regional': selectedRegional ?? widget.doc['regional'],
              'ciudad': selectedCiudad ?? widget.doc['ciudad'],
              'juzgado_ejecucion_penas': selectedJuzgadoEjecucionPenas ?? widget.doc['juzgado_ejecucion_penas'].toString(),
              'juzgado_ejecucion_penas_email': selectedJuzgadoEjecucionEmail ?? widget.doc['juzgado_ejecucion_penas_email'].toString(),
              'juzgado_que_condeno': selectedJuzgadoNombre ?? widget.doc['juzgado_que_condeno'].toString(),
              'juzgado_que_condeno_email': selectedJuzgadoConocimientoEmail ?? widget.doc['juzgado_que_condeno_email'].toString(),
              'delito': selectedDelito ?? widget.doc['delito'],
              'radicado': _radicadoController.text,
              'tiempo_condena': tiempoCondena,
              'fecha_captura': _fechaDeCapturaController.text,
              'td': _tdController.text,
              'nui': _nuiController.text,
              'patio': _patioController.text,
              'labor_descuento': _laborDescuentoController.text,
              'fecha_inicio_descuento': (_fechaInicioDescuentoController.text.trim().isEmpty ||
                  _fechaInicioDescuentoController.text.trim() == 'Sin información')
                  ? null
                  : _fechaInicioDescuentoController.text.trim(),
              'nombre_acudiente': _nombreAcudienteController.text,
              'apellido_acudiente': _apellidosAcudienteController.text,
              'parentesco_representante': _parentescoAcudienteController.text,
              'celular': _celularAcudienteController.text,
              'email': _emailAcudienteController.text,
              'status': 'activado',
            }).then((_) {
              // Guardar automáticamente los correos en la subcolección "correos_centro_reclusion"
              widget.doc.reference.collection('correos_centro_reclusion').doc('emails').set({
                'correo_direccion': correosCentro['correo_direccion'] ?? '',
                'correo_juridica': correosCentro['correo_juridica'] ?? '',
                'correo_principal': correosCentro['correo_principal'] ?? '',
                'correo_sanidad': correosCentro['correo_sanidad'] ?? '',
              });
                          ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Datos guardados con éxito y el usuario está activado'),
                  duration: Duration(seconds: 2),
                ),
              );
            });

            // Llamar al método para enviar mensaje de WhatsApp
            validarYEnviarMensaje();

          },
          child: const Text('Guardar Cambios'),
        ),
      ),
    );
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

    // Construir el mensaje
    String mensaje = Uri.encodeComponent(
        "Hola *$nombreAcudiente*,\n\n"
            "Tu cuenta de *Tu Proceso Ya* ha sido activada.\n\n"
            "Gracias por confiar en nosotros.\n\n"
            "Cordialmente,\nEl equipo de soporte."
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
    } else if (status == "servicio_solicitado") {
      color = Colors.blue;
      icono = Icons.info;
      mensaje = "Este usuario tiene solicitudes pendientes";
    } else {
      color = Colors.red;
      icono = Icons.error;
      mensaje = "El usuario aún no está activado";
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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
    IconData icono = isNotificatedActivated ? Icons.check_circle : Icons.error;
    String mensaje = isNotificatedActivated
        ? "Ya se notificó al usuario de la activación de la cuenta"
        : "El usuario aún no ha sido notificado de la activación";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
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
    );
  }



}