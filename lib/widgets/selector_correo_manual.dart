import 'package:flutter/material.dart';

class SelectorCorreoManualFlexible extends StatefulWidget {
  final String? entidadSeleccionada; // Dinámicamente cambia entre JEP o JDC
  final void Function(String correo, String entidad)? onCorreoValidado;

  const SelectorCorreoManualFlexible({
    super.key,
    required this.entidadSeleccionada,
    this.onCorreoValidado,
  });

  @override
  State<SelectorCorreoManualFlexible> createState() => _SelectorCorreoManualFlexibleState();
}

class _SelectorCorreoManualFlexibleState extends State<SelectorCorreoManualFlexible> {
  final TextEditingController _correoController = TextEditingController();
  bool _correoValido = false;

  @override
  void initState() {
    super.initState();
    _correoController.addListener(_validarCorreo);
  }

  void _validarCorreo() {
    final texto = _correoController.text.trim();
    final esValido = _esCorreoValido(texto);

    if (esValido != _correoValido) {
      setState(() => _correoValido = esValido);
    }

    // ✅ Solo actualiza si el correo es válido (no borra entidad nunca)
    if (_correoValido && widget.entidadSeleccionada != null) {
      widget.onCorreoValidado?.call(
        _correoController.text.trim(),
        widget.entidadSeleccionada!,
      );
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
    final entidad = widget.entidadSeleccionada ?? 'Entidad no seleccionada';

    return Card(
      color: Colors.white,
      elevation: 3,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
            const SizedBox(height: 8),

            TextField(
              controller: _correoController,
              decoration: InputDecoration(
                labelText: 'Correo electrónico alternativo',
                hintText: 'correo@ejemplo.com',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey, width: 2),
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
                      "Entidad usada al enviar: $entidad",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
