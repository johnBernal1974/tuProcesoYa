import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/ppl.dart';

class PplProvider with ChangeNotifier {
  late CollectionReference _ref;
  bool _loading = false;
  late final List<Ppl> _pplList = [];

  PplProvider() {
    _ref = FirebaseFirestore.instance.collection('Ppl');

  }

  bool get isLoading => _loading;
  List<Ppl> get pplList => _pplList;

  void setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  /// Crear un nuevo registro
  Future<void> create(Ppl ppl) async {
    try {
      await _ref.doc(ppl.id).set(ppl.toJson());
      print('Usuario creado exitosamente');
    } catch (error) {
      print('Error al crear el Usuario: $error');
    }
  }

  Future<Ppl?> getById(String id) async {
    DocumentSnapshot document = await _ref.doc(id).get();
    if(document.exists){
      Ppl ppl= Ppl.fromJson(document.data() as Map<String, dynamic>);
      return ppl;
    }
    else{
      return null;
    }

  }

  Future<String?> getVerificationStatus(String uid) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot snapshot = await _ref.doc(user.uid).get();
        if (snapshot.exists) {
          Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;
          return userData['status'];
        }
      }
      return null;
    } catch (error) {
      print('Error al obtener el estado de verificación: $error');
      return null;
    }
  }

  /// Actualizar un registro existente
  Future<void> update(Map<String, dynamic> data, String id) async {
    try {
      await _ref.doc(id).update(data);
      print('Registro actualizado exitosamente');
    } catch (error) {
      print('Error al actualizar el registro: $error');
    }
  }

  /// Eliminar un registro
  Future<void> delete(String id) async {
    try {
      await _ref.doc(id).delete();
      print('Registro eliminado exitosamente');
    } catch (error) {
      print('Error al eliminar el registro: $error');
    }
  }
}
