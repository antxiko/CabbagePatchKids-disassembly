#!/usr/bin/env python3
"""Lleva las anotaciones de un cartucho a su hermano, alineando el CODIGO.

Hyper Olympic 1 y 2 son el mismo programa con trozos metidos y quitados: las
rutinas son las mismas pero han caido en otra direccion. Comparar bytes crudos
no sirve, porque los operandos llevan direcciones. Aqui se decodifican las dos
ROM con sus trazados, se normaliza cada instruccion -los operandos de dieciseis
bits a cero- y se alinean las dos listas con difflib. De la alineacion sale una
tabla direccion_de_A -> direccion_de_B con la que se mueven las L, las C y las B.

Lo que NO se porta: las D y las F. Los bloques de datos hay que volver a
localizarlos con las herramientas de recorrido, porque su contenido cambia.

Uso: porta_notas.py <romA> <trazaA> <notasA> <romB> <trazaB> <salida> [org]
"""
import difflib
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from z80trace import Tracer                                   # noqa: E402

ABS16 = ({0x01, 0x11, 0x21, 0x31, 0x22, 0x2A, 0x32, 0x3A, 0xC3, 0xCD}
         | {0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA}
         | {0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC})


def instrucciones(rompath, trazapath, org):
    rom = open(rompath, "rb").read()
    t = Tracer(rom, org)
    out = []
    for k, a, b in json.load(open(trazapath))["blocks"]:
        if k != "c":
            continue
        p = a
        while p < b:
            n = t.ilen(p)
            if not n or p + n > b:
                break
            q = bytearray(rom[p - org:p - org + n])
            op = q[0]
            if op in ABS16 and n >= 3:
                q[-2] = q[-1] = 0
            elif op in (0xDD, 0xFD) and n >= 4 and q[1] in ABS16:
                q[-2] = q[-1] = 0
            elif op == 0xED and n == 4:
                q[-2] = q[-1] = 0
            out.append((p, bytes(q)))
            p += n
    return out


def main():
    ra, ta, na, rb, tb, sal = sys.argv[1:7]
    org = int(sys.argv[7], 0) if len(sys.argv) > 7 else 0x4000
    A = instrucciones(ra, ta, org)
    B = instrucciones(rb, tb, org)
    sm = difflib.SequenceMatcher(None, [x[1] for x in A], [x[1] for x in B],
                                 autojunk=False)
    mapa = {}
    iguales = 0
    for i, j, n in sm.get_matching_blocks():
        for k in range(n):
            mapa[A[i + k][0]] = B[j + k][0]
        iguales += n
    print("  %d instrucciones en A, %d en B, %d alineadas (%.1f %% de A)"
          % (len(A), len(B), iguales, 100.0 * iguales / len(A)))

    salen, perdidas = [], []
    for raw in open(na, encoding="utf-8"):
        ln = raw.rstrip("\n")
        m = re.match(r"^([LCB]) (0x[0-9A-Fa-f]+)(.*)$", ln)
        if not m:
            continue
        d = int(m.group(2), 0)
        if d in mapa:
            salen.append("%s 0x%04x%s" % (m.group(1), mapa[d], m.group(3)))
        else:
            perdidas.append(ln)
    with open(sal, "w", encoding="utf-8") as f:
        f.write("\n".join(salen) + "\n")
    print("  %d anotaciones portadas, %d sin sitio en el hermano"
          % (len(salen), len(perdidas)))
    if perdidas:
        with open(sal + ".perdidas", "w", encoding="utf-8") as f:
            f.write("\n".join(perdidas) + "\n")
        print("  las que no llegaron estan en %s.perdidas" % sal)


main()
