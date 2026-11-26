#!/usr/bin/env python3
"""Renders the Anedotas do Céu catalogue — one filterable page.

The ten Limites de Céu are the PWI "Sky Quest Chain" lineage; the BR game also
names its own story arcs (Crônica dos Deuses, Memória dos Gigantes, …) that do
not line up one-to-one with the Limites. So every arc carries a `ceu` tag, and
the page can be filtered by **either** axis — por Céu or por Arco — which is
what the owner asked for. One Céu (Soberano) gathers several arcs.

Kept as a single static page, in `/guias/`, on purpose: it stays indexable by
Google (the filter is client-side JavaScript that only hides and shows what is
already in the DOM), which an in-app canvas tool would lose. `paginas_html_test`
checks the AdSense tag, the `/privacidade/` link and that every image exists.

Run: python3 tool/anedotas/pagina.py
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from anedotas import GERAL, REINOS, ARCOS_EXTRA  # noqa: E402

RAIZ = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), '..', '..', 'web', 'guias',
    'anedotas-do-ceu',
)

ADSENSE = '''  <!-- AdSense. O número de editor é público por desenho — ele vai no bundle de
       toda a gente e também no `ads.txt` na raiz. Só onde há conteúdo do editor. -->
  <script async
          src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-7064703455080324"
          crossorigin="anonymous"></script>'''

# Estilo dos chips e das secções de arco. Inline porque é só desta página, e
# reusa as variáveis que `web/guias/estilo.css` já define.
STYLE = '''  <style>
    .filtros { margin: 1.6rem 0 0.4rem; }
    .filtros .grupo { margin-bottom: 0.9rem; }
    .filtros h3 { font-size: 0.72rem; letter-spacing: 1.3px; text-transform: uppercase;
      color: var(--text-muted); margin: 0 0 0.5rem; font-weight: 700; }
    .chips { display: flex; flex-wrap: wrap; gap: 0.4rem; }
    .chip { border: 1px solid var(--border); background: transparent; color: var(--text-muted);
      border-radius: 999px; padding: 0.34rem 0.82rem; font-size: 0.85rem; cursor: pointer;
      font-family: inherit; line-height: 1.2; }
    .chip:hover { border-color: var(--text-muted); }
    .chip.on { border-color: var(--accent); color: var(--accent); background: rgba(255,180,84,0.12); }
    .chip.limpar { color: var(--text-muted); border-style: dashed; }
    .arco { margin: 2.2rem 0; padding-top: 1.4rem; border-top: 1px solid var(--border); }
    .arco .badge { display: inline-block; font-size: 0.72rem; letter-spacing: 0.6px;
      text-transform: uppercase; color: var(--accent); border: 1px solid var(--border);
      border-radius: 999px; padding: 0.15rem 0.6rem; margin-bottom: 0.5rem; }
    #vazio { color: var(--text-muted); font-size: 0.95rem; padding: 1.5rem 0; }
  </style>'''


def _titulo(texto):
    return re.sub(
        r'\d[\d.]*',
        lambda m: f'<span class="algarismos">{m.group(0)}</span>',
        texto,
    )


def _escapar(texto):
    return (texto.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;'))


def _rico(texto):
    """As quatro marcas — **negrito**, *itálico*, `coord`, [texto](url) — mais
    a quebra de linha, que serve os `comecar` de duas missões de desbloqueio."""
    t = _escapar(texto)
    t = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', t)
    t = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', t)
    t = re.sub(r'(?<!\*)\*([^*\n]+)\*(?!\*)', r'<em>\1</em>', t)
    t = re.sub(r'`([^`]+)`', r'<code>\1</code>', t)
    t = t.replace('\n', '<br>\n')
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
{STYLE}
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


FONTE = (
    '  <hr>\n'
    '  <p style="color: var(--text-muted); font-size: 0.85rem;">'
    'Os Limites de Arcano a Ápice vêm da '
    '<a href="https://pwi.fandom.com/wiki/Perfect_World_Anecdote">PWpedia</a> '
    '(as coordenadas batem com o BR ±1); os arcos de expansão brasileira — '
    'Majestoso, Soberano, Crônica dos Deuses, Memória dos Gigantes — vêm do '
    'guia BR da <a href="https://triviapw.com.br/">Trivia PW</a>, recuperado '
    'pela Wayback Machine. Achou um passo diferente no jogo? Conte no '
    '<a href="https://discord.gg/n5v3WdSJyg">Discord</a> que a gente corrige.</p>'
)


def _ceus():
    """Os dez Limites, na ordem do jogo — o eixo *por Céu*."""
    return [
        {
            'slug': r['slug'],
            'nome': r['ceu'],
            'requisito': r['requisito'],
            'resumo': r['resumo'],
        }
        for r in REINOS
    ]


def _arcos():
    """Todos os arcos, ordenados por Céu — o principal de cada Limite, e depois
    os arcos extras que pertencem a esse mesmo Céu."""
    # Um arco por Limite, derivado do REINO (o `ceu`-slug é o próprio slug).
    principais = {
        r['slug']: {
            'slug': r['slug'],
            'nome': r['ceu'],
            'ceu': r['slug'],
            'extra': False,
            'requisito': r['requisito'],
            'ordem': r.get('ordem', ''),
            'resumo': r['resumo'],
            'comecar': r['comecar'],
            'passos': r['passos'],
            'nota': r.get('nota', ''),
        }
        for r in REINOS
    }
    extras_por_ceu = {}
    for a in ARCOS_EXTRA:
        extras_por_ceu.setdefault(a['ceu'], []).append({**a, 'extra': True})

    ordenados = []
    for r in REINOS:
        ordenados.append(principais[r['slug']])
        for e in extras_por_ceu.get(r['slug'], []):
            ordenados.append(e)
    return ordenados


def _nome_do_ceu(slug):
    for r in REINOS:
        if r['slug'] == slug:
            return r['ceu']
    return slug


def _seccao_do_arco(a):
    h = [f'  <section class="arco" data-ceu="{a["ceu"]}" data-arco="{a["slug"]}">']
    if a['extra']:
        h.append(f'    <span class="badge">{_escapar(_nome_do_ceu(a["ceu"]))}</span>')
    h.append(f'    <h2>{_titulo(a["nome"])}</h2>')
    req = a['requisito']
    if a.get('ordem'):
        req = f'{req} — {a["ordem"]}'
    h.append(f'    <p class="resumo">{_rico(a["resumo"])}</p>')
    h.append('    <div class="aviso">')
    h.append(f'      <p><strong>Requisito:</strong> {_rico(req)}.</p>')
    h.append('    </div>')
    if a.get('comecar'):
        h.append('    <h3>Como destravar</h3>')
        h.append(f'    <p>{_rico(a["comecar"])}</p>')
    if a['passos']:
        h.append('    <h3>As missões, em ordem</h3>')
        h.append('    <ol class="passos">')
        for passo in a['passos']:
            h.append(f'      <li>{_rico(passo)}</li>')
        h.append('    </ol>')
    if a.get('nota'):
        h.append(f'    <div class="aviso"><p>{_rico(a["nota"])}</p></div>')
    h.append('  </section>')
    return '\n'.join(h)


def _filtros(ceus, arcos):
    h = ['  <div class="filtros">']
    h.append('    <div class="grupo">')
    h.append('      <h3>Filtrar por Céu</h3>')
    h.append('      <div class="chips">')
    for c in ceus:
        h.append(
            f'        <button class="chip" type="button" data-tipo="ceu" '
            f'data-val="{c["slug"]}">{_escapar(c["nome"])}</button>'
        )
    h.append('      </div>')
    h.append('    </div>')
    h.append('    <div class="grupo">')
    h.append('      <h3>Filtrar por Arco de história</h3>')
    h.append('      <div class="chips">')
    # Só os arcos de nome próprio. O arco principal de cada Limite tem o nome
    # do Céu, portanto já está no filtro de cima — repeti-lo aqui seria
    # redundante e confuso.
    for a in arcos:
        if not a.get('extra'):
            continue
        h.append(
            f'        <button class="chip" type="button" data-tipo="arco" '
            f'data-val="{a["slug"]}">{_escapar(a["nome"])}</button>'
        )
    h.append(
        '        <button class="chip limpar" type="button" id="limpar">limpar</button>'
    )
    h.append('      </div>')
    h.append('    </div>')
    h.append('  </div>')
    return '\n'.join(h)


# O filtro: esconde e mostra o que já está no DOM, portanto o conteúdo continua
# todo indexável. Dois eixos independentes que se cruzam; clicar de novo no
# mesmo chip desliga-o.
SCRIPT = '''  <script>
  (function () {
    var fc = null, fa = null;
    var arcos = Array.prototype.slice.call(document.querySelectorAll('.arco'));
    var chips = Array.prototype.slice.call(document.querySelectorAll('.chip'));
    var vazio = document.getElementById('vazio');
    function aplicar() {
      var n = 0;
      arcos.forEach(function (s) {
        var ok = (!fc || s.getAttribute('data-ceu') === fc) &&
                 (!fa || s.getAttribute('data-arco') === fa);
        s.hidden = !ok;
        if (ok) n++;
      });
      chips.forEach(function (c) {
        var t = c.getAttribute('data-tipo'), v = c.getAttribute('data-val');
        var on = (t === 'ceu' && v === fc) || (t === 'arco' && v === fa);
        c.classList.toggle('on', on);
      });
      if (vazio) vazio.hidden = n > 0;
    }
    chips.forEach(function (c) {
      if (c.id === 'limpar') {
        c.addEventListener('click', function () { fc = null; fa = null; aplicar(); });
        return;
      }
      c.addEventListener('click', function () {
        var t = c.getAttribute('data-tipo'), v = c.getAttribute('data-val');
        if (t === 'ceu') fc = (fc === v) ? null : v;
        else fa = (fa === v) ? null : v;
        aplicar();
      });
    });
  })();
  </script>'''


def pagina_catalogo():
    url = 'https://portalpw.net/guias/anedotas-do-ceu/'
    desc = ('As anedotas do céu do The Classic 1.8.7: os dez Limites de Céu e '
            'os arcos de história, com as missões e as coordenadas — filtrável '
            'por Céu ou por Arco.')
    ceus = _ceus()
    arcos = _arcos()
    h = [cabeca('Anedotas do Céu', desc, url, 'Anedotas do Céu')]

    h.append(f'  <h1>{_titulo("Anedotas do Céu")}</h1>')
    h.append(
        '  <p class="resumo">As anedotas são o diário de missões do jogo. Os '
        'dez <strong>Limites de Céu</strong> (de Arcano a Soberano) são a '
        'espinha, mas algumas anedotas têm nome próprio — Crônica dos Deuses, '
        'Memória dos Gigantes — e cobrem o mesmo Céu por outro ângulo. Filtre '
        'por um ou por outro.</p>'
    )

    h.append(_filtros(ceus, arcos))
    h.append('  <p id="vazio" hidden>Nenhum arco com esse par de filtros. '
             'Toque em <strong>limpar</strong>.</p>')

    for a in arcos:
        h.append(_seccao_do_arco(a))

    # Os blocos gerais, no fim — valem para todos.
    for bloco in GERAL:
        h.append(f'  <h2>{_titulo(bloco["titulo"])}</h2>')
        for par in bloco['paragrafos']:
            h.append(f'  <p>{_rico(par)}</p>')

    h.append(FONTE)
    h.append(SCRIPT)
    h.append('')
    return '\n'.join(h) + RODAPE


def main():
    os.makedirs(RAIZ, exist_ok=True)
    # Um catálogo só, filtrável — as dez páginas por Limite deram lugar a ele.
    for antigo in os.listdir(RAIZ):
        if antigo.endswith('.html') and antigo != 'index.html':
            os.remove(os.path.join(RAIZ, antigo))
    destino = os.path.join(RAIZ, 'index.html')
    with open(destino, 'w', encoding='utf-8') as f:
        f.write(pagina_catalogo())
    print(f'catálogo escrito em {os.path.normpath(destino)}')


if __name__ == '__main__':
    main()
