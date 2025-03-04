import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tuprocesoya/models/ppl.dart';
import 'package:tuprocesoya/providers/ppl_provider.dart';
import 'package:tuprocesoya/src/colors/colors.dart';

import '../../../providers/auth_provider.dart';
import '../estamos_validando/estamos_validando.dart';

class RegistroPage extends StatefulWidget {

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
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmarController = TextEditingController();
  TextEditingController _centroReclusionController = TextEditingController(); // Controlador del campo de texto
  DateTime? fechaCaptura;

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

  String? selectedRegional; // Regional seleccionada
  String? selectedCentro; // Centro de reclusión seleccionado

  late MyAuthProvider _authProvider;
  late PplProvider _pplProvider;
  bool _mostrarDropdowns = false;

  // Listas de opciones para los Dropdowns
  List<Map<String, dynamic>> regionales = [];
  List<Map<String, Object>> centrosReclusionTodos = [];
  final List<String> parentescoOptions = ['Padre', 'Madre', 'Hermano/a', "Hijo/a", "Esposo/a", "Amigo/a", "Tio/a", "Sobrino/a", "Nieto/a", "Abuelo/a",'Abogado/a', 'Tutor/a', 'Otro'];
  final List<String> tipoDocumentoOptions = ['Cédula de Ciudadanía', 'Pasaporte', 'Tarjeta de Identidad'];
  final List<String> laborDescuentoOptions = ['Limpieza de celdas', 'Cocina', 'Trabajo en el taller de carpintería', 'Trabajo en el taller de costura', 'Servicio en biblioteca', 'Trabajo agrícola', 'Reparación de vehículos', 'Enseñanza en oficios', 'Asistencia en la zona de salud', 'Trabajo en el área de jardinería'];

  @override
  void initState() {
    super.initState();
    _authProvider = MyAuthProvider();
    _pplProvider = PplProvider();
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
                        child: Row(
                          mainAxisAlignment:MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("¡Información Importante!", style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 24
                            ),),
                            Image.asset(
                              'assets/images/logo_tu_proceso_ya.png',
                              width: 100,
                              height: 100,
                            ),
                          ],
                        ),
                      ),
                    ),
                    RichText(
                      textAlign: TextAlign.justify,
                      text: const TextSpan(
                        style: TextStyle(fontSize: 14, height: 1.2, color: Colors.black),
                        children: [
                          TextSpan(text: "Por favor, asegúrate de ingresar todos los datos de manera "),
                          TextSpan(text: "completa", style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: ", "),
                          TextSpan(text: "correcta", style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: " y "),
                          TextSpan(text: "veraz", style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: ". La precisión de la información es fundamental para que la plataforma pueda gestionar de manera efectiva las diligencias necesarias para la persona privada de la libertad (PPL). Cualquier error en los datos puede afectar los procesos y retrasar la asistencia que necesita. ¡Tu colaboración es clave para un servicio ágil y eficiente!"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text("Datos del acudiente.", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const Text("Es la persona que solicitará los servicios en nombre de la persona privada de la libertad .", style: TextStyle(fontSize: 13,
                        height: 1.1)),
                    _buildTextFormField(controller: nombreAcudienteController, label: 'Nombres del Acudiente', textCapitalization: TextCapitalization.words ),
                    _buildTextFormField(controller: apellidoAcudienteController, label: 'Apellidos del Acudiente', textCapitalization: TextCapitalization.words),

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
                    _buildTextFormField(controller: nombrePplController, label: 'Nombres del PPL', textCapitalization: TextCapitalization.words),
                    _buildTextFormField(controller: apellidoPplController, label: 'Apellidos del PPL', textCapitalization: TextCapitalization.words),

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
                    //seleccionarCentroReclusion(),

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
                      width: 250,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Guardar Registro'),
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
        try {
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
            //regional: selectedRegional ?? regionalController.text.trim(),
            regional: "",
            //centroReclusion: selectedCentro ?? centroReclusionController.text.trim(),
            centroReclusion: "",
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
            fechaCaptura: null,
            status: "registrado",
            isNotificatedActivated: false,
            isPaid: false,
            assignedTo: "",
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
        } on FirebaseAuthException catch (e) {
          Navigator.of(context).pop(); // Cerrar el indicador de carga
          print('Error en FirebaseAuth: ${e.code}');
          _mostrarMensaje(_traducirErrorFirebase(e.code));
        }
      }
    } catch (e) {
      Navigator.of(context).pop();
      print('Error en el proceso de registro: $e');
      _mostrarMensaje('Error al registrar el usuario: $e');
    }
  }

  /// Método para traducir los códigos de error de Firebase al español
  String _traducirErrorFirebase(String errorCode) {
    switch (errorCode) {
      case "email-already-in-use":
        return "El correo electrónico ya está registrado.";
      case "invalid-email":
        return "El formato del correo electrónico no es válido.";
      case "operation-not-allowed":
        return "El registro de nuevos usuarios está deshabilitado.";
      case "weak-password":
        return "La contraseña es demasiado débil. Intenta con una más segura.";
      case "user-disabled":
        return "Tu cuenta ha sido deshabilitada. Contacta al soporte.";
      case "too-many-requests":
        return "Has realizado demasiados intentos. Intenta de nuevo más tarde.";
      case "network-request-failed":
        return "Error de conexión. Revisa tu internet e intenta nuevamente.";
      default:
        return "Se ha producido un error desconocido. Inténtalo de nuevo.";
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
    fechaCaptura = null;
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

  // Widget seleccionarCentroReclusion() {
  //   if (centrosReclusionTodos.isEmpty) {
  //     Future.microtask(() => _fetchTodosCentrosReclusion());
  //   }
  //
  //   return Container(
  //     padding: const EdgeInsets.all(8),
  //     decoration: BoxDecoration(
  //       border: Border.all(color: primary),
  //       borderRadius: BorderRadius.circular(4),
  //       color: Colors.white,
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           "Buscar centro de reclusión (Escribe el nombre y selecciónalo)",
  //           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
  //         ),
  //         const SizedBox(height: 8),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: Autocomplete<Map<String, String>>(
  //                 optionsBuilder: (TextEditingValue textEditingValue) {
  //                   if (textEditingValue.text.isEmpty) {
  //                     return const Iterable<Map<String, String>>.empty();
  //                   }
  //                   return centrosReclusionTodos
  //                       .map((option) => option.map((key, value) => MapEntry(key, value.toString())))
  //                       .where((Map<String, String> option) =>
  //                       option['nombre']!.toLowerCase().contains(textEditingValue.text.toLowerCase()));
  //                 },
  //                 displayStringForOption: (Map<String, String> option) => option['nombre']!,
  //                 fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
  //                   _centroReclusionController = textEditingController; // Guardamos el controlador
  //                   return TextField(
  //                     controller: _centroReclusionController,
  //                     focusNode: focusNode,
  //                     decoration: InputDecoration(
  //                       hintText: "Busca ingresando la ciudad",
  //                       labelText: "Centro de reclusión",
  //                       border: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(10),
  //                         borderSide: const BorderSide(color: Colors.grey, width: 1),
  //                       ),
  //                       focusedBorder: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(10),
  //                         borderSide: const BorderSide(color: Colors.grey, width: 1),
  //                       ),
  //                       enabledBorder: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(10),
  //                         borderSide: const BorderSide(color: Colors.grey, width: 1),
  //                       ),
  //                       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
  //                     ),
  //                   );
  //                 },
  //                 optionsViewBuilder: (context, onSelected, options) {
  //                   if (options.isEmpty) {
  //                     return Material(
  //                       elevation: 4.0,
  //                       child: Container(
  //                         padding: const EdgeInsets.all(8.0),
  //                         child: const Text("No se encontraron centros"),
  //                       ),
  //                     );
  //                   }
  //                   return Align(
  //                     alignment: Alignment.topLeft,
  //                     child: Material(
  //                       elevation: 4.0,
  //                       child: Container(
  //                         padding: const EdgeInsets.all(8.0),
  //                         color: blancoCards,
  //                         child: ListView.builder(
  //                           padding: EdgeInsets.zero,
  //                           shrinkWrap: true,
  //                           itemCount: options.length,
  //                           itemBuilder: (context, index) {
  //                             final Map<String, String> option = options.elementAt(index);
  //                             return ListTile(
  //                               title: Text(option['nombre']!),
  //                               onTap: () {
  //                                 onSelected(option);
  //                               },
  //                             );
  //                           },
  //                         ),
  //                       ),
  //                     ),
  //                   );
  //                 },
  //                 onSelected: (Map<String, String> selection) {
  //                   setState(() {
  //                     selectedCentro = selection['id'];
  //                     selectedRegional = selection['regional'];
  //                   });
  //                   debugPrint("Centro seleccionado: ${selection['nombre']}");
  //                   debugPrint("Regional asociada: ${selection['regional']}");
  //                 },
  //               ),
  //             ),
  //             if (selectedCentro != null) // Solo mostrar el icono si hay un centro seleccionado
  //               IconButton(
  //                 icon: const Icon(Icons.clear, color: Colors.red),
  //                 onPressed: () {
  //                   setState(() {
  //                     selectedCentro = null;
  //                     selectedRegional = null;
  //                     _centroReclusionController.clear(); // 🔥 Limpia el texto del Autocomplete
  //                   });
  //                   debugPrint("Selección de centro de reclusión eliminada.");
  //                 },
  //               ),
  //           ],
  //         ),
  //         const SizedBox(height: 10),
  //         if (selectedCentro != null)
  //           Text(
  //             "Centro seleccionado: ${centrosReclusionTodos.firstWhere(
  //                   (centro) => centro['id'] == selectedCentro,
  //               orElse: () => <String, String>{},
  //             )['nombre']!}",
  //             style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
  //           ),
  //         const SizedBox(height: 10),
  //       ],
  //     ),
  //   );
  // }

}
