import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuprocesoya/src/colors/colors.dart';

import '../estamos_validando/estamos_validando.dart';

class RegistroPage extends StatefulWidget {
  final DocumentSnapshot? doc; // 🔥 Agregar el parámetro opcional `doc`

  RegistroPage({super.key, this.doc});

  @override
  _RegistroPageState createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final PageController _pageController = PageController();
  final _formKeyAcudiente = GlobalKey<FormState>();
  final _formKeyPPL = GlobalKey<FormState>();
  final _formKeyLegalPPL = GlobalKey<FormState>();
  final _formKeyInfoTdPPL = GlobalKey<FormState>();
  final _formKeyCorreo = GlobalKey<FormState>();
  final _formKeyPassword = GlobalKey<FormState>();
  int _currentPage = 0;
  int currentPageIndex = 0;
  List<Map<String, Object>> centrosReclusionTodos = [];
  bool _mostrarDropdowns = false;
  late Future<bool> _centrosFuture;


  // Controladores de texto
  final TextEditingController nombreAcudienteController = TextEditingController();
  final TextEditingController apellidoAcudienteController = TextEditingController();
  final TextEditingController celularController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController emailConfirmarController = TextEditingController();
  final TextEditingController nombrePplController = TextEditingController();
  final TextEditingController apellidoPplController = TextEditingController();
  final TextEditingController numeroDocumentoPplController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmarController = TextEditingController();
  final TextEditingController tdPplController = TextEditingController();
  final TextEditingController nuiPplController = TextEditingController();
  final TextEditingController patioPplController = TextEditingController();
  TextEditingController _centroReclusionController = TextEditingController(); // Controlador del campo de texto
  String? selectedRegional; // Regional seleccionada
  String? selectedCentro; // Centro de reclusión seleccionado

  final List<String> parentescoOptions = ['Padre', 'Madre', 'Hermano/a', "Hijo/a", "Esposo/a",
    "Amigo/a", "Tio/a", "Sobrino/a", "Nieto/a", "Abuelo/a",'Abogado/a', 'Tutor/a', 'Otro'];
  final List<String> tipoDocumentoOptions = ['Cédula de Ciudadanía', 'Pasaporte', 'Tarjeta de Identidad'];
  String? parentesco;
  String? tipoDocumento;
  String? td;
  String? nui;
  String? patio;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;


  void _nextPage() {
    if (_currentPage < 3) {
      setState(() {
        _currentPage++;
      });
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  void initState() {
    super.initState();
    _centrosFuture = _fetchTodosCentrosReclusion(); // ✅ Carga solo una vez
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
        backgroundColor: primary,
        title: Text('Registro - Paso ${_currentPage + 1} de 7', style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600), // Limita el ancho máximo
          padding: const EdgeInsets.all(10.0), // Agrega espacio alrededor del contenido
          child: Column(
            children: [
              LinearProgressIndicator(value: (_currentPage + 1) / 7, backgroundColor: Colors.grey.shade300),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildIntroduccion(),
                    _buildAcudienteForm(),
                    _buildPplForm(),
                    _buildPplCentroReclusionLegalForm(),
                    _buildPplInfoTDLegalForm(),
                    _buildCuentaCorreoForm(),
                    _buildCuentapasawordForm(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gris, // 🔥 Color de fondo
                          foregroundColor: Colors.white, // 🔥 Color del texto
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: _prevPage,
                        child: const Row(
                          children: [
                            Icon(Icons.keyboard_double_arrow_left, size: 20), // 🔹 Flecha doble antes del texto
                            SizedBox(width: 5), // Espacio entre icono y texto
                            Text('Anterior'),
                          ],
                        ),
                      ),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary, // 🔥 Color de fondo
                        foregroundColor: Colors.white, // 🔥 Color del texto
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: _currentPage == 6 ? _submitForm : _validarYContinuar,
                      child: Row(
                        children: [
                          Text(_currentPage == 6 ? 'Finalizar' : 'Siguiente'),
                          const SizedBox(width: 5), // Espacio entre texto e icono
                          const Icon(Icons.keyboard_double_arrow_right, size: 20), // 🔹 Flecha doble después del texto
                        ],
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
              const SizedBox(height: 20),
              const Text("¡Vamos a guiarte en el proceso de registro en nuestra plataforma!", style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 20, color: negro, height: 1.2)),
              const SizedBox(height: 40),
      
              RichText(
                textAlign: TextAlign.justify,
                text: const TextSpan(
                  style: TextStyle(fontSize: 15, height: 1.2, color: Colors.black),
                  children: [
                    TextSpan(text: "Por favor, asegúrate de ingresar todos los datos de manera "),
                    TextSpan(text: "completa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: negro)),
                    TextSpan(text: ", "),
                    TextSpan(text: "correcta", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    TextSpan(text: " y "),
                    TextSpan(text: "veraz", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    TextSpan(text: ". La precisión de la información es fundamental para que la plataforma pueda gestionar de manera efectiva las diligencias necesarias para la persona privada de la libertad (PPL). Cualquier error en los datos puede afectar los procesos y retrasar la asistencia que necesitas. ¡Tu colaboración es clave para un servicio ágil y eficiente!"),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text("¡Gracias por contar con nostros!", style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 18, color: negro, height: 1.2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcudienteForm() {
    return Form(
      key: _formKeyAcudiente, // Asociamos el formulario con la clave
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Text("Paso 1. Acudiente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 30),
              const Text("Ingresa los datos del Acudiente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
        
              // 🔹 Nombres
              TextFormField(
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
              const SizedBox(height: 15),
        
              // 🔹 Celular
              TextFormField(
                controller: celularController,
                keyboardType: TextInputType.phone,
                decoration: _buildInputDecoration('Celular').copyWith(
                  counterText: "", // 🔥 Oculta el contador de caracteres
                ),
                maxLength: 10,
                validator: _validarCelular,
              ),
        
              const SizedBox(height: 15),
        
              // 🔹 Parentesco del acudiente
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: DropdownButtonFormField<String>(
                  dropdownColor: blancoCards,
                  value: parentesco,
                  decoration: const InputDecoration(
                    labelText: 'Parentesco del acudiente',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary, width: 2),
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

  Widget _buildPplForm() {
    return Form(
      key: _formKeyPPL, // 🔥 Asignamos una clave de formulario para validar
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Información de la persona privada de la libertad",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
        
              // 🔹 Nombres
              TextFormField(
                controller: nombrePplController,
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
        
              // 🔹 Número de Documento (Validación: 8 o 10 dígitos)
              TextFormField(
                controller: numeroDocumentoPplController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration('Número de Documento').copyWith(
                  counterText: "", // 🔥 Oculta el contador de caracteres
                ),
                maxLength: 10, // 🔥 Límite de caracteres (máximo 10)
                validator: _validarNumeroDocumento,
              ),
              const SizedBox(height: 15),
        
              // 🔹 Tipo de Documento (Dropdown)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: DropdownButtonFormField<String>(
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
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPplCentroReclusionLegalForm() {
    return Form(
      key: _formKeyLegalPPL, // 🔥 Clave de validación del formulario
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

              const Text(
                "Escribe el nombre de la ciudad para ver las opciones. Luego, haz clic en una para seleccionarla.",
                style: TextStyle(fontSize: 12),
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
                  // ✅ Se muestra solo cuando los datos están listos con validación
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      seleccionarCentroReclusion(),
                      const SizedBox(height: 10),
                      // 🔥 Validación: Verifica que se haya seleccionado un centro antes de enviar el formulario
                      if (selectedCentro == null || selectedCentro!.isEmpty)
                        const Text(
                          "⚠ Debes seleccionar un centro de reclusión.",
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
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

  Widget _buildPplInfoTDLegalForm() {
    return Form(
      key: _formKeyInfoTdPPL,
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
                decoration: _buildInputDecoration('TD'),
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

              // 🔹 NUI - Solo números, longitud específica
              TextFormField(
                controller: nuiPplController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration('NUI'),
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

              // 🔹 PATIO - Campo obligatorio
              TextFormField(
                controller: patioPplController,
                keyboardType: TextInputType.text,
                decoration: _buildInputDecoration('Patio'),
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

  Widget _buildCuentaCorreoForm() {
    return Form(
      key: _formKeyCorreo,
      autovalidateMode: AutovalidateMode.onUserInteraction, // 🔥 Muestra errores en tiempo real
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Genial, información completa",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "¡Ahora vamos\na crear tu cuenta!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1),
              ),
              const SizedBox(height: 20),
        
              // 🔥 Alerta de información
              const Row(
                children: [
                  Icon(Icons.mark_email_read, color: Colors.amber, size: 40),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Por favor ingresa un correo electrónico válido, que esté activo y al cual tengas acceso, ya que allí "
                          "se te estará enviando toda la información relacionada con el PPL.",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
        
              // 🔹 Correo Electrónico
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  floatingLabelBehavior: FloatingLabelBehavior.always, // 🔥 Mantiene el título arriba
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder( // 🔥 Borde gris por defecto
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder( // 🔥 Borde azul cuando está seleccionado
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder( // 🔥 Borde rojo cuando hay error
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa un correo electrónico';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Por favor ingresa un correo electrónico válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
        
              // 🔹 Confirmar Correo Electrónico
              TextFormField(
                controller: emailConfirmarController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Confirmar Correo Electrónico',
                  floatingLabelBehavior: FloatingLabelBehavior.always, // 🔥 Mantiene el título arriba
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder( // 🔥 Borde gris por defecto
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder( // 🔥 Borde azul cuando está seleccionado
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder( // 🔥 Borde rojo cuando hay error
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor confirma tu correo electrónico';
                  }
                  if (value != emailController.text) {
                    return 'Los correos electrónicos no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCuentapasawordForm() {
    return Form(
      key: _formKeyPassword,
      autovalidateMode: AutovalidateMode.onUserInteraction, // 🔥 Muestra errores en tiempo real
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Último paso",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1),
              ),
              const SizedBox(height: 20),

              // 🔹 Mensaje de seguridad
              const Row(
                children: [
                  Icon(Icons.lock, color: Colors.amber, size: 40),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Ten en cuenta que la contraseña que vas a crear debe tener mínimo 6 caracteres. "
                          "Por la seguridad de tus datos, no la compartas con nadie.",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 🔹 Contraseña
              TextFormField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Crear una Contraseña',
                  floatingLabelBehavior: FloatingLabelBehavior.always, // 🔥 Mantiene el título arriba
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
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa una contraseña';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // 🔹 Confirmar Contraseña
              TextFormField(
                controller: passwordConfirmarController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  floatingLabelBehavior: FloatingLabelBehavior.always, // 🔥 Mantiene el título arriba
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
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor confirma tu contraseña';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  if (value != passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    final String password = passwordController.text.trim();
    final String passwordConfirm = passwordConfirmarController.text.trim();

    // 🔹 Si ambos campos están vacíos
    if (password.isEmpty && passwordConfirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor ingresa una contraseña y la confirmación."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 🔹 Si solo la contraseña está vacía
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor crea una contraseña."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 🔹 Si solo la confirmación está vacía
    if (passwordConfirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor confirma la contraseña."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 🔹 Si la contraseña tiene menos de 6 caracteres
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("La contraseña debe tener al menos 6 caracteres."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 🔹 Si la confirmación tiene menos de 6 caracteres
    if (passwordConfirm.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("La confirmación debe tener al menos 6 caracteres."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 🔹 Verifica si las contraseñas coinciden
    if (password != passwordConfirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Las contraseñas no coinciden."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 🔥 **Si todas las validaciones pasan, intenta registrar al usuario**
    try {
      print('✅ Iniciando el proceso de registro...');

      // 🔹 Muestra un indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 🔹 Obtiene los datos ingresados por el usuario
      String email = emailController.text.trim();

      // 🔹 Registra el usuario en Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 🔹 Obtiene el UID del usuario registrado
      String userId = userCredential.user!.uid;
      print('✅ Usuario registrado con UID: $userId');

      // 🔹 Crea un mapa con los datos del usuario
      Map<String, dynamic> userData = {
        "id": userId,
        "nombreAcudiente": nombreAcudienteController.text.trim(),
        "apellidoAcudiente": apellidoAcudienteController.text.trim(),
        "parentescoRepresentante": parentesco ?? "",
        "celular": celularController.text.trim(),
        "email": email,
        "nombrePpl": nombrePplController.text.trim(),
        "apellidoPpl": apellidoPplController.text.trim(),
        "tipoDocumentoPpl": tipoDocumento ?? "",
        "numeroDocumentoPpl": numeroDocumentoPplController.text.trim(),
        "regional": selectedRegional ?? "",
        "centroReclusion": selectedCentro ?? "",
        "td": tdPplController.text.trim(),
        "nui": nuiPplController.text.trim(),
        "patio": patioPplController.text.trim(),
        "status": "registrado",
        "isNotificatedActivated": false,
        "isPaid": false,
        "assignedTo": "",
        "fechaRegistro": DateTime.now(),
      };

      // 🔹 Guarda los datos en Firestore
      await FirebaseFirestore.instance.collection("Ppl").doc(userId).set(userData);
      print('✅ Datos guardados en Firestore correctamente.');

      // 🔹 Cierra el indicador de carga
      Navigator.of(context).pop();

      // 🔹 Muestra un mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registro completado con éxito."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // 🔹 Redirige a la página de confirmación
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => EstamosValidandoPage()), // 🚀 Ajusta con tu página de validación
      );

    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop(); // Cierra el indicador de carga
      print('❌ Error en FirebaseAuth: ${e.code}');
      _mostrarMensaje(_traducirErrorFirebase(e.code));
    } catch (e) {
      Navigator.of(context).pop(); // Cierra el indicador de carga
      print('❌ Error en el proceso de registro: $e');
      _mostrarMensaje('Error al registrar el usuario: $e');
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
  void _validarYContinuar() {
    // Validación de Acudiente en la página 1
    if (_currentPage == 1 && !_formKeyAcudiente.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor completa todos los campos del acudiente antes de continuar."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Validación de PPL en la página 2
    if (_currentPage == 2 && !_formKeyPPL.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor completa todos los datos del PPL antes de continuar."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 🔥 Nueva Validación: Centro de Reclusión en la página 3
    if (_currentPage == 3) {
      if (!_formKeyLegalPPL.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Por favor selecciona un Centro de Reclusión antes de continuar."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (selectedCentro == null || selectedCentro!.isEmpty) {
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
    // Validación de identificacion interna en la página 4
    if (_currentPage == 4 && !_formKeyInfoTdPPL.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor completa todos los datos antes de continuar."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    // Validación de email en la página 5
    if (_currentPage == 5) {
      final String email = emailController.text.trim();
      final String emailConfirmacion = emailConfirmarController.text.trim();
      final RegExp emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

      // 🔹 Verifica que ningún campo esté vacío
      if (email.isEmpty || emailConfirmacion.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(email.isEmpty && emailConfirmacion.isEmpty
                ? "Por favor ingresa un correo y la confirmación."
                : email.isEmpty
                ? "Por favor ingresa un correo."
                : "Por favor ingresa el correo de confirmación."),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      // 🔹 Validación del formato del correo
      if (!emailRegExp.hasMatch(email) || !emailRegExp.hasMatch(emailConfirmacion)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!emailRegExp.hasMatch(email)
                ? "Por favor ingresa un correo válido."
                : "El correo de confirmación no es válido."),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      // 🔹 Verifica que los correos coincidan exactamente
      if (email.toLowerCase() != emailConfirmacion.toLowerCase()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Los correos electrónicos no coinciden."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    if (_currentPage == 6) { // Página donde está el formulario de contraseña
      final String password = passwordController.text.trim();
      final String passwordConfirm = passwordConfirmarController.text.trim();

      // 🔹 Si ambos campos están vacíos
      if (password.isEmpty && passwordConfirm.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Por favor crea una contraseña y la confirmación."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // 🔹 Si solo la contraseña está vacía
      if (password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Por favor crea una contraseña."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // 🔹 Si solo la confirmación está vacía
      if (passwordConfirm.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Por favor confirma la contraseña."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // 🔹 Si la contraseña tiene menos de 6 caracteres
      if (password.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("La contraseña debe tener al menos 6 caracteres."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // 🔹 Si la confirmación tiene menos de 6 caracteres
      if (passwordConfirm.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("La confirmación debe tener al menos 6 caracteres."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // 🔹 Verifica si las contraseñas coinciden
      if (password != passwordConfirm) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Las contraseñas no coinciden."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }
    // Avanzar solo si todas las validaciones se cumplen
    if (_currentPage < 7) { // Ajusta el número máximo de páginas si es necesario
      setState(() {
        _currentPage++;
      });
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
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
    print("Ejecutando _fetchTodosCentrosReclusion 🚀");

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

      // 🔥 Ver los datos cargados en la consola antes de actualizar el estado
      print("✅ Centros de reclusión obtenidos: ${fetchedTodosCentros.length}");
      for (var centro in fetchedTodosCentros) {
        print("🔹 Centro: ${centro['nombre']} - Regional: ${centro['regional']}");
      }

      // 🔥 Solo actualiza el estado si los datos han cambiado
      if (centrosReclusionTodos.isEmpty || fetchedTodosCentros.length != centrosReclusionTodos.length) {
        setState(() {
          centrosReclusionTodos = fetchedTodosCentros;
        });
      }

      print("✅ Centros de reclusión cargados correctamente en la UI.");
      return true;
    } catch (e) {
      print("❌ Error al obtener centros de reclusión: $e");
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
