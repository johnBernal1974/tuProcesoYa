import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuprocesoya/Pages/administrador/solicitudes_derechos_peticion/solicitudes_derechos_peticion_admin.dart';
import 'package:tuprocesoya/Pages/client/derecho_de_peticion_solicitud/derecho_de_peticion_solicitud.dart';
import 'package:tuprocesoya/Pages/client/derechos_info/derechos_info.dart';
import 'package:tuprocesoya/Pages/nosotros/nosotros_page.dart';
import 'package:tuprocesoya/Pages/splash/splash.dart';
import 'package:tuprocesoya/src/colors/colors.dart';
import 'Pages/administrador/buzon_sugerencias_administrador/buzon_sugerencias_administrador.dart';
import 'Pages/administrador/editar_registro/editar_registro.dart';
import 'Pages/administrador/home_admin/home_admin.dart';
import 'Pages/administrador/respuesta_sugerencia_admin/respuesta_sugerencia_admin.dart';
import 'Pages/alimentar_base_datos_temporal/alimentar_base_datos_temporal.dart';
import 'Pages/client/buzon_sugerencias/buzon_sugerencias.dart';
import 'Pages/client/derecho_de_peticion/derecho_de_peticion.dart';
import 'Pages/client/estamos_validando/estamos_validando.dart';
import 'Pages/client/home/home.dart';
import 'Pages/client/mis_datos/mis_datos.dart';
import 'Pages/client/register/register.dart';
import 'Pages/client/solicitud_exitosa_derecho_peticion_page/solicitud_exitosa_derecho_peticion_page.dart';
import 'Pages/client/solicitudes_page/solicitudes_page.dart';
import 'Pages/client/tutela/tutela.dart';
import 'Pages/client/tutela_solicitud/tutela_solicitud.dart';
import 'Pages/forgot_password/forgot_password.dart';
import 'Pages/login/login.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Asegura que la inicialización esté completa antes de correr la app
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Usa las opciones generadas en firebase_options.dart
  );

  runApp(const MyApp());

  // Luego corre la aplicación
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tu Proceso Ya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primary, // Color personalizado
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepPurple,
        ).copyWith(
          secondary: Colors.deepPurpleAccent, // Color secundario
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16),

        ),
      ),
      initialRoute: 'splash', // Ruta inicial
      routes: {
        'home': (context) => const HomePage(), // Página principal
        'login': (context) => const LoginPage(),
        'register': (context) => const RegistroPage(),
        'splash': (context) => SplashPage(),
        'cargar_info': (context) => AddDelitoPage(),
        'mis_datos': (context) => const MisDatosPage(),
        'nosotros': (context) => const NosotrosPage(),
        'solicitudes_page': (context) => const SolicitudesdeServicioPage(),
        'derecho_peticion': (context) => const DerechoDePeticionPage(),
        'tutela': (context) => const TutelaPage(),
        'derecho_peticion_solicitud': (context) => const DerechoDePeticionSolicitudPage(),
        'tutela_solicitud': (context) => const TutelaSolicitudPage(),
        'home_admin': (context) => const HomeAdministradorPage(),
        'editar_registro_admin': (context) {
          final doc = ModalRoute.of(context)!.settings.arguments as DocumentSnapshot;
          return EditarRegistroPage(doc: doc);
        },
        'estamos_validando': (context) => EstamosValidandoPage(),
        'derechos_info': (context) => const DerechosInfoPage(),
        'buzon_sugerencias': (context) => const BuzonSugerenciasPage(),
        'forgot_password': (context) => const ForgotPasswordPage(),
        'buzon_sugerencias_administrador': (context) => const BuzonSugerenciasAdministradorPage(),
        'solicitud_exitosa_derecho_peticion': (context) => SolicitudExitosaDerechoPeticionPage(),
        'solicitudes_derecho_peticion_admin': (context) => const SolicitudesDerechoPeticionAdminPage(),

      },
      onGenerateRoute: (settings) {
        if (settings.name == 'respuesta_sugerencia_page_admin') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => RespuestaSugerenciaPage(
              userId: args['userId'],
              nombre: args['nombre'],
              sugerencia: args['sugerencia'],
              celular: args['celular'],
            ),
          );
        }
        return null; // Manejar otras rutas si es necesario
      },

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English, no country code
        Locale('es', ''), // Spanish, no country code
      ],
    );
  }
}
