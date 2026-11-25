import 'package:psp_taller/datos_sinteticos.dart';
import 'package:test/test.dart';

void main() {
  test('los datos sintéticos son siempre los mismos', () {
    expect(
      calcularEstadisticas(generarPrestamos(1000)),
      calcularEstadisticas(generarPrestamos(1000)),
    );
  });
}
