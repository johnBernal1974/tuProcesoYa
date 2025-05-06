
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:tuprocesoya/src/colors/colors.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import '../../../commons/drop_depatamentos_municipios.dart';
import '../../administrador/terminos_y_condiciones/terminos_y_condiciones.dart';
import '../estamos_validando/estamos_validando.dart';
import 'dart:html' as html;


class RegistroPage extends StatefulWidget {
  final DocumentSnapshot? doc; // 🔥 Agregar el parámetro opcional `doc`

  RegistroPage({super.key, this.doc});

  @override
  _RegistroPageState createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final PageController _pageController = PageController();
  final _formKeyAcudiente = GlobalKey<FormState>();
  final _formKeyTerminosYCondiciones = GlobalKey<FormState>();
  final _formKeyCelularAcudiente = GlobalKey<FormState>();
  final _formKeyParentescoAcudiente = GlobalKey<FormState>();
  final _formKeyNombresPPL = GlobalKey<FormState>();
  final _formKeyDocumentoPPL = GlobalKey<FormState>();
  final _formKeySituacionPPL = GlobalKey<FormState>();
  final _formKeyDomiciliarioCondicionalPPL = GlobalKey<FormState>();
  final _formKeyLegalPPL = GlobalKey<FormState>();
  final _formKeyTdPPL = GlobalKey<FormState>();
  final _formKeyNuiPPL = GlobalKey<FormState>();
  final _formKeyPatioPPL = GlobalKey<FormState>();
  int _currentPage = 0;
  int currentPageIndex = 0;
  List<Map<String, Object>> centrosReclusionTodos = [];
  late Future<bool> _centrosFuture;
  RecaptchaVerifier? _recaptchaVerifier;



  // Controladores de texto
  final TextEditingController nombreAcudienteController = TextEditingController();
  final TextEditingController apellidoAcudienteController = TextEditingController();
  final TextEditingController celularController = TextEditingController();
  final TextEditingController nombrePplController = TextEditingController();
  final TextEditingController apellidoPplController = TextEditingController();
  final TextEditingController numeroDocumentoPplController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmarController = TextEditingController();
  final TextEditingController tdPplController = TextEditingController();
  final TextEditingController nuiPplController = TextEditingController();
  final TextEditingController patioPplController = TextEditingController();
  final TextEditingController direccionPplController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  final TextEditingController codigoReferidoController = TextEditingController();

  String? selectedRegional;
  String? selectedCentro;
  String? departamentoSeleccionado;
  String? municipioSeleccionado;

  final List<String> parentescoOptions = [
    // 👪 Padres
    'Madre',
    'Padre',

    // 👧👦 Hijos
    'Hija',
    'Hijo',

    // 💑 Cónyuge
    'Esposa',
    'Esposo',

    // 👵👴 Abuelos
    'Abuela',
    'Abuelo',

    // 👧👦 Nietos
    'Nieta',
    'Nieto',

    // 🧍‍♂️🧍‍♀️ Hermanos
    'Hermana',
    'Hermano',

    // 👨‍👧‍👦 Tíos y primos
    'Tía',
    'Tío',
    'Prima',
    'Primo',

    // 👨‍❤️‍👨 Pareja no conyugal
    'Compañera',
    'Compañero',

    // 👨‍👩‍👧‍👦 Familia política
    'Cuñada',
    'Cuñado',
    'Suegra',
    'Suegro',
    'Nuera',
    'Yerno',

    // 👧👦 Sobrinos
    'Sobrina',
    'Sobrino',

    // 👥 Amistades
    'Amiga',
    'Amigo',

    // 👨‍⚖️ Representantes legales o similares
    'Abogado/a',
    'Tutor/a',

    // 🙋‍♀️ En nombre propio
    'En nombre propio',

    // ❓ Otro
    'Otro',
  ];

  final List<String> tipoDocumentoOptions = ['Cédula de Ciudadanía', 'Pasaporte', 'Tarjeta de Identidad'];
  final List<String> situacionOptions = ['En Reclusión', 'En Prisión domiciliaria', 'En libertad condicional'];
  String? parentesco;
  String? tipoDocumento;
  String? situacionActual;
  String? direccion;
  String? td;
  String? nui;
  String? patio;
  bool _aceptaTerminos = false;
  String? _verificationId;
  bool _otpEnviado = false;
  late ConfirmationResult _confirmationResult;
  RecaptchaVerifier? recaptchaVerifier;
  bool _otpCompleto = false;
  bool _mostrarPin = false;
  bool _verificandoOTP = false;
  bool _recaptchaValidado = false;
  String? codigoReferido;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      recaptchaVerifier = RecaptchaVerifier(
        container: 'recaptcha-container',
        size: RecaptchaVerifierSize.normal,
        theme: RecaptchaVerifierTheme.light,
        auth: FirebaseAuthPlatform.instance, // ✅ ESTE es el tipo correcto
      );
    }

    _centrosFuture = _fetchTodosCentrosReclusion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // ✅ Permite que la UI se ajuste al teclado
      backgroundColor: blanco,
      appBar: AppBar(
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white, size: 30),
        title: const Text('Proceso de registro', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600), // Limita el ancho máximo
          padding: const EdgeInsets.all(10.0), // Agrega espacio alrededor del contenido
          child: Column(
            children: [
              LinearProgressIndicator(value: (_currentPage + 1) /15, backgroundColor: Colors.grey.shade300),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildIntroduccion(),
                    _buildIntroAcudienteForm(),
                    _buildAcudienteForm(),
                    _buildCelularAcudienteForm(),
                    _buildParentescoAcudienteForm(),
                    _buildNombresPplForm(),
                    _buildDocumentoPplForm(),
                    _buildSituacionActualPplForm(),
                    _buildDireccionDomiciliarioCondicionalPplForm(),
                    _buildSeleccionDepartamentoMunicipioPplForm(),
                    if (situacionActual == "En Reclusión") _buildPplCentroReclusionLegalForm(),
                    _buildPplTDLegalForm(),
                    _buildPplNUILegalForm(),
                    _buildPplPatioLegalForm(),
                    _buildVerificacionCelularOTPForm(),
                    _buildPinRespaldoForm(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      SizedBox(
                        height: 35, // 🔥 Reducimos la altura del botón
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gris, // 🔥 Color de fondo
                            foregroundColor: Colors.white, // 🔥 Color del texto
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // 🔥 Menos padding
                            minimumSize: const Size(50, 25), // 🔥 Tamaño mínimo más pequeño
                          ),
                          onPressed: _prevPage,
                          child: const Row(
                            children: [
                              Icon(Icons.keyboard_double_arrow_left, size: 16), // 🔹 Icono más pequeño
                              SizedBox(width: 3), // 🔥 Menos espacio
                              Text('Anterior', style: TextStyle(fontSize: 14)), // 🔹 Texto más pequeño
                            ],
                          ),
                        ),
                      ),

                    SizedBox(
                      height: 35,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary, // 🔥 Color de fondo
                          foregroundColor: Colors.white, // 🔥 Color del texto
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // 🔥 Menos padding
                          minimumSize: const Size(50, 25), // 🔥 Tamaño mínimo más pequeño
                        ),
                        onPressed: (_currentPage == 14 && _otpCompleto) ? _verificarOTP : _validarYContinuar,
                        child: Row(
                          children: [
                            Text(
                              _currentPage == 15 ? 'Finalizar' : 'Siguiente',
                              style: const TextStyle(fontSize: 14), // 🔹 Texto más pequeño
                            ),
                            const SizedBox(width: 3), // 🔥 Menos espacio
                            const Icon(Icons.keyboard_double_arrow_right, size: 16), // 🔹 Icono más pequeño
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )

            ],
          ),
        ),
      ),
    );
  }

  void _prevPage() {
    // 🔥 Si estamos en la página 11 y la opción NO fue "En Reclusión", regresamos directamente a la 9
    if (_currentPage == 11 && situacionActual != "En Reclusión") {
      setState(() {
        _currentPage = 9;
      });
      _pageController.jumpToPage(9);
      return;
    }

    // 🔥 Si estamos en la página 10 y venimos directamente de la 7, regresamos a la 7
    if (_currentPage == 10 && situacionActual == "En Reclusión") {
      setState(() {
        _currentPage = 7; // Regresar directamente a la página 7
      });
      _pageController.jumpToPage(7);
      return;
    }

    // 🔥 Comportamiento normal para retroceder una página
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildIntroduccion() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/logo_tu_proceso_ya.png',
                width: isLargeScreen ? 100 : 100,
                height: isLargeScreen ? 100 : 100,
              ),
              const SizedBox(height: 15),
              const Text(
                "¡Vamos a guiarte en el proceso de registro en nuestra plataforma!",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 30),
              RichText(
                textAlign: TextAlign.justify,
                text: const TextSpan(
                  style: TextStyle(fontSize: 15, height: 1.2, color: Colors.black),
                  children: [
                    TextSpan(text: "Por favor, asegúrate de ingresar todos los datos de manera "),
                    TextSpan(text: "completa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                    TextSpan(text: ", "),
                    TextSpan(text: "correcta", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    TextSpan(text: " y "),
                    TextSpan(text: "veraz", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    TextSpan(text: ". La precisión de la información es fundamental para que la plataforma pueda gestionar de manera efectiva las diligencias necesarias para la persona privada de la libertad (PPL)."),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red), // ⚠️ Icono de advertencia
                 const SizedBox(width: 8), // Espacio entre el icono y el texto
                  Expanded( // Permite que el texto se ajuste sin desbordar
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.black, height: 1.1), // Estilo base
                        children: [
                          TextSpan(text: "Es "),
                          TextSpan(
                            text: "de suma importancia",
                            style: TextStyle(fontWeight: FontWeight.bold), // 🟡 Negrita para énfasis
                          ),
                          TextSpan(text: " que leas los términos y condiciones de nuestro servicio."),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 🟢 Formulario para validar términos y condiciones
              Form(
                key: _formKeyTerminosYCondiciones,
                child: FormField<bool>(
                  initialValue: _aceptaTerminos,
                  validator: (value) {
                    if (value != true) {
                      return "Debes aceptar los Términos y Condiciones para continuar.";
                    }
                    return null;
                  },
                  builder: (formFieldState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          title: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const TerminosCondicionesPage()), // Página de términos
                              );
                            },
                            child: const Text(
                              "He leído y acepto los Términos y Condiciones",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          value: _aceptaTerminos,
                          onChanged: (bool? value) {
                            setState(() {
                              _aceptaTerminos = value ?? false;
                              formFieldState.didChange(value); // Actualiza el estado del FormField
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        if (formFieldState.hasError) // Muestra error si no se marca
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Text(
                              formFieldState.errorText!,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 40),
              const Text(
                "¡Gracias por contar con nosotros!",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroAcudienteForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const Text("Acudiente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.justify,
              text: const TextSpan(
                style: TextStyle(fontSize: 14, height: 1.2, color: Colors.black),
                children: [
                  TextSpan(text: "El acudiente es el enlace designado por una persona privada de libertad para tramitar y solicitar "
                      "los servicios ofrecidos por nuestra plataforma. Suele ser un "),
                  TextSpan(text: "familiar", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: ", "),
                  TextSpan(text: "amigo", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: " o "),
                  TextSpan(text: "alguien de confianza", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: " en quien el PPL delega la representación de sus intereses y necesidades. A través "
                      "de este vínculo, podemos trabajar juntos para garantizar que sus derechos y necesidades "
                      "sean atendidos de manera efectiva."),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text("Código de referido", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Si alguien te refirió coloca su código, de lo contrario da click en el boton siguiente", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 40),
            TextFormField(
              keyboardType: TextInputType.number,
              controller: codigoReferidoController,
              decoration: _buildInputDecoration('Código referido'),
            ),
            const SizedBox(height: 130),
            Container(
              alignment: Alignment.centerRight,
              child: const Text("¡Iniciemos!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildAcudienteForm() {
    return Form(
      key: _formKeyAcudiente, // Asociamos el formulario con la clave
      child: SingleChildScrollView(
        //keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, // 🔥 Permite ocultar el teclado solo si se desliza
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ingresa los datos del Acudiente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            // 🔹 Nombres
            TextFormField(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              controller: nombreAcudienteController,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              decoration: _buildInputDecoration('Nombres'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa los nombres';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),

            // 🔹 Apellidos
            TextFormField(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              controller: apellidoAcudienteController,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              decoration: _buildInputDecoration('Apellidos'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa los apellidos';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
  Future<void> _agregarSubcoleccionReferido({
    required String codigoReferidor,
    required String nombre,
    required String apellido,
  }) async {
    final query = await FirebaseFirestore.instance
        .collection('referidores')
        .where('codigo', isEqualTo: codigoReferidor)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final docRef = query.docs.first.reference;

      await docRef.collection('referidos').add({
        'nombre': nombre,
        'apellido': apellido,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _incrementarContadorReferidos(String codigoReferidor) async {
    final query = await FirebaseFirestore.instance
        .collection('referidores')
        .where('codigo', isEqualTo: codigoReferidor)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final docRef = query.docs.first.reference;

      // Incrementar en +1 el contador de referidos
      await docRef.update({
        'totalReferidos': FieldValue.increment(1),
      });
    }
  }



  Widget _buildCelularAcudienteForm() {
    return Form(
      key: _formKeyCelularAcudiente,
      //autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Text(" Celular del Acudiente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              // 🔹 Advertencia del celular
              const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.amber, size: 30),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text("Por favor ingresa un número de celular activo y que tenga cuenta de WhatsApp, ya que por "
                        "este medio también podemos enviarte información relevante.", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // 🔹 Celular
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: celularController,
                keyboardType: TextInputType.phone,
                decoration: _buildInputDecoration('Celular').copyWith(
                  counterText: "", // 🔥 Oculta el contador de caracteres
                ),
                maxLength: 10,
                validator: _validarCelular,
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentescoAcudienteForm() {
    return Form(
      key: _formKeyParentescoAcudiente,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Text("Parentesco del Acudiente",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              const Text("¿Qué eres de la persona privada de la libertad?",
                  style: TextStyle(fontSize: 14)),
              const SizedBox(height: 15),

              // 🔹 Parentesco del acudiente (Dropdown con título arriba)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: DropdownButtonFormField<String>(
                  dropdownColor: blancoCards,
                  value: parentesco,
                  decoration: InputDecoration(
                    labelText: 'Parentesco del acudiente',
                    floatingLabelBehavior: FloatingLabelBehavior.always, // 🔥 Siempre muestra el título arriba
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
                      borderSide: const BorderSide(color: primary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder( // 🔥 Borde rojo cuando hay error
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      parentesco = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor selecciona el parentesco';
                    }
                    return null;
                  },
                  items: parentescoOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNombresPplForm() {
    return Form(
      key: _formKeyNombresPPL, // 🔥 Asignamos una clave de formulario para validar
      //autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Información de la persona privada de la libertad",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              RichText(
                text:const TextSpan(
                  style: TextStyle(fontSize: 12, color: Colors.black),
                  children: [
                    TextSpan(text: "Por favor ingresa los "),
                    TextSpan(
                      text: "nombres",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    TextSpan(text: " y "),
                    TextSpan(
                      text: "apellidos completos",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    TextSpan(text: " como aparecen en el documento de identidad."),
                  ],
                ),
              ),
              const SizedBox(height: 20),
        
              // 🔹 Nombres
              TextFormField(
                controller: nombrePplController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                decoration: _buildInputDecoration('Nombres'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa los nombres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
        
              // 🔹 Apellidos
              TextFormField(
                controller: apellidoPplController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                decoration: _buildInputDecoration('Apellidos'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa los apellidos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentoPplForm() {
    return Form(
      key: _formKeyDocumentoPPL,
      //autovalidateMode: AutovalidateMode.onUserInteraction, // 🔥 Valida en tiempo real
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Documento de la persona privada de la libertad",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 12, color: Colors.black),
                  children: [
                    TextSpan(text: "Por favor ingresa el "),
                    TextSpan(
                      text: "número de documento",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    TextSpan(text: " y selecciona el "),
                    TextSpan(
                      text: "tipo de documento",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    TextSpan(text: " correspondiente."),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 🔹 Número de Documento
              TextFormField(
                controller: numeroDocumentoPplController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration('Número de Documento').copyWith(
                  counterText: "", // 🔥 Oculta el contador de caracteres
                ),
                maxLength: 10,
                validator: _validarNumeroDocumento,
              ),
              const SizedBox(height: 25),

              // 🔹 Tipo de Documento (Dropdown)
              DropdownButtonFormField<String>(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                dropdownColor: blancoCards,
                value: tipoDocumento,
                decoration: _buildInputDecoration('Tipo de Documento'),
                onChanged: (value) {
                  setState(() {
                    tipoDocumento = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor selecciona un tipo de documento';
                  }
                  return null;
                },
                items: tipoDocumentoOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _verificarDuplicadosFirestore({String? celular, String? documento}) async {
    try {
      if (celular != null && celular.isNotEmpty) {
        final celularSnapshot = await FirebaseFirestore.instance
            .collection('Ppl')
            .where('celular', isEqualTo: celular)
            .limit(1)
            .get();

        if (celularSnapshot.docs.isNotEmpty) {
          _mostrarMensaje("Este número de celular ya está registrado.");
          return true;
        }
      }

      if (documento != null && documento.isNotEmpty) {
        final documentoSnapshot = await FirebaseFirestore.instance
            .collection('Ppl')
            .where('numero_documento_ppl', isEqualTo: documento)
            .limit(1)
            .get();

        if (documentoSnapshot.docs.isNotEmpty) {
          _mostrarMensaje("Este número de documento ya está registrado.");
          return true;
        }
      }

      return false;
    } catch (e) {
      _mostrarMensaje("Error al verificar duplicados: $e");
      return true; // Por seguridad, detiene el flujo si hay error
    }
  }

  Widget _buildSituacionActualPplForm() {
    return Form(
      key: _formKeySituacionPPL,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Text("Situación actual del Ppl",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              const Text("Selecciona una opción",
                  style: TextStyle(fontSize: 14)),
              const SizedBox(height: 15),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: DropdownButtonFormField<String>(
                  dropdownColor: blancoCards,
                  value: situacionActual,
                  decoration: InputDecoration(
                    labelText: 'Situación actual',
                    floatingLabelBehavior: FloatingLabelBehavior.always, // 🔥 Siempre muestra el título arriba
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
                      borderSide: const BorderSide(color: primary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder( // 🔥 Borde rojo cuando hay error
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      situacionActual = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor selecciona el una opción';
                    }
                    return null;
                  },
                  items: situacionOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDireccionDomiciliarioCondicionalPplForm() {
    return Form(
      key: _formKeyDomiciliarioCondicionalPPL, // 🔥 Asignamos una clave de formulario para validar
      //autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Has seleccionado que el PPL actualmente se encuentra en $situacionActual, por lo que requerimos la siguiente información.",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              RichText(
                text:const TextSpan(
                  style: TextStyle(fontSize: 12, color: Colors.black),
                  children: [
                    TextSpan(text: "Por favor ingresa de manera clara la "),
                    TextSpan(
                      text: "dirección",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    TextSpan(text: " donde se encuentra el PPL "),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 Nombres
              TextFormField(
                controller: direccionPplController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                decoration: _buildInputDecoration('Dirección'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa la dirección';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeleccionDepartamentoMunicipioPplForm() {
    final GlobalKey<FormState> formKeySituacionPPL = GlobalKey<FormState>();
    return Form(
      key: formKeySituacionPPL,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Text("Ahora dinos en que departamento y minicipio se encuentra el Ppl", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.1)),
              const SizedBox(height: 15),

              // ✅ Widget de selección de Departamento y Municipio
              DepartamentosMunicipiosWidget(
                departamentoSeleccionado: departamentoSeleccionado,
                municipioSeleccionado: municipioSeleccionado,
                onSelectionChanged: (String departamento, String municipio) {
                  setState(() {
                    departamentoSeleccionado = departamento;
                    municipioSeleccionado = municipio;
                  });
                },
              ),

              const SizedBox(height: 30), // Puedes quitar esto si ya no necesitas espacio extra
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPplCentroReclusionLegalForm() {
    return Form(
      key: _formKeyLegalPPL,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Centro de Reclusión",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 12, color: Colors.black),
                  children: [
                    TextSpan(text: "Escribe el "),
                    TextSpan(
                      text: "nombre de la ciudad",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    TextSpan(text: " donde está recluido para ver las opciones. Luego, haz clic en una para "),
                    TextSpan(
                      text: "seleccionarla.",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 🔥 FutureBuilder para cargar centros de reclusión
              FutureBuilder<bool>(
                future: _centrosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text("Cargando centros de reclusión..."),
                        ],
                      ),
                    );
                  }
                  if (snapshot.hasError || snapshot.data == false) {
                    return const Text("⚠ Error al cargar los centros de reclusión.");
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔥 Texto que muestra el centro seleccionado
                      if (selectedCentro != null && selectedCentro!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Centro de reclusión seleccionado:",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              Text(
                                "$selectedCentro",
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 30),
                      _seleccionarCentroReclusion(),
                      const SizedBox(height: 10),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

// 🔥 Nueva versión del campo de búsqueda con el letrero siempre visible
  Widget _seleccionarCentroReclusion() {
    return Autocomplete<Map<String, String>>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Map<String, String>>.empty();
        }
        return centrosReclusionTodos
            .map((option) => option.map((key, value) => MapEntry(key, value.toString())))
            .where((option) => option['nombre']!.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      displayStringForOption: (option) => option['nombre']!,
      onSelected: (option) {
        setState(() {
          selectedCentro = option['id'];
          selectedRegional = option['regional'];
        });
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          style: const TextStyle(fontSize: 14), // 🔥 Reduce el tamaño de la letra
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            labelText: "Centro de reclusión",
            floatingLabelBehavior: FloatingLabelBehavior.always, // 🔥 Mantiene el título arriba SIEMPRE
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primary, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: blancoCards, // 🔥 Fondo blanco para las opciones
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9, // Ajusta el ancho
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        option['nombre']!,
                        style: const TextStyle(fontSize: 14), // 🔥 Tamaño de la letra mejorado
                      ),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPplTDLegalForm() {
    return Form(
      key: _formKeyTdPPL,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Identificación interna del PPL",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // 🔹 TD (Tarjeta Decadactilar)
              TextFormField(
                controller: tdPplController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration('TD (Tarjeta Decadactilar)'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el TD';
                  }
                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'El TD solo puede contener números';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPplNUILegalForm() {
    return Form(
      key: _formKeyNuiPPL,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Identificación interna del PPL",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // 🔹 NUI - Solo números, longitud específica
              TextFormField(
                controller: nuiPplController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration('NUI (Número Único de Identificación)'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el NUI';
                  }
                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'El NUI solo puede contener números';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinRespaldoForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "PIN de Seguridad",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock, color: Colors.black54, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Crea un PIN de 4 dígitos que te servirá como clave de respaldo para recuperar tu cuenta en caso de que pierdas el acceso a tu número de celular. "
                      "Este PIN es muy importante, ya que sin él no podrás recuperar tu cuenta si cambias de teléfono o número.",
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: pinController,
            obscureText: !_mostrarPin,
            maxLength: 4,
            keyboardType: TextInputType.number,
            decoration: _buildInputDecoration("PIN de 4 dígitos").copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _mostrarPin ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _mostrarPin = !_mostrarPin;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.length != 4 || !RegExp(r'^\d{4}$').hasMatch(value)) {
                return 'Ingresa un PIN válido de 4 números.';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPplPatioLegalForm() {
    return Form(
      key: _formKeyPatioPPL,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Identificación interna del PPL",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 🔹 PATIO - Campo obligatorio
              TextFormField(
                controller: patioPplController,
                keyboardType: TextInputType.text,
                decoration: _buildInputDecoration('Patio No.'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el patio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificacionCelularOTPForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Verificación del número de celular",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.2),
            ),
            const SizedBox(height: 16),
            const Text(
              "Para continuar, necesitamos validar tu número de celular. Te enviaremos un código por mensaje de texto que deberás ingresar a continuación.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Botón para enviar el código
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: blanco,
                side: const BorderSide(color: primary, width: 2),
              ),
              onPressed: _enviarCodigoOTP,
              child: const Text("Enviar código de verificación"),
            ),
            if (_recaptchaValidado) ...[
              const SizedBox(height: 30),

              // Campo para ingresar el OTP
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: otpController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 50,
                  fieldWidth: 40,
                  activeFillColor: Colors.white,
                  selectedFillColor: Colors.white,
                  inactiveFillColor: Colors.white,
                  activeColor: primary,
                  selectedColor: primary,
                  inactiveColor: Colors.grey,
                ),
                cursorColor: primary,
                animationDuration: const Duration(milliseconds: 300),
                enableActiveFill: true,
                onChanged: (value) {
                  setState(() {
                    _otpCompleto = value.length == 6;
                  });
                },
              ),
              const SizedBox(height: 20),
              // Botón para verificar el OTP con estilo
              ElevatedButton.icon(
                icon: const Icon(Icons.verified, color: primary),
                label: Text(
                  _verificandoOTP ? "Validando código..." : "Verificar código",
                  style: const TextStyle(color: primary),
                ),
                onPressed: (_otpCompleto && !_verificandoOTP)
                    ? () async {
                  setState(() => _verificandoOTP = true);
                  _verificarOTP(); // tu función existente
                  setState(() => _verificandoOTP = false);
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: blanco,
                  side: BorderSide(
                    color: _otpCompleto ? primary : Colors.grey,
                    width: 2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _enviarCodigoOTP() async {
    final celular = celularController.text.trim();

    if (!RegExp(r'^[0-9]{10}$').hasMatch(celular)) {
      _mostrarMensaje("Número de celular inválido. Debe tener 10 dígitos.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (kIsWeb) {
        // ✅ Crea el RecaptchaVerifier en web
        recaptchaVerifier = RecaptchaVerifier(
          auth: FirebaseAuthPlatform.instance,
          container: 'recaptcha-container', // 👈 Aquí debe haber un div vacío en tu HTML
          size: RecaptchaVerifierSize.normal,
          theme: RecaptchaVerifierTheme.light,
          onSuccess: () {
            if (kDebugMode) print("✅ reCAPTCHA verificado correctamente");
            html.document.getElementById('recaptcha-container')?.style.display = 'none';
            setState(() {
              _recaptchaValidado = true;
            });
          },
          onError: (FirebaseAuthException e) {
            Navigator.of(context).pop();
            _mostrarMensaje("Error en reCAPTCHA: ${e.message}");
          },
          onExpired: () {
            Navigator.of(context).pop();
            _mostrarMensaje("El reCAPTCHA ha expirado");
          },
        );
      }

      // 🔥 Ahora sí enviamos el código usando el recaptchaVerifier
      final confirmationResult = await FirebaseAuth.instance.signInWithPhoneNumber(
        "+57$celular",
        recaptchaVerifier,
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // Cierra el loading
      }

      setState(() {
        _confirmationResult = confirmationResult;
        _otpEnviado = true;
        _recaptchaValidado = true;
      });

      if (kDebugMode) {
        print("✅ Código enviado correctamente");
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _mostrarMensaje("Error inesperado: ${e.toString()}");
      }
    }
  }



  void _guardarConPin() async {
    final pin = pinController.text.trim();
    final codigoReferidor = codigoReferidoController.text.trim();
    final nombre = nombrePplController.text.trim();
    final apellido = apellidoPplController.text.trim();
    final ciudad = municipioSeleccionado ?? "";

    if (pin.isEmpty || pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      _mostrarMensaje("El PIN debe tener exactamente 4 dígitos.");
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final userId = FirebaseAuth.instance.currentUser!.uid;

      final userData = {
        "id": userId,
        "nombre_acudiente": nombreAcudienteController.text.trim(),
        "apellido_acudiente": apellidoAcudienteController.text.trim(),
        "parentesco_representante": parentesco ?? "",
        "celular": celularController.text.trim(),
        "email": "", // vacío si no se usa
        "nombre_ppl": nombre,
        "apellido_ppl": apellido,
        "tipo_documento_ppl": tipoDocumento ?? "",
        "numero_documento_ppl": numeroDocumentoPplController.text.trim(),
        "regional": selectedRegional ?? "",
        "centro_reclusion": selectedCentro ?? "",
        "juzgado_ejecucion_penas": "",
        "juzgado_ejecucion_penas_email": "",
        "juzgado_que_condeno": "",
        "juzgado_que_condeno_email": "",
        "ciudad": "",
        "categoria_delito": "",
        "delito": "",
        "td": tdPplController.text.trim(),
        "nui": nuiPplController.text.trim(),
        "patio": patioPplController.text.trim(),
        "radicado": "",
        "tiempo_condena": 0,
        "status": "registrado",
        "isNotificatedActivated": false,
        "isPaid": false,
        "assignedTo": "",
        "fechaRegistro": DateTime.now(),
        "fecha_captura": null,
        "saldo": 0,
        "departamento": departamentoSeleccionado ?? "",
        "municipio": ciudad,
        "situacion": situacionActual ?? "",
        "direccion": direccionPplController.text.trim(),
        "pin_respaldo": sha256.convert(utf8.encode(pin)).toString(),
        "referidoPor": codigoReferidor,
      };

      await FirebaseFirestore.instance.collection("Ppl").doc(userId).set(userData);

      // 👉 Verifica y registra al referido si el código existe
      if (codigoReferidor.isNotEmpty) {
        final valido = await _codigoReferidoEsValido(codigoReferidor);
        if (valido) {
          await _agregarSubcoleccionReferido(
            codigoReferidor: codigoReferidor,
            nombre: nombre,
            apellido: apellido,

          );

          await _incrementarContadorReferidos(codigoReferidor);
        }
      }

      if (context.mounted) {
        Navigator.of(context).pop(); // cierra loading
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => EstamosValidandoPage()),
              (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      _mostrarMensaje("Error al guardar el PIN y datos: ${e.toString()}");
    }
  }


  void _verificarOTP() async {
    final codigo = otpController.text.trim();

    if (codigo.isEmpty || codigo.length != 6) {
      _mostrarMensaje("Ingresa un código válido de 6 dígitos.");
      return;
    }

    if (_confirmationResult == null) {
      _mostrarMensaje("Primero solicita el código de verificación.");
      return;
    }

    try {
      // Verifica el código ingresado
      await _confirmationResult!.confirm(codigo);

      if (kDebugMode) {
        print("✅ Código verificado correctamente");
      }

      // Redirecciona a la siguiente página, como tenías
      if (context.mounted) {
        setState(() {
          _currentPage = 16;
        });
        _pageController.jumpToPage(16);
      }
    } on FirebaseAuthException catch (_) {
      _mostrarMensaje("Código inválido o expirado. Intenta nuevamente.");
    } catch (e) {
      _mostrarMensaje("Error inesperado: ${e.toString()}");
    }
  }


  // Método auxiliar para mostrar mensajes
  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

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

  /// 🔥 **Método para validar y continuar a la siguiente página**
  Future<void> _validarYContinuar() async {
    if (_currentPage == 0 && !_formKeyTerminosYCondiciones.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes aceptar los Términos y Condiciones antes de continuar."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (_currentPage == 1) {
      final referidoPor = codigoReferidoController.text.trim();

      // Si el campo no está vacío, validar que el código exista
      if (referidoPor.isNotEmpty) {
        final esValido = await _codigoReferidoEsValido(referidoPor);
        if (!esValido) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("El código de referido ingresado no es válido."),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }
      }
    }


    if (_currentPage == 2 && !_formKeyAcudiente.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor completa todos los campos del acudiente antes de continuar."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Validación celular
    if (_currentPage == 3) {
      final celular = celularController.text.trim();

      if (!_formKeyCelularAcudiente.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Por favor ingresa el número del celular antes de continuar."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // 🔥 Validar si el número de celular ya está registrado
      final yaExiste = await _verificarDuplicadosFirestore(celular: celular);
      if (yaExiste) return; // 🛑 Detiene el avance si ya existe
    }

    // Validación parentesco
    if (_currentPage == 4 && !_formKeyParentescoAcudiente.currentState!.validate()) {
      if(context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Por favor selecciona un parentesco antes de continuar."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    // Validación nombres ppl
    if (_currentPage == 5 && !_formKeyNombresPPL.currentState!.validate()) {
      if(context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Por favor ingresa los datos completos antes de continuar."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    // Validación documento ppl
    if (_currentPage == 6) {
      final String documento = numeroDocumentoPplController.text.trim();
      final String? tipoDoc = tipoDocumento;

      if (!_formKeyDocumentoPPL.currentState!.validate()) {
        setState(() {}); // 🔥 Refresca la pantalla para mostrar los errores
        return;
      }

      // 🔹 Validar si ambos campos están vacíos
      if (documento.isEmpty && (tipoDoc == null || tipoDoc.isEmpty)) {
        if(context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Por favor ingresa el número de documento y selecciona el tipo de documento."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
      }

      // 🔹 Validar si solo el número de documento está vacío
      if (documento.isEmpty) {
        if(context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Por favor ingresa el número de documento."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
      }

      // 🔹 Validar si solo el tipo de documento no está seleccionado
      if (tipoDoc == null || tipoDoc.isEmpty) {
        if(context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Por favor selecciona el tipo de documento."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
      }

      // 🔹 Validar formato del número de documento (Debe ser de 8 o 10 dígitos)
      if (!RegExp(r'^\d{8}$|^\d{10}$').hasMatch(documento)) {
        if(context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("El número de documento debe tener 8 o 10 dígitos."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
      }

      // 🔥 Validación de documento ya registrado en Firestore
      final existeDocumento = await _verificarDuplicadosFirestore(documento: documento);
      if (existeDocumento) return;
    }



    //para la situacion del ppl
    // 🔹 Validación de la situación actual del PPL (Página 7)
    if (_currentPage == 7) {
      if (situacionActual == null || situacionActual!.isEmpty) {
        if(context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Por favor selecciona una opción."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
      }

      // 🔥 Si la opción seleccionada es "En Reclusión", salta a la página 10 directamente
      if (situacionActual == "En Reclusión") {
        setState(() {
          _currentPage = 10; // Página del centro de reclusión
        });
        _pageController.jumpToPage(10); // Ir directamente a la página 10
        return;
      } else {
        // 🔥 Si la opción es otra, ir a la página 8 (dirección) y **SALTAR la página 10**
        setState(() {
          _currentPage = 8;
        });
        _pageController.jumpToPage(8);
        return;
      }
    }

    //para la direccion
    if(_currentPage == 8){
      final String direccion = direccionPplController.text.trim();
      if (direccion.isEmpty) {
        if(context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Por favor ingresa la dirección."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
      }
    }
    // 🔹 Validación de selección de Departamento y Municipio (Página 9)
    if (_currentPage == 9) {
      if (departamentoSeleccionado == null || departamentoSeleccionado!.isEmpty) {
        if(context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Por favor selecciona un departamento."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
      }

      if (municipioSeleccionado == null || municipioSeleccionado!.isEmpty) {
        if(context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Por favor selecciona un municipio."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

      }

      // 🔥 Si el usuario seleccionó "En Reclusión", ir a la página 10
      if (situacionActual == "En Reclusión") {
        setState(() {
          _currentPage = 10;
        });
        _pageController.jumpToPage(10);
        return;
      }

      // 🔥 Si el usuario seleccionó otra opción, saltar la página 10 e ir directo a la 11
      setState(() {
        _currentPage = 13;
      });
      _pageController.jumpToPage(13);
      return;
    }



    // 🔥 Nueva Validación: Centro de Reclusión en la página 3
    if (_currentPage == 10) {

      if (!_formKeyLegalPPL.currentState!.validate()) {
        setState(() {}); // 🔥 Refresca la pantalla para mostrar los errores
        return;
      }


      if (!_formKeyLegalPPL.currentState!.validate()) {
        if(context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Por favor selecciona un Centro de Reclusión antes de continuar."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

      }

      if (selectedCentro == null || selectedCentro!.isEmpty) {
        if(context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Debes seleccionar un Centro de Reclusión antes de continuar."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
      }
    }

    if (_currentPage == 11) {
      final String td = tdPplController.text.trim();

      if (!_formKeyTdPPL.currentState!.validate()) {
        setState(() {}); // 🔥 Refresca la pantalla para mostrar los errores
        return;
      }

      // 🔹 Si todos los campos están vacíos
      if (td.isEmpty) {
        setState(() {}); // 🔥 Refresca la pantalla para que aparezcan los errores
        if(context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Por favor ingresa el TD."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

      }

      // 🔹 Validar formato de TD (Debe ser solo números)
      if (!RegExp(r'^[0-9]+$').hasMatch(td)) {
        setState(() {});
        if(context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("El TD solo puede contener números."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
      }
    }

    if (_currentPage == 12) {
      final String nui = nuiPplController.text.trim();

      if (!_formKeyNuiPPL.currentState!.validate()) {
        setState(() {}); // 🔥 Refresca la pantalla para mostrar los errores
        return;
      }

      // 🔹 Si todos los campos están vacíos
      if (nui.isEmpty) {
        setState(() {}); // 🔥 Refresca la pantalla para que aparezcan los errores
        const SnackBar(
          content: Text("Por favor ingresa el NUI."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        );
        return;
      }

      // 🔹 Validar formato de NUI (Debe ser solo números)
      if (!RegExp(r'^[0-9]+$').hasMatch(nui)) {
        setState(() {});
        const SnackBar(
          content: Text("El NUI solo puede contener números."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        );
        return;
      }
    }

    if (_currentPage == 13) {
      final String patio = patioPplController.text.trim();

      if (!_formKeyPatioPPL.currentState!.validate()) {
        setState(() {}); // 🔥 Refresca la pantalla para mostrar los errores
        return;
      }

      // 🔹 Validar si solo el Patio está vacío
      if (patio.isEmpty) {
        setState(() {});
        const SnackBar(
          content: Text("Por favor ingresa el número del patio."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        );
        return;
      }
    }

    if (_currentPage == 14) {
      final String celular = celularController.text.trim();

      if (!_formKeyCelularAcudiente.currentState!.validate()) {
        if(context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Por favor ingresa un número de celular válido."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

      }
      // 🔥 Verificar si el celular ya está registrado
      final existeCelular = await _verificarDuplicadosFirestore(celular: celular);
      if (existeCelular) return;

      _enviarCodigoOTP(); // Solo se llama si pasa la validación
      return;
    }


    if (_currentPage == 16) {
      final pin = pinController.text.trim();

      if (pin.isEmpty || pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
        if(context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ingresa un PIN válido de 4 números."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
      }

      _guardarConPin(); // Ahora sí guarda los datos
      return;
    }


    // Avanzar solo si todas las validaciones se cumplen
    if (_currentPage < 16) {
      setState(() {
        _currentPage++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<bool> _codigoReferidoEsValido(String referidoPor) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('referidores')
        .where('codigo', isEqualTo: referidoPor)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }


  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black), // ✅ Siempre negro
      floatingLabelStyle: const TextStyle(color: Colors.black), // ✅ Siempre visible en negro
      border: const OutlineInputBorder(), // Borde predeterminado
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey), // Borde gris cuando no está enfocado
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: primary, width: 2), // Borde primary cuando está enfocado
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2), // Borde rojo cuando hay error
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2), // Borde rojo cuando está enfocado y con error
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always, // ✅ Siempre arriba
    );
  }

  String? _validarCelular(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa un número de celular';
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
      return 'Debe contener exactamente 10 dígitos numéricos';
    }
    return null;
  }

  String? _validarNumeroDocumento(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa el número de documento';
    }
    if (!RegExp(r'^\d{8}$|^\d{10}$').hasMatch(value)) {
      return 'Debe tener exactamente 8 o 10 dígitos';
    }
    return null;
  }

  Future<bool> _fetchTodosCentrosReclusion() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collectionGroup('centros_reclusion')
          .get();

      List<Map<String, Object>> fetchedTodosCentros = querySnapshot.docs.map((doc) {
        final regionalId = doc.reference.parent.parent?.id ?? "";
        final data = doc.data() as Map<String, dynamic>;

        return {
          'id': doc.id,
          'nombre': data.containsKey('nombre') ? data['nombre'].toString() : '',
          'regional': regionalId,
        };
      }).toList();
      //
      // for (var centro in fetchedTodosCentros) {
      //   if (kDebugMode) {
      //     print("🔹 Centros obtenidos");
      //   }
      // }

      // 🔥 Solo actualiza el estado si los datos han cambiado
      if (centrosReclusionTodos.isEmpty || fetchedTodosCentros.length != centrosReclusionTodos.length) {
        setState(() {
          centrosReclusionTodos = fetchedTodosCentros;
        });
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error al obtener centros de reclusión: $e");
      }
      return false;
    }
  }

  Widget seleccionarCentroReclusion() {
    if (centrosReclusionTodos.isEmpty) {
      return const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Cargando centros de reclusión..."),
          ],
        ),
      );
    }

    return Autocomplete<Map<String, String>>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Map<String, String>>.empty();
        }
        return centrosReclusionTodos
            .map((option) => option.map((key, value) => MapEntry(key, value.toString())))
            .where((option) => option['nombre']!.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      displayStringForOption: (option) => option['nombre']!,
      onSelected: (option) {
        setState(() {
          selectedCentro = option['id'];
          selectedRegional = option['regional'];
        });
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          maxLines: null, // 🔥 Permite que el texto se expanda en múltiples líneas si es necesario
          style: const TextStyle(fontSize: 14), // 🔥 Reduce el tamaño de la letra
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
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
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: blancoCards, // 🔥 Fondo blanco para las opciones
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9, // Ajusta el ancho
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        option['nombre']!,
                        style: const TextStyle(fontSize: 11), // 🔥 Reduce el tamaño de la letra
                      ),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

}
