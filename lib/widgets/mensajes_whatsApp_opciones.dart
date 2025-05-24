class MensajesWhatsapp {
  static String generarMensaje(String nombre, int diasPrueba, String tipo) {
    switch (tipo) {
      case 'exclusion_art_68':
        return "Hola *$nombre*,\n\n"
            "Hemos validado cuidadosamente tu situación y queremos informarte lo siguiente:\n\n"
            "Según el *Artículo 68A del Código Penal Colombiano*, existen delitos por los cuales no se pueden otorgar beneficios penitenciarios como prisión domiciliaria, libertad condicional o permisos de salida. Esta norma busca restringir dichos beneficios para delitos especialmente graves.\n\n"
            "No obstante, *existen situaciones excepcionales* en las que, aún estando excluido por ley, *sí podría evaluarse el acceso a beneficios*. Estas situaciones incluyen:\n\n"
            "- Haber sido condenado por *tentativa* del delito y no por el delito consumado.\n"
            "- Tener una *condena inferior a 8 años*, en ciertos casos.\n"
            "- Que la condena se haya impuesto bajo *circunstancias atenuantes*.\n"
            "- Casos de *embarazo* o *maternidad reciente*, especialmente si el cuidado del menor está en riesgo.\n"
            "- Contar con *situaciones humanitarias comprobables* (como enfermedades graves, discapacidad, o dependencia familiar severa).\n"
            "- Existencia de *jurisprudencia favorable o interpretación flexible* en casos similares.\n\n"
            "** Si tú o tu familia consideran que puedes estar dentro de alguno de estos casos especiales, *haznos saber de inmediato* para ayudarte a evaluar tu caso.\n\n"
            "Además, recuerda que desde *Tu Proceso Ya* podemos apoyarte con la presentación de *derechos de petición* y *tutelas* para proteger tus derechos fundamentales durante el tiempo de reclusión.\n\n"
            "Ingresa a la plataforma aquí: https://www.tuprocesoya.com\n\n"
            "*El equipo de Tu Proceso Ya*";
            "*Tu Proceso Ya*";

            case 'proceso_en_tribunal':
        return "Hola *$nombre*,\n\n"
            "Actualmente tu caso se encuentra en un *tribunal de segunda instancia*, lo que significa que la sentencia está siendo revisada en apelación o impugnación. Esto ocurre cuando se ha presentado un recurso contra la decisión inicial del juzgado.\n\n"
            "Mientras el tribunal no haya tomado una decisión definitiva, el proceso *no se considera en firme*. Por esta razón, *no es posible solicitar beneficios penitenciarios* como prisión domiciliaria, libertad condicional o permisos especiales en esta etapa.\n\n"
            "Sabemos que esta espera puede ser difícil. Desde *Tu Proceso Ya* estaremos atentos a la evolución del proceso, y si detectamos *retrasos injustificados*, podemos ayudarte a presentar un *derecho de petición* o una *acción de tutela* para exigir al tribunal que actúe con celeridad.\n\n"
            "En cuanto el proceso quede en firme, te informaremos para evaluar si cumples los requisitos para solicitar algún beneficio.\n\n"
            "🔗 Puedes ingresar a la plataforma aquí:\nhttps://www.tuprocesoya.com\n\n"
            "*El equipo de Tu Proceso Ya*";

      case 'sin_juzgado_ejecucion':
        return "Hola *$nombre*,\n\n"
            "Actualmente tu proceso *todavía no cuenta con un Juzgado de Ejecución de Penas asignado*. Esto suele ocurrir cuando la sentencia aún no ha sido remitida por el juzgado de conocimiento o cuando el proceso está en tránsito hacia la jurisdicción actual correspondiente.\n\n"
            "Mientras no exista un juzgado asignado para la etapa de ejecución, *no es posible tramitar solicitudes de beneficios penitenciarios* como prisión domiciliaria, libertad condicional o permisos especiales, ya que estas dependen directamente de ese despacho judicial.\n\n"
            "Desde *Tu Proceso Ya* realizamos seguimiento constante al estado de tu proceso. Si identificamos que hay *retrasos anormales* en la asignación, te ayudaremos a presentar un *derecho de petición* o una *acción de tutela* para exigir que se agilicen los trámites pendientes.\n\n"
            "Tan pronto se asigne el juzgado correspondiente, te notificaremos para evaluar las opciones disponibles.\n\n"
            "🔗 Puedes ingresar a la plataforma aquí:\nhttps://www.tuprocesoya.com\n\n"
            "*El equipo de Tu Proceso Ya*";

      case 'sin_fecha_captura':
        return "Hola *$nombre*,\n\n"
            "Actualmente tu proceso *no cuenta con una fecha de captura registrada o confirmada*. Esto puede ocurrir cuando el proceso de documentación inicial aún no ha sido completado por la autoridad correspondiente, o cuando la información aún no ha sido actualizada formalmente en el sistema judicial.\n\n"
            "La fecha de captura es un dato fundamental para calcular el tiempo de condena cumplido, aplicar redenciones y evaluar tu acceso a *beneficios penitenciarios* como prisión domiciliaria, libertad condicional o permisos especiales.\n\n"
            "Desde *Tu Proceso Ya* realizamos seguimiento constante al estado de tu proceso. Si identificamos que la falta de esta información está generando retrasos o afectaciones, te ayudaremos a presentar un *derecho de petición* o una *acción de tutela* para exigir su inclusión oficial.\n\n"
            "Tan pronto se registre o actualice la fecha de captura, te informaremos para que puedas conocer con claridad el avance de tu condena y las opciones disponibles.\n\n"
            "*Te estaremos contactando para que juntos podamos resolver esta duda y así dejar tu cuenta totalmente actualizada y tu usuario activado.*\n\n"
            "🔗 Puedes ingresar a la plataforma aquí:\nhttps://www.tuprocesoya.com\n\n"
            "*El equipo de Tu Proceso Ya*";



      default:
        return "Hola *$nombre*,\n\n"
            "Tu cuenta ha sido activada exitosamente. Disfruta de *$diasPrueba días gratis* en Tu Proceso Ya.\n\n"
            "Ingresa aquí: https://www.tuprocesoya.com\n\n"
            "*El equipo de Tu Proceso Ya*";
    }
  }
}
