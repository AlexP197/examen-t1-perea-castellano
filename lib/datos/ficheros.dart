// ============================================================================
//  AD (0486) · Ficheros: importar y exportar (apartado AD-6).
//  Son funciones puras de Dart: se prueban con `flutter test` sin Firebase.
// ============================================================================
import 'dart:convert';

import '../modelo/material_taller.dart';
import '../modelo/prestamo.dart';

/// Error de formato al importar, con la posición del registro que falla.
/// Si el problema es el fichero entero (JSON mal formado o no es una lista),
/// el índice es -1.
class FormatoMaterialException implements Exception {
  final int indice;
  final String motivo;
  FormatoMaterialException(this.indice, this.motivo);
  @override
  String toString() => indice < 0
      ? 'Fichero no válido: $motivo'
      : 'Registro $indice: $motivo';
}

class ImportadorMateriales {
  /// Convierte el JSON de `assets/datos/materiales_iniciales.json` en objetos.
  /// Si un registro está mal, lanza [FormatoMaterialException] con su índice
  /// (empezando en 0). No devuelve nada a medias: o todo el fichero es válido
  /// o se rechaza entero.
  static List<MaterialTaller> desdeJson(String texto) {
    final Object? datos;
    try {
      datos = jsonDecode(texto);
    } on FormatException catch (e) {
      throw FormatoMaterialException(-1, 'JSON mal formado (${e.message})');
    }
    if (datos is! List) {
      throw FormatoMaterialException(-1, 'se esperaba una lista de materiales');
    }

    final resultado = <MaterialTaller>[];
    for (var i = 0; i < datos.length; i++) {
      resultado.add(_material(i, datos[i]));
    }
    return resultado;
  }

  static MaterialTaller _material(int i, Object? registro) {
    if (registro is! Map<String, dynamic>) {
      throw FormatoMaterialException(i, 'no es un objeto JSON');
    }

    String texto(String campo, {bool obligatorio = true}) {
      final v = registro[campo];
      if (v == null && !obligatorio) return '';
      if (v == null) throw FormatoMaterialException(i, 'falta el campo «$campo»');
      if (v is! String || (obligatorio && v.trim().isEmpty)) {
        throw FormatoMaterialException(i, '«$campo» debe ser un texto no vacío');
      }
      return v.trim();
    }

    int entero(String campo) {
      final v = registro[campo];
      if (v == null) throw FormatoMaterialException(i, 'falta el campo «$campo»');
      if (v is! num || v != v.toInt() || v < 0) {
        throw FormatoMaterialException(
          i,
          '«$campo» debe ser un entero mayor o igual que 0 (vale $v)',
        );
      }
      return v.toInt();
    }

    final nombre = texto('nombre');
    final categoria = texto('categoria');
    if (!MaterialTaller.categorias.contains(categoria)) {
      throw FormatoMaterialException(
        i,
        'categoría desconocida «$categoria» '
        '(válidas: ${MaterialTaller.categorias.join(', ')})',
      );
    }
    final unidades = entero('unidades');
    final disponibles = entero('disponibles');
    if (disponibles > unidades) {
      throw FormatoMaterialException(
        i,
        'disponibles ($disponibles) no puede ser mayor que unidades ($unidades)',
      );
    }
    final ubicacion = texto('ubicacion');
    final id = texto('id', obligatorio: false);
    final isbn = texto('isbn', obligatorio: false);

    return MaterialTaller(
      id: id,
      nombre: nombre,
      categoria: categoria,
      unidades: unidades,
      disponibles: disponibles,
      ubicacion: ubicacion,
      isbn: isbn.isEmpty ? null : isbn,
    );
  }
}

class ExportadorPrestamos {
  /// Cabecera del CSV. Además de las columnas pedidas se guarda `materialId`,
  /// porque sin él no se puede reconstruir el préstamo al leer el CSV.
  static const cabecera = [
    'id',
    'materialId',
    'material',
    'alumno',
    'salida',
    'devolucion',
    'dias',
    'incidencias',
  ];
  static const separador = ';';

  /// JSON con la lista de préstamos (formato de `Prestamo.toMap`, más el id).
  static String aJson(List<Prestamo> prestamos) =>
      const JsonEncoder.withIndent('  ').convert([
        for (final p in prestamos) {'id': p.id, ...p.toMap()},
      ]);

  /// Lee el JSON que genera [aJson].
  static List<Prestamo> desdeJson(String texto) => [
    for (final m in (jsonDecode(texto) as List).cast<Map<String, dynamic>>())
      Prestamo.fromMap(m['id'] as String, m),
  ];

  /// CSV con cabecera, separador `;`, fechas en ISO 8601 y comillas cuando un
  /// campo contiene `;`, comillas o saltos de línea. Las incidencias (una lista)
  /// van en una sola columna como lista JSON, p. ej. `["sin cargador"]`.
  static String aCsv(List<Prestamo> prestamos, {DateTime? ahora}) {
    final hoy = ahora ?? DateTime.now();
    final b = StringBuffer()..writeln(cabecera.join(separador));
    for (final p in prestamos) {
      final campos = [
        p.id,
        p.materialId,
        p.nombreMaterial,
        p.alumno,
        p.salida.toIso8601String(),
        p.devolucion?.toIso8601String() ?? '',
        '${p.diasHasta(hoy)}',
        jsonEncode(p.incidencias),
      ];
      b.writeln(campos.map(_escapar).join(separador));
    }
    return b.toString();
  }

  /// Lee el CSV que genera [aCsv]. Lanza [FormatException] si no es válido.
  static List<Prestamo> desdeCsv(String texto) {
    final filas = _filasCsv(texto);
    if (filas.isEmpty) throw const FormatException('CSV vacío');
    if (filas.first.join(separador) != cabecera.join(separador)) {
      throw FormatException('Cabecera inesperada: ${filas.first.join(separador)}');
    }

    final resultado = <Prestamo>[];
    for (var n = 1; n < filas.length; n++) {
      final f = filas[n];
      if (f.length == 1 && f.first.isEmpty) continue; // línea en blanco
      if (f.length != cabecera.length) {
        throw FormatException(
          'Línea ${n + 1}: ${f.length} columnas, se esperaban ${cabecera.length}',
        );
      }
      resultado.add(
        Prestamo(
          id: f[0],
          materialId: f[1],
          nombreMaterial: f[2],
          alumno: f[3],
          salida: DateTime.parse(f[4]),
          devolucion: f[5].isEmpty ? null : DateTime.parse(f[5]),
          // f[6] (días) es un dato calculado: no se lee.
          incidencias: f[7].isEmpty
              ? const []
              : List<String>.from(jsonDecode(f[7]) as List),
        ),
      );
    }
    return resultado;
  }

  static String _escapar(String campo) {
    final necesita =
        campo.contains(separador) ||
        campo.contains('"') ||
        campo.contains('\n') ||
        campo.contains('\r');
    if (!necesita) return campo;
    return '"${campo.replaceAll('"', '""')}"';
  }

  /// Separa el texto en filas y campos respetando las comillas: dentro de un
  /// campo entre comillas, `;` y saltos de línea son texto y `""` es una comilla.
  static List<List<String>> _filasCsv(String texto) {
    final filas = <List<String>>[];
    var fila = <String>[];
    final campo = StringBuffer();
    var entreComillas = false;

    for (var i = 0; i < texto.length; i++) {
      final c = texto[i];
      if (entreComillas) {
        if (c == '"') {
          if (i + 1 < texto.length && texto[i + 1] == '"') {
            campo.write('"');
            i++;
          } else {
            entreComillas = false;
          }
        } else {
          campo.write(c);
        }
      } else if (c == '"') {
        entreComillas = true;
      } else if (c == separador) {
        fila.add(campo.toString());
        campo.clear();
      } else if (c == '\n' || c == '\r') {
        if (c == '\r' && i + 1 < texto.length && texto[i + 1] == '\n') i++;
        fila.add(campo.toString());
        campo.clear();
        filas.add(fila);
        fila = <String>[];
      } else {
        campo.write(c);
      }
    }
    if (entreComillas) throw const FormatException('Comillas sin cerrar');
    if (campo.isNotEmpty || fila.isNotEmpty) {
      fila.add(campo.toString());
      filas.add(fila);
    }
    return filas;
  }
}
