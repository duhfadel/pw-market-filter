#!/usr/bin/env python3
"""Renders the seventeen Saga do Herói pages, plus their index.

Seventeen pages that differ only in their content would otherwise be
seventeen copies of the same forty-five lines of <head>. That is exactly
how `/guias/cartas-nuema` shipped without the AdSense tag: a page written
by hand a day after the others, missing the block nobody re-reads. Here
the head is written once and `paginas_html_test` checks every file that
comes out.

The same reasoning covers the numerals rule. Marcellus draws `0` as `O`
and `1` as `I`, so a digit in a heading has to sit inside
`<span class="algarismos">`. `_titulo` does that to every heading on the
way out — the rule is applied by construction instead of remembered
seventeen times.

Run: python3 tool/sagas/pagina.py
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from sagas import GERAL, SAGAS  # noqa: E402

RAIZ = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), '..', '..', 'web', 'guias',
    'saga-do-heroi',
)

ADSENSE = '''  <!-- AdSense. O número de editor é público por desenho — ele vai no bundle de
       toda a gente e também no `ads.txt` na raiz, que é o ficheiro que diz ao
       mercado quem está autorizado a vender este espaço. Não é segredo e não
       há onde o esconder.

       Em **todas** as páginas, e não só nas que têm espaço de anúncio: a tag é
       o que verifica a propriedade do site, e uma página sem ela é uma página
       que o revisor não consegue associar à conta. -->
  <script async
          src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-7064703455080324"
          crossorigin="anonymous"></script>'''


def _titulo(texto):
    """Wraps every run of digits so Marcellus does not draw it as letters."""
    return re.sub(r'\d[\d.]*', lambda m: f'<span class="algarismos">{m.group(0)}</span>', texto)


def _arte(s):
    """O ficheiro da arte, derivado do slug — nunca um campo.

    Um campo `arte` a dizer `guerreiro.webp` ao lado de um slug `guerreiro`
    é o mesmo facto em dois sítios, e a 29/10/2026 divergiu: uma expressão
    regular preencheu o campo do Ceifador com a arte do Guerreiro, e a
    página saiu com a pessoa errada ao lado do texto certo.
    """
    return s['slug'] + '.webp'


def _artigo(s):
    """«do Guerreiro», «da Feiticeira» — derivado, com escape manual.

    As três classes do jogo terminadas em -a (Feiticeira, Atiradora,
    Espiritualista) são as três femininas neste servidor, portanto a regra
    acerta nas dezassete. O campo `artigo` existe para o dia em que uma
    classe nova quebre isso — melhor uma porta aberta do que descobrir pelo
    texto errado na página.
    """
    return s.get('artigo') or ('da' if s['classe'].endswith('a') else 'do')


def _escapar(texto):
    return (texto.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;'))


def _rico(texto):
    """The four marks the pages use: **bold**, *italic*, `coord`, [text](url).

    Bold runs before italic on purpose — `**x**` would otherwise be eaten by
    the single-asterisk rule and come out as `<em>*x*</em>`. The italics mark
    the in-game emotes (*acenar*, *dar de ombros*), which is the one thing on
    these pages the player has to find in the interface rather than on a map.
    """
    t = _escapar(texto)
    t = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', t)
    t = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', t)
    t = re.sub(r'(?<!\*)\*([^*\n]+)\*(?!\*)', r'<em>\1</em>', t)
    t = re.sub(r'`([^`]+)`', r'<code>\1</code>', t)
    return t


def cabeca(titulo, descricao, url, secao):
    return f'''<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">

  <title>{_escapar(titulo)} — Portal PW</title>
  <meta name="description" content="{_escapar(descricao)}">

  <link rel="canonical" href="{url}">

  <meta property="og:type" content="article">
  <meta property="og:site_name" content="Portal PW">
  <meta property="og:locale" content="pt_BR">
  <meta property="og:title" content="{_escapar(titulo)}">
  <meta property="og:description" content="{_escapar(descricao)}">
  <meta property="og:url" content="{url}">
  <meta property="og:image" content="https://portalpw.net/og-v2.jpg">
  <meta property="og:image:type" content="image/jpeg">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta name="twitter:card" content="summary_large_image">

  <link rel="icon" type="image/x-icon" href="/favicon.ico?v=2">
  <link rel="stylesheet" href="/guias/estilo.css">
{ADSENSE}
</head>
<body>

<header class="topo">
  <div class="topo-interno">
    <a href="/" title="Portal PW">
      <img class="marca-larga" src="/assets/assets/images/portal-pw-logo-v2.webp" alt="Portal PW">
      <img class="marca-curta" src="/assets/assets/images/pw-mark.webp" alt="Portal PW">
    </a>
    <span class="secao">{_escapar(secao)}</span>
  </div>
</header>

<main>
'''


RODAPE = '''</main>

<div class="publicidade">
  <span class="rotulo">PUBLICIDADE</span>
  <a class="casa" href="mailto:duhspain@gmail.com">Quer anunciar neste espaço? <strong>Clique aqui</strong></a>
</div>

<footer>
  <p>
    Projeto de fã, sem vínculo com o The Classic Games.<br>
    <a href="/privacidade/">Privacidade</a> &middot;
    <a href="/guias/">Guias</a> &middot;
    <a href="/">Voltar ao Portal</a>
  </p>
</footer>

</body>
</html>
'''


def pagina_da_classe(s):
    """One class page: art, reward, how to start, and every mission in order."""
    url = f"https://portalpw.net/guias/saga-do-heroi/{s['slug']}"
    desc = (
        f"A Saga do Herói do {s['classe']} no The Classic 1.8.7: "
        f"{len(s['passos'])} missões com coordenadas, o ovo {s['ovo']} "
        f"e o título {s['titulo']} (+100 de HP)."
    )
    h = [cabeca(f"Saga do Herói: {s['classe']}", desc, url, 'Saga do Herói')]

    h.append(f'  <h1>{_titulo("Saga do Herói: " + s["classe"])}</h1>')
    h.append(f'  <p class="resumo">{_rico(s["resumo"])}</p>')

    if True:
        h.append(
            f'  <p class="arte-heroi">'
            # **O alt diz a classe e não o herói, de propósito.** Oito das
            # dezassete artes vêm da página da saga e as outras oito da
            # página da classe — e mesmo as primeiras têm nomes de ficheiro
            # como `Guerreiro.png`, que é arte de classe. Escrever «o herói
            # da saga» sobre uma arte de classe seria afirmar uma coisa que
            # a imagem não prova. «Arte do Guerreiro» é verdade nas duas.
            f'<img src="img/{_arte(s)}" alt="Arte do {_escapar(s["classe"])} no Perfect World" '
            f'loading="lazy"></p>'
        )

    # The reward first, because it is why anybody opens this page.
    h.append('  <h2>O que você ganha</h2>')
    h.append('  <div class="aviso">')
    h.append(f'    <p><strong>{_escapar(s["ovo"])}</strong> — um mascote cosmético, que só aparece depois de ser adicionado ao Códice.</p>')
    h.append(f'    <p><strong>Título: {_escapar(s["titulo"])}</strong> — <span class="algarismos">+100</span> de HP, e colorido.</p>')
    h.append('  </div>')
    h.append(
        '  <p>Os dois saem do <strong>baú brilhante</strong> no canto inferior direito do '
        'retrato, dentro da janela da Saga do Herói. Uma vez só por personagem.</p>'
    )

    h.append('  <h2>Antes de começar</h2>')
    h.append(
        '  <p>A saga pede <strong>nível <span class="algarismos">80</span> de pico '
        'histórico</strong> e <strong>cultivo Mahayana</strong>. E vale esperar: '
        '<strong>a experiência das missões escala até o nível '
        '<span class="algarismos">100</span></strong> e para de crescer ali, então '
        'fazer antes disso é jogar fora boa parte do que a saga paga.</p>'
    )

    h.append('  <h2>Como abrir</h2>')
    h.append(f'  <p>{_rico(s["comecar"])}</p>')

    if s.get('avisos'):
        h.append('  <h2>O que costuma travar</h2>')
        h.append('  <div class="aviso">')
        for a in s['avisos']:
            h.append(f'    <p>{_rico(a)}</p>')
        h.append('  </div>')

    h.append(f'  <h2>As {_titulo(str(len(s["passos"])))} missões, em ordem</h2>')
    h.append('  <ol class="passos">')
    for passo in s['passos']:
        h.append(f'    <li>{_rico(passo)}</li>')
    h.append('  </ol>')
    # O baú não é missão, e contá-lo como uma punha o número do título um
    # acima da verdade — foi o que o dono apanhou na primeira página. Fica
    # aqui fora da lista numerada, que é o lugar certo: é o que se faz
    # depois da última missão, não mais uma delas.
    #
    # E diz parabéns, a pedido do dono. Quarenta missões é muita coisa, e a
    # versão anterior fechava com «e a saga termina» no fim do passo 40 —
    # a frase mais fria possível para o fim de uma tarde de trabalho. Aqui
    # vale a mesma regra que mantém o dourado fora dos números: ele é a cor
    # do que importa, e esta é a única vez que a página o usa num bloco
    # inteiro.
    h.append('  <div class="remate">')
    h.append(f'    <p class="parabens">Parabéns! Você terminou a Saga do Herói '
             f'{_artigo(s)} {_escapar(s["classe"])}.</p>')
    h.append(
        f'    <p>Volte à janela da Saga do Herói, abra o retrato de '
        f'{_escapar(s["heroi"])} e clique no baú para pegar '
        f'<strong>{_escapar(s["ovo"])}</strong> e o título '
        f'<strong>{_escapar(s["titulo"])}</strong>, que vale '
        f'<strong>+100 de HP</strong>.</p>'
    )
    h.append('  </div>')

    if s.get('nota'):
        h.append(f'  <div class="aviso"><p>{_rico(s["nota"])}</p></div>')

    h.append('  <hr>')
    h.append(
        '  <p style="color: var(--text-muted); font-size: 0.85rem;">'
        'Conferido contra a <a href="https://wikipw.com.br/">Wiki PW</a>, o '
        '<a href="https://triviapw.com.br/">Trivia PW</a> e a '
        '<a href="https://pwi.fandom.com/wiki/Perfect_World_Hero_Saga">PWpedia</a>. '
        'Achou um passo diferente no jogo? Conte no '
        '<a href="https://discord.gg/n5v3WdSJyg">Discord</a> que a gente corrige.</p>'
    )
    h.append('  <p><a href="/guias/saga-do-heroi/">&larr; As dezessete sagas</a></p>')
    h.append('')
    return '\n'.join(h) + RODAPE


def pagina_indice():
    """The hub: the comparison table nobody else publishes."""
    url = 'https://portalpw.net/guias/saga-do-heroi/'
    desc = ('As 17 Sagas do Herói do The Classic 1.8.7 lado a lado: o herói, o ovo de '
            'mascote, o título de +100 de HP e quantas missões cada uma tem.')
    h = [cabeca('Saga do Herói: as 17 classes', desc, url, 'Saga do Herói')]

    h.append(f'  <h1>{_titulo("Saga do Herói: as 17 classes")}</h1>')
    h.append(
        '  <p class="resumo">Cada classe tem a sua: uma linha de missões que conta a '
        'história do herói dela e termina num mascote para o Códice e num título de '
        '<span class="algarismos">+100</span> de HP. Esta é a tabela das dezessete '
        'lado a lado — e depois, uma página por classe com as missões em ordem.</p>'
    )

    # **A grade vem antes das regras, e antes da tabela.** Quem chega aqui
    # chega por uma classe — a sua — e reconhece-a pela arte antes de ler
    # qualquer nome. A tabela continua por baixo porque responde a outra
    # pergunta, a de quem ainda não escolheu: qual delas é a mais curta.
    h.append('  <div class="grade-classes">')
    for s in SAGAS:
        h.append(
            f'    <a class="carta-classe" href="/guias/saga-do-heroi/{s["slug"]}">'
            f'<img src="img/{_arte(s)}" alt="Arte do {_escapar(s["classe"])}" loading="lazy">'
            f'<span>{_escapar(s["classe"])}</span></a>'
        )
    h.append('  </div>')

    h.append('  <h2>As regras, que valem para todas</h2>')
    h.append('  <ul>')
    h.append('    <li><strong>Abre com nível <span class="algarismos">80</span> de pico histórico e cultivo Mahayana.</strong> Pico histórico: se você já passou do <span class="algarismos">80</span> alguma vez, conta.</li>')
    h.append('    <li><strong>Fica em Missões, na quarta aba</strong> — <em>Saga do Herói</em>. Os heróis aparecem em retratos, três por vez, e as setas dos lados trocam de raça.</li>')
    h.append('    <li><strong>Espere o nível <span class="algarismos">100</span>.</strong> A experiência das missões cresce com o seu nível e trava no <span class="algarismos">100</span>. Fazer no <span class="algarismos">80</span> entrega o mesmo mascote e bem menos experiência.</li>')
    h.append('    <li><strong>A recompensa sai do baú</strong>, no canto inferior direito do retrato do herói. Uma vez por personagem.</li>')
    h.append('    <li><strong>Você não precisa ser da classe</strong> para fazer a saga dela. O que muda é só qual retrato você abre.</li>')
    h.append('  </ul>')

    h.append('  <h2>As dezessete</h2>')
    h.append('  <div class="rolagem">')
    h.append('  <table>')
    h.append('    <thead><tr><th>Classe</th><th>Herói</th><th>Mascote</th><th>Título</th><th>Missões</th></tr></thead>')
    h.append('    <tbody>')
    for s in SAGAS:
        n = str(len(s['passos'])) if s['passos'] else '—'
        h.append(
            f'      <tr><td><a href="/guias/saga-do-heroi/{s["slug"]}">{_escapar(s["classe"])}</a></td>'
            f'<td>{_escapar(s["heroi"])}</td><td>{_escapar(s["ovo"])}</td>'
            f'<td>{_escapar(s["titulo"])}</td><td class="num">{n}</td></tr>'
        )
    h.append('    </tbody>')
    h.append('  </table>')
    h.append('  </div>')

    for bloco in GERAL:
        h.append(f'  <h2>{_titulo(bloco["titulo"])}</h2>')
        for par in bloco['paragrafos']:
            h.append(f'  <p>{_rico(par)}</p>')

    h.append('  <hr>')
    h.append(
        '  <p style="color: var(--text-muted); font-size: 0.85rem;">'
        'Levantado a partir da <a href="https://wikipw.com.br/">Wiki PW</a>, do '
        '<a href="https://triviapw.com.br/">Trivia PW</a> e da '
        '<a href="https://pwi.fandom.com/wiki/Perfect_World_Hero_Saga">PWpedia</a>, '
        'que é a fonte em inglês e a única com todas numa página só.</p>'
    )
    h.append('')
    return '\n'.join(h) + RODAPE


def _conferir_artes():
    """A arte declarada tem de existir em disco.

    Nove das dezassete não têm retrato do herói em lado nenhum — as páginas
    novas do wikipw são texto puro — e por isso `arte` é `None` nelas. O erro
    que esta função apanha é o outro: declarar um ficheiro e não o ter, que
    desenha o ícone de imagem partida em vez de simplesmente não desenhar
    nada. Falha aqui, onde se vê, em vez de no browser de quem visita.
    """
    faltam = [
        _arte(s) for s in SAGAS
        if not os.path.exists(os.path.join(RAIZ, 'img', _arte(s)))
    ]
    if faltam:
        raise SystemExit(
            'Arte declarada e ausente em web/guias/saga-do-heroi/img/: '
            + ', '.join(faltam)
        )


def main():
    os.makedirs(RAIZ, exist_ok=True)
    _conferir_artes()
    escritos = []
    for s in SAGAS:
        destino = os.path.join(RAIZ, s['slug'] + '.html')
        with open(destino, 'w', encoding='utf-8') as f:
            f.write(pagina_da_classe(s))
        escritos.append(destino)
    destino = os.path.join(RAIZ, 'index.html')
    with open(destino, 'w', encoding='utf-8') as f:
        f.write(pagina_indice())
    escritos.append(destino)
    print(f'{len(escritos)} páginas escritas em {os.path.normpath(RAIZ)}')


if __name__ == '__main__':
    main()
