import 'package:intl/intl.dart';

import 'package:intl/intl.dart';

class ImpulsoProcesalTemplate {
  final String dirigido;                 // Ej: "Señor(a) Juez" | "Señor(a) Director(a)" | "Señores Oficina de Reparto"
  final String entidad;                  // Ej: "JUZGADO EPMS - Bogotá" (se mostrará lo que va después de "-")
  final String servicio;                 // Subcategoría/servicio, ej: "Redención de pena"
  final String numeroSeguimiento;        // Ref/TY: 123456
  final DateTime? fechaEnvioInicial;     // Para decir que ya pasó el término desde el envío inicial
  final int? diasPlazo;                  // 10/15/20/30 (opcional, embellece el texto)

  // Datos PPL
  final String nombrePpl;
  final String apellidoPpl;
  final String identificacionPpl;
  final String centroPenitenciario;
  final String nui;
  final String td;
  final String patio;

  final String emailAlternativo;

  // Branding
  final String logoUrl;

  // Comportamiento
  final bool mostrarEntidadSoloDespuesDeGuion;

  // ⬇️ NUEVO: HTML del correo anterior a incrustar
  final String? htmlAnterior;

  ImpulsoProcesalTemplate({
    required this.dirigido,
    required this.entidad,
    required this.servicio,
    required this.numeroSeguimiento,
    required this.nombrePpl,
    required this.apellidoPpl,
    required this.identificacionPpl,
    required this.centroPenitenciario,
    required this.nui,
    required this.td,
    required this.patio,
    this.emailAlternativo = "peticiones@tuprocesoya.com",
    this.fechaEnvioInicial,
    this.diasPlazo,
    this.logoUrl = "https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635",
    this.mostrarEntidadSoloDespuesDeGuion = true,
    this.htmlAnterior, // ⬅️ NUEVO
  });

  String _fmtFecha(DateTime d) =>
      DateFormat("d 'de' MMMM 'de' y, h:mm a", 'es').format(d);

  String _entidadVisible(String raw) {
    if (!mostrarEntidadSoloDespuesDeGuion) return raw.trim();
    final i = raw.indexOf('-');
    return i >= 0 ? raw.substring(i + 1).trim() : raw.trim();
  }

  String generarHtml() {
    final entidadMostrar = _entidadVisible(entidad);

    final fechaEnvioTxt = (fechaEnvioInicial != null) ? _fmtFecha(fechaEnvioInicial!) : null;

    final plazoTxt = (diasPlazo != null && diasPlazo! > 0)
        ? "$diasPlazo días"
        : "el término legal";

    // Pie legal
    final pieLegal = """
<div style="margin-top: 24px; color: #444; font-size: 12px;">
  <b style="color: black;">NOTA IMPORTANTE</b><br>
  <p style="margin-top: 5px;">
    La presente solicitud ha sido generada mediante la plataforma tecnológica <b>Tu Proceso Ya</b>...
    <b>no se requiere la firma de abogado ni apoderado para presentar una petición</b>...
  </p>
</div>
""";

    // ⬇️ NUEVO: bloque con el correo anterior completo (si existe)
    final bloqueCorreoAnterior = (htmlAnterior != null && htmlAnterior!.trim().isNotEmpty)
        ? """
<hr style="margin:24px 0;border:0;border-top:1px solid #ddd;">
<p style="font-size:13px;color:#555;margin:0 0 8px 0;"><b>Correo enviado inicialmente:</b></p>
<div style="border-left:3px solid #ccc;padding-left:12px;margin-top:8px;">
  ${htmlAnterior!}
</div>
"""
        : "";

    return """
<!DOCTYPE html>
<html lang="es">
<meta charset="UTF-8">
<body style="margin:0;padding:0;background:#fff;">
<div style="max-width:800px;margin:auto;padding:18px;font-family:Arial,Helvetica,sans-serif;font-size:14px;line-height:1.6;color:#111">

  <!-- Encabezado destinatario -->
  <p style="margin:0 0 1px 0"><b>$dirigido</b></p>
  <p style="margin:0 0 10px 0"><b>${entidadMostrar.isEmpty ? 'Autoridad competente' : entidadMostrar}</b></p>

  <!-- Asunto y referencia -->
  <p style="margin:8px 0 0 0; font-size:16px; line-height:1.3;">
    <span style="font-weight:900;">Asunto:</span>
    <span style="font-weight:900;"> Impulso procesal – $servicio - $numeroSeguimiento</span>
  </p><br><br>

  <!-- Cuerpo -->
  <p style="margin:0 0 12px 0">E.S.D,</p>

  yo, <b>$nombrePpl $apellidoPpl</b>, identificado con el número de cédula <b>$identificacionPpl</b>, actualmente recluido en <b>$centroPenitenciario</b>, con el NUI : <b>$nui</b> y TD : <b>$td</b>, ubicado en el Patio No: <b>$patio</b>.<br><br>

  <p style="margin:0 0 12px 0">
    Me permito solicitar, muy respetuosamente, se <b>impulse el trámite</b> de la solicitud remitida con anterioridad, a fin de que se profiera decisión de fondo o, en su defecto, se informe
    el estado actual de la actuación y las gestiones realizadas hasta la fecha.
  </p>

  ${ (fechaEnvioTxt != null) ? """
  <p style="margin:0 0 12px 0">
    Consta que la petición inicial fue enviada el <b>$fechaEnvioTxt</b> y ha transcurrido <b>$plazoTxt</b> sin que se haya obtenido respuesta de fondo.
  </p>
  """ : "" }

  <p style="margin:0 0 12px 0">
    En virtud de los principios de <b>celeridad</b> y <b>eficacia</b> que rigen la función administrativa y el <b>derecho fundamental de petición</b>
    (art. 23 C.P. y Ley 1755 de 2015), solicito se adopten de manera prioritaria las medidas necesarias para garantizar una respuesta oportuna.
    De no ser posible decidir de inmediato, agradezco se indique de forma clara el estado del trámite, las actuaciones pendientes y el plazo estimado para su resolución.
  </p>

  <p style="margin:0 0 16px 0">
    Por favor <b>compulsar copias</b> o remitir notificaciones a los siguientes correos, para fines de trazabilidad:
    <br><b>$emailAlternativo</b><br>
  </p>

  <p style="margin:0 0 20px 0">Atentamente,</p><br><br>

  <b>$nombrePpl $apellidoPpl</b><br>
  CC: $identificacionPpl<br>
  TD: $td<br>
  NUI: $nui<br>
  PATIO: $patio<br><br><br>

  <!-- ⬇️ Inserción del correo anterior -->
  $bloqueCorreoAnterior

  <!-- Logo -->
  <div style="margin:20px 0">
    <img src="$logoUrl" alt="Tu Proceso Ya" style="height:40px;display:inline-block"/>
  </div>

  $pieLegal
</div>
</body>
</html>
""";
  }
}

