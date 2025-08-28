// 📁 PreguntasTutelaHelper.dart
// Provee preguntas por categoría y subcategoría para solicitudes de tutela presentadas por familiares o acudientes de personas privadas de la libertad

class PreguntasTutelaHelper {
  static List<String> obtenerPreguntas(String? categoria, String? subcategoria) {
    if (categoria == null || subcategoria == null) return [];

    switch (categoria) {
      case 'Salud':
        return [
          'Redacta un relato claro y cronológico sobre tu necesidad o situación de salud. Incluye, en lo posible: qué requieres o qué se te negó/omitió/retrasó; fechas y, si puedes, lugares; entidades o personas involucradas (Sanidad del penal, ESE/EPS u hospital); cuéntanos si realizaste gestiones previas y si tuviste respuesta o no; cómo impacta en tu salud o pone en riesgo tu vida o integridad. Entre más completo el relato, mejor.'
        ];

      case 'Vida':
        return [
          'Redacta un relato claro y cronológico sobre la situación que amenaza tu vida. Incluye, en lo posible: en qué consiste la amenaza (si es actual, inminente o reiterada); fechas y, si puedes, lugares; personas o entidades involucradas (otros internos, funcionarios o grupos); si informaste a funcionarios del penal o presentaste denuncias y qué respuesta hubo (o si no hubo); medidas de protección solicitadas o esperadas; antecedentes de violencia, amenazas o negligencia; y si cuentas con evidencia o testigos. Entre más completo el relato, mejor.'
        ];

      case 'Integridad personal':
        return [
          'Redacta un relato claro y cronológico sobre los hechos que afectan tu integridad personal (física, mental o emocional). Incluye, en lo posible: qué ocurrió y cómo te afectó; si hubo tratos crueles, inhumanos o degradantes y por parte de quién; fechas y, si puedes, lugares; si recibiste atención médica o psicológica y qué diagnóstico o recomendaciones hubo; si informaste a las autoridades penitenciarias o presentaste quejas y cuál fue la respuesta (o si no hubo); si los hechos han sido reiterados o continúan; y qué medidas u órdenes solicitas al juez. Entre más completo el relato, mejor.'
        ];

      case 'Dignidad humana':
        return [
          'Redacta un relato claro y cronológico sobre la situación que afecta tu dignidad humana dentro del penal. Incluye, en lo posible: las condiciones materiales o tratos que consideras indignos (acceso a agua, salud, alimentación, higiene, descanso, saneamiento, hacinamiento, entre otros); fechas y, si puedes, lugares o pabellones; personas o autoridades involucradas; solicitudes o quejas presentadas ante la dirección del penal u otras entidades y la respuesta (o si no hubo); las consecuencias para tu salud física, mental o emocional; y si cuentas con evidencia (fotografías, testimonios o documentos). Entre más completo el relato, mejor.'
        ];

      case 'Debido proceso':
        return [
          'Redacta un relato claro y cronológico sobre la situación que vulnera tu derecho al debido proceso. Incluye, en lo posible: qué actuación administrativa o judicial se surtió sin tu conocimiento o participación; si te notificaron la decisión que te afectó y cuándo, o si hubo decisiones judiciales no notificadas; recursos, solicitudes o reclamaciones presentadas y su respuesta; autoridad o despacho involucrado; fechas y, si puedes, lugares; y qué orden solicitas al juez (por ejemplo, notificar formalmente, reponer términos, declarar nulidad o practicar pruebas). Entre más completo el relato, mejor.'
        ];


      case 'Intimidad':
        return [
          'Redacta un relato claro y cronológico sobre la situación que afectó tu intimidad personal o familiar. Incluye, en lo posible: qué hecho vulneró tu privacidad (acceso a correspondencia, historias clínicas, llamadas o registros); quién lo realizó; si ocurrió en espacios íntimos (celda, visitas) y si hubo grabaciones; si fue aislado o reiterado; si denunciaste o informaste a autoridades y qué respuesta hubo; consecuencias para ti y, si cuentas con evidencia o testigos, menciónalos; y qué medidas u órdenes solicitas al juez para proteger tu intimidad. Entre más completo el relato, mejor.'
        ];


      case 'Educación':
        return [
          'Redacta un relato claro y cronológico sobre tu necesidad o situación frente al acceso a la educación. Incluye, en lo posible: solicitudes hechas para ingresar o continuar en programas educativos dentro del establecimiento; obstáculos enfrentados (materiales, profesores, cupos, traslados, conectividad); si la negativa fue justificada o arbitraria y por quién; el tipo de formación que deseas cursar (básica, media, técnica o superior); constancias o respuestas de la institución; fechas y, si puedes, lugares; y qué orden solicitas al juez (por ejemplo, acceso, inscripción o suministro de materiales). Entre más completo el relato, mejor.'
        ];

      default:
        return ["Describa la situación con el mayor nivel de detalle posible."];
    }
  }
}
