// ============================================================================
//  AD (0486) · Implementación del contrato de `repositorios.dart` con
//  Cloud Firestore. Colecciones: `material` y `prestamos`.
//
//  AD-2  materialRef / prestamosRef con withConverter, Timestamp, crear.
//  AD-3  observarMaterial, observarPrestamos, pagina, prestamosAbiertosDe.
//  AD-4  actualizar (update) y borrar (con comprobación).
//  AD-5  prestar y devolver en transacciones.
//  AD-6  todos (para exportar).
// ============================================================================
import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelo/material_taller.dart';
import '../modelo/prestamo.dart';
import 'repositorios.dart';

/// Se lanza al intentar borrar un material que todavía tiene préstamos abiertos.
class MaterialConPrestamosException implements Exception {
  final String materialId;
  final int abiertos;
  MaterialConPrestamosException(this.materialId, this.abiertos);
  @override
  String toString() =>
      'No se puede borrar el material $materialId: tiene $abiertos '
      'préstamo(s) abierto(s). Devuélvelos antes de borrarlo.';
}

/// Se lanza al devolver un préstamo que ya estaba cerrado (o que no existe).
class PrestamoCerradoException implements Exception {
  final String prestamoId;
  final String motivo;
  PrestamoCerradoException(this.prestamoId, this.motivo);
  @override
  String toString() => 'No se puede devolver el préstamo $prestamoId: $motivo';
}

class RepositorioFirestore
    implements RepositorioMaterial, RepositorioPrestamos {
  final FirebaseFirestore db;
  RepositorioFirestore(this.db);

  // ------------------------------------------------------------------ AD-2
  /// Colección `material` tipada: Firestore convierte cada documento a
  /// [MaterialTaller] al leer y a Map al escribir. El id es el del documento.
  CollectionReference<MaterialTaller> get materialRef => db
      .collection('material')
      .withConverter<MaterialTaller>(
        fromFirestore: (snap, _) => MaterialTaller.fromMap(snap.id, snap.data()!),
        toFirestore: (m, _) => m.toMap(),
      );

  /// Colección `prestamos` tipada. Aquí NO se usa `Prestamo.toMap` (que guarda
  /// las fechas como texto): las fechas van como [Timestamp], las incidencias
  /// como lista y se añade el booleano `abierto` para poder filtrar por él.
  CollectionReference<Prestamo> get prestamosRef => db
      .collection('prestamos')
      .withConverter<Prestamo>(
        fromFirestore: (snap, _) => prestamoDesdeFirestore(snap.id, snap.data()!),
        toFirestore: (p, _) => prestamoAFirestore(p),
      );

  static Map<String, Object?> prestamoAFirestore(Prestamo p) => {
    'materialId': p.materialId,
    'nombreMaterial': p.nombreMaterial,
    'alumno': p.alumno,
    'salida': Timestamp.fromDate(p.salida),
    'devolucion': p.devolucion == null
        ? null
        : Timestamp.fromDate(p.devolucion!),
    'incidencias': p.incidencias,
    'abierto': p.abierto,
  };

  static Prestamo prestamoDesdeFirestore(String id, Map<String, dynamic> m) =>
      Prestamo(
        id: id,
        materialId: m['materialId'] as String,
        nombreMaterial: m['nombreMaterial'] as String,
        alumno: m['alumno'] as String,
        salida: _fecha(m['salida'])!,
        devolucion: _fecha(m['devolucion']),
        incidencias: List<String>.from(m['incidencias'] as List? ?? const []),
      );

  static DateTime? _fecha(Object? valor) => switch (valor) {
    Timestamp t => t.toDate(),
    DateTime d => d,
    String s => DateTime.parse(s), // por si hay datos antiguos guardados como texto
    _ => null,
  };

  /// Con id: `set` en ese documento (se conserva el id, p. ej. al importar).
  /// Sin id: `add` y Firestore genera uno nuevo, que se devuelve.
  @override
  Future<String> crear(MaterialTaller material) async {
    if (material.id.isNotEmpty) {
      await materialRef.doc(material.id).set(material);
      return material.id;
    }
    final ref = await materialRef.add(material);
    return ref.id;
  }

  // ------------------------------------------------------------------ AD-3
  /// Filtro por categoría (igualdad) y por disponibles > 0 (desigualdad),
  /// ordenado por nombre y en tiempo real con `snapshots()`.
  /// Necesita los índices compuestos de `firestore.indexes.json`.
  @override
  Stream<List<MaterialTaller>> observarMaterial({
    String? categoria,
    bool soloDisponibles = false,
  }) {
    Query<MaterialTaller> q = materialRef;
    if (categoria != null) q = q.where('categoria', isEqualTo: categoria);
    if (soloDisponibles) q = q.where('disponibles', isGreaterThan: 0);
    q = q.orderBy('nombre');
    return q.snapshots().map((s) => [for (final d in s.docs) d.data()]);
  }

  /// Solo abiertos si se pide, del más reciente al más antiguo.
  @override
  Stream<List<Prestamo>> observarPrestamos({bool soloAbiertos = false}) {
    Query<Prestamo> q = prestamosRef;
    if (soloAbiertos) q = q.where('abierto', isEqualTo: true);
    q = q.orderBy('salida', descending: true);
    return q.snapshots().map((s) => [for (final d in s.docs) d.data()]);
  }

  /// Paginación con cursor: orderBy + startAfter + limit.
  /// Se ordena también por el id del documento para desempatar dos materiales
  /// con el mismo nombre; así el cursor es único y no se repite ninguno.
  @override
  Future<List<MaterialTaller>> pagina({
    int limite = 10,
    MaterialTaller? despuesDe,
  }) async {
    Query<MaterialTaller> q = materialRef
        .orderBy('nombre')
        .orderBy(FieldPath.documentId);
    if (despuesDe != null) {
      q = q.startAfter([despuesDe.nombre, despuesDe.id]);
    }
    final snap = await q.limit(limite).get();
    return [for (final d in snap.docs) d.data()];
  }

  /// Cuántos préstamos abiertos tiene un material, con una consulta de
  /// agregación `count()`: el servidor cuenta y NO se descargan los documentos.
  Future<int> prestamosAbiertosDe(String materialId) async {
    final agregado = await prestamosRef
        .where('materialId', isEqualTo: materialId)
        .where('abierto', isEqualTo: true)
        .count()
        .get();
    return agregado.count ?? 0;
  }

  @override
  Future<void> actualizar(MaterialTaller material) =>
      throw UnimplementedError('AD-4');

  @override
  Future<void> borrar(String id) => throw UnimplementedError('AD-4');

  @override
  Future<String> prestar(String materialId, String alumno) =>
      throw UnimplementedError('AD-5');

  @override
  Future<void> devolver(String prestamoId, {String? incidencia}) =>
      throw UnimplementedError('AD-5');

  @override
  Future<List<Prestamo>> todos() => throw UnimplementedError('AD-6');
}
