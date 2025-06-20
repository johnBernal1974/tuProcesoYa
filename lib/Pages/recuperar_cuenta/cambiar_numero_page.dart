import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../src/colors/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

class CambiarNumeroPage extends StatefulWidget {
  final String userId; // UID o ID del documento del usuario

  const CambiarNumeroPage({super.key, required this.userId});

  @override
  State<CambiarNumeroPage> createState() => _CambiarNumeroPageState();
}

class _CambiarNumeroPageState extends State<CambiarNumeroPage> {
  final TextEditingController celularController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  String? _verificationId;
  bool _otpEnviado = false;
  bool _loading = false;
  int _segundosRestantes = 30;
  Timer? _timer;

  void _iniciarTemporizador() {
    _segundosRestantes = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _segundosRestantes--;
        if (_segundosRestantes <= 0) {
          timer.cancel();
        }
      });
    });
  }


  @override
  void dispose() {
    _timer?.cancel(); // 👈 Cancelamos el Timer al salir de la pantalla
    celularController.dispose();
    otpController.dispose();
    super.dispose();
  }

  void _enviarOTP() async {
    final celular = celularController.text.trim();

    if (celular.length != 10 || !RegExp(r'^\d{10}$').hasMatch(celular)) {
      _mostrarMensaje("Ingresa un número válido de 10 dígitos.");
      return;
    }

    if (mounted) setState(() => _loading = true);

    try {
      // 🔥 Solo usamos signInWithPhoneNumber directo
      final confirmationResult = await FirebaseAuth.instance.signInWithPhoneNumber("+57$celular");

      if (!mounted) return;
      setState(() {
        _verificationId = confirmationResult.verificationId;
        _otpEnviado = true;
        _loading = false;
      });
      _iniciarTemporizador();
      _mostrarMensaje("Código enviado correctamente.");
    } catch (e) {
      _mostrarMensaje("Error inesperado: ${e.toString()}");
      setState(() => _loading = false);
    }
  }



  void _verificarOTP() async {
    final codigo = otpController.text.trim();

    if (_verificationId == null || codigo.isEmpty) {
      _mostrarMensaje("Código inválido.");
      return;
    }

    setState(() => _loading = true); // 👈 Activar el loader

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: codigo,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final nuevoUID = userCredential.user?.uid;

      if (nuevoUID == null) {
        _mostrarMensaje("No se pudo obtener el nuevo UID.");
        return;
      }

      final originalDocRef = FirebaseFirestore.instance.collection('Ppl').doc(widget.userId);
      final newDocRef = FirebaseFirestore.instance.collection('Ppl').doc(nuevoUID);

      final originalSnapshot = await originalDocRef.get();
      if (!originalSnapshot.exists) {
        _mostrarMensaje("El usuario original no existe.");
        return;
      }

      final data = originalSnapshot.data();
      data?['celular'] = celularController.text.trim();
      data?['id'] = nuevoUID;

      await newDocRef.set(data!);
      await copiarYEliminarSubcolecciones(widget.userId, nuevoUID);

      // 🔹 Registrar en historial_acciones
      await FirebaseFirestore.instance
          .collection('Ppl')
          .doc(nuevoUID)
          .collection('historial_acciones')
          .add({
        'accion': 'Cambio de celular',
        'admin': 'Hecha por el mismo usuario',
        'fecha': FieldValue.serverTimestamp(),
      });

      await originalDocRef.delete();

      await eliminarUsuarioAnteriorHttp(widget.userId);

      _mostrarMensaje("✅ Número de celular actualizado.");

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, 'home', (_) => false);
      }
    } catch (e) {
      _mostrarMensaje("Error inesperado: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _loading = false); // 👈 Desactivar el loader
    }
  }


  Future<void> eliminarUsuarioAnteriorHttp(String uid) async {
    try {
      final url = Uri.parse("https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/eliminarUsuarioAuthHttp");
      final response = await http.post(url, body: {
        "uid": uid,
        "token": "clave-super-secreta-123", // 👈 Reemplaza esto por un valor seguro y privado
      });

      if (response.statusCode == 200) {
        print("✅ Usuario anterior eliminado vía HTTP");
      } else {
        print("⚠️ Error al eliminar usuario anterior: ${response.body}");
      }
    } catch (e) {
      print("❌ Error al llamar a la función HTTP: $e");
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white, size: 30),
        backgroundColor: primary,
        centerTitle: true,
        title: const Text("Actualizar celular", style: TextStyle(color: Colors.white)),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 15),
              const Text("Ingresa a continuación tu nuevo número de celular"),
              const SizedBox(height: 20),
              TextField(
                controller: celularController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: "Nuevo número de celular",
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
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 20),
              if (_otpEnviado)
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: "Código de verificación",
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
                    prefixIcon: const Icon(Icons.sms),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  elevation: _loading ? 0 : 4,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _loading
                    ? null
                    : (_otpEnviado ? _verificarOTP : _enviarOTP),
                child: AnimatedOpacity(
                  opacity: _loading ? 0.6 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: _loading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    _otpEnviado ? "Verificar código" : "Solicitar código",
                    style: const TextStyle(color: blanco),
                  ),
                ),
              ),
              const SizedBox(height: 12), // 👈 espacio entre botón y el texto de reenvío
              if (_otpEnviado && _segundosRestantes <= 0)
                TextButton(
                  onPressed: _enviarOTP,
                  child: const Text("Reenviar código"),
                )
              else if (_otpEnviado)
                Text(
                  "Puedes reenviar el código en $_segundosRestantes segundos",
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> copiarYEliminarSubcolecciones(String originalUID, String nuevoUID) async {
    final firestore = FirebaseFirestore.instance;
    final subcolecciones = [
      'seguimiento',
      'redenciones',
      'historial_acciones',
      'estadias',
      'comentarios',
      'correos_centro_reclusion',
      'eventos'
    ];

    for (String subcoleccion in subcolecciones) {
      final originalSubcolRef = firestore.collection('Ppl').doc(originalUID).collection(subcoleccion);
      final newSubcolRef = firestore.collection('Ppl').doc(nuevoUID).collection(subcoleccion);

      final snapshots = await originalSubcolRef.get();

      if (snapshots.docs.isNotEmpty) {
        for (final doc in snapshots.docs) {
          await newSubcolRef.doc(doc.id).set(doc.data());      // ✅ Copia el documento
          await originalSubcolRef.doc(doc.id).delete();        // ✅ Elimina el original
        }
      }
    }
  }

}
