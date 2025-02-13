
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../commons/file_picker_helper.dart';
import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';

class DerechoDePeticionSolicitudPage extends StatefulWidget {
  const DerechoDePeticionSolicitudPage({super.key});

  @override
  State<DerechoDePeticionSolicitudPage> createState() => _DerechoDePeticionSolicitudPageState();
}

class _DerechoDePeticionSolicitudPageState extends State<DerechoDePeticionSolicitudPage> {
  final _textController = TextEditingController();
  String _descripcion = '';

  String _hintCategory = 'Seleccione una categoría';
  String _hintSubCategory = 'Seleccione una subcategoría';
  String? fileName; // Para almacenar el nombre del archivo seleccionado

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

  Future<void> pickFile() async {
    String? selectedFile = await FilePickerHelper.pickFile();
    if (selectedFile != null) {
      setState(() {
        fileName = selectedFile;
      });
    }
  }

  Widget adjuntarDocumento(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: pickFile,
          child: const Row(
            children: [
              Icon(Icons.attach_file, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text(
                "Adjuntar documento",
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        if (fileName != null) ...[
          const SizedBox(height: 8),
          Text(
            "Archivo seleccionado: $fileName",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }




  String obtenerInstruccion(String? categoria, String? subCategoria) {
    if (categoria == null || subCategoria == null) return "";

    Map<String, Map<String, String>> instrucciones = {
      "Beneficios Penitenciarios": {
        "Libertad condicional": "2. Si cuentas con documentos que respalden tu solicitud, como antecedentes penales, informes de conducta o requisitos legales, adjúntalos.",
        "Prisión domiciliaria": "2. Si tienes documentos médicos, pruebas de arraigo o requisitos legales que respalden tu solicitud, adjúntalos.",
        "Permiso administrativo hasta de 72 horas": "2. Si cuentas con justificación legal, motivos humanitarios o documentos de respaldo, adjúntalos.",
        "Redención de pena": "2. Adjunta registros de estudio o trabajo dentro del centro penitenciario.",
        "Extinción de la sanción penal": "2. Si tienes documentos judiciales que respalden tu solicitud, adjúntalos."
      },
      "Salud y Atención Médica": {
        "Atención médica oportuna y adecuada": "2. Si tienes exámenes médicos o solicitudes previas sin respuesta, adjúntalas.",
        "Acceso a medicamentos": "2. Adjunta fórmulas médicas o documentos que certifiquen la necesidad del medicamento.",
        "Acceso a tratamientos especializados": "2. Si cuentas con dictámenes médicos o autorizaciones previas, adjúntalas.",
        "Remisión a especialistas": "2. Adjunta órdenes médicas que justifiquen la remisión.",
        "Cirugías y/o procedimientos urgentes": "2. Si tienes exámenes médicos o diagnósticos que respalden la urgencia, adjúntalos.",
        "Condiciones de higiene y salubridad": "2. Si has documentado pruebas de condiciones insalubres (fotos, reportes), adjúntalas."
      },
      "Condiciones de Reclusión": {
        "Hacinamiento": "2. Si tienes reportes o documentos que evidencien el problema, adjúntalos.",
        "Acceso a agua y alimentación": "2. Si tienes pruebas de racionamiento insuficiente o falta de agua, adjúntalas.",
        "Malos tratos": "2. Si cuentas con testimonios, denuncias previas o evidencia, adjúntalas.",
        "Traslados por seguridad": "2. Si tienes documentos que respalden la solicitud de traslado, adjúntalos."
      },
      "Trabajo": {
        "Derecho a trabajar": "2. Adjunta solicitudes previas o certificaciones de habilidades laborales.",
        "Capacitación laboral": "2. Si has solicitado capacitación antes y no la has recibido, adjunta la evidencia."
      },
      "Educación": {
        "Capacitación laboral": "2. Si tienes solicitudes previas o certificados académicos, adjúntalos."
      },
      "Visitas y Contacto": {
        "Visitas familiares": "2. Si tienes restricciones previas o solicitudes sin respuesta, adjunta la documentación.",
        "Visitas conyugales": "2. Adjunta pruebas de relación conyugal o documentos requeridos.",
        "Videollamadas": "2. Si has solicitado videollamadas y no las has recibido, adjunta la evidencia."
      },
      "Protección de Grupos Vulnerables": {
        "Protección a mujeres": "2. Si tienes pruebas de vulnerabilidad o antecedentes de violencia, adjúntalos.",
        "Protección a población adulta mayor": "2. Adjunta documentos que certifiquen la edad o necesidades especiales.",
        "Personas con discapacidad o condiciones de salud especiales": "2. Si tienes certificaciones médicas de discapacidad o condiciones especiales de salud, adjúntalas.",
        "Derechos de la población LGBTIQ+": "2. Si has sufrido discriminación o malos tratos, adjunta pruebas o denuncias.",
        "Derechos de Afrocolombianos": "2. Si has experimentado vulneración de derechos, adjunta pruebas.",
        "Derechos de indígenas": "2. Si hay violaciones a derechos étnicos, adjunta pruebas documentales."
      },
      "Régimen Disciplinario": {
        "Impugnación de sanciones": "2. Si tienes documentos o pruebas que demuestren irregularidades en la sanción impuesta, adjúntalos.",
        "Revisión de procesos": "2. Si consideras que tu proceso disciplinario tuvo fallos, adjunta pruebas o documentos legales.",
        "Acceso a beneficios": "2. Si has solicitado beneficios y no han sido concedidos, adjunta solicitudes previas y respuestas oficiales."
      },
    };

    return instrucciones[categoria]?[subCategoria] ?? "Si tienes documentos que respalden tu solicitud, adjúntalos.";
  }

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
                const Text('Derecho de Petición', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                const Text('Selecciona el tema sobre el cual quieres realizar el derecho de petición',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,height: 1)),

                const SizedBox(height: 25),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Menú principal
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        dropdownColor: Colors.amber.shade50,
                        decoration: InputDecoration(
                          labelText: _hintCategory,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey), // Borde gris
                            borderRadius: BorderRadius.circular(8.0), // Esquinas redondeadas opcionales
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey, width: 2.0), // Borde más grueso cuando está enfocado
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
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

                    const SizedBox(height: 15),
                    // Menú secundario (se muestra solo si hay una categoría seleccionada)
                    if (selectedCategory != null)
                      SizedBox(
                        width: double.infinity,
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: _hintSubCategory,
                            hintText: "Seleccione una opción", // Agrega un hint
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.grey), // Borde gris
                              borderRadius: BorderRadius.circular(8.0), // Bordes redondeados opcionales
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.grey, width: 2.0), // Borde más grueso cuando está enfocado
                              borderRadius: BorderRadius.circular(8.0),
                            ),
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
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: grisMedio),
                const SizedBox(height: 10),
                if (selectedCategory != null && selectedSubCategory != null)
                  const Column(
                    children: [
                      SizedBox(height: 25),
                      Text('INSTRUCCIONES', style: TextStyle(
                          fontSize: 18,
                        color: negro,
                        fontWeight: FontWeight.w900
                      )),
                      SizedBox(height: 25),
                      Text('1. Describe tu necesidad de forma clara y concisa. No incluyas el nombre del PPL (Persona Privada de la Libertad), '
                          'el sitio de reclusión ni otros datos similares, ya que la plataforma los '
                          'agregará automáticamente. Solo enfócate en detallar el problema o situación.', style: TextStyle(
                          fontSize: 14
                      )),
                    ],
                  ),

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
                const SizedBox(height: 20),
                // if (selectedCategory != null && selectedSubCategory != null)
                //   ElevatedButton(
                //     style: ElevatedButton.styleFrom(
                //       foregroundColor: Colors.white, backgroundColor: primary,
                //     ),
                //     onPressed: () {
                //       setState(() {
                //         _descripcion = _textController.text;
                //       });
                //       if (kDebugMode) {
                //         print(_descripcion);
                //       }
                //     },
                //     child: const Text('Guardar'),
                //   ),
                const SizedBox(height: 20),
                if (selectedCategory != null && selectedSubCategory != null) ...[
                  Text(
                    obtenerInstruccion(selectedCategory, selectedSubCategory),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                  ),
                  adjuntarDocumento(),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
