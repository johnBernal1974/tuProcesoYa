import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../commons/drop_depatamentos_municipios.dart';
import '../../../src/colors/colors.dart';

class RegistroAsistidoPage extends StatefulWidget {
  const RegistroAsistidoPage({super.key});

  @override
  State<RegistroAsistidoPage> createState() => _RegistroAsistidoPageState();
}

class _RegistroAsistidoPageState extends State<RegistroAsistidoPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController nombreAcudienteController = TextEditingController();
  final TextEditingController apellidoAcudienteController = TextEditingController();
  final TextEditingController celularController = TextEditingController();
  final TextEditingController nombrePplController = TextEditingController();
  final TextEditingController apellidoPplController = TextEditingController();
  final TextEditingController numeroDocumentoPplController = TextEditingController();
  final TextEditingController tdPplController = TextEditingController();
  final TextEditingController nuiPplController = TextEditingController();
  final TextEditingController patioPplController = TextEditingController();
  final TextEditingController direccionPplController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  final TextEditingController centroReclusionController = TextEditingController();


  String? parentesco;
  String? tipoDocumento;
  String? situacionActual;
  String? departamentoSeleccionado;
  String? municipioSeleccionado;

  bool _mostrarPin = false;

  Future<bool>? _centrosFuture;
  String? selectedCentro;
  String? selectedRegional;
  List<Map<String, String>> centrosReclusionTodos = [];
  String? selectedCentroNombre;


  @override
  void initState() {
    super.initState();
    _centrosFuture = _fetchTodosCentrosReclusion();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text("Registro asistido", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_currentPage + 1) / 16),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: _buildPages(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(onPressed: _prevPage, child: const Text("Anterior")),
                  ElevatedButton(
                    onPressed: _currentPage == _buildPages().length - 1 ? _guardar : _nextPage,
                    child: Text(_currentPage == _buildPages().length - 1 ? "Finalizar" : "Siguiente"),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPages() {
    final List<Widget> pages = [];

    // 1. ACUDIENTE
    pages.addAll([
      _buildPageWrapper(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ACUDIENTE", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          _buildTextField("Nombres del acudiente", nombreAcudienteController),
        ],
      )),
      _buildPageWrapper(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ACUDIENTE", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          _buildTextField("Apellidos del acudiente", apellidoAcudienteController),
        ],
      )),
      _buildPageWrapper(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ACUDIENTE", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          _buildTextField("Celular del acudiente", celularController, tipo: TextInputType.phone),
        ],
      )),
      _buildPageWrapper(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ACUDIENTE", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          _buildDropdown("Parentesco", parentescoOptions, parentesco, (val) => setState(() => parentesco = val)),
        ],
      )),
    ]);

    // 2. PPL
    pages.addAll([
      _buildPageWrapper(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("PPL", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          _buildTextField("Nombres del PPL", nombrePplController),
        ],
      )),
      _buildPageWrapper(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("PPL", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          _buildTextField("Apellidos del PPL", apellidoPplController),
        ],
      )),
      _buildPageWrapper(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("PPL", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          _buildTextField("Número de documento del PPL", numeroDocumentoPplController, tipo: TextInputType.number),
        ],
      )),
      _buildPageWrapper(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("PPL", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          _buildDropdown("Tipo de documento", _tipoDocumentoOptions, tipoDocumento, (val) => setState(() => tipoDocumento = val)),
        ],
      )),
      _buildPageWrapper(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("PPL", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          _buildDropdown("Situación actual", _situacionOptions, situacionActual, (val) {
            setState(() {
              situacionActual = val;

            });
          }),
        ],
      )),
    ]);

    // 3. Según situación actual
    if (situacionActual == "En Reclusión") {
      pages.addAll([
        _buildCentroReclusionPage(),
        _buildIdentificacionInternaPage("TD (Tarjeta Decadactilar)", tdPplController),
        _buildIdentificacionInternaPage("NUI (Número Único de Identificación)", nuiPplController),
        _buildIdentificacionInternaPage("Patio No.", patioPplController),
      ]);
    } else if (situacionActual == "En Prisión domiciliaria" || situacionActual == "En libertad condicional") {
      pages.addAll([
        _buildPageWrapper(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("UBICACIÓN ACTUAL DEL PPL", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildDepartamentoMunicipio(),
          ],
        )),
        _buildPageWrapper(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("DIRECCIÓN", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildTextField("Dirección", direccionPplController),
          ],
        )),
      ]);
    }

    // 4. PIN de seguridad
    pages.add(_buildPageWrapper(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("SEGURIDAD", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildPinField(),
      ],
    )));

    return pages;
  }


  Widget _seleccionarCentroReclusion() {
    return Autocomplete<Map<String, String>>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable.empty();
        return centrosReclusionTodos.where((option) =>
            option['nombre']!.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      displayStringForOption: (option) => option['nombre']!,
      onSelected: (option) {
        setState(() {
          selectedCentro = option['id'];
          selectedCentroNombre = option['nombre']; // <- NUEVO
          selectedRegional = option['regional'];
        });
      },

      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: "Centro de reclusión",
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelStyle: TextStyle(color: Colors.black), // Título siempre visible en gris oscuro
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Material(
          elevation: 4,
          child: Container(
            color: Colors.amber[50],
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options.elementAt(index);
                return ListTile(
                  title: Text(option['nombre']!),
                  onTap: () => onSelected(option),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCentroReclusionPage() {
    return _buildPageWrapper(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CENTRO DE RECLUSIÓN", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
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
                            selectedCentroNombre ?? '',
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
        ],
      ),
    );
  }

  Widget _buildIdentificacionInternaPage(String label, TextEditingController controller) {
    return _buildPageWrapper(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("IDENTIFICACIÓN INTERNA", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildTextField(label, controller, tipo: TextInputType.number),
        ],
      ),
    );
  }


  Future<bool> _fetchTodosCentrosReclusion() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collectionGroup('centros_reclusion').get();

      centrosReclusionTodos = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'nombre': data['nombre']?.toString() ?? '',
          'regional': doc.reference.parent.parent?.id.toString() ?? '',
        };
      }).toList();

      return true;
    } catch (e) {
      print("Error al cargar centros de reclusión: $e");
      return false;
    }
  }



  Widget _buildPageWrapper(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    nombreAcudienteController.dispose();
    apellidoAcudienteController.dispose();
    celularController.dispose();
    nombrePplController.dispose();
    apellidoPplController.dispose();
    numeroDocumentoPplController.dispose();
    tdPplController.dispose();
    nuiPplController.dispose();
    patioPplController.dispose();
    direccionPplController.dispose();
    pinController.dispose();
    centroReclusionController.dispose(); // nuevo
    super.dispose();
  }

  Future<String?> crearUsuarioPorCelular(String celular) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('crearUsuarioPorCelular');
      final result = await callable.call(<String, dynamic>{
        'celular': celular,
      });

      final data = result.data;
      return data['uid'];
    } catch (e) {
      print("Error al crear usuario por celular: $e");
      return null;
    }
  }


  Widget _buildTextField(String label, TextEditingController controller, {TextInputType tipo = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        controller: controller,
        keyboardType: tipo,
        decoration: const InputDecoration().copyWith(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: const TextStyle(color: Colors.black),
          border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12), // 🔥 Este ajuste lo soluciona
        ),
      ),
    );
  }


  Widget _buildDropdown(String label, List<String> items, String? selected, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: DropdownButtonFormField<String>(
        dropdownColor: blanco,
        value: selected,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: const TextStyle(color: Colors.black), // Siempre visible en negro
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          border: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDepartamentoMunicipio() {
    return DepartamentosMunicipiosWidget(
      departamentoSeleccionado: departamentoSeleccionado,
      municipioSeleccionado: municipioSeleccionado,
      onSelectionChanged: (dep, mun) {
        setState(() {
          departamentoSeleccionado = dep;
          municipioSeleccionado = mun;
        });
      },
    );
  }

  Widget _buildPinField() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("PIN de respaldo", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: pinController,
              obscureText: !_mostrarPin,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: "PIN de 4 dígitos",
                floatingLabelBehavior: FloatingLabelBehavior.always,
                counterText: "", // Oculta el contador de caracteres
                suffixIcon: IconButton(
                  icon: Icon(
                    _mostrarPin ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() => _mostrarPin = !_mostrarPin);
                  },
                ),
                border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _validarPaginaActual() {
    switch (_currentPage) {
      case 0:
        return nombreAcudienteController.text.trim().isNotEmpty;
      case 1:
        return apellidoAcudienteController.text.trim().isNotEmpty;
      case 2:
        return celularController.text.trim().isNotEmpty;
      case 3:
        return parentesco != null;
      case 4:
        return nombrePplController.text.trim().isNotEmpty;
      case 5:
        return apellidoPplController.text.trim().isNotEmpty;
      case 6:
        return numeroDocumentoPplController.text.trim().isNotEmpty;
      case 7:
        return tipoDocumento != null;
      case 8:
        return situacionActual != null;
      case 9:
        if (situacionActual == "En Reclusión") {
          return selectedCentro != null;
        } else {
          return departamentoSeleccionado != null && municipioSeleccionado != null;
        }
      case 10:
        if (situacionActual == "En Reclusión") {
          return tdPplController.text.trim().isNotEmpty;
        } else {
          return direccionPplController.text.trim().isNotEmpty;
        }
      case 11:
        if (situacionActual == "En Reclusión") {
          return nuiPplController.text.trim().isNotEmpty;
        }
        return true;
      case 12:
        if (situacionActual == "En Reclusión") {
          return patioPplController.text.trim().isNotEmpty;
        }
        return true;
      case 13:
        return pinController.text.trim().length == 4;
      default:
        return true;
    }
  }

  void _nextPage() {
    if (!_validarPaginaActual()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor completa todos los campos obligatorios.")),
      );
      return;
    }

    final pages = _buildPages();
    if (_currentPage < pages.length - 1) {
      setState(() => _currentPage++);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }


  void _prevPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<bool> verificarSiNumeroExiste(String celular) async {
    final HttpsCallable callable =
    FirebaseFunctions.instance.httpsCallable('verificarNumeroExistente');
    final result = await callable.call(<String, dynamic>{'celular': celular});
    return result.data['existe'] == true;
  }



  void _guardar() async {
    final pin = pinController.text.trim();

    if (pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PIN inválido")),
      );
      return;
    }

    final celularRaw = celularController.text.trim();
    if (celularRaw.isEmpty || celularRaw.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Número de celular inválido")),
      );
      return;
    }

    final celular = celularRaw.startsWith('+') ? celularRaw : '+57$celularRaw';

    try {
      // ✅ Llamar a la Cloud Function solo después de validar
      final callable = FirebaseFunctions.instance.httpsCallable('crearUsuarioPorCelular');
      final result = await callable.call({'celular': celular});
      final userId = result.data['uid'];

      print("✅ Usuario creado con UID: $userId");

      await FirebaseFirestore.instance.collection("Ppl").doc(userId).set({
        "id": userId,
        "nombre_acudiente": nombreAcudienteController.text.trim(),
        "apellido_acudiente": apellidoAcudienteController.text.trim(),
        "parentesco_representante": parentesco ?? "",
        "celular": celular,
        "email": "",
        "nombre_ppl": nombrePplController.text.trim(),
        "apellido_ppl": apellidoPplController.text.trim(),
        "tipo_documento_ppl": tipoDocumento ?? "",
        "numero_documento_ppl": numeroDocumentoPplController.text.trim(),
        "regional": selectedRegional ?? "",
        "centro_reclusion": selectedCentro ?? "",
        "juzgado_ejecucion_penas": "",
        "juzgado_ejecucion_penas_email": "",
        "juzgado_que_condeno": "",
        "juzgado_que_condeno_email": "",
        "ciudad": municipioSeleccionado ?? "",
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
        "municipio": municipioSeleccionado ?? "",
        "situacion": situacionActual ?? "",
        "exento": false,
        "direccion": direccionPplController.text.trim(),
        "pin_respaldo": sha256.convert(utf8.encode(pin)).toString(),
        "referidoPor": "",
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registro exitoso")),
        );
        Navigator.of(context).pushReplacementNamed('home_admin');
      }
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'already-exists') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠ Este número ya está registrado.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: ${e.message ?? 'Error desconocido'}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Error inesperado al registrar.")),
      );
      print("Error inesperado: $e");
    }
  }


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
  final List<String> _tipoDocumentoOptions = ["Cédula de Ciudadanía", "Tarjeta de Identidad", "Pasaporte"];
  final List<String> _situacionOptions = ["En Reclusión", "En Prisión domiciliaria", "En libertad condicional"];
}
