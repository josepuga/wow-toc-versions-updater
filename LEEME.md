# WoW TOC Versions Updater

Scripts Bash para actualizar las versiones de compatibilidad de los **addons de World of Warcraft**, evitando los avisos de addons desactualizados cuando Blizzard publica nuevas versiones de sus clientes.

El proceso se divide en dos scripts independientes:

## 1. `get-versions.sh`

Consulta la API de [BlizzTrack](https://blizztrack.com/) para obtener las últimas versiones de los diferentes clientes de World of Warcraft.

Genera una salida en formato CSV que puede redirigirse a un fichero:

```bash
./get-versions.sh > versions.csv
```

Cada línea contiene tres campos:

`CLIENTE,INTERFACE,VERSION_PUBLICA`

Ejemplo:

```csv
wow,120100,12.1.0.69933
wow_classic,50504,5.5.4.70032
wow_classic_era,11509,1.15.9.70003
wow_anniversary,20506,2.5.6.69795
wow_classic_beta,16001,1.60.1.70245
```

- **CLIENTE:** Identificador del cliente de WoW utilizado por BlizzTrack.
- **INTERFACE:** Número de versión utilizado en los ficheros `.toc` de los addons de WoW.
- **VERSION_PUBLICA:** Versión completa del cliente, incluido el número de compilación (*build*), tal como suele aparecer en los registros de cambios (*changelogs*), foros y notas de publicación.

Si no es posible obtener alguna versión, se utiliza `ERROR` como valor.

Este script sólo necesita ejecutarse cuando se quiera actualizar la información de las versiones de los clientes de WoW.

## 2. `update-toc.sh`

Actualiza el fichero `.toc` de un addon utilizando las versiones obtenidas previamente mediante `get-versions.sh`.

**Uso:**

```bash
./update-toc.sh path/to/AddonName.toc versions.csv
```

El script compara las versiones del CSV con las declaradas en el fichero `.toc` del addon.

**Si detecta cambios:**

- Actualiza `## Interface:` con las últimas versiones de compatibilidad.
- Incrementa el número **PATCH** de la versión del addon (`MAJOR.MINOR.PATCH`) en `## Version:`.
- Conserva las versiones `Interface` existentes cuando no se dispone de información actualizada.
- Actualiza `## TAG_ORDER:` para mantener la correspondencia correcta entre los clientes y sus versiones `Interface`.
- Crea una copia de seguridad del fichero `.toc` original con la extensión `.bak`.

**Si no detecta cambios**, el fichero `.toc` permanece intacto.

El script también muestra una advertencia si el fichero CSV tiene más de siete días de antigüedad.

## Configuración obligatoria del TOC: `TAG_ORDER`

El script `update-toc.sh` necesita un campo de metadatos adicional en el fichero `.toc` del addon:

```toc
## TAG_ORDER: wow wow_classic wow_classic_era wow_anniversary wow_classic_beta
## Interface: 120100, 50504, 11509, 20506, 16001
```

**`TAG_ORDER` es un campo de metadatos personalizado**, no una directiva estándar de Blizzard. Indica al script a qué cliente de WoW corresponde cada versión de `Interface`.

La correspondencia se establece por posición:

| TAG_ORDER | Interface | Cliente de WoW |
|---|---|---|
| `wow` | `120100` | Retail |
| `wow_classic` | `50504` | Classic progresivo |
| `wow_classic_era` | `11509` | Classic Era |
| `wow_anniversary` | `20506` | Anniversary |
| `wow_classic_beta` | `16001` | Classic Beta |

**Importante:**

- El número de elementos de `TAG_ORDER` debe coincidir con el número de versiones de `## Interface`.
- Ambos campos deben mantener el mismo orden.
- El orden en sí es arbitrario, siempre que se mantenga la correspondencia entre ambos campos.
- Sólo es necesario incluir los clientes de WoW compatibles con el addon.

El script actualiza automáticamente ambos campos cuando es necesario, manteniendo su correspondencia por posición aunque cambie el orden.

Sin `## TAG_ORDER`, el script no puede identificar a qué cliente de WoW pertenece cada versión de `Interface` y no actualizará el fichero `.toc`.

## Funcionamiento

Ambos scripts funcionan de manera independiente:

1. Ejecutar `get-versions.sh` para obtener las últimas versiones de los clientes de WoW y guardarlas en un fichero CSV.
2. Añadir el campo obligatorio `## TAG_ORDER` al fichero `.toc` de cada addon.
3. Ejecutar `update-toc.sh` para cada addon que se quiera actualizar.

Ejemplo:

```bash
./get-versions.sh > versions.csv

./update-toc.sh PugaLib/PugaLib.toc versions.csv
./update-toc.sh PugaMemories/PugaMemories.toc versions.csv
```

Esto permite obtener las versiones de los clientes de WoW una sola vez y reutilizar el mismo fichero CSV para actualizar tantos addons como se desee, sin realizar nuevas peticiones a la API.

El fichero CSV puede actualizarse cuando se considere necesario; no es obligatorio hacerlo diariamente.

La actualización de los ficheros `.toc` se realiza localmente y no requiere conexión a Internet.

## Requisitos

- Bash
- `curl` y `jq` (para `get-versions.sh`)
- Utilidades estándar de línea de comandos de GNU/Linux (para `update-toc.sh`)

## Nota importante

Actualizar `## Interface` evita los avisos de addons desactualizados, pero **no garantiza que un addon sea compatible con los cambios introducidos en la API de Blizzard**.

La compatibilidad real debe comprobarse igualmente.

## Licencia

Licencia MIT.

Copyright (c) 2026 José Puga.