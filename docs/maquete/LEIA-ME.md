# A maquete é a referência, e vive aqui por isso

`home.html` é a maquete da home que o dono aprovou depois de quatro rondas,
em 08/11/2026. **Estava numa pasta temporária da sessão** até 09/11, o que
quer dizer que a referência do redesenho podia desaparecer sem ninguém dar
por isso. Está versionada agora.

Abra-a com qualquer servidor estático a partir da raiz do repositório:

```
python3 -m http.server 8192
# depois: http://localhost:8192/docs/maquete/home.html
```

Os caminhos da arte apontam para `assets/images/classes-verticais/960/`, que
é a mesma pasta que a app usa — **uma arte, não uma cópia**. Uma segunda cópia
divergia na primeira vez que alguém trocasse um ficheiro.

## A publicada não serve para comparar

Há uma versão publicada em
`https://claude.ai/code/artifact/03e140bc-8b59-4407-925f-4db250726390`, e ela
**não tem arte de classe nenhuma** — zero referências a `classes-verticais`.
O herói dela é um céu desenhado em canvas. É lisa por construção, portanto
comparar a app com ela faz a arte verdadeira parecer de má qualidade quando
não é: medida a energia de borda na mesma região, a app dá **4,79** contra
**4,78** da maquete local. São a mesma imagem, com o mesmo recorte.

Isto custou uma ronda inteira a 09/11, por eu ter dado o link da publicada.

## Como comparar, e porque não se compara a olho

**Leia o CSS, não deduza.** Três voltas no herói, duas delas erradas, saíram
de eu olhar para uma captura e inferir o enquadramento. O CSS dizia tudo:

| | a maquete |
|---|---|
| altura do herói | `min-height: min(86vh, 760px)` |
| arte | `object-fit: cover; object-position: 76% 20%` |
| véu | `linear-gradient(100deg, #0B0B1A 4%, rgba(11,11,26,.86) 36%, rgba(11,11,26,.1) 66%, rgba(11,11,26,.5) 100%)` |
| véu de baixo | `linear-gradient(to top, #0B0B1A, transparent 34%)` |
| manchete | `clamp(38px, 5.6vw, 68px)`, `max-width: 14ch` |
| sub-linha | `16.5px`, `max-width: 46ch` |
| pílula | `rgba(11,11,26,.42)` + `backdrop-filter: blur(8px)`, borda `rgba(255,255,255,.18)` |
| pílula de Novidades | `.pil.ouro` — borda `rgba(255,180,84,.55)`, letra a ouro |
| coluna de leitura | `--col: 1180px` |
| secção | `padding: 58px 0` |
| cabeçalho de secção | Marcellus `13px`, `letter-spacing:.2em`, maiúsculas, apagado |
| faixa das versões | `border-top`/`bottom` filete, fundo `#13132A`, colunas com `border-left` |
| coluna da versão | `padding:34px 18px 36px`, nome Marcellus `30px`, número `21px/600` |
| fechada | `opacity:.62` |
| carta de guia | `border-radius:12px; padding:20px; gap:7px`, título Marcellus `19px` |
| painel do canal | `grid 1fr 1.15fr; gap:30px; padding:32px`, gradiente `135deg rgba(120,90,220,.16) → #13132A 62%` |

**E quando a olho não bate, meça os píxeis.** A comparação que fechou o herói
foi `ImageChops.difference` entre as duas capturas, depois de pedir ao DOM a
caixa exacta do herói com `getBoundingClientRect` — **sem isso os recortes
desalinham e a medição mente**: deu 32/255 desalinhada e 10,9 alinhada, com
mediana de 3,3.

## O que fica diferente de propósito

| | porquê |
|---|---|
| a descrição de cada servidor aparece nas colunas abertas | pedido do dono a 28/10/2026: *a tela pergunta qual mercado e só respondia com números* |
| a ordem é 1.2.6, 1.4.4, 1.8.7 | ordem cronológica, decisão do dono a 12/10/2026 |
| os guias são oito e não seis | são os reais |
| sem o cartão tracejado *o próximo está a caminho* | promete uma cadência que ninguém garantiu |
