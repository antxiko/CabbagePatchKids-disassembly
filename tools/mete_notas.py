#!/usr/bin/env python3
"""Mete en el fichero de notas las lineas de otro fichero, ordenadas y sin pisar.

    python3 tools/mete_notas.py <fichero con lineas L/C/B/D/F>

Comentar es una tanda larga, y las anotaciones se escriben aparte para no tocar
el fichero bueno hasta tener el lote entero. Esto las mezcla:

  - una C en una direccion que ya tiene C la SUSTITUYE (se esta corrigiendo);
  - una L en una direccion que ya tiene L la sustituye tambien;
  - las B se anaden, que un bloque puede tener varias lineas;
  - y todo queda ordenado por direccion, con el orden B, L, D, F, C dentro de
    cada una, que es el que espera mkasm.

Al acabar dice cuantas habia y cuantas hay, para que se vea el efecto.
"""
import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NOTAS = os.path.join(RAIZ, "src", "cabbagepatch.notes")
ORDEN = {"B": 0, "L": 1, "D": 2, "F": 3, "C": 4}


def clave(l):
    p = l.split()
    return (int(p[1], 0), ORDEN.get(p[0], 9))


def main():
    nuevas = [l.rstrip("\n") for l in open(sys.argv[1], encoding="utf-8")
              if l.strip() and not l.lstrip().startswith("#")]
    for l in nuevas:
        if not re.match(r"^[BLDFC] 0x[0-9A-Fa-f]+", l):
            raise SystemExit("linea que no es una directiva: %s" % l[:70])

    viejas = open(NOTAS, encoding="utf-8").read().splitlines()
    cabecera = [l for l in viejas if l.startswith("#")]
    cuerpo = [l for l in viejas if l.strip() and not l.startswith("#")]

    pisa = {(l.split()[0], l.split()[1].lower()) for l in nuevas
            if l.split()[0] in ("C", "L")}
    antes = len(cuerpo)
    cuerpo = [l for l in cuerpo
              if (l.split()[0], l.split()[1].lower()) not in pisa]
    cuerpo += nuevas
    cuerpo.sort(key=clave)
    open(NOTAS, "w", encoding="utf-8").write("\n".join(cabecera + cuerpo) + "\n")
    print("  %d lineas -> %d (%d nuevas, %d sustituidas)"
          % (antes, len(cuerpo), len(nuevas), antes + len(nuevas) - len(cuerpo)))


if __name__ == "__main__":
    main()
