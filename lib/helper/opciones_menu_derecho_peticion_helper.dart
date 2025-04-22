class MenuOptionsDerechoPeticionHelper {
  /// Devuelve un mapa con las categorías y sus respectivas subcategorías
  static final Map<String, List<String>> menuOptions = {
    "Beneficios Penitenciarios": [
      "Redención de pena",
    ],
    "Salud y Atención Médica": [
      "Atención médica oportuna y adecuada",
      "Acceso a medicamentos",
      "Acceso a tratamientos especializados",
      "Remisión a especialistas",
      "Cirugías y/o procedimientos urgentes",
      "Condiciones de higiene y salubridad",
    ],
    "Condiciones de Reclusión": [
      "Acceso a agua y alimentación",
      "Malos tratos",
      "Traslados por seguridad"
    ],
    "Régimen Disciplinario": [
      "Impugnación de sanciones",
      "Revisión de procesos",
      "Acceso a beneficios"
    ],
    "Trabajo": [
      "Derecho a trabajar",
      "Capacitación laboral"
    ],
    "Educación": [
      "Capacitación laboral"
    ],
    "Visitas y Contacto": [
      "Visitas familiares",
      "Visitas conyugales",
      "Videollamadas"
    ],
    "Protección de Grupos Vulnerables": [
      "Protección a mujeres",
      "Protección a población adulta mayor",
      "Personas con discapacidad o condiciones de salud especiales",
      "Derechos de la población LGBTIQ+",
      "Derechos de Afrocolombianos",
      "Derechos de indígenas",
    ],
    "Otros": [
      "Condición o situación especial",
    ],
  };

  /// Obtiene todas las categorías disponibles
  static List<String> obtenerCategorias() {
    return menuOptions.keys.toList();
  }

  /// Obtiene las subcategorías de una categoría específica
  static List<String> obtenerSubcategorias(String categoria) {
    return menuOptions[categoria] ?? [];
  }

  /// Verifica si una categoría existe en el menú
  static bool categoriaExiste(String categoria) {
    return menuOptions.containsKey(categoria);
  }

  /// Verifica si una subcategoría pertenece a una categoría dada
  static bool subcategoriaExiste(String categoria, String subcategoria) {
    return menuOptions[categoria]?.contains(subcategoria) ?? false;
  }
}
