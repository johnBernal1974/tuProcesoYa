import 'package:intl/intl.dart';

class SolicitudReadecuacionRedencionTemplate {
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
  final String numeroSeguimiento;
  final String situacion;
  final String nui;
  final String td;
  final String patio;

  SolicitudReadecuacionRedencionTemplate({
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

    Asunto: <b>Solicitud de Readecuación de Redención – $numeroSeguimiento</b><br>
    Radicado del proceso: <b>$radicado</b><br><br>

    Me amparo en el artículo 85 de la Constitución Política de Colombia y en el artículo 14 de la Ley 1437 de 2011.<br><br>

    E.S.D.<br><br>

    Yo, <b>$nombrePpl $apellidoPpl</b>, identificado con cédula de ciudadanía No. <b>$identificacionPpl</b>, TD: <b>$td</b>, NUI: <b>$nui</b>, actualmente recluido en el establecimiento penitenciario <b>$centroPenitenciario</b>, Patio <b>$patio</b>, presento ante usted la siguiente solicitud:<br><br>

    <span style="font-size: 16px;"><b>I. CONSIDERACIONES</b></span><br><br>

    Inicialmente este sentenciado solicita la aplicación del <b>principio de favorabilidad</b>, conforme al artículo 19, parágrafo segundo de la Ley 2466 del 25 de junio de 2025. 
    Dicha norma modifica la fórmula redentoria del antiguo artículo 82-2 de la Ley 65 de 1993, reconociendo ahora <b>dos (2) días de redención por cada tres (3) días de trabajo</b>, en comparación con el esquema anterior que solo reconocía un día por cada dos de actividad laboral.<br><br>

    Esta nueva disposición representa un beneficio concreto, ya que incrementa proporcionalmente la redención otorgada a quienes realizan actividades productivas certificadas. 
    De acuerdo con el numeral 7 del artículo 38 de la Ley 906 de 2004, es función del Juez de Ejecución de Penas y Medidas de Seguridad aplicar el principio de favorabilidad cuando una norma posterior resulte más beneficiosa al condenado.<br><br>

    <span style="font-size: 16px;"><b>II. FUNDAMENTOS DE DERECHO</b></span><br><br>

    Conforme a lo dispuesto en el artículo 103A de la Ley 1709 de 2014 y en conexidad con el artículo 64, y el numeral 7 del artículo 38 de la Ley 906 de 2004, el suscrito tiene derecho a solicitar la aplicación retroactiva de la Ley 2466 de 2025 por ser más favorable.

    El artículo 19 de dicha ley reconoce la redención de pena por trabajo y otorga dos (2) días de redención por cada tres (3) días de actividad laboral, lo que representa una mejora significativa frente al modelo anterior.<br><br>

    El <b>principio de favorabilidad</b> consagrado en el artículo 29 de la Constitución, en el artículo 6 de la Ley 599 de 2000, así como en tratados internacionales ratificados por Colombia como el Pacto Internacional de Derechos Civiles y Políticos y la Convención Americana sobre Derechos Humanos, exige la aplicación preferente de la norma más benigna, incluso de manera retroactiva.<br><br>

    La Corte Suprema de Justicia ha sostenido que el juez debe aplicar sin excepción la ley posterior más favorable a las personas condenadas, por cuanto su aplicación no depende de teorías abstractas sino del análisis del caso concreto (CSJ, Sala Penal, Rad. 16837, M.P. Jorge Aníbal Gómez Gallego, 3 de septiembre de 2011).<br><br>

    <span style="font-size: 16px;"><b>III. PRETENSIONES</b></span><br><br>

    <b>PRIMERO:</b> Que se dejen sin efecto los autos anteriores de redención de pena por trabajo ya proferidos, y se proceda a <b>readecuar</b> dichos reconocimientos conforme a lo establecido en el artículo 19 de la Ley 2466 de 2025, aplicando el principio de favorabilidad, y reconociendo en consecuencia un mayor número de días redimidos.<br><br>

    <b>SEGUNDO:</b> Que se requiera al establecimiento penitenciario <b>$centroPenitenciario</b> para que remita todos los certificados correspondientes a mis actividades de trabajo desde la fecha de inicio de mi condena.<br><br>

    <b>TERCERO:</b> Que, una vez allegados los certificados, se realice el cómputo de redención conforme a la nueva fórmula legal, es decir, <b>dos (2) días redimidos por cada tres (3) días de trabajo efectivo certificado</b>.<br><br><br>

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
        Este mensaje también será enviado a la Oficina Jurídica del establecimiento <strong>$centroPenitenciario</strong>, con el fin de dejar constancia formal de esta solicitud y facilitar el inicio oportuno de los trámites correspondientes.<br><br>
        
        La presente solicitud ha sido generada mediante la plataforma tecnológica <b>Tu Proceso Ya</b>, diseñada para facilitar el ejercicio autónomo del derecho fundamental de petición por parte de las personas privadas de la libertad o sus familiares.<br><br>

        En virtud del artículo 23 de la Constitución Política de Colombia y de las sentencias T-377 de 2014 y T-114 de 2017 de la Corte Constitucional, <b>no se requiere la firma de abogado ni apoderado para presentar una petición</b>. La plataforma actúa como medio de apoyo y canal de gestión digital, plenamente legítimo y válido.<br><br>

         Exigir firma del apoderado o desconocer al solicitante por el solo hecho de que la petición fue tramitada por medio electrónico, constituye una barrera de acceso a la justicia e infringe el principio de eficacia del derecho fundamental de petición.
      </p>
    </div>
  </body>
</html>
""");

    return buffer.toString();
  }
}
