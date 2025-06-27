import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../src/colors/colors.dart';

class TablaPreciosWidget extends StatelessWidget {
  const TablaPreciosWidget({super.key});

  Future<Widget> _construirTablaPrecios() async {
    final configSnapshot = await FirebaseFirestore.instance
        .collection('configuraciones')
        .limit(1)
        .get();

    if (configSnapshot.docs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No se encontraron configuraciones.'),
        ),
      );
    }

    final data = configSnapshot.docs.first.data();

    final NumberFormat formatoPesos = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$ ',
      decimalDigits: 0,
      customPattern: '\u00A4 #,##0',
    );

    final servicios = [
      {'nombre': 'Permiso de 72h', 'valor': data['valor_72h']},
      {'nombre': 'Acumulación de penas', 'valor': data['valor_acumulacion']},
      {'nombre': 'Libertad condicional', 'valor': data['valor_condicional']},
      {'nombre': 'Derecho de petición', 'valor': data['valor_derecho_peticion']},
      {'nombre': 'Prisión domiciliaria', 'valor': data['valor_domiciliaria']},
      {'nombre': 'Extinción de la pena', 'valor': data['valor_extincion']},
      {'nombre': 'Redención de penas', 'valor': data['valor_redenciones']},
      {'nombre': 'Suscripción (6 meses)', 'valor': data['valor_subscripcion']},
      {'nombre': 'Traslado de proceso', 'valor': data['valor_traslado_proceso']},
      {'nombre': 'Tutela', 'valor': data['valor_tutela']},
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
        ),
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.deepPurple,
                width: double.infinity,
                child: const Text(
                  'Precios de solicitudes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: Table(
                  border: TableBorder.all(color: Colors.grey),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent,
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Servicio',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Precio',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...servicios.map((serv) {
                      return TableRow(
                        decoration: const BoxDecoration(color: blanco),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(serv['nombre'].toString()),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              formatoPesos.format(
                                (serv['valor'] as num?)?.toDouble() ?? 0.0,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _construirTablaPrecios(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        return snapshot.data!;
      },
    );
  }
}
