import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';

class AdminTransaccionesPage extends StatefulWidget {
  const AdminTransaccionesPage({super.key});

  @override
  _AdminTransaccionesPageState createState() => _AdminTransaccionesPageState();
}

class _AdminTransaccionesPageState extends State<AdminTransaccionesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String> _userNames = {};
  Map<String, bool> _expandedCards = {};


  @override
  Widget build(BuildContext context) {

    return MainLayout(
      pageTitle: "Transacciones",
      content: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width >= 1000 ? double.infinity : double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("recargas")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No hay transacciones registradas."));
                }

                List<QueryDocumentSnapshot> transacciones = snapshot.data!.docs;

                // Agrupar por semana
                Map<String, List<QueryDocumentSnapshot>> transaccionesPorSemana = {};
                Map<String, int> totalPorSemana = {};
                int totalGlobal = 0;

                for (var transaction in transacciones) {
                  var fecha = (transaction["createdAt"] as Timestamp).toDate();

                  // 🔥 Obtener el inicio y fin de la semana (lunes - domingo)
                  DateTime inicioSemana = fecha.subtract(Duration(days: fecha.weekday - 1)); // Lunes
                  DateTime finSemana = inicioSemana.add(const Duration(days: 6)); // Domingo

                  // 🔥 Formatear para mostrar "Semana entre el 10 y el 16 de marzo de 2025"
                  String semana = "Semana entre el ${DateFormat("d", 'es_CO').format(inicioSemana)} "
                      "y el ${DateFormat("d 'de' MMMM 'de' yyyy", 'es_CO').format(finSemana)}";

                  transaccionesPorSemana.putIfAbsent(semana, () => []);
                  transaccionesPorSemana[semana]!.add(transaction);
                  if (transaction["status"] == "APPROVED") {
                    totalPorSemana[semana] = (totalPorSemana[semana] ?? 0) + (transaction["amount"] as num).toInt();
                    totalGlobal += (transaction["amount"] as num).toInt();
                  }
                }


                // Detectar si es móvil o PC
                bool esMovil = MediaQuery.of(context).size.width < 800;

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: gris, width: 3)
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Valor Total de Transacciones",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          Text(
                            "\$${NumberFormat("#,###", "es_CO").format(totalGlobal)}",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    esMovil
                        ? _buildMobileView(transaccionesPorSemana, totalPorSemana)
                        : _buildDesktopView(transaccionesPorSemana, totalPorSemana),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// **🔹 Construye la Vista en Móvil (Tarjetas)**
  Widget _buildMobileView(Map<String, List<QueryDocumentSnapshot>> transaccionesPorSemana, Map<String, int> totalPorSemana) {
    return Expanded(
      child: ListView(
        children: transaccionesPorSemana.entries.map((entry) {
          String semana = entry.key;
          List<QueryDocumentSnapshot> transacciones = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$semana - Total: \$${NumberFormat("#,###", "es_CO").format(totalPorSemana[semana] ?? 0)}",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black),
              ),
              const SizedBox(height: 8),
              ...transacciones.map((transaction) => _buildTransactionCard(transaction)).toList(),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// **🔹 Construye la Vista en PC (Tabla)**
  Widget _buildDesktopView(Map<String, List<QueryDocumentSnapshot>> transaccionesPorSemana, Map<String, int> totalPorSemana) {
    return Expanded(
      child: ListView(
        children: transaccionesPorSemana.entries.map((entry) {
          String semana = entry.key;
          List<QueryDocumentSnapshot> transacciones = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$semana - Total: \$${NumberFormat("#,###", "es_CO").format(totalPorSemana[semana] ?? 0)}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black),
              ),
              const SizedBox(height: 8),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
                  columns: const [
                    DataColumn(label: Text("Fecha", style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text("Usuario", style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text("Método Pago", style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text("Monto", style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text("Servicio", style: TextStyle(fontSize: 12))), // ✅ Nueva columna
                    DataColumn(label: Text("Referencia de pago", style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text("Estado", style: TextStyle(fontSize: 12))),
                  ],
                  rows: transacciones.map((transaction) {
                    var fecha = (transaction["createdAt"] as Timestamp).toDate();
                    var formattedDate = DateFormat("d 'de' MMMM 'de' y, HH:mm", 'es_CO').format(fecha);
                    var formattedAmount = "\$${NumberFormat("#,###", "es_CO").format(transaction["amount"] ?? 0)}";
                    var estado = _traducirEstado(transaction["status"]);
                    var paymentMethod = transaction["paymentMethod"] ?? "Desconocido";
                    var userId = transaction["userId"];
                    var transaccion = transaction["transactionId"];
                    var referenciaOriginal = transaction["reference"] ?? "";
                    var referenciaFormateada = referenciaOriginal.split('_').first;
                    if (referenciaFormateada.isNotEmpty) {
                      referenciaFormateada = referenciaFormateada[0].toUpperCase() + referenciaFormateada.substring(1);
                    }

                    return DataRow(cells: [
                      DataCell(Text(formattedDate, style: const TextStyle(fontSize: 12))),
                      DataCell(FutureBuilder<String>(
                        future: _getUserName(userId),
                        builder: (context, snapshot) {
                          final nombre = snapshot.data ?? "Cargando...";
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nombre, style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(userId, style: TextStyle(fontSize: 10, color: Colors.black.withOpacity(0.6))),
                            ],
                          );
                        },
                      )),
                      DataCell(Text(paymentMethod, style: const TextStyle(fontSize: 12))),
                      DataCell(
                        Text(
                          formattedAmount,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: estado == "Rechazado" ? Colors.red : Colors.black,
                            decoration: estado == "Rechazado" ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ),
                      ),
                      DataCell(Text(referenciaFormateada, style: const TextStyle(fontSize: 12))), // ✅ Nueva celda
                      DataCell(Text(transaccion, style: const TextStyle(fontSize: 12))),
                      DataCell(Text(
                        estado,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: estado == "Aprobado" ? Colors.green : Colors.red,
                        ),
                      )),
                    ]);
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// **🔹 Construye una tarjeta en Móvil**
  Widget _buildTransactionCard(QueryDocumentSnapshot transaction) {
    var fecha = (transaction["createdAt"] as Timestamp).toDate();
    var formattedDate = DateFormat("d 'de' MMMM 'de' y, HH:mm", 'es_CO').format(fecha);
    var formattedAmount = "\$${NumberFormat("#,###", "es_CO").format(transaction["amount"] ?? 0)}";
    var estado = _traducirEstado(transaction["status"]);
    var paymentMethod = transaction["paymentMethod"] ?? "Desconocido";
    var userId = transaction["userId"];
    var transaccionId = transaction["transactionId"];
    var referenciaOriginal = transaction["reference"] ?? "";
    var referenciaFormateada = referenciaOriginal.split('_').first;
    if (referenciaFormateada.isNotEmpty) {
      referenciaFormateada = referenciaFormateada[0].toUpperCase() + referenciaFormateada.substring(1);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        color: blanco,
        surfaceTintColor: blanco,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formattedAmount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: estado == "Rechazado" ? Colors.red : Colors.black,
                  decoration: estado == "Rechazado" ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
              const SizedBox(height: 5),
              Text("$formattedDate - $paymentMethod", style: const TextStyle(fontSize: 12)),

              // 🔽 Nombre e ID del usuario
              FutureBuilder<String>(
                future: _getUserName(userId),
                builder: (context, snapshot) {
                  final nombre = snapshot.data ?? "Cargando...";
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre, style: const TextStyle(fontSize: 12, color: Colors.black)),
                      const SizedBox(height: 2),
                      Text(userId, style: TextStyle(fontSize: 10, color: Colors.black.withOpacity(0.6))),
                    ],
                  );
                },
              ),

              const SizedBox(height: 5),
              // 🔽 Servicio
              Text(referenciaFormateada, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),

              const SizedBox(height: 5),
              Text("No. Transacción: $transaccionId", style: const TextStyle(fontSize: 10, color: Colors.grey)),

              const SizedBox(height: 5),
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
        ),
      ),
    );
  }




  /// **🔹 Obtiene el nombre del usuario desde Firestore**
  Future<String> _getUserName(String userId) async {
    try {
      var userDoc = await FirebaseFirestore.instance.collection("Ppl").doc(userId).get();
      if (userDoc.exists) {
        var nombre = userDoc["nombre_ppl"];
        var apellido = userDoc["apellido_ppl"];
        return "$nombre $apellido";
      } else {
        return "Usuario desconocido";
      }
    } catch (e) {
      return "Error al cargar";
    }
  }

  /// **🔹 Widget reutilizable para mostrar filas de detalles**
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

/// 🔹 Widget reutilizable para mostrar filas de detalles
Widget _buildDetailRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
      Expanded(
        child: Text(value, style: const TextStyle(fontSize: 12), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}

String _traducirEstado(String status) {
  switch (status) {
    case "APPROVED":
      return "Aprobado";
    case "DECLINED":
      return "Rechazado";
    default:
      return "Pendiente";
  }
}

