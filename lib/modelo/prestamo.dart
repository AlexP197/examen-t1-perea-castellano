/// Un préstamo de un material a un alumno.
///
/// Es el contrato común de los tres módulos: NO cambies los nombres de los campos.
class Prestamo {
  final String id;
  final String materialId;
  final String nombreMaterial; // copia del nombre, para listar sin otra lectura
  final String alumno;
  final DateTime salida;
  final DateTime? devolucion; // null mientras el préstamo está abierto
  final List<String> incidencias; // «pantalla rayada», «falta el cargador»…

  const Prestamo({
    required this.id,
    required this.materialId,
    required this.nombreMaterial,
    required this.alumno,
    required this.salida,
    this.devolucion,
    this.incidencias = const [],
  });

  bool get abierto => devolucion == null;

  /// Días que duró el préstamo (o que lleva, si sigue abierto).
  int diasHasta(DateTime ahora) =>
      (devolucion ?? ahora).difference(salida).inDays;

  Map<String, dynamic> toMap() => {
    'materialId': materialId,
    'nombreMaterial': nombreMaterial,
    'alumno': alumno,
    'salida': salida.toIso8601String(),
    'devolucion': devolucion?.toIso8601String(),
    'incidencias': incidencias,
  };

  factory Prestamo.fromMap(String id, Map<String, dynamic> m) => Prestamo(
    id: id,
    materialId: m['materialId'] as String,
    nombreMaterial: m['nombreMaterial'] as String,
    alumno: m['alumno'] as String,
    salida: DateTime.parse(m['salida'] as String),
    devolucion: m['devolucion'] == null
        ? null
        : DateTime.parse(m['devolucion'] as String),
    incidencias: List<String>.from(m['incidencias'] as List? ?? const []),
  );
}
