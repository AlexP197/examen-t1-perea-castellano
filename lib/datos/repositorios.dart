import '../modelo/material_taller.dart';
import '../modelo/prestamo.dart';

/// El contrato de la capa de datos. La interfaz (PMDM) solo habla con estas dos clases
/// abstractas; la implementación con Firestore (AD) está en `repositorio_firestore.dart`
/// y la de memoria, que ya funciona, en `repositorio_memoria.dart`.
abstract class RepositorioMaterial {
  /// Material en tiempo real, filtrado por categoría (null = todas) y, si se pide,
  /// solo el que tiene unidades disponibles. Ordenado por nombre.
  Stream<List<MaterialTaller>> observarMaterial({
    String? categoria,
    bool soloDisponibles = false,
  });

  /// Página de [limite] materiales ordenados por nombre, empezando después de [despuesDe].
  Future<List<MaterialTaller>> pagina({
    int limite = 10,
    MaterialTaller? despuesDe,
  });

  Future<String> crear(MaterialTaller material);
  Future<void> actualizar(MaterialTaller material);
  Future<void> borrar(String id);
}

abstract class RepositorioPrestamos {
  /// Presta una unidad del material. Debe fallar con [SinUnidadesException]
  /// si no quedan disponibles. Devuelve el id del préstamo.
  Future<String> prestar(String materialId, String alumno);

  /// Cierra el préstamo y devuelve la unidad al material.
  Future<void> devolver(String prestamoId, {String? incidencia});

  /// Préstamos en tiempo real, los más recientes primero.
  Stream<List<Prestamo>> observarPrestamos({bool soloAbiertos = false});

  /// Todos los préstamos (para exportar).
  Future<List<Prestamo>> todos();
}

class SinUnidadesException implements Exception {
  final String materialId;
  SinUnidadesException(this.materialId);
  @override
  String toString() => 'No quedan unidades disponibles de $materialId';
}
