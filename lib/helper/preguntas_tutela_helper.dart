// 📁 PreguntasTutelaHelper.dart
// Provee preguntas por categoría y subcategoría para solicitudes de tutela presentadas por familiares o acudientes de personas privadas de la libertad

class PreguntasTutelaHelper {
  static List<String> obtenerPreguntas(String? categoria, String? subcategoria) {
    if (categoria == null || subcategoria == null) return [];

    switch (categoria) {
      case "Salud":
        return [
          "¿Cuál es la necesidad médica o tratamiento que requiere la persona privada de la libertad?",
          "¿Qué servicio, medicamento o atención ha sido negado, omitido o retrasado?",
          "¿Sanidad del penal, ESE o entidad de salud fue informada sobre esta situación? ¿Qué respuesta dieron?",
          "¿La persona ha sido valorada por personal médico dentro del penal o en hospital externo?",
          "¿Esta situación afecta su salud o pone en riesgo su vida o integridad física?"
        ];

      case "Vida":
        return [
          "¿Qué situación representa una amenaza real o grave contra la vida de la persona privada de la libertad?",
          "¿Se ha informado a funcionarios del penal o se han realizado denuncias?",
          "¿Qué medidas de protección se han solicitado o se espera que se adopten?",
          "¿La persona ha sido objeto de violencia, amenazas o negligencia reiterada?",
          "¿Existe evidencia o testigos de la situación de riesgo?"
        ];

      case "Integridad personal":
        return [
          "¿Qué hechos o condiciones han afectado la integridad física, mental o emocional de la persona privada de la libertad?",
          "¿Ha recibido tratos crueles, inhumanos o degradantes por parte del personal penitenciario o de otros internos?",
          "¿Recibió atención médica o psicológica tras los hechos?",
          "¿Se informó a las autoridades penitenciarias o se presentó alguna queja?",
          "¿Los hechos han sido reiterados o no han recibido respuesta adecuada?"
        ];

      case "Dignidad humana":
        return [
          "¿Qué condiciones materiales o trato dentro del penal considera indignas para la persona privada de la libertad?",
          "¿Se han vulnerado derechos como acceso a agua, salud, alimentación, higiene o descanso?",
          "¿Se han realizado solicitudes ante la dirección del penal para mejorar dichas condiciones?",
          "¿Qué consecuencias ha tenido esta situación en la persona afectada?",
          "¿Se cuenta con pruebas como fotografías, testimonios o documentos?"
        ];

      case "Debido proceso":
        return [
          "¿Qué actuación administrativa o judicial se surtió sin conocimiento o participación del PPL?",
          "¿La persona fue notificada debidamente de la decisión que le afectó?",
          "¿Tuvo acceso a abogado o defensor para ejercer su defensa?",
          "¿Se presentó algún recurso, solicitud o reclamación frente a la situación?",
          "¿Qué derecho considera que fue vulnerado y por qué?"
        ];

      case "Intimidad":
        return [
          "¿Qué situación considera que vulneró la privacidad personal o familiar del PPL?",
          "¿Quién accedió a correspondencia, información médica o llamadas privadas de la persona privada de la libertad?",
          "¿El hecho ocurrió en un espacio íntimo como la celda o durante visitas? ¿Hubo grabaciones?",
          "¿Fue una situación reiterada o aislada? ¿Se denunció?",
          "¿Qué consecuencias tuvo esta intromisión en su vida privada?"
        ];

      case "Educación":
        return [
          "¿Se ha solicitado acceso a programas educativos dentro del centro penitenciario?",
          "¿Qué obstáculos ha enfrentado la persona privada de la libertad para acceder a educación (materiales, profesores, cupos)?",
          "¿La negativa fue debidamente justificada o fue arbitraria?",
          "¿Qué tipo de formación se desea cursar (básica, media, técnica, superior)?",
          "¿Se cuenta con constancia de la solicitud o de la negativa por parte de la institución?"
        ];

      default:
        return ["Describa la situación con el mayor nivel de detalle posible."];
    }
  }
}
