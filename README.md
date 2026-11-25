# Préstamos del taller · Examen T1 de 2.º DAM (PMDM · AD · PSP)

Proyecto base del examen del jueves 26/11/2026. **El enunciado es el PDF de la tarea «Examen T1»
del Aula Virtual**; este README solo explica qué hay aquí.

## Ramas

| Rama | Para quién | Qué trae |
|---|---|---|
| `main` | Quien se examina de PMDM, de PSP o de varios módulos | Modelos, contrato de datos, repositorio en memoria, una pantalla para modificar y el paquete `psp/` |
| `solo-ad` | Quien se examina **solo de AD** | Lo mismo, más **toda la interfaz hecha**: solo falta la capa de datos |

## Estructura

```
lib/modelo/            Contrato común: MaterialTaller y Prestamo (no cambies los campos)
lib/datos/             repositorios.dart (contrato), repositorio_memoria.dart (ya funciona),
                       repositorio_firestore.dart y ficheros.dart (AD los implementa)
lib/pantallas/         Interfaz (PMDM)
assets/datos/          JSON para importar (AD-6)
psp/                   Paquete Dart puro de PSP: procesos, isolates y sockets
firestore.rules        Reglas mínimas (usuario autenticado)
```

## Arrancar

```bash
flutter pub get
flutter run -d chrome           # la app arranca con el repositorio en memoria
cd psp && dart pub get && dart test
```

Firebase: `flutterfire configure` con **tu** proyecto (sustituye `lib/firebase_options.dart`).

## Commits

Un commit por apartado como mínimo, con el prefijo del módulo: `[PMDM-3] ...`, `[AD-5] ...`,
`[PSP-2] ...`. Se corrige el último commit anterior a las 11:15.

---

# Entrega · Acceso a Datos (AD) · rama `solo-ad`

- **URL publicada:** https://PON-AQUI-TU-PROYECTO.web.app
- **Proyecto de Firebase:** `PON-AQUI-EL-ID`
- **Apartados hechos:** AD-1, AD-2, AD-3, AD-4, AD-5, AD-6 y AD-7.

## Cómo se ejecuta

```bash
flutter pub get
flutter test                    # pruebas de ficheros y de Firestore (con fake_cloud_firestore)
flutter run -d chrome           # la app usa RepositorioFirestore
flutter build web
firebase deploy --only hosting,firestore   # publica la web, las reglas y los índices
```

Ficheros de la capa de datos: `lib/main.dart` (conexión), `lib/datos/repositorio_firestore.dart`
(Firestore) y `lib/datos/ficheros.dart` (importar/exportar). Pruebas en `test/`.

## AD-1 · Conexión y escrituras sin conexión

`main.dart` abre la conexión en `conectar()`: `Firebase.initializeApp`, la caché local de Firestore
con `Settings(persistenceEnabled: true)` y el inicio de sesión anónimo. Mientras tanto se ve
«Conectando…»; si algo falla (Firebase no arranca, no hay red, el inicio anónimo no está activado o se
superan 15 s) se muestra una pantalla de error con el motivo y un botón «Reintentar», en vez de una
pantalla en blanco.

**Qué pasa con las escrituras hechas sin conexión:** con la persistencia activada, Firestore guarda la
escritura en la caché local del dispositivo y la app la ve al instante (los `snapshots()` la muestran con
`hasPendingWrites`). Las escrituras quedan en una cola y se envían solas al servidor, en orden, cuando
vuelve la conexión, aunque se haya cerrado la app entre medias (en web, mientras no se borren los datos
del navegador). Si al llegar al servidor las reglas la rechazan, el cambio local se deshace. Las
**transacciones** (prestar y devolver) son la excepción: necesitan leer del servidor, así que sin conexión
fallan en lugar de quedar en cola.

## AD-2 · Persistencia

- `materialRef` y `prestamosRef` son referencias tipadas con `withConverter`.
- En `prestamos` las fechas `salida` y `devolucion` se guardan como `Timestamp`, `incidencias` como
  lista y se añade el booleano `abierto` (no está en el modelo: se calcula con `devolucion == null`) para
  poder consultar por él.
- `crear`: con id hace `set` en ese documento (al importar se conservan los ids del JSON); sin id hace
  `add` y devuelve el id nuevo.

## AD-3 · Consultas e índices

| Consulta | Índice compuesto (`firestore.indexes.json`) |
|---|---|
| material por categoría, ordenado por nombre | `categoria ↑, nombre ↑` |
| material con disponibles > 0, ordenado por nombre | `nombre ↑, disponibles ↑` |
| material por categoría y disponibles > 0, por nombre | `categoria ↑, nombre ↑, disponibles ↑` |
| préstamos abiertos, más recientes primero | `abierto ↑, salida ↓` |
| préstamos abiertos de un material (`count()`) | `materialId ↑, abierto ↑` |

`pagina` usa `orderBy('nombre')` + `orderBy(documentId)` + `startAfter([nombre, id])` + `limit`: el id
desempata dos materiales con el mismo nombre y así ninguno se repite entre páginas.
`prestamosAbiertosDe(materialId)` cuenta con `count()`, que devuelve solo el número sin descargar los
documentos.

## AD-4 · Modificar y borrar

`actualizar` usa `update` con los campos del material (no reemplaza el documento entero). `borrar`
llama antes a `prestamosAbiertosDe` y, si hay alguno, lanza `MaterialConPrestamosException` con un
mensaje que dice cuántos préstamos abiertos tiene.

## AD-5 · Transacciones

`prestar` lee el material dentro de una transacción; si no quedan unidades no escribe nada y lanza
`SinUnidadesException`; si quedan, descuenta una y crea el préstamo en la misma transacción.
`devolver` lee el préstamo en una transacción: si ya está cerrado lanza `PrestamoCerradoException` y
no suma nada; si está abierto lo cierra (`devolucion`, `abierto: false`, incidencia con `arrayUnion`) y
suma la unidad con `FieldValue.increment(1)`.

**Qué pasaría sin transacción si dos personas prestan la última unidad a la vez:** las dos leerían
`disponibles = 1`, las dos verían que queda una, las dos escribirían `disponibles = 0` y las dos crearían
su préstamo. Resultado: dos préstamos abiertos de un material que solo tiene una unidad, y el contador
dice 0 cuando en realidad se ha prestado una unidad que no existe. Con la transacción, Firestore detecta que el material ha cambiado
desde que se leyó y repite la transacción de la segunda persona con el dato nuevo (0), así que esa
lanza `SinUnidadesException`. Además, si algo falla a mitad, no se queda la unidad descontada sin
préstamo (todo o nada).

## AD-6 · Ficheros

- `ImportadorMateriales.desdeJson` valida cada registro y lanza `FormatoMaterialException` con su
  índice (desde 0): categoría desconocida, `disponibles > unidades`, campos que faltan o de tipo
  incorrecto. Si el JSON está mal formado o no es una lista, el índice es `-1` (no hay registro).
  `materiales_con_errores.json` se rechaza en el registro 1 (categoría «proyector»).
- `ExportadorPrestamos.aJson` / `desdeJson`, `aCsv` / `desdeCsv`. CSV con separador `;`, cabecera,
  fechas en ISO 8601 y comillas (con `""` para una comilla) si un campo contiene `;`, comillas o un salto
  de línea. Decisiones:
  - Cabecera `id;materialId;material;alumno;salida;devolucion;dias;incidencias`: se añade `materialId`
    porque sin él `desdeCsv` no podría reconstruir el préstamo.
  - `incidencias` es una lista: va en una sola columna como lista JSON (`["falta el cargador"]`).
  - `dias` es un dato calculado: se escribe pero no se lee.
- Pruebas en `test/ficheros_test.dart`: leen los dos JSON de `assets/datos/` con `File`, escriben el CSV
  en un fichero de `Directory.systemTemp` y lo vuelven a leer (también con una incidencia con `;`).

