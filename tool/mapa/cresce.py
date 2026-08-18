from PIL import Image, ImageDraw
from collections import deque
import colorsys, json

im = Image.open('mapa.webp').convert('L')
w, h = im.size
d = bytearray(im.tobytes())
cor = Image.open('mapa.webp').convert('RGB').load()

# ── 1. média local, para o limiar adaptativo ────────────────────────────────
S = [0] * ((w + 1) * (h + 1))
for y in range(h):
    linha = 0
    for x in range(w):
        linha += d[y * w + x]
        S[(y + 1) * (w + 1) + x + 1] = S[y * (w + 1) + x + 1] + linha

def media(x, y, r=34):
    x0, y0 = max(0, x - r), max(0, y - r)
    x1, y1 = min(w - 1, x + r), min(h - 1, y + r)
    total = (S[(y1+1)*(w+1)+x1+1] - S[y0*(w+1)+x1+1]
             - S[(y1+1)*(w+1)+x0] + S[y0*(w+1)+x0])
    return total / ((x1-x0+1) * (y1-y0+1))

# ── 2. sementes: o miolo claro de cada território ───────────────────────────
# Bordas medidas no perfil de luminância da imagem, não chutadas: o painel
# claro do mapa termina em 302 à esquerda, 71 no topo e 706 embaixo. À direita
# são duas: o bloco principal e as ilhas de baixo acabam em 719, e só a faixa
# do Dawnglory — a ilha do canto superior direito — vai até 783.
#
# Isso importa mais do que parece. Antes o limite era uma caixa larga demais e
# os territórios escorriam até ela, o que produzia o contorno serrilhado: o
# mapa é quase quadrado, e a borda externa tem de ser reta.
MAPA = (302, 71, 784, 706)

def dentro(x, y):
    """O painel do mapa, com as bordas medidas e não chutadas.

    Ele não é um retângulo só: o bloco principal e as ilhas de baixo terminam
    em x=719, e apenas a faixa do Dawnglory vai até 783. Embaixo é o inverso —
    o bloco principal acaba em 640 e só a coluna das ilhas desce até 706.
    """
    if not (302 <= x < 784 and 71 <= y < 706):
        return False
    if x >= 720:                 # faixa do Dawnglory, à direita de tudo
        # 199 e nao 215: o Eduardo marcou o fim da ilha em (750,197), e a borda
        # aparece na imagem entre y=192 e y=200. O limite antigo dava a ela
        # dezessete pixels de pergaminho escuro que nao sao territorio.
        return y < 199
    if x < 565:                  # metade esquerda: acaba na base do bloco
        return y < 641
    return True

# O papel de cada território: mais claro que a própria vizinhança. O ícone da
# capital é claro como papel e vira semente, então ele funcionava como muro,
# partindo o território em dois — o que o separa é o laranja: nele R-B passa
# de 100, no papel fica em 54.
papel = bytearray(w * h)
for y in range(MAPA[1], MAPA[3]):
    for x in range(MAPA[0], MAPA[2]):
        if not dentro(x, y):
            continue
        i = y * w + x
        r_, g_, b_ = cor[x, y]
        if d[i] > media(x, y) + 20 and d[i] > 90 and r_ - b_ < 85:
            papel[i] = 1

rot = [0] * (w * h)
regioes = []
for inicio in range(w * h):
    if rot[inicio] or not papel[inicio]:
        continue
    pilha = [inicio]; rot[inicio] = -1; px = []
    while pilha:
        i = pilha.pop(); px.append(i)
        x, y = i % w, i // w
        for nx, ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
            if dentro(nx, ny):
                j = ny * w + nx
                if not rot[j] and papel[j]:
                    rot[j] = -1; pilha.append(j)
    if len(px) < 400:
        for i in px: rot[i] = 0
        continue
    xs = [i % w for i in px]; ys = [i // w for i in px]
    if max(max(xs)-min(xs), max(ys)-min(ys)) > 6 * max(1, min(max(xs)-min(xs), max(ys)-min(ys))):
        for i in px: rot[i] = 0
        continue
    # O halo em volta das letras de "Territories of Perfect World" é claro o
    # bastante para virar semente. Ele mora sempre no mesmo canto, e Dawnglory
    # — o único território daquele lado — fica acima de y=230, então um
    # retângulo resolve sem regra inventada.
    if min(xs) > 725 and min(ys) > 240:
        for i in px: rot[i] = 0
        continue
    if sum(d[i] for i in px) / len(px) < 95:
        for i in px: rot[i] = 0
        continue
    regioes.append(px)

regioes.sort(key=lambda p: (min(i // w for i in p) // 45, min(i % w for i in p)))
for n, px in enumerate(regioes, 1):
    for i in px: rot[i] = n
print('sementes:', len(regioes))

# ── 3. crescer até encostar ─────────────────────────────────────────────────
# Cada pixel do mapa que ainda não tem dono vai para o território mais próximo.
# É o que faz a linha da fronteira ser dividida entre os dois vizinhos, em vez
# de virar buraco. O fundo fora do mapa mede 36; nada acima de 55 é fundo.
# O limite de distância é o que impede o vazamento: uma linha de fronteira tem
# 4 a 8 px, então 12 cobre qualquer divisa e para muito antes do brilho do
# pergaminho, que fica dezenas de pixels além do último território.
LIMITE = 12
fila = deque((i, 0) for n, px in enumerate(regioes, 1) for i in px)
passos = 0
while fila:
    i, dist = fila.popleft()
    if dist >= LIMITE:
        continue
    x, y = i % w, i // w
    for nx, ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
        if dentro(nx, ny):
            j = ny * w + nx
            if not rot[j] and d[j] > 55:
                rot[j] = rot[i]
                fila.append((j, dist + 1))
                passos += 1
print('pixels de fronteira distribuídos:', passos)

# Segunda passada, sem exigir claridade: o que sobrou dentro do mapa é o texto
# dos rótulos e os ícones das capitais, escuros demais para a primeira. Deixá-
# los sem dono faria cada letra virar um furo no contorno do território.
fila = deque((i, 0) for i, r in enumerate(rot) if r)
buracos = 0
while fila:
    i, dist = fila.popleft()
    if dist >= 14:
        continue
    x, y = i % w, i // w
    for nx, ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
        if dentro(nx, ny):
            j = ny * w + nx
            if not rot[j]:
                rot[j] = rot[i]
                fila.append((j, dist + 1))
                buracos += 1
print('buracos internos preenchidos:', buracos)

# ── 4. dissolver o que é pequeno demais para ser território ────────────────
# Sobram três tipos de caco, e todos são pequenos: o ícone da capital (que é
# claro como papel e vira semente), o halo em volta do texto de um rótulo, e a
# lasca de papel que uma linha grossa isola num canto. Caçar cada um por cor
# falhou — o ícone tem partes laranja e partes claras. O que eles têm em comum
# é o tamanho: o menor território de verdade tem umas cinco vezes a área do
# maior caco. Cada um se dissolve na vizinha com quem divide mais fronteira,
# que é para onde ele iria se nunca tivesse virado região.
MINIMO = 2200

def vizinhanca():
    conta = {}
    for y in range(1, h-1):
        for x in range(1, w-1):
            r = rot[y*w+x]
            if not r: continue
            for j in (y*w+x+1, y*w+x-1, (y+1)*w+x, (y-1)*w+x):
                o = rot[j]
                if o and o != r:
                    conta.setdefault(r, {})
                    conta[r][o] = conta[r].get(o, 0) + 1
    return conta

dissolvidos = 0
while True:
    areas = {}
    for r in rot:
        if r: areas[r] = areas.get(r, 0) + 1
    pequenas = [r for r, a in areas.items() if a < MINIMO]
    if not pequenas:
        break
    viz = vizinhanca()
    alvo = min(pequenas, key=lambda r: areas[r])
    parceiros = viz.get(alvo)
    if not parceiros:
        break
    destino = max(parceiros, key=parceiros.get)
    for i, r in enumerate(rot):
        if r == alvo:
            rot[i] = destino
    dissolvidos += 1

print(f'cacos dissolvidos: {dissolvidos} → {len({r for r in rot if r})} territórios')

json.dump({'w': w, 'h': h, 'rot': rot, 'n': len({r for r in rot if r})}, open('rotulos.json', 'w'))

# ── 4. ver o resultado ──────────────────────────────────────────────────────
saida = Image.new('RGB', (w, h), (11, 11, 26))
for i, r in enumerate(rot):
    if r:
        c = colorsys.hsv_to_rgb((r * 0.37) % 1.0, 0.55, 0.95)
        saida.putpixel((i % w, i // w), (int(c[0]*255), int(c[1]*255), int(c[2]*255)))
dr = ImageDraw.Draw(saida)
for n, px in enumerate(regioes, 1):
    xs = [i % w for i in px]; ys = [i // w for i in px]
    dr.text((sum(xs)//len(xs)-5, sum(ys)//len(ys)-5), str(n), fill=(0,0,0))
saida.save('crescido.png')
