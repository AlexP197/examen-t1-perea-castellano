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
