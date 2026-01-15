import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tuprocesoya/Pages/Inpec/tabla_solicitudes_inpec.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oficina Jurídica - Panel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth >= 900;
            return GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: items.map((item) {
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
              }).toList(),
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
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icono, size: 26),
              const SizedBox(height: 10),
              Text(
                item.titulo,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              StreamBuilder<QuerySnapshot>(
                stream: ref.snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Text('...');
                  }
                  final total = snap.data!.docs.length;
                  return Text(
                    '$total solicitudes',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
