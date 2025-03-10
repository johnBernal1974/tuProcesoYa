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
  bool _isLoading = false;

  /// 🔹 Retorna si el usuario actual es admin
  Future<bool> isUserAdmin(String uid) async {
    try {
      DocumentSnapshot adminDoc =
      await FirebaseFirestore.instance.collection('admin').doc(uid).get();

      if (adminDoc.exists) {
        rol = adminDoc['rol'] ?? 'user';
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Error verificando admin: $e");
      return false;
    }
  }

  /// 🔹 Carga los datos del administrador autenticado
  Future<void> loadAdminData() async {
    if (_isLoading || (adminName != null && adminApellido != null && rol != null)) return;

    _isLoading = true;
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        reset();
        return;
      }

      DocumentSnapshot adminDoc =
      await FirebaseFirestore.instance.collection('admin').doc(user.uid).get();

      if (adminDoc.exists) {
        adminName = adminDoc['name'] ?? '';
        adminApellido = adminDoc['apellidos'] ?? '';
        adminFullName = "$adminName $adminApellido".trim();
        rol = adminDoc['rol'] ?? '';
      } else {
        reset();
      }
    } catch (e) {
      print("❌ Error cargando datos del admin: $e");
      reset();
    }
    _isLoading = false;
  }

  /// 🔹 Limpia la información cuando se cierra sesión
  void reset() {
    adminName = null;
    adminApellido = null;
    adminFullName = null;
    rol = null;
  }
}
