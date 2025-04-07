import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class RecuperarCuentaPage extends StatefulWidget {
  const RecuperarCuentaPage({Key? key}) : super(key: key);

  @override
  _RecuperarCuentaPageState createState() => _RecuperarCuentaPageState();
}

class _RecuperarCuentaPageState extends State<RecuperarCuentaPage> {
  final TextEditingController documentoController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  bool _loading = false;

  void _verificarPin() async {
    final documento = documentoController.text.trim();
    final pin = pinController.text.trim();

    if (documento.isEmpty || pin.isEmpty) {
      _mostrarMensaje("Por favor llena todos los campos.");
      return;
    }

    setState(() => _loading = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('Ppl')
          .where('numero_documento_ppl', isEqualTo: documento)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _mostrarMensaje("No se encontró un usuario con ese documento.");
        setState(() => _loading = false);
        return;
      }

      final userData = query.docs.first.data();
      final hashedPinIngresado = sha256.convert(utf8.encode(pin)).toString();

      if (userData['pin_respaldo'] == hashedPinIngresado) {
        _mostrarMensaje("✅ PIN correcto. Puedes continuar con la recuperación.");

        // Aquí podrías redirigir al usuario a una pantalla para actualizar su número.
        // Ejemplo:
        // Navigator.push(context, MaterialPageRoute(builder: (_) => CambiarNumeroPage(userId: query.docs.first.id)));
      } else {
        _mostrarMensaje("El PIN no coincide.");
      }
    } catch (e) {
      _mostrarMensaje("Error: ${e.toString()}");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recuperar cuenta")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: documentoController,
              decoration: const InputDecoration(labelText: "Número de documento"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: pinController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "PIN de respaldo"),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _verificarPin,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text("Verificar PIN"),
            ),
          ],
        ),
      ),
    );
  }
}
