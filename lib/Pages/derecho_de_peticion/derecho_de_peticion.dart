import 'package:flutter/material.dart';

import '../../commons/main_layaout.dart';
import '../../src/colors/colors.dart';

class DerechoDePeticionPage extends StatefulWidget {
  const DerechoDePeticionPage({super.key});

  @override
  State<DerechoDePeticionPage> createState() => _DerechoDePeticionPageState();
}

class _DerechoDePeticionPageState extends State<DerechoDePeticionPage> {
  final _textController = TextEditingController();
  String _descripcion = '';

  String _hintCategory = 'Seleccione una categoría';
  String _hintSubCategory = 'Seleccione una subcategoría';

  final Map<String, List<String>> menuOptions = {
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
    "Beneficios Penitenciarios": [
      "Libertad condicional",
      "Redención de pena",
      "Resocialización",
      "Revisión de pena"
    ],
    "Garantías Procesales": [
      "Estado del proceso",
      "Defensa efectiva",
      "Retardos procesales",
      "Revisión de medida"
    ],
    "Régimen Disciplinario": [
      "Impugnación de sanciones",
      "Revisión de procesos",
      "Acceso a beneficios"
    ],
    "Trabajo y Educación": [
      "Acceso a educación",
      "Derecho a trabajar",
      "Capacitación laboral"
    ],
    "Visitas y Contacto": [
      "Visitas familiares",
      "Visitas conyugales",
      "Videollamadas"
    ],
    "Protección de Grupos Vulnerables": [
      "Derechos de la población LGBTIQ+",
      "Protección a mujeres",
      "Personas con discapacidad"
    ],
    "Indemnización o Reparación": [
      "Daños en pertenencias",
      "Salud afectada por negligencia"
    ]
  };

  String? selectedCategory;
  String? selectedSubCategory;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Solicitud de servicio',
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Derecho de Petición', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('El derecho de petición es un derecho fundamental que permite a los ciudadanos solicitar información,'
                ' realizar peticiones y presentar quejas ante las autoridades públicas.', style: TextStyle(
              fontSize: 11
            ),),
            const SizedBox(height: 20),
            const Text('Selecciona el tema sobre el cual quieres realizar el derecho de petición', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,height: 1)),

            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Menú principal
                SizedBox(
                  width: double.infinity,
                  child: DropdownButtonFormField<String>(
                    dropdownColor: Colors.deepPurple.shade100,
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
                      print("Esta es la categoria seleccionada*************************$selectedCategory");
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
                      dropdownColor: Colors.grey.shade400,
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
                        print("Esta es la subcategoria seleccionada*************************$selectedSubCategory");
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
                print(_descripcion);
              },
              child: const Text('Guardar'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}