// Rama `solo-ad`: la interfaz ya está hecha. Tu trabajo es la capa de datos (lib/datos/).
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'datos/repositorio_firestore.dart';
import 'firebase_options.dart';
import 'pantallas/app_solo_ad.dart';

/// Tiempo máximo para conectar antes de mostrar la pantalla de error.
const tiempoMaximoConexion = Duration(seconds: 15);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppPrestamos());
}

// ---------------------------------------------------------------- AD-1
/// Abre la conexión: inicia Firebase, configura la caché local de Firestore
/// e inicia sesión de forma anónima. Si algo falla lanza una excepción con
/// el motivo, que la app muestra en una pantalla de error.
Future<RepositorioFirestore> conectar() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(tiempoMaximoConexion);
  }

  final db = FirebaseFirestore.instance;
  // Caché local: las lecturas se sirven desde el dispositivo si no hay red y
  // las escrituras sin conexión se guardan en una cola local que se envía al
  // servidor cuando vuelve la conexión.
  // (Los ajustes solo se pueden cambiar antes del primer uso de Firestore.)
  try {
    db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (_) {
    // Ya estaban puestos (p. ej. al pulsar «Reintentar»): no pasa nada.
  }

  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    await auth.signInAnonymously().timeout(tiempoMaximoConexion);
  }
  return RepositorioFirestore(db);
}

String motivoError(Object e) => switch (e) {
  TimeoutException _ =>
    'No se ha podido conectar con Firebase en '
        '${tiempoMaximoConexion.inSeconds} s. ¿Hay conexión a Internet?',
  FirebaseAuthException(code: 'network-request-failed') =>
    'Sin conexión a Internet: no se ha podido iniciar sesión.',
  FirebaseAuthException(code: 'operation-not-allowed' || 'admin-restricted-operation') =>
    'El inicio de sesión anónimo no está activado en el proyecto de Firebase '
        '(Authentication → Método de acceso → Anónimo).',
  FirebaseAuthException(:final code, :final message) =>
    'Error de autenticación ($code): $message',
  FirebaseException(:final plugin, :final code, :final message) =>
    'Error de Firebase ($plugin/$code): $message',
  _ => 'No se ha podido iniciar Firebase: $e',
};

class AppPrestamos extends StatefulWidget {
  const AppPrestamos({super.key});

  @override
  State<AppPrestamos> createState() => _AppPrestamosState();
}

class _AppPrestamosState extends State<AppPrestamos> {
  late Future<RepositorioFirestore> _conexion = conectar();

  void _reintentar() => setState(() => _conexion = conectar());

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Préstamos del taller',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: FutureBuilder<RepositorioFirestore>(
        future: _conexion,
        builder: (context, snap) {
          if (snap.hasError) {
            return PantallaError(
              motivo: motivoError(snap.error!),
              onReintentar: _reintentar,
            );
          }
          if (!snap.hasData) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Conectando con Firebase…'),
                  ],
                ),
              ),
            );
          }
          final repo = snap.data!;
          return InicioSoloAd(material: repo, prestamos: repo);
        },
      ),
    );
  }
}

/// Pantalla que se ve cuando no se puede conectar, en vez de una pantalla en blanco.
class PantallaError extends StatelessWidget {
  final String motivo;
  final VoidCallback onReintentar;
  const PantallaError({
    super.key,
    required this.motivo,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Préstamos del taller')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'No se puede conectar',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(motivo, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
