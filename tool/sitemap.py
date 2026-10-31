#!/usr/bin/env python3
"""Escreve `web/sitemap.xml` varrendo as páginas que existem.

**Era uma lista à mão, e a lista envelheceu exactamente como listas à mão
envelhecem.** O comentário do ficheiro antigo dizia, com três páginas, que
«um gerador seria mais máquina do que o problema pede». A 29/10/2026
entraram dezoito páginas das Sagas do Herói e nenhuma foi inscrita — e a
30/10 o AdSense reprovou o site por **conteúdo de baixo valor**, tendo
diante dele nove URLs de vinte e quatro. As melhores páginas do site
estavam publicadas e invisíveis.

É a mesma forma que o `paginas_html_test` já existe para apanhar: uma lista
à mão tem o defeito que o teste existe para prevenir. Aqui a lista passou a
ser a pasta.

Duas regras no que entra:

**`noindex` manda.** Uma página que pede para não ser indexada não vai para
o sitemap — pedir as duas coisas ao mesmo tempo é dar instruções opostas ao
mesmo robô. É o caso de `/guerras/`.

**O endereço é o que o site liga, sem `.html`.** O Pages resolve
`/guias/runas` para `runas.html` sozinho, e é assim que todas as ligações
internas estão escritas. Listar a forma com extensão criaria uma segunda
morada para a mesma página, a competir com a primeira.

Corre: python3 tool/sitemap.py
"""

import os
import subprocess
import sys
from xml.sax.saxutils import escape

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
WEB = os.path.join(RAIZ, 'web')
SITE = 'https://portalpw.net'


def enderecos():
    """Caminho em disco -> endereço público, só do que pode ser indexado."""
    achados = []
    for pasta, _, ficheiros in os.walk(WEB):
        for nome in ficheiros:
            if not nome.endswith('.html'):
                continue
            caminho = os.path.join(pasta, nome)
            with open(caminho, encoding='utf-8') as f:
                if 'noindex' in f.read():
                    continue
            rel = os.path.relpath(caminho, WEB).replace(os.sep, '/')
            if rel == 'index.html':
                url = '/'
            elif rel.endswith('/index.html'):
                url = '/' + rel[: -len('index.html')]
            else:
                url = '/' + rel[: -len('.html')]
            achados.append((url, caminho))
    achados.sort()
    return achados


def datado(caminho):
    """A data do último commit que tocou o ficheiro, ou None.

    Um `lastmod` errado é pior do que nenhum — ensina o robô a desconfiar
    do ficheiro inteiro. A data do commit é a única que temos e é verdade.
    """
    try:
        saida = subprocess.run(
            ['git', 'log', '-1', '--format=%cs', '--', caminho],
            cwd=RAIZ, capture_output=True, text=True, timeout=20,
        )
        data = saida.stdout.strip()
        return data or None
    except Exception:
        return None


def main():
    linhas = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<!-- Gerado por tool/sitemap.py. Não editar à mão: a lista à mão foi',
        '     o que deixou dezoito páginas das sagas fora do Google. -->',
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
    ]
    achados = enderecos()
    for url, caminho in achados:
        linhas.append('  <url>')
        linhas.append(f'    <loc>{escape(SITE + url)}</loc>')
        data = datado(caminho)
        if data:
            linhas.append(f'    <lastmod>{data}</lastmod>')
        linhas.append('  </url>')
    linhas.append('</urlset>')
    linhas.append('')

    destino = os.path.join(WEB, 'sitemap.xml')
    with open(destino, 'w', encoding='utf-8') as f:
        f.write('\n'.join(linhas))

    print(f'{len(achados)} endereços em web/sitemap.xml')
    for url, _ in achados:
        print(f'  {url}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
