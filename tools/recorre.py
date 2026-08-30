#!/usr/bin/env python3
"""Recorre los bloques de datos con el MISMO formato que usa el cartucho.

    python3 tools/recorre.py [<rom> <trace.json>]

Un rango de datos no se declara porque sobre: se declara porque hay una
instruccion que lo lee y porque, leido con el formato que esa instruccion
espera, CIERRA donde tiene que cerrar. Esto hace las dos cosas:

  1. Busca las llamadas a los cinco consumidores de datos del cartucho,
     recorriendo SOLO inicios de instruccion del trazado (leer desde el byte
     de en medio de una instruccion inventa punteros), y para cada una recoge
     los `ld hl/de/bc,nn` inmediatamente anteriores:

        0x4502  COPIA_A_VRAM      HL origen, DE VRAM, BC cuantos  -> rango exacto
        0x4522  RELLENA_VRAM      no lee ROM (rellena con A)
        0x4D24  RLE_A_VRAM        HL = [VRAM de 2 bytes][flujo RLE]
        0x4D28  RLE_A_VRAM_DE     HL = flujo RLE, DE la VRAM
        0x45E7  PINTA_LISTA       HL = [VRAM][tiles...] 0xFE otra VRAM, 0xFF fin
        0x59BC  MOTOR_DE_ROTULOS  los SEIS bytes que van detras del call:
                                  lista, tiles y VRAM
        0x5A1B  RELLENA_CADA_32   HL = B bytes, uno por fila

  2. Recorre cada bloque con su formato y dice DONDE ACABA. Si un flujo RLE
     no termina en su 0x00, o una lista no da con su 0xFF, el rango estaba mal
     y se dice; no se apunta un final a ojo.

La salida son lineas `D` listas para el fichero de notas, cada una con la
direccion de la instruccion que la justifica.
"""
import json
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(AQUI)
sys.path.insert(0, AQUI)
from z80trace import Tracer                                   # noqa: E402

ORG, FIN = 0x4000, 0x8000

COPIA_A_VRAM = 0x4502
RELLENA_VRAM = 0x4522
RLE_A_VRAM = 0x4D24
RLE_A_VRAM_DE = 0x4D28
PINTA_LISTA = 0x45E7
MOTOR = 0x59BC
RELLENA_CADA_32 = 0x5A1B

LD_INM = {0x21: "hl", 0x11: "de", 0x01: "bc", 0x06: "b"}


def instrucciones(rom, traza):
    """Los inicios de instruccion del codigo trazado, en orden."""
    t = Tracer(rom, ORG)
    out = []
    for k, a, b in json.load(open(traza))["blocks"]:
        if k != "c":
            continue
        p = a
        while p < b:
            n = t.ilen(p)
            if not n or p + n > b:
                break
            out.append((p, n))
            p += n
    return out


def rle(rom, a):
    """0 fin; n<0x80 repite n veces el byte siguiente; n>=0x80 copia n&0x7F.
    Devuelve (fin, bytes escritos) o (None, motivo)."""
    p, esc = a - ORG, 0
    while True:
        if not 0 <= p < len(rom):
            return None, "se sale del cartucho"
        n = rom[p]
        p += 1
        if n == 0:
            return p + ORG, esc
        if n & 0x80:
            k = n & 0x7F
            p += k
            esc += k
        else:
            p += 1
            esc += n


def lista_de_tiles(rom, a):
    """PINTA_LISTA: palabra de VRAM y tiles hasta 0xFF; 0xFE arranca otra."""
    p, n = a - ORG + 2, 0
    while True:
        if not 0 <= p < len(rom):
            return None, "se sale del cartucho"
        v = rom[p]
        p += 1
        if v == 0xFF:
            return p + ORG, n
        if v == 0xFE:
            p += 2
            continue
        n += 1


def motor(rom, lista, tiles):
    """El motor de rotulos: cuenta con bit 7 = relleno de un tile, 0x80 =
    direccion nueva, 0 = fin. Devuelve (fin de la lista, fin de los tiles)."""
    lp, tp = lista - ORG, tiles - ORG
    while True:
        if not 0 <= lp < len(rom):
            return None, "la lista se sale del cartucho"
        n = rom[lp]
        if n == 0x80:
            lp += 3
            n = rom[lp]
        if n == 0:
            return lp + 1 + ORG, tp + ORG
        c = n & 0x7F
        tp += 1 if n & 0x80 else c
        lp += 1


def main():
    rom = open(os.path.join(RAIZ, sys.argv[1] if len(sys.argv) > 1
                            else "cabbagepatch.rom"), "rb").read()
    traza = os.path.join(RAIZ, sys.argv[2] if len(sys.argv) > 2
                         else "work/cabbagepatch.trace.json")
    ins = instrucciones(rom, traza)
    pos = {a: i for i, (a, _) in enumerate(ins)}

    def antes(i, reg, cuantas=14):
        """El ultimo `ld <reg>,nn` en las instrucciones anteriores a i."""
        for j in range(i - 1, max(-1, i - cuantas) - 1, -1):
            a, n = ins[j]
            op = rom[a - ORG]
            if LD_INM.get(op) == reg and n == 3:
                return rom[a - ORG + 1] | (rom[a - ORG + 2] << 8)
            if LD_INM.get(op) == reg and n == 2:
                return rom[a - ORG + 1]
        return None

    salida = []
    for i, (a, n) in enumerate(ins):
        if rom[a - ORG] != 0xCD:
            continue
        dst = rom[a - ORG + 1] | (rom[a - ORG + 2] << 8)
        if dst == COPIA_A_VRAM:
            src, cuantos = antes(i, "hl"), antes(i, "bc")
            if src is None or cuantos is None or not ORG <= src < FIN:
                continue
            salida.append((src, src + cuantos, "copia", a,
                           "%d bytes copiados a la VRAM %s"
                           % (cuantos, "0x%04X" % antes(i, "de")
                              if antes(i, "de") is not None else "?")))
        elif dst in (RLE_A_VRAM, RLE_A_VRAM_DE):
            src = antes(i, "hl")
            if src is None or not ORG <= src < FIN:
                continue
            ini = src + (2 if dst == RLE_A_VRAM else 0)
            fin, esc = rle(rom, ini)
            if fin is None:
                salida.append((src, src, "RLE ROTO", a, esc))
                continue
            salida.append((src, fin, "rle", a,
                           "flujo RLE que descomprime %d bytes de VRAM" % esc))
        elif dst == PINTA_LISTA:
            src = antes(i, "hl")
            if src is None or not ORG <= src < FIN:
                continue
            fin, cuantos = lista_de_tiles(rom, src)
            if fin is None:
                salida.append((src, src, "LISTA ROTA", a, cuantos))
                continue
            salida.append((src, fin, "lista", a,
                           "lista de %d tiles con su direccion de VRAM delante" % cuantos))
        elif dst == MOTOR:
            p = a + 3 - ORG
            lista = rom[p] | (rom[p + 1] << 8)
            tiles = rom[p + 2] | (rom[p + 3] << 8)
            vram = rom[p + 4] | (rom[p + 5] << 8)
            salida.append((a + 3, a + 9, "parametros", a,
                           "los seis bytes del call: lista 0x%04X, tiles 0x%04X, VRAM 0x%04X"
                           % (lista, tiles, vram)))
            if not (ORG <= lista < FIN and ORG <= tiles < FIN):
                continue
            fl, ft = motor(rom, lista, tiles)
            if fl is None:
                salida.append((lista, lista, "MOTOR ROTO", a, ft))
                continue
            salida.append((lista, fl, "motor-lista", a,
                           "lista del motor de rotulos (tiles en 0x%04X, VRAM 0x%04X)"
                           % (tiles, vram)))
            salida.append((tiles, ft, "motor-tiles", a,
                           "los tiles que reparte la lista de 0x%04X" % lista))
        elif dst == RELLENA_CADA_32:
            src, b = antes(i, "hl"), antes(i, "b")
            if src is None or b is None or not ORG <= src < FIN:
                continue
            salida.append((src, src + b, "cada32", a,
                           "%d bytes, uno por fila de 32 de la VRAM" % b))

    vistos = {}
    for ini, fin, clase, sitio, texto in salida:
        vistos.setdefault((ini, fin, clase), []).append(sitio)
    print("%d bloques distintos, de %d llamadas\n" % (len(vistos), len(salida)))
    for (ini, fin, clase) in sorted(vistos):
        sitios = vistos[(ini, fin, clase)]
        texto = next(t for i2, f2, c2, s2, t in salida
                     if (i2, f2, c2) == (ini, fin, clase))
        print("0x%04X 0x%04X  %-12s %5d B  <- %s   %s"
              % (ini, fin, clase, fin - ini,
                 " ".join("0x%04X" % s for s in sorted(set(sitios))), texto))

    # Solapes: dos bloques que se pisan son una lectura mala de alguno.
    print()
    plano = sorted((i, f, c) for (i, f, c) in vistos)
    for (a1, b1, c1), (a2, b2, c2) in zip(plano, plano[1:]):
        if b1 > a2:
            print("  SOLAPE: 0x%04X-0x%04X (%s) pisa 0x%04X-0x%04X (%s)"
                  % (a1, b1, c1, a2, b2, c2))


if __name__ == "__main__":
    main()
