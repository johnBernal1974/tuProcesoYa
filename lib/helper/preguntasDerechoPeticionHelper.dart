class PreguntasDerechoPeticionHelper {
  /// Obtiene las preguntas basadas en la categoría y subcategoría seleccionadas
  static List<String> obtenerPreguntasPorCategoriaYSubcategoria(String? categoria, String? subCategoria) {
    if (categoria == null || subCategoria == null) {
      return [
      "¿Cuál es el problema específico que desea reportar o exponer?",
      "¿Se ha solicitado ayuda, atención o respuesta por parte de alguna autoridad? ¿Cuál ha sido la respuesta o qué ha ocurrido?",
    ];
    }

    Map<String, Map<String, List<String>>> preguntasPorCategoria = {
      "Actualización de datos": {
        "Actualización de hoja de vida del Ppl": [
          "¿Explica porqué necesitas actualizar los datos, que información actualmente esta errónea y puede perjudicar o ha perjudicado al Ppl?",
          "¿Se ha hecho anteriormente la misma solicitud?, A quien se hizo la solicitud y que respuesta se ha obtenido?",
        ],
      },

      "Cartilla biográfica": {
        "Solicitud de cartilla biográfica": [
          "¿Para que se solicita la cartilla biográfica?",
          "¿Se ha hecho anteriormente la misma solicitud?, A quien se hizo la solicitud y que respuesta se ha obtenido?",
        ],
      },

      "Cursos transversales cambio de fase": {
        "Solicitud de cursos transversales": [
          "¿Que solicitud especifica desea realizar?",
          "¿Se ha hecho anteriormente la misma solicitud?, A quien se hizo la solicitud y que respuesta se ha obtenido?",
        ],
      },

      "Salud y Atención Médica": {
        "Atención médica oportuna y adecuada": [
          "Indicar con claridad el problema de salud que padece y desde cuando se ha necesitado atención médica",
          "¿Se ha solicitado atención médica antes y ha sido negada?",
        ],
        "Acceso a medicamentos": [
          "Indica el nombre del medicamento que se requiere, así como la razón médica o diagnóstico que justifica su necesidad.",
          "¿Se cuenta con una fórmula médica que lo respalde?",
        ],
        "Acceso a tratamientos especializados": [
          "¿Cuál es el diagnóstico médico actual y qué tratamiento especializado ha sido indicado por el personal de salud del centro penitenciario o por un profesional externo?",
          "¿Se ha solicitado anteriormente este tratamiento ante el área de sanidad del establecimiento o a través del INPEC? En caso afirmativo, ¿qué respuesta o gestión se ha recibido hasta el momento?",
        ],
        "Remisión a especialistas": [
          "¿Qué tipo de especialista se requiere y cuál es la razón médica que justifica dicha remisión, según valoración del personal de sanidad o diagnóstico previo?",
          "¿Se ha solicitado anteriormente esta remisión ante el área de sanidad del establecimiento o al INPEC? En caso afirmativo, ¿qué respuesta se ha recibido o qué gestión se ha realizado?",
        ],
        "Cirugías y/o procedimientos urgentes": [
          "¿Qué procedimiento o cirugía se requiere y cuál es la urgencia médica que justifica su realización inmediata?",
          "¿Existe un diagnóstico médico emitido por el personal de sanidad del centro penitenciario o por un profesional externo que respalde la necesidad del procedimiento?",
        ],
        "Condiciones de higiene y salubridad": [
          "¿Cuáles son las condiciones actuales de higiene y salubridad en su celda, baños y demás áreas comunes del establecimiento penitenciario?",
          "¿Ha presentado afectaciones en su salud física o mental como consecuencia de dichas condiciones? En caso afirmativo, indique cuáles.",
        ],
      },
      "Condiciones de Reclusión": {

        "Acceso a agua y alimentación": [
          "¿Cuenta con acceso suficiente y regular a agua potable y a alimentos en condiciones adecuadas de higiene y calidad nutricional?",
          "¿Ha presentado problemas de salud como consecuencia de la falta de acceso a agua potable o una alimentación deficiente? En caso afirmativo, describa cuáles.",
        ],
        "Malos tratos": [
          "¿Qué tipo de malos tratos ha experimentado dentro del establecimiento penitenciario? (Incluya si han sido físicos, verbales, psicológicos u otro tipo).",
          "¿Ha presentado denuncias o quejas formales ante las autoridades competentes (INPEC, Personería, Defensoría del Pueblo, entre otros)? En caso afirmativo, ¿qué respuesta o actuación se ha recibido hasta el momento?",
        ],
        "Traslados por seguridad": [
          "¿Qué razones justifican la solicitud de traslado?",
          "¿Existe algún documento o prueba que respalde el riesgo de seguridad?",
        ],
      },
      "Régimen Disciplinario": {
        "Impugnación de sanciones": [
          "¿Qué tipo de sanción disciplinaria desea impugnar y cuáles son las razones por las cuales considera que dicha sanción es injusta o vulnera sus derechos?",
          "¿Cuenta con pruebas documentales, testimonios u otros elementos que respalden su versión de los hechos? En caso afirmativo, descríbalos brevemente.",
        ],
        "Revisión de procesos": [
          "¿Qué proceso disciplinario desea que sea revisado y cuáles son las razones o irregularidades que justifican dicha solicitud?",
          "¿Cuenta con documentos, evidencias o antecedentes que respalden la petición de revisión? En caso afirmativo, descríbalos o indíquelo.",
        ],
        "Acceso a beneficios": [
          "¿Qué tipo de beneficio penitenciario está solicitando (como redención de pena, libertad condicional, permiso de 72 horas, prisión domiciliaria, entre otros), y cuál es su situación actual frente al cumplimiento de requisitos para acceder a dicho beneficio?",
          "¿Le ha sido negado anteriormente este beneficio? En caso afirmativo, ¿cuál fue la razón de la negativa y qué entidad la emitió?",
        ],
      },
      "Trabajo": {
        "Derecho a trabajar": [
          "¿Ha solicitado acceder a un trabajo dentro del establecimiento penitenciario y le ha sido negado? En caso afirmativo, indique ante qué autoridad realizó la solicitud y cuál fue la respuesta.",
          "¿Cuenta con experiencia laboral previa o ha recibido algún tipo de capacitación que respalde su interés en acceder a un empleo intramural?",
        ],
        "Capacitación laboral": [
          "¿Qué tipo de formación o capacitación laboral desea recibir dentro del establecimiento penitenciario, y cómo considera que esta podría contribuir a su proceso de resocialización?",
          "¿Ha solicitado anteriormente acceder a programas de capacitación o formación técnica? En caso afirmativo, ¿cuál fue la respuesta recibida o la razón por la cual no se ha brindado el acceso?",
        ],
      },
      "Educación": {
        "Educación formal": [
          "¿En qué nivel o área educativa desea recibir formación (como educación básica, media, bachillerato, educación técnica, tecnológica o superior)? Explique su interés.",
          "¿Ha solicitado previamente acceso a programas educativos dentro del establecimiento penitenciario y no ha recibido respuesta o el acceso ha sido negado? En caso afirmativo, indique ante quién se realizó la solicitud y cuál fue la respuesta.",
        ],
      },
      "Visitas y Contacto": {
        "Visitas familiares": [
          "¿Sus familiares han intentado visitarlo recientemente y se les ha negado el ingreso al establecimiento? En caso afirmativo, ¿qué razones les fueron dadas?",
          "¿Cuándo fue la última vez que recibió una visita familiar, y cuál ha sido la razón por la cual no ha podido volver a recibir visitas desde entonces (si aplica)?",
        ],
        "Visitas conyugales": [
          "¿Ha solicitado visitas conyugales y estas le han sido negadas? En caso afirmativo, ¿ante qué autoridad se hizo la solicitud y qué respuesta se recibió?",
          "¿Se le ha informado que existen condiciones de seguridad, normativas internas o restricciones específicas que impiden el ejercicio de este derecho? En caso afirmativo, descríbalas.",
        ],
        "Videollamadas": [
          "¿Ha solicitado la posibilidad de realizar videollamadas con familiares o allegados, y le ha sido negada o no se le ha brindado una respuesta oportuna?",
          "¿Tiene familiares que residen en otras ciudades o regiones y no pueden visitarlo presencialmente con regularidad? ¿Considera que la videollamada es su único medio viable de contacto familiar?",
        ],
      },
      "Protección de Grupos Vulnerables": {
        "Protección a mujeres": [
          "¿Ha sido víctima de algún tipo de violencia o vulneración de derechos dentro del establecimiento penitenciario (física, psicológica, sexual, institucional u otra)? En caso afirmativo, describa la situación.",
          "¿Ha solicitado apoyo, protección o acompañamiento a las autoridades competentes (como sanidad, INPEC, Defensoría del Pueblo, Personería, entre otros) y no ha recibido una respuesta oportuna y efectiva?",
        ],
        "Protección a población adulta mayor": [
          "¿Se han solicitado medidas especiales de protección o trato diferenciado por su condición de persona adulta mayor, y no se han implementado? En caso afirmativo, indique ante qué autoridad se hizo la solicitud.",
          "¿Presenta problemas de salud física o mental asociados a la edad que requieran atención médica prioritaria, condiciones especiales de reclusión o acompañamiento constante?",
        ],
        "Personas con discapacidad o condiciones de salud especiales": [
          "¿Qué tipo de discapacidad física, sensorial, cognitiva, psicosocial o condición médica especial presenta, y cómo afecta su vida diaria dentro del establecimiento penitenciario?",
          "¿Cuenta con diagnóstico o certificación médica que respalde su condición y que justifique la necesidad de medidas especiales de atención, accesibilidad o protección?",
        ],
        "Derechos de la población LGBTIQ+": [
          "¿Ha sido víctima de discriminación, violencia o tratos diferenciales dentro del establecimiento penitenciario debido a su orientación sexual, identidad o expresión de género? En caso afirmativo, describa la situación.",
          "¿Ha solicitado medidas de protección, reasignación de celda o acompañamiento institucional, y cuál ha sido la respuesta de las autoridades competentes?",
        ],
        "Derechos de Afrocolombianos": [
          "¿Ha sido víctima de discriminación, estigmatización o vulneración de derechos relacionados con su identidad étnica, cultural o ancestral dentro del establecimiento penitenciario?",
          "¿Ha presentado denuncias, quejas o solicitudes de acompañamiento ante las autoridades competentes (como INPEC, Personería o Defensoría del Pueblo) y cuál ha sido la respuesta recibida?",
        ],
        "Derechos de indígenas": [
          "¿Se han respetado sus costumbres, prácticas culturales, creencias espirituales y demás derechos colectivos como miembro de una comunidad indígena dentro del establecimiento penitenciario? En caso contrario, describa la situación.",
          "¿Ha solicitado apoyo legal, acompañamiento de autoridades indígenas o medidas de protección específicas, y cuál ha sido la respuesta de las autoridades penitenciarias o institucionales?",
        ],
      },
    };

    return preguntasPorCategoria[categoria]?[subCategoria] ?? [
      "¿Cuál es el problema específico que desea reportar o exponer?",
      "¿Se ha solicitado ayuda, atención o respuesta por parte de alguna autoridad? ¿Cuál ha sido la respuesta o qué ha ocurrido?",
    ];
  }
}
