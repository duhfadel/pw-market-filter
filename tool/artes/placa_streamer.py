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

from PIL import Image, ImageEnhance, ImageFilter

LARGURA, ALTURA = 690, 231
EMBLEMA = 170

# How far the emblem's right edge takes to dissolve into the scenery. Short
# enough that the subject keeps its outline, long enough that no vertical
# line survives.
RAMPA = 46


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


def placa(origem, sujeito=None, cenario=None):
    fonte = Image.open(origem).convert("RGB")

    fundo = _cobrir(fonte.crop(cenario) if cenario else fonte, LARGURA, ALTURA)
    fundo = fundo.filter(ImageFilter.GaussianBlur(5))
    fundo = ImageEnhance.Brightness(fundo).enhance(0.6)
    fundo = ImageEnhance.Color(fundo).enhance(0.85)

    emblema = _cobrir(fonte.crop(sujeito) if sujeito else fonte, EMBLEMA, ALTURA)

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
    args = pedido.parse_args()

    destino = args.origem.with_name(f"{args.login.lower()}.webp")
    imagem = placa(
        args.origem,
        tuple(args.sujeito) if args.sujeito else None,
        tuple(args.cenario) if args.cenario else None,
    )
    imagem.save(destino, "WEBP", quality=90)
    print(f"{destino} · {destino.stat().st_size // 1024} KB · {LARGURA}x{ALTURA}")


if __name__ == "__main__":
    main()
