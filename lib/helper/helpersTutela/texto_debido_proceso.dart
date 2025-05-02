// texto_debido_proceso.dart

class TextoDebidoProceso {
  static String obtenerTexto(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "falta de notificación de decisiones") {
      return '''
La ausencia de notificación efectiva de decisiones judiciales o administrativas que afectan derechos individuales constituye una violación al debido proceso (art. 29 CP), al impedir el ejercicio del derecho de defensa, contradicción y acceso oportuno a la justicia.''';
    }

    if (sub == "negación del derecho a defensa") {
      return '''
La falta de oportunidad para intervenir en los procedimientos que afectan directamente a una persona privada de la libertad constituye una vulneración del derecho a la defensa técnica y material, lo cual atenta contra los principios de contradicción, legalidad y equidad (art. 29 CP).''';
    }

    if (sub == "falta de acceso a expediente judicial") {
      return '''
La negativa o dilación injustificada en permitir el acceso al expediente judicial limita la posibilidad de conocer, controvertir y participar activamente en el proceso, vulnerando el derecho al debido proceso y a la información pública (arts. 29 y 74 CP).''';
    }

    if (sub == "demora injustificada en decisiones judiciales") {
      return '''
La dilación excesiva en la resolución de asuntos judiciales o administrativos relacionados con la situación jurídica de una persona privada de la libertad vulnera el principio de celeridad procesal, el derecho al acceso oportuno a la justicia y el derecho a obtener una decisión en tiempo razonable (art. 29 CP y estándares internacionales).''';
    }

    return "Texto no disponible para esta subcategoría.";
  }


  static String obtenerNormasDebidoProceso(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "falta de notificación de decisiones") {
      return '''
Artículo 29 de la Constitución Política: establece que toda persona tiene derecho a un debido proceso, lo cual incluye el conocimiento oportuno de las decisiones que le afectan.

Artículo 8 de la Convención Americana sobre Derechos Humanos: reconoce el derecho a ser informado previamente de las decisiones y acusaciones, y a contar con una defensa adecuada.

Sentencias T-850 de 2006 y T-129 de 2009: la Corte Constitucional señala que no notificar debidamente una decisión vulnera el derecho a la defensa y puede acarrear su nulidad.
''';
    }

    if (sub == "negación del derecho a defensa") {
      return '''
Artículo 29 de la Constitución Política: garantiza el derecho a la defensa en todas las etapas del proceso judicial o administrativo.

Artículo 14 del Pacto Internacional de Derechos Civiles y Políticos: consagra el derecho de toda persona a ser oída con las debidas garantías y a disponer del tiempo y medios adecuados para preparar su defensa.

Sentencias T-533 de 1995 y T-552 de 2016: reafirman que negar o limitar el acceso a defensa técnica o material representa una violación grave del debido proceso.
''';
    }

    if (sub == "falta de acceso a expediente judicial") {
      return '''
Artículos 29 y 74 de la Constitución Política: establecen el derecho al debido proceso y a acceder a documentos públicos, incluyendo expedientes judiciales.

Ley 1437 de 2011 (CPACA): prevé el derecho a consultar el expediente y obtener copias, como parte de la garantía de transparencia y defensa.

Sentencia T-466 de 2003: la Corte precisó que obstaculizar el acceso al expediente equivale a impedir el ejercicio efectivo del derecho de defensa.
''';
    }

    if (sub == "demora injustificada en decisiones judiciales") {
      return '''
Artículo 29 de la Constitución Política: reconoce el derecho a una decisión judicial dentro de un plazo razonable como parte del debido proceso.

Artículo 8.1 de la Convención Americana sobre Derechos Humanos: consagra el derecho a ser juzgado sin dilaciones indebidas.

Sentencias T-558 de 2003 y T-1238 de 2008: la Corte ha señalado que la mora judicial prolongada vulnera el derecho a la justicia pronta y efectiva.
''';
    }

    return 'No se han definido normas aplicables para esta subcategoría.';
  }


  static String obtenerPretensionesDebidoProceso(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "falta de notificación de decisiones") {
      return '''
Solicito que se tutele mi derecho fundamental al debido proceso, vulnerado por la omisión en la notificación de decisiones judiciales o administrativas que me afectan.\n\n
Ordénese a las autoridades competentes garantizar una notificación oportuna, clara y completa, permitiéndome ejercer adecuadamente mis derechos de defensa y contradicción.
''';
    }

    if (sub == "negación del derecho a defensa") {
      return '''
Solicito que se tutele mi derecho fundamental a la defensa, afectado por la imposibilidad de intervenir en actuaciones que me afectan o por la falta de asistencia jurídica oportuna.\n\n
Ordénese permitir mi participación efectiva en los procesos y asegurar el acompañamiento legal correspondiente.
''';
    }

    if (sub == "falta de acceso a expediente judicial") {
      return '''
Solicito que se tutele mi derecho fundamental al debido proceso, vulnerado por la restricción en el acceso a mi expediente judicial.\n\n
Ordénese permitir el acceso inmediato al expediente para conocer las actuaciones, pruebas y decisiones adoptadas, y ejercer los recursos legales correspondientes.
''';
    }

    if (sub == "demora injustificada en decisiones judiciales") {
      return '''
Solicito que se tutele mi derecho al debido proceso, afectado por una dilación injustificada en la resolución de un trámite judicial que afecta directamente mis derechos fundamentales.\n\n
Ordénese a la autoridad competente emitir la decisión correspondiente con base en el principio de celeridad procesal y justicia pronta.
''';
    }

    return '''
Solicito que se tutele mi derecho al debido proceso, conforme a lo expuesto en los hechos narrados.\n\n
Ordénese a las autoridades competentes adoptar las medidas necesarias para restablecer el ejercicio pleno de este derecho.
''';
  }



}
