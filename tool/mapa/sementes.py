"""Uma semente por território: funda, e clara em toda a vizinhança.

O critério "pixel mais claro entre os fundos" falhou de um jeito que só
apareceu ao depurar: ele escolhia o miolo do buraco de uma letra — papel de 252
cercado por tinta de 100. Semente ilhada perde a inundação e o território
termina com sete pixels. O que vale é a média de uma janela, não o pixel.
"""
import json, shutil, subprocess
from collections import deque
from PIL import Image

subprocess.run(['python3', 'cresce.py'], check=True, capture_output=True)
shutil.copy('rotulos.json', 'mascara.json')
d = json.load(open('rotulos.json'))
w, h, rot = d['w'], d['h'], d['rot']
lum = bytearray(Image.open('mapa.webp').convert('L').tobytes())

S = [0] * ((w + 1) * (h + 1))
for y in range(h):
    linha = 0
    for x in range(w):
        linha += lum[y * w + x]
        S[(y+1)*(w+1) + x+1] = S[y*(w+1) + x+1] + linha

def media(x, y, r=6):
    x0, y0 = max(0, x-r), max(0, y-r)
    x1, y1 = min(w-1, x+r), min(h-1, y+r)
    t = (S[(y1+1)*(w+1)+x1+1] - S[y0*(w+1)+x1+1] - S[(y1+1)*(w+1)+x0] + S[y0*(w+1)+x0])
    return t / ((x1-x0+1) * (y1-y0+1))

px = {}
for i, r in enumerate(rot):
    if r: px.setdefault(r, []).append(i)

sementes = {}
for r, p in px.items():
    dentro = set(p)
    dist, fila = {}, deque()
    for i in p:
        x, y = i % w, i // w
        if any((ny*w+nx) not in dentro for nx, ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1))):
            dist[i] = 0; fila.append(i)
    while fila:
        i = fila.popleft()
        x, y = i % w, i // w
        for nx, ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
            j = ny*w+nx
            if j in dentro and j not in dist:
                dist[j] = dist[i]+1; fila.append(j)
    fundo = max(dist.values())
    cand = [i for i, v in dist.items() if v >= fundo * 0.5]
    melhor = max(cand, key=lambda i: media(i % w, i // w))
    sementes[str(r)] = [melhor % w, melhor // w]

json.dump(sementes, open('sementes.json', 'w'))
vals = sorted(media(x, y) for x, y in sementes.values())
print(f'{len(sementes)} sementes · média da vizinhança: pior {vals[0]:.0f}, mediana {vals[len(vals)//2]:.0f}')
