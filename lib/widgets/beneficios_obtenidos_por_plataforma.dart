import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PplConBeneficiosPlataformaWidget extends StatefulWidget {
  const PplConBeneficiosPlataformaWidget({super.key});

  @override
  State<PplConBeneficiosPlataformaWidget> createState() =>
      _PplConBeneficiosPlataformaWidgetState();
}

class _PplConBeneficiosPlataformaWidgetState
    extends State<PplConBeneficiosPlataformaWidget> {
  String? filtroCiudad;     // null = todas
  String? filtroSituacion;  // null = todas
  String? filtroBeneficio;  // null = todos

  String norm(String s) => s.toLowerCase().trim();

  final List<String> _beneficiosFiltro = const [
    "Permiso de 72h",
    "Prisión Domiciliaria",
    "Libertad Condicional",
    "Extinción de la Pena",
  ];

  final List<String> _situacionesFiltro = const [
    "En Reclusión",
    "En Prisión domiciliaria",
    "En libertad condicional",
    "Extinción de la pena",
  ];

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection("Ppl")
        .where("haAdquiridoBeneficioEnPlataforma", isEqualTo: true)
        .orderBy("fechaPrimerBeneficioEnPlataforma", descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint("🔥 Error Firestore: ${snapshot.error}");
          return Text("Error: ${snapshot.error}");
        }



        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Text("Aún no hay PPL con beneficios obtenidos por la plataforma.");
        }

        // ✅ Sacar ciudades únicas desde lo que viene en el stream (sin otra consulta)
        final ciudadesUnicas = <String>{};
        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          final c = (data["ciudad"] ?? "").toString().trim();
          if (c.isNotEmpty) ciudadesUnicas.add(c);
        }
        final ciudadesOrdenadas = ciudadesUnicas.toList()..sort();

        // ✅ Aplicar filtros en memoria
        final filtrados = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;

          final ciudad = (data["ciudad"] ?? "").toString().trim();
          final situacion = (data["situacion"] ?? "").toString().trim();
          final beneficios = (data["beneficiosAdquiridos"] as List?)?.cast<String>() ?? [];

          final pasaCiudad = (filtroCiudad == null || filtroCiudad!.isEmpty)
              ? true
              : norm(ciudad) == norm(filtroCiudad!);

          final pasaSituacion = (filtroSituacion == null || filtroSituacion!.isEmpty)
              ? true
              : norm(situacion) == norm(filtroSituacion!);

          final pasaBeneficio = (filtroBeneficio == null || filtroBeneficio!.isEmpty)
              ? true
              : beneficios.any((b) => norm(b) == norm(filtroBeneficio!));

          return pasaCiudad && pasaSituacion && pasaBeneficio;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Filtros
            Card(
              color: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Filtros",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        // Beneficio
                        SizedBox(
                          width: 260,
                          child: DropdownButtonFormField<String>(
                            dropdownColor: Colors.white,
                            value: filtroBeneficio,
                            decoration: InputDecoration(
                              labelText: "Beneficio",
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.grey),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade600), // ✅ gris medio
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade600, width: 2), // ✅ gris medio
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text("Todos")),
                              ..._beneficiosFiltro.map(
                                    (b) => DropdownMenuItem(value: b, child: Text(b)),
                              ),
                            ],
                            onChanged: (v) => setState(() => filtroBeneficio = v),
                          ),
                        ),
                        // Ciudad
                        // SizedBox(
                        //   width: 260,
                        //   child: DropdownButtonFormField<String>(
                        //     value: filtroCiudad,
                        //     decoration: InputDecoration(
                        //       labelText: "Ciudad",
                        //       isDense: true,
                        //       border: OutlineInputBorder(
                        //         borderRadius: BorderRadius.circular(8),
                        //         borderSide: const BorderSide(color: Colors.grey),
                        //       ),
                        //       enabledBorder: OutlineInputBorder(
                        //         borderRadius: BorderRadius.circular(8),
                        //         borderSide: BorderSide(color: Colors.grey.shade600), // gris medio
                        //       ),
                        //       focusedBorder: OutlineInputBorder(
                        //         borderRadius: BorderRadius.circular(8),
                        //         borderSide: BorderSide(color: Colors.grey.shade600, width: 2),
                        //       ),
                        //     ),
                        //     items: [
                        //       const DropdownMenuItem(value: null, child: Text("Todas")),
                        //       ...ciudadesOrdenadas.map(
                        //             (c) => DropdownMenuItem(value: c, child: Text(c)),
                        //       ),
                        //     ],
                        //     onChanged: (v) => setState(() => filtroCiudad = v),
                        //   ),
                        // ),
                        //
                        // // Situación
                        // SizedBox(
                        //   width: 260,
                        //   child: DropdownButtonFormField<String>(
                        //     value: filtroSituacion,
                        //     decoration: InputDecoration(
                        //       labelText: "Situación",
                        //       isDense: true,
                        //       border: OutlineInputBorder(
                        //         borderRadius: BorderRadius.circular(8),
                        //         borderSide: const BorderSide(color: Colors.grey),
                        //       ),
                        //       enabledBorder: OutlineInputBorder(
                        //         borderRadius: BorderRadius.circular(8),
                        //         borderSide: BorderSide(color: Colors.grey.shade600), // gris medio
                        //       ),
                        //       focusedBorder: OutlineInputBorder(
                        //         borderRadius: BorderRadius.circular(8),
                        //         borderSide: BorderSide(color: Colors.grey.shade600, width: 2),
                        //       ),
                        //     ),
                        //     items: [
                        //       const DropdownMenuItem(value: null, child: Text("Todas")),
                        //       ..._situacionesFiltro.map(
                        //             (s) => DropdownMenuItem(value: s, child: Text(s)),
                        //       ),
                        //     ],
                        //     onChanged: (v) => setState(() => filtroSituacion = v),
                        //   ),
                        // ),

                        // Limpiar
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                filtroBeneficio = null;
                                filtroCiudad = null;
                                filtroSituacion = null;
                              });
                            },
                            icon: const Icon(Icons.refresh, color: Colors.grey),
                            label: const Text(
                              "Limpiar filtros",
                              style: TextStyle(color: Colors.black87),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade600), // ✅ gris medio
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ),

                      ],
                    ),

                    const SizedBox(height: 10),
                    Text(
                      "Resultados: ${filtrados.length} de ${docs.length}",
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ✅ Lista
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtrados.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = filtrados[index];
                final data = doc.data() as Map<String, dynamic>;

                // 🔹 PPL
                final nombrePpl =
                "${data["nombre_ppl"] ?? ""} ${data["apellido_ppl"] ?? ""}".trim();
                final docPpl = (data["numero_documento_ppl"] ?? "").toString();

                // 🔹 Acudiente
                final nombreAcudiente =
                "${data["nombre_acudiente"] ?? ""} ${data["apellido_acudiente"] ?? ""}"
                    .trim();
                final cedulaAcudiente =
                (data["cedula_responsable"] ?? "No registrada").toString();
                final parentesco =
                (data["parentesco_representante"] ?? "No registrado").toString();

                // 🔹 Contacto
                final celular = (data["celular"] ?? "No registrado").toString();
                final whatsapp = (data["celularWhatsapp"] ?? "No registrado").toString();

                // 🔹 Beneficios
                final List<String> beneficios =
                    (data["beneficiosAdquiridos"] as List?)?.cast<String>() ?? [];

                final primerBeneficio =
                (data["primerBeneficioEnPlataforma"] ?? "").toString();

                final fechaTs = data["fechaPrimerBeneficioEnPlataforma"];
                final fecha = fechaTs is Timestamp ? fechaTs.toDate() : null;

                String fechaTexto() {
                  if (fecha == null) return "Sin fecha";
                  String two(int n) => n.toString().padLeft(2, '0');
                  return "${two(fecha!.day)}/${two(fecha!.month)}/${fecha!.year}";
                }

                return Card(
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado
                        Row(
                          children: [
                            const Icon(Icons.verified,
                                color: Colors.green, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                nombrePpl.isEmpty ? "PPL sin nombre" : nombrePpl,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),
                        _linea("Documento PPL", docPpl),
                        _linea("Acudiente", nombreAcudiente),
                        _linea("Cédula acudiente", cedulaAcudiente),
                        _linea("Parentesco", parentesco),
                        _linea("Celular", celular),
                        _linea("WhatsApp", whatsapp),

                        const SizedBox(height: 8),
                        const Text(
                          "Beneficios obtenidos por la plataforma",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),

                        if (beneficios.isEmpty)
                          const Text(
                            "No hay beneficios registrados.",
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          )
                        else
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: beneficios
                                .map(
                                  (b) => Chip(
                                    label: Text(
                                      b,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    backgroundColor: Colors.grey.shade200, // ⬅️ fondo
                                    side: BorderSide(color: Colors.grey.shade400), // ⬅️ borde
                                    visualDensity: VisualDensity.compact,
                                  ),

                            )
                                .toList(),
                          ),

                        if (primerBeneficio.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            "Primer beneficio: $primerBeneficio (${fechaTexto()})",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _linea(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        "$label: $value",
        style: const TextStyle(fontSize: 12, color: Colors.black87),
      ),
    );
  }
}
