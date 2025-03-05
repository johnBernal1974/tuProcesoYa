import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../commons/admin_provider.dart';
import '../../../commons/main_layaout.dart';
import '../../../controllers/tiempo_condena_controller.dart';
import '../../../providers/ppl_provider.dart';
import '../../../src/colors/colors.dart';
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


  bool _isLoadingJuzgados = false; // Bandera para evitar múltiples cargas


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
    _asignarDocumento(); // Bloquea el documento al abrirlo

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

  // Future<void> _fetchJuzgadoCondenoPorCiudad() async {
  //   try {
  //     // Obtener la colección 'juzgado_condeno'
  //     QuerySnapshot querySnapshot = await FirebaseFirestore.instance
  //         .collection('juzgado_condeno')
  //         .get();
  //
  //     // Crear una lista para almacenar las "regionales" y sus "juzgados"
  //     List<Map<String, dynamic>> fetchedJuzgadoCondeno = [];
  //
  //     // Iterar sobre los documentos de la colección 'juzgado_condeno'
  //     for (var doc in querySnapshot.docs) {
  //       // Obtener el nombre de la "regional" desde el campo 'name'
  //       String juzgadoCondenoName = doc['name'] ?? 'Nombre no disponible';
  //
  //       // Acceder a la subcolección 'juzgados'
  //       QuerySnapshot juzgadosSnapshot = await doc.reference
  //           .collection('juzgados')
  //           .get();
  //       // Crear una lista con los juzgados usando el campo 'nombre' de cada documento
  //       List<String> juzgados = juzgadosSnapshot.docs.map<String>((centerDoc) {
  //         // Devuelve el campo 'nombre' convertido a String o, si es null, el id convertido a String
  //         return (centerDoc['nombre'] ?? centerDoc.id).toString();
  //       }).toList();
  //
  //
  //       // Armar el mapa con la información de la "regional" y sus "juzgados"
  //       Map<String, dynamic> regionalData = {
  //         'id': doc.id,                 // ID del documento de la "regional"
  //         'nombre': juzgadoCondenoName,   // Nombre obtenido
  //         'juzgados': juzgados,           // Lista de nombres de los juzgados
  //       };
  //       // Agregar la información a la lista final
  //       fetchedJuzgadoCondeno.add(regionalData);
  //     }
  //
  //     // Actualizar el estado con las regionales y sus juzgados
  //     setState(() {
  //       juzgadoQueCondeno = fetchedJuzgadoCondeno;
  //     });
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('Error al cargar las ciudades: $e');
  //     }
  //   }
  // }

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
    //_liberarDocumento(); // 🔥 Libera el documento al cerrar la pantalla
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
                // Align(
                //   alignment: Alignment.centerLeft, // 🔹 Alinear a la izquierda
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start, // 🔹 Asegurar que los widgets se alineen a la izquierda
                //     children: [
                //       estadoUsuarioWidget(widget.doc["status"]),
                //       const SizedBox(height: 10), // Espaciado opcional
                //       estadoNotificacionWidget(widget.doc["isNotificatedActivated"]),
                //     ],
                //   ),
                // ),
                // const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.doc["status"] != "bloqueado") ...[
                      botonGuardar(),
                      bloquearUsuario(),
                    ] else
                      FutureBuilder<bool>(
                        future: _adminPuedeDesbloquear(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox(); // Mientras carga, no muestra nada
                          }
                          if (snapshot.data == true) {
                            return desbloquearUsuario(); // Muestra el botón solo si el admin tiene permiso
                          }
                          return const SizedBox(); // Si no tiene permiso, no muestra nada
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 50),
                Column(
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
                  ],
                ),
                const SizedBox(height: 150),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Asigna el documento al operador actual para que solo él pueda verlo y editarlo
  Future<void> _asignarDocumento() async {
    String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    try {
      await widget.doc.reference.update({'assignedTo': currentUserUid});
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error al asignar el documento: $e");
      }
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
                );
              },
            ),
            const SizedBox(height: 10),

            // 🔹 Mostrar la selección actual 🔹
            if (selectedJuzgadoNombre != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Juzgado seleccionado: $selectedJuzgadoNombre",
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Correo: ${selectedJuzgadoConocimientoEmail ?? 'No disponible'}",
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                  ),
                ],
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
      final fechaCapturaRaw = widget.doc.get('fecha_captura'); // 🔹 Puede ser Timestamp o String
      DateTime? fechaCaptura = _convertirFecha(fechaCapturaRaw); // ✅ Usa la nueva función segura

      if (fechaCaptura == null) {
        debugPrint("❌ Error: No se pudo convertir la fecha de captura");
        return;
      }

      debugPrint("📌 Fecha de captura convertida correctamente: $fechaCaptura");

      await _calculoCondenaController.calcularTiempo(widget.doc.id); // 🔥 Solo pasamos `id`


      mesesRestante = _calculoCondenaController.mesesRestante ?? 0;
      diasRestanteExactos = _calculoCondenaController.diasRestanteExactos ?? 0;
      mesesEjecutado = _calculoCondenaController.mesesEjecutado ?? 0;
      diasEjecutadoExactos = _calculoCondenaController.diasEjecutadoExactos ?? 0;
      porcentajeEjecutado = _calculoCondenaController.porcentajeEjecutado ?? 0;

      debugPrint("🔹 Cálculo de condena completado:");
      debugPrint("   - Meses ejecutados: $mesesEjecutado");
      debugPrint("   - Días ejecutados: $diasEjecutadoExactos");
      debugPrint("   - Meses restantes: $mesesRestante");
      debugPrint("   - Días restantes: $diasRestanteExactos");
      debugPrint("   - Porcentaje ejecutado: $porcentajeEjecutado%");

      setState(() {}); // 🔹 Forzar actualización de UI
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
          borderSide: const BorderSide(color: Colors.deepPurple, width: 1), // Borde gris cuando no está enfocado
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 1), // Borde gris cuando está enfocado
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          child: const Text('Bloquear Usuario'),
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
            String admin = doc['admin'] ?? "Desconocido";
            String accion = doc['accion'] ?? "Ninguna";
            dynamic fechaRaw = doc['fecha']; // 🔥 Puede ser Timestamp o String

            DateTime? fecha = _convertirFecha(fechaRaw); // ✅ Usa la nueva función
            String fechaFormateada = _formatFecha(fecha);

            // 🔹 Definir color e icono según la acción
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
              icono = Icons.edit_note_outlined; // 🔹 Icono de edición para representar cambios
              textoAccion = "Actualizado por: ";
            } else {
              color = Colors.grey;
              icono = Icons.info;
              textoAccion = "Acción realizada por: ";
            }


            return ListTile(
              leading: Icon(icono, color: color),
              title: Text(
                "$textoAccion $admin",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Fecha: $fechaFormateada",
                style: const TextStyle(fontSize: 12),
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
      width: 200,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () async {
            bool confirmar = await _mostrarDialogoConfirmacionBotonGuardar();
            if (!confirmar) return; // Si el usuario cancela, no hace nada

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

            List<String> camposFaltantes = [];

            if ((selectedCentro ?? widget.doc['centro_reclusion']) == null) camposFaltantes.add("Centro de Reclusión");
            if ((selectedRegional ?? widget.doc['regional']) == null) camposFaltantes.add("Regional");
            if ((selectedCiudad ?? widget.doc['ciudad']) == null) camposFaltantes.add("Ciudad");
            if ((selectedJuzgadoEjecucionPenas ?? widget.doc['juzgado_ejecucion_penas']) == null) camposFaltantes.add("Juzgado de Ejecución de Penas");
            if ((selectedJuzgadoNombre ?? widget.doc['juzgado_que_condeno']) == null) camposFaltantes.add("Juzgado que Condenó");
            if ((selectedDelito ?? widget.doc['delito']) == null) camposFaltantes.add("Delito");

            int tiempoCondena = int.tryParse(_tiempoCondenaController.text) ?? 0;
            if (tiempoCondena == 0) {
              camposFaltantes.add("Condena en meses");
            }

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

            SystemChannels.textInput.invokeMethod('TextInput.hide');

            try {
              // 🔹 Obtener datos del admin actual
              User? user = FirebaseAuth.instance.currentUser;
              String adminName = "Desconocido";
              String adminId = user?.uid ?? "Desconocido";

              DocumentSnapshot adminDoc = await FirebaseFirestore.instance.collection('admin').doc(adminId).get();
              if (adminDoc.exists) {
                adminName = "${adminDoc['name']} ${adminDoc['apellidos']}";
              }

              // 🔥 Verificar si ya existe una acción de activado en el historial
              QuerySnapshot historialSnapshot = await widget.doc.reference
                  .collection('historial_acciones')
                  .where('accion', isEqualTo: 'activado')
                  .limit(1)
                  .get();

              bool yaActivado = historialSnapshot.docs.isNotEmpty;

              // 🔹 Actualizar el documento
              await widget.doc.reference.update({
                'nombre_ppl': _nombreController.text,
                'apellido_ppl': _apellidoController.text,
                'numero_documento_ppl': _numeroDocumentoController.text,
                'tipo_documento_ppl': _tipoDocumento,
                'centro_reclusion': selectedCentro ?? widget.doc['centro_reclusion'],
                'regional': selectedRegional ?? widget.doc['regional'],
                'ciudad': selectedCiudad ?? widget.doc['ciudad'],
                'juzgado_ejecucion_penas': selectedJuzgadoEjecucionPenas ?? widget.doc['juzgado_ejecucion_penas'],
                'juzgado_ejecucion_penas_email': selectedJuzgadoEjecucionEmail ?? widget.doc['juzgado_ejecucion_penas_email'],
                'juzgado_que_condeno': selectedJuzgadoNombre ?? widget.doc['juzgado_que_condeno'],
                'juzgado_que_condeno_email': selectedJuzgadoConocimientoEmail ?? widget.doc['juzgado_que_condeno_email'],
                'delito': selectedDelito ?? widget.doc['delito'],
                'radicado': _radicadoController.text,
                'tiempo_condena': tiempoCondena,
                'fecha_captura': _fechaDeCapturaController.text,
                'td': _tdController.text,
                'nui': _nuiController.text,
                'patio': _patioController.text,
                'nombre_acudiente': _nombreAcudienteController.text,
                'apellido_acudiente': _apellidosAcudienteController.text,
                'parentesco_representante': _parentescoAcudienteController.text,
                'celular': _celularAcudienteController.text,
                'email': _emailAcudienteController.text,
                'status': 'activado',
              });

              // 🔥 Registrar en el historial solo si es la primera activación
              if (!yaActivado) {
                await widget.doc.reference.collection('historial_acciones').add({
                  'admin': adminName,
                  'accion': 'activado',
                  'fecha': DateTime.now().toString(),
                });
              } else {
                // 🔥 Si ya fue activado antes, registrar como actualización
                await widget.doc.reference.collection('historial_acciones').add({
                  'admin': adminName,
                  'accion': 'actualización',
                  'fecha': DateTime.now().toString(),
                });
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Datos guardados con éxito.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }

              // 🔹 Redireccionar después de guardar
              Future.delayed(const Duration(seconds: 1), () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeAdministradorPage()),
                );
              });

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
          backgroundColor: blancoCards,
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