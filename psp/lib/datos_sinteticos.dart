// Préstamos sintéticos para medir: no salen de Firebase, se generan con una semilla
// fija, así que todos obtenéis los mismos datos y los mismos resultados.
import 'dart:math';

class PrestamoSintetico {
  final String materialId;
  final String categoria;
  final String alumno;
  final int dias;
  const PrestamoSintetico(
    this.materialId,
    this.categoria,
    this.alumno,
    this.dias,
  );
}

const _categorias = ['portatil', 'kit', 'libro', 'herramienta'];

List<PrestamoSintetico> generarPrestamos(int n, {int semilla = 2026}) {
  final r = Random(semilla);
  return List.generate(n, (_) {
    final c = _categorias[r.nextInt(_categorias.length)];
    return PrestamoSintetico(
      'm-$c-${r.nextInt(40)}',
      c,
      'alumno${r.nextInt(300)}',
      1 + r.nextInt(30),
    );
  });
}

/// Resultado del cálculo: préstamos y media de días por categoría, y los 5 materiales
/// más prestados. Dos resultados son iguales si lo son sus campos.
class Estadisticas {
  final Map<String, int> prestamosPorCategoria;
  final Map<String, double> mediaDiasPorCategoria;
  final List<String> top5Materiales;
  final int huella; // suma de comprobación: debe coincidir entre versiones
  const Estadisticas(
    this.prestamosPorCategoria,
    this.mediaDiasPorCategoria,
    this.top5Materiales,
    this.huella,
  );

  @override
  bool operator ==(Object other) =>
      other is Estadisticas && other.toString() == toString();
  @override
  int get hashCode => toString().hashCode;
  @override
  String toString() {
    final cats = prestamosPorCategoria.keys.toList()..sort();
    final texto = cats
        .map(
          (c) =>
              '$c: ${prestamosPorCategoria[c]} préstamos, '
              '${mediaDiasPorCategoria[c]!.toStringAsFixed(3)} días',
        )
        .join('\n');
    return '$texto\nTop 5: ${top5Materiales.join(', ')}\nHuella: $huella';
  }
}

const _modulo = 1000000007;

/// Huella de un préstamo: un cálculo deliberadamente costoso (simula validar el
/// préstamo contra reglas). Se suma módulo 1e9+7, así que el orden no importa.
int huellaDe(PrestamoSintetico p) {
  var h = p.dias;
  for (var i = 0; i < 400; i++) {
    h =
        (h * 31 +
            p.materialId.codeUnitAt(i % p.materialId.length) +
            p.alumno.length) %
        _modulo;
  }
  return h;
}

/// Versión SECUENCIAL de referencia. Es lenta a propósito con muchos datos:
/// la parte PSP-2 consiste en no bloquear con ella y en repartirla entre isolates.
Estadisticas calcularEstadisticas(List<PrestamoSintetico> prestamos) {
  final cuenta = <String, int>{};
  final dias = <String, int>{};
  final porMaterial = <String, int>{};
  var huella = 0;
  for (final p in prestamos) {
    huella = (huella + huellaDe(p)) % _modulo;
    cuenta[p.categoria] = (cuenta[p.categoria] ?? 0) + 1;
    dias[p.categoria] = (dias[p.categoria] ?? 0) + p.dias;
    porMaterial[p.materialId] = (porMaterial[p.materialId] ?? 0) + 1;
  }
  final medias = {for (final c in cuenta.keys) c: dias[c]! / cuenta[c]!};
  final top = porMaterial.entries.toList()
    ..sort(
      (a, b) => b.value != a.value
          ? b.value.compareTo(a.value)
          : a.key.compareTo(b.key),
    );
  return Estadisticas(
    cuenta,
    medias,
    top.take(5).map((e) => '${e.key} (${e.value})').toList(),
    huella,
  );
}
