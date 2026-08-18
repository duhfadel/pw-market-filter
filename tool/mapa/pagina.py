"""Monta web/guerras/index.html.

O SVG nunca e escrito a mao: sai de svg.py, entra em pagina-exemplo.html e e
copiado daqui para dentro do modelo. Este arquivo e a costura entre a esteira
de imagem (tudo em tool/mapa/) e o site.

    python3 tool/mapa/pagina.py
"""
import json
import pathlib

RAIZ = pathlib.Path(__file__).resolve().parents[2]
MAPA = RAIZ / 'tool' / 'mapa'


def svg() -> str:
    """Os 52 contornos, os numeros e as coroas, direto da pagina de exemplo."""
    linhas = (MAPA / 'pagina-exemplo.html').read_text().splitlines()
    inicio = next(i for i, l in enumerate(linhas) if '<svg ' in l)
    fim = next(i for i, l in enumerate(linhas) if '</svg>' in l)
    return '\n'.join(linhas[inicio:fim + 1])


def base() -> str:
    """A metade que nao muda: nome, gold e capital de cada territorio.

    Vai embutida no arquivo para que a pagina desenhe inteira sem rede. O dono,
    que e a metade que muda, vem do Supabase em tempo de carga.
    """
    nomes = json.loads((MAPA / 'nomes.json').read_text())
    dados = {v['n']: {'nome': v['nome'], 'capital': v['capital'], 'gold': v['gold']}
             for v in nomes.values()}
    return json.dumps({str(n): dados[n] for n in sorted(dados)}, ensure_ascii=False)


def main() -> None:
    pagina = (MAPA / 'modelo.html').read_text()
    pagina = pagina.replace('/*SVG*/', svg()).replace('/*BASE*/', base())
    destino = RAIZ / 'web' / 'guerras' / 'index.html'
    destino.parent.mkdir(parents=True, exist_ok=True)
    destino.write_text(pagina)
    print(f'{destino.relative_to(RAIZ)}: {len(pagina) / 1024:.0f} KB')


if __name__ == '__main__':
    main()
