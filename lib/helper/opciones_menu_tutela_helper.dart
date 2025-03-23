// 📁 MenuOptionsTutelaHelper.dart
// Provee las categorías y subcategorías de derechos tutelables para PPL

class MenuOptionsTutelaHelper {
  static final List<String> _categorias = [
    "Salud",
    "Vida",
    "Integridad personal",
    "Dignidad humana",
    "Debido proceso",
    "Intimidad",
    "Educación",
  ];

  static final Map<String, List<String>> _subcategorias = {
    "Salud": [
      "Negación de medicamentos",
      "Falta de remisión médica",
      "Demora en atención especializada",
      "Inexistencia de tratamientos adecuados",
      "Urgencia médica no atendida"
    ],
    "Vida": [
      "Amenazas dentro del penal",
      "Falta de medidas de protección",
      "Riesgo por condiciones insalubres",
      "Riesgo por hacinamiento",
      "Negligencia médica grave"
    ],
    "Integridad personal": [
      "Tratos crueles o degradantes",
      "Violencia física o psicológica",
      "Aislamiento prolongado e injustificado",
      "Negligencia frente a salud mental",
      "Negación de atención psicológica"
    ],
    "Dignidad humana": [
      "Condiciones de reclusión inhumanas",
      "Falta de acceso a servicios básicos",
      "Hacinamiento extremo",
      "Trato denigrante por personal penitenciario",
      "Falta de intimidad mínima"
    ],
    "Debido proceso": [
      "Falta de notificación de decisiones",
      "Negación del derecho a defensa",
      "Falta de acceso a expediente judicial",
      "Demora injustificada en decisiones judiciales",
    ],
    "Intimidad": [
      "Revisión invasiva de correspondencia",
      "Divulgación de información médica sin autorización",
      "Violación de correspondencia personal",
      "Uso de cámaras en espacios íntimos",
      "Acceso no autorizado a comunicaciones familiares"
    ],
    "Educación": [
      "Negación de acceso a programas educativos",
      "Falta de materiales o personal docente",
      "Discriminación por antecedentes",
      "Suspensión injustificada del proceso educativo",
      "Falta de adaptación educativa a PPL"
    ],
  };

  static List<String> obtenerCategorias() {
    return _categorias;
  }

  static List<String> obtenerSubcategorias(String categoria) {
    return _subcategorias[categoria] ?? [];
  }
}
