// Rama `solo-ad`: la interfaz ya está hecha. Tu trabajo es la capa de datos (lib/datos/).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'datos/repositorio_firestore.dart';
import 'firebase_options.dart';
import 'pantallas/app_solo_ad.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // AD-1: conexión. Ya está aquí lo mínimo; el apartado AD-1 pide más (lee el enunciado).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.signInAnonymously();
  final repo = RepositorioFirestore(FirebaseFirestore.instance);
  runApp(
    MaterialApp(
      title: 'Préstamos del taller',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: InicioSoloAd(material: repo, prestamos: repo),
    ),
  );
}
