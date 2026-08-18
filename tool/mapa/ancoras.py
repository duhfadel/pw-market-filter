"""Onde cabe um brasao no alto de cada territorio.

Tres coisas tornam isso menos obvio do que parece, e cada uma foi medida nas
52 formas antes de virar regra:

1. **O topo do retangulo que envolve a forma quase nunca esta dentro dela.**
   Os territorios sao irregulares e varios comecam num bico. Ancorar em `ymin`
   deixaria metade dos brasoes boiando no vizinho. A varredura vai por linhas,
   de cima para baixo, e so aceita uma altura onde cabe o quadrado inteiro --
   largura suficiente ali e ainda suficiente uma altura de icone abaixo, para
   ele nao ficar pendurado num afunilamento.

2. **"Em cima" sozinho nao basta, e parar na primeira altura que serve e cedo
   demais.** O territorio 7 e o caso: a y=65 ele so tem largura na ponta
   esquerda, e dois pixels mais abaixo abre inteiro. Um brasao naquela ponta
   parece do vizinho. Entao a varredura junta as posicoes possiveis da faixa
   de cima e escolhe a mais proxima do centro que o numero ja ocupa -- o ponto
   mais fundo da forma, vindo de sementes.py -- desempatando pela mais alta.

3. **O numero ja esta la, e ele ganha.** Com 23 px de brasao, 34 dos 52
   territorios tinham icone por cima do proprio numero. O brasao e portanto
   dimensionado pela faixa livre *acima* do numero, nunca pela forma inteira.

   Em oito territorios o numero esta perto demais do topo e nao sobra faixa
   nenhuma. Descer o numero de 0,5 a 5 px resolve os oito, e essa posicao nao
   e sagrada: ela veio de "ponto mais fundo da forma", nao do jogo. Entao o
   numero cede, desde que continue inteiro dentro do territorio.

Onde nem assim couber, a resposta e nao desenhar brasao. Um simbolo de 6 px e
uma mancha que nao identifica ninguem, e a cor do territorio ja diz de quem
ele e. O marcador de guerra nao depende disto: ele e o contorno da forma, que
todo territorio tem.
"""
from __future__ import annotations

import re

MINIMO = 10.0   # abaixo disso o brasao e uma mancha, nao um simbolo
MAXIMO = 20.0   # acima disso ele compete com o numero do territorio
NUMERO = 9.0    # meia altura do numero, medida no <text> de 12.5 px


def vertices(d: str) -> list:
    """Os pontos do caminho, na ordem em que ele os visita."""
    nums = [float(v) for v in re.findall(r'-?\d+(?:\.\d+)?', d)]
    return list(zip(nums[0::2], nums[1::2]))


def faixas(pts: list, y: float) -> list:
    """Os trechos horizontais de dentro da forma na altura `y`."""
    xs = []
    for i in range(len(pts)):
        (x1, y1), (x2, y2) = pts[i], pts[(i + 1) % len(pts)]
        if y1 == y2:
            continue
        if min(y1, y2) <= y < max(y1, y2):
            xs.append(x1 + (y - y1) * (x2 - x1) / (y2 - y1))
    xs.sort()
    return list(zip(xs[0::2], xs[1::2]))


def perto(pts: list, y: float, cx: float):
    """O trecho da altura `y` mais proximo de `cx` -- o centro do territorio."""
    faixa = faixas(pts, y)
    if not faixa:
        return None
    return min(faixa, key=lambda t: 0 if t[0] <= cx <= t[1]
               else min(abs(t[0] - cx), abs(t[1] - cx)))


def _passos(inicio: float, fim: float, passo: float = 0.5):
    y = inicio
    while y < fim:
        yield y
        y += passo


def ancora(d: str, cx: float, cy: float):
    """(x do centro, y do topo, lado) do brasao, ou None se nao couber."""
    pts = vertices(d)
    topo = min(p[1] for p in pts)
    inicio = topo + 2          # 2 px de folga para nao encostar na divisa
    fim = cy - NUMERO          # o numero e o piso: o brasao fica acima dele

    largo = max((perto(pts, y, cx) or (0, 0))[1] - (perto(pts, y, cx) or (0, 0))[0]
                for y in _passos(inicio, max(inicio + 1, fim)))
    lado = min(MAXIMO, largo * 0.5, fim - inicio)
    if lado < MINIMO:
        return None

    opcoes = []
    for y in _passos(inicio, fim - lado + 0.5):
        alto, baixo = perto(pts, y, cx), perto(pts, y + lado, cx)
        if not alto or not baixo:
            continue
        e, dir_ = max(alto[0], baixo[0]), min(alto[1], baixo[1])
        if dir_ - e >= lado:
            # Encostado no centro do territorio ate onde o trecho permite.
            x = min(max(cx, e + lado / 2), dir_ - lado / 2)
            opcoes.append((abs(x - cx), y, x))
    if not opcoes:
        return None
    _, y, x = min(opcoes)
    return x, y, lado


RECUO = 12.0    # o quanto o numero pode ceder para o brasao caber


def cabe_numero(pts: list, x: float, y: float, meia: float = 9.0,
                larg: float = 11.0) -> bool:
    """O numero inteiro esta dentro da forma nessa posicao?"""
    for yy in (y - meia, y, y + meia):
        f = perto(pts, yy, x)
        if not f or not (f[0] + 1 <= x - larg / 2 and x + larg / 2 <= f[1] - 1):
            return False
    return True


def de(caminhos: dict, rotulos: dict):
    """({numero: [x, y, lado]}, {numero: y do numero}) para o mapa.

    `rotulos` e {numero: (x, y)} da posicao atual do numero. A segunda saida
    traz so os que precisaram descer, e e o que a pagina reescreve no <text>.
    """
    brasoes, descidos = {}, {}
    for n, d in caminhos.items():
        pts = vertices(d)
        cx, cy = rotulos[n]
        recuo = 0.0
        while recuo <= RECUO:
            if cabe_numero(pts, cx, cy + recuo):
                a = ancora(d, cx, cy + recuo)
                if a:
                    brasoes[n] = [round(v, 1) for v in a]
                    if recuo:
                        descidos[n] = round(cy + recuo, 1)
                    break
            recuo += 0.5
    return brasoes, descidos
