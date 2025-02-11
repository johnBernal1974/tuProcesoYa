import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/models/ppl.dart';
import 'package:tuprocesoya/providers/ppl_provider.dart';
import 'package:tuprocesoya/src/colors/colors.dart';

import '../../../providers/auth_provider.dart';
import '../estamos_validando/estamos_validando.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  _RegistroPageState createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de los campos
  final TextEditingController nombreAcudienteController = TextEditingController();
  final TextEditingController apellidoAcudienteController = TextEditingController();
  final TextEditingController parentescoRepresentanteController = TextEditingController();
  final TextEditingController celularController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController emailConfirmarController = TextEditingController();
  final TextEditingController nombrePplController = TextEditingController();
  final TextEditingController apellidoPplController = TextEditingController();
  final TextEditingController tipoDocumentoPplController = TextEditingController();
  final TextEditingController numeroDocumentoPplController = TextEditingController();
  final TextEditingController regionalController = TextEditingController();
  final TextEditingController centroReclusionController = TextEditingController();
  final TextEditingController juzgadoEjecucionPenasController = TextEditingController();
  final TextEditingController juzgadoQueCondenoController = TextEditingController();
  final TextEditingController delitoController = TextEditingController();
  final TextEditingController radicadoController = TextEditingController();
  final TextEditingController tiempoCondenaController = TextEditingController();
  final TextEditingController tdController = TextEditingController();
  final TextEditingController nuiController = TextEditingController();
  final TextEditingController patioController = TextEditingController();
  final TextEditingController fechaCapturaController = TextEditingController();
  final TextEditingController fechaInicioDescuentoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmarController = TextEditingController();
  DateTime? fechaCaptura;
  DateTime? fechaInicioDescuento;
  final TextEditingController laborDescuentoController = TextEditingController();

  // Variables para los Dropdowns
  String? parentesco;
  String? tipoDocumento;
  String? regional;
  String? centroReclusion;
  String? juzgadoEjecucionPenas;
  String? juzgadoQueCondeno;
  String? delito;
  String? laborDescuento;
  String? _errorFechaCaptura;
  String? _errorFechaInicioDescuento;

  String? selectedRegional; // Regional seleccionada
  String? selectedCentro; // Centro de reclusión seleccionado

  late MyAuthProvider _authProvider;
  late PplProvider _pplProvider;

  // Listas de opciones para los Dropdowns
  List<Map<String, dynamic>> regionales = [];
  List<Map<String, dynamic>> centrosReclusion = [];
  final List<String> parentescoOptions = ['Padre', 'Madre', 'Hermano/a', "Hijo/a", "Esposo/a", "Amigo/a", "Tio/a", "Sobrino/a", "Nieto/a", "Abuelo/a",'Abogado/a', 'Tutor/a', 'Otro'];
  final List<String> tipoDocumentoOptions = ['Cédula de Ciudadanía', 'Pasaporte', 'Tarjeta de Identidad'];
  final List<String> laborDescuentoOptions = ['Limpieza de celdas', 'Cocina', 'Trabajo en el taller de carpintería', 'Trabajo en el taller de costura', 'Servicio en biblioteca', 'Trabajo agrícola', 'Reparación de vehículos', 'Enseñanza en oficios', 'Asistencia en la zona de salud', 'Trabajo en el área de jardinería'];

  @override
  void initState() {
    super.initState();
    _authProvider = MyAuthProvider();
    _pplProvider = PplProvider();
    _fetchRegionales();
  }


// Método auxiliar para convertir el texto del controlador a DateTime
  DateTime? _parseFecha(String fecha) {
    try {
      // Define el formato esperado para la entrada
      final formato = DateFormat('d/M/yyyy');
      return formato.parse(fecha);
    } catch (e) {
      print('Error al parsear fecha "$fecha": $e');
      return null;
    }
  }



  Future<void> signUp() async {
    try {
      if (_formKey.currentState!.validate()) {
        print('Formulario válido, mostrando el indicador de carga...');
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        String email = emailController.text.trim();
        String password = passwordController.text.trim();
        String confirmPassword = passwordConfirmarController.text.trim();
        String confirmEmail = emailConfirmarController.text.trim();

        // Validaciones adicionales
        if (email != confirmEmail) {
          Navigator.of(context).pop();
          _mostrarMensaje('Los correos electrónicos no coinciden.');
          return;
        }

        if (password != confirmPassword) {
          Navigator.of(context).pop();
          _mostrarMensaje('Las contraseñas no coinciden.');
          return;
        }

        if (password.length < 6) {
          Navigator.of(context).pop();
          _mostrarMensaje('La contraseña debe tener al menos 6 caracteres.');
          return;
        }

        print('Intentando registrar el usuario...');
        bool isSignUp = await _authProvider.signUp(email, password);
        print('Registro exitoso: $isSignUp');

        if (!isSignUp) {
          throw Exception('El registro del usuario falló. Por favor, inténtalo de nuevo.');
        }

        Ppl ppl = Ppl(
          id: _authProvider.getUser()!.uid,
          nombreAcudiente: nombreAcudienteController.text.trim(),
          apellidoAcudiente: apellidoAcudienteController.text.trim(),
          parentescoRepresentante: parentesco ?? "",
          celular: celularController.text.trim(),
          email: emailController.text.trim(),
          nombrePpl: nombrePplController.text.trim(),
          apellidoPpl: apellidoPplController.text.trim(),
          tipoDocumentoPpl: tipoDocumento ?? "",
          numeroDocumentoPpl: numeroDocumentoPplController.text.trim(),
          regional: selectedRegional ?? regionalController.text.trim(),
          centroReclusion: selectedCentro ?? centroReclusionController.text.trim(),
          juzgadoEjecucionPenas: "",
          juzgadoEjecucionPenasEmail: "",
          ciudad: "",
          juzgadoQueCondeno: "",
          juzgadoQueCondenoEmail: "",
          delito: "",
          radicado: "",
          tiempoCondena: 0,
          td: tdController.text.trim(),
          nui: nuiController.text.trim(),
          patio: patioController.text.trim(),
          laborDescuento: "",
          fechaCaptura: null,
          fechaInicioDescuento: null,
          status: "registrado"
        );

        print('Guardando usuario en Firestore...');
        await _pplProvider.create(ppl);
        print('Usuario guardado exitosamente.');

        Navigator.of(context).pop(); // Cerrar el indicador de carga
        _mostrarMensaje('Usuario registrado correctamente.');

        _formKey.currentState!.reset();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => EstamosValidandoPage()),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      print('Error en el proceso de registro: $e');
      _mostrarMensaje('Error al registrar el usuario: $e');
    }
  }


// Método auxiliar para mostrar mensajes
  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }


// Método para limpiar los controladores de texto
  void _limpiarControladores() {
    nombreAcudienteController.clear();
    apellidoAcudienteController.clear();
    parentesco = null;
    celularController.clear();
    emailController.clear();
    nombrePplController.clear();
    apellidoPplController.clear();
    tipoDocumento = null;
    numeroDocumentoPplController.clear();
    centroReclusionController.clear();
    juzgadoEjecucionPenas = null;
    juzgadoQueCondeno = null;
    delito = null;
    radicadoController.clear();
    tiempoCondenaController.clear();
    tdController.clear();
    nuiController.clear();
    patioController.clear();
    laborDescuento = null;
    fechaCaptura = null;
    fechaInicioDescuento = null;
  }

  // Método para crear un TextFormField con diseño común
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none, // Agregado para especificar la capitalización
    String? Function(String?)? validator, // Se permite la validación personalizada
    bool isError = false,
    bool obscureText = false,// Indica si hay un error
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        obscureText: obscureText,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isError ? Colors.red : Colors.black, // Color de la etiqueta si hay error
          ),
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey), // Borde gris cuando no tiene error
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.deepPurple), // Borde morado cuando está enfocado
          ),
          errorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red), // Borde rojo cuando hay error
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red), // Borde rojo cuando está enfocado y con error
          ),
        ),
        validator: validator ??
                (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              return null;
            },
      ),
    );
  }


  // Método para crear un DropdownButtonFormField
  Widget _buildDropdown({
    required String? value,
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey), // Borde gris
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.deepPurple), // Borde color primary
          ),
        ),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Este campo es obligatorio';
          }
          return null;
        },
        items: items
            .map((item) => DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            maxLines: 3, // Permite 3 líneas para el texto
            overflow: TextOverflow.ellipsis, // Puntos suspensivos si el texto es muy largo
            softWrap: true, // Permite que el texto se ajuste en varias líneas
          ),
        ))
            .toList(),
        style: const TextStyle(
          fontSize: 13, // Tamaño de la letra del texto seleccionado
          color: Colors.black,
          fontWeight: FontWeight.bold, // Color del texto seleccionado
        ),
        dropdownColor: Colors.white, // Color de fondo del desplegable
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

      // Si hay regionales, seleccionar la primera y obtener los centros de reclusión
      if (regionales.isNotEmpty) {
        // Asegurarse de que selectedRegional no sea nulo antes de usarlo
        if (selectedRegional != null) {
          _fetchCentrosReclusion(selectedRegional!);  // Obtener los centros de reclusión para la regional seleccionada
        } else {
          print('No se ha seleccionado ninguna regional');
        }
      }
    } catch (e) {
      print("Error al obtener las regionales: $e");
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

      // if (centrosReclusion.isNotEmpty) {
      //   selectedCentro = centrosReclusion.first['id'];  // Seleccionamos el primer centro por defecto
      // }
    } catch (e) {
      print("Error al obtener los centros de reclusión: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white, size: 30),
        title: const Text('Registro', style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 600, // Limitar el ancho en pantallas grandes
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        child: Image.asset(
                          'assets/images/logo_tu_proceso_ya.png',
                          width: 140,
                          height: 140,
                        ),
                      ),
                    ),
                    const Text("Para garantizar que la plataforma funcione de manera óptima..."),
                    const SizedBox(height: 30),
                    const Text("Datos del acudiente.", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    _buildTextFormField(controller: nombreAcudienteController, label: 'Nombre Acudiente', textCapitalization: TextCapitalization.words ),
                    _buildTextFormField(controller: apellidoAcudienteController, label: 'Apellido Acudiente', textCapitalization: TextCapitalization.words),

                    // Aseguramos que el Dropdown no se desborde
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: _buildDropdown(
                        value: parentesco,
                        label: 'Parentesco del acudiente',
                        items: parentescoOptions,
                        onChanged: (value) {
                          setState(() {
                            parentesco = value;
                          });
                        },
                      ),
                    ),

                    const Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.amber, size: 30), // Icono amarillo de atención
                        SizedBox(width: 10), // Espacio entre el icono y el texto
                        Expanded( // Asegura que el texto se adapte al ancho disponible
                          child: Text("Por favor ingresa un número de celular activo y que tenga cuenta de WhatsApp, ya que por "
                              "este medio también podemos enviarte información relevante.", style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    _buildTextFormField(controller: celularController, label: 'Celular', keyboardType: TextInputType.phone),
                    const SizedBox(height: 30),
                    const Text("Datos de la persona privada de la libertad.", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    _buildTextFormField(controller: nombrePplController, label: 'Nombre PPL', textCapitalization: TextCapitalization.words),
                    _buildTextFormField(controller: apellidoPplController, label: 'Apellido PPL', textCapitalization: TextCapitalization.words),

                    // Otros Dropdowns
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: _buildDropdown(
                        value: tipoDocumento,
                        label: 'Tipo de Documento',
                        items: tipoDocumentoOptions,
                        onChanged: (value) {
                          setState(() {
                            tipoDocumento = value;
                          });
                        },
                      ),
                    ),
                    _buildTextFormField(controller: numeroDocumentoPplController, label: 'Número de Documento'),
                    const SizedBox(height: 15),
                    const Divider(height: 2, color: primary),
                    const SizedBox(height: 15),
                    const Text("Lugar de reclusión", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                    ),
                    _buildTextFormField(controller: tdController, label: 'TD', keyboardType: TextInputType.number),
                    _buildTextFormField(controller: nuiController, label: 'NUI', keyboardType: TextInputType.number),
                    _buildTextFormField(controller: patioController, label: 'Patio'),
                    const SizedBox(height: 15),
                    const Divider(height: 2, color: primary),
                    const SizedBox(height: 15),
                    const Text("Creacion de cuenta", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.amber, size: 30), // Icono amarillo de atención
                        SizedBox(width: 10), // Espacio entre el icono y el texto
                        Expanded( // Asegura que el texto se adapte al ancho disponible
                          child: Text("Por favor ingresa un correo electrónico válido, que esté activo y al cual tengas acceso, ya que allí "
                              "se te estará enviando toda la información relacionada con el PPL", style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    _buildTextFormField(controller: emailController, label: 'Tu Email', keyboardType: TextInputType.emailAddress),
                    _buildTextFormField(controller: emailConfirmarController, label: 'Confirmar Email', keyboardType: TextInputType.emailAddress),
                    const Row(
                      children: [
                        Icon(Icons.info, color: Colors.amber, size: 30), // Icono amarillo de atención
                        SizedBox(width: 10), // Espacio entre el icono y el texto
                        Expanded( // Asegura que el texto se adapte al ancho disponible
                          child: Text("Ten en cuenta que la contraseña que vas a crear debe tener mínimo 6 carácteres. Por la seguridad de tus datos no la compartas con nadie", style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    _buildTextFormField(controller: passwordController, label: 'Crea una contraseña', keyboardType: TextInputType.visiblePassword, obscureText: true ),
                    _buildTextFormField(controller: passwordConfirmarController, label: 'Confirmar Contraseña', keyboardType: TextInputType.visiblePassword, obscureText: true),
                    const SizedBox(height: 50),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Enviar Formulario'),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}
