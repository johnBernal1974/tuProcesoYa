import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../Pages/administrador/listado_ppl_por_beneficio_page.dart';
import '../helper/beneficios_helper.dart';

class ReporteBeneficiosINPECPage extends StatelessWidget {
  const ReporteBeneficiosINPECPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('analisis_condena_ppl')
        .where('tiene_beneficio', isEqualTo: true);

    return Scaffold(
      backgroundColor: Colors.white, // ✅ fondo blanco
      appBar: AppBar(
        title: const Text('Reporte INPEC - Beneficios'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ref.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData) return const Center(child: Text('Sin datos'));

          final docs = snap.data!.docs;

          int c72 = 0, cDom = 0, cCon = 0, cExt = 0;

          for (final d in docs) {
            final m = d.data() as Map<String, dynamic>;
            final top = beneficioMasAlto(m);
            if (top == null) continue;

            switch (top) {
              case BeneficioTipo.permiso72:
                c72++;
                break;
              case BeneficioTipo.domiciliaria:
                cDom++;
                break;
              case BeneficioTipo.condicional:
                cCon++;
                break;
              case BeneficioTipo.extincion:
                cExt++;
                break;
            }
          }

          Widget tarjeta(BeneficioTipo tipo, int count, IconData icon) {
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListadoPplPorBeneficioPage(beneficio: tipo),
                  ),
                );
              },
              child: Card(
                color: Colors.white, // ✅ card blanca
                surfaceTintColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(icon, size: 28, color: Colors.black87),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tituloBeneficio(tipo),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cantidad: $count',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.black54),
                    ],
                  ),
                ),
              ),
            );
          }

          final items = <Widget>[
            tarjeta(BeneficioTipo.permiso72, c72, Icons.timer),
            tarjeta(BeneficioTipo.domiciliaria, cDom, Icons.home),
            tarjeta(BeneficioTipo.condicional, cCon, Icons.verified),
            tarjeta(BeneficioTipo.extincion, cExt, Icons.done_all),
          ];

          return LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;

              // ✅ móvil: columna
              if (w < 700) {
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: items,
                );
              }

              // ✅ PC: grid (tarjetas en la misma fila)
              int crossAxisCount = 4;
              if (w < 1100) crossAxisCount = 3;
              if (w < 900) crossAxisCount = 2;

              return GridView.count(
                padding: const EdgeInsets.all(12),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.6, // ancho vs alto (ajústalo si quieres)
                children: items,
              );
            },
          );
        },
      ),
    );
  }
}
