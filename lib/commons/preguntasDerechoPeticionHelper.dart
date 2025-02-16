class PreguntasDerechoPeticionHelper {
  /// Obtiene las preguntas basadas en la categoría y subcategoría seleccionadas
  static List<String> obtenerPreguntasPorCategoriaYSubcategoria(String? categoria, String? subCategoria) {
    if (categoria == null || subCategoria == null) return [
      "1. ¿Cuál es el problema específico que se desea reportar?",
      "2. ¿Se ha solicitado ayuda antes? ¿Cuál fue la respuesta?",
    ];

    Map<String, Map<String, List<String>>> preguntasPorCategoria = {
      "Beneficios Penitenciarios": {
        "Libertad condicional": [
          "¿Cuánto tiempo de condena se ha cumplido hasta ahora?",
          "¿Se ha mantenido buena conducta dentro del centro penitenciario?",
        ],
        "Prisión domiciliaria": [
          "¿Existe alguna condición médica o situación familiar que justifique la solicitud?",
          "¿Se cuenta con documentos que demuestren arraigo, como residencia o vínculos familiares?",
        ],
        "Permiso administrativo hasta de 72 horas": [
          "¿Cuál es el motivo por el que se necesita el permiso?",
          "¿Se tienen pruebas o documentos que respalden la solicitud?",
        ],
        "Redención de pena": [
          "¿Se ha participado en programas de estudio o trabajo dentro del penal?",
          "¿Se cuenta con documentos que certifiquen la redención de pena?",
        ],
        "Extinción de la sanción penal": [
          "¿En qué etapa del proceso judicial se encuentra actualmente?",
          "¿Se cuenta con documentos legales que respalden la solicitud?",
        ],
      },
      "Salud y Atención Médica": {
        "Atención médica oportuna y adecuada": [
          "¿Desde cuándo se necesita atención médica?",
          "¿Se ha solicitado atención antes y ha sido negada?",
        ],
        "Acceso a medicamentos": [
          "¿Qué medicamento se necesita y cuál es la razón?",
          "¿Se cuenta con una fórmula médica que lo respalde?",
        ],
        "Acceso a tratamientos especializados": [
          "¿Cuál es el diagnóstico y qué tratamiento especializado se requiere?",
          "¿Se ha solicitado antes este tratamiento y qué respuesta se ha recibido?",
        ],
        "Remisión a especialistas": [
          "¿Qué especialista se requiere y por qué?",
          "¿Se ha solicitado antes esta remisión y qué respuesta se obtuvo?",
        ],
        "Cirugías y/o procedimientos urgentes": [
          "¿Cuál es el procedimiento requerido y cuál es la urgencia?",
          "¿Existe un diagnóstico médico que lo respalde?",
        ],
        "Condiciones de higiene y salubridad": [
          "¿Cuáles son las condiciones de higiene en su celda y áreas comunes?",
          "¿Ha presentado problemas de salud debido a estas condiciones?",
        ],
      },
      "Condiciones de Reclusión": {
        "Hacinamiento": [
          "¿Cuántas personas comparten la celda y cuál es la capacidad máxima permitida?",
          "¿Se ha reportado esta situación y qué respuesta se ha recibido?",
        ],
        "Acceso a agua y alimentación": [
          "¿Se tiene acceso suficiente a agua potable y comida en buenas condiciones?",
          "¿Se han presentado problemas de salud debido a la falta de agua o alimentación?",
        ],
        "Malos tratos": [
          "¿Qué tipo de malos tratos ha experimentado?",
          "¿Se han presentado denuncias previas y cuál ha sido la respuesta?",
        ],
        "Traslados por seguridad": [
          "¿Qué razones justifican la solicitud de traslado?",
          "¿Existe algún documento o prueba que respalde el riesgo de seguridad?",
        ],
      },
      "Régimen Disciplinario": {
        "Impugnación de sanciones": [
          "¿Qué sanción se desea impugnar y por qué se considera injusta?",
          "¿Se tienen pruebas o testigos que respalden la versión?",
        ],
        "Revisión de procesos": [
          "¿Qué proceso disciplinario se desea revisar y por qué?",
          "¿Existen documentos que respalden la solicitud de revisión?",
        ],
        "Acceso a beneficios": [
          "¿Qué beneficio se está solicitando y en qué condición se encuentra?",
          "¿Ha sido negado anteriormente y cuál fue la razón?",
        ],
      },
      "Trabajo": {
        "Derecho a trabajar": [
          "¿Se ha solicitado empleo dentro del penal y ha sido negado?",
          "¿Se cuenta con experiencia o capacitación laboral previa?",
        ],
        "Capacitación laboral": [
          "¿Qué tipo de formación se desea recibir?",
          "¿Se ha solicitado capacitación anteriormente y ha sido negada?",
        ],
      },
      "Educación": {
        "Capacitación laboral": [
          "¿En qué área se desea recibir formación?",
          "¿Se ha solicitado acceso a educación antes y no se ha recibido?",
        ],
      },
      "Visitas y Contacto": {
        "Visitas familiares": [
          "1. ¿La familia ha intentado realizar visitas y se les ha negado el acceso?",
          "2. ¿Cuándo fue la última vez que se recibió una visita?",
        ],
        "Visitas conyugales": [
          "¿Se han solicitado visitas conyugales y han sido negadas?",
          "¿Existen condiciones de seguridad o normativas que impidan la visita?",
        ],
        "Videollamadas": [
          "¿Se han solicitado videollamadas y han sido negadas?",
          "¿Se tienen familiares que viven lejos y no pueden realizar visitas en persona?",
        ],
      },
      "Protección de Grupos Vulnerables": {
        "Protección a mujeres": [
          "¿Se ha sufrido algún tipo de violencia dentro del penal?",
          "¿Se ha solicitado ayuda y no se ha recibido respuesta?",
        ],
        "Protección a población adulta mayor": [
          "¿Se han solicitado medidas especiales para adultos mayores?",
          "¿Existen problemas de salud que requieran atención prioritaria?",
        ],
        "Personas con discapacidad o condiciones de salud especiales": [
          "¿Qué tipo de discapacidad o condición médica se tiene?",
          "¿Se cuenta con certificación médica que lo respalde?",
        ],
        "Derechos de la población LGBTIQ+": [
          "¿Ha sufrido discriminación o violencia por su orientación sexual o identidad de género?",
          "¿Ha solicitado medidas de protección y cuál ha sido la respuesta?",
        ],
        "Derechos de Afrocolombianos": [
          "¿Se han vulnerado derechos relacionados con la identidad cultural?",
          "¿Se han realizado denuncias previas y cuál ha sido la respuesta?",
        ],
        "Derechos de indígenas": [
          "¿Se han respetado las costumbres y derechos culturales de la comunidad indígena?",
          "¿Ha solicitado apoyo legal o medidas de protección y cuál ha sido la respuesta?",
        ],
      },
    };

    return preguntasPorCategoria[categoria]?[subCategoria] ?? [
      "¿Cuál es el problema específico que se desea reportar?",
      "¿Se ha solicitado ayuda antes? ¿Cuál fue la respuesta?",
    ];
  }
}
