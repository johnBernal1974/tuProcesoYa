import 'package:intl/intl.dart';

class SolicitudAcumulacionTemplate {
  final String dirigido;
  final String entidad;
  final String referencia;
  final String nombrePpl;
  final String apellidoPpl;
  final String identificacionPpl;
  final String centroPenitenciario;
  final String emailUsuario;
  final String emailAlternativo;
  final String radicado;
  final String jdc;
  final String juzgadoEjecucion;
  final String numeroSeguimiento;
  final String situacion;
  final String nui;
  final String td;
  final String patio;
  final String radicadoAcumular; // 🆕
  final String juzgadoAcumular;  // 🆕

  SolicitudAcumulacionTemplate({
    required this.dirigido,
    required this.entidad,
    required this.referencia,
    required this.nombrePpl,
    required this.apellidoPpl,
    required this.identificacionPpl,
    required this.centroPenitenciario,
    required this.emailUsuario,
    this.emailAlternativo = "peticiones@tuprocesoya.com",
    required this.radicado,
    required this.jdc,
    required this.juzgadoEjecucion,
    required this.numeroSeguimiento,
    required this.situacion,
    required this.nui,
    required this.td,
    required this.patio,
    required this.radicadoAcumular, // 🆕
    required this.juzgadoAcumular,  // 🆕
  });

  String generarTextoHtml() {
    final buffer = StringBuffer();

    buffer.writeln("""
  <html>
    <body style="font-family: Arial, sans-serif;">
      <b>$dirigido</b><br>
      <b>$entidad</b><br><br>

      Asunto: <b>Solicitud de Acumulación Jurídica de Penas Privativas de la Libertad – $numeroSeguimiento</b><br>
      Radicado principal: <b>$radicado</b><br><br><br>
      

      Me amparo en el artículo 85 de la Constitución Política de Colombia y en el artículo 14 de la Ley 1437 de 2011.<br><br>

      E.S.D.<br><br>

      Yo, <b>$nombrePpl $apellidoPpl</b>, identificado con cédula de ciudadanía No. <b>$identificacionPpl</b>, TD: <b>$td</b>, NUI: <b>$nui</b>, actualmente recluido en el establecimiento penitenciario <b>$centroPenitenciario</b>, Patio <b>$patio</b>, solicito a usted de manera 
comedida que se sirva decretar la acumulación jurídica de penas privativas de la libertad, de conformidad con 
los siguientes:<br><br>

      <span style="font-size: 16px;"><b>I. HECHOS</b></span><br><br>


En razón de distintas sentencias condenatorias me encuentro condenado a las siguientes penas:<br><br>

Actualmente me encuentro purgando la pena bajo el radicado <b>$radicado</b>, tramitado en <b>$juzgadoEjecucion.</b><br><br>
Proceso cuya pena se solicita acumular: Radicado <b>$radicadoAcumular</b>, en manos del <b>$juzgadoAcumular</b>.<br><br><br>

     <span style="font-size: 16px;"><b>II. FUNDAMENTOS DE DERECHO</b></span><br><br>

Conforme al artículo 460 de la Ley 906 de 2004, debe aplicarse el instituto de la <b>acumulación jurídica de penas</b>, el cual dispone:<br><br>

<i>“Las normas que regulan la dosificación de la pena, en caso de concurso de conductas punibles, se aplicarán también cuando los delitos conexos se hubieren fallado independientemente. Igualmente, cuando se hubieren proferido varias sentencias en diferentes procesos. En estos casos, la pena impuesta en la primera decisión se tendrá como parte de la sanción a imponer.<br><br>

No podrán acumularse penas por delitos cometidos con posterioridad al proferimiento de sentencia de primera o única instancia en cualquiera de los procesos, ni penas ya ejecutadas, ni las impuestas por delitos cometidos durante el tiempo que la persona estuviere privada de la libertad.”</i><br><br>

No obstante, la lectura de esta figura debe armonizarse con la jurisprudencia de las altas Cortes, que han interpretado la acumulación jurídica como un <b>derecho del condenado</b>, y no como una mera facultad discrecional del juez de ejecución.<br><br>

Al respecto, la <b>Corte Suprema de Justicia – Sala de Casación Penal</b>, en sentencia <b>STP7966-2016</b> (Rad. 86202), señaló:<br><br>

<i>“La acumulación de penas es un derecho del condenado, sobre lo cual la Sala no tiene ninguna duda, en consideración a que su procedencia no está sujeta a la discrecionalidad del Juez de Penas. Su aplicación también procede de oficio, simplemente porque la ley contiene un mandato para el funcionario judicial de acumular las penas acumulables, que no supedita a la mediación de petición de parte.<br><br>

Si eso es así, entonces cuando una pena se ejecutaba y era viable acumularla a otra u otras, pero no se resolvió oportunamente así porque nadie lo solicitó o porque no se hizo uso del principio de oficiosidad judicial, son circunstancias que no pueden significar la pérdida del derecho y, por lo tanto, en dicha hipótesis es procedente la acumulación de la pena ejecutada.”</i><br><br>

Asimismo, el <b>artículo 89 del Código de Procedimiento Penal</b> establece como derecho del procesado que las conductas punibles conexas se investiguen y juzguen conjuntamente, lo cual se traduce en la posibilidad de que:<br><br>

<i>“se le dicte una sola sentencia y que se le dosifique la pena de acuerdo con las reglas establecidas para el concurso de conductas punibles en el artículo 31 del Código Penal.”</i><br><br>

La <b>Corte Constitucional</b>, en la sentencia <b>C-1086 de 2008</b>, sostuvo:<br><br>

<i>“La expresión ‘ni penas ya ejecutadas’ contenida en el inciso segundo de la norma en cuestión, no puede conducir a la exclusión de la posibilidad de acumulación jurídica de penas en eventos de conexidad, cuando una de las condenas ya se encuentre ejecutada. [...] La persona condenada conserva el derecho a la acumulación para efectos de dosificación, en la fase de ejecución de las condenas proferidas en distintos procesos.<br><br>

Tratándose de un beneficio establecido a favor del sentenciado, si las penas eran acumulables pero la acumulación no se produjo porque la petición no se resolvió de manera oportuna, o no se hizo uso del principio de oficiosidad por parte del juez de ejecución, no puede considerarse que en tal hipótesis el cumplimiento de una de las sanciones excluya la posibilidad de su acumulación jurídica.”</i><br><br>

Finalmente, de conformidad con el artículo 31 de la Ley 599 de 2000:<br><br>

<i>Debe identificarse cuál es la pena más grave debidamente dosificada impuesta mediante sentencia condenatoria en firme.</i>
<i>A partir de dicha pena, puede aumentarse otro tanto, sin superar el límite legalmente establecido para el concurso de conductas punibles, cuyo tope máximo es de <b>60 años de prisión</b></i>.<br><br>

      <span style="font-size: 16px;"><b>III. PRETENSIONES</b></span><br><br>

<b>PRIMERO:</b> Que se oficie a los despachos judiciales que han conocido o conocen de los distintos procesos penales en los que he sido condenado, a fin de que remitan copia auténtica de las sentencias ejecutoriadas, con destino al despacho judicial que actualmente vigila la ejecución de las penas.<br><br>

<b>SEGUNDO:</b> Que una vez recibidas las decisiones judiciales pertinentes, se decrete la <b>acumulación jurídica de las penas</b>, conforme a lo previsto en el artículo 460 de la Ley 906 de 2004 y los desarrollos jurisprudenciales aplicables, y se realice una nueva dosificación que tenga como base la pena más grave debidamente individualizada, respetando el límite legal establecido por el artículo 31 del Código Penal.<br><br>

<span style="font-size: 16px;"><b>IV. PRUEBAS</b></span><br><br>

Ruego tener como pruebas los expedientes judiciales correspondientes a los procesos mencionados en los hechos, solicitando se verifique su contenido, en especial las sentencias condenatorias, fechas de ejecutoria y el trámite surtido en cada uno, con el fin de establecer la viabilidad de la acumulación jurídica conforme a lo dispuesto por la ley y la jurisprudencia vigente.<br><br>

<span style="font-size: 16px;"><b>V. COMPETENCIA</b></span><br><br>

Corresponde al juez de ejecución de penas y medidas de seguridad resolver las solicitudes de acumulación jurídica de penas impuestas en distintos procesos, cuando haya conexidad o se hayan dictado separadamente sin causa legal que lo justifique. Por tanto, su despacho es competente para conocer y decidir sobre la presente solicitud.<br><br><br><br>

      

      Por favor compulsar copias de notificaciones a la siguiente dirección electrónica:<br>
      $emailAlternativo<br>
      $emailUsuario<br><br><br>

      Atentamente,<br><br><br>
      <b>$nombrePpl $apellidoPpl</b><br>
      CC: $identificacionPpl<br>
      TD: $td<br>
      NUI: $nui<br><br><br>

      <div style="margin-top: 40px;">
        <img src="https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635" width="160" height="50"/>
      </div>

      <div style="margin-top: 40px;">
        <b>NOTA IMPORTANTE</b><br>
        <p style="font-size: 13px; margin-top: 5px;">
          Este mensaje también será enviado a la Oficina Jurídica del establecimiento <strong>$centroPenitenciario</strong>, con el fin de dejar constancia formal de esta solicitud y facilitar el inicio oportuno de los trámites correspondientes.
        </p>
      </div>
    </body>
  </html>
  """);

    return buffer.toString();
  }
}
