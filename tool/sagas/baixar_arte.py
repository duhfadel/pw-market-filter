#!/usr/bin/env python3
"""Downloads the seventeen class arts from the game's own marketplace.

**The source changed on 29/10/2026, and this one is canonical.** The first
version screenshotted the character art off two fan wikis — eight from the
saga pages, eight from the class pages, and the Ceifador from nowhere, because
the wiki has no page for it. The marketplace publishes all seventeen itself,
at `/assets/img/<ocupacao>.png`, in one consistent framing and a far larger
size. One source, seventeen files, no gap.

**The number in the file name is the occupation id, and the mapping is read
rather than typed.** `web/market_index.json` already carries `occupation` and
`class` on every one of the 2.486 characters, and across all of them each
occupation resolves to exactly one class — so the table is derived here and
checked on the way. Writing it by hand would be the same fact in two places,
and the day the server renumbers a class the hand copy is what lies.

The pacing is the collector's, and for the collector's reason: this is the
same host that refuses an IP for twenty minutes after four concurrent
workers. Seventeen requests, one at a time, three seconds apart.

Run: python3 tool/sagas/baixar_arte.py
"""

import json
import os
import sys
import time
import urllib.request

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
INDICE = os.path.join(RAIZ, 'web', 'market_index.json')
DESTINO = os.path.join(RAIZ, 'web', 'guias', 'saga-do-heroi', 'img')
ENDERECO = 'https://marketplace.theclassic.games/assets/img/{}.png'
PAUSA = 3.0

AGENTE = ('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
          'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Safari/537.36')


def ocupacoes():
    """class name -> occupation id, read off the collected market."""
    with open(INDICE, encoding='utf-8') as f:
        indice = json.load(f)

    visto = {}
    for c in indice['characters']:
        visto.setdefault(c['occupation'], set()).add(c['class'])

    mistos = {o: sorted(cs) for o, cs in visto.items() if len(cs) > 1}
    if mistos:
        raise SystemExit(
            'Uma ocupação com mais de uma classe — o número deixou de '
            f'identificar a classe: {mistos}'
        )
    return {next(iter(cs)): o for o, cs in visto.items()}


def main():
    import sagas  # noqa: E402  — carregado depois do sys.path do pagina.py
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

    mapa = ocupacoes()
    os.makedirs(DESTINO, exist_ok=True)

    faltam = [s['classe'] for s in sagas.SAGAS if s['classe'] not in mapa]
    if faltam:
        raise SystemExit(f'Classes que o mercado não conhece: {faltam}')

    total = 0
    for i, s in enumerate(sagas.SAGAS):
        occ = mapa[s['classe']]
        caminho = os.path.join(DESTINO, s['slug'] + '.png')
        pedido = urllib.request.Request(
            ENDERECO.format(occ), headers={'User-Agent': AGENTE})
        with urllib.request.urlopen(pedido, timeout=30) as r:
            dados = r.read()
        with open(caminho, 'wb') as f:
            f.write(dados)
        total += len(dados)
        print(f'{s["classe"]:16} ocupação {occ:2} -> {s["slug"]}.png '
              f'({len(dados) // 1024} KB)')
        if i < len(sagas.SAGAS) - 1:
            time.sleep(PAUSA)

    print(f'{len(sagas.SAGAS)} artes, {total // 1024} KB em bruto')
    return 0


if __name__ == '__main__':
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    sys.exit(main())
