import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';


class TutelaSolicitudPage extends StatefulWidget {
  const TutelaSolicitudPage({super.key});

  @override
  State<TutelaSolicitudPage> createState() => _TutelaSolicitudPageState();
}

class _TutelaSolicitudPageState extends State<TutelaSolicitudPage> {
  final _textController = TextEditingController();
  String _descripcion = '';

  String _hintCategory = 'Seleccione una categoría';
  String _hintSubCategory = 'Seleccione una subcategoría';

  final Map<String, List<String>> menuOptions = {

    "Beneficios Penitenciarios": [
      "Libertad condicional",
      "Prisión domiciliaria",
      "Permiso administrativo hasta de 72 horas",
      "Redención de pena",
      "Extinción de la sanción penal"
    ],
    "Salud y Atención Médica": [
      "Atención médica oportuna y adecuada",
      "Acceso a medicamentos",
      "Acceso a tratamientos especializados",
      "Remisión a especialistas",
      "Cirugías y/o procedimientos urgentes",
      "Condiciones de higiene y salubridad",
    ],
    "Condiciones de Reclusión": [
      "Hacinamiento",
      "Acceso a agua y alimentación",
      "Malos tratos",
      "Traslados por seguridad"
    ],

    "Régimen Disciplinario": [
      "Impugnación de sanciones",
      "Revisión de procesos",
      "Acceso a beneficios"
    ],
    "Trabajo": [
      "Derecho a trabajar",
      "Capacitación laboral"
    ],
    "Educación": [
      "Capacitación laboral"
    ],
    "Visitas y Contacto": [
      "Visitas familiares",
      "Visitas conyugales",
      "Videollamadas"
    ],
    "Protección de Grupos Vulnerables": [
      "Protección a mujeres",
      "Protección a población adulta mayor",
      "Personas con discapacidad o condiciones de salud especiales",
      "Derechos de la población LGBTIQ+",
      "Derechos de Afrocolombianos",
      "Derechos de indigenas",
    ],

  };

  String? selectedCategory;
  String? selectedSubCategory;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Solicitud de servicio',
      content: SingleChildScrollView(
        child: Center(
          child: Container(
            // Si el ancho de la pantalla es mayor o igual a 800, usa 800, de lo contrario ocupa todo el ancho disponible
            width: MediaQuery.of(context).size.width >= 1000 ? 1000 : double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Acción de tutela', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                const Text('Selecciona el tema sobre el cual quieres realizar la acción de tutela',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,height: 1)),

                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Menú principal
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        dropdownColor: Colors.amber.shade50,
                        decoration: InputDecoration(
                            labelText: _hintCategory),
                        value: selectedCategory,
                        items: menuOptions.keys.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value;
                            _hintCategory = 'Categoría seleccionada'; // Cambia el hint
                            selectedSubCategory = null; // Reset del segundo menú
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Menú secundario (se muestra solo si hay una categoría seleccionada)
                    if (selectedCategory != null)
                      SizedBox(
                        width: double.infinity,
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: _hintSubCategory,
                            hintText: "Seleccione una opción", // Agrega un hint
                          ),
                          dropdownColor: Colors.amber.shade50,
                          isExpanded: true, // Permitir varias líneas
                          value: selectedSubCategory,
                          items: menuOptions[selectedCategory]!.map((String subCategory) {
                            return DropdownMenuItem<String>(
                              value: subCategory,
                              child: Text(subCategory),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSubCategory = value;
                              _hintSubCategory = 'Subcategoría seleccionada'; // Cambia el hint
                            });
                          },
                        ),
                      ),
                    const SizedBox(height: 10),

                    // Mostrar selección final
                    if (selectedCategory != null && selectedSubCategory != null)

                      Text(
                        "Seleccionaste:\n$selectedCategory → $selectedSubCategory",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: grisMedio),
                const SizedBox(height: 10),
                if (selectedCategory != null && selectedSubCategory != null)
                  const Text('Describe claramente y de manera concisa tu necesidad, no '
                      'incluyas el nombre del PPL, sitio de reclusion y demas datos similares ya que la '
                      'plataforma hara eso por ti. Solo describe el problema que quieres resolver.', style: TextStyle(
                      fontSize: 12
                  )),
                const SizedBox(height: 10),

                if (selectedCategory != null && selectedSubCategory != null)
                  TextField(
                    controller: _textController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      hintText: 'Escribe aquí',
                    ),
                  ),
                const SizedBox(height: 10),
                if (selectedCategory != null && selectedSubCategory != null)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _descripcion = _textController.text;
                      });
                      if (kDebugMode) {
                        print(_descripcion);
                      }
                    },
                    child: const Text('Guardar'),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
