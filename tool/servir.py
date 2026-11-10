#!/usr/bin/env python3
"""Serve o site como o GitHub Pages serve — e não como o `http.server` serve.

**A diferença morde e já quase custou uma correcção errada.** Os guias são
ligados sem extensão — `/guias/runas`, não `/guias/runas.html` — porque o
GitHub Pages resolve isso sozinho. O `python3 -m http.server` não resolve nada
e responde **404** ao mesmo endereço, o que no ecrã se lê exactamente como um
link partido. Medido a 10/11/2026: sete guias, todos 404 no módulo do Python e
todos 200 em `portalpw.net`.

O perigo não é o 404 — é a reacção a ele. «Consertar» o href para o silenciar
seria guiar-se por um servidor que nenhum visitante usa, e partir o que
importa. Este ficheiro existe para que o engano não chegue a acontecer.

O que o Pages faz, por ordem, e o que isto copia:

1. o ficheiro exacto, se existir
2. `caminho.html`
3. `caminho/index.html`
4. `404.html` na raiz, com estado 404 — e sem ele, um 404 seco

**E não guarda nada em cache**, que é a outra razão para não usar o módulo
simples: um `max-age` do servidor local faz um build novo parecer um build
que não mudou, e esta casa já perdeu uma hora a esse engano.

    python3 tool/servir.py                 # build/web em 8000
    python3 tool/servir.py 8123            # noutra porta
    python3 tool/servir.py 8123 web        # e noutra pasta
"""

import os
import sys
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')


class ComoOPages(SimpleHTTPRequestHandler):
    """O `SimpleHTTPRequestHandler` com as três resoluções do Pages."""

    def translate_path(self, path):
        caminho = super().translate_path(path)
        if os.path.isdir(caminho) or os.path.exists(caminho):
            return caminho

        # `/guias/runas` -> `guias/runas.html`. O `?` e o `#` já saíram no
        # `translate_path` do pai.
        comHtml = caminho + '.html'
        if os.path.isfile(comHtml):
            return comHtml

        # `/guerras` -> `guerras/index.html`, que o Pages também serve mesmo
        # sem a barra no fim.
        comIndice = os.path.join(caminho, 'index.html')
        if os.path.isfile(comIndice):
            return comIndice

        return caminho

    def send_head(self):
        caminho = self.translate_path(self.path)
        if not os.path.exists(caminho):
            proprio = os.path.join(self.directory, '404.html')
            if os.path.isfile(proprio):
                self.path = '/404.html'
                # O estado tem de continuar a ser 404: uma página de erro
                # servida com 200 engana quem está a medir se um endereço
                # existe, que é metade do que se testa aqui.
                self.send_response(404)
                self.send_header('Content-Type', 'text/html; charset=utf-8')
                self._semCache()
                tamanho = os.path.getsize(proprio)
                self.send_header('Content-Length', str(tamanho))
                self.end_headers()
                return open(proprio, 'rb')
        return super().send_head()

    def end_headers(self):
        self._semCache()
        super().end_headers()

    def _semCache(self):
        self.send_header('Cache-Control', 'no-store, must-revalidate')

    def log_message(self, formato, *args):
        # Uma linha por pedido, sem o carimbo de hora que não ajuda em nada.
        sys.stderr.write(f'{self.address_string()} {formato % args}\n')


def main():
    porta = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
    pasta = sys.argv[2] if len(sys.argv) > 2 else os.path.join(RAIZ, 'build', 'web')
    pasta = os.path.abspath(pasta)

    if not os.path.isdir(pasta):
        raise SystemExit(
            f'{pasta} não existe — falta `flutter build web` ou a pasta está errada'
        )

    servidor = ThreadingHTTPServer(
        ('0.0.0.0', porta),
        partial(ComoOPages, directory=pasta),
    )
    print(f'{pasta}\nhttp://localhost:{porta}/  (Ctrl-C para parar)')
    try:
        servidor.serve_forever()
    except KeyboardInterrupt:
        print()


if __name__ == '__main__':
    main()
