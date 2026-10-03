"""Turns a streamer's own picture into the 690x231 plate the card expects.

**The card does not scale a picture to fit — it reads one.** `ao_vivo_strip`
treats the file as a banner whose left 170 px is the emblem and whose
remaining 520 px is scenery: the emblem column is cut by `BoxFit.cover` on
the card's *height*, and `CenarioDoBanner` reaches past the emblem for the
texture that sits behind the facts. A square or portrait file handed to that
geometry gets its middle cropped out and its subject lost — which is what
happened the first time art arrived, nearly square at 4.87 MB, and again when
pavaotv's 1024x1536 mascot arrived.

So the plate is authored rather than uploaded raw:

* the subject is cropped to the emblem's own 170x231, scaled down into it so
  it keeps its edges;
* the scenery is a *different* part of the same picture — the wall, the
  feathers, whatever the subject is standing against — blurred and dimmed.
  Blurring the whole picture instead puts an out-of-focus copy of the subject
  behind the sharp one, which reads as a smear rather than as a backdrop;
* the join is a soft ramp, because a vertical seam is the one artefact a
  reader takes for damage rather than for style.

Run:
  python3 tool/artes/placa_streamer.py <origem> <login> \
      --sujeito x0 y0 x1 y1 [--cenario x0 y0 x1 y1]

Both boxes are in the source image's own pixels. `--cenario` defaults to the
whole picture, which is right only when the subject does not dominate it.
The output lands beside the source as `<login>.webp`, under the bucket's
512 KB ceiling, ready to drag into the Supabase dashboard — nothing here
holds a key that may write to that bucket, and that is deliberate.
"""

import argparse
import pathlib

from PIL import Image, ImageChops, ImageEnhance, ImageFilter

LARGURA, ALTURA = 690, 231
EMBLEMA = 170

# The card's own panel colour, `PWColors.surface`. The scenery is screened
# over it so it can never come out darker than the card it sits on — see
# `_cenario`.
SUPERFICIE = (0x13, 0x13, 0x2A)

# The brightest the scenery is allowed to be, as a median luminance. Measured
# off the two plates already on the site that read well: gsafoot's wall at 56
# and pavaotv's feathers at 80. It is a **ceiling, never a floor** — see
# `_cenario` for why pulling a dark banner up was tried and thrown away.
LUMINANCIA_ALVO = 62

# How far the emblem's right edge takes to dissolve into the scenery. Short
# enough that the subject keeps its outline, long enough that no vertical
# line survives.
RAMPA = 46


def _luminancia(cor):
    return 0.2126 * cor[0] + 0.7152 * cor[1] + 0.0722 * cor[2]


def _mediana(imagem):
    """The median pixel of an image, channel by channel."""
    px = list(imagem.getdata())
    return tuple(
        sorted(p[canal] for p in px)[len(px) // 2] for canal in range(3)
    )


def _cenario(imagem):
    """The backdrop: blurred, pulled towards a known brightness, never a hole.

    **A fixed dimming factor was wrong and it took a dark banner to show it.**
    Multiplying by 0.6 suits a brightly lit wall and ruins a night sky:
    penumbrapw's starfield came out at a luminance of 2 against the card's own
    21, so the right half of the card would have been a black rectangle — a
    hole, read as a rendering fault rather than as a backdrop.

    **Brightening it was the obvious fix and it was worse.** Pulling that sky
    up to the target meant a gain of four, and four times almost-nothing is
    four times the compression noise: the result was a flat navy blotch, mud
    rather than sky. So the target is a ceiling and never a floor — art that
    is too bright is brought down, art that is dark is left dark.

    What stops the hole instead is the screen against the card's own panel
    colour, which can only ever lighten. A night sky comes out a shade above
    the card and reads as what it is; nothing is amplified, and no art can
    land darker than the surface it sits on.
    """
    imagem = imagem.filter(ImageFilter.GaussianBlur(5))
    imagem = ImageEnhance.Color(imagem).enhance(0.85)

    atual = _luminancia(_mediana(imagem))
    if atual > LUMINANCIA_ALVO:
        imagem = ImageEnhance.Brightness(imagem).enhance(
            max(LUMINANCIA_ALVO / atual, 0.25),
        )

    chao = Image.new("RGB", imagem.size, SUPERFICIE)
    return ImageChops.screen(imagem, chao)


def _cobrir(imagem, largura, altura):
    """Scales and centre-crops to exactly `largura x altura`, like BoxFit.cover."""
    w, h = imagem.size
    escala = max(largura / w, altura / h)
    imagem = imagem.resize(
        (max(1, round(w * escala)), max(1, round(h * escala))), Image.LANCZOS
    )
    w, h = imagem.size
    esq, topo = (w - largura) // 2, (h - altura) // 2
    return imagem.crop((esq, topo, esq + largura, topo + altura))


def placa(origem, sujeito=None, cenario=None, brilho=1.0):
    fonte = Image.open(origem).convert("RGB")

    fundo = _cenario(_cobrir(fonte.crop(cenario) if cenario else fonte, LARGURA, ALTURA))

    emblema = _cobrir(fonte.crop(sujeito) if sujeito else fonte, EMBLEMA, ALTURA)
    if brilho != 1.0:
        emblema = ImageEnhance.Brightness(emblema).enhance(brilho)

    # A straight alpha ramp over the emblem's last pixels. `paste` wants a
    # single-channel mask, and building it a column at a time is clear enough
    # at this width to be worth more than any vectorised trick.
    mascara = Image.new("L", (EMBLEMA, ALTURA), 255)
    px = mascara.load()
    for x in range(EMBLEMA - RAMPA, EMBLEMA):
        valor = round(255 * (EMBLEMA - 1 - x) / RAMPA)
        for y in range(ALTURA):
            px[x, y] = valor

    fundo.paste(emblema, (0, 0), mascara)
    return fundo


def main():
    pedido = argparse.ArgumentParser(description=__doc__)
    pedido.add_argument("origem", type=pathlib.Path)
    pedido.add_argument("login")
    pedido.add_argument("--sujeito", type=int, nargs=4, metavar=("X0", "Y0", "X1", "Y1"))
    pedido.add_argument("--cenario", type=int, nargs=4, metavar=("X0", "Y0", "X1", "Y1"))
    pedido.add_argument(
        "--brilho",
        type=float,
        default=1.0,
        help="lift the subject only, for art too dark to read at the 97 px "
        "the card actually draws it (discreet is not the same as invisible)",
    )
    args = pedido.parse_args()

    destino = args.origem.with_name(f"{args.login.lower()}.webp")
    imagem = placa(
        args.origem,
        tuple(args.sujeito) if args.sujeito else None,
        tuple(args.cenario) if args.cenario else None,
        args.brilho,
    )
    imagem.save(destino, "WEBP", quality=90)
    print(f"{destino} · {destino.stat().st_size // 1024} KB · {LARGURA}x{ALTURA}")


if __name__ == "__main__":
    main()
