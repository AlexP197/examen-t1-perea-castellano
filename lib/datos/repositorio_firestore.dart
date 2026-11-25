// ============================================================================
//  AD (0486) · Esta clase la implementas tú.
//  Cumple el contrato de `repositorios.dart` usando Cloud Firestore.
//  Colecciones: `material` y `prestamos`. Lee el enunciado: cada método
//  tiene su apartado y sus criterios.
// ============================================================================
import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelo/material_taller.dart';
import '../modelo/prestamo.dart';
import 'repositorios.dart';

class RepositorioFirestore
    implements RepositorioMaterial, RepositorioPrestamos {
  final FirebaseFirestore db;
  RepositorioFirestore(this.db);

  // TODO(AD-2): referencias tipadas con withConverter.
  CollectionReference<MaterialTaller> get materialRef =>
      throw UnimplementedError('AD-2');
  CollectionReference<Prestamo> get prestamosRef =>
      throw UnimplementedError('AD-2');

  @override
  Stream<List<MaterialTaller>> observarMaterial({
    String? categoria,
    bool soloDisponibles = false,
  }) => throw UnimplementedError('AD-3');

  @override
  Future<List<MaterialTaller>> pagina({
    int limite = 10,
    MaterialTaller? despuesDe,
  }) => throw UnimplementedError('AD-3');

  @override
  Future<String> crear(MaterialTaller material) =>
      throw UnimplementedError('AD-2');

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
  Stream<List<Prestamo>> observarPrestamos({bool soloAbiertos = false}) =>
      throw UnimplementedError('AD-3');

  @override
  Future<List<Prestamo>> todos() => throw UnimplementedError('AD-6');
}
