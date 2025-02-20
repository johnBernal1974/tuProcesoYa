import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminProvider {
  static final AdminProvider _instance = AdminProvider._internal();
  factory AdminProvider() => _instance;
  AdminProvider._internal();

  String? adminName;
  String? adminApellido;
  String? adminFullName; // Nuevo campo con el nombre completo
  bool isLoading = false;

  // Método para verificar si el usuario es admin
  Future<bool> isUserAdmin(String uid) async {
    try {
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admin')
          .doc(uid)
          .get();

      return adminDoc.exists; // Si el documento existe, es admin
    } catch (e) {
      print("❌ Error verificando admin: $e");
      return false;
    }
  }

  // Método para cargar el nombre y apellido del admin
  Future<void> loadAdminData() async {
    if ((adminName != null && adminApellido != null) || isLoading) return;
    isLoading = true;

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        adminName = '';
        adminApellido = '';
        adminFullName = '';
        isLoading = false;
        return;
      }

      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admin')
          .doc(user.uid)
          .get();

      if (adminDoc.exists) {
        adminName = adminDoc['name'] ?? ''; // Obtiene solo el nombre
        adminApellido = adminDoc['apellidos'] ?? ''; // Obtiene solo el apellido
        adminFullName = "$adminName $adminApellido".trim(); // Concatena nombre y apellido
      } else {
        adminName = '';
        adminApellido = '';
        adminFullName = '';
      }
    } catch (e) {
      print("❌ Error cargando datos del admin: $e");
      adminName = '';
      adminApellido = '';
      adminFullName = '';
    }

    isLoading = false;
  }

  // Método para resetear los datos cuando se cierre sesión
  void reset() {
    adminName = null;
    adminApellido = null;
    adminFullName = null;
  }
}
