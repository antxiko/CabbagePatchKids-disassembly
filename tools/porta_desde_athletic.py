#!/usr/bin/env python3
"""Trae las anotaciones de Athletic Land a Cabbage Patch Kids alineando el CODIGO.

Cabbage Patch Kids es el motor de Athletic Land recompilado con trozos metidos
y quitados: las rutinas son las mismas pero han caido en otra direccion.
Comparar bytes crudos no sirve, porque los operandos llevan direcciones. Aqui
se decodifican las dos ROM con sus trazados, se normaliza cada instruccion -los
operandos de dieciseis bits a cero- y se alinean las dos listas con difflib.

De la alineacion sale una tabla direccion_de_A -> direccion_de_B, y con ella:

  * las L, C y B se mueven a la direccion que les toca aqui;
  * los rangos D y las anchuras F se RELOCALIZAN: un rango de datos va entre
    dos trozos de codigo, y si los dos extremos caen en instrucciones alineadas
    (o a la misma distancia de una), el rango se traduce. Si el tamano cambia,
    se dice, y si un extremo no se puede traducir, se manda a revisar;
  * toda direccion 0xNNNN citada DENTRO de un texto se traduce tambien, y la
    que no se puede traducir queda marcada <<?0xNNNN>> para mirarla a mano.

Lo que sale es un BORRADOR: cada rango con tamano distinto o cuyos bytes ya no
son los mismos hay que volver a medirlo, y cada cifra de un comentario portado
hay que remedirla aqui (el codigo es el mismo; los datos no).

Uso: porta_desde_athletic.py <romA> <trazaA> <notasA> <romB> <trazaB> <salida>
"""
import difflib
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from z80trace import Tracer                                   # noqa: E402

ORG, FIN = 0x4000, 0x8000
ABS16 = ({0x01, 0x11, 0x21, 0x31, 0x22, 0x2A, 0x32, 0x3A, 0xC3, 0xCD}
         | {0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA}
         | {0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC})


def instrucciones(rom, trazapath):
    t = Tracer(rom, ORG)
    out = []
    for k, a, b in json.load(open(trazapath))["blocks"]:
        if k != "c":
            continue
        p = a
        while p < b:
            n = t.ilen(p)
            if not n or p + n > b:
                break
            q = bytearray(rom[p - ORG:p - ORG + n])
            op = q[0]
            if op in ABS16 and n >= 3:
                q[-2] = q[-1] = 0
            elif op in (0xDD, 0xFD) and n >= 4 and q[1] in ABS16:
                q[-2] = q[-1] = 0
            elif op == 0xED and n == 4:
                q[-2] = q[-1] = 0
            out.append((p, bytes(q), n))
            p += n
    return out


class Mapa:
    """direccion de A -> direccion de B, exacta para instrucciones alineadas y
    por desplazamiento local para lo que cae entre dos alineadas con el mismo
    delta a los dos lados."""

    def __init__(self, A, B, iguales):
        self.exacto = {}
        for i, j, n in iguales:
            for k in range(n):
                self.exacto[A[i + k][0]] = B[j + k][0]
        self.claves = sorted(self.exacto)
        self.finA = A[-1][0] + A[-1][2] if A else ORG
        self.finB = B[-1][0] + B[-1][2] if B else ORG

    def _vecinos(self, a):
        import bisect
        i = bisect.bisect_left(self.claves, a)
        antes = self.claves[i - 1] if i > 0 else None
        despues = self.claves[i] if i < len(self.claves) else None
        return antes, despues

    def traduce(self, a):
        """Devuelve (direccion en B, 'exacta'|'delta'|None)."""
        if a in self.exacto:
            return self.exacto[a], "exacta"
        if a == FIN:
            return FIN, "exacta"
        antes, despues = self._vecinos(a)
        da = self.exacto[antes] - antes if antes is not None else None
        dd = self.exacto[despues] - despues if despues is not None else None
        if da is not None and dd is not None and da == dd:
            return a + da, "delta"
        if a >= self.claves[-1]:
            # detras de la ultima instruccion alineada: el final del cartucho
            # es un punto fijo, asi que se traduce por el delta de la ultima
            return a + da, "delta"
        return None, None


def traduce_texto(texto, mapa, rangos):
    """Traduce las 0xNNNN citadas en un texto. `rangos` son los D ya traducidos
    de A (inicio -> inicio en B), para que una cita a un bloque de datos siga
    apuntando a su bloque."""
    sin = []

    def rep(m):
        v = int(m.group(1), 16)
        if not ORG <= v < FIN:
            return m.group(0)
        if v in rangos:
            return "0x%04X" % rangos[v]
        d, como = mapa.traduce(v)
        if d is None:
            sin.append(v)
            return "<<?0x%04X>>" % v
        return "0x%04X" % d
    return re.sub(r"0x([0-9A-Fa-f]{4})", rep, texto), sin


def main():
    ra, ta, na, rb, tb, sal = sys.argv[1:7]
    romA, romB = open(ra, "rb").read(), open(rb, "rb").read()
    A, B = instrucciones(romA, ta), instrucciones(romB, tb)
    sm = difflib.SequenceMatcher(None, [x[1] for x in A], [x[1] for x in B],
                                 autojunk=False)
    iguales = sm.get_matching_blocks()
    mapa = Mapa(A, B, iguales)
    alineadas = sum(n for _, _, n in iguales)
    print("  %d instrucciones en A, %d en B, %d alineadas (%.1f %% de A, %.1f %% de B)"
          % (len(A), len(B), alineadas, 100.0 * alineadas / len(A),
             100.0 * alineadas / len(B)))
    tramos = [(A[i][0], B[j][0], n) for i, j, n in iguales if n >= 20]
    print("  tramos alineados de 20+ instrucciones: %d" % len(tramos))
    for a, b, n in tramos[:60]:
        print("    A 0x%04X -> B 0x%04X  (%+d)  %d instr" % (a, b, b - a, n))

    # El codigo trazado de B: un rango de datos traducido que caiga encima es
    # una traduccion falsa (B ha reorganizado esa zona), no un dato.
    codigoB = set()
    for k, a, b in json.load(open(tb))["blocks"]:
        if k == "c":
            codigoB.update(range(a, b))

    # 1) Los rangos D primero, para que las citas a datos se traduzcan por bloque.
    lineas = [l.rstrip("\n") for l in open(na, encoding="utf-8")]
    rangosAB = {}
    salida, revisar, perdidas = [], [], []
    citas_sin = []
    for ln in lineas:
        m = re.match(r"^D (0x[0-9A-Fa-f]+) (0x[0-9A-Fa-f]+) (\S+)(.*)$", ln)
        if not m:
            continue
        a, b = int(m.group(1), 0), int(m.group(2), 0)
        a2, ca = mapa.traduce(a)
        b2, cb = mapa.traduce(b)
        nombre, desc = m.group(3), m.group(4)
        motivo = None
        if a2 is None or b2 is None or b2 <= a2:
            motivo = "SIN SITIO"
        elif a2 < ORG or b2 > FIN:
            motivo = "SE SALE DEL CARTUCHO"
        elif any(x in codigoB for x in range(a2, b2)):
            motivo = "CAE EN CODIGO"
        if motivo:
            revisar.append("D %s %s %s%s   # %s (A=%s B=%s)"
                           % (m.group(1), m.group(2), nombre, desc, motivo,
                              "0x%04X" % a2 if a2 else "?",
                              "0x%04X" % b2 if b2 else "?"))
            continue
        rangosAB[a] = a2
        iguales_bytes = romA[a - ORG:b - ORG] == romB[a2 - ORG:b2 - ORG]
        marca = ""
        if (b2 - a2) != (b - a):
            marca = "   # REVISAR: tamano %d -> %d" % (b - a, b2 - a2)
        elif not iguales_bytes:
            marca = "   # bytes distintos (mismo tamano)"
        salida.append((a2, "D 0x%04X 0x%04X %s%s%s" % (a2, b2, nombre, desc, marca)))
    # 2) Las F van con su D.
    for ln in lineas:
        m = re.match(r"^F (0x[0-9A-Fa-f]+) (.*)$", ln)
        if not m:
            continue
        a = int(m.group(1), 0)
        if a in rangosAB:
            salida.append((rangosAB[a], "F 0x%04X %s" % (rangosAB[a], m.group(2))))
        else:
            revisar.append(ln + "   # su D no se tradujo")
    # 3) L, C y B por la alineacion exacta de instrucciones.
    for ln in lineas:
        m = re.match(r"^([LCB]) (0x[0-9A-Fa-f]+)(.*)$", ln)
        if not m:
            continue
        d = int(m.group(2), 0)
        if d in mapa.exacto:
            texto, sin = traduce_texto(m.group(3), mapa, rangosAB)
            citas_sin += sin
            salida.append((mapa.exacto[d], "%s 0x%04X%s" % (m.group(1), mapa.exacto[d], texto)))
        elif d in rangosAB:
            # etiquetas puestas sobre un bloque de datos (L en un D)
            texto, sin = traduce_texto(m.group(3), mapa, rangosAB)
            citas_sin += sin
            salida.append((rangosAB[d], "%s 0x%04X%s" % (m.group(1), rangosAB[d], texto)))
        else:
            perdidas.append(ln)
    # Las descripciones de los D tambien llevan citas (solo la descripcion: las
    # direcciones del propio rango ya estan traducidas).
    final = []
    for a2, ln in salida:
        if ln.startswith("D "):
            cabeza, desc = ln.split(None, 3)[:3], ln.split(None, 3)[3] if len(ln.split(None, 3)) > 3 else ""
            texto, sin = traduce_texto(desc, mapa, rangosAB)
            citas_sin += sin
            ln = " ".join(cabeza) + (" " + texto if texto else "")
        final.append((a2, ln))
    orden = {"B": 0, "L": 1, "D": 2, "F": 3, "C": 4}
    final.sort(key=lambda t: (t[0], orden[t[1][0]]))
    with open(sal, "w", encoding="utf-8") as f:
        f.write("\n".join(l for _, l in final) + "\n")
    with open(sal + ".revisar", "w", encoding="utf-8") as f:
        f.write("\n".join(revisar) + "\n")
    with open(sal + ".perdidas", "w", encoding="utf-8") as f:
        f.write("\n".join(perdidas) + "\n")
    nD = sum(1 for _, l in final if l.startswith("D "))
    print("  portadas: %d lineas (%d D); a revisar: %d; perdidas (sin sitio): %d; "
          "citas sin traducir: %d (%d distintas)"
          % (len(final), nD, len(revisar), len(perdidas), len(citas_sin), len(set(citas_sin))))
    if citas_sin:
        print("  citas sin sitio:", " ".join("0x%04X" % v for v in sorted(set(citas_sin))[:40]))


if __name__ == "__main__":
    main()
