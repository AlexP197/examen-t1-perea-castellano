import 'package:flutter/material.dart';

import 'datos/repositorio_memoria.dart';
import 'pantallas/lista_material.dart';

// Cuando la capa de datos de AD funcione, se cambia a Firestore aquí (apartado AD-1).
final repo = RepositorioMemoria(iniciales: materialDeEjemplo);

void main() {
  runApp(const PrestamosTallerApp());
}

class PrestamosTallerApp extends StatelessWidget {
  const PrestamosTallerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Préstamos del taller',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('Material del taller')),
        body: ListaMaterial(repo: repo),
      ),
    );
  }
}
