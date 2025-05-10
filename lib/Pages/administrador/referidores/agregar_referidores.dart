import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../commons/drop_depatamentos_municipios.dart';
import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';

class RegistrarReferidorPage extends StatefulWidget {
  const RegistrarReferidorPage({super.key});

  @override
  State<RegistrarReferidorPage> createState() => _RegistrarReferidorPageState();
}

class _RegistrarReferidorPageState extends State<RegistrarReferidorPage> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _identificacionController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  String? _departamentoSeleccionado;
  String? _ciudadSeleccionada;
  String? _codigoGenerado;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _obtenerCodigoSiguiente();
  }

  Future<void> _obtenerCodigoSiguiente() async {
    final snapshot = await FirebaseFirestore.instance.collection("referidores").get();
    final codigos = snapshot.docs.map((doc) => int.tryParse(doc['codigo'] ?? '0') ?? 0).toList();
    codigos.sort();
    setState(() {
      _codigoGenerado = (codigos.isNotEmpty ? codigos.last + 1 : 101).toString();
    });
  }

  Future<void> _guardarReferidor() async {
    if (_nombreController.text.isEmpty || _identificacionController.text.isEmpty || _celularController.text.isEmpty || _ciudadSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Completa todos los campos")));
      return;
    }

    setState(() => _guardando = true);

    final nuevoRef = {
      "nombre": _nombreController.text.trim(),
      "identificacion": _identificacionController.text.trim(),
      "celular": _celularController.text.trim(),
      "ciudad": _ciudadSeleccionada!,
      "codigo": _codigoGenerado,
      "totalReferidos": 0,
    };

    await FirebaseFirestore.instance.collection("referidores").add(nuevoRef);

    // 🔄 Limpiar campos
    _nombreController.clear();
    _identificacionController.clear();
    _celularController.clear();
    setState(() {
      _departamentoSeleccionado = null;
      _ciudadSeleccionada = null;
    });

    // 🆕 Generar nuevo código
    await _obtenerCodigoSiguiente();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Referidor registrado con éxito")));
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: "Registrar Referidor",
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_codigoGenerado != null)
                  Text("Código asignado: $_codigoGenerado", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

                const SizedBox(height: 20),
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: "Nombre",
                    floatingLabelBehavior: FloatingLabelBehavior.always, // 👈 siempre visible
                    labelStyle: TextStyle(color: Colors.grey), // Color del título
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _identificacionController,
                  decoration: const InputDecoration(
                    labelText: "Identificación",
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _celularController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Celular",
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                DepartamentosMunicipiosWidget(
                  departamentoSeleccionado: _departamentoSeleccionado,
                  municipioSeleccionado: _ciudadSeleccionada,
                  onSelectionChanged: (departamento, municipio) {
                    _departamentoSeleccionado = departamento;
                    _ciudadSeleccionada = municipio;
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardarReferidor,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _guardando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Guardar Referidor", style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
