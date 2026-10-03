"""Draws the 640x320 panel a streamer puts under their Twitch channel.

**A panel is read in one glance, from a list of other panels, by somebody who
is watching something else.** So it says three things and stops: what it is,
who it is for, and where to go. The version numbers are deliberately absent —
they date the image, and an image on somebody else's channel is the hardest
thing in this project to go back and correct.

Built from the site's own palette and faces rather than from a screenshot, so
the panel and the page a click later look like the same place.

Run: python3 tool/artes/painel_twitch.py
"""

import pathlib

from PIL import Image, ImageDraw, ImageFont

LARGURA, ALTURA = 640, 320

# `PWColors`, read off `lib/core/theme/pw_colors.dart`. Typed here rather than
# imported because this is a Python tool and Dart is the source of truth — a
# drift costs a dull panel, not a wrong site.
NOITE = (0x12, 0x10, 0x2A)
SURFACE = (0x1C, 0x1C, 0x38)
PAPEL = (0xF0, 0xE6, 0xF2)
OURO = (0xFF, 0xB4, 0x54)
VIOLETA = (0x78, 0x5A, 0xDC)
MUDO = (0x9A, 0x93, 0xB8)

FONTES = pathlib.Path("assets/fonts")
DESTINO = pathlib.Path("design/painel-twitch.png")
DESTINO_LOGO = pathlib.Path("design/painel-twitch-logo.png")
LOGO = pathlib.Path("design/originais/portal-perfect-world-logo.png")


def _fonte(nome, tamanho):
    return ImageFont.truetype(str(FONTES / nome), tamanho)


def _centrar(desenho, y, texto, fonte, cor, espaco=0):
    """Draws `texto` centred on the panel, with optional letter-spacing."""
    if espaco == 0:
        largura = desenho.textlength(texto, font=fonte)
        desenho.text(((LARGURA - largura) / 2, y), texto, font=fonte, fill=cor)
        return

    larguras = [desenho.textlength(c, font=fonte) for c in texto]
    total = sum(larguras) + espaco * (len(texto) - 1)
    x = (LARGURA - total) / 2
    for caractere, largura in zip(texto, larguras):
        desenho.text((x, y), caractere, font=fonte, fill=cor)
        x += largura + espaco


def _fundo():
    """Night, with a violet bloom behind the headline.

    A flat ground reads as a placeholder next to the artwork every other panel
    on a Twitch channel carries, and a picture would compete with the words.
    A gradient is the middle: it gives the panel a light source without
    putting anything in it to look at.
    """
    base = Image.new("RGB", (LARGURA, ALTURA), NOITE)
    px = base.load()
    cx, cy, raio = LARGURA / 2, ALTURA * 0.40, LARGURA * 0.62
    for y in range(ALTURA):
        for x in range(LARGURA):
            d = (((x - cx) / raio) ** 2 + ((y - cy) / (raio * 0.72)) ** 2) ** 0.5
            peso = max(0.0, 1.0 - d) ** 2 * 0.42
            px[x, y] = tuple(
                round(NOITE[c] + (VIOLETA[c] - NOITE[c]) * peso) for c in range(3)
            )
    return base


def _esquerda(desenho, x, y, texto, fonte, cor, espaco=0):
    if espaco == 0:
        desenho.text((x, y), texto, font=fonte, fill=cor)
        return
    for caractere in texto:
        desenho.text((x, y), caractere, font=fonte, fill=cor)
        x += desenho.textlength(caractere, font=fonte) + espaco


def desenhar_com_logo():
    """The same panel with the existing wordmark instead of a typeset one.

    **It needs a plate behind it to be readable at all.** The mark is dark red
    script over a gold sphere on transparency, authored for a light page; laid
    straight onto the night ground its letters sink into it, which is the main
    thing wrong with the panel this replaces. A pale rounded plate gives it
    the background it was drawn for.
    """
    painel = _fundo()
    d = ImageDraw.Draw(painel)
    d.rectangle([(0, 0), (LARGURA - 1, ALTURA - 1)], outline=SURFACE, width=2)

    marca = Image.open(LOGO).convert("RGBA")
    # 196 and not 300: the mark is nearly 3:2, so at 300 its plate alone eats
    # 223 of the panel's 320 and the three lines below fall off the bottom.
    alvo = 196
    marca = marca.resize((alvo, round(alvo * marca.height / marca.width)))

    chapa = Image.new("RGBA", (marca.width + 28, marca.height + 16), (0, 0, 0, 0))
    ImageDraw.Draw(chapa).rounded_rectangle(
        [(0, 0), (chapa.width - 1, chapa.height - 1)],
        radius=14,
        fill=(0xF2, 0xEE, 0xF6, 0xF0),
    )
    chapa.alpha_composite(marca, (14, 8))
    painel.paste(chapa, ((LARGURA - chapa.width) // 2, 20), chapa)

    topo = 20 + chapa.height + 16
    _centrar(d, topo, "Filtros de market", _fonte("Marcellus-Regular.ttf", 38), PAPEL)
    _centrar(
        d,
        topo + 52,
        "para todas as versões do TheClassic PW",
        _fonte("Inter-Regular.ttf", 16),
        MUDO,
    )
    _centrar(d, topo + 82, "portalpw.net", _fonte("Inter-Bold.ttf", 26), OURO)

    DESTINO_LOGO.parent.mkdir(parents=True, exist_ok=True)
    painel.save(DESTINO_LOGO)
    print(f"{DESTINO_LOGO} · {DESTINO_LOGO.stat().st_size // 1024} KB")


def desenhar():
    painel = _fundo()
    d = ImageDraw.Draw(painel)

    # A hairline inside the edge, the same device every card on the site uses
    # to say "this is a surface" rather than "this is the background".
    d.rectangle([(0, 0), (LARGURA - 1, ALTURA - 1)], outline=SURFACE, width=2)

    _centrar(d, 44, "PORTAL PW", _fonte("Inter-SemiBold.ttf", 15), MUDO, espaco=5)

    # Marcellus is safe here and nowhere near a number: it draws Roman figures,
    # so its `1` has no flag and its `0` is barely an `O`. The headline has no
    # digits in it, which is also why the versions live in words below.
    _centrar(d, 92, "Filtros de market", _fonte("Marcellus-Regular.ttf", 54), PAPEL)

    d.line(
        [(LARGURA / 2 - 46, 168), (LARGURA / 2 + 46, 168)], fill=VIOLETA, width=2
    )

    _centrar(
        d, 190, "para todas as versões do", _fonte("Inter-Regular.ttf", 19), MUDO
    )
    _centrar(
        d, 218, "TheClassic PW", _fonte("Inter-SemiBold.ttf", 19), PAPEL
    )

    _centrar(d, 262, "portalpw.net", _fonte("Inter-Bold.ttf", 30), OURO)

    DESTINO.parent.mkdir(parents=True, exist_ok=True)
    painel.save(DESTINO)
    print(f"{DESTINO} · {DESTINO.stat().st_size // 1024} KB · {LARGURA}x{ALTURA}")


if __name__ == "__main__":
    desenhar()
    desenhar_com_logo()
