#!/usr/bin/env python3
"""Turns the downloaded class art into what the pages serve.

Two jobs: cut the figure out of its background, and shrink it. The first one
is usually already done.

**The marketplace publishes the art with a real alpha channel** — 62% to 76%
of each file is already transparent — so for those there is nothing to cut and
cutting would destroy them: `convert('RGB')` drops the alpha and whatever
colour sat under the transparent pixels becomes visible, which is how the
first run turned clean cut-outs into opaque rectangles. So the first thing
this does is ask the file whether it is already a cut-out, and believe it.

The flood fill below stays for art that arrives on white, which is what the
fan wikis serve. It is **a fill from the four corners, never a threshold on
white**: a rule like "every pixel above 240 becomes transparent" is one line
and it eats the character — Yeona's dress, the Sacerdote's robe, the white of
every eye. What makes a pixel background is not being white, it is being white
*and reachable from outside the figure*.

Run: python3 tool/sagas/arte.py
"""

import os
import sys

from PIL import Image, ImageDraw

DIR = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), '..', '..',
    'web', 'guias', 'saga-do-heroi', 'img',
)

LARGURA = 560    # Two times the 280 the page draws, for retina. No more.
TETO = 90_000    # Bigger than this and the quality gives way, not the rule.
TOLERANCIA = 56  # How far from the corner's colour the fill still spreads.
BOLSAO = 0.05    # Biggest trapped white patch still treated as background.
BRANCO = 240     # Below this a pale pixel is the character, not the page.
SENTINELA = (255, 0, 255)  # What the fill paints, and what we then read back.


def _ja_recortada(img):
    """True when the file already carries real transparency."""
    return img.mode in ('RGBA', 'LA', 'P') and img.convert('RGBA') \
        .getchannel('A').getextrema()[0] == 0


def _recortar(img):
    """Makes the outside-reachable background transparent."""
    img = img.convert('RGB')
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            if px[x, y] == SENTINELA:
                px[x, y] = (254, 0, 254)

    l, a = img.width - 1, img.height - 1
    for canto in ((0, 0), (l, 0), (0, a), (l, a)):
        # A corner that is already part of the figure is not a background
        # sample — filling from it would eat the character from the edge in.
        r, g, b = px[canto]
        if r + g + b < 600:
            continue
        ImageDraw.floodfill(img, canto, SENTINELA, thresh=TOLERANCIA)

    fora = img.convert('RGBA')
    fora.putdata([
        (r, g, b, 0) if (r, g, b) == SENTINELA else (r, g, b, 255)
        for (r, g, b, _) in fora.getdata()
    ])
    _furar_bolsoes(fora)
    return fora


def _furar_bolsoes(img):
    """Clears background trapped inside the figure, which the corners miss.

    An arm, a cape and a body enclose a patch of the original white page. The
    corner fill cannot reach it — correctly, by its own rule — so it survives
    as a bright hole in the middle of a cut-out figure.

    Two conditions together: **strictly white** and **under 5% of the
    picture**. The second was measured, not guessed: across the eight pieces
    of wiki art, the largest trapped patch was the Atiradora's at **1,86%**
    and the next largest anywhere was **0,01%**. The cap sits in that gap.

    The gap is wide because **painted art is almost never flat 240+ across a
    region and a flat background always is**. The Sacerdote's wings look white
    and read as noise here, because they are shaded.
    """
    largura, altura = img.size
    px = img.load()
    teto = int(largura * altura * BOLSAO)
    visto = bytearray(largura * altura)

    for y0 in range(altura):
        for x0 in range(largura):
            i = y0 * largura + x0
            if visto[i]:
                continue
            r, g, b, a = px[x0, y0]
            if a == 0 or min(r, g, b) < BRANCO:
                visto[i] = 1
                continue
            mancha, fila = [], [(x0, y0)]
            visto[i] = 1
            while fila:
                x, y = fila.pop()
                mancha.append((x, y))
                if len(mancha) > teto:
                    break
                for vx, vy in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if not (0 <= vx < largura and 0 <= vy < altura):
                        continue
                    j = vy * largura + vx
                    if visto[j]:
                        continue
                    r2, g2, b2, a2 = px[vx, vy]
                    if a2 == 0 or min(r2, g2, b2) < BRANCO:
                        continue
                    visto[j] = 1
                    fila.append((vx, vy))
            if len(mancha) <= teto:
                for x, y in mancha:
                    px[x, y] = (255, 255, 255, 0)


def _gravar(img, caminho):
    """Saves under the ceiling, dropping quality a step at a time.

    The busiest art lands at 124 KB at quality 82, for a picture the page
    draws at 260 px. The ceiling is not calling that a mistake — it is there
    to stop a fan site serving a megabyte of art nobody asked for. So the
    quality bends instead of the rule.
    """
    for q in (82, 76, 70, 64, 58):
        img.save(caminho, 'WEBP', quality=q, method=6)
        if os.path.getsize(caminho) <= TETO:
            return q
    return 58


def main():
    total = 0
    for nome in sorted(os.listdir(DIR)):
        if not nome.endswith('.png'):
            continue
        bruto = os.path.join(DIR, nome)
        caminho = bruto[:-4] + '.webp'
        antes = os.path.getsize(bruto)

        img = Image.open(bruto)
        pronta = _ja_recortada(img)
        img = img.convert('RGBA') if pronta else _recortar(img)

        cortados = sum(1 for p in img.getdata() if p[3] == 0)
        fatia = cortados * 100 // (img.width * img.height)

        if img.width > LARGURA:
            alt = round(img.height * LARGURA / img.width)
            img = img.resize((LARGURA, alt), Image.LANCZOS)
        q = _gravar(img, caminho)
        os.remove(bruto)

        depois = os.path.getsize(caminho)
        total += depois

        # Os dois extremos são defeitos, e só um deles estava guardado no
        # princípio. «Nada transparente» quer dizer fundo que não é branco;
        # **«tudo transparente» quer dizer captura vazia** — e foi isso que
        # aconteceu com três artes cujo elemento não estava à vista quando o
        # browser fotografou. As duas acabam numa página errada, mas só a
        # segunda desenha um buraco onde devia estar uma pessoa.
        aviso = ''
        if fatia == 0:
            aviso = '  <-- NADA TRANSPARENTE, confira o fundo'
        if fatia >= 99:
            aviso = '  <-- IMAGEM VAZIA, a captura falhou'
        origem = 'já vinha recortada' if pronta else 'recortada aqui'
        print(f'{os.path.basename(caminho):20} {antes // 1024:4} KB -> '
              f'{depois // 1024:3} KB  {img.width}x{img.height}  '
              f'{fatia}% transp.  q{q}  ({origem}){aviso}')

    print(f'total: {total // 1024} KB')
    return 0


if __name__ == '__main__':
    sys.exit(main())
