import 'package:flutter_test/flutter_test.dart';
import 'package:prestamos_taller/datos/repositorio_memoria.dart';
import 'package:prestamos_taller/datos/repositorios.dart';

void main() {
  test('el repositorio en memoria presta y devuelve', () async {
    final repo = RepositorioMemoria(iniciales: materialDeEjemplo);
    final id = await repo.prestar('m-lib-1', 'Ana');
    await repo.prestar('m-lib-1', 'Luis');
    expect(
      () => repo.prestar('m-lib-1', 'Eva'),
      throwsA(isA<SinUnidadesException>()),
    );
    await repo.devolver(id);
    expect((await repo.todos()).where((p) => p.abierto).length, 1);
  });
}
