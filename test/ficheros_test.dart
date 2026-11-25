// AD-6 · Pruebas de importar y exportar ficheros.
// Leen los ficheros de assets/datos/ con File y escriben el CSV en un fichero
// temporal (Directory.systemTemp) para volver a leerlo.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prestamos_taller/datos/ficheros.dart';
import 'package:prestamos_taller/modelo/prestamo.dart';

/// Compara dos préstamos campo a campo (Prestamo no define ==).
void expectMismoPrestamo(Prestamo a, Prestamo b) {
  expect(a.id, equals(b.id));
  expect(a.materialId, equals(b.materialId));
  expect(a.nombreMaterial, equals(b.nombreMaterial));
  expect(a.alumno, equals(b.alumno));
  expect(a.salida, equals(b.salida));
  expect(a.devolucion, equals(b.devolucion));
  expect(a.incidencias, equals(b.incidencias));
}

Matcher formatoEnIndice(int indice) => isA<FormatoMaterialException>()
    .having((e) => e.indice, 'indice', indice);

void main() {
  group('ImportadorMateriales.desdeJson', () {
    test('convierte materiales_iniciales.json', () {
      final texto = File(
        'assets/datos/materiales_iniciales.json',
      ).readAsStringSync();
      final lista = ImportadorMateriales.desdeJson(texto);
      expect(lista, hasLength(12));
      expect(lista.first.id, 'm-port-1');
      expect(lista.first.nombre, 'Portátil Lenovo ThinkPad');
      expect(lista.first.unidades, 6);
      final libro = lista.firstWhere((m) => m.id == 'm-lib-1');
      expect(libro.isbn, '9781617296147');
      expect(lista.firstWhere((m) => m.id == 'm-kit-1').isbn, isNull);
    });

    test('rechaza materiales_con_errores.json en el registro 1', () {
      final texto = File(
        'assets/datos/materiales_con_errores.json',
      ).readAsStringSync();
      expect(
        () => ImportadorMateriales.desdeJson(texto),
        throwsA(formatoEnIndice(1)), // categoría «proyector»
      );
    });

    test('detecta disponibles > unidades', () {
      const texto =
          '[{"id":"a","nombre":"Ratón","categoria":"herramienta",'
          '"unidades":5,"disponibles":7,"ubicacion":"Cajón"}]';
      expect(
        () => ImportadorMateriales.desdeJson(texto),
        throwsA(formatoEnIndice(0)),
      );
    });

    test('detecta campos que faltan', () {
      const texto =
          '[{"id":"ok","nombre":"Cable","categoria":"kit","unidades":1,'
          '"disponibles":1,"ubicacion":"A"},'
          '{"id":"x","categoria":"kit","unidades":2,"disponibles":2,'
          '"ubicacion":"B"}]';
      expect(
        () => ImportadorMateriales.desdeJson(texto),
        throwsA(formatoEnIndice(1)),
      );
    });

    test('detecta JSON mal formado', () {
      expect(
        () => ImportadorMateriales.desdeJson('[{"id": "a", '),
        throwsA(formatoEnIndice(-1)),
      );
    });
  });

  group('ExportadorPrestamos', () {
    final prestamos = [
      Prestamo(
        id: 'p1',
        materialId: 'm-kit-1',
        nombreMaterial: 'Kit Arduino Uno',
        alumno: 'Ana',
        salida: DateTime(2026, 11, 2, 9, 30),
        devolucion: DateTime(2026, 11, 9, 12, 0),
        incidencias: ['falta un cable; y el LED', 'caja "rota"'],
      ),
      Prestamo(
        id: 'p2',
        materialId: 'm-port-1',
        nombreMaterial: 'Portátil Lenovo ThinkPad',
        alumno: 'Luis Pérez',
        salida: DateTime(2026, 11, 20, 8, 15),
      ),
    ];

    test('aCsv: cabecera, separador ;, fechas ISO 8601 y comillas', () {
      final csv = ExportadorPrestamos.aCsv(
        prestamos,
        ahora: DateTime(2026, 11, 26),
      );
      final lineas = csv.trim().split('\n');
      expect(
        lineas.first,
        'id;materialId;material;alumno;salida;devolucion;dias;incidencias',
      );
      expect(lineas, hasLength(3));
      expect(lineas[1], contains('2026-11-02T09:30:00.000'));
      expect(lineas[1], contains(';7;')); // días del préstamo cerrado
      expect(lineas[2], contains(';5;')); // días que lleva el abierto
      // La incidencia con ; y comillas va entre comillas y con "" dobladas.
      expect(lineas[1], contains(';"[""falta un cable; y el LED"",'));
    });

    test('ida y vuelta por un fichero CSV temporal da los mismos préstamos',
        () {
      final dir = Directory.systemTemp.createTempSync('prestamos_');
      try {
        final fichero = File('${dir.path}/prestamos.csv');
        fichero.writeAsStringSync(ExportadorPrestamos.aCsv(prestamos));
        final leidos = ExportadorPrestamos.desdeCsv(
          fichero.readAsStringSync(),
        );
        expect(leidos, hasLength(prestamos.length));
        for (var i = 0; i < prestamos.length; i++) {
          expectMismoPrestamo(leidos[i], prestamos[i]);
        }
        expect(leidos.first.incidencias.first, contains(';'));
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('aJson y desdeJson también dan los mismos préstamos', () {
      final leidos = ExportadorPrestamos.desdeJson(
        ExportadorPrestamos.aJson(prestamos),
      );
      for (var i = 0; i < prestamos.length; i++) {
        expectMismoPrestamo(leidos[i], prestamos[i]);
      }
    });

    test('desdeCsv rechaza una cabecera incorrecta', () {
      expect(
        () => ExportadorPrestamos.desdeCsv('a;b;c\n1;2;3\n'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
