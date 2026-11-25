import 'dart:async';

import '../modelo/material_taller.dart';
import '../modelo/prestamo.dart';
import 'repositorios.dart';

/// Implementación en memoria del contrato. Ya funciona: sirve para que la interfaz
/// se pueda desarrollar y probar sin Firebase. Los datos se pierden al cerrar la app.
class RepositorioMemoria implements RepositorioMaterial, RepositorioPrestamos {
  final Map<String, MaterialTaller> _material = {};
  final Map<String, Prestamo> _prestamos = {};
  final _cambios = StreamController<void>.broadcast();
  int _siguiente = 1;

  RepositorioMemoria({List<MaterialTaller> iniciales = const []}) {
    for (final m in iniciales) {
      _material[m.id] = m;
    }
  }

  String _nuevoId(String prefijo) => '$prefijo${_siguiente++}';
  void _avisar() => _cambios.add(null);

  Stream<T> _vivo<T>(T Function() leer) async* {
    yield leer();
    await for (final _ in _cambios.stream) {
      yield leer();
    }
  }

  List<MaterialTaller> _filtrar(String? categoria, bool soloDisponibles) {
    final lista =
        _material.values
            .where((m) => categoria == null || m.categoria == categoria)
            .where((m) => !soloDisponibles || m.disponibles > 0)
            .toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));
    return lista;
  }

  @override
  Stream<List<MaterialTaller>> observarMaterial({
    String? categoria,
    bool soloDisponibles = false,
  }) => _vivo(() => _filtrar(categoria, soloDisponibles));

  @override
  Future<List<MaterialTaller>> pagina({
    int limite = 10,
    MaterialTaller? despuesDe,
  }) async {
    final todos = _filtrar(null, false);
    final inicio = despuesDe == null
        ? 0
        : todos.indexWhere((m) => m.id == despuesDe.id) + 1;
    return todos.skip(inicio).take(limite).toList();
  }

  @override
  Future<String> crear(MaterialTaller material) async {
    final id = material.id.isEmpty ? _nuevoId('m') : material.id;
    _material[id] = material.copyWith(id: id);
    _avisar();
    return id;
  }

  @override
  Future<void> actualizar(MaterialTaller material) async {
    _material[material.id] = material;
    _avisar();
  }

  @override
  Future<void> borrar(String id) async {
    _material.remove(id);
    _avisar();
  }

  @override
  Future<String> prestar(String materialId, String alumno) async {
    final m = _material[materialId];
    if (m == null || m.disponibles <= 0) throw SinUnidadesException(materialId);
    _material[materialId] = m.copyWith(disponibles: m.disponibles - 1);
    final id = _nuevoId('p');
    _prestamos[id] = Prestamo(
      id: id,
      materialId: materialId,
      nombreMaterial: m.nombre,
      alumno: alumno,
      salida: DateTime.now(),
    );
    _avisar();
    return id;
  }

  @override
  Future<void> devolver(String prestamoId, {String? incidencia}) async {
    final p = _prestamos[prestamoId];
    if (p == null || !p.abierto) return;
    _prestamos[prestamoId] = Prestamo(
      id: p.id,
      materialId: p.materialId,
      nombreMaterial: p.nombreMaterial,
      alumno: p.alumno,
      salida: p.salida,
      devolucion: DateTime.now(),
      incidencias: [
        ...p.incidencias,
        if (incidencia != null && incidencia.isNotEmpty) incidencia,
      ],
    );
    final m = _material[p.materialId];
    if (m != null) _material[m.id] = m.copyWith(disponibles: m.disponibles + 1);
    _avisar();
  }

  List<Prestamo> _ordenados(bool soloAbiertos) =>
      _prestamos.values.where((p) => !soloAbiertos || p.abierto).toList()
        ..sort((a, b) => b.salida.compareTo(a.salida));

  @override
  Stream<List<Prestamo>> observarPrestamos({bool soloAbiertos = false}) =>
      _vivo(() => _ordenados(soloAbiertos));

  @override
  Future<List<Prestamo>> todos() async => _ordenados(false);
}

/// Datos de ejemplo para arrancar sin Firebase.
const materialDeEjemplo = [
  MaterialTaller(
    id: 'm-port-1',
    nombre: 'Portátil Lenovo ThinkPad',
    categoria: 'portatil',
    unidades: 6,
    disponibles: 6,
    ubicacion: 'Armario A',
  ),
  MaterialTaller(
    id: 'm-kit-1',
    nombre: 'Kit Arduino Uno',
    categoria: 'kit',
    unidades: 10,
    disponibles: 10,
    ubicacion: 'Estantería 2',
  ),
  MaterialTaller(
    id: 'm-lib-1',
    nombre: 'Flutter in Action',
    categoria: 'libro',
    unidades: 2,
    disponibles: 2,
    ubicacion: 'Biblioteca',
    isbn: '9781617296147',
  ),
  MaterialTaller(
    id: 'm-her-1',
    nombre: 'Polímetro digital',
    categoria: 'herramienta',
    unidades: 4,
    disponibles: 4,
    ubicacion: 'Armario B',
  ),
];
