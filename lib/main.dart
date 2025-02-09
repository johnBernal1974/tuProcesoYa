import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuprocesoya/Pages/mis_datos/mis_datos.dart';
import 'package:tuprocesoya/Pages/nosotros/nosotros_page.dart';
import 'package:tuprocesoya/Pages/splash/splash.dart';
import 'package:tuprocesoya/src/colors/colors.dart';
import 'Pages/administrador/editar_registro/editar_registro.dart';
import 'Pages/administrador/home_admin/home_admin.dart';
import 'Pages/alimentar_base_datos_temporal/alimentar_base_datos_temporal.dart';
import 'Pages/derecho_de_peticion/derecho_de_peticion.dart';
import 'Pages/estamos_validando/estamos_validando.dart';
import 'Pages/home/home.dart';
import 'Pages/login/login.dart';
import 'Pages/register/register.dart';
import 'Pages/solicitudes_page/solicitudes_page.dart';
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

  runApp(const MyApp());  // Luego corre la aplicación
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
        'home_admin': (context) => const HomeAdministradorPage(),
        'editar_registro_admin': (context) {
          final doc = ModalRoute.of(context)!.settings.arguments as DocumentSnapshot;
          return EditarRegistroPage(doc: doc);
        },
        'estamos_validando': (context) => EstamosValidandoPage(),

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
