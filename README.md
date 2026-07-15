# unity-package-template

Repositorio plantilla (**GitHub Template Repository**) para crear paquetes de
Unity (UPM) siguiendo la convenciÃ³n oficial de layout de Unity. La raÃ­z de
este repositorio **es** la raÃ­z del paquete, asÃ­ que se puede instalar
directamente por Git URL sin pasos intermedios.

## CÃ³mo usarlo

1. En GitHub, pulsa **"Use this template" â†’ "Create a new repository"** y
   dale nombre al repo del paquete nuevo (por convenciÃ³n,
   `com.enriranjan.<package-id>` o simplemente `<package-id>`).
2. Clona el repo nuevo y ejecuta el script de inicializaciÃ³n desde su raÃ­z:

   ```bash
   # bash / macOS / Linux / Git Bash en Windows
   tools/init-package.sh mypackage MyPackage "My Package" "QuÃ© hace el paquete."
   ```

   ```powershell
   # PowerShell
   tools/init-package.ps1 mypackage MyPackage "My Package" "QuÃ© hace el paquete."
   ```

   Si omites argumentos, el script te los pedirÃ¡ de forma interactiva. El
   script:
   - valida que `package-id` sea minÃºsculas (guiones permitidos) y que
     `PackageName` sea PascalCase,
   - reemplaza todos los tokens `inventory`, `Inventory`,
     `Inventory` y `Inventario genérico basado en slots: capacidad, añadir/retirar y eventos de cambio sobre identificadores opacos. C# puro, sin conocimiento del tipo de item ni del motor; la semántica de qué contiene cada slot la aporta la capa de aplicación.` en contenidos y nombres de
     archivo,
   - se autoelimina (borra `tools/`) al terminar,
   - imprime las instrucciones de instalaciÃ³n finales.

3. Revisa `package.json`, aÃ±ade `keywords`, ajusta la versiÃ³n mÃ­nima de
   Unity si hace falta, y empieza a escribir cÃ³digo.
4. Haz commit, crea un tag (`git tag v0.1.0`) y ya puedes instalarlo desde
   otros proyectos por Git URL.

## Estructura y el porquÃ© de cada carpeta

```
package.json          Manifiesto UPM: id, versiÃ³n, dependencias, samples.
README.md             Este archivo.
CHANGELOG.md          Historial de versiones (Keep a Changelog + SemVer).
LICENSE.md            Licencia MIT.
.gitignore            Ignora cachÃ©s/artefactos, pero NO ignora *.meta.
.gitattributes        Normaliza line endings y marca tipos de texto/binario.
Editor/               CÃ³digo que solo corre en el Editor (SÃ puede usar Unity).
Runtime/              CÃ³digo de producciÃ³n del paquete (sistemas puros, ver abajo).
Tests/Editor/         Tests NUnit que corren en el Editor.
Tests/Runtime/        Tests NUnit del cÃ³digo de Runtime.
Samples~/             Ejemplos opcionales, importables desde Package Manager.
Documentation~/       DocumentaciÃ³n larga que no debe aparecer como asset.
tools/                Script de inicializaciÃ³n. Se autodestruye tras usarse.
```

Las carpetas con `~` al final (`Samples~`, `Documentation~`) son ignoradas
por el importador de Unity: no aparecen como assets ni generan `.meta`, que
es justo lo que se quiere para samples (se copian explÃ­citamente al
importarlos) y para documentaciÃ³n en Markdown/imÃ¡genes.

## Arquitectura: `noEngineReferences` por defecto

Los paquetes que siguen esta plantilla asumen una arquitectura en la que los
**sistemas estÃ¡n escritos en C# puro, sin dependencias de Unity**; Unity se
trata como una capa de vista/adaptador sobre ese cÃ³digo. Por eso:

- El asmdef de `Runtime/` (`EnriRanjan.Inventory.asmdef`) tiene
  `"noEngineReferences": true`. Esto le dice al compilador de Unity que
  **prohÃ­ba** cualquier referencia a `UnityEngine`/`UnityEditor` en ese
  ensamblado â€” si el cÃ³digo intenta usar una API de Unity ahÃ­, no compila.
  Esto mantiene el core testeable con NUnit puro y reutilizable fuera de
  Unity.
- El asmdef de `Editor/` sÃ­ puede usar Unity (`"noEngineReferences": false`)
  porque su rol es justamente ser la capa de integraciÃ³n/editor tooling.

### CuÃ¡ndo y cÃ³mo desactivarlo

Si tu paquete necesita usar Unity de verdad en Runtime (un `MonoBehaviour`,
`ScriptableObject`, `Physics`, etc. como parte del propio sistema y no solo
como vista), cambia el flag en `Runtime/EnriRanjan.Inventory.asmdef`:

```diff
- "noEngineReferences": true
+ "noEngineReferences": false
```

Hazlo solo cuando el acoplamiento a Unity sea inherente al paquete (por
ejemplo, un paquete de utilidades de `Transform` o de rendering). Si el
paquete modela lÃ³gica de dominio, prefiere mantener el core sin
`noEngineReferences` y exponer una capa fina en `Editor/` o en un ensamblado
adicional de "adapters" que sÃ­ referencie Unity.

## Los archivos `.meta` se commitean

A diferencia de un proyecto de Unity normal (donde a veces se discute si
ignorar `.meta`), en un **paquete** los `.meta` **deben** estar en el
repositorio:

- Contienen los GUID estables que Unity usa para resolver referencias
  (prefabs, assets, scripts) entre el paquete y el proyecto que lo consume.
- Si faltan o se regeneran, cualquier proyecto que ya tenga referencias
  serializadas a assets de este paquete las pierde.
- Por eso `.gitignore` estÃ¡ pensado para un **repo de paquete**, no para un
  proyecto de Unity completo: ignora cachÃ©s (`Library/`, `Temp/`, IDEs...)
  pero nunca `*.meta`.

Cuando aÃ±adas un archivo nuevo dentro de Unity (con el paquete como
embedded/local package), Unity generarÃ¡ su `.meta` automÃ¡ticamente â€”
simplemente aÃ±Ã¡delo tambiÃ©n al commit.

## Versionado

Este template sigue [SemVer](https://semver.org/) y
[Keep a Changelog](https://keepachangelog.com/):

- Cada release se documenta en `CHANGELOG.md` bajo `## [x.y.z] - fecha`.
- La versiÃ³n tambiÃ©n se actualiza en `package.json` (`"version"`).
- Se crea un **tag de git** con el mismo nÃºmero, prefijado con `v`
  (`git tag v1.0.0`), porque es lo que permite instalar una versiÃ³n
  concreta por Git URL:

  ```
  https://github.com/enriranjan/<package-id>.git#v1.0.0
  ```

  Sin `#tag`, Git URL apunta a la rama por defecto (normalmente `main`),
  lo cual es Ãºtil en desarrollo pero no reproducible para consumidores del
  paquete.

## InstalaciÃ³n

### a) Por Git URL (para consumir el paquete en otro proyecto)

En `Packages/manifest.json` del proyecto Unity que lo va a usar:

```json
{
  "dependencies": {
    "com.enriranjan.<package-id>": "https://github.com/enriranjan/<package-id>.git#v0.1.0"
  }
}
```

TambiÃ©n puedes aÃ±adirlo desde el editor: **Package Manager â†’ "+" â†’ Install
package from git URL...** y pegar la misma URL con `#tag`.

### b) Como embedded package (mientras desarrollas el paquete)

Clona (o coloca) este repositorio directamente dentro de la carpeta
`Packages/` del proyecto:

```
<UnityProject>/Packages/com.enriranjan.<package-id>/
```

Unity detecta automÃ¡ticamente cualquier carpeta bajo `Packages/` que
contenga un `package.json` como paquete "embedded": aparece en el Package
Manager, es totalmente editable desde el proyecto, y no requiere entrada en
`manifest.json`. Es el modo recomendado mientras se itera sobre el propio
paquete, ya que los cambios se ven al instante y puedes commitear/pushear
desde ese mismo checkout.

## AÃ±adir samples

Los samples viven en `Samples~/<NombreDelSample>/` (con `~` para que Unity
no los importe automÃ¡ticamente) y se declaran en `package.json`:

```json
"samples": [
  {
    "displayName": "Basic Usage",
    "description": "Ejemplo mÃ­nimo de uso.",
    "path": "Samples~/BasicUsage"
  }
]
```

El usuario del paquete los importa desde **Package Manager â†’ tu paquete â†’
Samples â†’ Import**, lo que copia la carpeta a `Assets/Samples/...` del
proyecto consumidor. AÃ±ade nuevos samples creando una carpeta hermana y una
entrada adicional en el array `samples`.

## Tokens de la plantilla

| Token               | DÃ³nde aparece                                   | Ejemplo       |
|---------------------|--------------------------------------------------|---------------|
| `inventory`    | `package.json`, nombres de archivo, docs         | `mypackage`   |
| `Inventory`  | asmdefs, namespaces C#, nombres de archivo       | `MyPackage`   |
| `Inventory`  | `package.json`, README/CHANGELOG generados       | `My Package`  |
| `Inventario genérico basado en slots: capacidad, añadir/retirar y eventos de cambio sobre identificadores opacos. C# puro, sin conocimiento del tipo de item ni del motor; la semántica de qué contiene cada slot la aporta la capa de aplicación.`   | `package.json`                                   | descripciÃ³n corta |

Todos son reemplazados automÃ¡ticamente por `tools/init-package.sh` /
`tools/init-package.ps1`. El prefijo de organizaciÃ³n `enriranjan` /
`EnriRanjan` es fijo y no es un token: se usa igual en todos los paquetes.
