import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tuprocesoya/src/colors/colors.dart';

import '../client/register/register.dart';

class ValidarCodigoPage extends StatefulWidget {
  const ValidarCodigoPage({super.key});

  @override
  State<ValidarCodigoPage> createState() => _ValidarCodigoPageState();
}

class _ValidarCodigoPageState extends State<ValidarCodigoPage> {
  final TextEditingController _codigoController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verificarYCanjearCodigo() async {
    String codigoIngresado = _codigoController.text.trim();

    if (codigoIngresado.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El código debe tener 6 dígitos.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final docRef = FirebaseFirestore.instance.collection('codigos_acceso').doc(codigoIngresado);

      // 1. Consultamos el documento de forma directa
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        throw "El código ingresado no es válido.";
      }

      final data = snapshot.data() as Map<String, dynamic>;
      if (data['usado'] == true) {
        throw "Este código ya fue utilizado anteriormente.";
      }

      // 2. Si pasa las validaciones, lo marcamos como usado inmediatamente
      await docRef.update({
        'usado': true,
        'fechaUso': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // 3. Redirigir a la página de registro pasando el código ingresado
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RegistroPage(codigoIngresado: codigoIngresado),
        ),
      );

    } catch (e) {
      if (!mounted) return;

      // Limpiamos cualquier texto técnico para mostrar el mensaje exacto
      String mensajeError = e.toString().replaceAll("Exception: ", "").replaceAll("ClientException: ", "");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeError),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primary, // 👈 Color primary en el AppBar
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // 👈 Flecha de atrás en blanco
        title: const Text(
          "Ingresar Código de Acceso",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView( // 👈 Permite desplazamiento vertical desde arriba
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  Image.asset(
                    'assets/images/logo_tu_proceso_ya_transparente.png',
                    height: isMobile ? 40 : 70,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      border: Border.all(color: Colors.orange.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                            SizedBox(width: 6),
                            Text(
                              "Aviso importante",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent, fontSize: 13),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          "• Este código de acceso sirve para un único uso.\n"
                              "• No salgas de la página de registro ni la recargues hasta haberlo terminado en su totalidad.",
                          style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Por favor, introduce el código de 6 dígitos que recibiste tras realizar tu pago para continuar con el registro.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _codigoController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 4),
                    decoration: InputDecoration(
                      labelText: "Código de 6 dígitos",
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      // 👈 Borde gris fijo en todos los estados
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isLoading ? null : _verificarYCanjearCodigo,
                      child: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Text("Validar Código", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}