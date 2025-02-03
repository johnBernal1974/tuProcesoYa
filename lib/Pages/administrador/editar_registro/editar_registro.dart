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
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _numeroDocumentoController = TextEditingController();
  final _radicadoController = TextEditingController();
  final _tiempoCondenaController = TextEditingController();
  final _fechaDeCapturaController = TextEditingController();
  final _tdController = TextEditingController();
  final _nuiController = TextEditingController();
  final _patioController = TextEditingController();

  List<Map<String, dynamic>> regionales = [];
  List<Map<String, dynamic>> centrosReclusion = [];
  List<Map<String, dynamic>> juzgadosEjecucionPenas = [];
  List<Map<String, dynamic>> juzgadoQueCondeno = [];
  List<Map<String, dynamic>> delito = [];

  String? selectedRegional; // Regional seleccionada
  String? selectedCentro; // Centro de reclusión seleccionado
  String? selectedJuzgadoEjecucionPenas;
  String? selectedJuzgadoCondeno;
  String? selectedDelito;

  String _regional = "";
  String _centroReclusion = "";
  String _juzgadoEjecucionPenas= "";
  String _juzgadoQueCondeno= "";
  String _delito= "";
  bool _mostrarDropdowns = true;
  bool _mostrarDropdownJuzgadoEjecucion = false;
  bool _mostrarDropdownJuzgadoCondeno = false;
  bool _mostrarDropdownDelito = false;
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

  final List<String> _opciones = [
    'Cédula de Ciudadanía',
    'Pasaporte',
  ];

  @override
  void initState() {
    super.initState();
    _calculoCondenaController.calcularTiempo(widget.doc.id).then((_) {
      mesesRestante = _calculoCondenaController.mesesRestante!;
      diasRestanteExactos= _calculoCondenaController.diasRestanteExactos!;
      mesesEjecutado= _calculoCondenaController.mesesEjecutado!;
      diasEjecutadoExactos= _calculoCondenaController.diasEjecutadoExactos!;
      porcentajeEjecutado = _calculoCondenaController.porcentajeEjecutado!;
    });
    _fetchRegionales();
    _obtenerDatos();
    _fetchDelitos();
    if (widget.doc != null) {
      _nombreController.text = widget.doc.get('nombre_ppl');
      _apellidoController.text = widget.doc.get('apellido_ppl');
      _numeroDocumentoController.text =
          widget.doc.get('numero_documento_ppl').toString();
      _tipoDocumento = widget.doc.get('tipo_documento_ppl');
      _radicadoController.text = widget.doc.get('radicado');
      _tiempoCondenaController.text = widget.doc.get('tiempo_condena').toString();
      _fechaDeCapturaController.text = widget.doc.get('fecha_captura');
      _tdController.text = widget.doc.get('td');
      _nuiController.text = widget.doc.get('nui');
      _patioController.text = widget.doc.get('patio');
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
            // Puedes mostrar el id en pantalla si lo deseas
            // Text('ID del documento: ${widget.doc.id}'),
            const SizedBox(height: 20),
            datosEjecucionCondena(),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nombreController,
              style: const TextStyle(fontWeight: FontWeight.bold, height: 1),
              decoration: InputDecoration(
                labelText: 'Nombre',
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _apellidoController,
              style: const TextStyle(fontWeight: FontWeight.bold, height: 1),
              decoration: InputDecoration(
                labelText: 'Apellido',
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su apellido';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField(
              value: _tipoDocumento,
              onChanged: (String? newValue) {
                setState(() {
                  _tipoDocumento = newValue!;
                });
              },
              items: _opciones.map((String option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option),
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
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _numeroDocumentoController,
              style: const TextStyle(fontWeight: FontWeight.bold, height: 1),
              decoration: InputDecoration(
                labelText: 'Número de Documento',
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su número de documento';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            seleccionarCentroReclusion(),
            const SizedBox(height: 15),
            seleccionarJuzgadoEjecucionPenas(),
            const SizedBox(height: 15),
            seleccionarJuzgadoQueCondeno(),
            const SizedBox(height: 15),
            seleccionarDelito(),
            const SizedBox(height: 15),
            TextFormField(
              controller: _fechaDeCapturaController,
              style: const TextStyle(fontWeight: FontWeight.bold, height: 1),
              decoration: InputDecoration(
                labelText: 'Fecha de captura YYYY-MM-DD',
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese la fecha de captura';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _radicadoController,
              style: const TextStyle(fontWeight: FontWeight.bold, height: 1),
              decoration: InputDecoration(
                labelText: 'Radicado No',
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el número de radicado';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _tiempoCondenaController,
              style: const TextStyle(fontWeight: FontWeight.bold, height: 1),
              decoration: InputDecoration(
                labelText: 'Tiempo de condena en meses',
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el tiempo de condena en meses';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _tdController,
              style: const TextStyle(fontWeight: FontWeight.bold, height: 1),
              decoration: InputDecoration(
                labelText: 'TD',
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el TD';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _nuiController,
              style: const TextStyle(fontWeight: FontWeight.bold, height: 1),
              decoration: InputDecoration(
                labelText: 'NUI',
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el NUI';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _patioController,
              style: const TextStyle(fontWeight: FontWeight.bold, height: 1),
              decoration: InputDecoration(
                labelText: 'Número de patio',
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el patio';
                }
                return null;
              },
            ),
            const SizedBox(height: 50),
            ElevatedButton(
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
                    'delito': selectedDelito ?? widget.doc['delito'],
                    'radicado': _radicadoController.text,
                    'tiempo_condena': tiempoCondena,
                    'fecha_captura': _fechaDeCapturaController.text,
                    'td': _tdController.text,
                    'nui': _nuiController.text,
                    'patio': _patioController.text,
                  }).then((_) {
                    // Muestra un snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Datos guardados con éxito'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  });
                }
              },
              child: const Text('Guardar Cambios'),
            ),
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

  Widget seleccionarCentroReclusion(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_regional != "" && _centroReclusion != "")
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _mostrarDropdowns = true;
                    _regional = "";
                    _centroReclusion = "";
                  });
                },
                child: const Row(
                  children: [
                    Text("Regional", style: TextStyle(fontSize: 11)),
                    Icon(Icons.edit, size: 15),
                  ],
                ),
              ),
              Text(widget.doc['regional'], style: const TextStyle(fontWeight: FontWeight.bold, height: 1)),
              const SizedBox(height: 15),
              const Text("Centro de reclusión", style: TextStyle(fontSize: 11)),
              Text(widget.doc['centro_reclusion'], style: const TextStyle(fontWeight: FontWeight.bold, height: 1),),
              const SizedBox(height: 15),
            ],
          )
        else if (_mostrarDropdowns)

          Column(
            children: [
              // Primer DropdownButton para seleccionar la regional
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey), // Borde gris
                  borderRadius: BorderRadius.circular(4), // Borde redondeado
                  color: Colors.white, // Fondo blanco
                ),
                child: DropdownButton<String>(
                  value: selectedRegional,
                  hint: const Text('Selecciona una regional'),
                  onChanged: (value) {
                    setState(() {
                      selectedRegional = value;
                      selectedCentro = null;  // Limpiar la selección de centro cuando cambie la regional
                    });
                    _fetchCentrosReclusion(value!);  // Cargar los centros de reclusión
                  },
                  isExpanded: true,  // Hacer que el DropdownButton ocupe el ancho disponible
                  dropdownColor: Colors.white, // Color de fondo del desplegable
                  style: const TextStyle(color: Colors.black), // Color de texto negro
                  items: regionales.map((regional) {
                    return DropdownMenuItem<String>(
                      value: regional['id'],
                      child: Text(
                        regional['nombre']!,
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
                    _mostrarDropdowns = false;
                    _regional = widget.doc['regional'];
                    _centroReclusion = widget.doc['centro_reclusion'];
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
              if (selectedRegional != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey), // Borde gris
                    borderRadius: BorderRadius.circular(4), // Borde redondeado
                    color: Colors.white, // Fondo blanco
                  ),
                  child: DropdownButton<String>(
                    value: selectedCentro,
                    hint: const Text('Selecciona un centro de reclusión'),
                    onChanged: (value) {
                      setState(() {
                        selectedCentro = value;
                      });
                    },
                    isExpanded: true,  // Hacer que el DropdownButton ocupe el ancho disponible
                    dropdownColor: Colors.white, // Color de fondo del desplegable
                    style: const TextStyle(color: Colors.black), // Color de texto negro
                    items: centrosReclusion.map((centro) {
                      return DropdownMenuItem<String>(
                        value: centro['id'],
                        child: Text(
                          centro['nombre']!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,  // Texto en negro
                          ),
                          maxLines: 3,  // Permitir hasta 3 líneas de texto
                          overflow: TextOverflow.ellipsis,
                          // Asegurarse de que el texto no se desborde
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

  Widget seleccionarJuzgadoEjecucionPenas(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_juzgadoEjecucionPenas.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _mostrarDropdownJuzgadoEjecucion = true;
                    _juzgadoEjecucionPenas = "";
                  });
                },
                child: const Row(
                  children: [
                    Text("Juzgado de Ejecución de Penas", style: TextStyle(fontSize: 11)),
                    Icon(Icons.edit, size: 15),
                  ],
                ),
              ),
              Text(widget.doc['juzgado_ejecucion_penas'], style: const TextStyle(fontWeight: FontWeight.bold, height: 1)),
              const SizedBox(height: 10),
            ],
          )
        else if (_mostrarDropdownJuzgadoEjecucion)
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(8),
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
                    _juzgadoEjecucionPenas = widget.doc['juzgado_ejecucion_penas'];
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
          )
        else
          Container(),
      ],
    );
  }

  Widget seleccionarJuzgadoQueCondeno(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_juzgadoQueCondeno.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _mostrarDropdownJuzgadoCondeno = true;
                    _juzgadoQueCondeno = "";
                  });
                },
                child: const Row(
                  children: [
                    Text("Juzgado que condenó", style: TextStyle(fontSize: 11)),
                    Icon(Icons.edit, size: 15),
                  ],
                ),
              ),
              Text(widget.doc['juzgado_que_condeno'], style: const TextStyle(fontWeight: FontWeight.bold, height: 1)),
              const SizedBox(height: 10),
            ],
          )
        else if (_mostrarDropdownJuzgadoCondeno)
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
                  value: selectedJuzgadoCondeno,
                  hint: const Text('Selecciona el juzgado que condenó'),
                  onChanged: (value) {
                    setState(() {
                      selectedJuzgadoCondeno = value;
                    });
                  },
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black),
                  items: juzgadoQueCondeno.map((juzgado) {
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
                    _mostrarDropdownJuzgadoCondeno = false;
                    _juzgadoQueCondeno = widget.doc['juzgado_que_condeno'];
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
          )
        else
          Container(),
      ],
    );
  }

  Widget seleccionarDelito() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_delito.isNotEmpty)
          Column(
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
      final String juzgadoQueCondeno = data['juzgado_que_condeno'];
      final String delito = data['delito'];

      setState(() {
        _regional = regional;
        _centroReclusion = centroReclusion;
        _juzgadoEjecucionPenas = juzgadoEjecucionPenas;
        _juzgadoQueCondeno = juzgadoQueCondeno;
        _delito = delito;
      });
      print("*****Regional: $_regional y centro reclusión: $_centroReclusion, el Juzgado de ejecucion de penas es: "
          "$_juzgadoEjecucionPenas y el juzgado que condeno fue: $_juzgadoQueCondeno y el delito es: $delito");
    } else {
      print('El documento no existe');
    }
  }

  Widget datosEjecucionCondena(){
    double screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Condena transcurrida',
              style: TextStyle(fontSize: screenWidth > 600 ? 16 : 12,
                  color: negroLetras),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Condena restante',
              style: TextStyle(fontSize: screenWidth > 600 ? 16 : 12,
                  color: negroLetras),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Porcentaje ejecutado',
              style: TextStyle(fontSize: screenWidth > 600 ? 14 : 12, color: negroLetras),
            ),
            Text(
              '${porcentajeEjecutado.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: screenWidth > 600 ? 14 : 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}