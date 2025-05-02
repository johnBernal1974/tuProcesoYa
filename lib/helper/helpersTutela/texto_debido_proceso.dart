// texto_debido_proceso.dart

class TextoDebidoProceso {
  static String obtenerTexto(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "falta de notificación de decisiones") {
      return '''
La falta de notificación oportuna de decisiones judiciales o administrativas dentro del contexto penitenciario vulnera mi derecho fundamental al debido proceso, consagrado en el artículo 29 de la Constitución Política.

Este derecho garantiza que toda persona tenga conocimiento de las actuaciones que le afectan, con el fin de ejercer su defensa, presentar recursos o actuar en consecuencia. La Corte Constitucional ha enfatizado en sentencias como la T-352 de 2016 y la T-1037 de 2008 que la omisión en notificar actos que incidan en la situación jurídica de un recluso constituye una violación del debido proceso y del acceso a la justicia.

El desconocimiento de las decisiones impide ejercer el derecho de contradicción, vulnera el principio de publicidad procesal y afecta gravemente el derecho de defensa.''';
    }

    if (sub == "negación del derecho a defensa") {
      return '''
La negación del derecho a defensa dentro de procesos disciplinarios o judiciales en el contexto carcelario vulnera directamente el artículo 29 de la Constitución Política, que establece como garantía fundamental el derecho a ser oído, a presentar pruebas y a controvertir las que se alleguen en su contra.

La Corte Constitucional, en sentencias como la T-1191 de 2004 y la T-452 de 2012, ha reiterado que el interno debe contar con oportunidades reales para ejercer su defensa técnica o material, incluso dentro de los procedimientos penitenciarios. La ausencia de garantías mínimas genera indefensión y afecta gravemente el principio de contradicción y el acceso a la justicia.''';
    }

    if (sub == "falta de acceso a expediente judicial") {
      return '''
La imposibilidad de acceder al expediente judicial que contiene información esencial para mi defensa y el ejercicio de mis derechos vulnera el derecho fundamental al debido proceso, consagrado en el artículo 29 de la Constitución.

El acceso al expediente es una garantía mínima que permite conocer el contenido de las actuaciones, preparar argumentos y ejercer mecanismos de defensa. En la Sentencia T-631 de 2011, la Corte Constitucional estableció que negar el acceso a los documentos procesales configura una barrera inconstitucional al derecho de defensa, especialmente en contextos de reclusión donde las personas privadas de la libertad dependen del Estado para ejercer sus derechos.''';
    }

    if (sub == "demora injustificada en decisiones judiciales") {
      return '''
La demora excesiva en la resolución de solicitudes, recursos o decisiones judiciales relacionadas con mi situación jurídica constituye una violación al derecho fundamental al debido proceso, especialmente al principio de celeridad que debe regir toda actuación judicial o administrativa, conforme al artículo 29 de la Constitución Política.

La Corte Constitucional ha indicado en múltiples pronunciamientos (T-118 de 2010, T-154 de 2014) que el retardo injustificado en la administración de justicia vulnera no solo el debido proceso, sino también el acceso a la justicia y la seguridad jurídica de las personas privadas de la libertad. Este retardo puede afectar directamente situaciones como redenciones de pena, solicitudes de libertad, recursos de apelación y demás trámites esenciales para la garantía de los derechos.''';
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
