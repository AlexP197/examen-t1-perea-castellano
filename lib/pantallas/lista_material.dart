import 'package:flutter/material.dart';

import '../datos/repositorios.dart';
import '../modelo/material_taller.dart';

/// Pantalla que YA existe. En el apartado PMDM-2 la modificas (no la rehagas desde cero).
class ListaMaterial extends StatelessWidget {
  final RepositorioMaterial repo;
  const ListaMaterial({super.key, required this.repo});

  IconData _icono(String categoria) => switch (categoria) {
    'portatil' => Icons.laptop,
    'kit' => Icons.memory,
    'libro' => Icons.menu_book,
    _ => Icons.build,
  };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MaterialTaller>>(
      stream: repo.observarMaterial(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final lista = snap.data!;
        return ListView.builder(
          itemCount: lista.length,
          itemBuilder: (context, i) {
            final m = lista[i];
            return ListTile(
              leading: Icon(_icono(m.categoria)),
              title: Text(m.nombre),
              subtitle: Text(m.ubicacion),
              trailing: Text('${m.disponibles}/${m.unidades}'),
            );
          },
        );
      },
    );
  }
}
