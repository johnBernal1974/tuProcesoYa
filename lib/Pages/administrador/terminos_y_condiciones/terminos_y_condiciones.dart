import 'package:flutter/material.dart';
import '../../../commons/main_layaout.dart';

class TerminosCondicionesPage extends StatelessWidget {
  const TerminosCondicionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Términos y Condiciones',
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 14.0, color: Colors.black),
            children: <TextSpan>[
              TextSpan(
                text: 'TÉRMINOS Y CONDICIONES DE USO DE LA PLATAFORMA DE ASISTENCIA JURÍDICA\n\n',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: '1. OBJETO\n',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'Tu Proceso Ya tiene como finalidad facilitar la redacción y gestión de derechos de petición y tutelas para personas privadas de la libertad en calidad de condenados en Colombia. No constituye un servicio de asesoría o representación jurídica, ya que tanto los derechos de petición como las tutelas pueden ser instaurados directamente por cualquier ciudadano sin la necesidad de ser abogado. La plataforma actúa como un medio de apoyo documental para quienes deseen presentar estos recursos.\n\n',
              ),
              TextSpan(
                text: '2. REQUISITOS Y OBLIGACIONES DEL USUARIO\n',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: '2.1. Veracidad de la información: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'El usuario está obligado a proporcionar información completa, exacta y veraz. La falsificación de datos, la omisión de información relevante o el suministro de datos engañosos podrá generar el rechazo de la solicitud y la posibilidad de tomar acciones legales.\n\n',
              ),
              TextSpan(
                text: '2.2. Uso personal e intransferible: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'La cuenta del usuario es personal e intransferible. Cualquier intento de suplantación de identidad, uso de documentos falsos o de terceros sin autorización constituirá una falta grave y podrá dar lugar a la cancelación de los servicios.\n\n',
              ),
              TextSpan(
                text: '2.3. Prohibición de manipulación o entorpecimiento de trámites: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'El usuario no podrá realizar acciones que entorpezcan el normal desarrollo de los procesos o que tengan como finalidad afectar de manera fraudulenta la ejecución de los trámites jurídicos. Cualquier conducta que busque alterar el debido proceso podrá ser reportada a las autoridades competentes.\n\n',
              ),
              TextSpan(
                text: '2.4. Responsabilidad en la gestión documental: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'La carga y envío de documentos debe cumplir con los requisitos legales. La plataforma no se hará responsable por errores en la información suministrada por el usuario ni por consecuencias derivadas de la inexactitud o falsedad de la misma.\n\n',
              ),
              TextSpan(
                text: '3. ALCANCE DEL SERVICIO\n\n',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: '3.1. La plataforma no ofrece asesoría jurídica personalizada ni representación legal en procesos judiciales',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: '. Su función se limita a facilitar la gestión documental para la elaboración y presentación de derechos de petición y tutelas.\n\n',
              ),
              TextSpan(
                text: '3.2. No se garantiza el resultado favorable de las solicitudes tramitadas',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: '. La resolución final de cada petición o tutela depende exclusivamente de las entidades judiciales y penitenciarias competentes. Los tiempos de respuesta pueden variar según la carga administrativa y los procedimientos internos de cada entidad, por lo que la plataforma no es responsable de retrasos o demoras en la resolución de los casos.\n\n',
              ),
              TextSpan(
                text: '3.3. La plataforma se reserva el derecho de rechazar solicitudes que:\n\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: '3.3.1. No cumplan con los requisitos legales o presenten errores en su redacción.\n',
              ),
              TextSpan(
                text: '3.3.2. Contengan información falsa, fraudulenta o contradictoria.\n',
              ),
              TextSpan(
                text: '3.3.3. Estén relacionadas con asuntos ajenos a su alcance o que impliquen asesoría jurídica personalizada.\n\n',
              ),
              TextSpan(
                text: '4. SANCIONES Y CONSECUENCIAS POR INCUMPLIMIENTO\n',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'Cualquier intento de suplantación, falsificación de documentos o información será motivo de cancelación inmediata del acceso a la plataforma y la denegación del servicio. Dependiendo de la gravedad del incumplimiento, la plataforma podrá tomar acciones legales ante las autoridades competentes.\n\n',
              ),
              TextSpan(
                text: '5. LIMITACIÓN DE RESPONSABILIDAD\n\n',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: '5.1. La plataforma no se hace responsable por errores, omisiones o demoras atribuibles a las entidades a las cuales se dirigen las solicitudes.\n',
              ),
              TextSpan(
                text: '5.2.  Los tiempos de respuesta de las solicitudes dependen exclusivamente de las entidades judiciales y penitenciarias, y pueden estar sujetos a retrasos administrativos ajenos a la plataforma.\n',
              ),
              TextSpan(
                text: '5.3.  No garantizamos la disponibilidad ininterrumpida de la plataforma. En caso de fallas tecnológicas, se realizarán los esfuerzos razonables para restablecer el servicio.\n\n',
              ),
              TextSpan(
                text: '6. USO LEGITIMO DE LA PLATAFORMA\n\n',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'Nuestra plataforma no requiere intermediarios. Todos los servicios disponibles en Tu Proceso Ya pueden ser gestionados directamente por los usuarios sin la intervención de terceros. Por lo tanto, le recomendamos abstenerse de realizar pagos a personas que afirmen actuar en nombre de la plataforma o que ofrezcan gestionar trámites a cambio de dinero. Cualquier intento de cobro por servicios no autorizados deberá ser reportado de inmediato.\n\n',
              ),
              TextSpan(
                text: 'AL UTILIZAR ESTA PLATAFORMA, EL USUARIO DECLARA HABER LEÍDO Y ACEPTADO ESTOS TÉRMINOS Y CONDICIONES.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
