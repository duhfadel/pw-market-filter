"""Trims the screenshot frame off the vertical class art.

The seventeen 480x720 crops in `assets/images/classes-verticais/` were cut by
hand out of 946x2049 phone screenshots, and eight of them took a band of the
screenshot with them: a black bar from the top of the capture, or — worse — a
strip of whatever sat *below* the artwork on that page. The Guerreiro's was
74 px tall, a tenth of the card, holding two unrelated thumbnails; the Ceifador
and the Mago carry smaller versions of the same thing.

It was invisible for as long as the art only ever appeared on the home's
Destaques cards, because their veil is at its darkest exactly where the band
sits. The chooser's doors put the same art on a card with a shorter footer, and
the Guerreiro's seam showed on the first screenshot — which is the lesson worth
keeping: a veil that hides a defect is not a veil that fixed it.

The bands were found by measuring, not by eye: the mean row-to-row difference
down each image is a flat few units through real artwork and spikes above 90
at a stitch. `encontrar_costuras()` is that scan, kept here so a new art can be
checked the same way instead of trusted.

Each image is cropped to its clean rows, then to the widest 2:3 window centred
in them, then resized back to 480x720 — the shape every card on the site cuts
these to. Making the file 2:3 rather than leaving it short is deliberate: a
short file renders identically under `BoxFit.cover`, so the only thing the
asset would gain by staying short is the ability to disagree with what the
screen shows.

Run: python3 tool/artes/aparar.py
"""

import pathlib
import statistics

from PIL import Image

PASTA = pathlib.Path("assets/images/classes-verticais")
LADO = (480, 720)

# First and last clean row of each image that needed one, read off the scan
# below. A class absent from here was measured and found clean.
LIMPO = {
    "andarilho": (36, 713),
    "arqueiro": (12, 720),
    "bardo": (0, 718),
    "ceifador": (0, 691),
    "feiticeira": (2, 720),
    "guerreiro": (0, 646),
    "mago": (0, 694),
    "retalhador": (0, 718),
}


def encontrar_costuras(imagem):
    """Rows where the picture changes abruptly enough to be a stitch.

    Returns `(mediana, [(linha, salto)])`. A real painting runs at a median of
    three to seven; a stitched-in strip of another screenshot lands at 90+.
    """
    largura, altura = imagem.size
    px = imagem.load()
    saltos = []
    for y in range(1, altura):
        soma = 0
        for x in range(0, largura, 4):
            a, b = px[x, y - 1], px[x, y]
            soma += abs(a[0] - b[0]) + abs(a[1] - b[1]) + abs(a[2] - b[2])
        saltos.append((soma / (largura / 4) / 3, y))
    mediana = statistics.median(s for s, _ in saltos)
    limiar = max(40, mediana * 8)
    return mediana, [(y, round(s, 1)) for s, y in saltos if s > limiar]


def aparar(caminho, topo, base):
    """Crops to the clean rows, then to a centred 2:3 window, then to 480x720."""
    imagem = Image.open(caminho).convert("RGB")
    largura, _ = imagem.size
    imagem = imagem.crop((0, topo, largura, base))
    altura = base - topo

    # The widest 2:3 window the clean rows can hold. Centred horizontally
    # because nothing here says where the figure is, and every one of these
    # crops was framed on its subject to begin with.
    alvo = round(altura * LADO[0] / LADO[1])
    if alvo < largura:
        margem = (largura - alvo) // 2
        imagem = imagem.crop((margem, 0, margem + alvo, altura))
    else:
        alvo = round(largura * LADO[1] / LADO[0])
        margem = (altura - alvo) // 2
        imagem = imagem.crop((0, margem, largura, margem + alvo))

    imagem.resize(LADO, Image.LANCZOS).save(caminho, "WEBP", quality=88)


def main():
    for nome, (topo, base) in sorted(LIMPO.items()):
        caminho = PASTA / f"{nome}.webp"
        aparar(caminho, topo, base)
        print(f"{nome}: linhas {topo}-{base} mantidas")

    print()
    for caminho in sorted(PASTA.glob("*.webp")):
        mediana, costuras = encontrar_costuras(Image.open(caminho).convert("RGB"))
        estado = costuras if costuras else "limpa"
        print(f"{caminho.stem}: mediana {mediana:.2f} · {estado}")


if __name__ == "__main__":
    main()
