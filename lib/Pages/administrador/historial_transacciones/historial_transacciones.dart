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

                  totalPorSemana[semana] = (totalPorSemana[semana] ?? 0) + (transaction["amount"] as num).toInt();
                  totalGlobal += (transaction["amount"] as num).toInt();
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
                "$semana - Total: \$${NumberFormat("#,###", "es_CO").format(totalPorSemana[semana])}",
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
                "$semana - Total: \$${NumberFormat("#,###", "es_CO").format(totalPorSemana[semana])}",
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
                    DataColumn(label: Text("ID Usuario", style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text("Método Pago", style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text("Monto", style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text("Referencia de pago", style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text("Estado", style: TextStyle(fontSize: 12))),
                  ],
                  rows: transacciones.map((transaction) {
                    var fecha = (transaction["createdAt"] as Timestamp).toDate();
                    var formattedDate = DateFormat("d 'de' MMMM 'de' y, HH:mm", 'es_CO').format(fecha);
                    var formattedAmount = "\$${NumberFormat("#,###", "es_CO").format(transaction["amount"])}";
                    var estado = _traducirEstado(transaction["status"]);
                    var paymentMethod = transaction["paymentMethod"] ?? "Desconocido";
                    var userId = transaction["userId"];
                    var transaccion = transaction["transactionId"];

                    return DataRow(cells: [
                      DataCell(Text(formattedDate, style: const TextStyle(fontSize: 12))),
                      DataCell(FutureBuilder<String>(
                        future: _getUserName(userId),
                        builder: (context, snapshot) {
                          return Text(snapshot.data ?? "Cargando...", style: const TextStyle(fontSize: 12));
                        },
                      )),
                      DataCell(Text(userId, style: const TextStyle(fontSize: 12))),
                      DataCell(Text(paymentMethod, style: const TextStyle(fontSize: 12))),
                      DataCell(Text(formattedAmount, style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 12))),
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
    var formattedAmount = "\$${NumberFormat("#,###", "es_CO").format(transaction["amount"])}";
    var estado = _traducirEstado(transaction["status"]);
    var paymentMethod = transaction["paymentMethod"] ?? "Desconocido";
    var userId = transaction["userId"];
    var transaccionId = transaction["transactionId"];

    // 🔥 Obtiene el estado actual de la tarjeta (por defecto cerrada)
    bool isExpanded = _expandedCards[transaccionId] ?? false;

    return Card(
      color: blanco,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(formattedAmount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$formattedDate - $paymentMethod", style: const TextStyle(fontSize: 12)),
                // 🔥 Muestra directamente el nombre si ya está almacenado en el mapa
                Text(
                  "ID: $userId - ${_userNames[userId] ?? 'Cargando...'}",
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  estado,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: estado == "Aprobado" ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _expandedCards[transaccionId] = !isExpanded;
                      // 🔥 Si el nombre del usuario aún no se ha cargado, obtenerlo
                      if (!_userNames.containsKey(userId)) {
                        _fetchUserName(userId);
                      }
                    });
                  },
                ),
              ],
            ),
          ),

          // 🔥 Sección Expandible 🔥
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.grey),
                  _buildDetailRow("Nombre:", _userNames[userId] ?? "Cargando..."),
                  _buildDetailRow("ID de transacción:", transaccionId),
                  const SizedBox(height: 10),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// **🔹 Obtiene el nombre del usuario desde Firestore una sola vez**
  void _fetchUserName(String userId) async {
    try {
      var userDoc = await FirebaseFirestore.instance.collection("Ppl").doc(userId).get();
      if (userDoc.exists) {
        var nombre = "${userDoc["nombre_ppl"]} ${userDoc["apellido_ppl"]}";
        setState(() {
          _userNames[userId] = nombre; // 🔥 Almacena el nombre en el mapa
        });
      } else {
        setState(() {
          _userNames[userId] = "Usuario desconocido";
        });
      }
    } catch (e) {
      setState(() {
        _userNames[userId] = "Error al cargar";
      });
    }
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

