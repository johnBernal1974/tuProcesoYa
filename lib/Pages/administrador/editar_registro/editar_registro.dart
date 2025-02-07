import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  /// variables para guardar opciones seleccionadas
  String? selectedRegional; // Regional seleccionada
  String? selectedCentro; // Centro de reclusión seleccionado
  String? selectedJuzgadoEjecucionPenas;
  String? selectedCiudad;
  String? selectedJuzgadoNombre;
  String? selectedDelito;

  String _regional = "";
  String _centroReclusion = "";


  String _juzgadoEjecucionPenas= "";
  String _ciudad= "";


  String _juzgadoQueCondeno= "";
  String _juzgado= "";


  String _delito= "";

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
    _regional = widget.doc['regional'] ?? "";
    _centroReclusion = widget.doc['centro_reclusion'] ?? "";
    Future.delayed(Duration.zero, () {
      setState(() {
        isLoading = false; // Cambia el estado después de que se verifiquen los valores
      });
    });
    _fetchJuzgado_condeno();
    _obtenerDatos();
    _fetchDelitos();
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
    if (widget.doc != null) {
      _nombreController.text = widget.doc.get('nombre_ppl') ?? "";
      _apellidoController.text = widget.doc.get('apellido_ppl') ?? "";
      _numeroDocumentoController.text = widget.doc.get('numero_documento_ppl').toString() ?? "";
      _tipoDocumento = widget.doc.get('tipo_documento_ppl') ?? "";
      _radicadoController.text = widget.doc.get('radicado') ?? "";
      _tiempoCondenaController.text = widget.doc.get('tiempo_condena').toString() ?? "";
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Datos generales',
      content: Form(
        key: _formKey,
        child: ListView(
          children: [
            const Text('Información del PPL', style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18
            ),),
            //Puedes mostrar el id en pantalla si lo deseas
            Text('ID: ${widget.doc.id}', style: TextStyle(fontSize: 11)),
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
            const Text('Información del Acudiente', style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18)),
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
            botonGuardar(),
            const SizedBox(height: 150),
          ],
        ),
      ),
    );
  }

  /// Método para obtener las regionales desde Firestore
  Future<void> _fetchRegionales() async {
    try {
      // Obtener la colección 'regional'
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('regional')
          .get();

      // Crear una lista para almacenar las regionales y sus centros de reclusión
      List<Map<String, dynamic>> fetchedRegionales = [];

      // Iterar sobre los documentos de la colección 'regional'
      for (var doc in querySnapshot.docs) {
        // Obtener el nombre de la regional desde el campo 'name'
        String regionalName = doc['name'] ?? 'Nombre no disponible'; // Asegurarse de que no sea nulo

        // Acceder a la subcolección 'centros_reclusion' para obtener los centros
        QuerySnapshot centrosReclusionSnapshot = await doc.reference
            .collection('centros_reclusion')
            .get();

        // Crear una lista con los centros de reclusión
        List<String> centrosReclusion = centrosReclusionSnapshot.docs
            .map((centerDoc) => centerDoc.id)  // Usar el id del centro como nombre o identificador
            .toList();

        // Agregar los datos de la regional y sus centros a la lista
        fetchedRegionales.add({
          'id': doc.id,  // El id del documento de la regional
          'nombre': regionalName,  // El nombre de la regional
          'centros_reclusion': centrosReclusion,  // Lista de centros de reclusión
        });
      }

      // Actualizar el estado con las regionales y centros de reclusión
      setState(() {
        regionales = fetchedRegionales;
      });

      print('Regiones cargadas correctamente');
    } catch (e) {
      print('Error al cargar las regionales: $e');
    }
  }

  Future<void> _fetchJuzgado_condeno() async {
    try {
      // Obtener la colección 'juzgado_condeno'
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('juzgado_condeno')
          .get();

      // Crear una lista para almacenar las ciudades y sus juzgados
      List<Map<String, dynamic>> fetchedJuzgadoCondeno = [];

      // Iterar sobre los documentos de la colección 'juzgado_condeno'
      for (var doc in querySnapshot.docs) {
        // Obtener el nombre de la ciudad desde el campo 'name'
        String JuzgadoCondenoName = doc['name'] ?? 'Nombre no disponible'; // Asegurarse de que no sea nulo

        // Acceder a la subcolección 'centros_reclusion' para obtener los centros
        QuerySnapshot juzgadosSnapshot = await doc.reference
            .collection('juzgados')
            .get();

        // Crear una lista con los centros de reclusión
        List<String> juzgados = juzgadosSnapshot.docs
            .map((centerDoc) => centerDoc.id)  // Usar el id del centro como nombre o identificador
            .toList();

        // Agregar los datos de la regional y sus centros a la lista
        fetchedJuzgadoCondeno.add({
          'id': doc.id,  // El id del documento de la regional
          'nombre': JuzgadoCondenoName,  // El nombre de la regional
          'juzgados': juzgados,  // Lista de centros de reclusión
        });
      }

      // Actualizar el estado con las regionales y centros de reclusión
      setState(() {
        juzgadoQueCondeno = fetchedJuzgadoCondeno;
      });

      print('Ciudades cargadas correctamente');
    } catch (e) {
      print('Error al cargar las ciudades: $e');
    }
  }

  /// Método para obtener los centros de reclusión según la regional seleccionada
  Future<void> _fetchCentrosReclusion(String regionalId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('regional')
          .doc(regionalId)
          .collection('centros_reclusion')
          .get();

      List<Map<String, String>> fetchedCentros = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'nombre': doc.id,  // Usamos el 'id' como el 'nombre' del centro
        };
      }).toList();

      setState(() {
        centrosReclusion = fetchedCentros;
      });
      print("Centro reclusion*********************$centrosReclusion");

      // if (centrosReclusion.isNotEmpty) {
      //   selectedCentro = centrosReclusion.first['id'];  // Seleccionamos el primer centro por defecto
      // }
    } catch (e) {
      print("Error al obtener los centros de reclusión: $e");
    }
  }

  /// Método para obtener los juzgados de conocimiento según la ciudad seleccionada
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
        };
      }).toList();

      setState(() {
        juzgadosConocimiento = fetchedJuzgadoConocimiento;
      });
      print("Juzgandos de conocimiento*********************$juzgadosConocimiento");


    } catch (e) {
      print("Error al obtener los juzgado de conocimiento: $e");
    }
  }

  /// Método para obtener los delitos
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
      print("Delitos*********************$delito");

      // if (delitos.isNotEmpty) {
      //   selectedDelito = delitos.first['delito'];  // Seleccionamos el primer delito por defecto
      // }
    } catch (e) {
      print("Error al obtener los delitos: $e");
    }
  }



  Widget seleccionarCentroReclusion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isLoading)
          if (_regional.isEmpty && _centroReclusion.isEmpty && !_mostrarDropdowns)
            Align(
              alignment: Alignment.centerLeft, // Alinea el botón a la izquierda
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  side: BorderSide(width: 1, color: Theme.of(context).primaryColor), // Borde con color primario
                  backgroundColor: Colors.white, // Fondo blanco
                  foregroundColor: Colors.black, // Letra en negro
                ),
                onPressed: () {
                  setState(() {
                    _mostrarDropdowns = true;
                    _fetchRegionales(); // Cargar regionales al presionar el botón
                  });
                },
                child: const Text("Seleccionar Centro de Reclusión"),
              ),
            )
          else if (_regional.isNotEmpty && _centroReclusion.isNotEmpty && !_mostrarDropdowns)
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
                        _mostrarDropdowns = true;
                        _regional = "";
                        _centroReclusion = "";
                        _fetchRegionales();
                      });
                    },
                    child: const Row(
                      children: [
                        Text("Regional", style: TextStyle(fontSize: 11)),
                        Icon(Icons.edit, size: 15),
                      ],
                    ),
                  ),
                  Text(_regional, style: const TextStyle(fontWeight: FontWeight.bold, height: 1)),
                  const SizedBox(height: 15),
                  const Text("Centro de reclusión", style: TextStyle(fontSize: 11)),
                  Text(_centroReclusion, style: const TextStyle(fontWeight: FontWeight.bold, height: 1)),
                  const SizedBox(height: 15),
                ],
              ),
            )
          else
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white,
                  ),
                  child: DropdownButton<String>(
                    value: selectedRegional,
                    hint: const Text('Selecciona una regional'),
                    onChanged: (value) {
                      setState(() {
                        selectedRegional = value;
                        selectedCentro = null;
                      });
                      _fetchCentrosReclusion(value!);
                    },
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black),
                    items: regionales.map((regional) {
                      return DropdownMenuItem<String>(
                        value: regional['id'],
                        child: Text(
                          regional['nombre']!,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      _mostrarDropdowns = false;
                      _regional = widget.doc['regional'] ?? "";
                      _centroReclusion = widget.doc['centro_reclusion'] ?? "";
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

                if (selectedRegional != null)
                  Container(
                    alignment: Alignment.topLeft,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white,
                    ),
                    child: DropdownButton<String>(
                      value: selectedCentro,
                      hint: const Text('Selecciona un centro de reclusión'),
                      onChanged: (value) {
                        setState(() {
                          selectedCentro = value;
                        });
                      },
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black),
                      items: centrosReclusion.map((centro) {
                        return DropdownMenuItem<String>(
                          value: centro['id'],
                          child: Text(
                            centro['nombre']!,
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
      ],
    );
  }




  Widget seleccionarJuzgadoQueCondeno(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_juzgadoQueCondeno != "" && _juzgado != "")
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey), // Borde gris
              borderRadius: BorderRadius.circular(4), // Borde redondeado
              color: Colors.white, // Fondo blanco
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _mostrarDropdownJuzgadoCondeno = true;
                      _juzgadoQueCondeno = "";
                      _juzgado = "";
                    });
                  },
                  child: const Row(
                    children: [
                      Text("Ciudad juzgado de conocimiento", style: TextStyle(fontSize: 11)),
                      Icon(Icons.edit, size: 15),
                    ],
                  ),
                ),
                Text(widget.doc['ciudad'], style: const TextStyle(fontWeight: FontWeight.bold, height: 1)),
                const SizedBox(height: 15),
                const Text("Juzgado de conocimiento", style: TextStyle(fontSize: 11)),
                Text(widget.doc['juzgado_que_condeno'], style: const TextStyle(fontWeight: FontWeight.bold, height: 1),),
                const SizedBox(height: 15),
              ],
            ),
          )
        else if (_mostrarDropdownJuzgadoCondeno)

          Column(
            children: [
              // Primer DropdownButton para seleccionar la ciudad
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey), // Borde gris
                  borderRadius: BorderRadius.circular(4), // Borde redondeado
                  color: Colors.white, // Fondo blanco
                ),
                child: DropdownButton<String>(
                  value: selectedCiudad,
                  hint: const Text('Selecciona una ciudad'),
                  onChanged: (value) {
                    setState(() {
                      selectedCiudad = value;
                      selectedJuzgadoNombre = null;  // Limpiar la selección de juzgado de conocimiento al cambiar la ciudad
                    });
                    _fetchJuzgadosConocimiento(value!);  // Cargar los juzgados de conocimiento
                  },
                  isExpanded: true,  // Hacer que el DropdownButton ocupe el ancho disponible
                  dropdownColor: Colors.white, // Color de fondo del desplegable
                  style: const TextStyle(color: Colors.black), // Color de texto negro
                  items: juzgadoQueCondeno.map((ciudad) {
                    return DropdownMenuItem<String>(
                      value: ciudad['id'],
                      child: Text(
                        ciudad['nombre']!,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),  // Texto en negro
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _mostrarDropdownJuzgadoCondeno = false;
                    _ciudad = widget.doc['ciudad'];
                    _juzgado = widget.doc['juzgado_que_condeno'];
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

              // Agregar espacio entre los dos DropdownButtons
              const SizedBox(height: 20),

              // Segundo DropdownButton para seleccionar el centro de reclusión
              if (selectedCiudad != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey), // Borde gris
                    borderRadius: BorderRadius.circular(4), // Borde redondeado
                    color: Colors.white, // Fondo blanco
                  ),
                  child: DropdownButton<String>(
                    value: selectedJuzgadoNombre, // Cambiar a selectedJuzgadoNombre
                    hint: const Text('Selecciona un juzgado de conocimiento'),
                    onChanged: (value) {
                      setState(() {
                        selectedJuzgadoNombre = value; // Cambiar a selectedJuzgadoNombre
                      });
                    },
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black),
                    items: juzgadosConocimiento.map((juzgados) {
                      return DropdownMenuItem<String>(
                        value: juzgados['nombre'], // Mantener el nombre como valor
                        child: Text(
                          juzgados['nombre']!,
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
          )
        else
          Container(), // Mostrar un contenedor vacío si no se cumplen las condiciones anteriores
      ],
    );
  }

  Widget seleccionarJuzgadoEjecucionPenas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.doc['juzgado_ejecucion_penas'] != null )
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
              ],
            ),
          )
        else
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                ),
                child: DropdownButton<String>(
                  value: selectedJuzgadoEjecucionPenas,
                  hint: const Text('Selecciona un Juzgado de Ejecución de Penas'),
                  onChanged: (value) {
                    setState(() {
                      selectedJuzgadoEjecucionPenas = value;
                    });
                  },
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black),
                  items: juzgadosEjecucionPenas.map((juzgado) {
                    return DropdownMenuItem<String>(
                      value: juzgado['id'],
                      child: Text(
                        juzgado['nombre']!,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                ),
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



  Widget seleccionarDelito() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_delito.isNotEmpty)
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
                      _delito = "";
                    });
                  },
                  child: const Row(
                    children: [
                      Text("Delito", style: TextStyle(fontSize: 11)),
                      Icon(Icons.edit, size: 15),
                    ],
                  ),
                ),
                Text(widget.doc['delito'], style: const TextStyle(fontWeight: FontWeight.bold, height: 1)),
              ],
            ),
          )
        else
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
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
                  items: delito.map((delito) {
                    return DropdownMenuItem<String>(
                      value: delito['delito'],
                      child: Text(
                        delito['delito']!,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                    _delito = widget.doc['delito'];
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
      final String regional = data['regional'];
      final String centroReclusion = data['centro_reclusion'];
      final String juzgadoEjecucionPenas = data['juzgado_ejecucion_penas'];
      final String juzgado = data['juzgado_que_condeno'];
      final String juzgadoQueCondeno = data['ciudad'];
      final String delito = data['delito'];

      setState(() {
        _regional = regional;
        _centroReclusion = centroReclusion;
        _juzgadoEjecucionPenas = juzgadoEjecucionPenas;
        _juzgado = juzgado;
        _juzgadoQueCondeno = juzgadoQueCondeno;
        _delito = delito;
      });
      print("*****Regional: $_regional");
      print("*****centro reclusión: $_centroReclusion");
      print("*****Juzgado de ejecucion de penas es: $_juzgadoEjecucionPenas");
      print("*****La ciudad donde pertenece el juzgado de conocimiento es: $juzgadoQueCondeno");
      print("*****juzgado que condeno fue: $juzgado");
      print("*****el delito es: $delito");


    } else {
      print('El documento no existe');
    }
  }

  Widget datosEjecucionCondena(){
    double screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Condena transcurrida',
              style: TextStyle(fontSize: screenWidth > 600 ? 16 : 12,
                  color: negroLetras),
              textAlign: TextAlign.center,
            ),
            const SizedBox(width: 10),
            Text(
              mesesEjecutado == 1
                  ? diasEjecutadoExactos == 1
                  ? '$mesesEjecutado mes : $diasEjecutadoExactos día'
                  : '$mesesEjecutado mes : $diasEjecutadoExactos días'
                  : diasEjecutadoExactos == 1
                  ? '$mesesEjecutado meses : $diasEjecutadoExactos día'
                  : '$mesesEjecutado meses : $diasEjecutadoExactos días',
              style: TextStyle(fontSize: screenWidth > 600 ? 14 : 12, fontWeight: FontWeight.bold),
            )
          ],
        ),
        Row(
          children: [
            Text(
              'Condena restante',
              style: TextStyle(fontSize: screenWidth > 600 ? 16 : 12,
                  color: negroLetras),
              textAlign: TextAlign.center,
            ),
            const SizedBox(width: 10),
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
              style: TextStyle(fontSize: screenWidth > 600 ? 14 : 12, fontWeight: FontWeight.bold),
            )
          ],
        ),
        Row(
          children: [
            Text(
              'Porcentaje ejecutado',
              style: TextStyle(fontSize: screenWidth > 600 ? 14 : 12, color: negroLetras),
            ),
            const SizedBox(width: 10),
            Text(
              '${porcentajeEjecutado.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: screenWidth > 600 ? 14 : 12, fontWeight: FontWeight.bold),
            ),
          ],
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
    );
  }

  Widget botonGuardar(){
    return Container(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: primary,
        ),
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            int tiempoCondena = int.parse(_tiempoCondenaController.text);
            // Oculta el teclado
            SystemChannels.textInput.invokeMethod('TextInput.hide');
            // Actualiza el documento en Firestore
            widget.doc.reference.update({
              'nombre_ppl': _nombreController.text,
              'apellido_ppl': _apellidoController.text,
              'numero_documento_ppl': _numeroDocumentoController.text,
              'tipo_documento_ppl': _tipoDocumento,
              'centro_reclusion': selectedCentro ?? widget.doc['centro_reclusion'],
              'regional': selectedRegional ?? widget.doc['regional'],
              'ciudad': selectedCiudad ?? widget.doc['ciudad'],
              'juzgado_que_condeno': selectedJuzgadoNombre ?? widget.doc['juzgado_que_condeno'].toString(),
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
            }).then((_) {
              // Muestra un snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Datos guardados con éxito'),
                  duration: Duration(seconds: 2),
                ),
              );
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.red,
                content: Text(
                  'Hay información que aún no se ha llenado',
                  style: TextStyle(color: Colors.white),
                ),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        child: const Text('Guardar Cambios'),
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
}