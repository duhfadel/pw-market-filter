"""Normaliza o contraste localmente: a ideia do Eduardo, aplicada por janela.

Aumentar o contraste da imagem inteira não resolve, porque o problema não é a
imagem ser lavada — é a borda ser forte no meio claro e fraca no canto escuro.
Normalizando cada pixel pelo mínimo e pelo máximo da vizinhança, toda borda
vira preta e todo papel vira branco, independentemente de onde esteja.

Mínimo e máximo por janela em tempo linear, com deque monotônica: fazer isso
por força bruta seria janela × pixels, o que em Python puro não termina.
"""
from PIL import Image
from collections import deque

R = 9   # metade da janela: maior que a linha mais grossa, menor que o menor território

def filtro_1d(vals, n, r, maior):
    """Mínimo (ou máximo) deslizante sobre uma sequência."""
    saida = [0] * n
    dq = deque()
    for i in range(n + r):
        if i < n:
            while dq and ((vals[dq[-1]] <= vals[i]) if maior else (vals[dq[-1]] >= vals[i])):
                dq.pop()
            dq.append(i)
        j = i - r
        if j >= 0:
            while dq[0] < j - r:
                dq.popleft()
            saida[j] = vals[dq[0]]
    return saida

def extremos(d, w, h, maior):
    """Aplica o filtro nas linhas e depois nas colunas."""
    tmp = [0] * (w * h)
    for y in range(h):
        linha = filtro_1d(d[y*w:(y+1)*w], w, R, maior)
        tmp[y*w:(y+1)*w] = linha
    saida = [0] * (w * h)
    for x in range(w):
        col = filtro_1d([tmp[y*w+x] for y in range(h)], h, R, maior)
        for y in range(h):
            saida[y*w+x] = col[y]
    return saida

if __name__ == '__main__':
    im = Image.open('mapa.webp').convert('L')
    w, h = im.size
    d = list(im.tobytes())
    lo = extremos(d, w, h, False)
    hi = extremos(d, w, h, True)
    out = bytearray(w * h)
    for i in range(w * h):
        faixa = hi[i] - lo[i]
        # Onde não há variação (miolo liso de um território) o pixel é papel.
        out[i] = 255 if faixa < 12 else min(255, max(0, (d[i] - lo[i]) * 255 // faixa))
    Image.frombytes('L', (w, h), bytes(out)).save('normalizado.png')
    escuros = sum(1 for v in out if v < 90)
    print(f'normalizado · {escuros*100//(w*h)}% dos pixels ficaram escuros (as bordas)')
