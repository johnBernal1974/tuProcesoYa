import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tuprocesoya/providers/ppl_provider.dart';
import '../models/ppl.dart';
import '../src/colors/colors.dart';

class MyAuthProvider {
  late FirebaseAuth _firebaseAuth;

  MyAuthProvider() {
    _firebaseAuth = FirebaseAuth.instance;
  }

  BuildContext? get context => null;

  Future<bool> login(String email, String password, BuildContext context) async {
    String? errorMessage;

    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (error) {
      print('Error: ${error.code} \n ${error.message}');
      errorMessage = _getErrorMessage(error.code);
      showSnackbar(context, errorMessage);
      return false;
    }
    return true;
  }

  String _getErrorMessage(String errorCode) {
    Map<String, String> errorMessages = {
      'user-not-found': 'Usuario no encontrado. Verifica tu correo electrónico.',
      'wrong-password': 'Contraseña incorrecta. Inténtalo de nuevo.',
      'invalid-email': 'La dirección de correo electrónico no tiene el formato correcto.',
      'user-disabled': 'La cuenta de usuario ha sido deshabilitada.',
      'invalid-credential': 'Las credenciales proporcionadas no son válidas.',
      'network-request-failed': 'Sin señal. Revisa tu conexión de INTERNET.',
    };

    return errorMessages[errorCode] ?? 'Error desconocido';
  }

  void showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontSize: 16),
      ),
      backgroundColor: rojo,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  User? getUser() {
    return _firebaseAuth.currentUser;
  }

  void checkIfUserIsLogged(BuildContext? context, PplProvider pplProvider) {
    if (context != null) {
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user != null) {
          print('El usuario está logueado');

          Ppl? ppl = await pplProvider.getById(user.uid);
          if (ppl != null) {
            String? verificationStatus = await pplProvider.getVerificationStatus(user.uid);
            if (verificationStatus == 'procesando') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('En este momento no tienes acceso a esta cuenta')),
              );
              return;
            } else if (verificationStatus == 'registrado') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cuenta registrada, pero aún no está activa')),
              );
              return;
            } else if (verificationStatus == 'activado') {
              Navigator.pushNamedAndRemoveUntil(context, 'general_page', (route) => false);
              return;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Estado desconocido: $verificationStatus')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Este usuario no es válido')),
            );
            await signOut();
          }
        } else {
          Navigator.pushNamedAndRemoveUntil(context, "login", (route) => false);
          print('El usuario NO está logueado');
        }
      });
    }
  }

  Future<bool> signUp(String email, String password) async {
    String? errorMessage;

    try {
      await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (error) {
      errorMessage = error.code;
      print('ErrorMessage: $errorMessage');
      rethrow;
    }
    return true;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<String> getTypeUser() async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      throw Exception('Usuario no logueado');
    }

    final firestore = FirebaseFirestore.instance;
    final userDoc = await firestore.collection('Ppl').doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('Usuario no encontrado');
    }

    final userData = userDoc.data();
    if (userData == null) {
      throw Exception('Datos del usuario no encontrados');
    }

    final typeUser = userData['typeUser'];
    if (typeUser == null) {
      throw Exception('typeUser del usuario no encontrado');
    }

    return typeUser;
  }
}
