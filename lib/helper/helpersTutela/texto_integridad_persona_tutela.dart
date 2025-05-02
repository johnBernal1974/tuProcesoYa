// texto_integridad_personal.dart
class TextoIntegridadPersonal {
  static String obtenerTexto(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "tratos crueles o degradantes") {
      return '''
Se vulnera el derecho fundamental a la integridad personal (art. 12 de la Constitución Política), que prohíbe todo trato cruel, inhumano o degradante. Esta violación afecta también la dignidad humana (art. 1 CP) y desconoce los estándares mínimos de protección exigidos por el derecho internacional de los derechos humanos.''';
    }

    if (sub == "violencia física o psicológica") {
      return '''
Se vulneran los derechos fundamentales a la integridad física y mental (art. 12 CP) y a la dignidad humana (art. 1 CP), cuando el recluso es sometido a actos de violencia dentro del centro penitenciario, sea por parte de otros internos o del personal de custodia, sin medidas efectivas de protección institucional.''';
    }

    if (sub == "aislamiento prolongado e injustificado") {
      return '''
Se vulneran los derechos fundamentales a la integridad personal (art. 12 CP) y a la salud mental (art. 49 CP), cuando se impone un aislamiento prolongado sin justificación legal, afectando gravemente la estabilidad psicológica y emocional del interno.''';
    }

    if (sub == "negligencia frente a salud mental") {
      return '''
Se vulnera el derecho a la integridad personal (art. 12 CP), a la salud mental (art. 49 CP) y a la dignidad humana (art. 1 CP), cuando las autoridades omiten brindar atención psicológica adecuada pese a síntomas evidentes de afectación emocional.''';
    }

    if (sub == "negación de atención psicológica") {
      return '''
Se vulneran los derechos fundamentales a la salud mental (art. 49 CP), a la integridad personal (art. 12 CP) y a la dignidad humana (art. 1 CP), al no garantizar atención psicológica oportuna, continua y especializada dentro del establecimiento penitenciario.''';
    }

    return "Texto no disponible para esta subcategoría.";
  }

  static String obtenerNormasIntegridadPersonal(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "tratos crueles o degradantes") {
      return '''
Artículo 12 de la Constitución Política: prohíbe expresamente toda forma de tortura, trato cruel, inhumano o degradante.

Artículo 5 de la Convención Americana sobre Derechos Humanos: establece que toda persona tiene derecho al respeto de su integridad física, psíquica y moral.

Artículo 7 del Pacto Internacional de Derechos Civiles y Políticos: prohíbe la tortura o penas y tratos crueles, inhumanos o degradantes.

Sentencias T-881 de 2002 y T-229 de 2008: la Corte Constitucional reitera la prohibición de tratos que atenten contra la dignidad humana, especialmente en contextos de reclusión.
''';
    }

    if (sub == "violencia física o psicológica") {
      return '''
Artículo 12 de la Constitución Política: protege la integridad personal contra cualquier forma de violencia.

Artículo 2 del Código Penitenciario y Carcelario (Ley 65 de 1993): impone al Estado el deber de proteger los derechos fundamentales de las personas privadas de la libertad.

Sentencias T-425 de 2017 y T-282 de 2014: se establece que la violencia entre internos o por parte del personal penitenciario debe ser prevenida, sancionada y reparada.
''';
    }

    if (sub == "aislamiento prolongado e injustificado") {
      return '''
Artículo 12 de la Constitución Política: incluye el derecho a no ser sometido a condiciones que afecten la salud física o mental.

Reglas Mandela de la ONU (Regla 43): prohíben el aislamiento prolongado mayor a 15 días y cualquier forma de aislamiento como castigo.

Sentencia T-762 de 2015: la Corte advierte que el aislamiento debe ser excepcional, motivado y con controles estrictos para no constituir trato cruel.
''';
    }

    if (sub == "negligencia frente a salud mental") {
      return '''
Artículo 49 de la Constitución Política: consagra el derecho a la salud como servicio público esencial, incluyendo la salud mental.

Ley 1616 de 2013 (Ley de Salud Mental): establece la atención prioritaria en salud mental como parte integral del sistema de salud.

Sentencia T-760 de 2008: señala que la atención en salud debe ser oportuna, integral y sin barreras, incluso para afecciones psicológicas.
''';
    }

    if (sub == "negación de atención psicológica") {
      return '''
Artículo 49 de la Constitución Política: impone al Estado la obligación de prestar servicios de salud mental como parte del derecho a la salud.

Ley 1616 de 2013: establece la atención psicológica como derecho fundamental y parte del sistema general de seguridad social en salud.

Sentencias T-570 de 2010 y T-448 de 2013: la Corte ordena garantizar acceso a atención psicológica en centros de reclusión y reconoce su papel en la protección de la integridad personal.
''';
    }

    return 'No se han definido normas aplicables para esta subcategoría.';
  }



  static String obtenerPretensionesIntegridadPersonal(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "tratos crueles o degradantes") {
      return "Solicito que se tutele mi derecho fundamental a la integridad personal, en atención a los tratos crueles, inhumanos o degradantes a los que he sido sometido(a).\n\n"
          "Ordénese a las autoridades penitenciarias cesar de inmediato dichas conductas y adoptar medidas efectivas para prevenir su repetición.";
    }

    if (sub == "violencia física o psicológica") {
      return "Solicito que se tutele mi derecho fundamental a la integridad personal, en razón de los actos de violencia física o psicológica sufridos en reclusión.\n\n"
          "Ordénese la implementación de medidas urgentes para protegerme y garantizar un entorno seguro.";
    }

    if (sub == "aislamiento prolongado e injustificado") {
      return "Solicito que se tutele mi derecho fundamental a la integridad personal, afectado por una medida de aislamiento prolongado e injustificado.\n\n"
          "Ordénese el levantamiento inmediato de dicha medida y la revisión de su legalidad y proporcionalidad.";
    }

    if (sub == "negligencia frente a salud mental") {
      return "Solicito que se tutele mi derecho fundamental a la integridad personal, afectado por la negligencia institucional frente a mi salud mental.\n\n"
          "Ordénese la atención especializada continua y oportuna, conforme a mis necesidades psicológicas.";
    }

    if (sub == "negación de atención psicológica") {
      return "Solicito que se tutele mi derecho fundamental a la integridad personal, en virtud de la negación de atención psicológica.\n\n"
          "Ordénese el acceso inmediato y permanente a servicios profesionales de salud mental.";
    }

    return "Solicito que se tutele mi derecho fundamental a la integridad personal y se adopten las medidas necesarias para su protección.";
  }



}
