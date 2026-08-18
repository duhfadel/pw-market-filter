"""Monta as duas paginas de web/guerras/.

O SVG nunca e escrito a mao: sai de svg.py, entra em pagina-exemplo.html e e
copiado daqui para dentro do modelo. Este arquivo e a costura entre a esteira
de imagem (tudo em tool/mapa/) e o site.

    python3 tool/mapa/pagina.py

Alem de copiar, ele calcula onde cabe um brasao no alto de cada territorio
(ancoras.py) e, nos oito territorios apertados, desce o numero os poucos
pixels que fazem o brasao caber. E por isso que o SVG do site nao e byte a
byte o da pagina de exemplo.
"""
import json
import pathlib
import re
import sys

RAIZ = pathlib.Path(__file__).resolve().parents[2]
MAPA = RAIZ / 'tool' / 'mapa'
sys.path.insert(0, str(MAPA))

import ancoras  # noqa: E402


def bloco_svg() -> str:
    """Os 52 contornos, os numeros e as coroas, direto da pagina de exemplo."""
    linhas = (MAPA / 'pagina-exemplo.html').read_text().splitlines()
    inicio = next(i for i, l in enumerate(linhas) if '<svg ' in l)
    fim = next(i for i, l in enumerate(linhas) if '</svg>' in l)
    return '\n'.join(linhas[inicio:fim + 1])


def caminhos(svg: str) -> dict:
    return {int(n): d for n, d in
            re.findall(r'<path id="t(\d+)" class="t" d="([^"]+)"', svg)}


def rotulos(svg: str) -> dict:
    return {int(n): (float(x), float(y)) for x, y, n in
            re.findall(r'<text class="n[^"]*" x="([\d.]+)" y="([\d.]+)">(\d+)</text>', svg)}


def desce_numeros(svg: str, descidos: dict) -> str:
    """Reescreve o y dos numeros que cederam espaco ao brasao.

    O texto e recolocado como estava, nao remontado a partir do inteiro: o
    territorio 8 esta escrito "08" no SVG e refazer com `int` comia o zero.
    """
    def troca(m):
        rotulo = m.group(3)
        n = int(rotulo)
        return (f'<text class="{m.group(1)}" x="{m.group(2)}" y="{descidos[n]}">{rotulo}</text>'
                if n in descidos else m.group(0))
    return re.sub(r'<text class="(n[^"]*)" x="([\d.]+)" y="[\d.]+">(\d+)</text>', troca, svg)


def base() -> str:
    """A metade que nao muda: nome, gold e capital de cada territorio.

    Vai embutida no arquivo para que a pagina desenhe inteira sem rede. O dono,
    a guerra e o texto, que sao a metade que muda, vem do Supabase em tempo de
    carga.
    """
    nomes = json.loads((MAPA / 'nomes.json').read_text())
    dados = {v['n']: {'nome': v['nome'], 'capital': v['capital'], 'gold': v['gold']}
             for v in nomes.values()}
    return json.dumps({str(n): dados[n] for n in sorted(dados)}, ensure_ascii=False)


def main() -> None:
    svg = bloco_svg()
    brasoes, descidos = ancoras.de(caminhos(svg), rotulos(svg))
    svg = desce_numeros(svg, descidos)

    destino = RAIZ / 'web' / 'guerras'
    destino.mkdir(parents=True, exist_ok=True)

    mapa = (MAPA / 'modelo.html').read_text()
    mapa = (mapa.replace('/*SVG*/', svg)
                .replace('/*BASE*/', base())
                .replace('/*BRASOES*/', json.dumps(brasoes)))
    (destino / 'index.html').write_text(mapa)

    # A ficha leva o mapa inteiro de novo, todo apagado menos o territorio da
    # vez. Custa o dobro de SVG e responde "onde fica isso?", que e a primeira
    # pergunta de quem chega por um link sem ter decorado os 52 numeros.
    ficha = ((MAPA / 'modelo-territorio.html').read_text()
             .replace('/*BASE*/', base())
             .replace('/*MINI*/', svg))
    (destino / 'territorio' / 'index.html').parent.mkdir(exist_ok=True)
    (destino / 'territorio' / 'index.html').write_text(ficha)

    print(f'web/guerras/index.html            {len(mapa) / 1024:5.0f} KB'
          f'  ({len(brasoes)} brasoes, {len(descidos)} numeros descidos)')
    print(f'web/guerras/territorio/index.html {len(ficha) / 1024:5.0f} KB')


if __name__ == '__main__':
    main()
