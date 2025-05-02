// texto_intimidad.dart
class TextoIntimidad {
  static String obtenerTexto(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "revisión invasiva de correspondencia") {
      return '''
La interceptación, apertura o revisión injustificada de la correspondencia personal vulnera el derecho fundamental a la intimidad (art. 15 CP) y el secreto de las comunicaciones, además de afectar la privacidad familiar y la autonomía del interno para comunicarse libremente.''';
    }

    if (sub == "divulgación de información médica sin autorización") {
      return '''
La revelación de datos médicos personales sin el consentimiento informado del paciente priva a la persona de su derecho a la intimidad (art. 15 CP) y a la confidencialidad de su historia clínica, derecho reconocido también por la Ley 1581 de 2012 sobre protección de datos.''';
    }

    if (sub == "violación de correspondencia personal") {
      return '''
La violación del contenido de cartas enviadas o recibidas por personas privadas de la libertad constituye una transgresión al derecho a la intimidad y a la libertad de comunicación, protegido por el artículo 15 de la Constitución y el artículo 42 de la Ley 65 de 1993.''';
    }

    if (sub == "uso de cámaras en espacios íntimos") {
      return '''
La instalación de dispositivos de videovigilancia en baños, duchas o celdas sin justificación legal adecuada constituye una injerencia desproporcionada en la intimidad personal, vulnerando el derecho constitucional a la privacidad (art. 15 CP) y el principio de dignidad humana.''';
    }

    if (sub == "acceso no autorizado a comunicaciones familiares") {
      return '''
La intromisión en conversaciones familiares sin orden judicial o sin motivación legal válida vulnera el derecho a la intimidad (art. 15 CP), el secreto de las comunicaciones y la protección especial que debe brindarse al núcleo familiar del recluso (art. 42 CP).''';
    }

    return "Texto no disponible para esta subcategoría.";
  }

  static String obtenerNormasIntimidad(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "revisión invasiva de correspondencia") {
      return '''
Artículo 15 de la Constitución Política: consagra el derecho fundamental a la intimidad personal y familiar, incluyendo la inviolabilidad de la correspondencia y demás formas de comunicación privada.

Artículo 12 de la Declaración Universal de los Derechos Humanos: prohíbe injerencias arbitrarias en la vida privada, la familia, la correspondencia y el honor de las personas.

Sentencias T-332 de 2012 y T-702 de 2013: la Corte Constitucional reitera que la revisión de correspondencia en contextos carcelarios debe ser excepcional, motivada y realizada bajo parámetros estrictos que garanticen el respeto por la intimidad.
''';
    }

    if (sub == "divulgación de información médica sin autorización") {
      return '''
Artículo 15 de la Constitución Política: protege el derecho al buen nombre y a la intimidad personal, incluyendo la reserva sobre la historia clínica y los datos sensibles.

Ley 1581 de 2012: regula la protección de datos personales en Colombia, estableciendo que la información médica solo puede ser tratada con autorización del titular.

Sentencias T-101 de 2015 y T-473 de 2019: la Corte señala que revelar información médica sin consentimiento constituye una vulneración grave a la intimidad y al derecho a la salud.
''';
    }

    if (sub == "violación de correspondencia personal") {
      return '''
Artículo 15 de la Constitución Política: garantiza la inviolabilidad de la correspondencia como manifestación del derecho a la intimidad.

Artículo 42 de la Ley 65 de 1993: establece que las comunicaciones de los internos, especialmente con sus familiares y abogados, deben respetar su confidencialidad, salvo en casos excepcionales.

Sentencia T-123 de 2004: la Corte resalta que la apertura injustificada de correspondencia personal de los reclusos constituye una violación al derecho fundamental a la intimidad.
''';
    }

    if (sub == "uso de cámaras en espacios íntimos") {
      return '''
Artículo 15 de la Constitución Política: protege la vida privada de las personas, prohibiendo intervenciones arbitrarias o desproporcionadas.

Ley 1581 de 2012 y Decreto 1377 de 2013: regulan el tratamiento de datos personales e imágenes, exigiendo consentimiento para la captura y uso de datos sensibles.

Sentencias T-303 de 2021 y T-289 de 2017: la Corte advierte que instalar cámaras en zonas íntimas o sin justificación razonable vulnera el derecho a la intimidad y puede constituir una forma de trato degradante.
''';
    }

    if (sub == "acceso no autorizado a comunicaciones familiares") {
      return '''
Artículo 15 de la Constitución Política: reconoce el derecho a la privacidad en las comunicaciones, incluyendo aquellas con familiares.

Artículo 42 de la Constitución Política: consagra la protección reforzada a la familia como núcleo esencial de la sociedad.

Sentencias T-257 de 2007 y T-438 de 2013: establecen que las restricciones o accesos no autorizados a las comunicaciones familiares deben ser excepcionales y debidamente justificadas, respetando el principio de dignidad humana.
''';
    }

    return 'No se han definido normas aplicables para esta subcategoría.';
  }


  static String obtenerPretensionesIntimidad(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "revisión invasiva de correspondencia") {
      return '''
Solicito que se tutele mi derecho fundamental a la intimidad, vulnerado por la revisión injustificada y sistemática de mi correspondencia personal.\n\n
Ordénese cesar dichas prácticas y establecer garantías para la confidencialidad de mis comunicaciones.
''';
    }

    if (sub == "divulgación de información médica sin autorización") {
      return '''
Solicito que se tutele mi derecho a la intimidad y a la confidencialidad médica, vulnerado por la divulgación de información clínica sin mi consentimiento.\n\n
Ordénese adoptar protocolos de manejo reservado de los datos personales y clínicos conforme a la normativa legal vigente.
''';
    }

    if (sub == "violación de correspondencia personal") {
      return '''
Solicito que se tutele mi derecho fundamental a la intimidad, afectado por la apertura o lectura no autorizada de mi correspondencia privada.\n\n
Ordénese a las autoridades penitenciarias abstenerse de interceptar mis comunicaciones sin justificación legal, respetando mis derechos fundamentales.
''';
    }

    if (sub == "uso de cámaras en espacios íntimos") {
      return '''
Solicito que se tutele mi derecho a la intimidad personal, vulnerado por la instalación de cámaras en lugares destinados al aseo, descanso o privacidad.\n\n
Ordénese el retiro inmediato de dichos dispositivos y se adopten medidas que garanticen la privacidad mínima exigida por los estándares constitucionales.
''';
    }

    if (sub == "acceso no autorizado a comunicaciones familiares") {
      return '''
Solicito que se tutele mi derecho fundamental a la intimidad y a la vida familiar, vulnerado por la interceptación o supervisión injustificada de mis comunicaciones con familiares.\n\n
Ordénese restringir dichas prácticas y se asegure un canal de comunicación respetuoso con mis derechos fundamentales.
''';
    }

    return '''
Solicito que se tutele mi derecho a la intimidad, conforme a lo expuesto en los hechos narrados.\n\n
Ordénese a las autoridades penitenciarias respetar y garantizar este derecho conforme a los estándares constitucionales y jurisprudenciales.
''';
  }


}
