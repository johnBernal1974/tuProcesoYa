import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/providers/auth_provider.dart';
import '../../../commons/main_layaout.dart';

class HistorialRedencionesPage extends StatefulWidget {
  const HistorialRedencionesPage({super.key});

  @override
  State<HistorialRedencionesPage> createState() => _HistorialRedencionesPageState();
}

class _HistorialRedencionesPageState extends State<HistorialRedencionesPage> {
  late String _uid;
  late MyAuthProvider _authProvider;
  bool _isLoading = true;
  List<Map<String, dynamic>> _redenciones = [];
  double _totalDiasRedimidos = 0.0;

  @override
  void initState() {
    super.initState();
    _authProvider = MyAuthProvider();
    _loadUserRedenciones();
  }

  Future<void> _loadUserRedenciones() async {
    final user = _authProvider.getUser();
    if (user != null) {
      setState(() {
        _uid = user.uid;
      });

      try {
        QuerySnapshot redencionesSnapshot = await FirebaseFirestore.instance
            .collection('Ppl')
            .doc(_uid)
            .collection('redenciones')
            .orderBy('fecha_redencion', descending: true)
            .get();

        double sumatoria = 0.0;

        setState(() {
          _redenciones = redencionesSnapshot.docs.map((doc) {
            String fechaStr = doc['fecha_redencion'] ?? "";
            DateTime fecha;

            try {
              fecha = DateFormat('d/M/yyyy').parse(fechaStr);
            } catch (e) {
              debugPrint("\u274c Error al parsear fecha: $fechaStr - $e");
              fecha = DateTime(2000, 1, 1);
            }

            double dias = (doc['dias_redimidos'] ?? 0).toDouble();
            sumatoria += dias;

            return {
              'dias_redimidos': dias,
              'fecha': fecha,
            };
          }).toList();

          _totalDiasRedimidos = sumatoria;
          _isLoading = false;
        });
      } catch (e) {
        debugPrint("\u274c Error al obtener redenciones: $e");
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatearDias(double dias) {
    return dias % 1 == 0 ? dias.toStringAsFixed(0) : dias.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Historial de Redenciones',
      content: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width >= 1000 ? 600 : double.infinity,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _redenciones.isEmpty
                ? const Center(
              child: SizedBox(
                height: 100,
                child: Text(
                  "No tienes redenciones registradas.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            )
                : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: MediaQuery.of(context).size.width,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: DataTable(
                  columnSpacing: MediaQuery.of(context).size.width >= 600 ? 150 : 100,
                  headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey.shade300),
                  columns: const [
                    DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                      label: Align(
                        alignment: Alignment.centerRight,
                        child: Text('Días Redimidos', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                  rows: [
                    ..._redenciones.map(
                          (redencion) => DataRow(cells: [
                        DataCell(Text(
                          DateFormat('d MMM yyyy').format(redencion['fecha']),
                          style: const TextStyle(fontSize: 13),
                        )),
                        DataCell(
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _formatearDias(redencion['dias_redimidos']),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    DataRow(
                      color: MaterialStateColor.resolveWith((states) => Colors.grey.shade300),
                      cells: [
                        const DataCell(Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        )),
                        DataCell(
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _formatearDias(_totalDiasRedimidos),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
