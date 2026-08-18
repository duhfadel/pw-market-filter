# O mapa de guerras territoriais

Cinquenta e dois territórios traçados a partir de uma imagem do mapa, virando
um SVG onde cada um é uma forma com nome, cor e clique próprios.

## Como rodar

```
python3 sementes.py    # acha o miolo de cada território (chama cresce.py)
python3 bacia.py       # decide de quem é cada pixel, aplicando correcoes.json
python3 svg.py         # converte as regiões em caminhos vetoriais
python3 nomes.py       # casa cada região com o número e o nome do jogo
python3 pagina.py      # monta web/guerras/index.html com o SVG e o modelo
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

## Onde ficam os donos

Em lugar nenhum daqui. `pagina.py` embute no HTML só a metade que **não muda** —
nome, gold e capital são propriedades do mapa do jogo, não da guerra — e a
página busca os donos no Supabase (`portal-pw`, tabelas `territorios` e
`guildas`) ao carregar.

É por isso que atualizar uma conquista não passa por este diretório, nem por um
commit, nem por CI: é editar uma linha no painel. E é por isso que a página
desenha inteira, com os 52 nomes, mesmo com o banco fora do ar.

`pagina-exemplo.html` continua aqui como a fonte do SVG — `pagina.py` copia o
bloco `<svg>` dele. Os donos inventados que ela mostra (NUEMA, ESPADAS, CORVOS,
AURORA) são só demonstração e não vão para o site.

## A distinção que a página faz questão de manter

Três estados, três frases diferentes, porque confundi-los é publicar mentira:

| Situação | O que a página diz |
|---|---|
| Tem donos | "última mudança em DD/MM/AAAA" |
| Tabela sem nenhum dono | "As conquistas ainda não foram preenchidas" |
| Banco não respondeu | "Não foi possível carregar quem domina cada um agora" |

Um mapa todo cinza porque ninguém conquistou nada e um mapa todo cinza porque a
rede caiu são a mesma imagem. A linha embaixo do título é o que os separa.
