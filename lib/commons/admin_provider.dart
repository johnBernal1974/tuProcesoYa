import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminProvider {
  static final AdminProvider _instance = AdminProvider._internal();
  factory AdminProvider() => _instance;
  AdminProvider._internal();

  String? adminName;
  bool isLoading = false;

  // Método para verificar si el usuario es admin
  Future<bool> isUserAdmin(String uid) async {
    try {
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admin') // Asegúrate de que esta colección existe en Firestore
          .doc(uid)
          .get();

      return adminDoc.exists; // Si el documento existe, es admin
    } catch (e) {
      print("❌ Error verificando admin: $e");
      return false;
    }
  }

  // Método para cargar el nombre del admin
  Future<void> loadAdminName() async {
    if (adminName != null || isLoading) return; // Evita recargar innecesariamente
    isLoading = true;

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        adminName = ''; // Usuario no autenticado, evita mostrar el CircularProgressIndicator
        isLoading = false;
        return;
      }

      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admin')
          .doc(user.uid)
          .get();

      if (adminDoc.exists) {
        adminName = adminDoc['name']; // Asegúrate de que en Firestore hay un campo "name"
      } else {
        adminName = ''; // Si el usuario no es admin, asigna una cadena vacía
      }
    } catch (e) {
      print("❌ Error cargando el nombre del admin: $e");
      adminName = ''; // Previene errores en la UI
    }

    isLoading = false;
  }

  // Método para resetear los datos cuando se cierre sesión
  void reset() {
    adminName = null;
  }
}
