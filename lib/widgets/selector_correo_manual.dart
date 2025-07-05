import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SelectorCorreoManualFlexible extends StatefulWidget {
  final String? entidadSeleccionada; // Este debe ser el JEP/JDC (no se toca)
  final void Function(String correo, String entidad)? onCorreoValidado;
  final void Function(String nombreCiudad)? onCiudadNombreSeleccionada;
  final void Function(String correo, String entidad)? onEnviarCorreoManual; // ✅

  final VoidCallback? onOmitir; // ✅ Nuevo callback para omitir

  const SelectorCorreoManualFlexible({
    super.key,
    required this.entidadSeleccionada,
    this.onCorreoValidado,
    this.onCiudadNombreSeleccionada,
    this.onEnviarCorreoManual,
    this.onOmitir,
  });

  @override
  State<SelectorCorreoManualFlexible> createState() => _SelectorCorreoManualFlexibleState();
}

class _SelectorCorreoManualFlexibleState extends State<SelectorCorreoManualFlexible> {
  final TextEditingController _correoController = TextEditingController();
  bool _correoValido = false;

  List<String> _ciudades = [];
  String? _ciudadSeleccionada;
  String? _nombreCiudadSeleccionada;

  @override
  void initState() {
    super.initState();
    _correoController.addListener(_validarCorreo);
    _cargarCiudadesDesdeFirestore();
  }

  Future<void> _cargarCiudadesDesdeFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('reparto').get();
    setState(() {
      _ciudades = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> _onSeleccionarCiudad(String ciudad) async {
    final doc = await FirebaseFirestore.instance.collection('reparto').doc(ciudad).get();
    final data = doc.data();
    if (data != null && data.containsKey('email')) {
      final email = data['email'];
      _correoController.text = email;
      _validarCorreo();
    }

    if (data != null && data.containsKey('nombre')) {
      widget.onCiudadNombreSeleccionada?.call(data['nombre']);
      setState(() {
        _nombreCiudadSeleccionada = data['nombre'];
      });
    }

    setState(() {
      _ciudadSeleccionada = ciudad;
    });
  }

  void _validarCorreo() {
    final texto = _correoController.text.trim();
    final esValido = _esCorreoValido(texto);

    if (esValido != _correoValido) {
      setState(() => _correoValido = esValido);
    }
  }

  bool _esCorreoValido(String correo) {
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return regex.hasMatch(correo);
  }

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entidad = widget.entidadSeleccionada ?? 'Señor(a) Juez';
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Card(
          color: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "¿Deseas ingresar un correo de reparto para el envío?",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 12),

                Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: Colors.white,
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _ciudadSeleccionada,
                    items: _ciudades.map((ciudad) {
                      return DropdownMenuItem(
                        value: ciudad,
                        child: Text(ciudad),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      labelText: "Ciudad de reparto",
                      filled: true,
                      fillColor: Colors.white,
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
                    onChanged: (value) {
                      if (value != null) {
                        _onSeleccionarCiudad(value);
                      }
                    },
                  ),
                ),

                if (_nombreCiudadSeleccionada != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Nombre del juzgado: $_nombreCiudadSeleccionada",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),

                TextField(
                  controller: _correoController,
                  decoration: InputDecoration(
                    labelText: 'Correo de reparto',
                    hintText: 'correo@ejemplo.com',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 13),
                ),

                const SizedBox(height: 8),
                Text(
                  _correoValido
                      ? "✅ Correo válido. Se enviará con la entidad seleccionada."
                      : "❌ El correo no es válido.",
                  style: TextStyle(
                    color: _correoValido ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.account_balance, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Entidad usada al enviar: ${_nombreCiudadSeleccionada ?? entidad}",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Botón de Enviar correo
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text("Enviar correo"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: !_correoValido
                        ? null
                        : () {
                      if (widget.onEnviarCorreoManual != null) {
                        final entidadEnviar = _nombreCiudadSeleccionada ?? widget.entidadSeleccionada ?? "Entidad no especificada";
                        widget.onEnviarCorreoManual!(
                          _correoController.text.trim(),
                          entidadEnviar,
                        );
                      }
                    },
                  ),
                ),

                const SizedBox(height: 8),
                // Botón Omitir este paso
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onOmitir?.call();
                    },
                    child: const Text("Omitir este paso"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
