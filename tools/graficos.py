#!/usr/bin/env python3
"""Rehace la VRAM del cartucho y la pinta en PNG. Ninguna imagen es una captura.

    python3 tools/graficos.py cabbagepatch.rom docs/imagenes

Aqui no se dibuja "lo que parece": se repiten, en el mismo orden y con las
mismas direcciones, las copias que hace la ROM. La lista sale del listado:

  CARGA_FUENTE (0x461E) sube los 48 glifos de 0x4A37 al tercio de en medio y
  0x4635 los reparte por los otros dos; CARGA_PATRONES_Y_COLORES (0x6CA2) sube
  los patrones y luego los COLORES, que van comprimidos por rachas (el RLE de
  0x4D24, con la direccion de VRAM delante); CARGA_LOS_SPRITES (0x76EF)
  descomprime los seis flujos de la tabla de 0x55F5 y dos mas en la tabla de
  patrones de sprite; y PANTALLA_DEL_TITULO (0x480F) redefine los tiles del
  logotipo y les repite dieciseis bytes de color diecisiete veces.

Si un rango estuviera mal etiquetado, saldria ruido. Que salgan dibujos es la
comprobacion.

El mapa de la VRAM sale de los ocho registros de 0x44F1 (R2=0x0E, R3=0x7F,
R4=0x07, R6=0x03): nombres en 0x3800, colores en 0x0000, patrones en 0x2000 y
patrones de sprite en 0x1800.
"""
import os
import struct
import sys
import zlib

ORG = 0x4000
# La paleta del TMS9918, con el 0 transparente pintado como el fondo.
PAL = [(0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120),
       (84, 85, 237), (125, 118, 252), (212, 82, 77), (66, 235, 245),
       (252, 85, 84), (255, 121, 120), (212, 193, 84), (230, 206, 128),
       (33, 176, 59), (201, 91, 186), (204, 204, 204), (255, 255, 255)]
REJA = (56, 56, 74)


def png(w, h, filas, fn):
    raw = b"".join(b"\x00" + bytes(v for p in f for v in p) for f in filas)

    def chunk(t, d):
        return (struct.pack(">I", len(d)) + t + d
                + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF))
    with open(fn, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n"
                + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


class VRAM:
    """Los 16 KB de memoria de video, y las tres formas que tiene el cartucho
    de escribir en ella."""

    def __init__(self, rom):
        self.m = bytearray(0x4000)
        self.rom = rom

    def copia(self, src, dst, n):                      # 0x4502
        self.m[dst:dst + n] = self.rom[src - ORG:src - ORG + n]

    def rellena(self, dst, n, v):                      # 0x4522
        self.m[dst:dst + n] = bytes([v]) * n

    def espeja(self, src, dst, n):                     # 0x6DC1
        """B bytes con los ocho bits de cada uno al reves. B=0 son 256."""
        n = n or 256
        for i in range(n):
            b = self.rom[src - ORG + i]
            self.m[dst + i] = int("{:08b}".format(b)[::-1], 2)

    def rle(self, src, dst=None):                      # 0x4D24 / 0x4D28
        """0 acaba; con el bit 7 se copian n&0x7F bytes tal cual; sin el, se
        repite n veces el byte siguiente. Con dst a None, los dos primeros
        bytes del flujo son la direccion de destino."""
        p = src - ORG
        if dst is None:
            dst = (self.rom[p] | (self.rom[p + 1] << 8)) & 0x3FFF
            p += 2
        else:
            dst &= 0x3FFF
        while True:
            n = self.rom[p]
            p += 1
            if n == 0:
                return dst
            if n & 0x80:
                k = n & 0x7F
                self.m[dst:dst + k] = self.rom[p:p + k]
                p += k
                dst += k
            else:
                self.m[dst:dst + n] = bytes([self.rom[p]]) * n
                p += 1
                dst += n


def carga_la_fuente(v):
    """CARGA_FUENTE (0x461E) y el reparto de 0x4635."""
    v.rellena(0x0180, 0x180, 0xF0)          # blanco sobre transparente
    v.copia(0x4A37, 0x2180, 0x180)          # los 48 glifos
    # 0x4635 sube ocho bytes por tile subiendo el codigo 0x11 cada vuelta: es
    # lo que deja la misma fuente en los tres tercios.
    v.m[0x2800:0x3000] = v.m[0x2000:0x2800]
    v.m[0x3000:0x3800] = v.m[0x2000:0x2800]
    v.m[0x0800:0x1000] = v.m[0x0000:0x0800]
    v.m[0x1000:0x1800] = v.m[0x0000:0x0800]


def carga_el_juego(v):
    """CARGA_PATRONES_Y_COLORES (0x6CA2), copia a copia."""
    v.copia(0x6EDD, 0x2080, 0x100)
    v.copia(0x6FDD, 0x2300, 0x0A0)
    v.espeja(0x6FDD, 0x23A0, 0x30)
    v.copia(0x707D, 0x2600, 0x0C0)
    v.espeja(0x70A5, 0x26C0, 0x00)          # ld bc,0x0018 deja B=0: 256 bytes
    v.copia(0x713D, 0x2700, 0x040)
    v.espeja(0x713D, 0x2740, 0x30)
    for a in (0x6DD3, 0x6E6B):              # con la VRAM delante
        v.rle(a)
    v.rle(0x6E6D, 0x03A0)
    v.rle(0x6E88)
    v.rle(0x6E9A, 0x06C0)
    v.rle(0x6EC0)
    v.rle(0x6EC2, 0x0740)
    v.copia(0x4E07, 0x2B00, 0x0F0)
    v.espeja(0x4E07, 0x2BF0, 0xF0)
    v.copia(0x4DDF, 0x2580, 0x038)
    v.espeja(0x4DDF, 0x25B8, 0x30)
    v.copia(0x4EF7, 0x2D10, 0x0F0)
    v.copia(0x4FE7, 0x2E00, 0x088)
    v.espeja(0x4FE7, 0x2E88, 0x50)
    v.rellena(0x0B00, 0x1E0, 0xF5)
    v.rellena(0x0580, 0x068, 0xF5)
    v.copia(0x506F, 0x0D10, 0x058)
    v.rellena(0x0D68, 0x098, 0xF5)
    v.copia(0x50C7, 0x0E00, 0x088)
    v.copia(0x50C7, 0x0E88, 0x050)


def carga_los_sprites(v):
    """CARGA_LOS_SPRITES (0x76EF): los seis flujos de la tabla de 0x55F5 y dos
    mas, en la tabla de patrones de sprite (0x1800)."""
    tabla = 0x55F5
    dst = 0x1A00
    for i in range(6):
        p = tabla - ORG + i * 2
        v.rle(v.rom[p] | (v.rom[p + 1] << 8), dst)
        dst += 0x80
    v.rle(0x7342, 0x1E20)
    v.rle(0x7475, 0x1E60)
    v.rle(0x7840)


def pantalla_del_titulo(v):
    """PANTALLA_DEL_TITULO (0x480F): el logotipo y sus colores."""
    v.rle(0x4894)                            # patrones, con la VRAM delante
    dst = 0x0400
    for _ in range(0x18):                    # diecisiete filas de 16 colores
        v.rle(0x4A2B, dst)
        dst += 0x10
    v.rellena(0x0580, 0x010, 0xC0)
    v.rellena(0x1180, 0x170, 0x70)           # la fuente del menu, en cyan


def tile(v, tercio, t, esc=2):
    pat = v.m[0x2000 + tercio * 0x800 + t * 8:][:8]
    col = v.m[0x0000 + tercio * 0x800 + t * 8:][:8]
    filas = []
    for r in range(8):
        fg, bg = PAL[col[r] >> 4], PAL[col[r] & 15]
        fila = []
        for b in range(8):
            fila += [fg if (pat[r] >> (7 - b)) & 1 else bg] * esc
        filas += [fila] * esc
    return filas


def hoja_de_tiles(v, fn, esc=2):
    W = 32 * (8 * esc + 1)
    out = []
    for tercio in range(3):
        for fila in range(8):
            filas = [[REJA] * W for _ in range(8 * esc)]
            for c in range(32):
                px = tile(v, tercio, fila * 32 + c, esc)
                x0 = c * (8 * esc + 1)
                for r in range(8 * esc):
                    filas[r][x0:x0 + 8 * esc] = px[r]
            out += filas + [[REJA] * W]
        out += [[(120, 40, 40)] * W] * 2
    png(W, len(out), out, fn)


def hoja_de_sprites(v, fn, esc=3):
    """Los 64 patrones de 16x16 de 0x1800. El color no esta aqui: lo pone la
    ficha de cada sprite, asi que salen en blanco."""
    W = 16 * (16 * esc + 1)
    out = []
    for fila in range(4):
        filas = [[REJA] * W for _ in range(16 * esc)]
        for c in range(16):
            d = v.m[0x1800 + (fila * 16 + c) * 32:][:32]
            for r in range(16):
                bits = (d[r] << 8) | d[16 + r]
                for b in range(16):
                    col = (255, 255, 255) if (bits >> (15 - b)) & 1 else (0, 0, 0)
                    for dy in range(esc):
                        for dx in range(esc):
                            filas[r * esc + dy][c * (16 * esc + 1) + b * esc + dx] = col
        out += filas + [[REJA] * W]
    png(W, len(out), out, fn)


def rotulo(v, fn, tiles, ancho, esc=3, tercio=0):
    """Una tira de tiles seguidos, tal como el cartucho los pinta en pantalla."""
    alto = (len(tiles) + ancho - 1) // ancho
    W, H = ancho * 8 * esc, alto * 8 * esc
    out = [[(0, 0, 0)] * W for _ in range(H)]
    for i, t in enumerate(tiles):
        px = tile(v, tercio, t, esc)
        x0, y0 = (i % ancho) * 8 * esc, (i // ancho) * 8 * esc
        for r in range(8 * esc):
            out[y0 + r][x0:x0 + 8 * esc] = px[r]
    png(W, H, out, fn)


def main(argv):
    rom = open(argv[1] if len(argv) > 1 else "cabbagepatch.rom", "rb").read()
    salida = argv[2] if len(argv) > 2 else "docs/imagenes"
    os.makedirs(salida, exist_ok=True)

    # 1. La pantalla del titulo: la fuente, el logotipo y sus colores.
    v = VRAM(rom)
    carga_la_fuente(v)
    pantalla_del_titulo(v)
    # El logotipo lo pinta TITULO_COLUMNA (0x4850) columna a columna: en la
    # columna n van los tiles 0x80+2n (fila 3) y 0x81+2n (fila 4), y son
    # VEINTICUATRO columnas (el `cp 018h` de 0x4855).
    #
    # Y hay una TERCERA fila que es facil pasar por alto: 0x4872 mira en que
    # columna esta -`sub 0ABh / cp 002h`- y solo en las columnas 7 y 8 escribe
    # los tiles 0xB0 y 0xB1; en las demas, el tile 0. Esos dos son la cola de
    # la "g" de Cabbage, que sin ellos sale cortada.
    fila1 = [0x80 + 2 * n for n in range(24)]
    fila2 = [0x81 + 2 * n for n in range(24)]
    fila3 = [0xB0 + (n - 7) if n in (7, 8) else 0 for n in range(24)]
    rotulo(v, os.path.join(salida, "titulo.png"), fila1 + fila2 + fila3, 24)

    # 2. Los graficos del juego.
    v = VRAM(rom)
    carga_la_fuente(v)
    carga_el_juego(v)
    carga_los_sprites(v)
    hoja_de_tiles(v, os.path.join(salida, "tiles.png"))
    hoja_de_sprites(v, os.path.join(salida, "sprites.png"))

    # 3. La fuente sola, que es donde se ve que el codigo de tile ES el ASCII.
    v2 = VRAM(rom)
    carga_la_fuente(v2)
    rotulo(v2, os.path.join(salida, "fuente.png"),
           list(range(0x30, 0x60)), 16, tercio=1)
    print("  %s: titulo.png, tiles.png, sprites.png y fuente.png" % salida)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
