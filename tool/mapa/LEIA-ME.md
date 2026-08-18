# O mapa de guerras territoriais

Cinquenta e dois territórios traçados a partir de uma imagem do mapa, virando
um SVG onde cada um é uma forma com nome, cor e clique próprios.

## Como rodar

```
python3 sementes.py    # acha o miolo de cada território (chama cresce.py)
python3 bacia.py       # decide de quem é cada pixel, aplicando correcoes.json
python3 svg.py         # converte as regiões em caminhos vetoriais
python3 nomes.py       # casa cada região com o número e o nome do jogo
python3 pagina.py      # monta as duas paginas de web/guerras/
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
página busca no Supabase (`portal-pw`) tudo que muda: o dono, o brasão dele, se
o território está em guerra, o comentário da guilda, o resumo da última guerra
e quem está transmitindo.

É por isso que atualizar uma conquista não passa por este diretório, nem por um
commit, nem por CI: é editar uma linha no painel. E é por isso que a página
desenha inteira, com os 52 nomes, mesmo com o banco fora do ar.

`pagina-exemplo.html` continua aqui como a fonte do SVG — `pagina.py` copia o
bloco `<svg>` dele. Os donos inventados que ela mostra (NUEMA, ESPADAS, CORVOS,
AURORA) são só demonstração e não vão para o site.

## Os dois ícones, e por que só um pode ser arquivo

O **brasão** é arte de cada guilda e mora em `web/guerras/icones/`; a coluna
`guildas.brasao` diz qual arquivo usar. Falta de arquivo deixa o território com
a cor da guilda e sem símbolo — nunca um quadrado quebrado.

O **marcador de guerra** é desenhado dentro do próprio SVG, e isso é de
propósito: é a informação mais urgente da página, e não pode depender de um
download que pode faltar. Ele é duas coisas ao mesmo tempo — o contorno
tracejado da forma, que existe em todo território e se vê sem passar o mouse, e
o selo de espadas, que confirma de perto.

O contorno é desenhado **duas vezes**, uma escura por baixo da tracejada. Com
uma só, o vermelho da guerra sobre o vermelho de uma guilda vermelha
praticamente sumia, e um alerta que depende da cor do dono não é alerta.

Duas armadilhas que custaram uma rodada cada:

- **`<use>` com `<symbol>` monta uma shadow tree**, e `.selo-guerra circle` não
  atravessa ela: o selo saiu preto em vez de vermelho, com o CSS certo no
  arquivo. A marca é um `<g>` clonado com `cloneNode`, que deixa os nós no
  documento onde o seletor os alcança.
- **Remontar o `<text>` do número a partir do inteiro come o zero.** O
  território 8 está escrito `08` no SVG; `desce_numeros` recoloca o rótulo como
  estava em vez de formatá-lo de novo.

## Onde cabe um brasão, e por que isso não é `ymin`

`ancoras.py` responde isso, e o cabeçalho dele conta as três medições que
viraram regra. O resumo: o topo do retângulo que envolve um território quase
nunca está dentro dele; parar na primeira altura que serve põe o brasão numa
ponta que parece do vizinho; e com 23 px de brasão, **34 dos 52** territórios
ficavam com o ícone por cima do próprio número.

A saída foi o número ceder. Em oito territórios ele desce de 1 a 9 px — o
suficiente para os 52 caberem — e essa posição não era sagrada: veio de "ponto
mais fundo da forma", não do jogo. É por isso que o SVG do site não é byte a
byte o de `pagina-exemplo.html`.

## Território sem nada não é clicável

É a regra que mais decide como a página se comporta, e ela vale a pena escrita:
**só vira link o território que tem comentário, resumo ou — durante a guerra —
streamer.** Uma ficha que repete o que o mapa acabou de mostrar é um clique
gasto à toa, e ensina a não clicar da próxima vez.

Quem responde é a coluna `tem_ficha` da view `mapa`, e não a página: calcular
no navegador significaria baixar o comentário e o resumo dos 52 territórios só
para descobrir quais estão vazios — pagar o texto inteiro para não mostrar
texto nenhum.

O cursor é a única promessa de clique que o mapa faz, e ela só é feita a quem
tem o que mostrar; o realce do hover fica em todos, porque serve ao painel ao
lado. Na lista, que não depende do mouse, quem é clicável ganha um `ler ›`.

**A armadilha:** `tem_ficha` tem que concordar exatamente com o que a ficha vai
desenhar. A primeira versão contava os streamers houvesse guerra ou não, mas a
página só os lista durante uma — então território com streamer e sem guerra era
clicável e abria uma página vazia, que é justamente o defeito que a regra
existe para impedir. Quando uma seção ganha uma condição, a coluna ganha a
mesma.

## O que a ficha mostra, e nessa ordem

1. **Quem está transmitindo**, se houver guerra. Vem primeiro porque é a única
   coisa da página que perde o valor daqui a uma hora.
2. **O que a guilda diz** — citação com o brasão, o nome de quem falou e a
   data. É voz de parte interessada, e a citação é o que diz isso.
3. **A última guerra** — o relato, em texto corrido.

Comentário e resumo são duas colunas e não uma justamente por causa de 2 e 3:
juntos num campo só, ninguém sabe qual frase é do dono.

O texto dos dois é escapado e só então ganha parágrafo, `**negrito**` e
`[texto](link)`. Aceitar HTML cru num campo do painel é dar script na página a
quem escreve nele. Quebra de linha simples vira espaço e só linha em branco
começa parágrafo — a regra do markdown: com `<br>`, texto colado do Discord,
que vem quebrado na largura da janela de lá, saía em escadinha.

`streamers.url` vira `href`, e é conferido **duas vezes de propósito**: a
tabela recusa o que não for `http(s)`, e a página confere o esquema de novo
antes de desenhar. Com uma só, a proteção fica num sistema e o risco no outro.
Escapar não resolve — `javascript:alert(1)` não tem nenhum dos caracteres que
um escapador troca, e passaria inteiro para dentro do `href`.

## Num PC o mapa cabe na tela

O desenho é 482x635 — mais alto que largo — então quem manda no tamanho dele é
a **altura** da janela, não a largura. Sem isso, numa tela de 1400 px ele saía
com 945 px de altura e a metade sul só aparecia rolando, o que num mapa é o
mesmo que não mostrar.

A conta está no CSS: desconta da altura da janela o cabeçalho, o título e as
folgas (`--fora`), e converte o que sobra em largura pela proporção do desenho.
A coluna do mapa encolhe junto e a grade se centraliza, senão sobraria um
buraco ao lado das guildas.

`--fora` tem dois valores, e o segundo mora num `body:has(.previa)`: o aviso de
prévia ocupa 76 px e é temporário. Assim, no dia em que ele sair do HTML o mapa
cresce sozinho para ocupar o espaço — em vez de continuar encolhido por causa
de um aviso que já não existe.

Medido em 1366x768, 1440x900 e 1920x1080: cabe nas três, sem rolagem lateral. A
regra é `min-width:881px`, então o telefone segue como estava.

## A distinção que a página faz questão de manter

Três estados, três frases diferentes, porque confundi-los é publicar mentira:

| Situação | O que a página diz |
|---|---|
| Tem donos | "última mudança em DD/MM/AAAA" |
| Tabela sem nenhum dono | "As conquistas ainda não foram preenchidas" |
| Banco não respondeu | "Não foi possível carregar quem domina cada um agora" |

Um mapa todo cinza porque ninguém conquistou nada e um mapa todo cinza porque a
rede caiu são a mesma imagem. A linha embaixo do título é o que os separa.
