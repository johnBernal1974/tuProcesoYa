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
  int? _saldo; // 🔹 Guarda el saldo del usuario

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
      _fetchSaldo(); // 🔥 Carga el saldo una vez que se tiene el userId
    } else {
      print("⚠️ No hay usuario autenticado.");
    }
  }

  /// **🔹 Obtiene el saldo del usuario desde Firestore**
  Future<void> _fetchSaldo() async {
    if (_userId.isEmpty) return;

    final userDoc = await _firestore.collection("Ppl").doc(_userId).get();
    if (userDoc.exists) {
      setState(() {
        _saldo = userDoc.data()?['saldo'] ?? 0;
      });
    }
  }

  /// **🔹 Traduce el estado de pago a español**
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

  /// **🔹 Obtiene el concepto de la referencia**
  String _obtenerConcepto(String reference) {
    if (reference.startsWith("suscripcion")) return "Suscripción";
    if (reference.startsWith("recarga")) return "Recarga";
    if (reference.startsWith("peticion")) return "Derecho petición";
    if (reference.startsWith("tutela")) return "Tutela";
    if (reference.startsWith("domiciliaria")) return "Solicitud domiciliaria";
    if (reference.startsWith("permiso")) return "Permiso 72h";
    if (reference.startsWith("condicional")) return "Libertad Condicional";
    if (reference.startsWith("extincion")) return "Extinción de pena";
    if (reference.startsWith("traslado")) return "Traslado proceso";
    return "Otro";
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
            padding: const EdgeInsets.all(0.0),
            child: Column(
              children: [
                Expanded(
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
                          var formattedDate =
                          DateFormat("d 'de' MMMM 'de' y, HH:mm", 'es_CO').format(fecha);
                          var amount = transaction["amount"] as num;
                          var estado = _traducirEstado(transaction["status"]);
                          var concepto = _obtenerConcepto(transaction["reference"]);
                          var transactionId = transaction["transactionId"] ?? "ID no disponible";
                          var paymentMethod = transaction["paymentMethod"] ?? "ID no disponible";

                          return Card(
                            color: blanco,
                            surfaceTintColor: blanco,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "\$${NumberFormat("#,###", "es_CO").format(amount)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: estado == "Rechazado" ? Colors.red : Colors.black,
                                      decoration: estado == "Rechazado" ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  Text(
                                    estado,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: estado == "Aprobado" ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '$concepto - ',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "ID: $transactionId",
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                  Text(
                                    "Método de pago: : $paymentMethod",
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
