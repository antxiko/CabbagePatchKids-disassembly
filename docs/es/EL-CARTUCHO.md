# El cartucho

16.384 bytes con la cabecera de siempre: `AB` en `0x4000`, `INIT` en `0x404F`,
y STATEMENT, DEVICE y TEXT a cero. La BIOS lo mapea en la **página 1**
(0x4000-0x7FFF) y salta a `INIT` al terminar de arrancar.

## El mapa de memoria

| | |
|---|---|
| 0x4000-0x7FFF | el cartucho |
| 0xE000-0xE3FF | la RAM del juego, que `INIT` borra |
| 0xE400 | la pila |

Del cartucho, **7.981 bytes son código** (4.038 instrucciones) y **8.403 son
datos**, en 143 rangos con nombre. No sobra nada.

## Lo que se le dice al VDP

Los ocho registros están en `0x44F1` y `0x44D7` los copia a `0xE038` antes de
mandarlos:

| registro | valor | qué significa |
|---|---|---|
| R0 | 0x02 | SCREEN 2 |
| R1 | 0xE2 | 16K, pantalla encendida, interrupciones y sprites de 16x16 |
| R2 | 0x0E | tabla de nombres en 0x3800 |
| R3 | 0x7F | tabla de colores en 0x0000 |
| R4 | 0x07 | tabla de patrones en 0x2000 |
| R5 | 0x76 | atributos de sprite en 0x3B00 |
| R6 | 0x03 | patrones de sprite en 0x1800 |
| R7 | 0xE1 | borde negro |

## Cómo se guardan los dibujos

De tres maneras, y el listado usa las tres para recorrer los datos y saber
dónde acaba cada bloque:

**Por rachas**, que descomprime `RLE_A_VRAM` (0x4D24). Un byte de cuenta: el
cero acaba, una cuenta con el bit 7 puesto copia esos bytes tal cual, y sin él
repite el byte siguiente esas veces. Entrando por `0x4D24` el flujo trae
delante su propia dirección de VRAM, de dos bytes; entrando por `0x4D28` la
dirección viene en DE.

**Copias tal cual**, `0x4502`, con HL, DE y BC.

**Copias espejadas**, `0x6DC1`: lo mismo, pero cada byte entra con sus ocho
bits al revés, así que un dibujo sirve para una cosa y para la misma mirando al
otro lado. Cuenta con B, y una de las llamadas carga `ld bc,0x0018`, que deja B
a cero: esa copia son 256 bytes, no 24.

## La fuente

48 glifos de ocho bytes en `0x4A37`. **El código de tile ES el ASCII**, así que
van del 0x30 (`0`) al 0x5F, y `0x4635` los repite en los tres tercios de la
pantalla para poder escribir en cualquier sitio.

![La fuente](../imagenes/fuente.png)

Detrás de la Z hay cinco celdas que no son letras: la palabra `with` que el
menú necesita para «1PLAYER with JOYSTICK», y las dos flechas del cursor.

## Las listas que dibujan

Dos formatos, los dos listas de códigos de tile:

- `PINTA_LISTA` (0x45E7) lee una dirección de VRAM y luego códigos de tile
  hasta un 0xFF; un 0xFE por medio empieza otra vez en otro sitio. Es lo que
  pinta los rótulos.
- El **motor de rótulos**, `MOTOR_DE_ROTULOS` (0x59BC), coge sus tres
  argumentos de los **seis bytes que van detrás de su propio call** —una lista,
  unos tiles y una dirección de VRAM— y vuelve por detrás de ellos. La lista es
  una tira de cuentas: con el bit 7, esas casillas con un solo tile; sin él,
  esos tiles copiados uno a uno; 0x80 empieza otra dirección y 0 acaba.
