import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../helper/beneficios_helper.dart';

class ListadoPplPorBeneficioPage extends StatelessWidget {
  final BeneficioTipo beneficio;

  const ListadoPplPorBeneficioPage({
    super.key,
    required this.beneficio,
  });

  @override
  Widget build(BuildContext context) {
    final String titulo = tituloBeneficio(beneficio);
    bool esPantallaGrande(BuildContext context) {
      return MediaQuery.of(context).size.width >= 900;
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('PPL con $titulo'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('analisis_condena_ppl')
            .where('tiene_beneficio', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Sin datos'));
          }

          final filtrados = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return beneficioMasAlto(data) == beneficio;
          }).toList();

          if (filtrados.isEmpty) {
            return const Center(child: Text('No hay personas con este beneficio'));
          }

          // 👇 DECISIÓN AUTOMÁTICA
          if (esPantallaGrande(context)) {
            return _tablaPC(filtrados);
          } else {
            return _tarjetasMovil(filtrados);
          }
        },
      ),
    );
  }

  Widget _tablaPC(List<QueryDocumentSnapshot> docs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
        columns: const [
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('Documento')),
          DataColumn(label: Text('TD')),
          DataColumn(label: Text('NUI')),
          DataColumn(label: Text('Patio')),
          DataColumn(label: Text('Estado del beneficio')),
        ],
        rows: docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          final nombre = '${data['nombres'] ?? ''} ${data['apellidos'] ?? ''}';
          final cedula = data['numero_documento'] ?? '';
          final td = data['td'] ?? '';
          final nui = data['nui'] ?? '';
          final patio = data['patio'] ?? '';

          final estados = beneficiosHasta(beneficio)
              .map((b) =>
          '${tituloBeneficio(b)}: ${textoEstadoBeneficio(data, b)}')
              .join('\n');

          return DataRow(
            cells: [
              DataCell(Text(nombre)),
              DataCell(Text(cedula)),
              DataCell(Text(td)),
              DataCell(Text(nui)),
              DataCell(Text(patio)),
              DataCell(Text(estados)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _tarjetasMovil(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;

        final nombre = '${data['nombres']} ${data['apellidos']}';
        final cedula = data['numero_documento'] ?? '';
        final td = data['td'] ?? '';
        final nui = data['nui'] ?? '';
        final patio = data['patio'] ?? '';

        final listaBeneficios = beneficiosHasta(beneficio);

        return Card(
          color: Colors.white,
          elevation: 1.5,
          child: ExpansionTile(
            title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('C.C. $cedula'),
            childrenPadding: const EdgeInsets.all(12),
            children: [
              _dato('TD', td),
              _dato('NUI', nui),
              _dato('Patio', patio),
              const SizedBox(height: 8),
              ...listaBeneficios.map((b) => Text(
                '${tituloBeneficio(b)}: ${textoEstadoBeneficio(data, b)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              )),
            ],
          ),
        );
      },
    );
  }


  Widget _dato(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(valor.toString().trim().isEmpty ? '—' : valor),
          ),
        ],
      ),
    );
  }
}
