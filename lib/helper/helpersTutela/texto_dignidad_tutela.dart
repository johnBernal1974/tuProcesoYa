// texto_dignidad_humana.dart
class TextoDignidadHumana {
  static String obtenerTexto(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "condiciones de reclusión inhumanas") {
      return '''
Las condiciones de reclusión que desconocen estándares mínimos de habitabilidad y trato humano vulneran el derecho fundamental a la dignidad humana (art. 1 CP), así como la prohibición de tratos crueles, inhumanos o degradantes (art. 12 CP), afectando directamente la integridad física y moral de la persona privada de la libertad.''';
    }

    if (sub == "falta de acceso a servicios básicos") {
      return '''
La carencia de servicios esenciales como agua potable, alimentación, higiene o acceso a baños en condiciones adecuadas vulnera el derecho a la dignidad humana (art. 1 CP), el mínimo vital (art. 11 CP) y el derecho a condiciones de vida compatibles con la salud y la existencia digna.''';
    }

    if (sub == "hacinamiento extremo") {
      return '''
El hacinamiento penitenciario grave constituye una violación sistemática al derecho a la dignidad humana (art. 1 CP) y a la integridad personal, al someter a las personas privadas de la libertad a condiciones incompatibles con su humanidad, afectando su salud física y mental.''';
    }

    if (sub == "trato denigrante por personal penitenciario") {
      return '''
El uso de lenguaje humillante, castigos arbitrarios o conductas agresivas por parte del personal penitenciario vulnera la dignidad humana (art. 1 CP), la integridad personal (art. 12 CP), y contraviene el deber estatal de tratar con respeto y humanidad a quienes se encuentran bajo su custodia.''';
    }

    if (sub == "falta de intimidad mínima") {
      return '''
La ausencia de espacios mínimos de privacidad para el aseo, descanso o necesidades fisiológicas vulnera la dignidad humana (art. 1 CP), el derecho a la intimidad personal (art. 15 CP), y constituye una afectación a la integridad psicosocial del interno.''';
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
