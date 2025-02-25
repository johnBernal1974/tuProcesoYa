import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminProvider {
  static final AdminProvider _instance = AdminProvider._internal();
  factory AdminProvider() => _instance;
  AdminProvider._internal();

  String? adminName;
  String? adminApellido;
  String? adminFullName;
  String? rol;
  bool isLoading = false;

  // Método para verificar si el usuario es admin
  Future<bool> isUserAdmin(String uid) async {
    try {
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admin')
          .doc(uid)
          .get();

      if (adminDoc.exists) {
        // Actualizamos el rol desde el nodo 'rol'
        rol = adminDoc['rol'] ?? 'user';
      }
      return adminDoc.exists;
    } catch (e) {
      print("❌ Error verificando admin: $e");
      return false;
    }
  }

  // Método para cargar el nombre y apellido del admin
  Future<void> loadAdminData() async {
    if ((adminName != null && adminApellido != null && rol != null) || isLoading) return;
    isLoading = true;

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        adminName = '';
        adminApellido = '';
        adminFullName = '';
        rol = '';
        isLoading = false;
        return;
      }

      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admin')
          .doc(user.uid)
          .get();

      if (adminDoc.exists) {
        adminName = adminDoc['name'] ?? '';
        adminApellido = adminDoc['apellidos'] ?? '';
        adminFullName = "$adminName $adminApellido".trim();
        rol = adminDoc['rol'] ?? '';
      } else {
        adminName = '';
        adminApellido = '';
        adminFullName = '';
        rol = '';
      }
    } catch (e) {
      print("❌ Error cargando datos del admin: $e");
      adminName = '';
      adminApellido = '';
      adminFullName = '';
      rol = '';
    }

    isLoading = false;
  }

  // Método para resetear los datos cuando se cierre sesión
  void reset() {
    adminName = null;
    adminApellido = null;
    adminFullName = null;
    rol = null;
  }
}
