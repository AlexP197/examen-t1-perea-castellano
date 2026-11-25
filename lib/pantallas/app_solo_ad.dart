// ============================================================================
//  Rama `solo-ad`: interfaz COMPLETA, ya hecha. No hace falta tocarla.
//  Funciona en cuanto la capa de datos (repositorio_firestore.dart y
//  ficheros.dart) cumpla el contrato de repositorios.dart.
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../datos/ficheros.dart';
import '../datos/repositorios.dart';
import '../modelo/material_taller.dart';
import '../modelo/prestamo.dart';

class InicioSoloAd extends StatefulWidget {
  final RepositorioMaterial material;
  final RepositorioPrestamos prestamos;
  const InicioSoloAd({
    super.key,
    required this.material,
    required this.prestamos,
  });

  @override
  State<InicioSoloAd> createState() => _InicioSoloAdState();
}

class _InicioSoloAdState extends State<InicioSoloAd> {
  int _pestana = 0;

  @override
  Widget build(BuildContext context) {
    final paginas = [
      PantallaMaterial(material: widget.material, prestamos: widget.prestamos),
      PantallaPrestamos(prestamos: widget.prestamos),
      PantallaCatalogo(material: widget.material),
      PantallaFicheros(material: widget.material, prestamos: widget.prestamos),
    ];
    const titulos = ['Material', 'Préstamos', 'Catálogo paginado', 'Ficheros'];
    return Scaffold(
      appBar: AppBar(title: Text(titulos[_pestana])),
      body: paginas[_pestana],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pestana,
        onDestinationSelected: (i) => setState(() => _pestana = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2),
            label: 'Material',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz),
            label: 'Préstamos',
          ),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Catálogo'),
          NavigationDestination(icon: Icon(Icons.file_copy), label: 'Ficheros'),
        ],
      ),
    );
  }
}

void avisar(BuildContext context, String texto) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

Future<String?> pedirTexto(
  BuildContext context,
  String titulo,
  String etiqueta,
) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: TextField(
        controller: c,
        autofocus: true,
        decoration: InputDecoration(labelText: etiqueta),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, c.text.trim()),
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------- Material
class PantallaMaterial extends StatefulWidget {
  final RepositorioMaterial material;
  final RepositorioPrestamos prestamos;
  const PantallaMaterial({
    super.key,
    required this.material,
    required this.prestamos,
  });

  @override
  State<PantallaMaterial> createState() => _PantallaMaterialState();
}

class _PantallaMaterialState extends State<PantallaMaterial> {
  String? _categoria;
  bool _soloDisponibles = false;

  Future<void> _prestar(MaterialTaller m) async {
    final alumno = await pedirTexto(context, 'Prestar «${m.nombre}»', 'Alumno');
    if (alumno == null || alumno.isEmpty || !mounted) return;
    try {
      await widget.prestamos.prestar(m.id, alumno);
      if (mounted) avisar(context, 'Prestado a $alumno');
    } on SinUnidadesException {
      if (mounted) avisar(context, 'No quedan unidades de ${m.nombre}');
    } catch (e) {
      if (mounted) avisar(context, 'Error: $e');
    }
  }

  Future<void> _borrar(MaterialTaller m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar material'),
        content: Text('¿Borrar «${m.nombre}»?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.material.borrar(m.id);
    } catch (e) {
      if (mounted) avisar(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FormularioMaterial(repo: widget.material),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                DropdownButton<String?>(
                  value: _categoria,
                  hint: const Text('Todas'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    for (final c in MaterialTaller.categorias)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) => setState(() => _categoria = v),
                ),
                const Spacer(),
                const Text('Solo disponibles'),
                Switch(
                  value: _soloDisponibles,
                  onChanged: (v) => setState(() => _soloDisponibles = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MaterialTaller>>(
              stream: widget.material.observarMaterial(
                categoria: _categoria,
                soloDisponibles: _soloDisponibles,
              ),
              builder: (context, snap) {
                if (snap.hasError)
                  return Center(child: Text('Error: ${snap.error}'));
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());
                final lista = snap.data!;
                if (lista.isEmpty)
                  return const Center(child: Text('Sin material'));
                return ListView(
                  children: [
                    for (final m in lista)
                      ListTile(
                        title: Text(m.nombre),
                        subtitle: Text('${m.categoria} · ${m.ubicacion}'),
                        leading: CircleAvatar(child: Text('${m.disponibles}')),
                        trailing: PopupMenuButton<String>(
                          onSelected: (op) => switch (op) {
                            'prestar' => _prestar(m),
                            'editar' => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FormularioMaterial(
                                  repo: widget.material,
                                  inicial: m,
                                ),
                              ),
                            ),
                            _ => _borrar(m),
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'prestar',
                              child: Text('Prestar'),
                            ),
                            PopupMenuItem(
                              value: 'editar',
                              child: Text('Editar'),
                            ),
                            PopupMenuItem(
                              value: 'borrar',
                              child: Text('Borrar'),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FormularioMaterial extends StatefulWidget {
  final RepositorioMaterial repo;
  final MaterialTaller? inicial;
  const FormularioMaterial({super.key, required this.repo, this.inicial});

  @override
  State<FormularioMaterial> createState() => _FormularioMaterialState();
}

class _FormularioMaterialState extends State<FormularioMaterial> {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.inicial?.nombre);
  late final _unidades = TextEditingController(
    text: '${widget.inicial?.unidades ?? 1}',
  );
  late final _ubicacion = TextEditingController(
    text: widget.inicial?.ubicacion,
  );
  late String _categoria = widget.inicial?.categoria ?? 'kit';

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    final unidades = int.parse(_unidades.text);
    final previo = widget.inicial;
    final prestadas = previo == null ? 0 : previo.unidades - previo.disponibles;
    final m = MaterialTaller(
      id: previo?.id ?? '',
      nombre: _nombre.text.trim(),
      categoria: _categoria,
      unidades: unidades,
      disponibles: unidades - prestadas,
      ubicacion: _ubicacion.text.trim(),
      isbn: previo?.isbn,
    );
    try {
      previo == null
          ? await widget.repo.crear(m)
          : await widget.repo.actualizar(m);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) avisar(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final prestadas = widget.inicial == null
        ? 0
        : widget.inicial!.unidades - widget.inicial!.disponibles;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.inicial == null ? 'Nuevo material' : 'Editar material',
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Mínimo 3 caracteres'
                  : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: [
                for (final c in MaterialTaller.categorias)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _categoria = v!),
            ),
            TextFormField(
              controller: _unidades,
              decoration: const InputDecoration(labelText: 'Unidades'),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1) return 'Número entero mayor que 0';
                if (n < prestadas) return 'Hay $prestadas prestadas';
                return null;
              },
            ),
            TextFormField(
              controller: _ubicacion,
              decoration: const InputDecoration(labelText: 'Ubicación'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obligatoria' : null,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _guardar, child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Préstamos
class PantallaPrestamos extends StatefulWidget {
  final RepositorioPrestamos prestamos;
  const PantallaPrestamos({super.key, required this.prestamos});

  @override
  State<PantallaPrestamos> createState() => _PantallaPrestamosState();
}

class _PantallaPrestamosState extends State<PantallaPrestamos> {
  bool _soloAbiertos = true;

  Future<void> _devolver(Prestamo p) async {
    final incidencia = await pedirTexto(
      context,
      'Devolver «${p.nombreMaterial}»',
      'Incidencia (opcional)',
    );
    if (incidencia == null) return;
    try {
      await widget.prestamos.devolver(p.id, incidencia: incidencia);
      if (mounted) avisar(context, 'Devuelto');
    } catch (e) {
      if (mounted) avisar(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Solo préstamos abiertos'),
          value: _soloAbiertos,
          onChanged: (v) => setState(() => _soloAbiertos = v),
        ),
        Expanded(
          child: StreamBuilder<List<Prestamo>>(
            stream: widget.prestamos.observarPrestamos(
              soloAbiertos: _soloAbiertos,
            ),
            builder: (context, snap) {
              if (snap.hasError)
                return Center(child: Text('Error: ${snap.error}'));
              if (!snap.hasData)
                return const Center(child: CircularProgressIndicator());
              final lista = snap.data!;
              if (lista.isEmpty)
                return const Center(child: Text('Sin préstamos'));
              return ListView(
                children: [
                  for (final p in lista)
                    ListTile(
                      title: Text('${p.nombreMaterial} → ${p.alumno}'),
                      subtitle: Text(
                        'Salida ${p.salida.toLocal().toString().substring(0, 16)}'
                        '${p.abierto ? '' : ' · devuelto'}'
                        '${p.incidencias.isEmpty ? '' : ' · ${p.incidencias.join(', ')}'}',
                      ),
                      trailing: p.abierto
                          ? TextButton(
                              onPressed: () => _devolver(p),
                              child: const Text('Devolver'),
                            )
                          : const Icon(Icons.check),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Catálogo paginado
class PantallaCatalogo extends StatefulWidget {
  final RepositorioMaterial material;
  const PantallaCatalogo({super.key, required this.material});

  @override
  State<PantallaCatalogo> createState() => _PantallaCatalogoState();
}

class _PantallaCatalogoState extends State<PantallaCatalogo> {
  final _items = <MaterialTaller>[];
  bool _fin = false;
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (_cargando || _fin) return;
    setState(() => _cargando = true);
    try {
      final pagina = await widget.material.pagina(
        limite: 5,
        despuesDe: _items.isEmpty ? null : _items.last,
      );
      setState(() {
        _items.addAll(pagina);
        _fin = pagina.length < 5;
      });
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Center(child: Text('Error: $_error'));
    return ListView(
      children: [
        for (final m in _items)
          ListTile(title: Text(m.nombre), subtitle: Text(m.categoria)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: _fin
              ? const Center(child: Text('No hay más'))
              : OutlinedButton(
                  onPressed: _cargando ? null : _cargar,
                  child: const Text('Cargar 5 más'),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Ficheros
class PantallaFicheros extends StatefulWidget {
  final RepositorioMaterial material;
  final RepositorioPrestamos prestamos;
  const PantallaFicheros({
    super.key,
    required this.material,
    required this.prestamos,
  });

  @override
  State<PantallaFicheros> createState() => _PantallaFicherosState();
}

class _PantallaFicherosState extends State<PantallaFicheros> {
  String _salida = '';

  Future<void> _importar(String asset) async {
    try {
      final texto = await rootBundle.loadString(asset);
      final lista = ImportadorMateriales.desdeJson(texto);
      for (final m in lista) {
        await widget.material.crear(m);
      }
      setState(
        () => _salida = 'Importados ${lista.length} materiales de $asset',
      );
    } on FormatoMaterialException catch (e) {
      setState(() => _salida = 'Fichero rechazado: $e');
    } catch (e) {
      setState(() => _salida = 'Error: $e');
    }
  }

  Future<void> _exportar(bool csv) async {
    try {
      final todos = await widget.prestamos.todos();
      final texto = csv
          ? ExportadorPrestamos.aCsv(todos)
          : ExportadorPrestamos.aJson(todos);
      await Clipboard.setData(ClipboardData(text: texto));
      setState(() => _salida = texto);
      if (mounted) avisar(context, 'Copiado al portapapeles');
    } catch (e) {
      setState(() => _salida = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: () =>
                  _importar('assets/datos/materiales_iniciales.json'),
              child: const Text('Importar materiales_iniciales.json'),
            ),
            OutlinedButton(
              onPressed: () =>
                  _importar('assets/datos/materiales_con_errores.json'),
              child: const Text('Importar materiales_con_errores.json'),
            ),
            FilledButton.tonal(
              onPressed: () => _exportar(false),
              child: const Text('Exportar préstamos a JSON'),
            ),
            FilledButton.tonal(
              onPressed: () => _exportar(true),
              child: const Text('Exportar préstamos a CSV'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SelectableText(
          _salida,
          style: const TextStyle(fontFamily: 'monospace'),
        ),
      ],
    );
  }
}
