# Registro de Jogadores da Guild — design

> Data: 2026-11-26. Primeiro subsistema de uma plataforma maior; a *sala de
> guerras* é um segundo projeto, desenhado à parte.

## O problema

Quem tem seis personagens numa guild não sabe, de cabeça, quem bate mais, quem
aguenta mais, quem está pronto para uma TW. O marketplace tem os dados exatos
de um personagem — mas **só de quem está à venda**, e os jogadores da guild não
estão. A única fonte do build de um jogador da guild é a **tela de personagem**
dele, que ele vê no cliente.

Medido num print real (o Mozaum, Retalhador nível 105 do Ragnarok): o painel
**Personagem** é texto e lê-se inteiro — HP `59225`, Nível de Ataque `428`,
as seis defesas, crítico `74%`, índice de dano, sobrevivência. Já o
**equipamento** e as **runas** são só ícones: o nome, o nível de ataque da
arma, o refino e as pedras moram no *tooltip*, que o print não mostra. Base,
Con/For/Int/Des, o jogador pode deixar `Oculto`.

**Conclusão que molda tudo:** dá para registrar o *poder efetivo* de um
jogador a partir do print; **não** dá para registrar o gear item a item. A base
é de status, não de inventário.

## O objetivo deste subsistema

Um painel autenticado onde a staff da guild **adiciona, remove, edita e filtra**
jogadores pelos seus status, a partir do print da tela de personagem. Três
peças: **contas + papéis** (a fundação), a **base de jogadores**, e o **upload
do print**.

## O que este subsistema NÃO é (não-objetivos)

- **Não é a sala de guerras.** Essa é a segunda peça, desenhada depois. Os
  papéis já preveem o acesso a ela, mas a tela não entra aqui.
- **Não lê a imagem sozinho.** O site publicado não tem como chamar um leitor
  de visão. O print sobe, fica *pendente*, e a transcrição dos status é feita
  à mão numa sessão de trabalho (hoje, por mim; amanhã, por quem for). Leitura
  automática por OCR/IA é um projeto à parte, com custo e risco próprios.
- **Não tem fluxo de aprovação.** Quem tem permissão edita direto; não há
  "solicitar e aprovar" (decisão do dono, 26/11).
- **Não tem auto-registro.** As contas são criadas pelo admin e distribuídas.
  Não há cadastro aberto.
- **Não guarda o inventário item a item.** Ver a conclusão acima.

## Papéis e permissões

Contas de verdade, com um papel cada. A matriz:

| Ação | Admin | Staff editor | Staff básico | Sala de guerras |
|---|---|---|---|---|
| Ver a lista de jogadores | ✓ | ✓ | ✓ | — |
| Adicionar / editar / remover jogador | ✓ | ✓ | ✓ | — |
| Subir print | ✓ | ✓ | ✓ | — |
| Gerir contas e papéis | ✓ | — | — | — |
| Sala de guerras *(2ª peça)* | ✓ | ✓ | — | ✓ |

O papel **Sala de guerras** e a coluna dela existem no modelo desde já, mas a
tela que ela abre é a segunda peça. A diferença entre *staff editor* e *staff
básico* nesta primeira peça é só o acesso futuro à sala de guerras — na base de
jogadores os dois fazem o mesmo.

Quem **sobe o print** é quem tem conta (admin e staff). Não há papel de "membro"
que entre no site: o membro manda o print para a staff (pelo Discord), e a
staff sobe. Se um dia quisermos membros subindo o próprio print, é um quarto
papel, somado sem refazer nada.

## Arquitetura

### Onde mora, e a decisão de dependência

O app Flutter de hoje fala com o Supabase por **HTTP puro** (pacote `http`),
sem o SDK `supabase_flutter`. Autenticação com sessão e *refresh token* é
sensível, e é justamente onde um SDK maduro vale mais do que código à mão.
Duas saídas:

- **(A — recomendada) Rota Flutter `/guild` + `supabase_flutter`.** O painel é
  uma rota nova do app, atrás de login, reusando tema, estado (Bloc/GetIt) e os
  widgets que já existem. O SDK cuida da sessão, do refresh e das consultas
  autenticadas (que respeitam o RLS). **Custo:** uma dependência nova — e a
  regra deste repositório é não adicionar dependência sem o dono aprovar. É uma
  decisão para a revisão do spec.
- **(B) Rota Flutter `/guild` + auth na mão sobre o GoTrue REST.** Sem
  dependência nova: login por `POST /auth/v1/token`, guardar `access_token`/
  `refresh_token`, anexar `Bearer` ao PostgREST, renovar quando expira. **Custo:**
  mais código e mais superfície de bug num ponto security-sensitive — exatamente
  o que um SDK evita.

**Decisão do dono (26/11): saída (A), com `supabase_flutter`.** É o único lugar
do site com auth de verdade, e hand-roll de token é onde mora o bug de
segurança. A rota fica atrás de login e o código do painel viaja no bundle de
todos — o que protege os dados é o **RLS no banco**, nunca esconder a UI. Fica
a primeira dependência nova do repositório aprovada de propósito, e só para
isto.

*(Uma terceira via — página estática `/guild` em HTML+JS com `supabase-js`, como
o `/guerras` faz — foi considerada e descartada: montar CRUD com papéis em JS
puro é mais tedioso e sai de fora da suíte de testes em Dart.)*

### O banco (Supabase, projeto `portal-pw`)

Três coisas novas:

1. **`perfis`** — liga cada conta do Supabase Auth a um papel.
   `(id uuid → auth.users, papel text check in ('admin','staff_editor','staff_basico','sala_guerras'), nome text, criado_em)`.
2. **`jogadores`** — um registro por personagem (ver o esquema de status
   abaixo), mais `print_url text` (o print inteiro), `recorte_runas_url text` e
   `recorte_gear_url text` (os recortes para mostrar debaixo do jogador, nulos
   até a transcrição), `status text check in ('pendente','transcrito')`,
   `criado_por uuid`, `criado_em`, `atualizado_em`.
3. **Bucket `prints`** no Supabase Storage — a imagem de cada jogador, só para
   quem tem conta.

### RLS — quem lê e escreve o quê

Ao contrário do resto do site (leitura-aberta), aqui **tudo é fechado ao
anônimo**: a chave publicável não lê nem escreve `jogadores`, `perfis` nem o
bucket. O acesso é só para o papel `authenticated`, e as políticas leem o papel
do usuário a partir de `perfis`:

- `jogadores`: `select` para qualquer autenticado com papel de staff/admin;
  `insert/update/delete` idem (nesta peça, os três papéis de edição podem tudo
  na base). Uma função `papel_do(uid)` (security definer) devolve o papel, e as
  políticas a usam — como o mapa já faz com `security_invoker`.
- `perfis`: `select` do próprio; `insert/update/delete` só admin.
- Storage `prints`: `insert/select` para autenticados; sem acesso anônimo.

Criar conta é no painel do Supabase (ou numa tela de admin), por quem é admin —
não há cadastro público.

### O fluxo dos dados

```
staff faz login  →  sobe o print (Storage, bucket prints)
                 →  cria o registro do jogador com status 'pendente'
                 →  [sessão de trabalho] eu leio os prints pendentes
                 →  preencho os status, status vira 'transcrito'
                 →  a lista mostra, filtrável
```

Um registro `pendente` aparece na lista com os status em branco e um aviso de
"à espera de transcrição". Isso é honesto: a staff vê que subiu e está na fila,
sem fingir que já leu.

## O esquema de status

Os campos vêm do painel **Personagem** do print, que é texto legível:

**Identidade:** `nome`, `cla`, `classe`, `nivel`, `despertares`, `cultivo`,
`limite` (ex.: *Céu Soberano IV*).

**Combate (o que se filtra):** `hp`, `mp`, `ataque_fisico` (texto, é um
intervalo), `ataque_magico`, `acerto`, `nivel_ataque`, `furia`, as seis defesas
(`def_fisica`, `def_metal`, `def_madeira`, `def_agua`, `def_fogo`, `def_terra`),
`esquiva`, `nivel_defesa`, `critico`, `canalizacao`, `penetracao_fisica`,
`penetracao_magica`, `espirito`, `indice_dano`, `sobrevivencia`.

Guardados como número onde são número (para ordenar e filtrar), e como texto
onde o jogo mostra intervalo (`100039-104485`). Um campo que o jogador deixou
`Oculto` fica nulo — e nulo é *não informado*, nunca zero, pela mesma razão que
um conduíte sem atributo não desenha zero.

## O print como referência visual

As **cartas**, o **gear** e as **runas** ficam de fora do *dado* estruturado —
as cartas dariam só o tipo, e o nível da arma, o refino, as pedras e o nível de
cada runa moram no tooltip, não no ícone. Mas o print guarda tudo isso como
**imagem**, e é aí que entra a ideia do dono (26/11): **usar partes do print
como referência visual.**

Além do print inteiro, o registro guarda **recortes** — o painel de runas, o de
equipamento — e a lista mostra-os debaixo de cada jogador. Não vira dado
filtrável (não dá para ordenar por «runa nível 8» a partir de um ícone), mas o
olho vê o setup de runas e de gear de cada um. **A base passa a ter as duas
metades:** os status, que se filtram; e a cara do build, que se vê.

Os recortes são feitos à mão na mesma sessão de transcrição — porque a janela
do jogo pode estar arrastada para qualquer canto do print, e um corte por
coordenada fixa erraria. Quem transcreve recorta, como quem lê os números.

## A tela

- **Login** — e-mail e senha (Supabase Auth). Erro claro, sem vazar se o e-mail
  existe.
- **A lista** — tabela dos jogadores, uma linha cada, com os status-chave
  (classe, limite, nível de ataque, HP, defesas, crítico). Filtro por status
  (ex.: *nível de ataque ≥ X*, *por classe*, *por limite*) e ordenação por
  coluna, no modelo das ferramentas que o site já tem (Títulos, o filtro do
  mercado). Os `pendente` aparecem marcados.
- **Adicionar / editar** — um formulário com os campos do esquema e o upload do
  print. Visível conforme o papel.
- **Admin** — uma tela simples de contas e papéis, só para o admin (pode ser a
  própria tela do Supabase numa primeira versão).

## Segurança

- **O RLS é a linha de defesa, não a UI.** O painel inteiro pode viajar no
  bundle; sem uma sessão autenticada com papel, o banco não devolve nem aceita
  nada. Provar com `curl` anônimo antes de confiar — como o contador e o mapa
  já foram provados.
- **A chave de serviço nunca entra no cliente.** Criar contas e qualquer
  escrita privilegiada é no painel do Supabase ou num Worker, nunca no bundle.
- **O print pode conter o nome do jogador e o clã** — é dado que a própria
  staff sobe, e o bucket é fechado ao anônimo. Nada de rosto nem dado pessoal
  além do nick do jogo.

## Testes

- O domínio (o modelo do jogador, o parsing dos números do print quando eu
  transcrevo, a lógica de filtro) é Dart puro e testado como as outras
  ferramentas — Red/Green.
- O RLS é provado por `curl` contra o Supabase: um anônimo recebe `401/empty`,
  um `staff_basico` não gere contas, um `select` sem sessão não devolve linha.
- A tela ganha testes onde ganham o seu sustento (o filtro, a lista vazia, o
  estado *pendente*), sem meta de cobertura.

## Decisões tomadas (26/11)

1. **`supabase_flutter` aprovado** — saída (A).
2. **Primeiro adicionar, depois filtrar.** A primeira iteração é login +
   papéis + criar o registro + subir o print (e os recortes) + ver a lista; o
   **filtro por status e o refino de quais campos filtrar** vêm numa segunda
   iteração, sobre dados reais. Não se afina o filtro no vazio.
3. **Sem conta de membro.** Só staff — com ou sem a permissão da sala de
   guerras. O papel da staff é popular e melhorar o status dos jogadores a
   partir das imagens; o membro manda o print pela staff.
4. **O print vira referência visual** — recortes de runas e de gear debaixo de
   cada jogador, além dos status. Ver *O print como referência visual*.
