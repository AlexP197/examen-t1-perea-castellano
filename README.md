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

