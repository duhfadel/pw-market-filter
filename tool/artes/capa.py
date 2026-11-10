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
        # A altura manda: a arte enche os 1520 e a largura sai do que calhar.
        # É este o passo que faz a escala ser 1,06x em vez de 1,48x.
        escala = ALTURA / cena.height
        g = cena.resize((round(cena.width * escala), ALTURA), Image.LANCZOS)

        x0, x1 = round(i * larg), round((i + 1) * larg)
        meio = g.width // 2
        corte = meio - (x1 - x0) // 2
        tela.paste(g.crop((corte, 0, corte + (x1 - x0), ALTURA)), (x0, 0))

    d = ImageDraw.Draw(tela)
    for i in range(1, len(fs)):
        x = round(i * larg)
        d.line([(x, 0), (x, ALTURA)], fill=NOITE, width=FIO)

    tela.save(DESTINO, 'WEBP', quality=QUALIDADE, method=6)
    print(
        f'{len(fs)} classes -> {DESTINO} '
        f'({LARGURA}x{ALTURA}, {os.path.getsize(DESTINO) // 1024} KB)'
    )


if __name__ == '__main__':
    montar()
