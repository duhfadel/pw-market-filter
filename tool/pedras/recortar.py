#!/usr/bin/env python3
"""Tira a moldura e o fundo dos ícones das pedras do set.

**Escreve numa pasta própria e nunca por cima de `assets/icons/items/`**, que
é partilhada por toda a app — o card, as tiras de pedra, as linhas de item.
Recortar em cima mudaria o site inteiro sem aviso, para servir um chip.

**O preenchimento por cantos, que já se usa na arte das classes, não serve
aqui.** Ele procura uma fronteira a partir de fora, e nestes ícones o canto
*é* a moldura: o preenchimento pára nela e nunca chega ao fundo escuro de
dentro. Medido em três tolerâncias a 04/11/2026, não tirou nada.

O que serve é a estrutura, que foi medida em vez de suposta:

**A moldura tem dois pixéis** — um contorno escuro e uma borda clara. O anel
de fora dá brilho médio 50, o seguinte 164, e do terceiro para dentro cai
para os 37 do fundo. Dois pixéis saem de cada lado e sobra o interior.

**E o fundo é escuro, a pedra é clara.** Por isso a transparência sai do
brilho de cada pixel e não de uma fronteira: abaixo de [_LO] é fundo, acima
de [_HI] é pedra, e entre os dois desvanece. **O desvanecer é o ponto** — o
brilho da pedra dissolve-se no fundo e um corte reto deixaria halo ou
comeria o brilho, que foi o que reprovou a primeira tentativa.

Os limiares foram escolhidos a olho sobre três variantes renderizadas lado a
lado. Mais baixo deixa um retângulo de fundo à volta do Defesa +3; mais alto
começa a comer o miolo do Diamante do Tigre.

Corre: python3 tool/pedras/recortar.py
"""

import os
import sys

from PIL import Image

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
ORIGEM = os.path.join(RAIZ, 'assets', 'icons', 'items')
DESTINO = os.path.join(RAIZ, 'assets', 'icons', 'pedras')

_MOLDURA = 2   # pixéis de contorno e borda, medidos.
_LO = 60       # abaixo disto é fundo.
_HI = 120      # acima disto é pedra inteira.

# **Só as cinco pedras de equipamento, que são as que o chip desenha.**
#
# As de acessório ficam de fora porque não cortam: medido, a Pedra de Yan Luo
# e a Pedra de Montanha têm brilho mediano de 157 e 128 contra os 53 das de
# equipamento — são claras no tile quase todo, e o limiar deixa 92% e 94%
# delas de pé. Recortá-las mal seria pior do que não as recortar, e nenhuma
# tela as mostra.
#
# Escritos aqui e não lidos de `lib/market/set_stones.dart` porque este
# script é Python e aquilo é Dart; `set_stones_test` crava que as duas
# listas não divergiram.
IDS = [21377, 38153, 38154, 25154, 38155]


def recortar(caminho):
    im = Image.open(caminho).convert('RGB')
    lado = im.width
    im = im.crop((_MOLDURA, _MOLDURA, lado - _MOLDURA, lado - _MOLDURA))
    fora = im.convert('RGBA')
    fora.putdata([
        (r, g, b, _alfa(r, g, b)) for (r, g, b, _) in fora.getdata()
    ])
    return fora


def _alfa(r, g, b):
    lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
    if lum <= _LO:
        return 0
    if lum >= _HI:
        return 255
    return int(255 * (lum - _LO) / (_HI - _LO))


def main():
    os.makedirs(DESTINO, exist_ok=True)
    for pid in IDS:
        origem = os.path.join(ORIGEM, f'{pid}.png')
        if not os.path.exists(origem):
            raise SystemExit(
                f'{origem} não existe. Corra `dart run tool/fetch_icons.dart` '
                'antes deste script.'
            )
        cut = recortar(origem)
        transp = sum(1 for p in cut.getdata() if p[3] == 0)
        total = cut.width * cut.height
        caminho = os.path.join(DESTINO, f'{pid}.png')
        cut.save(caminho)
        fatia = transp * 100 // total
        # Os dois extremos são defeitos. Nada transparente quer dizer que o
        # fundo não era escuro; tudo transparente quer dizer que a pedra não
        # era clara — e nos dois casos o chip desenha errado em silêncio.
        aviso = ''
        if fatia < 10:
            aviso = '  <-- QUASE NADA RECORTADO'
        if fatia > 90:
            aviso = '  <-- QUASE TUDO APAGADO'
        print(f'  {pid}: {cut.width}x{cut.height}, {fatia}% transparente'
              f'{aviso}')
    print(f'{len(IDS)} pedras em assets/icons/pedras/')
    return 0


if __name__ == '__main__':
    sys.exit(main())
