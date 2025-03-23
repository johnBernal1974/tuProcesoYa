import 'package:flutter/material.dart';

import '../src/colors/colors.dart';

class DelitosDropdownWidget extends StatelessWidget {
  final String? categoriaSeleccionada;
  final String? delitoSeleccionado;
  final Function(String, String) onDelitoChanged;

  const DelitosDropdownWidget({
    Key? key,
    required this.categoriaSeleccionada,
    required this.delitoSeleccionado,
    required this.onDelitoChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, List<String>> delitosPorCategoria = {
      "Delitos contra la vida y la integridad personal": [
        "Homicidio",
        "Feminicidio",
        "Lesiones personales",
        "Inducción al suicidio",
        "Aborto",
        "Omisión de socorro"
      ],
      "Delitos contra personas y bienes protegidos por el DIH": [
        "Homicidio en persona protegida",
        "Tortura en persona protegida",
        "Actos de terrorismo",
        "Toma de rehenes"
      ],
      "Delitos contra la libertad individual y otras garantías": [
        "Secuestro extorsivo",
        "Secuestro simple",
        "Desaparición forzada",
        "Amenazas",
        "Tráfico de menores",
        "Trata de personas",
        "Violación de habitación ajena"
      ],
      "Delitos contra la libertad y formación sexuales": [
        "Acceso carnal violento",
        "Acceso carnal abusivo con menor de 14 años",
        "Actos sexuales abusivos",
        "Pornografía infantil",
        "Proxenetismo con menor",
        "Estímulo a la prostitución de menores"
      ],
      "Delitos contra el patrimonio económico": [
        "Hurto calificado y agravado",
        "Hurto simple",
        "Extorsión",
        "Estafa",
        "Abuso de confianza",
        "Receptación",
        "Daño en bien ajeno"
      ],
      "Delitos contra la seguridad pública": [
        "Concierto para delinquir",
        "Terrorismo",
        "Amenaza terrorista",
        "Instigación a delinquir",
        "Falsedad en documento público",
        "Falsedad en documento privado"
      ],
      "Delitos contra la seguridad pública y tranquilidad ciudadana": [
        "Fabricación, tráfico o porte de armas de fuego",
        "Porte de armas de uso privativo",
        "Fabricación de explosivos",
        "Perturbación del orden público"
      ],
      "Delitos contra la salud pública": [
        "Tráfico, fabricación o porte de estupefacientes",
        "Cultivo ilícito",
        "Microtráfico",
        "Distribución ilegal de medicamentos"
      ],
      "Delitos contra la administración pública": [
        "Cohecho propio",
        "Concusión",
        "Peculado por apropiación",
        "Enriquecimiento ilícito",
        "Prevaricato por acción u omisión",
        "Omisión de denuncia"
      ],
      "Delitos contra la fe pública": [
        "Falsedad personal",
        "Falsedad material en documento público",
        "Uso de documento falso",
        "Suplantación de identidad",
        "Alteración de documento de identidad"
      ],
      "Delitos contra la familia": [
        "Violencia intrafamiliar",
        "Incumplimiento de obligaciones alimentarias",
        "Abandono de menor o persona en estado de vulnerabilidad",
        "Bigamia"
      ],
      "Delitos informáticos": [
        "Acceso abusivo a un sistema informático",
        "Violación de datos personales",
        "Suplantación de sitios web",
        "Interceptación de datos informáticos",
        "Obstrucción ilegítima de datos"
      ],
      "Delitos contra el medio ambiente": [
        "Contaminación ambiental",
        "Deforestación ilegal",
        "Caza o tráfico de fauna silvestre",
        "Explotación ilícita de yacimientos mineros"
      ],
      "Otros delitos": [
        "Lavado de activos",
        "Omisión del agente retenedor",
        "Evasión de presos",
        "Fuga de presos",
        "Violación de medidas sanitarias"
      ]
      // Agrega más categorías aquí
    };

    final List<String> delitosDisponibles = categoriaSeleccionada != null
        ? delitosPorCategoria[categoriaSeleccionada!] ?? []
        : [];
    print("🔎 categoriaDelito: $categoriaSeleccionada");
    print("🔎 selectedDelito: $delitoSeleccionado");


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
          DropdownButtonFormField<String>(
            dropdownColor: blanco,
            isExpanded: true,
            value: categoriaSeleccionada,
            decoration: _inputDecoration("Categoría del delito"),
            items: delitosPorCategoria.keys.map((String categoria) {
              return DropdownMenuItem<String>(
                value: categoria,
                child: Text(categoria),
              );
            }).toList(),
            onChanged: (String? nuevaCategoria) {
              if (nuevaCategoria != null) {
                onDelitoChanged(nuevaCategoria, '');
              }
            },
          ),
          const SizedBox(height: 20),

          delitosDisponibles.isNotEmpty
              ? DropdownButtonFormField<String>(
            dropdownColor: blanco,
            isExpanded: true,
            value: (delitoSeleccionado != null &&
                delitoSeleccionado!.isNotEmpty &&
                delitosDisponibles.contains(delitoSeleccionado))
                ? delitoSeleccionado
                : null,

            decoration: _inputDecoration("Delito"),
            items: delitosDisponibles.map((String delito) {
              return DropdownMenuItem<String>(
                value: delito,
                child: Text(delito),
              );
            }).toList(),
            onChanged: (String? nuevoDelito) {
              if (nuevoDelito != null && categoriaSeleccionada != null) {
                onDelitoChanged(categoriaSeleccionada!, nuevoDelito);
              }
            },
          )
              : const SizedBox.shrink(),


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
