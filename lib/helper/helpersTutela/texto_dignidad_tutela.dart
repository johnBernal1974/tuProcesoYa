// texto_dignidad_humana.dart
class TextoDignidadHumana {
  static String obtenerTexto(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "condiciones de reclusión inhumanas") {
      return '''
Las condiciones inhumanas de reclusión vulneran gravemente mi derecho fundamental a la dignidad humana, reconocido en el artículo 1 de la Constitución Política. La Corte Constitucional ha reiterado que el respeto por la dignidad es el eje estructurante del ordenamiento jurídico colombiano y debe guiar todas las actuaciones del Estado, especialmente respecto de las personas privadas de la libertad.

La Sentencia T-388 de 2013 evidenció un estado de cosas inconstitucional en los centros penitenciarios del país, por situaciones de hacinamiento, insalubridad, escasez de alimentos, agua y servicios médicos, que violan derechos fundamentales como la dignidad, la integridad personal y la vida digna.

Tales condiciones no solo afectan mi salud física y mental, sino que configuran una forma de trato cruel, inhumano y degradante prohibido por los estándares nacionales e internacionales.''';
    }

    if (sub == "falta de acceso a servicios básicos") {
      return '''
La carencia prolongada de servicios básicos como agua potable, saneamiento, alimentación adecuada y atención médica vulnera directamente mi derecho a una existencia digna. La dignidad humana, como principio fundante del Estado Social de Derecho, exige que las condiciones de reclusión sean compatibles con el respeto mínimo por la humanidad de las personas.

La Corte Constitucional ha señalado, en sentencias como la T-153 de 1998 y la T-762 de 2015, que la privación de servicios esenciales no puede considerarse una consecuencia legítima de la pena privativa de la libertad. Estas omisiones agravan la situación de vulnerabilidad y constituyen tratos inhumanos que deben ser corregidos de forma inmediata por el Estado.''';
    }

    if (sub == "hacinamiento extremo") {
      return '''
El hacinamiento extremo constituye una violación sistemática al derecho a la dignidad humana, afectando la salud, la integridad y la convivencia en los centros penitenciarios. La Corte Constitucional, en la Sentencia T-388 de 2013, declaró que el sistema penitenciario colombiano se encuentra en un estado de cosas inconstitucional, precisamente por esta problemática estructural.

El artículo 1 de la Constitución, junto con tratados internacionales como la Convención Americana sobre Derechos Humanos, impone al Estado la obligación de garantizar que las condiciones de reclusión respeten la dignidad de los internos, lo cual es incompatible con celdas sobrepobladas, sin ventilación, higiene ni espacio personal.''';
    }

    if (sub == "trato denigrante por personal penitenciario") {
      return '''
El trato denigrante por parte del personal penitenciario vulnera mi derecho fundamental a la dignidad humana y configura un trato cruel, inhumano o degradante, prohibido por el artículo 12 de la Constitución y por instrumentos internacionales como el Pacto Internacional de Derechos Civiles y Políticos.

La Corte Constitucional ha establecido en la Sentencia T-106 de 2004 que el trato respetuoso y digno debe ser garantizado a toda persona bajo custodia del Estado, sin distinción alguna. La autoridad no puede ejercer su poder mediante humillaciones, amenazas, gritos o tratos ofensivos, ya que ello implica una regresión inadmisible en materia de derechos humanos.''';
    }

    if (sub == "falta de intimidad mínima") {
      return '''
La ausencia de condiciones mínimas de intimidad en los espacios de reclusión vulnera mi derecho a la dignidad humana, reconocido como valor fundante del Estado colombiano en el artículo 1 de la Constitución. La Corte Constitucional ha sostenido que la dignidad exige el respeto de espacios privados, incluso en contextos carcelarios.

La jurisprudencia constitucional (Sentencia T-542 de 1992) ha señalado que la privación de libertad no implica la pérdida de todos los derechos fundamentales. La negación de espacios personales mínimos, como baños sin divisiones, hacinamiento en celdas o ausencia de privacidad, afecta directamente mi integridad psíquica y emocional.''';
    }

    return "Texto no disponible para esta subcategoría.";
  }


  static String obtenerNormasDignidadHumana(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "condiciones de reclusión inhumanas") {
      return '''
Artículo 1 de la Constitución Política: reconoce la dignidad humana como principio fundante del Estado Social de Derecho.

Artículo 12 de la Constitución Política: prohíbe todo tipo de trato cruel, inhumano o degradante.

Artículo 5 de la Convención Americana sobre Derechos Humanos: garantiza que toda persona sea tratada con dignidad, especialmente en privación de libertad.

Sentencias T-388 de 2013 y T-153 de 1998: la Corte Constitucional declaró un estado de cosas inconstitucional en las cárceles colombianas, debido a las condiciones indignas de reclusión.
''';
    }

    if (sub == "falta de acceso a servicios básicos") {
      return '''
Artículo 1 de la Constitución Política: establece que la dignidad humana es un valor esencial del orden constitucional.

Artículo 11 de la Constitución Política: consagra el derecho fundamental a la vida, que incluye condiciones mínimas de existencia digna.

Artículo 25 de la Declaración Universal de los Derechos Humanos: establece el derecho a un nivel de vida adecuado, incluyendo alimentación, agua y vivienda.

Sentencias T-499 de 2003 y T-153 de 1998: reconocen que negar el acceso a servicios básicos vulnera la dignidad humana y puede constituir trato inhumano.
''';
    }

    if (sub == "hacinamiento extremo") {
      return '''
Artículo 1 de la Constitución Política: declara que el respeto a la dignidad humana es pilar del Estado.

Artículo 24 de la Constitución Política: protege el libre desarrollo de la personalidad y la movilidad, limitadas injustamente por el hacinamiento.

Sentencias T-153 de 1998 y T-388 de 2013: advierten que el hacinamiento carcelario constituye una violación sistemática de derechos fundamentales.

Estado de cosas inconstitucional: declarado por la Corte Constitucional ante el colapso del sistema penitenciario por sobrepoblación y condiciones indignas.
''';
    }

    if (sub == "trato denigrante por personal penitenciario") {
      return '''
Artículo 12 de la Constitución Política: prohíbe expresamente la tortura, tratos crueles, inhumanos o degradantes.

Artículo 5 de la Convención Americana sobre Derechos Humanos: reconoce el derecho de toda persona privada de libertad a un trato digno.

Sentencias T-881 de 2002 y T-229 de 2008: establecen que los actos de denigración por parte del personal penitenciario vulneran gravemente la dignidad del recluso.
''';
    }

    if (sub == "falta de intimidad mínima") {
      return '''
Artículo 15 de la Constitución Política: protege el derecho a la intimidad personal y familiar.

Reglas Mandela de la ONU (Reglas Mínimas para el Tratamiento de los Reclusos): obligan a los Estados a respetar la privacidad de las personas privadas de la libertad.

Sentencia T-594 de 1993: afirma que incluso en reclusión, las personas conservan un núcleo esencial de privacidad e intimidad.
''';
    }

    return 'No se han definido normas aplicables para esta subcategoría.';
  }


  static String obtenerPretensionesDignidadHumana(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "condiciones de reclusión inhumanas") {
      return '''
Solicito que se tutele mi derecho fundamental a la dignidad humana, vulnerado por las condiciones inadecuadas e inhumanas de reclusión a las que he sido sometido(a).\n\n
Ordénese a las autoridades competentes adoptar medidas inmediatas que garanticen condiciones materiales mínimas de existencia, conforme a los estándares constitucionales y de derechos humanos.
''';
    }

    if (sub == "falta de acceso a servicios básicos") {
      return '''
Solicito que se tutele mi derecho a la dignidad humana, afectado por la ausencia de servicios esenciales que comprometen mi bienestar y subsistencia digna.\n\n
Ordénese garantizar el acceso regular y adecuado a servicios básicos como agua potable, alimentación, saneamiento y aseo personal dentro del establecimiento de reclusión.
''';
    }

    if (sub == "hacinamiento extremo") {
      return '''
Solicito que se tutele mi derecho a la dignidad humana, vulnerado por el hacinamiento extremo que impera en el lugar de reclusión.\n\n
Ordénese implementar acciones inmediatas que mitiguen dicha situación y aseguren el respeto por mis derechos fundamentales.
''';
    }

    if (sub == "trato denigrante por personal penitenciario") {
      return '''
Solicito que se tutele mi derecho a la dignidad humana, afectado por conductas denigrantes provenientes del personal penitenciario.\n\n
Ordénese adelantar las investigaciones correspondientes, sancionar a los responsables y adoptar mecanismos de prevención para evitar la repetición de estos actos.
''';
    }

    if (sub == "falta de intimidad mínima") {
      return '''
Solicito que se tutele mi derecho a la dignidad humana, menoscabado por la falta de respeto a mi intimidad dentro del establecimiento penitenciario.\n\n
Ordénese adoptar medidas que garanticen espacios de privacidad adecuados, evitando prácticas invasivas que resulten injustificadas.
''';
    }

    return '''
Solicito que se tutele mi derecho a la dignidad humana, conforme a lo expuesto en los hechos narrados.\n\n
Ordénese adoptar medidas correctivas y de protección que aseguren su restablecimiento.
''';
  }


}
