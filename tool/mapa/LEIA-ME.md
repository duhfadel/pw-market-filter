# O mapa de guerras territoriais

Cinquenta e dois territórios traçados a partir de uma imagem do mapa, virando
um SVG onde cada um é uma forma com nome, cor e clique próprios.

## Como rodar

```
python3 sementes.py    # acha o miolo de cada território (chama cresce.py)
python3 bacia.py       # decide de quem é cada pixel, aplicando correcoes.json
python3 svg.py         # converte as regiões em caminhos vetoriais
python3 nomes.py       # casa cada região com o número e o nome do jogo
```

Só precisa de `Pillow`. Cada passo grava um JSON que o seguinte lê.

## Por que existe `correcoes.json`

Nenhum algoritmo lê este mapa perfeitamente, e não é falta de técnica: é um
pergaminho pintado, com pincelada macia, textura por cima, vinheta escurecendo
um lado e ícones de cidade desenhados em cima das divisas. Em vários pontos
duas leituras são igualmente defensáveis para uma regra, e óbvias para quem
conhece o mapa.

`correcoes.json` é onde essa diferença mora. Cada entrada é um **fato sobre o
mapa**, não um ajuste de parâmetro:

- `paredes` — trechos onde a divisa existe desenhada mas está fraca demais para
  a inundação respeitar;
- `sementes_extra` — territórios que o script não viu, ou que precisam nascer
  em outro ponto;
- `fundir` — duas regiões que são o mesmo território.

Cada uma carrega `_nota` dizendo de onde veio a informação: medição na imagem
ou clique do jogador em `corrigir.html`. É isso que torna o mapa reproduzível —
mexer no algoritmo não invalida as correções.

## As três lições que custaram caro

1. **A fronteira pertence aos dois vizinhos.** Deixar a linha sem dono produz
   buracos; cada pixel dela vai para o território mais próximo, e a linha é
   desenhada por cima, no `stroke` do SVG.
2. **O limite externo é reto, e medi-lo folgado estraga o contorno.** As bordas
   saíram do perfil de luminância da imagem: 302 à esquerda, 71 no topo, 719 à
   direita do bloco, 641 na base, e a faixa do Dawnglory até 783 e y<199.
3. **O ícone da capital é claro como papel** e vira semente, partindo o
   território em dois. O que o separa é o laranja: nele R−B passa de 100, no
   papel fica em 54.

## O que ainda não está aqui

`pagina-exemplo.html` é a página pronta, mas com **donos inventados** — as
guildas NUEMA, ESPADAS, CORVOS e AURORA são demonstração. Ela vive em `tool/`
de propósito: mover para `web/guerras/` é o que a publica, e isso só deve
acontecer com dados de verdade.
