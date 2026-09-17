# Adaptación para proyecto universitario (copia propia de GTA SA)

Este documento describe los cambios aplicados al source-kit para construir el
mod VR a partir de **una copia propia y legalmente obtenida** de GTA San
Andreas, en lugar del set de splits oficial de Google Play.

## Contexto

El kit original está endurecido para rechazar cualquier APK que no sea el set de
splits retail de Google Play 2.11.311 (firma oficial, `libGame.so` con hash
conocido, DEX/libs exactos). Para un proyecto académico que parte de la copia
del juego que el estudiante ya posee, esos controles de procedencia no aplican.

La copia de trabajo de este proyecto es un **APK autocontenido** de ~2.5 GB
(`gta_sa_2.11.311.apk`): contiene en un solo archivo el `base`, el `arm64`
(`lib/arm64-v8a/libGame.so`) y los datos del juego (`assets/...`). `assemble.py`
ya soporta este caso como APK monolítico (`monolithic = True`).

## Cambios aplicados

### `tools/assemble.py`
- `classify_game_package` ya no lanza error si el hash de `libGame.so` difiere
  del retail cuando se usa `--allow-unofficial-source`; emite una advertencia y
  continúa (los hooks VR son version-guarded en runtime).
- Se omiten las comprobaciones estrictas de DEX/libs retail en modo no oficial.
- `GamePackage` ahora expone `engine_sha256`; el `build-manifest.json` registra
  el hash real del engine del APK procesado en lugar de la constante retail, para
  que la verificación posterior coincida.

### `tools/build-and-install.ps1` (master)
- Nuevo parámetro `-AllowUnofficialSource` que se propaga a la validación
  (`--allow-unofficial-source`) y al build (`-AllowUnofficialSource`).
- `Assert-BuildArtifacts` omite los chequeos de firmante oficial de Play y del
  hash retail de `libGame.so` cuando `-AllowUnofficialSource` está presente,
  confiando en el hash registrado por `assemble.py`.

### `tools/build.ps1`
- Ya reenviaba `-AllowUnofficialSource` a `assemble.py`; sin cambios necesarios.

## Uso

```powershell
.\tools\build-and-install.ps1 `
  -GamePackage "c:\gts sa vr\gta_sa_2.11.311.apk" `
  -AudioSource "D:\Mods\gta-sa-ps2-style-mod-pack_1786856007_737162.7z" `
  -AllowUnofficialSource `
  -BuildOnly
```

Para instalar en Quest, quita `-BuildOnly` y conecta el dispositivo con depuración
USB y modo desarrollador.

## Notas de responsabilidad

- Estos cambios **no** redistribuyen ni descargan nada de Rockstar; solo procesan
  la copia que el usuario ya posee legalmente.
- El runtime VR sigue siendo version-guarded: si el engine de la copia difiere
  demasiado del 2.11.311 esperado, los hooks opcionales se desactivan en runtime.
- Mantén `libGame.so` byte-idéntico en disco; el kit no lo modifica.

## Arquitectura del mod VR (extraída del code graph)

El code graph del proyecto (`graphify-out/graph.json`, 5814 nodos / 10172 edges)
muestra tres subsistemas conectados:

- **`loader/src/com/savr/SavrApplication.java`** (comunidad 74, grado 15): el
  `Application` de Android que se carga antes de la actividad del juego. Crea la
  superficie de render VR (`createGameSurface`), engancha la textura del juego
  (`attachGameTexture` / `updateGameTexture`) y delega a `nativeOnApplicationCreate`.
- **`native/src/VrCamera.cpp`** (comunidad 4, grado 627): el núcleo de render
  estéreo. Contiene `OnRenderScene`, `OnScanWorld`, `OnSetupMapEntityVisibility`,
  el consumidor de `RenderQueue` y los contadores de LOD/culling para la cámara
  de aeronaves. Es el archivo más conectado del runtime.
- **`native/src/Xr.cpp` / `Xr.h`** (comunidad XR): la capa OpenXR que posee la
  sesión del headset, los swapchains, el estado de los controladores, las manos
  VR y las capas de composición.

El flujo es: `SavrApplication` (Java) carga `libsavr.so` → el native resuelve
los símbolos exportados de `libGame.so` → instala hooks version-guarded → el
hilo de juego graba las dos vistas de ojo vía RenderWare y el hilo OpenXR
compone la salida en el headset. Los controladores de Quest se traducen a la
entrada de gamepad móvil existente del juego.

## Nota sobre graphify y los binarios del juego

`python -m graphify extract` indexa **solo código fuente** (C/C++, Java, Python,
scripts). Los binarios comprimidos (`gta_sa_2.11.311.apk`, el `.7z` del audio
mod) se reportan como "no clasificados" y se omiten: graphify no es un extractor
de archivos comprimidos, sino un indexador de código. Por eso el graph se construye
desde la raíz del source-kit y no desde los APK/mod pack.
