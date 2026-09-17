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
