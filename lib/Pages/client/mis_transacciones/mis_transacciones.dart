import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';

class MisTransaccionesPage extends StatefulWidget {
  const MisTransaccionesPage({super.key});

  @override
  _MisTransaccionesPageState createState() => _MisTransaccionesPageState();
}

class _MisTransaccionesPageState extends State<MisTransaccionesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
      print("🔹 User ID cargado: $_userId"); // 🔥 Verifica que se esté cargando
    } else {
      print("⚠️ No hay usuario autenticado.");
    }
  }

  /// Traduce el estado de pago a español
  String _traducirEstado(String status) {
    switch (status) {
      case "APPROVED":
        return "Aprobado";
      case "DECLINED":
        return "Rechazado";
      case "PENDING":
        return "Pendiente";
      case "VOIDED":
        return "Anulado";
      default:
        return "Desconocido";
    }
  }

  /// Obtiene el concepto de la referencia
  String _obtenerConcepto(String reference) {
    return reference.startsWith("suscripcion") ? "Suscripción" : "Recarga";
  }

  @override
  Widget build(BuildContext context) {
    if (_userId.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()), // 🔥 Espera a cargar el userId
      );
    }

    return MainLayout(
      pageTitle: "Mis Transacciones",
      content: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width >= 1000 ? 800 : double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: _userId.isNotEmpty
                  ? _firestore
                  .collection("recargas")
                  .where("userId", isEqualTo: _userId)
                  .orderBy("createdAt", descending: true)
                  .snapshots()
                  : null, // 🔥 Evita que la consulta falle si _userId es null
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No tienes transacciones registradas."));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var transaction = snapshot.data!.docs[index];
                    var fecha = (transaction["createdAt"] as Timestamp).toDate();
                    var formattedDate = DateFormat("d 'de' MMMM 'de' y, HH:mm", 'es_CO').format(fecha);
                    var formattedAmount = "\$${NumberFormat("#,###", "es_CO").format(transaction["amount"])}";
                    var estado = _traducirEstado(transaction["status"]);
                    var concepto = _obtenerConcepto(transaction["reference"]);
                    var transactionId = transaction["transactionId"] ?? "ID no disponible";

                    return Card(
                      color: blanco,
                      surfaceTintColor: blanco,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          concepto == "Suscripción" ? Icons.subscriptions : Icons.account_balance_wallet,
                          color: concepto == "Suscripción" ? Colors.blue : Colors.green,
                          size: 20,
                        ),
                        title: Text(
                          formattedAmount,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$concepto - $formattedDate",
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              "ID: $transactionId", // 🔥 Se muestra el ID de la transacción
                              style: const TextStyle(fontSize: 10, color: Colors.grey), // 🔥 Pequeño y gris
                            ),
                          ],
                        ),
                        trailing: Text(
                          estado,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: estado == "Aprobado" ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
