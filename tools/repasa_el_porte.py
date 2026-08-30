#!/usr/bin/env python3
"""Caza las anotaciones que vienen del cartucho hermano y aqui son mentira.

    python3 tools/repasa_el_porte.py [<rom del hermano> <notas del hermano>]

DE DONDE SALE ESTO. Cabbage Patch Kids es el motor de Athletic Land recompilado:
las mismas rutinas en otras direcciones. Las anotaciones se trajeron con
tools/porta_desde_athletic.py, que alinea las dos listas de instrucciones y
mueve cada L, C y B a la direccion que le toca aqui. Eso pone el comentario en
el sitio correcto, pero **no cambia lo que dice**. Un comentario que alli era
verdad puede ser mentira aqui, y el reensamblado no lo va a notar: los bytes
salen identicos igual, porque un comentario no es un byte.

LO QUE COMPRUEBA, y ninguna es heuristica:

  1. CITAS SIN TRADUCIR. El porte deja marcadas `<<?0xNNNN>>` las direcciones
     que no supo mover. Cada una es una mentira segura.

  2. DIRECCIONES CITADAS QUE AQUI NO EXISTEN. Un comentario que dice "0x5A4B"
     esta senalando un sitio, y ese sitio tiene que ser aqui el arranque de una
     instruccion o caer dentro de un rango de datos declarado. Si cae en medio
     de una instruccion, viene del hermano.

  3. EL NOMBRE DEL OTRO JUEGO, y el numero de catalogo del otro cartucho.

  4. CIFRAS PORTADAS. Si un comentario de aqui es IDENTICO a uno del hermano,
     las dos instrucciones que anotan tienen que ser tambien iguales una vez
     puestos a cero los operandos de dieciseis bits, que son direcciones y
     cambian de sitio por definicion. Si el mnemonico o un inmediato de ocho
     bits difieren, el comentario esta describiendo la instruccion del hermano
     y casi seguro publica una cifra que aqui es falsa.

     Se mira la instruccion anotada Y LA SIGUIENTE, porque el caso caro es
     justo ese: el comentario cuelga de un `ld hl,nn` -que normalizado es
     igual en los dos cartuchos- y la cifra de la que habla esta en el
     `ld bc,nn` de debajo. Asi salieron las cinco cuentas de tiles de
     0x6CA2, que aqui son otras.

     Esto NO demuestra que el comentario mienta: es la lista de sitios donde el
     porte pudo colar una cifra, para MIRARLOS uno a uno.

Sale con 1 si hay algo de 1, 2, 3 o 4; los de 5 son avisos que hay que mirar.
"""
import json
import os
import re
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(AQUI)
sys.path.insert(0, AQUI)
from z80trace import Tracer                                   # noqa: E402

ORG, FIN = 0x4000, 0x8000
NOTAS = os.path.join(RAIZ, "src", "cabbagepatch.notes")
ROM = os.path.join(RAIZ, "cabbagepatch.rom")
TRAZA = os.path.join(RAIZ, "work", "cabbagepatch.trace.json")
DOCS = os.path.join(RAIZ, "docs")

HERMANO_ROM = os.path.join(RAIZ, "..", "ATHLETIC_DISAM", "athletic.rom")
HERMANO_TRAZA = os.path.join(RAIZ, "..", "ATHLETIC_DISAM", "work", "athletic.trace.json")
HERMANO_NOTAS = os.path.join(RAIZ, "..", "ATHLETIC_DISAM", "src", "athletic.notes")

# El hermano de armazon y su numero de catalogo. Nombrarlo en el listado o en
# una pagina que no sea la de hallazgos es un copia y pega.
OTRO = ("Athletic Land", "ATHLETIC LAND", "RC-700")

ABS16 = ({0x01, 0x11, 0x21, 0x31, 0x22, 0x2A, 0x32, 0x3A, 0xC3, 0xCD}
         | {0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA}
         | {0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC})
# Los saltos relativos tambien llevan una direccion dentro (el desplazamiento),
# y cambia en cuanto el codigo de al lado no mide igual. Si no se pone a cero,
# la mitad de las instrucciones del cartucho parecen distintas.
REL8 = {0x10, 0x18, 0x20, 0x28, 0x30, 0x38}


def mapa_de(rompath, trazapath):
    """arranques de instruccion y bytes de datos declarados por el trazado."""
    rom = open(rompath, "rb").read()
    t = Tracer(rom, ORG)
    arranques, datos, normal = set(), set(), {}
    for k, a, b in json.load(open(trazapath))["blocks"]:
        if k == "c":
            p = a
            while p < b:
                n = t.ilen(p)
                if not n:
                    break
                arranques.add(p)
                q = bytearray(rom[p - ORG:p - ORG + n])
                op = q[0]
                if op in ABS16 and n >= 3:
                    q[-2] = q[-1] = 0
                elif op in (0xDD, 0xFD) and n >= 4 and q[1] in ABS16:
                    q[-2] = q[-1] = 0
                elif op == 0xED and n == 4:
                    q[-2] = q[-1] = 0
                elif op in REL8 and n == 2:
                    q[1] = 0
                normal[p] = bytes(q)
                p += n
        else:
            datos.update(range(a, b))
    return arranques, datos, normal


def comentarios(path):
    """{direccion: texto} de las directivas C, y las L/B aparte."""
    C, otras = {}, []
    for ln in open(path, encoding="utf-8"):
        ln = ln.rstrip("\n")
        m = re.match(r"^C (0x[0-9A-Fa-f]+) (.*)$", ln)
        if m:
            C[int(m.group(1), 0)] = m.group(2).strip()
        elif re.match(r"^[LBD] ", ln):
            otras.append(ln)
    return C, otras


def siguiente(normal, a):
    """La instruccion de despues, normalizada."""
    ds = sorted(k for k in normal if k > a)
    return normal[ds[0]] if ds else None


def main():
    mal = 0
    texto = open(NOTAS, encoding="utf-8").read()
    lineas = texto.splitlines()

    print("== 1. citas que el porte no supo traducir")
    n = 0
    for i, l in enumerate(lineas, 1):
        for m in re.finditer(r"<<\?(0x[0-9A-Fa-f]{4})>>", l):
            print("   linea %d: %s   en: %s" % (i, m.group(1), l[:90]))
            n += 1
    print("   %d" % n)
    mal += n

    print("== 2. direcciones citadas que aqui no existen")
    arranques, datos, normal = mapa_de(ROM, TRAZA)
    rangos = [(int(a, 0), int(b, 0)) for a, b in
              re.findall(r"^D (0x\w+) (0x\w+)", texto, re.M)]
    declarados = set()
    for a, b in rangos:
        declarados.update(range(a, b))
    n = 0
    for i, l in enumerate(lineas, 1):
        if l.startswith("D "):
            cuerpo = " ".join(l.split()[3:])
        else:
            cuerpo = l
        for m in re.finditer(r"0x([0-9A-Fa-f]{4})", cuerpo):
            v = int(m.group(1), 16)
            if not ORG <= v < FIN:
                continue
            if v in arranques or v in declarados or v in datos:
                continue
            print("   linea %d: 0x%04X no es ni instruccion ni dato declarado | %s"
                  % (i, v, l[:80]))
            n += 1
    print("   %d" % n)
    mal += n

    print("== 3. el otro juego, nombrado donde no toca")
    n = 0
    for sitio in [NOTAS] + [os.path.join(r, f) for r, _, fs in os.walk(DOCS)
                            for f in fs if f.endswith(".md")]:
        base = os.path.basename(sitio)
        if base in ("FINDINGS.md", "HALLAZGOS.md"):
            continue          # ahi el asunto ES lo que se comparte
        try:
            t = open(sitio, encoding="utf-8").read()
        except OSError:
            continue
        for i, l in enumerate(t.splitlines(), 1):
            # los tres bloques de datos que el cartucho arrastra del hermano SI
            # se nombran: es justo lo que dicen
            if "resto_" in l or "restos_" in l:
                continue
            for nombre in OTRO:
                if nombre in l:
                    print("   %s:%d nombra %s" % (base, i, nombre))
                    n += 1
    print("   %d" % n)
    mal += n

    print("== 4. direcciones de RAM citadas que la instruccion no carga")
    n = 0
    rom = open(ROM, "rb").read()
    t = Tracer(rom, ORG)
    C, _ = comentarios(NOTAS)
    for a, txt in sorted(C.items()):
        if a not in arranques:
            continue
        largo = t.ilen(a)
        cita = set(re.findall(r"(?:0x)?([EF][0-9A-Fa-f]{3})", txt))
        if len(cita) != 1 or largo < 3:
            continue
        op = rom[a - ORG]
        if op not in ABS16:
            continue
        valor = rom[a - ORG + largo - 2] | (rom[a - ORG + largo - 1] << 8)
        if valor < 0xC000:
            continue
        dice = int(cita.pop(), 16)
        if dice != valor:
            print("   0x%04X dice %04X y la instruccion carga %04X | %s"
                  % (a, dice, valor, txt[:70]))
            n += 1
    print("   %d" % n)
    mal += n

    print("== 5. comentarios identicos al hermano sobre otra instruccion")
    if not os.path.exists(HERMANO_TRAZA):
        print("   (no esta el trazado del hermano; se salta)")
        return 1 if mal else 0
    _, _, normalH = mapa_de(HERMANO_ROM, HERMANO_TRAZA)
    CH, _ = comentarios(HERMANO_NOTAS)
    C, _ = comentarios(NOTAS)
    porTexto = {}
    for a, t in CH.items():
        porTexto.setdefault(t, []).append(a)
    iguales = sospechosos = 0
    for a, t in sorted(C.items()):
        if t not in porTexto:
            continue
        iguales += 1
        aqui = normal.get(a)
        if aqui is None:
            continue
        sig = siguiente(normal, a)
        vale = False
        for b in porTexto[t]:
            if normalH.get(b) != aqui:
                continue
            if sig is None or siguiente(normalH, b) is None or siguiente(normalH, b) == sig:
                vale = True
                break
        if vale:
            continue
        print("   0x%04X: %s" % (a, t[:88]))
        sospechosos += 1
    print("   %d comentarios identicos al hermano, %d sobre otra instruccion"
          % (iguales, sospechosos))
    return 1 if mal else 0


if __name__ == "__main__":
    sys.exit(main())
