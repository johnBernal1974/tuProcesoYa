import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../src/colors/colors.dart';
import 'cambiar_numero_page.dart'; // Asegúrate de importar tus colores aquí

class RecuperarCuentaPage extends StatefulWidget {
  const RecuperarCuentaPage({Key? key}) : super(key: key);

  @override
  _RecuperarCuentaPageState createState() => _RecuperarCuentaPageState();
}

class _RecuperarCuentaPageState extends State<RecuperarCuentaPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController documentoController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  bool _loading = false;
  bool _obscurePin = true;

  void _verificarPin() async {
    if (!_formKey.currentState!.validate()) return;

    final documento = documentoController.text.trim();
    final pin = pinController.text.trim();

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

      final userDoc = query.docs.first;
      final userData = userDoc.data();
      final hashedPinIngresado = sha256.convert(utf8.encode(pin)).toString();

      if (userData['pin_respaldo'] == hashedPinIngresado) {
        _mostrarMensaje("✅ PIN correcto. Puedes continuar con la recuperación.");

        // 👇 Redirigir a la página para cambiar número
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CambiarNumeroPage(userId: userDoc.id),
            ),
          );
        });

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white, size: 30),
          title: const Text("Recuperar cuenta",
              style: TextStyle(color: Colors.white))),
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600), // Limita el ancho máximo
          padding: const EdgeInsets.all(20.0), // Agrega espacio alrededor del contenido
          child: Column(
            children: [
              const Text("Para recuperar tu cuenta debes ingresar el número del documento del Ppl y la clave de 4 digitos que guardaste en el registro",
              style: TextStyle(height: 1.1)),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // CAMPO DE DOCUMENTO
                      TextFormField(
                        controller: documentoController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Número de documento del Ppl",
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelStyle: const TextStyle(color: gris),
                          floatingLabelStyle: const TextStyle(color: primary, fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: gris, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: gris, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: primary, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          prefixIcon: const Icon(Icons.badge),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "El número de documento es obligatorio";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // CAMPO DE PIN
                      TextFormField(
                        controller: pinController,
                        obscureText: _obscurePin,
                        maxLength: 4,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "PIN de respaldo",
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelStyle: const TextStyle(color: gris),
                          floatingLabelStyle: const TextStyle(color: primary, fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: gris, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: gris, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: primary, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                _obscurePin = !_obscurePin;
                              });
                            },
                            child: Icon(
                              _obscurePin ? Icons.visibility : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "El PIN es obligatorio";
                          }
                          if (value.length != 4) {
                            return "El PIN debe tener 4 dígitos";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 30),

                      // BOTÓN DE VERIFICACIÓN
                      SizedBox(
                        width: 300,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: primary,
                          ),
                          onPressed: _loading ? null : _verificarPin,
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                            "Verificar PIN",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
