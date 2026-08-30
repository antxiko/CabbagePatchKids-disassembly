# Empezar

El desensamblado comentado de **Cabbage Patch Kids** (Konami, RC-716, 1984), el
cartucho MSX de 16 KB. Todo lo que hay aquí sale del binario y se vuelve a
generar desde él.

## Lo que hace falta

- **Python 3** (sin paquetes de fuera)
- **pasmo**, para reensamblar
- **z80dasm**, sólo para los nemónicos
- el cartucho, que este repositorio **no distribuye**

Va en la raíz como `cabbagepatch.rom`, 16.384 bytes, sha256

    114945c770531db3ae61eb330d7ed870a3c00d3a90db2a29a4c134135c2c0707

y `make comprueba` lo verifica.

## La prueba que decide

    make verify

Reensambla `src/cabbagepatch.asm` con pasmo y compara el resultado, byte a
byte, con el cartucho. Si dice `OK: reproducible byte a byte`, el listado no se
ha inventado nada.

## Lo que el reensamblado NO puede cazar

Un listado puede reensamblar perfectamente y estar mal: si unos dibujos se leen
como instrucciones, los bytes no cambian, sólo lo que se dice de ellos. Por eso
van tres comprobaciones más, todas colgadas de `make sanity`:

- **ningún rango declarado como datos puede salir como código**
  (`check_trace.py` y `check_datos_como_codigo.py`, que cruza los 143 rangos
  declarados contra el trazado);
- **ningún punto de entrada puede caer dentro de uno** (`check_entradas.py`): si
  las dos cosas están declaradas a la vez, una de las dos es falsa;
- **ni un byte sin asignar** (`presupuesto.py`). Hoy dice **16.384 de 16.384,
  100 %**.

## Todo lo que se puede ejecutar

    make            # trazado, listado, verify y los tests
    make listado    # regenera src/cabbagepatch.asm desde las anotaciones
    make sanity     # lo que el reensamblado no cubre
    make densidad   # cuánto está comentado, rutina a rutina
    make imagenes   # redibuja los PNG de docs/imagenes desde la ROM
    make web        # regenera esta web
    make test       # los tests

Y uno más, que es de este cartucho:

    python3 tools/repasa_el_porte.py

Las anotaciones **vienen portadas de otro cartucho** —ver
[Hallazgos](HALLAZGOS.md)— y ésa es su guardiana: comprueba que ninguna
dirección citada en un comentario sea un resto, que el otro juego no se nombre
donde no toca, y lista todos los comentarios idénticos a los del hermano que
estén sobre otra instrucción.

## Qué hay aquí

- `src/cabbagepatch.asm` — el listado; generado, no editado a mano
- `src/cabbagepatch.notes` — las anotaciones, ancladas a direcciones
- `src/cabbagepatch.entries` — los puntos de entrada, cada uno justificado
- `src/cabbagepatch.nocode` — las tablas de despacho, que el trazador no debe
  leer como código
- `docs/` — esta web, en inglés y en castellano
- `tools/` — el trazador, el generador del listado, los recorredores de
  formatos y las herramientas de dibujo
