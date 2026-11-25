// ============================================================================
//  AD (0486) · Ficheros: importar y exportar. Lo implementas tú (apartado AD-6).
//  Son funciones puras de Dart: se prueban con `flutter test` sin Firebase.
// ============================================================================
import '../modelo/material_taller.dart';
import '../modelo/prestamo.dart';

/// Error de formato al importar, con la posición del registro que falla.
class FormatoMaterialException implements Exception {
  final int indice;
  final String motivo;
  FormatoMaterialException(this.indice, this.motivo);
  @override
  String toString() => 'Registro $indice: $motivo';
}

class ImportadorMateriales {
  /// Convierte el JSON de `assets/datos/materiales_iniciales.json` en objetos.
  /// Si un registro está mal, lanza [FormatoMaterialException] con su índice.
  static List<MaterialTaller> desdeJson(String texto) =>
      throw UnimplementedError('AD-6');
}

class ExportadorPrestamos {
  /// JSON con la lista de préstamos (formato de `Prestamo.toMap`, más el id).
  static String aJson(List<Prestamo> prestamos) =>
      throw UnimplementedError('AD-6');

  /// CSV con cabecera: id;material;alumno;salida;devolucion;dias;incidencias
  static String aCsv(List<Prestamo> prestamos, {DateTime? ahora}) =>
      throw UnimplementedError('AD-6');
}
