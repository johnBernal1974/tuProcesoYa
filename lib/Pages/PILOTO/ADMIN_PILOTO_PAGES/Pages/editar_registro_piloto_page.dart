import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../src/colors/colors.dart';
import '../widgets_piloto/formulario_estadias_reclusión_piloto.dart';
import '../widgets_piloto/tabla_vista_estadias_reclusion_piloto.dart';




class EditRegistroPilotoPage extends StatefulWidget {
  final String docId;
  final String titulo;

  const EditRegistroPilotoPage({
    super.key,
    required this.docId,
    this.titulo = "Edición de pre-registro (Piloto)",
  });

  @override
  State<EditRegistroPilotoPage> createState() => _EditRegistroPilotoPageState();
}

class _EditRegistroPilotoPageState extends State<EditRegistroPilotoPage> {
  bool _guardando = false;
  bool _controllersListos = false;

  // --------- Controllers PPL ----------
  final _pplNombres = TextEditingController();
  final _pplApellidos = TextEditingController();
  final _pplTipoDocumento = TextEditingController();
  final _pplNumeroDocumento = TextEditingController();
  final _pplNui = TextEditingController();
  final _pplTd = TextEditingController();
  final _pplPatio = TextEditingController();
  final _pplDelito = TextEditingController();
  final _pplNumeroProceso = TextEditingController();

  //DateTime? _fechaCaptura;

  // --------- Controllers ACUDIENTE ----------
  final _acuNombres = TextEditingController();
  final _acuApellidos = TextEditingController();
  final _acuTipoDocumento = TextEditingController();
  final _acuNumeroDocumento = TextEditingController();
  final _acuCelular = TextEditingController();
  final _acuParentesco = TextEditingController();

  // Estado general
  String _estado = "pendiente";


  final _centroSel = ValueNotifier<CatalogItem?>(null);
  final _jConSel   = ValueNotifier<CatalogItem?>(null);
  final _jEjeSel   = ValueNotifier<CatalogItem?>(null);

  final ValueNotifier<String> _estadoVN = ValueNotifier<String>("pendiente");
  bool _editandoCentro = false;
  bool _editandoJCon = false;
  bool _editandoJEje = false;

  List<CatalogItem> _centros = [];
  bool _cargandoCentros = false;






  @override
  void dispose() {
    _pplNombres.dispose();
    _pplApellidos.dispose();
    _pplTipoDocumento.dispose();
    _pplNumeroDocumento.dispose();
    _pplNui.dispose();
    _pplTd.dispose();
    _pplPatio.dispose();
    _pplDelito.dispose();
    _pplNumeroProceso.dispose();

    _acuNombres.dispose();
    _acuApellidos.dispose();
    _acuTipoDocumento.dispose();
    _acuNumeroDocumento.dispose();
    _acuCelular.dispose();
    _acuParentesco.dispose();

    _estadoVN.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance.collection('pre_registro_ppl').doc(widget.docId);

    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
        backgroundColor: primary,
        title: Text(widget.titulo, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: "Refrescar",
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        onPressed: _guardando ? null : () => _guardarCambios(docRef),
        icon: _guardando
            ? const SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : const Icon(Icons.save, color: Colors.white),
        label: const Text("Guardar", style: TextStyle(color: Colors.white)),
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("❌ No se encontró el preregistro", style: TextStyle(color: Colors.red)),
            );
          }

          final data = (snapshot.data!.data() as Map<String, dynamic>?) ?? {};
          final ppl = (data['ppl'] as Map<String, dynamic>?) ?? {};
          final acudiente = (data['acudiente'] as Map<String, dynamic>?) ?? {};

          final selecciones = (data['selecciones'] as Map<String, dynamic>?) ?? {};


          // ✅ Cargar controllers 1 sola vez por apertura
          if (!_controllersListos) {
            final centroId = selecciones['centro_reclusion_id']?.toString();
            final jConId   = selecciones['juzgado_conocimiento_id']?.toString();
            final jEjeId   = selecciones['juzgado_ejecucion_id']?.toString();

            final centroNombre = (selecciones['centro_reclusion_nombre'] ?? '').toString();
            final centroNombreLargo = (selecciones['centro_reclusion_nombre_largo'] ??
                selecciones['centro_reclusion_nombre'] ??
                '')
                .toString();

            if ((centroId ?? '').isNotEmpty) {
              _centroSel.value = CatalogItem(
                id: centroId!,
                nombreCorto: centroNombre,
                nombreLargo: centroNombreLargo,
                regionalNombre: '', // si no lo guardas en selecciones, déjalo vacío
                direccion: '',      // igual
                telefono: '',
                correos: const {},  // opcional: si guardas correos en selecciones, aquí los pones
              );
            } else {
              _centroSel.value = null;
            }

            _jConSel.value   = pickById(kJuzgadosConocimientoPiloto, jConId);
            _jEjeSel.value   = pickById(kJuzgadosEjecucionPiloto, jEjeId);

            _estadoVN.value = (data['estado'] ?? 'pendiente').toString();


            _estado = (data['estado'] ?? 'pendiente').toString();

            _pplNombres.text = (ppl['nombres'] ?? '').toString();
            _pplApellidos.text = (ppl['apellidos'] ?? '').toString();
            _pplTipoDocumento.text = (ppl['tipo_documento'] ?? '').toString();
            _pplNumeroDocumento.text = (ppl['numero_documento'] ?? '').toString();
            _pplNui.text = (ppl['nui'] ?? '').toString();
            _pplTd.text = (ppl['td'] ?? '').toString();
            _pplPatio.text = (ppl['patio'] ?? '').toString();
            _pplDelito.text = (ppl['delito'] ?? '').toString();
            _pplNumeroProceso.text = (ppl['numero_proceso'] ?? '').toString();

            // final ts = ppl['fecha_captura'];
            // if (ts is Timestamp) _fechaCaptura = ts.toDate();

            _acuNombres.text = (acudiente['nombres'] ?? '').toString();
            _acuApellidos.text = (acudiente['apellidos'] ?? '').toString();
            _acuTipoDocumento.text = (acudiente['tipo_documento'] ?? '').toString();
            _acuNumeroDocumento.text = (acudiente['numero_documento'] ?? '').toString();
            _acuCelular.text = (acudiente['celular'] ?? '').toString();
            _acuParentesco.text = (acudiente['parentesco'] ?? '').toString();

            _controllersListos = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _cardResumen(data, ppl, acudiente),

                const SizedBox(height: 12),

                _cardSeccion(
                  titulo: "Estado del preregistro",
                  icono: Icons.info_outline,
                  child: ValueListenableBuilder<String>(
                    valueListenable: _estadoVN,
                    builder: (_, estado, __) {
                      return DropdownButtonFormField<String>(
                        value: estado,
                        items: const [
                          DropdownMenuItem(value: "pendiente", child: Text("Pendiente")),
                          DropdownMenuItem(value: "en_revision", child: Text("En revisión")),
                          DropdownMenuItem(value: "aprobado", child: Text("Aprobado")),
                          DropdownMenuItem(value: "rechazado", child: Text("Rechazado")),
                        ],
                        onChanged: (v) => _estadoVN.value = (v ?? "pendiente"),
                        decoration: _dec("Estado"),
                      );
                    },
                  ),
                ),

                _cardSeccion(
                  titulo: "Datos del PPL",
                  icono: Icons.person,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _pplNombres, decoration: _dec("Nombres"))),
                          const SizedBox(width: 10),
                          Expanded(child: TextFormField(controller: _pplApellidos, decoration: _dec("Apellidos"))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _pplTipoDocumento, decoration: _dec("Tipo documento"))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _pplNumeroDocumento,
                              keyboardType: TextInputType.number,
                              decoration: _dec("Número documento"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _pplNui, decoration: _dec("NUI"))),
                          const SizedBox(width: 10),
                          Expanded(child: TextFormField(controller: _pplTd, decoration: _dec("TD"))),
                          const SizedBox(width: 10),
                          Expanded(child: TextFormField(controller: _pplPatio, decoration: _dec("Patio"))),
                        ],
                      ),
                      const SizedBox(height: 10),

                      _cardSeccion(
                        titulo: "Estadías (Piloto)",
                        icono: Icons.table_chart_outlined,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWideScreen = constraints.maxWidth > 900;

                            if (isWideScreen) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: FormularioEstadiaAdminPiloto(pplId: widget.docId),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 4,
                                    child: TablaEstadiasAdminPiloto(pplId: widget.docId),
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  FormularioEstadiaAdminPiloto(pplId: widget.docId),
                                  const SizedBox(height: 16),
                                  TablaEstadiasAdminPiloto(pplId: widget.docId),
                                ],
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(controller: _pplDelito, decoration: _dec("Delito")),
                      const SizedBox(height: 10),
                      TextFormField(controller: _pplNumeroProceso, decoration: _dec("Número de proceso")),
                    ],
                  ),
                ),

                _cardSeccion(
                  titulo: "Selecciones (Piloto)",
                  icono: Icons.account_tree_outlined,
                  child: Column(
                    children: [
                      // 🟣 Centro de reclusión
                      ValueListenableBuilder<CatalogItem?>(
                        valueListenable: _centroSel,
                        builder: (_, value, __) {
                          if (!_editandoCentro && value != null) {
                            return Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: value.nombreCorto,
                                    readOnly: true,
                                    decoration: _dec("Centro de reclusión").copyWith(
                                      suffixIcon: IconButton(
                                        tooltip: "Cambiar",
                                        onPressed: () async {
                                          setState(() => _editandoCentro = true);
                                          await _cargarCentrosSiHaceFalta();
                                        },

                                        icon: const Icon(Icons.edit),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

                          // Modo edición (mostrar buscador)
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_cargandoCentros)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                              else
                                _autoCatalog(
                                  label: "Centro de reclusión",
                                  value: value,
                                  items: _centros, // ✅ List<CatalogItem>
                                  onSelected: (v) {
                                    _centroSel.value = v;
                                    setState(() => _editandoCentro = false);
                                  },
                                  onClear: () => _centroSel.value = null,
                                ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => setState(() => _editandoCentro = false),
                                  child: const Text("Cancelar"),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 10),

                      // 🔵 Juzgado de conocimiento
                      ValueListenableBuilder<CatalogItem?>(
                        valueListenable: _jConSel,
                        builder: (_, value, __) {
                          if (!_editandoJCon && value != null) {
                            return TextFormField(
                              initialValue: value.nombreCorto,
                              readOnly: true,
                              decoration: _dec("Juzgado de conocimiento").copyWith(
                                suffixIcon: IconButton(
                                  tooltip: "Cambiar",
                                  onPressed: () => setState(() => _editandoJCon = true),
                                  icon: const Icon(Icons.edit),
                                ),
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _autoCatalog(
                                label: "Juzgado de conocimiento",
                                value: value,
                                items: kJuzgadosConocimientoPiloto,
                                onSelected: (v) {
                                  _jConSel.value = v;
                                  setState(() => _editandoJCon = false);
                                },
                                onClear: () => _jConSel.value = null,
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => setState(() => _editandoJCon = false),
                                  child: const Text("Cancelar"),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 10),

                      // 🟢 Juzgado de ejecución de penas
                      ValueListenableBuilder<CatalogItem?>(
                        valueListenable: _jEjeSel,
                        builder: (_, value, __) {
                          if (!_editandoJEje && value != null) {
                            return TextFormField(
                              initialValue: value.nombreCorto,
                              readOnly: true,
                              decoration: _dec("Juzgado de ejecución de penas").copyWith(
                                suffixIcon: IconButton(
                                  tooltip: "Cambiar",
                                  onPressed: () => setState(() => _editandoJEje = true),
                                  icon: const Icon(Icons.edit),
                                ),
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _autoCatalog(
                                label: "Juzgado de ejecución de penas",
                                value: value,
                                items: kJuzgadosEjecucionPiloto, // ✅ por ahora
                                onSelected: (v) {
                                  _jEjeSel.value = v;
                                  setState(() => _editandoJEje = false);
                                },
                                onClear: () => _jEjeSel.value = null,
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => setState(() => _editandoJEje = false),
                                  child: const Text("Cancelar"),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 14),
                    ],
                  ),
                ),


                _cardSeccion(
                  titulo: "Datos del acudiente",
                  icono: Icons.family_restroom,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _acuNombres, decoration: _dec("Nombres"))),
                          const SizedBox(width: 10),
                          Expanded(child: TextFormField(controller: _acuApellidos, decoration: _dec("Apellidos"))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _acuTipoDocumento, decoration: _dec("Tipo documento"))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _acuNumeroDocumento,
                              keyboardType: TextInputType.number,
                              decoration: _dec("Número documento"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _acuCelular,
                              keyboardType: TextInputType.phone,
                              decoration: _dec("Celular"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: TextFormField(controller: _acuParentesco, decoration: _dec("Parentesco"))),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 90),
              ],
            ),
          );
        },
      ),
    );
  }

  CatalogItem? pickById(List<CatalogItem> list, String? id) {
    if (id == null) return null;
    for (final item in list) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> _cargarCentrosSiHaceFalta() async {
    if (_centros.isNotEmpty || _cargandoCentros) return;

    setState(() => _cargandoCentros = true);

    final snap = await FirebaseFirestore.instance
        .collection('centros_reclusion')
        .where('activo', isEqualTo: true)
        .get();

    final items = snap.docs.map((d) => CatalogItem.fromDoc(d)).toList()
      ..sort((a, b) => a.nombreCorto.toLowerCase().compareTo(b.nombreCorto.toLowerCase()));

    if (!mounted) return;
    setState(() {
      _centros = items;
      _cargandoCentros = false;
    });
  }



  Widget _autoCatalog({
    required String label,
    required CatalogItem? value,
    required List<CatalogItem> items,
    required void Function(CatalogItem v) onSelected,
    required VoidCallback onClear,
  }) {
    return Autocomplete<CatalogItem>(
      initialValue: TextEditingValue(text: value == null ? "" : value.nombreCorto),
      displayStringForOption: (o) => o.nombreCorto,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final q = textEditingValue.text.trim().toLowerCase();
        if (q.isEmpty) return items;
        return items.where((e) {
          final a = (e.nombreCorto ?? "").toLowerCase();
          final b = (e.nombreLargo ?? "").toLowerCase();
          return a.contains(q) || b.contains(q);
        });
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        final tieneValor = (value != null);

        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: _dec(label).copyWith(
            hintText: "Buscar…",
            suffixIcon: !tieneValor
                ? const Icon(Icons.search)
                : IconButton(
              tooltip: "Limpiar",
              onPressed: () {
                controller.clear();
                onClear();
                FocusScope.of(context).requestFocus(focusNode);
              },
              icon: const Icon(Icons.clear),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelectedOpt, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 760),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final opt = options.elementAt(index);

                  final titulo = opt.nombreCorto ?? opt.nombreLargo ?? "";
                  final subtitulo = (opt.nombreLargo != null && opt.nombreCorto != opt.nombreLargo)
                      ? opt.nombreLargo
                      : null;

                  return ListTile(
                    dense: true,
                    title: Text(titulo, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: subtitulo == null
                        ? null
                        : Text(subtitulo, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onSelectedOpt(opt),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }


  Future<void> _guardarCambios(DocumentReference docRef) async {
    setState(() => _guardando = true);

    try {
      await docRef.update({
        "estado": _estadoVN.value,
        "updated_at": FieldValue.serverTimestamp(),

        "ppl": {
          "nombres": _pplNombres.text.trim(),
          "apellidos": _pplApellidos.text.trim(),
          "tipo_documento": _pplTipoDocumento.text.trim(),
          "numero_documento": _pplNumeroDocumento.text.trim(),
          "nui": _pplNui.text.trim(),
          "td": _pplTd.text.trim(),
          "patio": _pplPatio.text.trim(),
          "delito": _pplDelito.text.trim(),
          "numero_proceso": _pplNumeroProceso.text.trim(),

        },

        "selecciones": {
          // 🟣 Centro de reclusión
          "centro_reclusion_id": _centroSel.value?.id,
          "centro_reclusion_nombre": _centroSel.value?.nombreCorto,

          // 🔵 Juzgado de conocimiento
          "juzgado_conocimiento_id": _jConSel.value?.id,
          "juzgado_conocimiento_nombre":
          _jConSel.value?.nombreLargo ?? _jConSel.value?.nombreCorto,

          // 🟢 Juzgado de ejecución de penas
          "juzgado_ejecucion_id": _jEjeSel.value?.id,
          "juzgado_ejecucion_nombre":
          _jEjeSel.value?.nombreLargo ?? _jEjeSel.value?.nombreCorto,
        },

        "acudiente": {
          "nombres": _acuNombres.text.trim(),
          "apellidos": _acuApellidos.text.trim(),
          "tipo_documento": _acuTipoDocumento.text.trim(),
          "numero_documento": _acuNumeroDocumento.text.trim(),
          "celular": _acuCelular.text.trim(),
          "celular_raw": _acuCelular.text.trim(),
          "parentesco": _acuParentesco.text.trim(),
        },
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Cambios guardados")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error guardando: $e")),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _cardResumen(
      Map<String, dynamic> data,
      Map<String, dynamic> ppl,
      Map<String, dynamic> acudiente,
      ) {
    final pplNombre =
    "${(ppl['nombres'] ?? '').toString()} ${(ppl['apellidos'] ?? '').toString()}"
        .trim();

    final selecciones = (data['selecciones'] as Map<String, dynamic>?) ?? {};

    // 🔑 leer SOLO lo guardado
    final centroNombreCorto =
    (selecciones['centro_reclusion_nombre'] ?? '—').toString();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pplNombre.isEmpty ? "PPL (sin nombre)" : pplNombre,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _chip("Centro", centroNombreCorto),
                _chip("Estado", (data['estado'] ?? 'pendiente').toString()),
                _chip("DocId", widget.docId),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text("$label: $value", style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _cardSeccion({
    required String titulo,
    required IconData icono,
    required Widget child,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: primary),
                const SizedBox(width: 10),
                Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label) {
    const borderColor = Color(0xFFB0B0B0); // gris medio visible
    const focusedColor = primary; // tu color institucional

    return InputDecoration(
      labelText: label,
      isDense: true,

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor, width: 1.2),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: focusedColor, width: 1.6),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.4),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.6),
      ),

      labelStyle: const TextStyle(color: Colors.black87),
      floatingLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
    );
  }

}

class CatalogItem {
  final String id;
  final String nombreCorto;
  final String nombreLargo;
  final String regionalNombre;
  final String direccion;
  final String telefono;
  final Map<String, dynamic> correos;

  const CatalogItem({
    required this.id,
    required this.nombreCorto,
    required this.nombreLargo,
    required this.regionalNombre,
    required this.direccion,
    required this.telefono,
    required this.correos,
  });

  factory CatalogItem.fromDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return CatalogItem(
      id: doc.id,
      nombreCorto: (d['nombreCorto'] ?? '').toString(),
      nombreLargo: (d['nombreLargo'] ?? '').toString(),
      regionalNombre: (d['regionalNombre'] ?? '').toString(),
      direccion: (d['direccion'] ?? '').toString(),
      telefono: (d['telefono'] ?? '').toString(),
      correos: (d['correos'] as Map<String, dynamic>?) ?? {},
    );
  }

  String get fullText =>
      "${nombreCorto} ${nombreLargo} ${regionalNombre} ${direccion}".toLowerCase();
}



const List<CatalogItem> kJuzgadosConocimientoPiloto = [
  CatalogItem(
    id: "jpc_conocimiento_bogota",
    nombreCorto: "Juzgado Penal del Circuito – Bogotá",
    nombreLargo: "Juzgado Penal del Circuito con Función de Conocimiento de Bogotá",
    regionalNombre: "",
    direccion: "",
    telefono: "",
    correos: const {},
  ),
  // ...
];

const List<CatalogItem> kJuzgadosEjecucionPiloto = [
  CatalogItem(
    id: "jepms_1",
    nombreCorto: "Juzgado 1° de Ejecución de Penas",
    nombreLargo: "Juzgado Primero de Ejecución de Penas y Medidas de Seguridad",
    regionalNombre: "",
    direccion: "",
    telefono: "",
    correos: const {},
  ),
  // ...
];





