import 'package:flutter/material.dart';
import '../src/colors/colors.dart';

class DelitosAutocompleteWidget extends StatefulWidget {
  final String? categoriaSeleccionada;
  final String? delitoSeleccionado;
  final Function(String, String) onDelitoChanged;

  const DelitosAutocompleteWidget({
    Key? key,
    required this.categoriaSeleccionada,
    required this.delitoSeleccionado,
    required this.onDelitoChanged,
  }) : super(key: key);

  @override
  State<DelitosAutocompleteWidget> createState() => _DelitosAutocompleteWidgetState();
}

class _DelitosAutocompleteWidgetState extends State<DelitosAutocompleteWidget> {
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _delitoController = TextEditingController();

  late final Map<String, List<String>> delitosPorCategoria;
  late final Map<String, String> delitoACategoria;
  late final List<String> listaDelitosOrdenada;

  @override
  void initState() {
    super.initState();

    delitosPorCategoria = {
      "Delitos contra el régimen constitucional y legal": [
        "Sedición"
      ],
      "Delitos contra la vida y la integridad personal": [
        "Aborto", "Feminicidio", "Homicidio", "Homicidio agravado", "Inducción al suicidio", "Lesiones personales", "Omisión de socorro", "Tentativa de homicidio",
        "Tentativa de femenicidio",
      ],
      "Delitos contra personas y bienes protegidos por el DIH": [
        "Actos de terrorismo", "Homicidio en persona protegida", "Toma de rehenes", "Tortura en persona protegida",
      ],
      "Delitos contra la libertad individual y otras garantías": [
        "Amenazas", "Desaparición forzada", "Secuestro extorsivo", "Secuestro simple", "Tráfico de menores", "Trata de personas", "Violación de habitación ajena",
      ],
      "Delitos contra la libertad y formación sexuales": [
        "Acceso carnal abusivo con menor de 14 años", "Acceso carnal violento", "Actos sexuales abusivos", "Estímulo a la prostitución de menores", "Pornografía infantil", "Proxenetismo con menor",
      ],
      "Delitos contra el patrimonio económico": [
        "Abuso de confianza", "Daño en bien ajeno", "Estafa", "Extorsión", "Hurto calificado y agravado", "Hurto simple", "Receptación", "Tentativa de hurto", "Tentativa de hurto calificado",
      ],
      "Delitos contra la seguridad pública": [
        "Concierto para delinquir", "Falsedad en documento privado", "Falsedad en documento público", "Instigación a delinquir", "Terrorismo", "Amenaza terrorista",
      ],
      "Delitos contra la seguridad pública y tranquilidad ciudadana": [
        "Fabricación de explosivos", "Fabricación, tráfico o porte de armas de fuego", "Perturbación del orden público", "Porte de armas de uso privativo",
      ],
      "Delitos contra la salud pública": [
        "Cultivo ilícito", "Distribución ilegal de medicamentos", "Microtráfico", "Tráfico, fabricación o porte de estupefacientes",
      ],
      "Delitos contra la administración pública": [
        "Cohecho propio", "Concusión", "Enriquecimiento ilícito", "Omisión de denuncia", "Peculado por apropiación", "Prevaricato por acción u omisión","Simulación de investidura"
      ],
      "Delitos contra la fe pública": [
        "Alteración de documento de identidad", "Falsedad material en documento público", "Falsedad personal", "Suplantación de identidad", "Uso de documento falso",
      ],
      "Delitos contra la familia": [
        "Abandono de menor o persona en estado de vulnerabilidad", "Bigamia", "Incumplimiento de obligaciones alimentarias", "Violencia intrafamiliar", "Inasistencia alimentaria"
      ],
      "Delitos informáticos": [
        "Acceso abusivo a un sistema informático", "Interceptación de datos informáticos", "Obstrucción ilegítima de datos", "Suplantación de sitios web", "Violación de datos personales",
      ],
      "Delitos contra el medio ambiente": [
        "Caza o tráfico de fauna silvestre", "Contaminación ambiental", "Deforestación ilegal", "Explotación ilícita de yacimientos mineros",
      ],
      "Otros delitos": [
        "Evasión de presos", "Fuga de presos", "Lavado de activos", "Omisión del agente retenedor", "Violación de medidas sanitarias",
      ],
    };

    delitoACategoria = {};
    for (var entry in delitosPorCategoria.entries) {
      for (var delito in entry.value) {
        delitoACategoria[delito] = entry.key;
      }
    }

    listaDelitosOrdenada = delitoACategoria.keys.toList()..sort();

    _delitoController.text = widget.delitoSeleccionado ?? '';
    _categoriaController.text =
        delitoACategoria[widget.delitoSeleccionado ?? ''] ?? widget.categoriaSeleccionada ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Delito por el cual está condenado",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.1),
          ),
          const SizedBox(height: 20),

          Container(
            color: blanco,
            child: Autocomplete<String>(
              initialValue: TextEditingValue(text: widget.delitoSeleccionado ?? ''),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                return listaDelitosOrdenada.where((delito) =>
                    delito.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String nuevoDelito) {
                final categoria = delitoACategoria[nuevoDelito] ?? "Otros delitos";
                _delitoController.text = nuevoDelito;
                _categoriaController.text = categoria;
                widget.onDelitoChanged(categoria, nuevoDelito);
                setState(() {}); // fuerza el rebuild
              },
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                controller.text = _delitoController.text;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: _inputDecoration("Buscar delito").copyWith(
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        _delitoController.clear();
                        _categoriaController.clear();
                        widget.onDelitoChanged('', '');
                        setState(() {}); // fuerza actualización de la UI
                      },
                    )
                        : null,
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    color: Colors.amber.shade50,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(option),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  )

                );
              },
            ),
          ),

          const SizedBox(height: 20),

          TextFormField(
            controller: _categoriaController,
            readOnly: true,
            decoration: _inputDecoration("Categoría del delito"),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }
}

