import 'package:intl/intl.dart';

class SolicitudDesistimientoApelacionTemplate {
  final String dirigido; // puede venir vacío, el template lo sustituirá
  final String entidad;
  final String referencia;
  final String nombrePpl;
  final String apellidoPpl;
  final String identificacionPpl;
  final String centroPenitenciario;
  final String emailUsuario;
  final String emailAlternativo;
  final String radicado;
  final String numeroSeguimiento;
  final String situacion;
  final String nui;
  final String td;
  final String patio;

  final DateTime? fechaApelacion;
  final int? diasTranscurridos;
  final String motivoAdicional;

  SolicitudDesistimientoApelacionTemplate({
    this.dirigido = "",
    required this.entidad,
    required this.referencia,
    required this.nombrePpl,
    required this.apellidoPpl,
    required this.identificacionPpl,
    required this.centroPenitenciario,
    required this.emailUsuario,
    this.emailAlternativo = "peticiones@tuprocesoya.com",
    required this.radicado,
    required this.numeroSeguimiento,
    required this.situacion,
    required this.nui,
    required this.td,
    required this.patio,
    this.fechaApelacion,
    this.diasTranscurridos,
    this.motivoAdicional = "",
  });

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    try {
      return DateFormat("dd 'de' MMMM 'de' yyyy", 'es').format(d);
    } catch (_) {
      return DateFormat("dd/MM/yyyy").format(d!);
    }
  }

  String generarTextoHtml() {
    // Si el parámetro dirigido viene vacío, usamos este texto por defecto.
    final dirigidoFinal = dirigido.trim().isEmpty ? 'Respetados Magistrados:' : dirigido.trim();

    // calcular días si hace falta
    final computedDias = diasTranscurridos ??
        (fechaApelacion != null ? DateTime.now().difference(fechaApelacion!).inDays : null);
    final radicadoTxt = radicado.trim().isEmpty ? 'No disponible' : radicado.trim();
    final fechaApelacionTxt = fechaApelacion != null ? _formatDate(fechaApelacion) : '';

    final buffer = StringBuffer();

    buffer.writeln('''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Desistimiento de apelación</title>
  <style>
    body { font-family: Arial, Helvetica, sans-serif; color:#222; font-size:13px; line-height:1.5; margin:0; padding:0; }
    .container { max-width:900px; margin:0 auto; padding:16px; }
    .small { font-size:12px; color:#444; }
    h1 { font-size:16px; margin-bottom:6px; }
    h2 { font-size:14px; margin-top:18px; margin-bottom:6px; }
    p { margin:6px 0; }
    .meta { margin-bottom:12px; }
    .firma { margin-top:18px; }
    .nota { font-size:11px; color:#666; margin-top:22px; border-top:1px solid #eee; padding-top:8px; }
    .bold { font-weight:700; }
    .tabla-datos { background:#f7f7f7; padding:8px; border-radius:6px; margin:10px 0; }
    .dirigido { margin-bottom:4px; font-weight:400; color:#444; font-size:13px; }
    .entidad { margin-bottom:10px; font-size:18px; font-weight:800; color:#000; }
    .meta p { margin:4px 0; }
    .firma p { margin:0; } /* firma compacta sin saltos extra */
  </style>
</head>
<body>
  <div class="container">

    <!-- Encabezado: dirigido + entidad -->
    <p class="dirigido">${dirigidoFinal}</p>
    <p class="entidad">${entidad}</p>

    <div class="meta">
      <p><b>Asunto:</b> Desistimiento de apelación – <span class="bold">${numeroSeguimiento}</span></p>
      <p><b>Radicado / No. de proceso:</b> <span class="bold">${radicadoTxt}</span></p>
      ${fechaApelacionTxt.isNotEmpty ? '<p><b>Fecha de apelación:</b> <span class="bold">' + fechaApelacionTxt + '</span></p>' : ''}
    </div>

    <p><b>E.S.D.</b></p>

    <p>
      Yo, <b>${nombrePpl} ${apellidoPpl}</b>, identificado(a) con cédula de ciudadanía No. <b>${identificacionPpl}</b>,
      TD: <b>${td}</b>, NUI: <b>${nui}</b>, actualmente recluido(a) en el establecimiento penitenciario
      <b>${centroPenitenciario}</b>, Patio <b>${patio}</b>, en pleno uso de mis facultades y en ejercicio del derecho de defensa,
      me permito manifestar al despacho lo siguiente:
    </p>

    <h2>I. PETICIÓN PRINCIPAL</h2>
    <p>
      Solicito se tenga por presentado el desistimiento del recurso de apelación interpuesto en el proceso identificado con el radicado <b>${radicadoTxt}</b>,
      se ordene el retiro de la impugnación practicada y se proceda a continuar con la ejecución de la decisión de fondo conforme al ordenamiento jurídico aplicable.
    </p>

    <p>
      Así mismo, solicito se me notifique la providencia que resuelva sobre este desistimiento, con el fin de tener plena certeza procesal
      de la decisión adoptada por ese Honorable Tribunal.
    </p>

    <h2>II. EXPOSICIÓN DE MOTIVOS</h2>
    <p>
      Manifiesto que la presente decisión es libre, consciente y no producto de coacción. 
      Los motivos que justifican el desistimiento son de carácter personal y procesal; 
      entre ellos pueden mencionarse la valoración de riesgos y beneficios de proseguir 
      con la impugnación, la existencia de acuerdos o la voluntad explícita del recurrente 
      de no continuar con la instancia recursal.
    </p>
    ${motivoAdicional.isNotEmpty ? '<p><b>Motivo(s) adicional(es):</b><br>' + motivoAdicional + '</p>' : ''}

    <p>
      Declaro expresamente que esta decisión de desistir del recurso de apelación 
      la realizo de manera <b>libre, consciente y sin coacción alguna</b>, 
      comprendiendo plenamente sus efectos jurídicos y procesales.
    </p>

    <h2>III. FUNDAMENTOS DE DERECHO</h2>
    <p>
      La presente solicitud se fundamenta en las normas procesales aplicables al desistimiento de recursos, la autonomía del recurrente y los principios
      constitucionales de debido proceso y derecho de defensa.
    </p>
    <p>
      De conformidad con lo dispuesto en el <b>artículo 314 del Código General del Proceso</b>, aplicable por remisión en materia penal y procesal, 
      el recurso interpuesto es susceptible de desistimiento expreso por parte del recurrente. Asimismo, conforme al <b>artículo 183 del Código de Procedimiento Penal</b>,
      el desistimiento de la impugnación debe ser aceptado por el despacho y produce el efecto de dejar en firme la providencia impugnada.
    </p>
    <p>
      En tal sentido, solicito se profiera el correspondiente auto en el que se acepte el desistimiento, se archive la actuación relacionada con la apelación 
      y se deje constancia en el expediente.
    </p>

    <h2>IV. PETICIONES SUBSIDIARIAS Y DE CELERIDAD</h2>
    <p>
      En subsidio, solicito que, en caso de necesitar formalidades adicionales para que surta efectos el desistimiento, ese despacho indique las diligencias
      pendientes y el plazo estimado para su resolución. Dada la naturaleza ejecutiva del asunto y la cercanía al cumplimiento de la pena (de existir días
      pendientes), ruego se tramite con prioridad para evitar dilaciones injustificadas.
    </p>

    <h2>V. NOTIFICACIONES</h2>
    <p>
      Solicito se compulsen copias y se remitan notificaciones a las siguientes direcciones electrónicas para fines de trazabilidad:
      <br><b>${emailAlternativo}</b>
      <br><b>${emailUsuario}</b>
    </p>

    <div class="firma">
      <p>Atentamente,</p>
      <p><b>${nombrePpl} ${apellidoPpl}</b></p>
      <p>CC: ${identificacionPpl}</p>
      <p>TD: ${td} &nbsp; | &nbsp; NUI: ${nui}</p>
    </div>

    <div class="nota">
      <p class="small">
        NOTA: Esta solicitud ha sido generada mediante la plataforma <b>Tu Proceso Ya</b>. En virtud del derecho de petición (art. 23 C.P.)
        y demás normas aplicables, solicito se surta trámite y se deje constancia de su recepción. Si se requiere, adjunto poder o documento que acredite
        la representación o la voluntad del desistimiento.
      </p>
    </div>

    <div style="margin-top: 40px;">
      <img src="https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635" width="160" height="50"/>
    </div>

  </div>
</body>
</html>
''');

    return buffer.toString();
  }
}
