
import 'dart:math';
import 'dart:io'; // Necesario para manejar archivos en almacenamiento local

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:tuprocesoya/Pages/client/solicitud_exitosa_derecho_peticion_page/solicitud_exitosa_derecho_peticion_page.dart';
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
  String _hintCategory = 'Seleccione una categoría';
  String _hintSubCategory = 'Seleccione una subcategoría';
 // Para almacenar el nombre del archivo seleccionado

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
  List<PlatformFile> _selectedFiles = [];
  List<String> archivosUrls = [];

  Future<void> pickFiles() async {
    try {
      // Permitir selección múltiple de archivos
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true, // Permitir selección múltiple
      );

      if (result != null) {
        print("Número de archivos seleccionados: ${result.files.length}");

        setState(() {
          // Agregar los archivos seleccionados a la lista existente
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      print("Error al seleccionar archivos: $e");
    }
  }


  Widget adjuntarDocumento() {
    return Column(
      children: [
        GestureDetector(
          onTap: pickFiles,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.attach_file, color: primary, size: 18),
              SizedBox(width: 8),
              Text(
                "Adjuntar documentos",
                style: TextStyle(
                  color: primary,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            alignment: Alignment.topLeft,
            child: const Text(
              "Archivos seleccionados:",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedFiles.length,
            itemBuilder: (context, index) {
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                leading: IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: blanco,
                          title: const Text("Eliminar archivo"),
                          content: Text(
                            "¿Estás seguro de que deseas eliminar ${_selectedFiles[index].name}?",
                          ),
                          actions: [
                            TextButton(
                              child: const Text("Cancelar"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text("Eliminar"),
                              onPressed: () {
                                setState(() {
                                  _selectedFiles.removeAt(index);
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                title: Text(
                  _selectedFiles[index].name,
                  style: const TextStyle(fontSize: 12, height: 1.2),
                  textAlign: TextAlign.left,
                ),
              );
            },
          )
        ],
      ],
    );
  }

  String obtenerInstruccion(String? categoria, String? subCategoria) {
    if (categoria == null || subCategoria == null) return "";

    Map<String, Map<String, String>> instrucciones = {
      "Beneficios Penitenciarios": {
        "Libertad condicional": "4. Si cuentas con documentos que respalden tu solicitud, como antecedentes penales, informes de conducta o requisitos legales, adjúntalos.",
        "Prisión domiciliaria": "4. Si tienes documentos médicos, pruebas de arraigo o requisitos legales que respalden tu solicitud, adjúntalos.",
        "Permiso administrativo hasta de 72 horas": "2. Si cuentas con justificación legal, motivos humanitarios o documentos de respaldo, adjúntalos.",
        "Redención de pena": "4. Adjunta registros de estudio o trabajo dentro del centro penitenciario.",
        "Extinción de la sanción penal": "4. Si tienes documentos judiciales que respalden tu solicitud, adjúntalos."
      },
      "Salud y Atención Médica": {
        "Atención médica oportuna y adecuada": "4. Si tienes exámenes médicos o solicitudes previas sin respuesta, adjúntalas.",
        "Acceso a medicamentos": "4. Adjunta fórmulas médicas o documentos que certifiquen la necesidad del medicamento.",
        "Acceso a tratamientos especializados": "4. Si cuentas con dictámenes médicos o autorizaciones previas, adjúntalas.",
        "Remisión a especialistas": "4. Adjunta órdenes médicas que justifiquen la remisión.",
        "Cirugías y/o procedimientos urgentes": "4. Si tienes exámenes médicos o diagnósticos que respalden la urgencia, adjúntalos.",
        "Condiciones de higiene y salubridad": "4. Si has documentado pruebas de condiciones insalubres (fotos, reportes), adjúntalas."
      },
      "Condiciones de Reclusión": {
        "Hacinamiento": "4. Si tienes reportes o documentos que evidencien el problema, adjúntalos.",
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
            width: MediaQuery.of(context).size.width >= 1000 ? 1000 : double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Derecho de Petición', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                const Text(
                  'Selecciona el tema sobre el cual quieres realizar el derecho de petición',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1),
                ),
                const SizedBox(height: 25),
                _buildDropdownMenus(), // Sección de Dropdowns

                const SizedBox(height: 10),
                const Divider(height: 1, color: grisMedio),
                const SizedBox(height: 10),

                // Solo se muestra si ambas opciones están seleccionadas
                if (selectedCategory != null && selectedSubCategory != null) _buildInstructionsAndInput(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Método que crea los dropdowns para seleccionar la categoría y subcategoría.
  Widget _buildDropdownMenus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Menú principal
        SizedBox(
          width: double.infinity,
          child: DropdownButtonFormField<String>(
            dropdownColor: Colors.amber.shade50,
            decoration: _inputDecoration(_hintCategory),
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
                _hintCategory = 'Categoría seleccionada';
                selectedSubCategory = null; // Resetea subcategoría
              });
            },
          ),
        ),

        const SizedBox(height: 15),

        // Menú secundario (Solo se muestra si hay una categoría seleccionada)
        if (selectedCategory != null)
          SizedBox(
            width: double.infinity,
            child: DropdownButtonFormField<String>(
              decoration: _inputDecoration(_hintSubCategory),
              dropdownColor: Colors.amber.shade50,
              isExpanded: true,
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
                  _hintSubCategory = 'Subcategoría seleccionada';
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
    );
  }

  /// Método que construye las instrucciones, inputs y botón según la categoría y subcategoría seleccionada.
  Widget _buildInstructionsAndInput() {
    List<String> preguntas = obtenerPreguntasPorCategoriaYSubcategoria(selectedCategory, selectedSubCategory);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        const Text(
          'INSTRUCCIONES',
          style: TextStyle(fontSize: 18, color: negro, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 25),

        // Instrucción fija para todos los casos
        const Text(
          "1. Describe tu necesidad de forma clara y concisa. No incluyas el nombre del PPL (Persona Privada de la Libertad), el sitio de reclusión ni otros datos similares, ya que la plataforma los agregará automáticamente.",
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 10),
        TextField(
          textCapitalization: TextCapitalization.sentences,
          controller: TextEditingController(),
          maxLines: 5,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
            hintText: 'Escribe aquí',
          ),
        ),
        const SizedBox(height: 15),

        // Preguntas específicas según categoría y subcategoría
        ...List.generate(
          preguntas.length,
              (index) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                preguntas[index],
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              TextField(
                textCapitalization: TextCapitalization.sentences,
                controller: TextEditingController(),
                maxLines: 5,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                  hintText: 'Responde aquí',
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),

        const SizedBox(height: 20),

        adjuntarDocumento(),
        const SizedBox(height: 30),

        // Botón de envío
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: primary),
          onPressed: () {
            mostrarInformacion();
            guardarSolicitud();
          },
          child: const Text(
            "Enviar solicitud",
            style: TextStyle(color: blanco),
          ),
        ),
      ],
    );
  }

  /// Obtiene las instrucciones basadas en la categoría y subcategoría seleccionadas
  List<String> obtenerPreguntasPorCategoriaYSubcategoria(String? categoria, String? subCategoria) {
    if (categoria == null) return [];

    Map<String, Map<String, List<String>>> preguntasPorCategoria = {
      "Beneficios Penitenciarios": {
        "Libertad condicional": [
          "2. ¿Cuánto tiempo de la pena ya has cumplido?",
          "3. ¿Has tenido buena conducta en el centro penitenciario?",
        ],
        "Prisión domiciliaria": [
          "2. ¿Tienes alguna condición médica o familiar que justifique la solicitud?",
          "3. ¿Cuentas con documentos de arraigo (residencia, familia)?",
        ],
        "Permiso administrativo hasta de 72 horas": [
          "2. ¿Cuál es el motivo del permiso solicitado?",
          "3. ¿Cuentas con pruebas que justifiquen tu necesidad?",
        ],
        "Redención de pena": [
          "2. ¿Has participado en programas de estudio o trabajo en el centro penitenciario?",
          "3. ¿Tienes documentación que certifique tu redención de pena?",
        ],
        "Extinción de la sanción penal": [
          "2. ¿En qué instancia del proceso judicial te encuentras?",
          "3. ¿Tienes documentos judiciales que respalden la solicitud?",
        ],
      },
      "Salud y Atención Médica": {
        "Atención médica oportuna y adecuada": [
          "2. ¿Desde cuándo presentas la necesidad de atención médica?",
          "3. ¿Has solicitado atención médica anteriormente y te la han negado?",
        ],
        "Acceso a medicamentos": [
          "2. ¿Qué medicamento necesitas y por qué?",
          "3. ¿Tienes una fórmula médica que lo respalde?",
        ],
        "Acceso a tratamientos especializados": [
          "2. ¿Cuál es tu diagnóstico y qué tratamiento especializado necesitas?",
          "3. ¿Has solicitado el tratamiento antes y qué respuesta has recibido?",
        ],
        "Remisión a especialistas": [
          "2. ¿Qué tipo de especialista necesitas consultar?",
          "3. ¿Tienes órdenes médicas que justifiquen la remisión?",
        ],
        "Cirugías y/o procedimientos urgentes": [
          "2. ¿Cuál es la cirugía o procedimiento que necesitas?",
          "3. ¿Tienes exámenes médicos o diagnósticos que respalden la urgencia?",
        ],
        "Condiciones de higiene y salubridad": [
          "2. ¿Has documentado pruebas de condiciones insalubres?",
          "3. ¿Has presentado quejas sobre esta situación anteriormente?",
        ],
      },
      "Condiciones de Reclusión": {
        "Hacinamiento": [
          "2. ¿Cuántas personas hay en tu celda y cuántas debería haber?",
          "3. ¿Has reportado antes esta situación? ¿Qué respuesta has recibido?",
        ],
        "Acceso a agua y alimentación": [
          "2. ¿Recibes suficiente agua potable y alimentación adecuada?",
          "3. ¿Has sufrido problemas de salud debido a la falta de agua o comida?",
        ],
        "Malos tratos": [
          "2. ¿Has sido víctima de malos tratos por parte de funcionarios o internos?",
          "3. ¿Has denunciado estos hechos y qué respuesta has recibido?",
        ],
        "Traslados por seguridad": [
          "2. ¿Cuál es la razón de tu solicitud de traslado?",
          "3. ¿Tienes amenazas documentadas o pruebas de riesgo?",
        ],
      },
      "Trabajo": {
        "Derecho a trabajar": [
          "2. ¿Has solicitado empleo dentro del penal y te lo han negado?",
          "3. ¿Tienes experiencia o capacitación laboral previa?",
        ],
        "Capacitación laboral": [
          "2. ¿Qué tipo de formación te gustaría recibir?",
          "3. ¿Has solicitado capacitación anteriormente y te la han negado?",
        ],
      },
      "Educación": {
        "Capacitación laboral": [
          "2. ¿Qué tipo de formación te gustaría recibir?",
          "3. ¿Has solicitado educación anteriormente y no la has recibido?",
        ],
      },
      "Visitas y Contacto": {
        "Visitas familiares": [
          "2. ¿Tu familia ha solicitado visita y ha sido rechazada?",
          "3. ¿Cuándo fue la última vez que tuviste una visita?",
        ],
        "Visitas conyugales": [
          "2. ¿Tienes documentación que acredite tu relación conyugal?",
          "3. ¿Has solicitado visitas conyugales anteriormente y cuál fue la respuesta?",
        ],
        "Videollamadas": [
          "2. ¿Has solicitado videollamadas y no han sido autorizadas?",
          "3. ¿Tienes familiares en el exterior que no pueden visitarte físicamente?",
        ],
      },
      "Protección de Grupos Vulnerables": {
        "Protección a mujeres": [
          "2. ¿Has sufrido algún tipo de violencia dentro del penal?",
          "3. ¿Has solicitado ayuda y no has recibido respuesta?",
        ],
        "Protección a población adulta mayor": [
          "2. ¿Cuáles son las condiciones actuales que afectan tu bienestar como adulto mayor?",
          "3. ¿Has solicitado protección especial o asistencia médica?",
        ],
        "Personas con discapacidad o condiciones de salud especiales": [
          "2. ¿Qué tipo de discapacidad o condición médica tienes?",
          "3. ¿Cuentas con certificación médica de tu condición?",
        ],
        "Derechos de la población LGBTIQ+": [
          "2. ¿Has sufrido discriminación o malos tratos debido a tu orientación o identidad de género?",
          "3. ¿Has presentado denuncias previas y cuál ha sido la respuesta?",
        ],
        "Derechos de Afrocolombianos": [
          "2. ¿Has experimentado discriminación o vulneración de derechos por tu etnia?",
          "3. ¿Tienes pruebas documentales de la vulneración de tus derechos?",
        ],
        "Derechos de indígenas": [
          "2. ¿Tus derechos étnicos han sido vulnerados dentro del penal?",
          "3. ¿Has solicitado medidas especiales de protección?",
        ],
      },
      "Régimen Disciplinario": {
        "Impugnación de sanciones": [
          "2. ¿Qué sanción deseas impugnar y por qué consideras que es injusta?",
          "3. ¿Tienes pruebas o testigos que respalden tu versión?",
        ],
        "Revisión de procesos": [
          "2. ¿Qué aspecto del proceso disciplinario consideras que fue incorrecto?",
          "3. ¿Tienes documentos o pruebas que respalden tu solicitud?",
        ],
        "Acceso a beneficios": [
          "2. ¿Qué beneficio estás solicitando y por qué lo consideras aplicable a tu caso?",
          "3. ¿Has solicitado antes este beneficio y qué respuesta has recibido?",
        ],
      },
    };

    return preguntasPorCategoria[categoria]?[subCategoria] ?? [
      "2. ¿Cuál es el problema específico que deseas reportar?",
      "3. ¿Has solicitado ayuda anteriormente? ¿Qué respuesta has recibido?",
    ];
  }


  // /// Método que retorna instrucciones según la categoría seleccionada. no se esta usando
  // List<String> obtenerInstruccionesPorCategoria(String? category) {
  //   switch (category) {
  //     case 'Salud y Atención Médica':
  //       return [
  //         '1. Describe tu necesidad médica de manera clara.',
  //         '2. Indica si la persona ha recibido atención previamente.',
  //         '3. Explica por qué consideras que la atención es insuficiente o inadecuada.'
  //       ];
  //     case 'Beneficios Penitenciarios':
  //       return [
  //         '1. Explica el tipo de beneficio que solicitas.',
  //         '2. Justifica por qué la persona privada de la libertad cumple con los requisitos.',
  //         '3. Proporciona detalles sobre su comportamiento y condiciones legales.'
  //       ];
  //     case 'Condiciones de Reclusión':
  //       return [
  //         '1. Describe las condiciones actuales en las que se encuentra la persona privada de la libertad.',
  //         '2. Explica cómo afectan su bienestar físico y mental.',
  //         '3. Propón soluciones o mejoras necesarias.'
  //       ];
  //     case 'Trabajo':
  //       return [
  //         '1. Especifica el tipo de trabajo solicitado dentro del centro penitenciario.',
  //         '2. Explica cómo beneficiará al PPL en su proceso de resocialización.',
  //         '3. Indica si ya ha trabajado antes en el centro penitenciario.'
  //       ];
  //     case 'Educación':
  //       return [
  //         '1. Menciona el nivel educativo del PPL.',
  //         '2. Indica qué estudios desea cursar.',
  //         '3. Explica la importancia de la educación en su proceso de reinserción social.'
  //       ];
  //     case 'Visitas y Contacto':
  //       return [
  //         '1. Especifica el tipo de contacto solicitado (visitas, llamadas, videollamadas).',
  //         '2. Explica si ha tenido restricciones previas.',
  //         '3. Justifica por qué el contacto es necesario o urgente.'
  //       ];
  //     case 'Protección de Grupos Vulnerables':
  //       return [
  //         '1. Indica la situación de vulnerabilidad del PPL.',
  //         '2. Explica si ha sido víctima de agresiones o discriminación.',
  //         '3. Describe las medidas de protección que consideras necesarias.'
  //       ];
  //     case 'Régimen Disciplinario':
  //       return [
  //         '1. Explica el motivo de la sanción impuesta.',
  //         '2. Indica si se han vulnerado derechos en el proceso disciplinario.',
  //         '3. Proporciona argumentos o pruebas que respalden la solicitud de revisión.'
  //       ];
  //     default:
  //       return ['No hay instrucciones disponibles para esta categoría.'];
  //   }
  // }

  /// Método para reutilizar el estilo de los inputs.
  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey, width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }


  void mostrarInformacion() {
    print("Categoría seleccionada: ${selectedCategory}");
    print("Subcategoría seleccionada: ${selectedSubCategory}");
    print("Texto ingresado: $_textController");
    print("Archivos seleccionados: ${_selectedFiles.join(', ')}");
  }


  Future<void> guardarSolicitud() async {
    if (selectedCategory == null || selectedSubCategory == null || _textController.text.isEmpty) {
      print("Por favor, complete todos los campos antes de guardar.");
      return;
    }

    // Obtener el usuario actual
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No hay usuario autenticado.");
      return;
    }

    String idUser = user.uid; // Obtener el ID del usuario autenticado

    // Mostrar el diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          backgroundColor: blancoCards,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Subiendo información, por favor espera..."),
            ],
          ),
        );
      },
    );

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      FirebaseStorage storage = FirebaseStorage.instance;

      // Generar un ID único para el documento
      String docId = firestore.collection('derechos_peticion_solicitados').doc().id;

      // Generar un número de seguimiento aleatorio de 10 dígitos
      String numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();

      // Lista para almacenar URLs de archivos subidos
      List<String> archivosUrls = [];

      // Subir cada archivo seleccionado con el contentType correcto
      for (PlatformFile file in _selectedFiles) {
        try {
          String filePath = 'derechos_peticion/$docId/${file.name}';
          Reference storageRef = storage.ref(filePath);

          UploadTask uploadTask;

          // Detectar tipo de archivo
          String ext = file.name.split('.').last.toLowerCase();
          String contentType;

          if (ext == "jpg" || ext == "jpeg") {
            contentType = "image/jpeg";
          } else if (ext == "png") {
            contentType = "image/png";
          } else if (ext == "pdf") {
            contentType = "application/pdf";
          } else {
            contentType = "application/octet-stream"; // Tipo genérico
          }

          if (kIsWeb) {
            uploadTask = storageRef.putData(file.bytes!, SettableMetadata(contentType: contentType));
          } else {
            File fileToUpload = File(file.path!);
            uploadTask = storageRef.putFile(fileToUpload, SettableMetadata(contentType: contentType));
          }

          TaskSnapshot snapshot = await uploadTask;
          String downloadUrl = await snapshot.ref.getDownloadURL();

          archivosUrls.add(downloadUrl);
        } catch (e) {
          print("Error al subir el archivo ${file.name}: $e");
        }
      }

      // Guardar datos en Firestore
      await firestore.collection('derechos_peticion_solicitados').doc(docId).set({
        "id": docId,
        "idUser": idUser, // Guardar el ID del usuario
        "numero_seguimiento": numeroSeguimiento,
        "categoria": selectedCategory,
        "subcategoria": selectedSubCategory,
        "texto": _textController.text,
        "archivos": archivosUrls,
        "fecha": FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.pop(context); // Cerrar el diálogo de carga
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SolicitudExitosaDerechoPeticionPage()),
        );
      }

      print("✅ Solicitud guardada con éxito. ID: $docId, Número Seguimiento: $numeroSeguimiento, Usuario: $idUser");
    } catch (e) {
      print("❌ Error al guardar la solicitud: $e");

      if (context.mounted) {
        Navigator.pop(context); // Cerrar el diálogo de carga

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            content: const Text("Hubo un problema al guardar la solicitud. Por favor, intenta nuevamente."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Aceptar"),
              ),
            ],
          ),
        );
      }
    }
  }


}
