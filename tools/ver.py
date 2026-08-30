#!/usr/bin/env python3
"""Ensena un trozo del listado alrededor de una direccion.

    python3 tools/ver.py 0x4629 [lineas_antes] [lineas_despues]
    python3 tools/ver.py 0x4629 0x4640          (un rango de direcciones)

Es para mirar el codigo mientras se comenta, sin sacar medio fichero por la
consola.
"""
import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASM = os.path.join(RAIZ, "src", "cabbagepatch.asm")


def main():
    lineas = open(ASM, encoding="utf-8").read().splitlines()
    dirs = []
    for i, l in enumerate(lineas):
        m = re.search(r";([0-9a-f]{4})(?:\s|$)", l)
        dirs.append((int(m.group(1), 16), i) if m else (None, i))
    a = int(sys.argv[1], 0)
    if len(sys.argv) > 2 and sys.argv[2].startswith("0x"):
        b = int(sys.argv[2], 0)
        ini = next(i for d, i in dirs if d is not None and d >= a)
        fin = next((i for d, i in dirs if d is not None and d >= b), len(lineas))
    else:
        antes = int(sys.argv[2]) if len(sys.argv) > 2 else 6
        despues = int(sys.argv[3]) if len(sys.argv) > 3 else 18
        pos = next(i for d, i in dirs if d is not None and d >= a)
        ini, fin = max(0, pos - antes), min(len(lineas), pos + despues)
    for l in lineas[ini:fin]:
        print(l[:120])


if __name__ == "__main__":
    main()
