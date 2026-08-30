# En el emulador

Las imágenes de la galería están dibujadas desde la ROM, sin emulador. Esta
página es lo otro: lo que se comprobó **haciendo correr el cartucho**, que es la
única manera de saber que una pantalla existe y que se ve como el código dice.

El arnés es `tools/omsx_capturas.tcl`, sobre una Philips VG-8020 —un MSX1 real
de la época— con el cartucho puesto en la línea de órdenes:

```
CPK_OUT=work/shots CPK_TECLAS="16 BARRA;19 ABAJO;23 FOTO" \
  openmsx -machine Philips_VG_8020 -cart cabbagepatch.rom \
          -script tools/omsx_capturas.tcl
```

`CPK_TECLAS` es una lista de parejas `segundo tecla`, y `FOTO` dispara una
captura. Las teclas se pulsan en la **matriz del teclado**, no se teclean: con
`type` se escribiría la palabra.

## Lo que dejó cerrado

- **Las dos pantallas de preparación son lo que dice el código.** La primera
  enseña el muñeco dentro de un marco verde con las cuatro teclas debajo
  —`FORWARD`, `BACKWARD`, `CURSOR`, `END`—, que son exactamente las cuatro
  acciones en las que `0x79BA` convierte una pulsación. La segunda añade
  `--NAME--` y el nombre.
- **El nombre de fábrica es ANNA LEE**, y está en pantalla antes de tocar nada.
- **El parque se llama BABYLAND PARK**, y los bebés crecen en repollos. El
  cartel son los diecisiete tiles de `0x6BE5`.
- **El título acredita `© OAA,INC. 1983`**, que no es lo mismo que el
  `©KONAMI 1984` de la pantalla de juego.

## Dos trampas que costaron una captura cada una

- Lanzado con `-script`, openMSX arranca con el renderer *uninitialized* y
  `screenshot` devuelve un PNG en negro con rc=0. Hay que encenderlo a mano con
  `set renderer SDLGL-PP`.
- Con `set throttle off` la máquina corre a toda pastilla y el renderer se
  salta los cuadros, así que la captura hay que pedirla con el acelerador
  **puesto** y con `after realtime`, que es reloj de pared.

## Y una cosa que el emulador no daba

Llegar a la pantalla del nombre a base de teclas no funciona si la opción
elegida en el menú es de joystick, porque entonces el juego lee el joystick y
el teclado no cuenta. En vez de pelearse con eso, el paso del menú se empuja a
mano —`CPK_POKE="30 0xE001 4"` escribe ese byte en ese segundo—, que es lo
mismo que hace el juego al avanzar, sólo que sin esperar a acertar con la
tecla.
