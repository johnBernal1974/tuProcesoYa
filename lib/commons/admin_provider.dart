import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminProvider {
  static final AdminProvider _instance = AdminProvider._internal();
  factory AdminProvider() => _instance;
  AdminProvider._internal();

  String? adminName;
  bool isLoading = false;

  Future<void> loadAdminName() async {
    if (adminName != null || isLoading) return;
    isLoading = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print("📢 Consultando Firestore para obtener el nombre del admin...");
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admin')
          .doc(user.uid)
          .get();
      if (adminDoc.exists) {
        final adminData = adminDoc.data() as Map<String, dynamic>;
        adminName = adminData['name'];
        print("✅ Nombre del admin cargado: $adminName");
      }
    }
    isLoading = false;
  }

  // 🔴 Método para borrar el admin cuando se cierre sesión
  void reset() {
    adminName = null;
  }
}

