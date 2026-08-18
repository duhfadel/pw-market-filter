"""As regiões de pixels viram caminhos vetoriais.

O contorno é seguido pelas *arestas* entre pixels, não pelos pixels: assim dois
territórios vizinhos usam exatamente os mesmos pontos na divisa, e o mapa fecha
sem fresta. Traçar por pixel deixaria meio pixel de folga entre cada par.
"""
import json

d = json.load(open('rotulos.json'))
w, h, rot = d['w'], d['h'], d['rot']

def arestas_da_regiao(alvo):
    """Cada lado de pixel onde o vizinho não é da mesma região."""
    E = {}
    def liga(a, b):
        E.setdefault(a, []).append(b)
    for y in range(h):
        base = y * w
        for x in range(w):
            if rot[base + x] != alvo:
                continue
            if x == 0 or rot[base + x - 1] != alvo:      liga((x, y+1), (x, y))
            if x == w-1 or rot[base + x + 1] != alvo:    liga((x+1, y), (x+1, y+1))
            if y == 0 or rot[base - w + x] != alvo:      liga((x, y), (x+1, y))
            if y == h-1 or rot[base + w + x] != alvo:    liga((x+1, y+1), (x, y+1))
    return E

def lacos(E):
    """Encadeia as arestas em anéis fechados."""
    saida = []
    E = {k: list(v) for k, v in E.items()}
    while E:
        inicio = next(iter(E))
        anel = [inicio]
        atual = inicio
        while True:
            vizinhos = E.get(atual)
            if not vizinhos:
                break
            prox = vizinhos.pop()
            if not vizinhos:
                del E[atual]
            anel.append(prox)
            atual = prox
            if atual == inicio:
                break
        if len(anel) > 8:
            saida.append(anel)
    return saida

def simplifica(pts, eps=0.55):
    """Douglas-Peucker: tira o ponto que ninguém sente falta."""
    if len(pts) < 3:
        return pts
    (x0, y0), (x1, y1) = pts[0], pts[-1]
    dx, dy = x1 - x0, y1 - y0
    norma = (dx*dx + dy*dy) ** 0.5 or 1
    pior, idx = 0, 0
    for i in range(1, len(pts) - 1):
        x, y = pts[i]
        dist = abs(dy*x - dx*y + x1*y0 - y1*x0) / norma
        if dist > pior:
            pior, idx = dist, i
    if pior <= eps:
        return [pts[0], pts[-1]]
    return simplifica(pts[:idx+1], eps)[:-1] + simplifica(pts[idx:], eps)

regioes = sorted({r for r in rot if r})
xs = [i % w for i, r in enumerate(rot) if r]
ys = [i // w for i, r in enumerate(rot) if r]
MX0, MY0, MX1, MY1 = min(xs), min(ys), max(xs) + 1, max(ys) + 1

import sys
sys.setrecursionlimit(100000)
caminhos, pontos_antes, pontos_depois = {}, 0, 0
for r in regioes:
    anel_maior = max(lacos(arestas_da_regiao(r)), key=len)
    pontos_antes += len(anel_maior)
    # Um anel começa e termina no mesmo ponto, e a reta entre eles tem
    # comprimento zero: o Douglas-Peucker aplicado direto acha que nenhum ponto
    # se afasta dela e devolve dois. Corta-se o anel no ponto mais distante do
    # início, simplifica-se as duas metades e emenda.
    a = anel_maior[:-1] if anel_maior[0] == anel_maior[-1] else anel_maior
    x0, y0 = a[0]
    corte = max(range(len(a)), key=lambda i: (a[i][0]-x0)**2 + (a[i][1]-y0)**2)
    s = simplifica(a[:corte+1])[:-1] + simplifica(a[corte:] + [a[0]])[:-1]
    pontos_depois += len(s)
    caminhos[r] = 'M' + 'L'.join(f'{x-MX0} {y-MY0}' for x, y in s) + 'Z'

print(f'{len(caminhos)} caminhos · {pontos_antes} pontos → {pontos_depois} depois de simplificar')
json.dump({'vb': [MX1-MX0, MY1-MY0], 'p': caminhos}, open('caminhos.json', 'w'))
