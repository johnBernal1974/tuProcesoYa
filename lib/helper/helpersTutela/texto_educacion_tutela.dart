// texto_educacion.dart
class TextoEducacion {
  static String obtenerTexto(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "negación de acceso a programas educativos") {
      return '''
La negación de acceso a programas educativos vulnera directamente mi derecho fundamental a la educación, consagrado en el artículo 67 de la Constitución Política, y también afecta mi derecho a la igualdad, la dignidad humana y el principio de resocialización previsto en el artículo 1 de la Ley 65 de 1993 (Código Penitenciario y Carcelario).

La Corte Constitucional ha sostenido que el acceso a la educación en centros penitenciarios no es un privilegio, sino un deber y un derecho exigible. En la Sentencia T-282 de 2016, la Corte reafirmó que las autoridades penitenciarias deben garantizar de manera progresiva y efectiva el acceso de los internos a programas educativos como parte de su proceso de resocialización y dignificación.

La omisión en brindar este acceso configura una falla del Estado en su obligación de asegurar la formación integral de las personas privadas de la libertad, perpetuando condiciones de exclusión y vulnerabilidad.''';
    }

    if (sub == "falta de materiales o personal docente") {
      return '''
La ausencia de materiales educativos o personal docente dentro del establecimiento carcelario afecta el núcleo esencial del derecho a la educación, en tanto impide el desarrollo efectivo del proceso formativo y académico de las personas privadas de la libertad.

El artículo 67 de la Constitución establece que la educación es un derecho de la persona y un servicio público que cumple una función social. Según la Sentencia T-529 de 2009, el Estado tiene la obligación de proveer los recursos mínimos para hacer efectiva la educación en los centros penitenciarios, lo cual incluye docentes capacitados, instalaciones adecuadas y material didáctico.

La falta de estos elementos convierte la oferta educativa en una ilusión, vulnerando además principios de equidad, igualdad de oportunidades y el deber estatal de resocialización.''';
    }

    if (sub == "discriminación por antecedentes") {
      return '''
La exclusión de programas educativos por razón de los antecedentes penales constituye una forma de discriminación proscrita por la Constitución (artículos 13 y 67) y la jurisprudencia constitucional.

En la Sentencia T-499 de 2011, la Corte Constitucional precisó que los antecedentes penales no pueden ser una barrera para el acceso a derechos como la educación, dado que esto perpetúa el estigma y contraviene el principio de resocialización. Las personas privadas de la libertad deben tener igualdad de oportunidades frente al acceso a programas de formación y superación personal.

Por tanto, limitar el acceso a la educación por estos motivos constituye una vulneración a la dignidad humana y al derecho a la igualdad.''';
    }

    if (sub == "suspensión injustificada del proceso educativo") {
      return '''
La interrupción o suspensión injustificada del proceso educativo de una persona privada de la libertad vulnera el derecho fundamental a la educación, protegido por el artículo 67 de la Constitución, y contradice el principio de continuidad de los derechos fundamentales, tal como lo ha sostenido la jurisprudencia constitucional.

En la Sentencia T-401 de 2010, la Corte sostuvo que el acceso a la educación debe prestarse con regularidad, y que su suspensión solo puede justificarse por razones objetivas y proporcionales. La interrupción arbitraria o negligente impide el desarrollo personal y limita las oportunidades de reintegración social del interno.

El derecho a la educación no puede depender de factores administrativos o del capricho de las autoridades del centro penitenciario.''';
    }

    if (sub == "falta de adaptación educativa a ppl") {
      return '''
La falta de adaptación de la oferta educativa a las condiciones y necesidades específicas de las personas privadas de la libertad vulnera el derecho a la educación con enfoque diferencial, el cual es exigible en virtud del principio de dignidad humana (art. 1 CP), igualdad (art. 13 CP) y educación (art. 67 CP).

En la Sentencia T-218 de 2013, la Corte Constitucional resaltó la necesidad de adoptar medidas diferenciadas para garantizar el acceso efectivo a la educación de grupos en situación de vulnerabilidad, incluidos los reclusos. Esto implica ofrecer horarios flexibles, material accesible, y rutas pedagógicas adaptadas a las condiciones carcelarias.

Negarse a implementar esta adaptación profundiza la exclusión social de las personas privadas de la libertad y les impide ejercer su derecho a la educación en condiciones de equidad.''';
    }

    return "Texto no disponible para esta subcategoría.";
  }

  static String obtenerNormasEducacion(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "negación de acceso a programas educativos") {
      return '''
Artículo 67 de la Constitución Política: establece que la educación es un derecho de la persona y un servicio público que tiene una función social.

Reglas Mandela (Regla 104): disponen que los reclusos deben tener acceso a programas educativos, incluyendo instrucción básica obligatoria.

Sentencia T-745 de 2010: la Corte reiteró que negar el acceso a la educación en reclusión vulnera el derecho a la resocialización y dignidad humana.
''';
    }

    if (sub == "falta de materiales o personal docente") {
      return '''
Artículo 67 de la Constitución Política: impone al Estado el deber de asegurar condiciones adecuadas para la prestación del servicio educativo.

Sentencia T-263 de 2009: la Corte ordenó garantizar materiales e infraestructura mínima para la educación de personas privadas de la libertad.

Sentencia T-685 de 2012: reiteró que el acceso a una educación digna incluye condiciones logísticas, humanas y pedagógicas suficientes.
''';
    }

    if (sub == "discriminación por antecedentes") {
      return '''
Artículo 13 de la Constitución Política: reconoce la igualdad ante la ley y prohíbe toda forma de discriminación.

Artículo 67 de la Constitución Política: reafirma el derecho de toda persona a la educación, sin distinción.

Ley 1098 de 2006, artículo 41: prohíbe expresamente cualquier acto discriminatorio en el ámbito educativo.

Sentencia T-606 de 2007: la Corte estableció que excluir a una persona de programas educativos por su condición jurídica es un acto de discriminación inaceptable.
''';
    }

    if (sub == "suspensión injustificada del proceso educativo") {
      return '''
Artículo 67 de la Constitución Política: obliga a garantizar la continuidad del proceso educativo.

Ley 115 de 1994 (Ley General de Educación): señala que el Estado debe asegurar el acceso y permanencia en el sistema educativo.

Sentencia T-943 de 2001: la Corte afirmó que suspender arbitrariamente el acceso a la educación vulnera el derecho a la formación integral.
''';
    }

    if (sub == "falta de adaptación educativa a ppl") {
      return '''
Artículo 13 de la Constitución Política: garantiza el principio de igualdad, incluyendo ajustes razonables para personas en condiciones especiales.

Artículos 67 y 68 de la Constitución: aseguran el derecho a una educación acorde a las capacidades y condiciones de los estudiantes.

Reglas Mandela (Regla 104): disponen que los programas educativos deben adaptarse a las necesidades individuales de los reclusos.

Sentencia T-025 de 2004: reconoce la obligación de diseñar políticas públicas inclusivas y con enfoque diferencial.

Sentencia T-655 de 2013: enfatiza el deber del Estado de adaptar el servicio educativo a las condiciones de vulnerabilidad y reclusión.
''';
    }

    return 'No se han definido normas aplicables para esta subcategoría.';
  }



  static String obtenerPretensionesEducacion(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "negación de acceso a programas educativos") {
      return '''
Solicito que se tutele mi derecho fundamental a la educación, vulnerado por la negativa de acceso a los programas formativos ofrecidos en el establecimiento penitenciario.\n\n
Ordénese garantizar mi inclusión en dichos programas, permitiendo el desarrollo académico y personal conforme a los principios de resocialización y dignidad humana.
''';
    }

    if (sub == "falta de materiales o personal docente") {
      return '''
Solicito que se tutele mi derecho fundamental a la educación, afectado por la falta de condiciones mínimas para el aprendizaje.\n\n
Ordénese a la entidad correspondiente dotar al establecimiento penitenciario de los materiales educativos y personal docente requeridos para el desarrollo de los programas académicos.
''';
    }

    if (sub == "discriminación por antecedentes") {
      return '''
Solicito que se tutele mi derecho a la educación, junto al principio de igualdad y no discriminación, vulnerados por la exclusión injustificada de los programas académicos debido a mis antecedentes penales.\n\n
Ordénese eliminar todo criterio de exclusión basado en antecedentes judiciales, garantizando el acceso igualitario a la educación dentro del establecimiento.
''';
    }

    if (sub == "suspensión injustificada del proceso educativo") {
      return '''
Solicito que se tutele mi derecho fundamental a la educación, afectado por la suspensión arbitraria de mi proceso formativo.\n\n
Ordénese el restablecimiento inmediato de mi participación en el programa educativo, así como medidas para asegurar su continuidad y culminación efectiva.
''';
    }

    if (sub == "falta de adaptación educativa a ppl") {
      return '''
Solicito que se tutele mi derecho a una educación inclusiva y adaptada, vulnerado por la falta de ajustes razonables frente a mi condición de persona privada de la libertad.\n\n
Ordénese implementar las adecuaciones pedagógicas necesarias que permitan mi acceso real y efectivo a los programas formativos en condiciones equitativas.
''';
    }

    return '''
Solicito que se tutele mi derecho fundamental a la educación, conforme a lo expuesto en los hechos narrados.\n\n
Ordénese a las autoridades garantizar el ejercicio efectivo de este derecho bajo condiciones dignas, continuas y sin discriminación.
''';
  }



}
