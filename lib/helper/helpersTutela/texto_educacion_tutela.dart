// texto_educacion.dart
class TextoEducacion {
  static String obtenerTexto(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "negación de acceso a programas educativos") {
      return '''
La negativa a permitir el acceso a programas educativos dentro del centro penitenciario vulnera el derecho fundamental a la educación (art. 67 CP), así como el principio de resocialización (art. 10 Ley 65 de 1993), al impedir el desarrollo personal y la reintegración social de la persona privada de la libertad.''';
    }

    if (sub == "falta de materiales o personal docente") {
      return '''
La ausencia de recursos pedagógicos y de personal capacitado en los programas educativos de los centros penitenciarios vulnera el derecho a una educación efectiva (art. 67 CP) y el principio de igualdad material (art. 13 CP), al crear barreras estructurales que afectan el acceso real al proceso formativo.''';
    }

    if (sub == "discriminación por antecedentes") {
      return '''
La exclusión de personas privadas de la libertad de programas educativos con base en sus antecedentes penales vulnera el derecho a la educación sin discriminación (arts. 13 y 67 CP), y contraviene el principio de igualdad ante la ley y el deber estatal de garantizar la educación como derecho universal.''';
    }

    if (sub == "suspensión injustificada del proceso educativo") {
      return '''
La suspensión arbitraria o prolongada de los programas educativos sin una justificación legal vulnera el derecho a la educación continua (art. 67 CP) y al debido proceso (art. 29 CP), generando una afectación directa al proyecto de vida del interno.''';
    }

    if (sub == "falta de adaptación educativa a ppl") {
      return '''
La ausencia de ajustes razonables que permitan a las personas privadas de la libertad acceder a la educación en condiciones compatibles con su situación de reclusión vulnera los derechos a la igualdad (art. 13 CP) y a la educación (art. 67 CP), así como los principios de dignidad y resocialización.''';
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
