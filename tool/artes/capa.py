"""Monta a capa do herói: as dezassete artes de classe numa só imagem.

**A arte ao alto em vez de deitada, e é daí que vem a nitidez.** O herói é uma
faixa larga e baixa — a largura da página por 760 px — e uma arte 960×1440
posta a cobri-la é esticada pela *largura*: 1,48× numa janela de 1420, 2× numa
de 1920, o que em píxeis de ecrã retina são 2,96× e 4×. Era isso que amolecia o
rosto, e não havia arte maior em lado nenhum: procurou-se no site oficial
brasileiro (952×880, menos do que já temos), no oficial chinês (outra arte, 800
px) e no do servidor (ícones de 36×36).

Posta **de pé**, a mesma arte enche os 1520 px de altura da faixa em píxeis de
ecrã a **1,06×** — praticamente sem ampliação. Dezassete delas lado a lado
enchem a largura sem que nenhuma seja esticada.

O que isto custa por visita, medido: a home buscava uma classe a 140 KB e passa
a buscar esta a 281 KB. São +141 KB para mostrar dezassete em vez de uma, com o
dobro da nitidez.

**O fio de noite entre as tiras é deliberado.** Encostadas, duas faces vizinhas
tocam-se e lê-se como uma figura a invadir a outra; desvanecidas umas nas
outras ficam uma pintura só e deixa de se perceber que são dezassete coisas. O
fio diz *são dezassete classes* na mesma linguagem do filete que abre cada
secção do site.

**O tamanho é 2840×1520 e não é arbitrário:** é exactamente a faixa a 1420 px
num ecrã retina, portanto ali fica 1:1 e as dezassete aparecem todas. Mais
largo que isso, o `cover` corta em cima e em baixo e as dezassete continuam lá;
mais estreito, corta pelos lados.

Correr: python3 tool/artes/capa.py
"""

import glob
import os

from PIL import Image, ImageDraw, ImageStat

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
FONTE = os.path.join(RAIZ, 'assets', 'images', 'classes-verticais', '960')
DESTINO = os.path.join(RAIZ, 'assets', 'images', 'capa-classes.webp')

NOITE = (11, 11, 26)
LARGURA, ALTURA = 2840, 1520
FIO = 6
QUALIDADE = 78

# **Duas das dezassete trazem o logótipo da Perfect World pintado na arte**, e
# ele não pode ir para a capa: este site diz em todas as páginas que é projecto
# de fã sem vínculo, e uma marca do editor na primeira dobra contradiz isso
# sem uma palavra.
#
# Medido a 10/11/2026 sobre os ficheiros: no sacerdote o `PERFECT WORLD` ocupa
# de 13% a 73% da largura e de 77% a 95% da altura — larga de mais para a
# evitar escolhendo outra fatia, porque a tira leva ~16% da largura e o que
# sobra limpo é a borda. No místico aparece só o topo de um `P` no canto
# inferior esquerdo.
#
# Aparar pelo fundo é o que custa menos: o que fica é reescalado para encher a
# faixa, portanto o sacerdote passa a 1,30× e o místico a 1,09×, contra os
# 1,06× das outras quinze. Continua tudo abaixo do 1,48× que o herói tinha
# antes de isto existir.
APARAR_EM_BAIXO = {'sacerdote': 0.50, 'mistico': 0.08}

# **Onde está o rosto em cada arte, em fracção da largura.** Lido à mão de uma
# grelha de 10% sobre o terço de cima das dezassete, a 10/11/2026 — do mesmo
# modo que as linhas dos Registos foram contadas de fotografias da janela do
# jogo, e pela mesma razão: a medição automática chegou perto e não chegou lá.
#
# O que ela faz e onde falha: procurar pele no topo e tomar a janela mais
# densa acerta em doze das dezassete, e nas outras cinco a maior mancha de
# pele não é uma cara — é uma perna do Mago, um braço da Atiradora, o fundo
# cor de fogo do Guerreiro. Nenhum limiar separa isso, porque a regra de pele
# em RGB não sabe o que é uma cara.
#
# A tabela manda e o automático é a rede: uma classe que entre amanhã sem
# linha aqui continua a ser enquadrada sozinha, em vez de cair no meio — que
# era o palpite que deixava o Bardo, o Ceifador e o Mercenário só com
# cenário, e foi o que o dono viu.
ROSTO_EM = {
    'andarilho': 0.47,
    'arcano': 0.50,
    'arqueiro': 0.37,
    'atiradora': 0.63,
    # **O Bárbaro não tem rosto nesta arte** — é todo armadura, e varrer a
    # largura inteira não encontra cara nenhuma. Fica no tigre branco, que é a
    # assinatura da classe e lê-se tão bem como um rosto.
    'barbaro': 0.50,
    'bardo': 0.88,
    'ceifador': 0.80,
    'espiritualista': 0.12,
    'feiticeira': 0.50,
    'guerreiro': 0.40,
    'mago': 0.50,
    'mercenario': 0.18,
    'mistico': 0.47,
    'paladino': 0.62,
    'retalhador': 0.62,
    'sacerdote': 0.50,
    'tormentador': 0.58,
}


def _foco(cena, janela):
    """Onde cortar a tira de [janela] píxeis de largura, em píxeis de origem.

    **A tira leva ~16% da largura da arte, e cravá-la no meio falhava.** As
    dezassete não têm a figura centrada: o Bardo, o Ceifador e o Mercenário
    saíam só com cenário, que foi o que o dono viu — *«tem alguns que não se
    vê nada»*.

    Procura-se pele no **terço de cima**, que é onde um rosto está nestas
    artes, e escolhe-se a janela que apanha mais. **A janela mais densa e não
    o centro de massa**, e a diferença não é subtil: a regra de pele em RGB
    também acende em fogo e em couro, portanto o Mago mede 59% de «pele» que
    é fundo laranja e o Guerreiro 73%. Uma média é puxada por essa mancha
    para longe da cara; a janela mais densa ignora-a, porque o pico continua a
    estar onde o rosto está.

    Sem pele nenhuma que chegue, cai-se na energia de borda — onde o desenho
    tem mais detalhe. Nunca no meio por omissão: o meio é precisamente o
    palpite que não funcionou.
    """
    W, H = cena.size
    topo = round(H * 0.34)
    px = cena.load()
    passo = 3

    coluna = [0] * W
    peso = 0
    for y in range(0, topo, passo):
        for x in range(0, W, passo):
            r, g, b = px[x, y]
            if (
                r > 95
                and g > 40
                and b > 20
                and max(r, g, b) - min(r, g, b) > 15
                and abs(r - g) > 15
                and r > g
                and r > b
            ):
                coluna[x] += 1
                peso += 1

    amostras = len(range(0, topo, passo)) * len(range(0, W, passo))
    # 0,4% é o mínimo para um rosto contar como rosto; abaixo disso é ruído de
    # madeira ou de couro, e há arte com a cara tapada por elmo.
    if peso <= amostras * 0.004:
        cinza = cena.convert('L')
        g = cinza.load()
        coluna = [0] * W
        for y in range(1, topo, 2):
            for x in range(1, W, 2):
                coluna[x] += abs(g[x, y] - g[x - 1, y]) + abs(g[x, y] - g[x, y - 1])

    janela = min(janela, W)
    soma = sum(coluna[:janela])
    melhor, melhor_x = soma, 0
    for x in range(1, W - janela + 1):
        soma += coluna[x + janela - 1] - coluna[x - 1]
        if soma > melhor:
            melhor, melhor_x = soma, x
    return melhor_x


def _luz(caminho):
    """A luminosidade média da arte, de 0 a 255."""
    return ImageStat.Stat(Image.open(caminho).convert('L')).mean[0]


def montar():
    fs = glob.glob(os.path.join(FONTE, '*.webp'))
    if not fs:
        raise SystemExit(f'nenhuma arte em {FONTE}')

    # **As escuras à esquerda, e não por gosto.** O texto do herói ocupa o
    # primeiro terço, e o véu que o assenta foi medido na maquete contra uma
    # pintura cujo lado esquerdo já era escuro. Com as dezassete por ordem
    # alfabética calhava ali o Andarilho a 116 e o Arcano a 134, e a manchete
    # ficava a competir com arte clara — via-se logo no telemóvel, onde a
    # faixa é mais estreita e o texto ocupa quase tudo.
    #
    # Por luz crescente, o Tormentador (51) e o Mercenário (60) abrem, e o
    # Bardo (174) e o Ceifador (156) ficam no fim, onde não há letra nenhuma.
    # Custa zero e evita mexer no véu, que é número da maquete.
    fs.sort(key=_luz)

    tela = Image.new('RGB', (LARGURA, ALTURA), NOITE)
    larg = LARGURA / len(fs)

    for i, f in enumerate(fs):
        cena = Image.open(f).convert('RGB')

        apara = APARAR_EM_BAIXO.get(os.path.basename(f)[:-5], 0.0)
        if apara:
            cena = cena.crop((0, 0, cena.width, round(cena.height * (1 - apara))))

        # A altura manda: a arte enche os 1520 e a largura sai do que calhar.
        # É este o passo que faz a escala ser 1,06x em vez de 1,48x.
        escala = ALTURA / cena.height
        g = cena.resize((round(cena.width * escala), ALTURA), Image.LANCZOS)

        x0, x1 = round(i * larg), round((i + 1) * larg)
        lw = x1 - x0
        nome = os.path.basename(f)[:-5]

        rosto = ROSTO_EM.get(nome)
        if rosto is None:
            # O foco é calculado na arte de origem e convertido, para a conta
            # não depender do tamanho a que a tira foi reescalada.
            corte = round(_foco(cena, round(lw / escala)) * escala)
        else:
            corte = round(rosto * g.width) - lw // 2
        corte = min(max(0, corte), g.width - lw)
        tela.paste(g.crop((corte, 0, corte + lw, ALTURA)), (x0, 0))

    d = ImageDraw.Draw(tela)
    for i in range(1, len(fs)):
        x = round(i * larg)
        d.line([(x, 0), (x, ALTURA)], fill=NOITE, width=FIO)

    for nome in APARAR_EM_BAIXO:
        if not os.path.exists(os.path.join(FONTE, f'{nome}.webp')):
            raise SystemExit(
                f'{nome} está na lista de aparar e não existe em {FONTE} — '
                'ou mudou de nome, ou o logótipo voltou sem ninguém dar por ele'
            )

    tela.save(DESTINO, 'WEBP', quality=QUALIDADE, method=6)
    print(
        f'{len(fs)} classes -> {DESTINO} '
        f'({LARGURA}x{ALTURA}, {os.path.getsize(DESTINO) // 1024} KB)'
    )


if __name__ == '__main__':
    montar()
