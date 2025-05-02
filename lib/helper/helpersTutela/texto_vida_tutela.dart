// texto_vida.dart
class TextoVida {
  static String obtenerTexto(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "amenazas dentro del penal") {
      return '''
La omisión de las autoridades penitenciarias frente a las amenazas recibidas dentro del establecimiento de reclusión constituye una vulneración directa a mi derecho fundamental a la vida, consagrado en el artículo 11 de la Constitución Política. Dicho derecho es inalienable e irrenunciable y exige del Estado una protección efectiva frente a riesgos ciertos e inminentes, como lo ha señalado reiteradamente la Corte Constitucional (Sentencia T-102 de 2011).

El deber de custodia del Estado frente a las personas privadas de la libertad impone una obligación reforzada de protección frente a amenazas internas, particularmente si estas provienen de otros internos o del mismo personal. Así lo ha advertido la Corte en la Sentencia T-815 de 2005, donde enfatiza que la responsabilidad del Estado es aún mayor debido a la posición de indefensión del interno.''';
    }

    if (sub == "falta de medidas de protección") {
      return '''
La ausencia de medidas efectivas de protección pese a la advertencia de riesgos concretos vulnera mi derecho fundamental a la vida, contemplado en el artículo 11 de la Constitución. La Corte Constitucional ha señalado que esta protección debe ser activa, no pasiva, y que las autoridades tienen el deber de prevenir daños previsibles (Sentencia T-312 de 2002).

La omisión en implementar esquemas de protección adecuados a pesar de las denuncias o alertas constituye una falla en el deber positivo del Estado de garantizar la vida e integridad física de los reclusos, conforme al artículo 5 de la Convención Americana sobre Derechos Humanos.''';
    }

    if (sub == "riesgo por condiciones insalubres") {
      return '''
La permanencia prolongada en entornos insalubres, sin acceso a condiciones mínimas de higiene, ventilación o agua potable, pone en grave riesgo mi salud y vida, y por tanto constituye una violación del artículo 11 de la Constitución, así como del artículo 12 del Pacto Internacional de Derechos Económicos, Sociales y Culturales.

La Corte Constitucional en la Sentencia T-153 de 1998 reconoció que las condiciones materiales de reclusión hacen parte del mínimo vital para una existencia digna, y que el incumplimiento de estándares básicos puede constituir una amenaza directa al derecho a la vida.''';
    }

    if (sub == "riesgo por hacinamiento") {
      return '''
El hacinamiento carcelario configura una situación de riesgo cierto y grave para la vida, salud e integridad de las personas privadas de la libertad, conforme lo ha advertido la Corte Constitucional en la Sentencia T-388 de 2013, al declarar un estado de cosas inconstitucional sobre el sistema penitenciario colombiano.

El artículo 11 de la Constitución, junto con el artículo 10 del Pacto Internacional de Derechos Civiles y Políticos, imponen al Estado la obligación de garantizar que el cumplimiento de la pena no derive en condiciones que atenten contra la vida o expongan a tratos crueles, inhumanos o degradantes.''';
    }

    if (sub == "negligencia médica grave") {
      return '''
La negligencia grave en la atención médica en contextos penitenciarios no solo vulnera el derecho a la salud, sino también el derecho fundamental a la vida (art. 11 CP), especialmente cuando omisiones, demoras o errores ponen en riesgo la supervivencia del recluso.

La Corte Constitucional ha señalado que, en virtud del principio de dignidad humana (art. 1 CP), las personas privadas de la libertad tienen derecho a recibir atención médica oportuna y adecuada. En la Sentencia T-020 de 2017 se enfatizó que esta atención es inaplazable y que su omisión compromete seriamente la vida del interno.''';
    }

    return "Texto no disponible para esta subcategoría.";
  }

  static String obtenerNormasVida(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "amenazas dentro del penal") {
      return '''
Artículo 11 de la Constitución Política: establece que el derecho a la vida es inviolable y debe ser protegido por el Estado bajo cualquier circunstancia.

Artículo 5 de la Convención Americana sobre Derechos Humanos: señala que toda persona tiene derecho a que se respete su integridad física, psíquica y moral, lo cual incluye la protección de su vida.

Sentencias T-102 de 2011 y T-815 de 2005: la Corte reitera el deber reforzado del Estado de proteger a las personas privadas de la libertad frente a amenazas internas.
''';
    }

    if (sub == "falta de medidas de protección") {
      return '''
Artículo 11 de la Constitución Política: reconoce el derecho fundamental a la vida como eje central del orden constitucional.

Artículo 5 de la Convención Americana sobre Derechos Humanos: obliga al Estado a prevenir situaciones que puedan poner en peligro la vida de personas bajo su custodia.

Sentencias T-312 de 2002 y T-215 de 2018: la Corte exige una protección activa por parte de las autoridades frente a riesgos advertidos, no basta con una actitud pasiva.
''';
    }

    if (sub == "riesgo por condiciones insalubres") {
      return '''
Artículo 11 de la Constitución Política: protege la vida no solo como existencia biológica, sino como una vida digna.

Artículo 12 del Pacto Internacional de Derechos Económicos, Sociales y Culturales: reconoce el derecho de toda persona al disfrute del más alto nivel posible de salud física y mental.

Sentencia T-153 de 1998: establece que las condiciones materiales de detención deben respetar la dignidad humana y no poner en riesgo la vida o salud del recluso.
''';
    }

    if (sub == "riesgo por hacinamiento") {
      return '''
Artículo 11 de la Constitución Política: impone al Estado la obligación de proteger la vida frente a condiciones que la amenacen, como el hacinamiento extremo.

Artículo 10 del Pacto Internacional de Derechos Civiles y Políticos: establece que toda persona privada de la libertad debe ser tratada humanamente y con el respeto debido a la dignidad inherente al ser humano.

Sentencia T-388 de 2013: declara el estado de cosas inconstitucional en el sistema penitenciario colombiano debido al hacinamiento, reconociéndolo como una amenaza directa a la vida y salud de los internos.
''';
    }

    if (sub == "negligencia médica grave") {
      return '''
Artículo 11 de la Constitución Política: establece el derecho a la vida como inviolable, lo cual implica garantizar condiciones mínimas de salud.

Artículo 1 de la Constitución: reconoce la dignidad humana como principio fundante del Estado social de derecho, lo cual obliga a brindar atención médica adecuada en contextos de reclusión.

Sentencias T-020 de 2017 y T-760 de 2008: la Corte ha reiterado que la negligencia médica en contextos penitenciarios puede traducirse en una vulneración del derecho a la vida, obligando al Estado a actuar de manera urgente.
''';
    }

    return 'No se han definido normas aplicables para esta subcategoría.';
  }


  static String obtenerPretensionesVida(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "amenazas dentro del penal") {
      return '''
Solicito que se tutele mi derecho fundamental a la vida, amenazado por situaciones de riesgo dentro del establecimiento penitenciario.\n\n
Ordénese a las autoridades penitenciarias implementar medidas inmediatas y efectivas de protección que garanticen mi seguridad e integridad.
''';
    }

    if (sub == "falta de medidas de protección") {
      return '''
Solicito que se tutele mi derecho fundamental a la vida, ante la omisión de medidas de protección pese a la existencia de riesgos conocidos.\n\n
Ordénese la adopción urgente de acciones concretas y adecuadas por parte de las autoridades para garantizar mi vida e integridad física.
''';
    }

    if (sub == "riesgo por condiciones insalubres") {
      return '''
Solicito que se tutele mi derecho fundamental a la vida, frente a las condiciones insalubres del lugar de reclusión que ponen en peligro mi salud.\n\n
Ordénese a las autoridades penitenciarias adoptar de forma inmediata medidas que mejoren las condiciones de higiene, ventilación y salubridad en mi lugar de reclusión.
''';
    }

    if (sub == "riesgo por hacinamiento") {
      return '''
Solicito que se tutele mi derecho fundamental a la vida, vulnerado por el hacinamiento extremo en el que me encuentro privado de la libertad.\n\n
Ordénese la reubicación inmediata o la adopción de medidas urgentes que reduzcan el riesgo sanitario y físico derivado de dicha situación.
''';
    }

    if (sub == "negligencia médica grave") {
      return '''
Solicito que se tutele mi derecho fundamental a la vida, afectado por la negligencia médica grave que ha impedido el acceso a atención oportuna.\n\n
Ordénese brindar atención médica especializada de forma inmediata, conforme a mi estado de salud y bajo supervisión de personal calificado.
''';
    }

    return '''
Solicito que se tutele mi derecho fundamental a la vida, conforme a los hechos narrados.\n\n
Ordénese adoptar las medidas necesarias que garanticen su protección efectiva.
''';
  }



}
