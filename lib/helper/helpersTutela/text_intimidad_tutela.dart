// texto_intimidad.dart
class TextoIntimidad {
  static String obtenerTexto(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "revisión invasiva de correspondencia") {
      return '''
El derecho fundamental a la intimidad, consagrado en el artículo 15 de la Constitución Política, ha sido vulnerado por la práctica de revisión invasiva de mi correspondencia personal sin autorización judicial previa ni fundamento legal que lo justifique.

La Corte Constitucional ha establecido que, si bien en el contexto penitenciario pueden existir ciertos límites a la intimidad, éstos deben respetar los principios de razonabilidad y proporcionalidad. En la Sentencia T-562 de 2009, se precisó que toda revisión debe estar sustentada en razones de seguridad concretas y no puede implicar la lectura arbitraria del contenido de las comunicaciones personales.

La correspondencia entre un interno y su familia hace parte del núcleo esencial de su privacidad y su intromisión injustificada afecta su dignidad humana y su derecho a mantener lazos afectivos durante la reclusión.''';
    }

    if (sub == "divulgación de información médica sin autorización") {
      return '''
Se vulnera el derecho a la intimidad (art. 15 CP) por la divulgación indebida de mi información médica personal sin mi autorización o sin orden legal o judicial que lo justifique.

La Corte Constitucional, en Sentencia T-414 de 2009, señaló que la historia clínica y la información sobre el estado de salud de una persona son datos sensibles que hacen parte del núcleo esencial de la intimidad, y su manejo está protegido por el principio de confidencialidad médica.

Su divulgación a terceros sin consentimiento constituye una transgresión grave a la privacidad y a la dignidad humana, y más aún si se trata de personas privadas de la libertad, en condición de especial sujeción frente al Estado.''';
    }

    if (sub == "violación de correspondencia personal") {
      return '''
La intervención de mi correspondencia personal sin autorización judicial constituye una violación directa a mi derecho fundamental a la intimidad y al secreto de las comunicaciones, conforme a lo dispuesto en el artículo 15 de la Constitución.

La Corte Constitucional, en la Sentencia T-332 de 2001, afirmó que ni siquiera en contextos de reclusión se puede justificar la interceptación o apertura de correspondencia sin una orden judicial expresa y con fines estrictamente necesarios.

Esta conducta atenta contra la confianza en el sistema penitenciario, debilita los lazos familiares y socava los derechos fundamentales de las personas internas.''';
    }

    if (sub == "uso de cámaras en espacios íntimos") {
      return '''
Se vulnera gravemente mi derecho a la intimidad y dignidad humana al instalarse cámaras de videovigilancia en espacios que exigen privacidad, como duchas, sanitarios o zonas de cambio de ropa, sin ninguna justificación de seguridad proporcional ni autorización judicial.

En la Sentencia T-851 de 2014, la Corte Constitucional reiteró que la videovigilancia en espacios íntimos debe limitarse estrictamente y justificarse con criterios de necesidad, idoneidad y proporcionalidad, ya que la protección de la vida privada sigue vigente incluso dentro del sistema penitenciario.

El uso arbitrario de cámaras en espacios privados constituye una forma de trato denigrante e inhumano que vulnera derechos fundamentales de la población reclusa.''';
    }

    if (sub == "acceso no autorizado a comunicaciones familiares") {
      return '''
La intervención o acceso no autorizado a mis comunicaciones familiares, incluyendo llamadas o videollamadas, vulnera el derecho fundamental a la intimidad y a la comunicación privada, protegido por el artículo 15 de la Constitución y el artículo 17 del Pacto Internacional de Derechos Civiles y Políticos.

La Corte Constitucional, en la Sentencia T-881 de 2002, estableció que las comunicaciones entre personas privadas de la libertad y sus familiares forman parte del ejercicio pleno de su personalidad y derechos fundamentales, y no pueden ser objeto de restricción arbitraria o vigilancia injustificada.

El monitoreo sin control judicial constituye una medida desproporcionada que afecta gravemente el vínculo familiar y la dignidad humana del interno.''';
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
