import 'package:intl/intl.dart';

class SolicitudAsignacionJEPTemplate {
  final String dirigido;
  final String entidad; // Juzgado de conocimiento destinatario
  final String referencia;
  final String nombrePpl;
  final String apellidoPpl;
  final String identificacionPpl;
  final String centroPenitenciario;
  final String emailUsuario;
  final String emailAlternativo;
  final String radicado; // Radicado del proceso de conocimiento
  final String jdc;      // Juzgado de conocimiento
  final String numeroSeguimiento;
  final String situacion;
  final String nui;
  final String td;
  final String patio;

  SolicitudAsignacionJEPTemplate({
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
    required this.numeroSeguimiento,
    required this.situacion,
    required this.nui,
    required this.td,
    required this.patio,
  });

  String generarTextoHtml() {
    final buffer = StringBuffer();

    buffer.writeln("""
<html>
  <body style="font-family: Arial, sans-serif;">
    <b>$dirigido</b><br>
    <b>$entidad</b><br><br>

    Asunto: <b>Solicitud de asignación de Juzgado de Ejecución de Penas – $numeroSeguimiento</b><br>
    Radicado del proceso: <b>$radicado</b><br><br>
    

    Me amparo en el artículo 85 de la Constitución Política de Colombia y en el artículo 14 de la Ley 1437 de 2011.<br><br>

    E.S.D.<br><br>

    Yo, <b>$nombrePpl $apellidoPpl</b>, identificado con cédula de ciudadanía No. <b>$identificacionPpl</b>, TD: <b>$td</b>, NUI: <b>$nui</b>, actualmente recluido en el establecimiento penitenciario <b>$centroPenitenciario</b>, Patio <b>$patio</b>, presento ante usted la siguiente solicitud:<br><br>

    <span style="font-size: 16px;"><b>I. CONSIDERACIONES</b></span><br><br>

Con ocasión de la sentencia condenatoria proferida dentro del proceso identificado con el radicado <b>$radicado</b>, y encontrándome actualmente en <b>$situacion</b>, resulta indispensable que se <b>asigne formalmente</b> un Juzgado de Ejecución de Penas y Medidas de Seguridad (JEP), conforme lo exige la normativa vigente, para el control y vigilancia del cumplimiento de la pena.  
<br><br>
Hasta la fecha, no se ha informado ni notificado despacho de ejecución competente. Esta omisión <b>impide el inicio de la etapa de ejecución</b> y retrasa actuaciones esenciales como la práctica de cómputos de pena, certificaciones de redenciones, valoración de conducta, así como la tramitación de beneficios administrativos o judiciales.  
<br><br>
La falta de asignación del JEP <b>afecta directamente mi derecho fundamental de acceso a la administración de justicia</b>, el principio de celeridad procesal y el cumplimiento efectivo de la condena, en tanto el juzgado de conocimiento tiene la obligación legal de remitir la actuación al juez de ejecución inmediatamente después de la ejecutoria de la sentencia.
<br><br>


    <span style="font-size: 16px;"><b>II. FUNDAMENTOS DE DERECHO</b></span><br><br>

• <b>Artículo 471 de la Ley 906 de 2004</b>: dispone que, ejecutoriada la sentencia, el juez que la profirió remitirá al Juez de Ejecución de Penas y Medidas de Seguridad competente copia de la misma y de los documentos que sirvieron de base para el juicio, a fin de que se dé inicio a la ejecución.  
<br>
• <b>Artículo 38, numeral 7, de la Ley 906 de 2004</b>: atribuye al Juez de Ejecución de Penas y Medidas de Seguridad la competencia para vigilar la ejecución de la pena y resolver lo relativo a redenciones, cómputos y beneficios, función que requiere la previa remisión del expediente por el juzgado de conocimiento.  
<br>
• <b>Artículo 64 de la Ley 65 de 1993</b> (Código Penitenciario y Carcelario): señala que el control judicial del cumplimiento de la pena corresponde al juez de ejecución, pero previa remisión del proceso por parte del juzgado que dictó la condena.  
<br>
• <b>Artículos 23 y 229 de la Constitución Política</b>: consagran los derechos fundamentales de petición y de acceso a la administración de justicia, los cuales resultan afectados cuando no se asigna oportunamente el juez competente para la etapa de ejecución.  
<br>
• <b>Artículos 13 y 209 de la Constitución Política</b>: establecen el deber de las autoridades de garantizar igualdad y eficacia en el trámite de las solicitudes, así como el principio de celeridad en la función pública.  
<br>
• <b>Corte Suprema de Justicia, Sala de Casación Penal, Rad. 39436 del 25 de septiembre de 2013</b>: reitera que es deber del juzgado de conocimiento remitir oportunamente la actuación al juez de ejecución para garantizar el derecho de defensa y el acceso a beneficios penitenciarios.  
<br>
• <b>Corte Constitucional, Sentencia T-782 de 2004</b>: determina que la falta de remisión del expediente al JEP constituye una vulneración del derecho de acceso a la administración de justicia y del debido proceso.  
<br><br>


    <span style="font-size: 16px;"><b>III. PRETENSIONES</b></span><br><br>

<b>PRIMERO:</b> Que ese despacho, como Juzgado de Conocimiento, disponga de manera inmediata lo pertinente para la <b>asignación formal</b> del Juzgado de Ejecución de Penas y Medidas de Seguridad competente en el proceso con radicado <b>$radicado</b>, y remita el expediente completo con sus anexos.  
<br><br>
<b>SEGUNDO:</b> Que, una vez asignado, se informe por este mismo medio el nombre completo, ciudad, datos de contacto y número de radicación de ejecución, y se confirme la recepción del expediente por parte del JEP.  
<br><br>
<b>TERCERO:</b> Que se notifique tanto al establecimiento penitenciario <b>$centroPenitenciario</b> como al suscrito interno de la decisión adoptada, dejando constancia en el expediente.  
<br><br>
<b>CUARTO:</b> Que, en caso de que ya exista un JEP asignado, se suministre de manera clara y completa la información de dicho despacho, incluyendo dirección física, correo electrónico y número de radicado de ejecución, con copia al establecimiento penitenciario.  
<br><br>


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

    <div style="margin-top: 40px; color: #444; font-size: 12px;">
      <b style="color: black;">NOTA IMPORTANTE</b><br>
      <p style="margin-top: 5px;">
        Este mensaje también será enviado a la Oficina Jurídica del establecimiento <strong>$centroPenitenciario</strong>, con el fin de dejar constancia formal de esta solicitud y facilitar el inicio oportuno de los trámites correspondientes.<br><br>

        La presente solicitud ha sido generada mediante la plataforma tecnológica <b>Tu Proceso Ya</b>, diseñada para facilitar el ejercicio autónomo del derecho fundamental de petición por parte de las personas privadas de la libertad o sus familiares.<br><br>

        En virtud del artículo 23 de la Constitución Política de Colombia y de las sentencias T-377 de 2014 y T-114 de 2017 de la Corte Constitucional, <b>no se requiere la firma de abogado ni apoderado para presentar una petición</b>. La plataforma actúa como medio de apoyo y canal de gestión digital, plenamente legítimo y válido. Exigir firma del apoderado o desconocer al solicitante por el solo hecho de que la petición fue tramitada por medio electrónico, constituye una barrera de acceso a la justicia e infringe el principio de eficacia del derecho fundamental de petición.
      </p>
    </div>

  </body>
</html>
""");

    return buffer.toString();
  }
}
