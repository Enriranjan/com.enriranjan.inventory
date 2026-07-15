# unity-package-template

Repositorio plantilla (**GitHub Template Repository**) para crear paquetes de
Unity (UPM) siguiendo la convención oficial de layout de Unity. La raíz de
este repositorio **es** la raíz del paquete, así que se puede instalar
directamente por Git URL sin pasos intermedios.

## Cómo usarlo

1. En GitHub, pulsa **"Use this template" → "Create a new repository"** y
   dale nombre al repo del paquete nuevo (por convención,
   `com.enriranjan.<package-id>` o simplemente `<package-id>`).
2. Clona el repo nuevo y ejecuta el script de inicialización desde su raíz:

   ```bash
   # bash / macOS / Linux / Git Bash en Windows
   tools/init-package.sh mypackage MyPackage "My Package" "Qué hace el paquete."
   ```

   ```powershell
   # PowerShell
   tools/init-package.ps1 mypackage MyPackage "My Package" "Qué hace el paquete."
   ```

   Si omites argumentos, el script te los pedirá de forma interactiva. El
   script:
   - valida que `package-id` sea minúsculas (guiones permitidos) y que
     `PackageName` sea PascalCase,
   - reemplaza todos los tokens `__PACKAGE_ID__`, `__PACKAGE_NAME__`,
     `__DISPLAY_NAME__` y `__DESCRIPTION__` en contenidos y nombres de
     archivo,
   - se autoelimina (borra `tools/`) al terminar,
   - imprime las instrucciones de instalación finales.

3. Revisa `package.json`, añade `keywords`, ajusta la versión mínima de
   Unity si hace falta, y empieza a escribir código.
4. Haz commit, crea un tag (`git tag v0.1.0`) y ya puedes instalarlo desde
   otros proyectos por Git URL.

## Estructura y el porqué de cada carpeta

```
package.json          Manifiesto UPM: id, versión, dependencias, samples.
README.md             Este archivo.
CHANGELOG.md          Historial de versiones (Keep a Changelog + SemVer).
LICENSE.md            Licencia MIT.
.gitignore            Ignora cachés/artefactos, pero NO ignora *.meta.
.gitattributes        Normaliza line endings y marca tipos de texto/binario.
Editor/               Código que solo corre en el Editor (SÍ puede usar Unity).
Runtime/              Código de producción del paquete (sistemas puros, ver abajo).
Tests/Editor/         Tests NUnit que corren en el Editor.
Tests/Runtime/        Tests NUnit del código de Runtime.
Samples~/             Ejemplos opcionales, importables desde Package Manager.
Documentation~/       Documentación larga que no debe aparecer como asset.
tools/                Script de inicialización. Se autodestruye tras usarse.
```

Las carpetas con `~` al final (`Samples~`, `Documentation~`) son ignoradas
por el importador de Unity: no aparecen como assets ni generan `.meta`, que
es justo lo que se quiere para samples (se copian explícitamente al
importarlos) y para documentación en Markdown/imágenes.

## Arquitectura: `noEngineReferences` por defecto

Los paquetes que siguen esta plantilla asumen una arquitectura en la que los
**sistemas están escritos en C# puro, sin dependencias de Unity**; Unity se
trata como una capa de vista/adaptador sobre ese código. Por eso:

- El asmdef de `Runtime/` (`EnriRanjan.__PACKAGE_NAME__.asmdef`) tiene
  `"noEngineReferences": true`. Esto le dice al compilador de Unity que
  **prohíba** cualquier referencia a `UnityEngine`/`UnityEditor` en ese
  ensamblado — si el código intenta usar una API de Unity ahí, no compila.
  Esto mantiene el core testeable con NUnit puro y reutilizable fuera de
  Unity.
- El asmdef de `Editor/` sí puede usar Unity (`"noEngineReferences": false`)
  porque su rol es justamente ser la capa de integración/editor tooling.

### Cuándo y cómo desactivarlo

Si tu paquete necesita usar Unity de verdad en Runtime (un `MonoBehaviour`,
`ScriptableObject`, `Physics`, etc. como parte del propio sistema y no solo
como vista), cambia el flag en `Runtime/EnriRanjan.__PACKAGE_NAME__.asmdef`:

```diff
- "noEngineReferences": true
+ "noEngineReferences": false
```

Hazlo solo cuando el acoplamiento a Unity sea inherente al paquete (por
ejemplo, un paquete de utilidades de `Transform` o de rendering). Si el
paquete modela lógica de dominio, prefiere mantener el core sin
`noEngineReferences` y exponer una capa fina en `Editor/` o en un ensamblado
adicional de "adapters" que sí referencie Unity.

## Los archivos `.meta` se commitean

A diferencia de un proyecto de Unity normal (donde a veces se discute si
ignorar `.meta`), en un **paquete** los `.meta` **deben** estar en el
repositorio:

- Contienen los GUID estables que Unity usa para resolver referencias
  (prefabs, assets, scripts) entre el paquete y el proyecto que lo consume.
- Si faltan o se regeneran, cualquier proyecto que ya tenga referencias
  serializadas a assets de este paquete las pierde.
- Por eso `.gitignore` está pensado para un **repo de paquete**, no para un
  proyecto de Unity completo: ignora cachés (`Library/`, `Temp/`, IDEs...)
  pero nunca `*.meta`.

Cuando añadas un archivo nuevo dentro de Unity (con el paquete como
embedded/local package), Unity generará su `.meta` automáticamente —
simplemente añádelo también al commit.

## Versionado

Este template sigue [SemVer](https://semver.org/) y
[Keep a Changelog](https://keepachangelog.com/):

- Cada release se documenta en `CHANGELOG.md` bajo `## [x.y.z] - fecha`.
- La versión también se actualiza en `package.json` (`"version"`).
- Se crea un **tag de git** con el mismo número, prefijado con `v`
  (`git tag v1.0.0`), porque es lo que permite instalar una versión
  concreta por Git URL:

  ```
  https://github.com/enriranjan/<package-id>.git#v1.0.0
  ```

  Sin `#tag`, Git URL apunta a la rama por defecto (normalmente `main`),
  lo cual es útil en desarrollo pero no reproducible para consumidores del
  paquete.

## Instalación

### a) Por Git URL (para consumir el paquete en otro proyecto)

En `Packages/manifest.json` del proyecto Unity que lo va a usar:

```json
{
  "dependencies": {
    "com.enriranjan.<package-id>": "https://github.com/enriranjan/<package-id>.git#v0.1.0"
  }
}
```

También puedes añadirlo desde el editor: **Package Manager → "+" → Install
package from git URL...** y pegar la misma URL con `#tag`.

### b) Como embedded package (mientras desarrollas el paquete)

Clona (o coloca) este repositorio directamente dentro de la carpeta
`Packages/` del proyecto:

```
<UnityProject>/Packages/com.enriranjan.<package-id>/
```

Unity detecta automáticamente cualquier carpeta bajo `Packages/` que
contenga un `package.json` como paquete "embedded": aparece en el Package
Manager, es totalmente editable desde el proyecto, y no requiere entrada en
`manifest.json`. Es el modo recomendado mientras se itera sobre el propio
paquete, ya que los cambios se ven al instante y puedes commitear/pushear
desde ese mismo checkout.

## Añadir samples

Los samples viven en `Samples~/<NombreDelSample>/` (con `~` para que Unity
no los importe automáticamente) y se declaran en `package.json`:

```json
"samples": [
  {
    "displayName": "Basic Usage",
    "description": "Ejemplo mínimo de uso.",
    "path": "Samples~/BasicUsage"
  }
]
```

El usuario del paquete los importa desde **Package Manager → tu paquete →
Samples → Import**, lo que copia la carpeta a `Assets/Samples/...` del
proyecto consumidor. Añade nuevos samples creando una carpeta hermana y una
entrada adicional en el array `samples`.

## Tokens de la plantilla

| Token               | Dónde aparece                                   | Ejemplo       |
|---------------------|--------------------------------------------------|---------------|
| `__PACKAGE_ID__`    | `package.json`, nombres de archivo, docs         | `mypackage`   |
| `__PACKAGE_NAME__`  | asmdefs, namespaces C#, nombres de archivo       | `MyPackage`   |
| `__DISPLAY_NAME__`  | `package.json`, README/CHANGELOG generados       | `My Package`  |
| `__DESCRIPTION__`   | `package.json`                                   | descripción corta |

Todos son reemplazados automáticamente por `tools/init-package.sh` /
`tools/init-package.ps1`. El prefijo de organización `enriranjan` /
`EnriRanjan` es fijo y no es un token: se usa igual en todos los paquetes.
