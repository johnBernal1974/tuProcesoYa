import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:tuprocesoya/Pages/Inpec/tabla_solicitudes_inpec.dart';
import '../../../commons/main_layaout.dart'; // 👈 ajusta la ruta según tu proyecto

class PanelJuridicaPenitenciariaHomePage extends StatelessWidget {
  const PanelJuridicaPenitenciariaHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_BeneficioPanelItem>[
      _BeneficioPanelItem(
        titulo: 'Permiso 72 horas',
        coleccion: 'permiso_solicitados',
        icono: Icons.timer_outlined,
      ),
      _BeneficioPanelItem(
        titulo: 'Prisión domiciliaria',
        coleccion: 'domiciliaria_solicitados',
        icono: Icons.home_outlined,
      ),
      _BeneficioPanelItem(
        titulo: 'Libertad condicional',
        coleccion: 'condicional_solicitados',
        icono: Icons.gavel_outlined,
      ),
      _BeneficioPanelItem(
        titulo: 'Extinción de la pena',
        coleccion: 'extincion_pena_solicitados',
        icono: Icons.verified_outlined,
      ),
    ];

    return MainLayout(
      pageTitle: 'Oficina Jurídica - Panel',
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth >= 900;

            // ✅ Si quieres que quede alineado arriba y no centrado:
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child:GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 4 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: isWide ? 120 : 105, // 👈 ALTURA REAL de cada tarjeta
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return _BeneficioCard(
                      item: item,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SolicitudesBeneficioTablePage(
                              titulo: item.titulo,
                              coleccion: item.coleccion,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BeneficioPanelItem {
  final String titulo;
  final String coleccion;
  final IconData icono;

  _BeneficioPanelItem({
    required this.titulo,
    required this.coleccion,
    required this.icono,
  });
}

class _BeneficioCard extends StatelessWidget {
  final _BeneficioPanelItem item;
  final VoidCallback onTap;

  const _BeneficioCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection(item.coleccion);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        height: 100,
        child: Card(
          elevation: 0, // 👈 sin sombra
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(item.icono, size: 22),
                const SizedBox(height: 6),
                Text(
                  item.titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                StreamBuilder<QuerySnapshot>(
                  stream: ref.snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Text(
                        '...',
                        style: TextStyle(fontSize: 14),
                      );
                    }
                    final total = snap.data!.docs.length;
                    return Text(
                      '$total',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    );
                  },
                ),
                const Text(
                  'solicitudes',
                  style: TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


