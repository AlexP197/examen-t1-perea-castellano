// AD-7 · Pruebas de RepositorioFirestore con una base de datos falsa
// (fake_cloud_firestore): no hace falta conexión ni proyecto de Firebase.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prestamos_taller/datos/repositorio_firestore.dart';
import 'package:prestamos_taller/datos/repositorios.dart';
import 'package:prestamos_taller/modelo/material_taller.dart';

const libro = MaterialTaller(
  id: 'm-lib-3',
  nombre: 'Designing Data-Intensive Applications',
  categoria: 'libro',
  unidades: 1,
  disponibles: 1,
  ubicacion: 'Biblioteca',
);

void main() {
  late FakeFirebaseFirestore db;
  late RepositorioFirestore repo;

  setUp(() async {
    db = FakeFirebaseFirestore();
    repo = RepositorioFirestore(db);
    await repo.crear(libro);
  });

  test('no se puede prestar sin unidades', () async {
    // Queda 1 unidad: el primer préstamo funciona.
    final id = await repo.prestar(libro.id, 'Ana');
    expect(id, isNotEmpty);
    expect((await repo.materialRef.doc(libro.id).get()).data()!.disponibles, 0);

    // El segundo falla con SinUnidadesException…
    await expectLater(
      repo.prestar(libro.id, 'Luis'),
      throwsA(isA<SinUnidadesException>()),
    );

    // …y no se ha escrito nada: sigue habiendo 1 préstamo y 0 disponibles.
    expect(await repo.todos(), hasLength(1));
    expect((await repo.materialRef.doc(libro.id).get()).data()!.disponibles, 0);
  });

  test('el préstamo se guarda con Timestamp, lista y booleano abierto',
      () async {
    final id = await repo.prestar(libro.id, 'Ana');
    final crudo = (await db.collection('prestamos').doc(id).get()).data()!;
    expect(crudo['abierto'], isTrue);
    expect(crudo['incidencias'], isA<List>());
    expect(crudo['salida'].runtimeType.toString(), contains('Timestamp'));
  });

  test('devolver cierra el préstamo, suma la unidad y no se repite', () async {
    final id = await repo.prestar(libro.id, 'Ana');
    await repo.devolver(id, incidencia: 'falta el marcapáginas');

    final p = (await repo.prestamosRef.doc(id).get()).data()!;
    expect(p.abierto, isFalse);
    expect(p.incidencias, ['falta el marcapáginas']);
    expect((await repo.materialRef.doc(libro.id).get()).data()!.disponibles, 1);

    // Devolverlo otra vez lanza una excepción y no suma nada.
    await expectLater(
      repo.devolver(id),
      throwsA(isA<PrestamoCerradoException>()),
    );
    expect((await repo.materialRef.doc(libro.id).get()).data()!.disponibles, 1);
  });

  test('borrar no borra un material con préstamos abiertos', () async {
    final id = await repo.prestar(libro.id, 'Ana');
    expect(await repo.prestamosAbiertosDe(libro.id), 1);
    await expectLater(
      repo.borrar(libro.id),
      throwsA(isA<MaterialConPrestamosException>()),
    );

    await repo.devolver(id);
    expect(await repo.prestamosAbiertosDe(libro.id), 0);
    await repo.borrar(libro.id);
    expect((await repo.materialRef.doc(libro.id).get()).exists, isFalse);
  });

  test('crear sin id usa add y devuelve el id nuevo', () async {
    final id = await repo.crear(
      const MaterialTaller(
        id: '',
        nombre: 'Osciloscopio',
        categoria: 'herramienta',
        unidades: 1,
        disponibles: 1,
        ubicacion: 'Armario C',
      ),
    );
    expect(id, isNotEmpty);
    expect((await repo.materialRef.doc(id).get()).data()!.nombre, 'Osciloscopio');
  });
}
