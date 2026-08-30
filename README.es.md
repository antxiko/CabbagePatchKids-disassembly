# Cabbage Patch Kids (Konami, RC-716) — desensamblado comentado

El desensamblado comentado del cartucho MSX de 16 KB, reproducible byte a byte.

**[Leer el trabajo →](https://antxiko.github.io/CabbagePatchKids-disassembly/es/)**
· [In English](README.md)

    make            # traza, genera el listado, lo reensambla y pasa los tests
    make verify     # la prueba que decide: reensamblar tiene que devolver la ROM
    make sanity     # que no quede ni un byte sin explicar
    make densidad   # cuanto esta comentado, rutina a rutina
    make imagenes   # redibuja las imagenes desde la ROM
    make web        # regenera la web

La ROM **no se distribuye aqui**. Va en la raiz como `cabbagepatch.rom`, 16384
bytes, sha256

    114945c770531db3ae61eb330d7ed870a3c00d3a90db2a29a4c134135c2c0707

`make comprueba` lo verifica.

## Como esta

| | |
|---|---|
| reensambla byte a byte | si |
| bytes explicados | 16.384 de 16.384 (100 %) |
| codigo trazado | 7.981 bytes, 4.038 instrucciones |
| datos identificados | 8.403 bytes en 143 rangos con nombre |
| comentado | 988 comentarios de linea, 24,5 % |
| rutinas flojas (por debajo del 10 %) | 0 de 562 |

Las anotaciones viven aparte del listado, ancladas a la direccion que
describen, asi que sobreviven a un retrazado. Lo que hay en el `.notes`:

| | |
|---|---|
| etiquetas con nombre | 314 |
| comentarios anclados | 974 |
| rangos de datos con explicación | 143 |

## Algunas cosas que aparecieron

- **Antes de jugar, el cartucho te hace dos preguntas**: que muneco quieres y
  como se llama. El nombre son diez letras que de fabrica dicen **ANNA LEE**,
  escritas en los valores de arranque del jugador justo al lado de las tres
  vidas y el reloj — y se queda en pantalla toda la partida.
- **El parque se llama BABYLAND PARK**, y los bebes crecen en repollos.
- **Viajan 439 bytes de decorado de otro cartucho, sin usar.** Tres bloques son
  byte a byte datos del juego anterior de Konami para MSX, movidos aqui con un
  desfase fijo, y nada en este binario los apunta. Este juego es aquel motor
  recompilado: el 68,5 % de sus instrucciones casan una a una.
- **Todo el juego corre dentro de la interrupcion.** `INIT` la engancha y cae en
  un bucle de dos bytes para siempre; un candado hace que el juego se
  ralentice en vez de atropellarse cuando un fotograma se alarga.
- **El despachador se encuentra su propia tabla**: hace `pop` de la direccion de
  retorno, que es donde empieza la tabla de palabras, y no vuelve nunca al
  `call`. Lo que tiene que correr *despues* de un estado se empuja antes en la
  pila — y sin ver eso, 138 bytes de codigo parecen datos.
- **Una instruccion se escribe en la RAM**, porque el Z80 no la tiene: siete
  bytes que se automodifican el desplazamiento para hacer `ld (IX+A),B`.
- **No lleva la marca oculta de Konami.** El formato lo descubrio Manuel Pazos;
  este cartucho no tiene ningun `0xAA` cerrando nada al final de la ROM.

## Que hay aqui

- `src/cabbagepatch.asm` — el listado; generado, no editado a mano
- `src/cabbagepatch.notes` — las anotaciones, ancladas a direcciones
- `src/cabbagepatch.entries` — los puntos de entrada, cada uno justificado
- `src/cabbagepatch.nocode` — las tablas de despacho, donde el trazador no debe
  meterse
- `docs/` — la web, en ingles y en castellano
- `tools/` — el trazador, el generador del listado, los recorredores de
  formatos, las herramientas de dibujo y `repasa_el_porte.py`, la guardiana de
  las anotaciones portadas

## El trabajo

| | |
|---|---|
| [Empezar](docs/es/EMPEZAR.md) | lo que hace falta y que hace cada orden |
| [El juego](docs/es/EL-JUEGO.md) | Babyland Park, y las dos preguntas de antes de jugar |
| [El cartucho](docs/es/EL-CARTUCHO.md) | la cabecera, el mapa de memoria y como se guardan los dibujos |
| [El codigo](docs/es/EL-CODIGO.md) | la interrupcion, el despachador y el sonido |
| [Hallazgos](docs/es/HALLAZGOS.md) | lo que dice el binario |
| [En el emulador](docs/es/EN-EL-EMULADOR.md) | lo que se comprobo haciendolo correr |
| [Preguntas abiertas](docs/es/PREGUNTAS-ABIERTAS.md) | lo que sigue sin cerrar |

Ver `AVISO-LEGAL.md`.
