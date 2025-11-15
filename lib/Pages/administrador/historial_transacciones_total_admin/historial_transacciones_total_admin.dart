import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';

class AdminTransaccionesHistoricoPage extends StatefulWidget {
  const AdminTransaccionesHistoricoPage({super.key});

  @override
  _AdminTransaccionesHistoricoPageState createState() =>
      _AdminTransaccionesHistoricoPageState();
}

class _AdminTransaccionesHistoricoPageState
    extends State<AdminTransaccionesHistoricoPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String> _userNames = {};
  Map<String, bool> _expandedCards = {};

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: "Historial de Transacciones",
      content: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width >= 1000
              ? double.infinity
              : double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("recargas_historicas")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No hay transacciones registradas."));
                }

                List<QueryDocumentSnapshot> transacciones =
                    snapshot.data!.docs;

                // 🔹 Agrupar por semana (como ya lo tenías)
                Map<String, List<QueryDocumentSnapshot>>
                transaccionesPorSemana = {};
                Map<String, int> totalPorSemana = {};
                int totalGlobal = 0;

                // 🔹 Resumen por concepto (solo Aprobadas)
                Map<String, int> conteoPorConcepto = {};
                Map<String, int> valorPorConcepto = {};

                for (var transaction in transacciones) {
                  var fecha =
                  (transaction["createdAt"] as Timestamp).toDate();
                  final status = transaction["status"] as String? ?? "";
                  final amount =
                      (transaction["amount"] as num?)?.toInt() ?? 0;

                  // 🔹 Obtener concepto desde reference (antes del primer "_")
                  String referenciaOriginal =
                      transaction["reference"] ?? "";
                  String concepto = "";
                  if (referenciaOriginal.isNotEmpty) {
                    concepto = referenciaOriginal.split('_').first;
                  }
                  if (concepto.isEmpty) {
                    concepto = "Sin concepto";
                  }

                  // 🔹 Resumen global por concepto (solo aprobadas)
                  if (status == "APPROVED") {
                    conteoPorConcepto[concepto] =
                        (conteoPorConcepto[concepto] ?? 0) + 1;
                    valorPorConcepto[concepto] =
                        (valorPorConcepto[concepto] ?? 0) + amount;
                    totalGlobal += amount;
                  }

                  // 🔹 Agrupación por semana (sin filtros, como antes)
                  DateTime inicioSemana = fecha
                      .subtract(Duration(days: fecha.weekday - 1)); // Lunes
                  DateTime finSemana =
                  inicioSemana.add(const Duration(days: 6)); // Domingo

                  String semana =
                      "Semana entre el ${DateFormat("d", 'es_CO').format(inicioSemana)} "
                      "y el ${DateFormat("d 'de' MMMM 'de' yyyy", 'es_CO').format(finSemana)}";

                  transaccionesPorSemana.putIfAbsent(semana, () => []);
                  transaccionesPorSemana[semana]!.add(transaction);

                  if (status == "APPROVED") {
                    totalPorSemana[semana] =
                        (totalPorSemana[semana] ?? 0) + amount;
                  }
                }

                // Detectar si es móvil o PC
                bool esMovil =
                    MediaQuery.of(context).size.width < 800;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Total global de transacciones aprobadas (igual que antes)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border:
                        Border.all(color: gris, width: 3),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Valor Total de Transacciones Aprobadas",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            "\$${NumberFormat("#,###", "es_CO").format(totalGlobal)}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 🔹 Botón que abre el resumen en un AlertDialog superpuesto
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.analytics, size: 18),
                        label: const Text(
                          "Ver resumen por concepto",
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: conteoPorConcepto.isEmpty
                            ? null
                            : () {
                          _mostrarResumenConceptosDialog(
                            context,
                            conteoPorConcepto,
                            valorPorConcepto,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🔹 Lista por semana (lo mismo que ya tenías)
                    Expanded(
                      child: transaccionesPorSemana.isEmpty
                          ? const Center(
                        child: Text(
                          "No hay transacciones registradas.",
                          style: TextStyle(fontSize: 12),
                        ),
                      )
                          : esMovil
                          ? _buildMobileView(
                        transaccionesPorSemana,
                        totalPorSemana,
                      )
                          : _buildDesktopView(
                        transaccionesPorSemana,
                        totalPorSemana,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 AlertDialog con scroll que muestra el resumen por concepto
  void _mostrarResumenConceptosDialog(
      BuildContext context,
      Map<String, int> conteoPorConcepto,
      Map<String, int> valorPorConcepto,
      ) {
    // 🔹 Totales globales del resumen
    final int totalServicios = conteoPorConcepto.values.fold(0, (a, b) => a + b);
    final int totalValor = valorPorConcepto.values.fold(0, (a, b) => a + b);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: blanco,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Resumen por concepto",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          content: SizedBox(
            width: MediaQuery.of(ctx).size.width * 0.8,
            height: MediaQuery.of(ctx).size.height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Totales generales arriba del cuadro
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.deepPurple.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Totales generales (pagos aprobados)",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Total servicios / pagos: $totalServicios",
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        "Valor total: \$${NumberFormat("#,###", "es_CO").format(totalValor)}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // 🔹 Tabla o lista según el tamaño de pantalla
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: _buildResumenConceptos(
                      ctx, // 🔹 pasamos el contexto aquí
                      conteoPorConcepto,
                      valorPorConcepto,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  /// 🔹 Contenido del resumen por concepto (con scroll horizontal interno)
  Widget _buildResumenConceptos(
      BuildContext context,
      Map<String, int> conteoPorConcepto,
      Map<String, int> valorPorConcepto,
      ) {
    final conceptos = conteoPorConcepto.keys.toList()..sort();
    final isMobile = MediaQuery.of(context).size.width < 600;

    // 🔹 En móvil: lista sencilla, sin DataTable, todo visible
    if (isMobile) {
      return Card(
        color: blanco,
        surfaceTintColor: blanco,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: gris.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Pagos aprobados por concepto",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              ...conceptos.map((concepto) {
                final cantidad = conteoPorConcepto[concepto] ?? 0;
                final valor = valorPorConcepto[concepto] ?? 0;
                final conceptoCap =
                concepto.isNotEmpty ? concepto[0].toUpperCase() + concepto.substring(1) : concepto;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      // Concepto
                      Expanded(
                        flex: 3,
                        child: Text(
                          conceptoCap,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // # pagos
                      Expanded(
                        flex: 1,
                        child: Text(
                          cantidad.toString(),
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Valor total
                      Expanded(
                        flex: 2,
                        child: Text(
                          "\$${NumberFormat("#,###", "es_CO").format(valor)}",
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      );
    }

    // 🔹 En tablet/PC: DataTable con scroll horizontal (como ya lo tenías)
    return Card(
      color: blanco,
      surfaceTintColor: blanco,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: gris.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pagos aprobados por concepto",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
                columns: const [
                  DataColumn(
                    label: Text(
                      "Concepto",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "# pagos",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Valor total",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: conceptos.map((concepto) {
                  final cantidad = conteoPorConcepto[concepto] ?? 0;
                  final valor = valorPorConcepto[concepto] ?? 0;
                  final conceptoCap =
                  concepto.isNotEmpty ? concepto[0].toUpperCase() + concepto.substring(1) : concepto;

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          conceptoCap,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      DataCell(
                        Text(
                          cantidad.toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      DataCell(
                        Text(
                          "\$${NumberFormat("#,###", "es_CO").format(valor)}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// **🔹 Vista en Móvil (Tarjetas)** – sin Expanded interno
  Widget _buildMobileView(
      Map<String, List<QueryDocumentSnapshot>> transaccionesPorSemana,
      Map<String, int> totalPorSemana,
      ) {
    return ListView(
      children: transaccionesPorSemana.entries.map((entry) {
        String semana = entry.key;
        List<QueryDocumentSnapshot> transacciones = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$semana - Total: \$${NumberFormat("#,###", "es_CO").format(totalPorSemana[semana] ?? 0)}",
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.black),
            ),
            const SizedBox(height: 8),
            ...transacciones
                .map((transaction) => _buildTransactionCard(transaction))
                .toList(),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  /// **🔹 Vista en PC (Tabla)** – sin Expanded interno
  Widget _buildDesktopView(
      Map<String, List<QueryDocumentSnapshot>> transaccionesPorSemana,
      Map<String, int> totalPorSemana,
      ) {
    return ListView(
      children: transaccionesPorSemana.entries.map((entry) {
        String semana = entry.key;
        List<QueryDocumentSnapshot> transacciones = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$semana - Total: \$${NumberFormat("#,###", "es_CO").format(totalPorSemana[semana] ?? 0)}",
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                MaterialStateProperty.all(Colors.grey[200]),
                columns: const [
                  DataColumn(
                      label:
                      Text("Fecha", style: TextStyle(fontSize: 12))),
                  DataColumn(
                      label:
                      Text("Usuario", style: TextStyle(fontSize: 12))),
                  DataColumn(
                      label: Text("Método Pago",
                          style: TextStyle(fontSize: 12))),
                  DataColumn(
                      label:
                      Text("Monto", style: TextStyle(fontSize: 12))),
                  DataColumn(
                      label: Text("Servicio",
                          style: TextStyle(fontSize: 12))),
                  DataColumn(
                      label: Text("Referencia de pago",
                          style: TextStyle(fontSize: 12))),
                  DataColumn(
                      label:
                      Text("Estado", style: TextStyle(fontSize: 12))),
                ],
                rows: transacciones.map((transaction) {
                  var fecha =
                  (transaction["createdAt"] as Timestamp).toDate();
                  var formattedDate =
                  DateFormat("d 'de' MMMM 'de' y, HH:mm", 'es_CO')
                      .format(fecha);
                  var formattedAmount =
                      "\$${NumberFormat("#,###", "es_CO").format(transaction["amount"] ?? 0)}";
                  var estado = _traducirEstado(transaction["status"]);
                  var paymentMethod =
                      transaction["paymentMethod"] ?? "Desconocido";
                  var userId = transaction["userId"];
                  var transaccion =
                  transaction["transactionId"];
                  var referenciaOriginal =
                      transaction["reference"] ?? "";
                  var referenciaFormateada =
                      referenciaOriginal.split('_').first;
                  if (referenciaFormateada.isNotEmpty) {
                    referenciaFormateada =
                        referenciaFormateada[0].toUpperCase() +
                            referenciaFormateada.substring(1);
                  }

                  return DataRow(cells: [
                    DataCell(Text(formattedDate,
                        style:
                        const TextStyle(fontSize: 12))),
                    DataCell(
                      FutureBuilder<String>(
                        future: _getUserName(userId),
                        builder: (context, snapshot) {
                          final nombre =
                              snapshot.data ?? "Cargando...";
                          return Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(nombre,
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(userId,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.black
                                          .withOpacity(0.6))),
                            ],
                          );
                        },
                      ),
                    ),
                    DataCell(Text(paymentMethod,
                        style:
                        const TextStyle(fontSize: 12))),
                    DataCell(
                      Text(
                        formattedAmount,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: estado == "Rechazado"
                              ? Colors.red
                              : Colors.black,
                          decoration: estado == "Rechazado"
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                    DataCell(Text(referenciaFormateada,
                        style:
                        const TextStyle(fontSize: 12))),
                    DataCell(Text(transaccion,
                        style:
                        const TextStyle(fontSize: 12))),
                    DataCell(
                      Text(
                        estado,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: estado == "Aprobado"
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  /// **🔹 Tarjeta en móvil**
  Widget _buildTransactionCard(QueryDocumentSnapshot transaction) {
    var fecha =
    (transaction["createdAt"] as Timestamp).toDate();
    var formattedDate =
    DateFormat("d 'de' MMMM 'de' y, HH:mm", 'es_CO').format(fecha);
    var formattedAmount =
        "\$${NumberFormat("#,###", "es_CO").format(transaction["amount"] ?? 0)}";
    var estado = _traducirEstado(transaction["status"]);
    var paymentMethod = transaction["paymentMethod"] ?? "Desconocido";
    var userId = transaction["userId"];
    var transaccionId = transaction["transactionId"];
    var referenciaOriginal = transaction["reference"] ?? "";
    var referenciaFormateada =
        referenciaOriginal.split('_').first;
    if (referenciaFormateada.isNotEmpty) {
      referenciaFormateada =
          referenciaFormateada[0].toUpperCase() +
              referenciaFormateada.substring(1);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        color: blanco,
        surfaceTintColor: blanco,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                formattedAmount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: estado == "Rechazado"
                      ? Colors.red
                      : Colors.black,
                  decoration: estado == "Rechazado"
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              const SizedBox(height: 5),
              Text("$formattedDate - $paymentMethod",
                  style: const TextStyle(fontSize: 12)),

              // 🔽 Nombre e ID del usuario
              FutureBuilder<String>(
                future: _getUserName(userId),
                builder: (context, snapshot) {
                  final nombre =
                      snapshot.data ?? "Cargando...";
                  return Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(nombre,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black)),
                      const SizedBox(height: 2),
                      Text(userId,
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.black
                                  .withOpacity(0.6))),
                    ],
                  );
                },
              ),

              const SizedBox(height: 5),
              // 🔽 Servicio
              Text(referenciaFormateada,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900)),

              const SizedBox(height: 5),
              Text("No. Transacción: $transaccionId",
                  style: const TextStyle(
                      fontSize: 10, color: Colors.grey)),

              const SizedBox(height: 5),
              Text(
                estado,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: estado == "Aprobado"
                      ? Colors.green
                      : Colors.red,
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
      var userDoc = await FirebaseFirestore.instance
          .collection("Ppl")
          .doc(userId)
          .get();
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

  /// **🔹 Widget reutilizable (método)**
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

/// 🔹 Widget reutilizable global (si lo usas en otros lados)
Widget _buildDetailRow(String label, String value) {
  return Row(
    mainAxisAlignment:
    MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey)),
      Expanded(
        child: Text(value,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis),
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
