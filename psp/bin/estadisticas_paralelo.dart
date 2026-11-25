// PSP-2 · Isolates. Lee el enunciado.
// Ejecuta: dart run bin/estadisticas_paralelo.dart 1000000 4
import 'package:psp_taller/datos_sinteticos.dart';

void main(List<String> args) {
  final n = args.isNotEmpty ? int.parse(args[0]) : 1000000;
  final datos = generarPrestamos(n);
  final reloj = Stopwatch()..start();
  final secuencial = calcularEstadisticas(datos);
  print('Secuencial: ${reloj.elapsedMilliseconds} ms\n$secuencial');
  // TODO(PSP-2): versión con K isolates y comparación con la secuencial.
}
