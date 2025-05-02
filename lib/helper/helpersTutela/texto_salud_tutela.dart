// texto_salud.dart

class TextoSalud {

  static String obtenerTexto(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "negación de medicamentos") {
      return '''
Se vulnera el derecho fundamental a la salud (art. 49 de la Constitución Política), al negarse el suministro de medicamentos prescritos por un profesional. Esta omisión afecta, además, los derechos a la vida (art. 11) y a la dignidad humana (art. 1), al poner en riesgo la integridad física y mental del solicitante.
''';
    }

    if (sub == "falta de remisión médica") {
      return '''
Se vulneran los derechos fundamentales a la salud (art. 49 CP), a la vida (art. 11 CP) y a la integridad personal, al no garantizar la remisión oportuna a un especialista, pese a la orden médica. Esta omisión impide una atención continua, integral y eficaz.
''';
    }

    if (sub == "demora en atención especializada") {
      return '''
Se vulnera el derecho a la salud (art. 49 CP), particularmente en su dimensión de acceso oportuno y continuo, así como el derecho a la vida (art. 11 CP), al dilatar injustificadamente el acceso a servicios médicos especializados requeridos.
''';
    }

    if (sub == "inexistencia de tratamientos adecuados") {
      return '''
Se vulneran los derechos fundamentales a la salud (art. 49 CP) y a la dignidad humana (art. 1 CP), al no garantizar un tratamiento adecuado y conforme al diagnóstico médico, lo cual compromete la efectividad del sistema de salud y la vida del paciente.
''';
    }

    if (sub == "urgencia médica no atendida") {
      return '''
Se vulneran los derechos fundamentales a la vida (art. 11 CP), a la salud (art. 49 CP) y a la integridad personal, al omitirse la atención médica inmediata en un caso de urgencia evidente, desconociendo la obligación estatal de proteger la vida en situaciones críticas.
''';
    }

    return "Texto no disponible para esta subcategoría.";
  }

  static String obtenerNormasAplicables(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "negación de medicamentos") {
      return '''
Artículo 48 de la Constitución Política: reconoce la seguridad social como un servicio público de carácter obligatorio, con garantía de acceso universal. El derecho a la salud se entiende como un derecho fundamental autónomo.

Artículo 49 de la Constitución Política: establece la obligación del Estado de garantizar el acceso a los servicios de promoción, protección y recuperación de la salud.

Artículo 11 de la Constitución: protege el derecho fundamental a la vida, el cual se ve amenazado ante la negación de medicamentos esenciales.

Sentencia T-860 de 2007: establece que la interrupción o negación de tratamientos formulados vulnera el derecho a la salud, la vida y la dignidad humana.

Sentencia T-760 de 2008: reconoce la salud como derecho fundamental y refuerza el deber de garantizar la continuidad de tratamientos médicos prescritos por profesionales de la salud.

Sentencia T-344 de 2017: refuerza que el sistema de salud no puede trasladar la carga administrativa al paciente ni interrumpir tratamientos esenciales.
''';
    }

    if (sub == "falta de remisión médica") {
      return '''
Artículo 49 de la Constitución Política: establece el derecho fundamental a la salud y la obligación del Estado de garantizar su prestación oportuna.

Artículo 1 de la Constitución: garantiza el respeto a la dignidad humana, lo cual exige atención médica integral.

Sentencia T-1025 de 2007: señala que omitir o dilatar una remisión médica urgente constituye una barrera de acceso inconstitucional.

Sentencia T-315 de 2016: establece que las EPS o autoridades no pueden obstaculizar el acceso a especialistas mediante trámites innecesarios.

Sentencia T-110 de 2019: recuerda que el derecho a la salud implica el acceso oportuno, continuo e integral a los servicios médicos requeridos.
''';
    }

    // Repite lo mismo para las demás subcategorías...

    return "Normas no definidas para esta subcategoría.";
  }

  static String obtenerPretensiones(String subcategoria) {
    final sub = subcategoria.toLowerCase();

    if (sub == "negación de medicamentos") {
      return '''
Solicito que se tutele mi derecho fundamental a la salud, frente a la negación injustificada de medicamentos previamente formulados por el personal médico tratante.\n\n
Ordénese a la entidad correspondiente la entrega inmediata, completa y continua de dichos medicamentos, sin dilaciones ni barreras administrativas, garantizando así el acceso efectivo al tratamiento prescrito.
''';
    }

    if (sub == "falta de remisión médica") {
      return '''
Solicito que se tutele mi derecho fundamental a la salud, vulnerado por la falta de remisión médica oportuna a los especialistas requeridos.\n\n
Ordénese a la entidad de salud realizar de forma inmediata la remisión correspondiente, conforme a la valoración médica practicada y en atención a la urgencia que exige el caso.
''';
    }

    if (sub == "demora en atención especializada") {
      return '''
Solicito que se tutele mi derecho fundamental a la salud, afectado por la dilación injustificada en la asignación de atención médica especializada.\n\n
Ordénese a la entidad de salud asignar de forma prioritaria la cita requerida con el especialista correspondiente, en el menor tiempo posible, y adoptar correctivos que eviten nuevas demoras.
''';
    }

    if (sub == "inexistencia de tratamientos adecuados") {
      return '''
Solicito que se tutele mi derecho fundamental a la salud, vulnerado por la ausencia de un tratamiento adecuado conforme al diagnóstico emitido.\n\n
Ordénese garantizar la prestación de un tratamiento médico idóneo, integral y ajustado a mis condiciones clínicas, eliminando toda barrera de acceso al mismo.
''';
    }

    if (sub == "urgencia médica no atendida") {
      return '''
Solicito que se tutele mi derecho fundamental a la salud y a la vida, debido a la omisión de atención médica en una situación de urgencia manifiesta.\n\n
Ordénese a la entidad correspondiente adoptar medidas que aseguren la atención médica inmediata ante futuras emergencias, y se tomen correctivos frente a la omisión ocurrida.
''';
    }

    return "No se ha definido una pretensión específica para esta subcategoría.";
  }

  static String obtenerPruebas(String subcategoria) {
    return '''
Como pruebas de los hechos expuestos, adjunto el derecho de petición elevado anteriormente solicitando la atención requerida,\n\n
junto con los documentos clínicos, fórmulas médicas, resultados de exámenes y demás soportes que evidencian la necesidad del tratamiento y la omisión de atención por parte de la entidad encargada.\n\n
Estos documentos permiten demostrar la vulneración de mis derechos fundamentales, en particular el derecho a la salud, y sustentan la presente solicitud de amparo constitucional.
''';
  }



}
