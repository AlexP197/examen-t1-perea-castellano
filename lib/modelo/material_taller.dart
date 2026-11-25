/// Un material del taller que se puede prestar (portátil, kit Arduino, libro…).
///
/// Es el contrato común de los tres módulos: NO cambies los nombres de los campos.
class MaterialTaller {
  final String id;
  final String nombre;
  final String categoria; // 'portatil', 'kit', 'libro', 'herramienta'
  final int unidades; // unidades que tiene el taller
  final int disponibles; // unidades que no están prestadas
  final String ubicacion; // armario o estantería
  final String? isbn; // solo para los libros

  const MaterialTaller({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.unidades,
    required this.disponibles,
    required this.ubicacion,
    this.isbn,
  });

  static const categorias = ['portatil', 'kit', 'libro', 'herramienta'];

  MaterialTaller copyWith({
    String? id,
    String? nombre,
    String? categoria,
    int? unidades,
    int? disponibles,
    String? ubicacion,
    String? isbn,
  }) => MaterialTaller(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    categoria: categoria ?? this.categoria,
    unidades: unidades ?? this.unidades,
    disponibles: disponibles ?? this.disponibles,
    ubicacion: ubicacion ?? this.ubicacion,
    isbn: isbn ?? this.isbn,
  );

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'categoria': categoria,
    'unidades': unidades,
    'disponibles': disponibles,
    'ubicacion': ubicacion,
    if (isbn != null) 'isbn': isbn,
  };

  factory MaterialTaller.fromMap(String id, Map<String, dynamic> m) =>
      MaterialTaller(
        id: id,
        nombre: m['nombre'] as String,
        categoria: m['categoria'] as String,
        unidades: (m['unidades'] as num).toInt(),
        disponibles: (m['disponibles'] as num).toInt(),
        ubicacion: m['ubicacion'] as String,
        isbn: m['isbn'] as String?,
      );

  @override
  String toString() => 'MaterialTaller($id, $nombre, $disponibles/$unidades)';
}
