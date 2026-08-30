#!/usr/bin/env python3
"""Genera la portada de la web, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

Las de la galeria NO son capturas: las dibuja tools/graficos.py rehaciendo la
memoria de video con las mismas copias que hace el cartucho, y descomprimiendo
sus rachas con el mismo formato que corre el Z80. Las tres que si son capturas
lo dicen en su pie.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# Las cifras salen de las herramientas, no de escribirlas a ojo:
# 16384 = 7981 + 8403, que es lo que imprime tools/presupuesto.py (make sanity);
# RUTINAS son las etiquetas con nombre propio (directiva L del .notes) y
# DENSIDAD lo que mide tools/densidad.py (make densidad).
CODIGO = 7981
DATOS = 8403
RUTINAS = 288
COMENTARIOS = 974
DENSIDAD_ES = "24,5 %"
DENSIDAD_EN = "24.5%"


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="Cabbage Patch Kids — desensamblado comentado",
        aviso="<b>La galería no lleva capturas.</b> Los gráficos están "
              "<b>dibujados desde los bytes de la ROM</b>: "
              "<code>tools/graficos.py</code> rehace la memoria de vídeo con "
              "las mismas copias que hace el cartucho y descomprime sus rachas "
              "con el mismo formato que corre el Z80. Las tres capturas de "
              "emulador que hay lo dicen en su pie. El listado y las cifras "
              "salen del binario y se reproducen con <code>make</code>.",
        claim="Antes de jugar, el cartucho te hace dos preguntas: <b>qué muñeco "
              "quieres</b> y <b>cómo se llama</b>. El nombre, diez letras que "
              "de fábrica dicen ANNA LEE, te acompaña abajo en la pantalla toda "
              "la partida. Y el parque por el que anda se llama BABYLAND, con "
              "los bebés creciendo en repollos.",
        ficha=["Konami · <b>© Konami 1984</b>",
               "Cartucho <b>RC-716</b>, 16 KB",
               "MSX1 · <b>página 1</b>", "Volcado <b>114945c7…</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El código"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("EN-EL-EMULADOR.html", "En el emulador"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El cartucho en cifras", h_find="Lo que apareció al desmontarlo",
        h_scr="Lo que el cartucho dibuja",
        cifras=[("100 %", "del binario explicado"),
                (mil(RUTINAS, "es"), "rutinas identificadas"),
                (mil(CODIGO, "es"), "bytes de código"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "bytes sin identificar"),
                (DENSIDAD_ES, "de densidad de comentarios")],
        nota_scr="Debajo de cada pie está de dónde sale. Se rehacen con "
                 "<code>make imagenes</code> y no hace falta emulador.",
        pie_leg="Esto es trabajo de documentación y preservación: el código y "
                "los gráficos siguen siendo de sus autores y de Konami, y la "
                "imagen del cartucho no se distribuye.",
    ),
    "en": dict(
        titulo="Cabbage Patch Kids — a commented disassembly",
        aviso="<b>The gallery has no screenshots.</b> The graphics are "
              "<b>drawn from the ROM's bytes</b>: "
              "<code>tools/graficos.py</code> rebuilds video memory with the "
              "same copies the cartridge makes and decompresses its runs with "
              "the same format the Z80 runs. The three emulator captures there "
              "are say so in their caption. The listing and the numbers come "
              "from the binary and are reproduced with <code>make</code>.",
        claim="Before you play, the cartridge asks you two things: <b>which kid "
              "you want</b> and <b>what it is called</b>. The name, ten letters "
              "that come out of the factory saying ANNA LEE, stays at the "
              "bottom of the screen for the whole game. And the park it walks "
              "through is called BABYLAND, with the babies growing in cabbages.",
        ficha=["Konami · <b>© Konami 1984</b>",
               "An <b>RC-716</b> 16 KB cartridge",
               "MSX1 · <b>page 1</b>", "Dump <b>114945c7…</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("FINDINGS.html", "Findings"),
                ("IN-THE-EMULATOR.html", "In the emulator"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The cartridge in numbers",
        h_find="What turned up when we took it apart",
        h_scr="What the cartridge draws",
        cifras=[("100%", "of the binary explained"),
                (mil(RUTINAS, "en"), "routines identified"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "bytes unidentified"),
                (DENSIDAD_EN, "comment density")],
        nota_scr="Under each caption is where it comes from. They are all "
                 "rebuilt by <code>make imagenes</code>, no emulator needed.",
        pie_leg="This is documentation and preservation work: the code and "
                "artwork still belong to their authors and to Konami, and the "
                "cartridge image is not distributed.",
    ),
}

HALLAZGOS = {
    "es": [
        ("El cartucho arrastra datos de otro juego, y aquí no los lee nadie",
         "<p>Tres bloques —<code>0x6718</code> (16 bytes), <code>0x6AA6</code> "
         "(251) y <code>0x6BF6</code> (172)— son, <b>byte a byte</b>, listas y "
         "tiles de fondo de <em>Athletic Land</em>, el cartucho anterior de la "
         "casa, movidos aquí +1.724, +1.002 y +1.027.</p>"
         "<p>Y no se usan: ni una instrucción del binario los apunta, ni "
         "aparece su dirección dentro de ninguna tabla. Este juego es el motor "
         "de aquél recompilado —el 68,5 % de sus instrucciones se alinean una a "
         "una—, y en la mudanza se vinieron 439 bytes de decorado que ya no "
         "pinta nadie. Lo mismo pasa con la rutina muerta de <code>0x44D2</code>, "
         "que es la misma que allí.</p>"),
        ("Tú eliges el muñeco y le pones nombre, y el nombre es parte de la partida",
         "<p>El menú no lleva directo al juego: pasa por dos pantallas. En la "
         "primera se elige el muñeco con dos bytes, <code>0xE05B</code> y "
         "<code>0xE05C</code>, que dan la fila y la columna de cada mitad de la "
         "figura (<code>0x78C9</code> reparte cinco sprites con ellos). En la "
         "segunda se escribe el nombre: <b>diez letras</b> en "
         "<code>0xE05D</code>, que se recorren en redondo entre el blanco y la "
         "Z (<code>0x7968</code>).</p>"
         "<p>De fábrica dice <b>ANNA LEE</b>, y está escrito en los valores de "
         "arranque del jugador, en <code>0x44A3</code>, junto a las vidas y el "
         "tiempo. Con dos jugadores la pantalla se repite: cada uno bautiza el "
         "suyo (<code>0x426B</code>).</p>"),
        ("Todo el juego corre dentro de la interrupción",
         "<p><code>INIT</code> (0x404F) escribe <code>jp 0x402C</code> en el "
         "gancho H.KEYI y se queda en un <code>jr</code> a sí mismo para "
         "siempre. A partir de ahí, cada fotograma la interrupción toca el "
         "sonido, lee los mandos y ejecuta <b>un paso</b> del estado que diga "
         "<code>0xE000</code>.</p>"
         "<p>Y lleva candado: <code>0xE005</code>. Si un paso tarda más de un "
         "fotograma, la interrupción siguiente sólo mueve la música y se va "
         "(<code>0x404C</code>), así que el juego se ralentiza en vez de "
         "atropellarse.</p>"),
        ("El despachador de Konami: la tabla va pegada detrás del CALL",
         "<p><code>0x4082</code> no recibe la tabla: <b>se la encuentra</b>. "
         "Hace <code>add a,a / pop hl</code>, y ese <code>pop</code> recoge la "
         "dirección de retorno, que es justo donde empieza la tabla de "
         "palabras. Luego salta con <code>jp (hl)</code> y no vuelve nunca al "
         "<code>call</code>.</p>"
         "<p>Hay cinco tablas así: los 20 estados del juego (0x4144), los seis "
         "pasos del menú (0x41F8), los 17 estados del jugador (0x6016) y dos de "
         "cuatro para las pantallas de preparación. Cada una cierra clavada "
         "contra su destino más bajo, que es lo que da su tamaño.</p>"),
        ("Y lo que tiene que correr DESPUÉS del estado se empuja en la pila",
         "<p>Como el despachador no vuelve, no hay forma de encadenar nada "
         "detrás… salvo dejarlo puesto antes. <code>0x4131</code> mete en HL "
         "una de dos direcciones —<code>0x4735</code> con partida en marcha, "
         "<code>0x40C1</code> sin ella— y hace <code>push hl</code>: el "
         "<code>ret</code> del estado aterriza ahí.</p>"
         "<p>Sin darse cuenta de eso, esas dos rutinas no las alcanza el "
         "trazador y salen del listado como si fueran datos. Son 138 bytes de "
         "código: el parpadeo del rótulo del jugador y la lectura de teclas del "
         "menú.</p>"),
        ("La rutina que el Z80 no tiene, escrita en la RAM",
         "<p>El desplegador de dibujos necesita <code>ld (IX+A),B</code> —un "
         "desplazamiento variable—, y el Z80 sólo admite el desplazamiento "
         "fijo dentro del opcode. La solución del cartucho es escribir el byte "
         "del desplazamiento en marcha: siete bytes copiados a la RAM que "
         "hacen <code>ld (0xE5FD),a</code> y luego <code>ld (ix+00h),b</code>, "
         "donde <code>0xE5FD</code> es justo el operando de esa segunda "
         "instrucción.</p>"),
        ("No lleva la marca oculta de Konami",
         "<p>Muchos cartuchos de la casa esconden al final de la ROM su número "
         "de catálogo y el título en katakana; lo descubrió <b>Manuel Pazos</b> "
         "(<a href=\"https://threadreaderapp.com/thread/1437082207634575365.html\">"
         "@ManuelPazosMSX</a>), y gracias a él se sabe dónde mirar. Aquí no "
         "está: detrás del relleno hay datos del reproductor de sonido y ningún "
         "<code>0xAA</code> que cierre la marca. El RC-716 sale del catálogo, "
         "no del binario.</p>"),
    ],
    "en": [
        ("The cartridge carries another game's data, and nothing here reads it",
         "<p>Three blocks — <code>0x6718</code> (16 bytes), <code>0x6AA6</code> "
         "(251) and <code>0x6BF6</code> (172) — are, <b>byte for byte</b>, "
         "background lists and tiles from <em>Athletic Land</em>, the house's "
         "earlier cartridge, moved here by +1,724, +1,002 and +1,027.</p>"
         "<p>And they are unused: not one instruction points at them, and their "
         "addresses appear in no table. This game is that engine recompiled — "
         "68.5% of its instructions line up one to one — and 439 bytes of "
         "scenery came along in the move with nothing left to draw them. The "
         "same goes for the dead routine at <code>0x44D2</code>, which is the "
         "same one it has there.</p>"),
        ("You pick the kid and name it, and the name is part of the game",
         "<p>The menu does not lead straight into play: two screens come "
         "first. On the first you choose the kid with two bytes, "
         "<code>0xE05B</code> and <code>0xE05C</code>, which give the row and "
         "column of each half of the figure (<code>0x78C9</code> places five "
         "sprites from them). On the second you type the name: <b>ten "
         "letters</b> at <code>0xE05D</code>, cycled round between blank and Z "
         "(<code>0x7968</code>).</p>"
         "<p>Out of the factory it says <b>ANNA LEE</b>, and it is written into "
         "the player's start-up values at <code>0x44A3</code>, next to the "
         "lives and the time. With two players the screen comes round twice: "
         "each names their own (<code>0x426B</code>).</p>"),
        ("The whole game runs inside the interrupt",
         "<p><code>INIT</code> (0x404F) writes <code>jp 0x402C</code> into the "
         "H.KEYI hook and drops into a <code>jr</code> to itself forever. From "
         "there, every frame the interrupt plays the sound, reads the controls "
         "and runs <b>one step</b> of whatever state <code>0xE000</code> "
         "names.</p>"
         "<p>And it carries a latch, <code>0xE005</code>. If a step takes "
         "longer than a frame, the next interrupt only moves the music along "
         "and leaves (<code>0x404C</code>), so the game slows down instead of "
         "tripping over itself.</p>"),
        ("Konami's dispatcher: the table sits right behind the CALL",
         "<p><code>0x4082</code> is not handed the table: <b>it finds it</b>. "
         "It does <code>add a,a / pop hl</code>, and that <code>pop</code> "
         "picks up the return address, which is exactly where the word table "
         "starts. Then it jumps with <code>jp (hl)</code> and never comes back "
         "to the <code>call</code>.</p>"
         "<p>There are five such tables: the game's 20 states (0x4144), the "
         "menu's six steps (0x41F8), the player's 17 states (0x6016) and two of "
         "four for the set-up screens. Each closes exactly against its lowest "
         "destination, and that is what gives its size.</p>"),
        ("And whatever has to run AFTER the state is pushed on the stack",
         "<p>Since the dispatcher never returns, there is no way to chain "
         "anything behind it… except to leave it there first. "
         "<code>0x4131</code> loads HL with one of two addresses — "
         "<code>0x4735</code> with a game in play, <code>0x40C1</code> without "
         "— and does <code>push hl</code>: the state's <code>ret</code> lands "
         "there.</p>"
         "<p>Miss that and the tracer never reaches those two routines, and "
         "they come out of the listing as if they were data. That is 138 bytes "
         "of code: the blinking of the player label and the menu's key "
         "reading.</p>"),
        ("The instruction the Z80 does not have, written into RAM",
         "<p>The drawing unpacker needs <code>ld (IX+A),B</code> — a variable "
         "displacement — and the Z80 only takes a fixed one inside the opcode. "
         "The cartridge's answer is to write the displacement byte as it goes: "
         "seven bytes copied into RAM that do <code>ld (0xE5FD),a</code> and "
         "then <code>ld (ix+00h),b</code>, where <code>0xE5FD</code> is exactly "
         "the operand of that second instruction.</p>"),
        ("It does not carry Konami's hidden mark",
         "<p>Many of the house's cartridges hide their catalogue number and the "
         "title in katakana at the end of the ROM; <b>Manuel Pazos</b> "
         "(<a href=\"https://threadreaderapp.com/thread/1437082207634575365.html\">"
         "@ManuelPazosMSX</a>) found it, and it is thanks to him that anyone "
         "knows to look. Here it is absent: behind the filler there is "
         "sound-player data and no <code>0xAA</code> to close the mark. RC-716 "
         "comes from the catalogue, not from the binary.</p>"),
    ],
}

GALERIA = [
    ("titulo.png",
     "DIBUJADO desde 0x4894 — el logotipo del título, que son tiles: el "
     "cartucho los descomprime en la tabla de patrones y luego los coloca "
     "columna a columna. Los dos de la cola de la «g» van en una tercera fila "
     "que sólo tiene dibujo en dos columnas",
     "DRAWN from 0x4894 — the title logo, which is made of tiles: the "
     "cartridge unpacks them into the pattern table and then places them "
     "column by column. The two that make the tail of the «g» sit on a third "
     "row that has artwork in two columns only"),
    ("tiles.png",
     "DIBUJADOS repitiendo las copias de CARGA_PATRONES_Y_COLORES (0x6CA2): "
     "los tres tercios de la tabla de patrones con su color. Las flores, la "
     "hierba, el ladrillo y los repollos con cara salen de ahí",
     "DRAWN by replaying the copies in CARGA_PATRONES_Y_COLORES (0x6CA2): the "
     "three thirds of the pattern table with their colour. The flowers, the "
     "grass, the brickwork and the cabbages with faces all come from there"),
    ("sprites.png",
     "DIBUJADOS de los seis flujos de la tabla de 0x55F5 y dos más: los 64 "
     "patrones de sprite de 16x16. El color no está aquí —lo pone la ficha de "
     "cada sprite—, así que salen en blanco",
     "DRAWN from the six streams in the table at 0x55F5 and two more: the 64 "
     "16×16 sprite patterns. The colour is not here — each sprite's own record "
     "carries it — so they come out white"),
    ("fuente.png",
     "DIBUJADA de 0x4A37 — los 48 glifos de ocho bytes. El código de tile ES "
     "el ASCII, así que van del 0x30 («0») al 0x5F, y detrás de la Z quedan el "
     "«with» del menú y las dos flechas del cursor",
     "DRAWN from 0x4A37 — the 48 eight-byte glyphs. The tile code IS the "
     "ASCII, so they run from 0x30 («0») to 0x5F, and after the Z come the "
     "menu's «with» and the two cursor arrows"),
]

CAPTURAS = [
    ("partida.png",
     "CAPTURA de openMSX: la primera pantalla, con el cartel de BABYLAND PARK, "
     "los bebés creciendo en repollos y el nombre del muñeco abajo a la "
     "izquierda",
     "A CAPTURE from openMSX: the first screen, with the BABYLAND PARK sign, "
     "the babies growing in cabbages and the kid's name at the bottom left"),
    ("muneco.png",
     "CAPTURA: la primera de las dos pantallas de preparación, la de elegir el "
     "muñeco. Las cuatro teclas que dice son las que lee 0x79BA",
     "A CAPTURE: the first of the two set-up screens, where you choose the "
     "kid. The four keys it names are the ones 0x79BA reads"),
    ("nombre.png",
     "CAPTURA: la segunda, con el nombre de fábrica. Las diez letras viven en "
     "0xE05D y se recorren en redondo",
     "A CAPTURE: the second one, with the factory name. The ten letters live "
     "at 0xE05D and cycle round"),
]


def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def galeria(imgdir, entradas, idioma, faltan):
    imgs = ""
    for fich, es, en in entradas:
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    return imgs


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    logo = os.path.join(imgdir, "titulo.png")
    cabecera = (f'<img src="{img64(logo)}" alt="Cabbage Patch Kids">'
                if os.path.exists(logo) else "<h1>Cabbage Patch Kids</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    faltan = []
    imgs = galeria(imgdir, GALERIA + CAPTURAS, idioma, faltan)
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' · '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
