# Preguntas abiertas

Lo cerrado y lo que no, separado. Lo medido lleva su medida; lo supuesto dice
que lo es y **no se ha escrito en el listado como si fuera un hecho**.

---

## MEDIDO, y cerrado

- El cartucho entero: **16.384 bytes, 16.384 explicados, cero sin explicar**.
- El listado **reensambla byte a byte** con pasmo.
- **143 rangos de datos** declarados, todos cruzados contra el trazado, y cada
  uno recorrido con el formato que usa quien lo lee —el descompresor de rachas,
  el motor de rótulos, las listas de tiles— o apuntado por una instrucción que
  lo lee.
- Comentado al **24,5 %**, con **ninguna rutina por debajo del 10 %** de 562.
- Los tres bloques que sobran del otro cartucho son idénticos **byte a byte** y
  **no tienen ninguna referencia**: ni un inmediato, ni una palabra dentro de
  ninguna tabla.

---

## SUPUESTO, y dicho como tal

- **Que los dos bytes de la pantalla del muñeco eligen su aspecto.** Lo medido
  es que `0xE05B` y `0xE05C` son una fila y una columna cada uno, que `0x78C9`
  coloca cinco sprites con ellos, y que la pantalla ofrece exactamente las
  cuatro acciones que produce `0x79BA`. Qué pieza del muñeco cambia con cada
  uno no se ha leído una por una.
- **Los nombres de algunos obstáculos.** El motor es el de Athletic Land y sus
  anotaciones vinieron con él, así que unos cuantos están nombrados por lo que
  hacen allí. Aquí los dibujos son otros, y los nombres de los objetos se han
  suavizado allí donde no se ha comprobado el dibujo.

---

## ABIERTO: lo que no se pudo cerrar

### 1. Si los tres bloques sobrantes se llegaron a usar

Están completos y bien formados —las listas cierran con su propio 0x00
exactamente donde empiezan las que sí se usan— pero no los lee nadie. Si la
recompilación se los trajo sin más o si alguna versión anterior sí los usaba,
este binario no lo puede decir.

### 2. Qué hace la demo, y cómo decide

El modo de atracción juega solo desde el estado 7, y los estados de alrededor
(18 y 19) son suyos, pero la rutina que le da los movimientos no se ha
despiezado.

### 3. Los seis flujos de la tabla de 0x55F5

Son seis flujos por rachas de 96 bytes de VRAM cada uno, uno elegido por el
nibble alto de `0xE05B`, y van a la **tabla de patrones de sprite**. Eso cierra
clavado. Cuál es de qué muñeco, y si la elección de la primera pantalla es lo
que los selecciona, no se ha comprobado en pantalla.

### 4. El salto ciego de 0x408B

Es el `jp (hl)` del propio despachador, y sus cinco tablas están todas
localizadas, así que al trazado no le falta nada. Se apunta aquí porque un
salto ciego siempre merece nombrarse: si existiera una sexta tabla, saldría de
ahí.
