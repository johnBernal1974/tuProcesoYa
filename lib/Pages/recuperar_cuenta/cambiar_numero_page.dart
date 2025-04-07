import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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



  void _enviarOTP() async {
    final celular = celularController.text.trim();

    if (celular.length != 10 || !RegExp(r'^\d{10}$').hasMatch(celular)) {
      _mostrarMensaje("Ingresa un número válido de 10 dígitos.");
      return;
    }

    setState(() => _loading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: "+57$celular",
      timeout: const Duration(seconds: 60),
      verificationCompleted: (_) {},
      verificationFailed: (error) {
        _mostrarMensaje("Error: ${error.message}");
        setState(() => _loading = false);
      },
      codeSent: (verificationId, resendToken) {
        setState(() {
          _verificationId = verificationId;
          _otpEnviado = true;
          _loading = false;
        });
        _iniciarTemporizador();
        _mostrarMensaje("Código enviado.");
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }


  void _verificarOTP() async {
    final codigo = otpController.text.trim();

    if (_verificationId == null || codigo.isEmpty) {
      _mostrarMensaje("Código inválido.");
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: codigo,
      );

      // Verifica el OTP (esto lanza excepción si es inválido)
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Si el OTP fue válido, actualizamos en Firestore
      final celular = celularController.text.trim();
      await FirebaseFirestore.instance.collection('Ppl').doc(widget.userId).update({
        'celular': celular,
      });

      _mostrarMensaje("✅ Número actualizado exitosamente.");
      if (context.mounted) Navigator.of(context).pop(); // Puedes redirigir si lo deseas
    } on FirebaseAuthException catch (_) {
      _mostrarMensaje("Código inválido o expirado.");
    } catch (e) {
      _mostrarMensaje("Error inesperado: ${e.toString()}");
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Actualizar número de celular")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: celularController,
              decoration: const InputDecoration(labelText: "Nuevo número de celular"),
              keyboardType: TextInputType.phone,
              maxLength: 10,
            ),
            const SizedBox(height: 20),
            if (_otpEnviado)
              TextField(
                controller: otpController,
                decoration: const InputDecoration(labelText: "Código OTP"),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : _otpEnviado
                  ? _verificarOTP
                  : _enviarOTP,
              child: Text(_otpEnviado ? "Verificar código" : "Enviar OTP"),
            ),
            if (_otpEnviado && _segundosRestantes <= 0)
              TextButton(
                onPressed: _enviarOTP,
                child: const Text("Reenviar código"),
              )
            else if (_otpEnviado)
              Text("Puedes reenviar el código en $_segundosRestantes segundos", style: const TextStyle(fontSize: 12)),

          ],
        ),
      ),
    );
  }
}
