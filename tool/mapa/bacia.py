"""Watershed por marcadores: uma semente por território, inundação pelo claro.

A diferença para o que havia antes está em duas linhas de ideia:

1. O número de territórios não é descoberto — é dado. Cada semente é um
   território, então ícone de capital não vira região e vizinho não gruda.
2. A inundação é por custo, não por distância: sai da semente e avança sempre
   pelo pixel mais claro disponível. Uma linha escura é cara, então a água só a
   atravessa quando não há mais nada, e a divisa entre dois territórios cai em
   cima da linha desenhada — que é a que o olho vê.
"""
import heapq, json
from PIL import Image

im = Image.open('mapa.webp').convert('L')
w, h = im.size
d = bytearray(im.tobytes())

# O custo da inundação vem da imagem de contraste normalizado, não do bruto.
# É a ideia do Eduardo no lugar onde ela vale mais: no bruto, uma divisa fraca
# custa quase o mesmo que papel e a água passa por cima dela; no normalizado,
# toda divisa é preta, então atravessar qualquer uma é caro do mesmo jeito, e a
# fronteira para exatamente em cima da linha desenhada.
mascara = json.load(open('mascara.json'))['rot']
custo = bytearray(Image.open('normalizado.png').tobytes())

# Dois estágios, e a razão de ser dois:
#
# O texto dos nomes é preto de verdade — uma letra mede 2 de luminância, uma
# linha de fronteira mede ~150. Tratado como muro, ele parte territórios ao
# meio (a divisa nascia dentro de "The Frozen Path"). Tratado como papel, ele
# vira atalho e um território dispara pelo mapa por dentro das palavras.
#
# Então a água anda só pelo papel limpo, e tudo o que ela não alcançou — texto,
# linhas, ícones — é repartido depois pelo vizinho mais próximo, que é o que
# divide uma fronteira ao meio entre os dois lados.
PAPEL = 90
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

# A máscara (lida acima) diz onde existe território; a inundação decide de
# quem é cada pixel. Sem ela a água enche a margem escura do pergaminho e um
# território come a borda inteira do mapa.
sementes = json.load(open('sementes.json'))          # {'1': [x, y], ...}

# Correções apontadas a olho. São o que o algoritmo não tem como saber: que
# duas regiões são o mesmo território, ou que ali existe um território que ele
# não viu. Cada entrada é um fato sobre o mapa, e nenhuma delas mexe no resto.
import os
correcoes = json.load(open('correcoes.json')) if os.path.exists('correcoes.json') else {}
sementes.update({k: v for k, v in correcoes.get('sementes_extra', {}).items()})

# Paredes: trechos onde a divisa existe desenhada no mapa mas está fraca demais
# para a água respeitar. A inundação não entra nelas; o estágio 2 as reparte
# entre os dois lados depois, que é o que uma fronteira deve ser.
bloqueio = bytearray(w * h)
for par in correcoes.get('paredes', []):
    (x0, y0), (x1, y1) = par['de'], par['ate']
    passos = max(abs(x1-x0), abs(y1-y0)) or 1
    for k in range(passos + 1):
        cx = round(x0 + (x1-x0) * k / passos)
        cy = round(y0 + (y1-y0) * k / passos)
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                if 0 <= cx+dx < w and 0 <= cy+dy < h:
                    bloqueio[(cy+dy) * w + cx+dx] = 1
if correcoes.get('paredes'):
    print('paredes aplicadas:', len(correcoes['paredes']))
rot = [0] * (w * h)
fila = []
for nome, (x, y) in sementes.items():
    i = y * w + x
    rot[i] = int(nome)
    heapq.heappush(fila, (0, i))   # semente entra na frente: o custo dela é irrelevante

while fila:
    _, i = heapq.heappop(fila)
    r = rot[i]
    x, y = i % w, i // w
    for nx, ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
        if dentro(nx, ny):
            j = ny * w + nx
            if not rot[j] and mascara[j] and custo[j] >= PAPEL and not bloqueio[j]:
                rot[j] = r
                heapq.heappush(fila, (255 - custo[j], j))

# Sobra do que a inundação não alcançou: pedaço da máscara que ficou ilhado
# atrás de uma linha grossa. Sem isto ele fica sem dono e aparece como buraco
# preto no mapa final.
from collections import deque
fila2 = deque(i for i, r in enumerate(rot) if r)
sobras = 0
while fila2:
    i = fila2.popleft()
    x, y = i % w, i // w
    for nx, ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
        if dentro(nx, ny):
            j = ny * w + nx
            # Dentro do painel, tudo é de alguém: os limites já foram medidos,
            # então não há como isto vazar para fora do mapa.
            if not rot[j]:
                rot[j] = rot[i]
                fila2.append(j)
                sobras += 1
print('sobras entregues ao vizinho:', sobras)

# fusões: duas regiões que são um território só
for a, b in correcoes.get('fundir', []):
    for i, r in enumerate(rot):
        if r == a:
            rot[i] = b
if correcoes.get('fundir'):
    print('fusões aplicadas:', correcoes['fundir'])

areas = {}
for r in rot:
    if r: areas[r] = areas.get(r, 0) + 1
a = sorted(areas.values())
print(f'{len(areas)} territórios · menor {a[0]} · maior {a[-1]}')
json.dump({'w': w, 'h': h, 'rot': rot, 'n': len(areas)}, open('rotulos.json', 'w'))
