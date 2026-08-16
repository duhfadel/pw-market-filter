# Portal PW

Ferramentas para o mercado do **The Classic PW 1.8.7**, em
[portalpw.net](https://portalpw.net/).

Hoje tem uma: o **Market Filter**.

## Market Filter

Filtra o marketplace de personagens do **The Classic PW 1.8.7**
([marketplace.theclassic.games/pw187](https://marketplace.theclassic.games/pw187))
pelos **itens equipados** — o que o site não deixa fazer.

Lá dá pra filtrar por classe e por uma faixa grossa de preço. O que decide se
um personagem vale a compra é o equipamento, e pra ver equipamento você tem que
abrir as 770 páginas na mão.

## Por que o nome do item não basta

Três armas de Guerreiro têm a palavra *Dilacerador* no nome e três valores
diferentes do atributo que importa:

| arma | Nível de Ataque | faixa de preço |
|---|---|---|
| ★★★Dilacerador Raivoso | **70** | 1000 TCC |
| ★★★Dilacerador do Vento | 40 | 90 a 500 TCC |
| ★★Dilacerador Gelado | 30 | 45 a 150 TCC |

Por isso todo lugar onde este app mostra um item mostra o número junto.

E o número separa mais do que parece: das 770 fichas coletadas, **139
personagens** carregam uma arma de 70 — cada classe tem a sua, com nome
diferente — do mais barato a **130 TCC** ao mais caro a **8000**.

## Como usar

Escolha a classe, escolha a arma pelo nome com o atributo ao lado, e os
personagens que a usam aparecem do mais barato pro mais caro. Clicar num card
abre a ficha real no marketplace.

Para perguntas que o seletor não formula — "70 de ataque em qualquer peça",
"elmo rank 4 no +11" — há os filtros por atributo embaixo, combináveis.

## Como funciona

Dois programas, um arquivo entre eles.

```
site  ──►  tool/collect.dart  ──►  web/market_index.json  ──►  app Flutter
           coletor, Dart puro       o contrato                 filtra em memória
```

O coletor lê a lista inteira numa requisição e depois as fichas, **uma por vez,
a cada 1,5 s** — o site bloqueia por IP, e a lentidão é o desenho, não uma
primeira versão a otimizar. O que ele já leu fica gravado, então uma
atualização é uma requisição pra lista mais os personagens novos: segundos, não
os 28 minutos da primeira passada.

O app não sabe o que é HTML e o coletor não sabe o que é filtro.

## Rodando local

```bash
flutter pub get
dart run tool/collect.dart          # ~28 min na primeira vez
dart run tool/fetch_icons.dart      # ícones de classe e de item
flutter run -d chrome
```

Depois disso, `dart run tool/collect.dart --resume` atualiza em segundos, e
`--rebuild` reescreve o índice a partir do que está em disco, sem rede.

Sem coleta nenhuma o app abre dizendo qual comando rodar, em vez de abrir vazio.

## Publicação

Um workflow do GitHub Actions coleta a cada 20 minutos e republica no GitHub
Pages. Roda no IP do runner, não no seu.

## Aviso

Projeto de fã, sem vínculo com o The Classic Games. Lê apenas páginas públicas
do marketplace, uma requisição de cada vez.
