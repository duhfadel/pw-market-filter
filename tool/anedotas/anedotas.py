# -*- coding: utf-8 -*-
"""As Anedotas do Céu, como dados — uma página por Limite de Céu.

As anedotas são o diário de missões do jogo, e os dez **Limites de Céu**
(Arcano → Soberano) são a espinha delas: cada Limite abre a sua anedota, e
concluir uma parte dá um Título com atributo — o mesmo sistema da ferramenta
de Títulos. O mercado mede o total num número só (`Progresso total … / 2756`),
que não diz onde você parou; estas páginas dizem.

**De onde vem, e a honestidade disso.** A Trivia PW removeu os guias de
anedota, e a Wiki PW esteve fora do ar quando isto foi levantado. A espinha
veio da **PWpedia** (inglês), e o lado brasileiro foi conferido contra a
Trivia, a Wiki PW e a `pwdatabase.com/br`: a geografia é a mesma (Mundo
Primitivo, Cidade de Kirin) e as coordenadas batem com ±1 — o Imperador
Branco: Alexander em `380,474`, o Caldeirão Sagrado em `370,464`, o Emissário
do Céu Arcano em `373,469`. Os nomes de NPC e item em português são os do
nosso cliente onde foram confirmados; onde não foram, ficam marcados, nunca
afirmados.

`passos` é um por missão, na ordem em que o jogo as entrega. As marcas são as
mesmas das Sagas: `**negrito**`, `` `coord` ``, `[texto](url)` e `*itálico*`
para a ação que se executa na interface (*Meditar*).

`pronto` diz se a página do reino já foi escrita. O índice lista os dez em
ordem de qualquer jeito — um reino por escrever aparece esmaecido, *em breve*,
em vez de sumir, porque a ausência é informação: diz quanto falta.
"""

# Os blocos de abertura do índice — o que vale para todos os dez reinos.
GERAL = [
    {
        'titulo': 'O que são as anedotas, e por que elas valem',
        'paragrafos': [
            '**A anedota é o diário de missões do Mundo Perfeito.** Ela guarda '
            'em que ponto de cada linha de missões você parou, e serve de '
            'mapa para não se perder entre centenas delas. O mercado resume '
            'tudo num número — `Progresso total … / 2756` — que diz o quanto, '
            'mas não o quê nem onde.',

            '**Concluir uma parte dá um Título com atributo.** É a mesma moeda '
            'da ferramenta de [Títulos](/registros): cada anedota fechada '
            'solta um título permanente. Por isso vale fazê-las em ordem — e '
            'por isso elas estão aqui.',

            '**Os dez Limites de Céu são a espinha.** Arcano, Miragem, Astral, '
            'Oscilante, Crepúsculo, Real, Devoto, Ápice, Majestoso e Soberano: '
            'cada Limite abre a sua própria anedota, e subir um é o que '
            'destrava o próximo. Esta é a página de cada um, na ordem do jogo.',
        ],
    },
    {
        'titulo': 'Antes de começar o Céu Arcano',
        'paragrafos': [
            '**O Céu Arcano é o primeiro Limite, e abre no nível '
            '`90` com um Despertar.** Ele acontece no **Mundo Primitivo**, em '
            'volta da **Cidade de Kirin** — o mesmo mapa que a versão '
            'internacional chama *Primal World*. Para chegar lá você precisa '
            'ter fechado a fase histórica do Pináculo do Mundo no Despertar I.',

            'A linha não dá só o Limite: as missões pagam experiência, '
            'espírito, reputação e as **Páginas do Céu Arcano**, que são o que '
            'alimenta a subida do próprio Limite.',
        ],
    },
]


REINOS = []

REINOS.append({
    'slug': 'arcano',
    'nome': 'Arcano',
    'ceu': 'Céu Arcano',
    'ingles': 'Arcane Sky',
    'ordem': 'o primeiro dos dez Limites',
    'requisito': 'Nível 90, Despertar I (após o Pináculo do Mundo e os Novos Horizontes)',
    'resumo': 'A primeira anedota de Céu, no Mundo Primitivo, em volta da '
              'Cidade de Kirin. Desbloqueá-la sobe o seu Limite de Céu pela '
              'primeira vez; as missões pagam experiência, espírito, reputação '
              'e as Páginas do Céu Arcano.',
    'comecar':
        'Primeiro você destrava o Limite, em duas missões que o jogo entrega '
        'sozinho quando você chega ao Mundo Central no nível `90` com um '
        'Despertar:\n'
        '**1. Explore o Mundo Primitivo** — fale com o **Mensageiro do Tempo** '
        'na plataforma central de Arcosaur, em `553,655(28)`. Ele abre o '
        'teleporte para o Mundo Primitivo. Recompensa: um Pacote de Avatar de '
        'Guerra C.\n'
        '**2. O Que é o Limite?** — já no Mundo Primitivo, fale com o '
        '**Caldeirão Sagrado** na Cidade de Kirin, em `370,464`. Use a ação '
        '*Meditar* e espere `10` segundos — cinco vezes. Depois fale com o '
        '**Emissário do Céu Arcano** em `373,469`. Isso sobe o seu Limite para '
        'Céu Arcano e abre a anedota.',
    'passos': [
        '**Pré-Céu Arcano: as quatro vigias** — com o Emissário do Céu Arcano '
        '(`373,469`) como despachante, fale com os quatro Postos de Vigia no '
        'ar: o da Cidade de Kirin em `378,458(38)`, o da Torre do Dragão em '
        '`319,516(43)`, o do Cume do Macaco da Neve em `374,578(50)` e o da '
        'Fortaleza do Tirano em `351,624(47)`. Em cada um aparece uma Sombra '
        'Repentina que conta um pedaço do lugar. Volte ao Emissário. '
        'Recompensa: um Pacote de Avatar de Guerra C.',

        '**Pré-Céu Arcano: Força Necessária** — ao chegar ao nível `90` ou '
        'acima, fale de novo com o Emissário do Céu Arcano (`373,469`). '
        'Recompensa: `10` Sangue Primordial e uma Página do Céu Arcano. É o '
        'que libera a anedota propriamente dita.',

        '**Céu Arcano I: o Registro do Exército** — fale com o **Imperador '
        'Branco: Alexander**, atrás da área de nascimento humana da Cidade de '
        'Kirin, em `380,474`. Pegue um Registro do Exército no Registro ali ao '
        'lado (`377,471`) e entregue a ele. Depois fale com o **Comandante '
        'Wei**, no grupo da Força de Resistência (`379,467`), e volte ao '
        'Alexander. Recompensa: `2952` Moedas de Prata, `1.475.700` de '
        'experiência, `590.280` de espírito, `148` de reputação e `394` de '
        'vitae.',

        '**Céu Arcano I: limpar o Exército Tirano** — ainda com o Imperador '
        'Branco: Alexander (`380,474`), mate `5` Guerreiros do Exército Tirano '
        'perto dele, fale com o Comandante Wei (`379,467`) e mate `3` Soldados '
        'do Exército Tirano. Cuidado ao atacar: é fácil puxar monstros demais '
        'de uma vez — se isso acontecer, suba ao ar e fique parado até eles '
        'voltarem ao lugar.',

        '**Céu Arcano II: o Posto Avançado do Tirano** — o despachante agora é '
        'o Posto de Vigia Roubado, no Reduto da Coruja do Céu (`338,473`). Vá '
        'ao Posto Avançado do Tirano (`346,488`) e fale com Linn Shoyo, na '
        'borda do acampamento (`350,488`).',

        '**Céu Arcano II: explodir os celeiros** — Linn Shoyo (`350,488`) dá '
        '`4` Dinamites. Entregue aos quatro Celeiros do posto — em `348,487`, '
        '`347,486`, `343,488` e `342,489` — o que dá para fazer do ar, sem '
        'puxar os monstros. Volte a Linn Shoyo, acenda o Pavio de Dinamite no '
        'meio do posto (`345,487`) e fale com ele de novo.',

        '**Céu Arcano III: os guaxinins de bambu** — fale com o Chefe Guaxinim '
        'de Bambu, na vila dele (`374,506`). Mate `5` Lutadores e `5` '
        'Guerreiros Guaxinim na Floresta do Crepúsculo, a oeste da vila, e '
        'cave as Pedras Suspeitas ao lado do Chefe (`375,505`) para um '
        'Guaxinim Ninja aparecer. Mate-o e volte ao Chefe.',

        '**Céu Arcano III: o Acampamento Avançado** — vá ao Acampamento '
        'Avançado do Tirano (`346,523`), fale com Chie Tenmus num canto dele '
        '(`341,525`), mate `5` Demônios Tóxicos ao sul e fale com a Placa na '
        'entrada do acampamento (`345,525`).',

        '**Céu Arcano IV: limpar o acampamento** — a partir daqui é preciso '
        'estar em Céu Arcano IV. Ainda no Acampamento Avançado, mate `6` '
        'Sentinelas Ocultas, junte `4` Hastes de Madeira dos Ídolos em volta '
        '(`342,529`, `344,526`, `349,533`) e mate Sacerdotes Sombrios por `2` '
        'Gemas. Entregue tudo ao Mastro Quebrado no meio (`344,528`) e acenda '
        'o Braseiro ao fundo (`345,534`).',

        '**Céu Arcano IV: o ritual no Altar Primitivo** — pegue a Varinha '
        'Primitiva no Braseiro, vá ao Altar Primitivo, ao norte (`341,547`), e '
        'conduza o ritual: limpe Soldados e Piromantes e os Focos Arcanos em '
        'volta, incendeie os Componentes do Ritual e conclua no Altar '
        '(`338,548`). **Voe o tempo todo** — um Xamã Sombrio patrulha o chão.',

        '**Céu Arcano IV: as vilas dos guaxinins** — siga para a Vila do '
        'Guaxinim das Árvores (`353,562`), colete um Cristal de Vitalidade '
        'espalhado pela vila, entregue ao Chefe de lá e limpe os Guaxinins '
        'Corrompidos em volta, na Planície da Aliança.',

        '**O fim do Céu Arcano: o Palácio da Prata Fluida** — a última missão '
        'da linha pede **Despertar II, nível `100`**, porque entra numa '
        'instância (a que o original chama *Flowsilver Palace*). É a parte '
        'mais dependente de versão — confirme o nome e o acesso no seu cliente '
        'antes de contar com ela.',
    ],
    'nota': '**No total, a linha do Céu Arcano paga cerca de `101.600` Moedas '
            'de Prata, `50` milhões de experiência, `20` milhões de espírito, '
            '`5.093` de reputação e `14.728` de vitae**, mais `2` Pacotes de '
            'Avatar de Guerra C, `10` Sangue Primordial, a Página do Céu '
            'Arcano e `100` Pílulas Místicas — contando o desbloqueio e as '
            'duas missões antes de subir o Limite.\n'
            '**Os nomes de NPC e item são tradução fiel da PWpedia; as '
            'coordenadas batem com o BR (±1).** Fez alguma e viu um nome ou uma '
            'coordenada diferente no seu cliente? Conte no '
            '[Discord](https://discord.gg/n5v3WdSJyg) que a gente acerta — uma '
            'correção de quem jogou vale mais do que três sites concordando.',
    'pronto': True,
})

# Os outros nove, na ordem do jogo — ainda por escrever. O índice mostra-os
# esmaecidos, para dizer quanto falta em vez de fingir que são só um.
REINOS.append({
    'slug': 'miragem',
    'nome': 'Miragem',
    'ceu': 'Céu da Miragem',
    'ingles': 'Mirage Sky',
    'ordem': 'o segundo dos dez Limites',
    'requisito': 'Nível 90, Despertar II, Céu de Miragem I (após a União da Justiça)',
    'resumo': 'A segunda anedota de Céu, ainda no Mundo Primitivo. Agora se '
              'enfrenta o Exército Tirano de perto — do Acampamento da '
              'Retaguarda à Vila de Outono e à Crista do Macaco da Neve — e a '
              'linha fecha num assalto à fortaleza.',
    'comecar':
        '**1. Chamado do Céu da Miragem** — com o Céu Arcano no `10` e a barra '
        'de vitae cheia, a missão chega sozinha. Depois do **segundo '
        'Despertar**, no nível `90`, fale com o Imperador Branco: Alexander em '
        'Kirin (`379,473`).\n'
        '**2. Céu da Miragem** — fale com Whitesurge, em Kirin (`371,463`) ou '
        'no Acampamento da Retaguarda do Tirano (`364,595`). Isso sobe o seu '
        'Limite para Céu da Miragem e abre a anedota.',
    'passos': [
        '**A escuridão da Espada de Luz** — Whitesurge manda falar com o '
        'Comandante Du, no Acampamento da Retaguarda do Tirano (`364,594`). '
        'Mate `5` Cavaleiros de Placa de Luz ali e volte a ele.',

        '**Escolhas difíceis** — mate `5` Infantes do Exército Tirano ao norte '
        'do acampamento e fale com o Aldeão de Outono, na Vila de Outono '
        '(`383,615`), a nordeste.',

        '**Tesouros da Vila de Outono** — junte os quatro tesouros ao norte da '
        'vila: em `383,628`, `384,626`, `383,624` e `379,627`. Leve ao Chefe '
        'da Vila de Outono (`387,618`).',

        '**Jovem cabeça-quente, e o Ancião** — colete `2` Planos Secretos do '
        'Tirano com os Aldeões Feridos a noroeste (`367,630`), entregue ao '
        'Chefe, e depois fale com o Ancião da Vila de Outono (`389,615`).',

        '**O segredo dos Macacos da Neve** — mate `5` Macacos da Neve Alfa na '
        'Crista do Macaco da Neve (fique longe do meio, por causa do Sacerdote '
        'e do Alto Cacique) e fale com Linn Shoyo, na saída da crista '
        '(`377,584`).',

        '**Prata Sagrada** — mate o Sacerdote do Macaco da Neve por um Minério '
        'de Prata Gélida. É um chefe de dano mágico que foge do corpo a corpo '
        '— melhor atraí-lo para o lado leste e atordoá-lo. Depois fale com '
        'Chie Tenmus (`377,584`).',

        '**A ajuda dos Guaxinins das Árvores** — vá à Vila do Guaxinim das '
        'Árvores (`358,560`), espere alguns segundos e fale depressa com um '
        'Aprendiz de Peão Guaxinim antes que ele se afaste.',

        '**O assalto à fortaleza** — a reta final encadeia aeronaves '
        'emprestadas, assassinos das sombras e o plano de ataque até o assalto '
        'à fortaleza do Tirano. A penúltima missão pede **nível `100`** e '
        'entra numa instância (o original chama *Flowsilver Palace*) — a parte '
        'mais dependente de versão; confirme no seu cliente.',
    ],
    'nota': '**A linha da Miragem é longa e fecha num assalto à fortaleza**, '
            'com a penúltima missão pedindo nível `100` e uma instância. Os '
            'nomes vêm da PWpedia e as coordenadas batem com o BR (±1) — viu '
            'diferente? Conte no [Discord](https://discord.gg/n5v3WdSJyg).',
    'pronto': True,
})

REINOS.append({
    'slug': 'astral',
    'nome': 'Astral',
    'ceu': 'Céu Astral',
    'ingles': 'Astral Sky',
    'ordem': 'o terceiro dos dez Limites',
    'requisito': 'Nível 100, Despertar II, Céu de Miragem X (após o Lacre Final)',
    'resumo': 'A terceira anedota muda de região: do Posto do Vigor às vilas '
              'de pedra do leste — Pedra de Tinta, Cidade Luneska, o '
              'Acampamento dos Goblins de Gelo e a Prisão Glacial. É a linha '
              'mais longa até aqui, com nove fases.',
    'comecar':
        'Com o Céu da Miragem no `10`, a missão chega pelo **Emissário do Céu '
        'Astral Zhou**, em Kirin (`377,460`), que o teleporta ao **Posto do '
        'Vigor** (`405,584`). Fale com os seis Postos de Vigia no ar — sobre o '
        'Posto do Vigor (`405,584`), a Vila Pedra de Tinta (`413,619`), as '
        'Ruínas Pedra de Névoa (`480,625`), a Cidade Luneska (`448,602`), o '
        'Acampamento dos Goblins de Gelo (`444,561`) e a Prisão Glacial '
        '(`435,584`) — e volte ao Imperador Branco: Alexander, agora na Vila '
        'de Outono (`388,614`).',
    'passos': [
        '**Reforços e insígnias** — pelo Alexander (Vila de Outono, '
        '`388,614`), limpe Desertores e Reforços do Exército Tirano em volta '
        'do Posto do Vigor e junte `3` Insígnias Luneskanas dos Cavaleiros '
        'Misteriosos. Entregue ao Tenente Kwei (`404,584`).',

        '**As pedras antigas** — com o Comandante Feng (`404,585`) e depois o '
        'Historiador, colete `4` Pedras Antigas ao norte do Posto do Vigor '
        '(dá para cavar a mesma quatro vezes) e entregue ao Historiador '
        '(`401,592`).',

        '**Os Oren da Pedra Escura** — mate Oren da Pedra Escura ao norte, '
        'fale com o Jovem Oren ao sul da Vila Pedra de Tinta (`412,607`) e '
        'junte `4` Fragmentos de Rocha, até alcançar o Céu Astral II.',

        '**Céu Astral II: a Vila Pedra de Tinta** — com o Chefe Pedra de Tinta '
        '(`409,618`), derrube Oren Gigantes por Fragmentos de Pedra Escura e '
        'cave o Caco de Pedra Antiga no centro da vila (`414,624`; o nome '
        'aparece em branco, atrás do caco). Leve ao Ancião (`409,620`).',

        '**Céu Astral II: o Colosso de Pedra Escura** — enfrente o Colosso de '
        'Pedra Escura, a leste da vila. É um chefe de ataque físico forte que '
        'baixa a sua defesa — melhor com ajuda.',

        '**Céu Astral III: a Fronteira Luneska** — pelo Oren Progenitor, na '
        'Vila Pedra de Tinta (`414,631`), e depois pelo Oren Errante, na '
        'Fronteira Luneska (`458,624`).',

        '**Céu Astral IV: as Ruínas Pedra de Névoa** — pelo Oren Infiltrador, '
        'na Fronteira Luneska (`472,636`), e o Oren Erudito, nas Ruínas Pedra '
        'de Névoa (`486,640`).',

        '**Céu Astral V: os campos de energia** — pelo Guardião de Alma '
        'Lunesco, nas Ruínas Pedra de Névoa (`481,625`), e o Guardião do Campo '
        'de Energia, no ar da Fronteira Luneska (`469,618`).',

        '**Céu Astral VI: o Acampamento dos Goblins de Gelo** — pela Sentinela '
        'do Campo de Energia (`459,565`) e o Mestre dos Goblins de Gelo, no '
        'acampamento deles (`443,560`).',

        '**Céu Astral VII–VIII: a Prisão Glacial** — pelo Comandante do Estado '
        'do Vigor, na Prisão Glacial (`439,594`), e os Comandantes de Assalto '
        'Norte e Oeste, na Fronteira Luneska (`480,616` e `450,604`).',

        '**Céu Astral IX: a Cidade Luneska** — fecha com o Comandante de '
        'Assalto Oeste (`450,604`) e o Espelho da Visão Distante, na Cidade '
        'Luneska (`483,587`).',
    ],
    'nota': '**A linha do Astral tem nove fases e é a mais longa até aqui** — '
            'do Posto do Vigor à Cidade Luneska. Nomes e coordenadas da '
            'PWpedia, que batem com o BR (±1). Viu um passo diferente? '
            '[Discord](https://discord.gg/n5v3WdSJyg).',
    'pronto': True,
})

REINOS.append({
    'slug': 'oscilante',
    'nome': 'Oscilante',
    'ceu': 'Céu Oscilante',
    'ingles': 'Shifting Sky',
    'ordem': 'o quarto dos dez Limites',
    'requisito': 'Nível 100, Despertar II, Céu Astral X',
    'resumo': "A quarta anedota desce para debaixo d'água, no Mar Silencioso. "
              'Você monta num peixe e cruza as vilas do fundo — Costa-Mar, a '
              'Enseada da Pérola, a Floresta Reluzente e Marévoa — numa linha '
              'de nove fases.',
    'comecar':
        'Com o Céu Astral no `10`, fale com a **Imagem de Althea**, em Kirin '
        '(`373,465`), que o teleporta ao alto das Escadas de Astraluna '
        '(`401,522`), a nordeste. Fale com o Imperador Branco: Alexander ali '
        "ao lado (`403,521`). Daqui em diante tudo acontece debaixo d'água.",
    'passos': [
        '**Sob o mar** — com o Comandante da Frota Corcoran, na Frota Aliada '
        '(`417,528`), você monta num peixe que mostra o Mar Silencioso e o '
        'deixa na frente da Vila Costa-Mar (`425,501`). Bárbaro e Feiticeira '
        'precisam estar em forma humana para montar.',

        '**Céu Oscilante II: a Enseada da Pérola** — com o Chefe Costa-Mar '
        'Wavelance (`427,506`), vá à Enseada da Pérola (`461,502`), mate um '
        'Saqueador Shoka e fale com o Chefe Aphon, dentro do tronco oco na '
        'Floresta Reluzente (`471,536`).',

        '**Céu Oscilante III: o Eremita Sem Nome** — ache o Eremita Sem Nome, '
        'que vagueia pela Floresta Reluzente (`481,531`), espere meio minuto e '
        'fale de novo com ele nas Ruínas de Marécorrente (`444,529`).',

        '**Céu Oscilante IV–V: Marévoa** — com o Senhor da Maré Hydro, em '
        'Marévoa (`446,486`), recupere o Memento da Maré no Memorial '
        '(`447,492`) e fale com o Comandante Rowan (`447,485`). Depois limpe '
        '`5` Batedores Shoka ao sul e fale com o Chefe Astronus, na Vila '
        'Mar-Estrela (`435,458`).',

        '**Céu Oscilante VI–VII: Marévoa e a Vila Mar-Estrela** — de volta ao '
        'Senhor da Maré Hydro (`446,486`) e ao Chefe Astronus, na Vila '
        'Mar-Estrela (`435,458`), e depois ao Comandante Rowan, em Marévoa '
        '(`447,485`).',

        '**Céu Oscilante VIII: o Acampamento da Vanguarda** — o Comandante '
        'Rowan muda-se para o Acampamento da Vanguarda (`496,472`); a linha '
        'segue por ele ali.',

        '**Céu Oscilante IX: a Plataforma Abissal** — fecha com o Rowan '
        '(`496,472`) e o Batedor Naveen, na Plataforma Abissal (`478,454`).',
    ],
    'nota': "**Toda a linha do Oscilante é debaixo d'água, no Mar Silencioso**, "
            'em nove fases, do Mar Silencioso à Plataforma Abissal. Nomes e '
            'coordenadas da PWpedia (batem com o BR ±1). Viu diferente? '
            '[Discord](https://discord.gg/n5v3WdSJyg).',
    'pronto': True,
})

REINOS.append({
    'slug': 'crepusculo',
    'nome': 'Crepúsculo',
    'ceu': 'Céu do Crepúsculo',
    'ingles': 'Twilight Sky',
    'ordem': 'o quinto dos dez Limites',
    'requisito': 'Nível 100, Despertar II, Céu Oscilante X',
    'resumo': 'A quinta anedota começa em Marévoa e se abre em três caminhos '
              '— Fogo, Vento e Água —, cada um com o seu Senhor elemental. São '
              'dez fases, as maiores até aqui.',
    'comecar':
        'Com o Céu Oscilante no `10`, fale com o **Senhor da Maré Hydro**, em '
        'Marévoa (`446,486`), e com o Batedor Shensei ao lado (`443,486`).',
    'passos': [
        '**Céu do Crepúsculo I–II** — pelo Hydro (`446,486`), fale com o '
        'Comandante da Muralha Seidon, no extremo norte da Muralha do Abismo '
        '(`454,463`), limpe `5` Batedores Shoka ao sul e fale com o Chefe '
        'Astronus, na Vila Mar-Estrela (`435,458`). Depois fale com o Arauto '
        'de Pelágius, em Marévoa (`450,481`).',

        '**Céu do Crepúsculo III: os três Senhores** — pelo Imperador Branco: '
        'Alexander, em Kirin (`379,473`), apresente-se aos três Senhores '
        'elementais: o Senhor do Fogo Pyrathion, na Vila de Outono '
        '(`388,612`); o Senhor do Vento Tempestra, no Acampamento dos Goblins '
        'de Gelo (`444,561`); e o Senhor da Água Pelágius, na Floresta '
        'Reluzente (`471,536`). Volte ao Alexander.',

        '**Escolha um caminho: Fogo, Vento ou Água** — durante as fases III a '
        'V você decide qual Senhor ajudar, gastando um Tratado de Ajuda '
        'Imperial. Cada caminho é uma série própria de missões, aberta pelos '
        'Arautos em Kirin (`371,471` Vento, `372,472` Água, `373,470` Fogo).',

        '**Céu do Crepúsculo IV–VI: de volta a Kirin** — depois do caminho '
        'escolhido, três fases com o Imperador Branco: Alexander, em Kirin '
        '(`379,473`).',

        '**Céu do Crepúsculo VII–IX: os três Senhores em Modo História** — '
        'revisite o Senhor do Fogo Pyrathion, na Vila de Outono (`386,615`), o '
        'Senhor do Vento Tempestra, nas Ruínas Pedra de Névoa (`481,625`), e o '
        'Senhor da Água Hydro, em Marévoa (`446,486`).',

        '**Céu do Crepúsculo X: a Corte do Rei Shoka** — a última fase '
        'teleporta você para uma masmorra (a Corte do Rei Shoka), que você '
        'provavelmente terá de fechar sozinho. Prepare-se antes de começar: '
        'concluir "Eco das Eras" tranca o retorno à instância.',
    ],
    'nota': '**O Crepúsculo tem dez fases e uma escolha de caminho — Fogo, '
            'Vento ou Água — e fecha numa masmorra.** Nomes e coordenadas da '
            'PWpedia (batem com o BR ±1). Viu diferente? '
            '[Discord](https://discord.gg/n5v3WdSJyg).',
    'pronto': True,
})

REINOS.append({
    'slug': 'real',
    'nome': 'Real',
    'ceu': 'Céu Real',
    'ingles': 'Royal Sky',
    'ordem': 'o sexto dos dez Limites',
    'requisito': 'Nível 100, Despertar II, Céu do Crepúsculo X',
    'resumo': 'A sexta anedota muda de continente: vai para Neverfall e as '
              'Estepes do Oeste. Passa pela Vila dos Vaga-lumes, as Ruínas do '
              'Titã, o Castelo Desolado e Dalmoor, em dez fases.',
    'comecar':
        'Com o Céu do Crepúsculo no `10`, ao entrar nas Estepes do Oeste a '
        'missão chega sozinha e o teleporta ao norte de Neverfall (`350,644`), '
        'perto da Imperatriz da Luz Althea.',
    'passos': [
        '**Céu Real I: a Vila dos Vaga-lumes** — com a Garota Cega, na Vila '
        'dos Vaga-lumes (`350,712`), pegue o Símbolo no Símbolo Misterioso ao '
        'norte (`343,723`) e entregue a Firefly Entha (`343,717`).',

        '**Céu Real II: as Frutas Quasímodo** — no Vale de Messinar (Ruínas do '
        'Titã), use a Rede de Vara para matar `5` Frutas Quasímodo no ar '
        '(`331,691`) — elas são imunes a dano normal — e fale com Mahmu, o '
        'Titã (`332,698`). Cuidado com a Serpe das Areias Mortas, que voa pela '
        'área.',

        '**Céu Real III–IV: o Castelo Desolado** — pelo Fantasma de uma '
        'Garota, nas Ruínas do Titã (`316,716`); não saia da área do Templo da '
        'Morte ou a missão falha. Depois, no Castelo Desolado (`354,725`), '
        'mate `8` Bruxos Perversos e fale com o Soldado Monson (`352,722`).',

        '**Céu Real V–VI: girassóis e Dalmoor** — colete `5` Girassóis Murchos '
        'a noroeste do Arbusto de Girassol e entregue a Kimchala (`376,692`). '
        'Depois, com o Pastor Louco em Dalmoor (`388,675`), fale com o Ancião '
        'Bolafofa na Vila Bolafofa (`423,657`).',

        '**Céu Real VII: a Cavalaria da Rosa** — pelo Comandante da Cavalaria '
        'da Rosa Vetrin, na Vila Bolafofa (`420,655`).',

        '**Céu Real VIII–IX: o Agouro e o Vulcão** — pela Dama de Gelo do '
        'Agouro, na Fonte do Agouro (`409,696`), e o Cacique Sheren, no '
        'Aglomerado Vulcânico de Dallagher (`487,714`).',

        '**Céu Real X: o Templo da Queda Celeste** — a última fase pede o '
        'Templo da Queda Celeste até o **andar `18`** (uma instância). Vale '
        'limpar até lá antes de começar as missões, para poupar buffs de '
        'vitae.',
    ],
    'nota': '**O Real muda de continente, para Neverfall e as Estepes do '
            'Oeste**, em dez fases, da Vila dos Vaga-lumes ao Templo da Queda '
            'Celeste. Nomes e coordenadas da PWpedia (batem com o BR ±1). Viu '
            'diferente? [Discord](https://discord.gg/n5v3WdSJyg).',
    'pronto': True,
})

REINOS.append({
    'slug': 'devoto',
    'nome': 'Devoto',
    'ceu': 'Céu Devoto',
    'ingles': 'Pious Sky',
    'ordem': 'o sétimo dos dez Limites',
    'requisito': 'Nível 100, Despertar II, Céu Real X',
    'resumo': 'A sétima anedota é uma história longa na cidade de Nicada, nas '
              'Estepes do Oeste — dezenas de missões em torno da Câmara de '
              'Comércio, dos aprendizes e dos mutantes que cercam a cidade.',
    'comecar':
        'Com o Céu Real no `10` e a barra de vitae cheia, ao entrar nas '
        'Estepes do Oeste a missão chega sozinha. Fale com o **Emissário do '
        'Céu Devoto Kuza**, em Nicada (`565,600`), para obter o Céu Devoto 1.',
    'passos': [
        '**Visitar o Castelão, acampar em Nicada** — pelo Kuza (`565,600`), '
        'fale com o Lorde de Nicada Adrien (`554,589`) e depois com o '
        'Atendente Phil (`561,597`).',

        '**A Câmara de Comércio** — fale com o Presidente Edmond (`569,609`); '
        'ele o põe num balão numa volta pela cidade. Não pode estar '
        'transformado para aceitar a missão.',

        '**Comprar materiais, e o ataque** — pela Guarda Real Rachia '
        '(`548,603`), compre `10` Jades Laranja do Comerciante Barzel '
        '(`547,598`). Depois mate `10` Lobos Mutantes fora da cidade (em volta '
        'de `528,603`) e volte a Rachia.',

        '**Inquérito e os aprendizes** — a história segue por Nicada: Barzel '
        '(`547,598`), Alicia (`547,600`), o Curador Ilio no prédio do Distrito '
        'Financeiro (`540,607`) e os aprendizes Carl e Eily.',

        '**Da cidade à estrada** — a história segue de Nicada para a Estação '
        'de Cargas, com o Chefe dos Correios Cahill (`562,579`), e depois para '
        'Warmspring, com a Arquimaga Dolores (`592,565`).',

        '**O retorno a Nicada** — a linha volta ao Distrito Financeiro de '
        'Nicada, com Goodhill (`545,611`), e às Estepes do Oeste, com a '
        'Arquimaga Pandora (`542,581`), encadeando dezenas de missões — os '
        'mutantes, o Cavaleiro, o Castelo Spotwood — até o fim.',
    ],
    'nota': '**O Devoto é a anedota mais longa — uma história inteira em '
            'Nicada**, com dezenas de missões encadeadas. Como não tem fases '
            'numeradas, aqui ficam os marcos com coordenada; use a janela de '
            'missões (tecla `Q`) para não se perder. Nomes e coordenadas da '
            'PWpedia (batem com o BR ±1). Viu diferente? '
            '[Discord](https://discord.gg/n5v3WdSJyg).',
    'pronto': True,
})

REINOS.append({
    'slug': 'apice',
    'nome': 'Ápice',
    'ceu': 'Céu Ápice',
    'ingles': 'Apex Sky',
    'ordem': 'o oitavo dos dez Limites',
    'requisito': 'Nível 100, Despertar II, Céu Devoto X',
    'resumo': 'A oitava anedota continua nas Estepes do Oeste, em Drapna e na '
              'Vila Hannibal, com a Imperatriz da Luz Althea te acompanhando. '
              'A linha fecha rumo ao Palácio da Perdição.',
    'comecar':
        'Com o Céu Devoto no `10` e a barra de vitae cheia, a missão chega '
        'sozinha. Fale com o **Apóstolo do Ápice Zenet**, em Drapna '
        '(`522,567`).',
    'passos': [
        '**A caçada a Aida continua** — você é teleportado ao Clã dos '
        'Alquimistas; fale com a Imperatriz da Luz Althea no Pilar Telepático '
        '(`570,528`). Ela passa a te seguir (só você a vê). Investigue a Vila '
        'Hannibal (`521,533`) com ela — fique no chão para concluir.',

        '**O Pássaro sem Alma** — na Vila Hannibal (`522,534`), mate `5` '
        'Pássaros sem Alma no céu (`518,535`) e `5` Espantalhos ao lado '
        '(`516,537`), falando com Althea entre as etapas.',

        '**A Alma do Feno** — ache a origem do grito enquanto mata os '
        'Espantalhos (`517,539`): use a ação Atacar num Espantalho, fale com o '
        'Espantalho Bod (`516,541`) e mate `5` Espíritos do Medo (`519,540`).',

        '**Tabu, e o resgate** — pelo Espantalho Bod (`516,541`), mate o Clone '
        'de Tattiul que surge em cima de você e volte a falar com Althea '
        '(`522,534`).',

        '**As tribos e as forjas** — a história passa pelo Clã dos Alquimistas '
        '(`587,507`), a Forja de Lava (`571,500`), as Planícies do Espírito '
        'Sagrado (`556,509`), a Tribo dos Morcegos Vampiros (`511,518`) e a '
        'Tribo do Senhor das Feras (`543,499`).',

        '**A caçada a Aida** — ela aparece nas Cavernas Sem Fim (`583,469`); a '
        'linha segue para o Fórum do Esquecimento (`543,459`) e volta à '
        'Prefeitura (`316,614`) e à Praça do Paladino (`361,601`).',

        '**Céu Ápice: o Palácio da Perdição** — a reta final leva ao Palácio '
        'da Perdição (`602,535`), com a Freira Penitente Aileen. É a instância '
        'que fecha o Ápice.',
    ],
    'nota': '**O Ápice fecha numa instância, o Palácio da Perdição**, depois de '
            'passar pelas tribos e forjas das Estepes do Oeste. Nomes e '
            'coordenadas da PWpedia (batem com o BR ±1). Viu diferente? '
            '[Discord](https://discord.gg/n5v3WdSJyg).',
    'pronto': True,
})

REINOS.append({
    'slug': 'majestoso',
    'nome': 'Majestoso',
    'ceu': 'Céu Majestoso',
    'ingles': 'Rising Sky',
    'ordem': 'o nono dos dez Limites',
    'requisito': 'Nível 100, Despertar II, Céu Ápice X',
    'resumo': 'A nona anedota, da expansão Ascensão Selvagem, numa área nova a '
              'noroeste de Quedanunca — as Planícies do Ocidente e a Floresta '
              'Vidal. É uma trama élfica e de Yggdrasil, com NPCs que te seguem '
              'e alguns quebra-cabeças pelo caminho.',
    'comecar':
        'Com o **Céu Ápice no `10`**, fale com o **Apóstolo do Céu Divino '
        'Yoshin**, em Quedanunca (`564,502`, na Cidade de Nicada), para subir '
        'ao Céu Majestoso. Aviso: muitos mobs daqui dão dano proporcional ao '
        'seu HP — vá com buffs, amuleto e poções.',
    'passos': [
        '**Céu Majestoso: Corpo Original** — com Martelinho, que te segue, vá '
        'a `218,710` e cave "Restaurar a Formação Mágica".',

        '**Céu Majestoso: Quarto Cristal** — com Martelinho te seguindo, vá a '
        '`256,698` e fale com Landar em `257,695`.',

        '**Céu Majestoso: Ir à Floresta** — com a Princesa da Água Elisa te '
        'seguindo, vá a `228,716`, derrote `3` Guerreiros Alados Manipulados e '
        'conclua falando com ela.',

        '**Decifrando os Caracteres** — depois de falar com Vidar, você recebe '
        'o Livro Comparativo da Língua Élfica. Leia-o (botão direito), e a '
        'palavra que os símbolos formam é **YGGDRASIL** — digite em maiúsculas '
        'e envie.',

        '**Suprimentos Temporários** — colete as Frutas Doces nos galhos das '
        'árvores em `219,689` (Floresta Vidal) e, logo depois, os Fungos '
        'Frescos no chão ali ao lado.',

        '**Aberrações: as pegadas** — a missão não aponta NPC nem alvo; em '
        'frente ao NPC que a inicia (`223,685`, Floresta Vidal) há pegadas. '
        'Siga-as até `232,694` para invocar o Rhya e derrote-o sozinho.',

        '**Mar de Egil: pescar** — use a Isca Quedanunca no lago (botão '
        'direito) e aperte Espaço para fisgar `5` Peixes Marinhos Frescos. '
        'Depois, junte o Molho de Mel ao peixe para cozinhar `5` Peixes '
        'Grelhados Apetitosos.',

        '**Interseção do Sol: o Livro de Sangue** — voe até `219,698` e cave o '
        'Livro de Sangue no galho; a senha é **`0413`** para cavar o Diário. '
        'Depois use a Carta do Pai (botão direito).',

        '**O Templo do Céu, e a Tranca** — vá a `222,741` (a altura importa) '
        'para chegar ao Templo do Céu. Lá, resolva o quebra-cabeça de '
        'deslizar: leve a peça de cor diferente até a seta à direita — as '
        'peças horizontais só andam na horizontal, as verticais só na '
        'vertical.',
    ],
    'nota': '**Levantado do guia BR da Trivia (expansão Ascensão Selvagem), '
            'recuperado pela Wayback Machine.** A PWpedia chama este Limite de '
            '*Rising Sky*. Coordenadas do cliente BR. Viu um passo diferente? '
            '[Discord](https://discord.gg/n5v3WdSJyg).',
    'pronto': True,
})

REINOS.append({
    'slug': 'soberano',
    'nome': 'Soberano',
    'ceu': 'Céu Soberano',
    'ingles': 'Sealed Sky',
    'ordem': 'o décimo e último Limite',
    'requisito': 'Nível 102, Despertar II, Céu Majestoso X',
    'resumo': 'A décima e última anedota, da expansão Yggdrasil: um Ragnarök '
              'inteiro, na Segunda Raiz da Árvore do Mundo e em Quedanunca. É '
              'uma de três anedotas ligadas — Soberano, Crônica dos Deuses e '
              'Memória dos Gigantes —, então siga pela janela de missões '
              '(tecla `Q`) para não se perder entre elas.',
    'comecar':
        'Precisa de **Céu Soberano I+ e nível `102`**. A linha abre em **Céu · '
        'Segunda Raiz**: fale com **Althea, Imperatriz da Luz**, na Prefeitura '
        '(`315,611`), e vá ao **Vidar** no Reino Congelado (`271,671`). Para '
        'invocar o Vidar ou o Gatinho Branco mais tarde, há o Deus da Natureza '
        'Vidar em `247,501`, na Trompa da Vitória.',
    'passos': [
        '**Afinidade** — ganhe afinidade com os Gigantes dando-lhes presentes '
        '(cada um vale `+10`, e caem de monstros da Segunda Raiz): Jord '
        '(`213,608`), Mímir (`245,595`), Laufey (`245,566`) e Farbanti '
        '(`246,626`). A afinidade muda o final da história.',

        '**Gigante de Gelo e Geada** — fale com Óbido, o Gigante de Gelo, em '
        '`264,666`.',

        '**Mar do Medo Timoroso** — pelo Vidar, vá a `248,628` e lute com '
        'Farbanti, o Gigante do Mar (`247,625`). Isso libera a anedota Memória '
        'dos Gigantes.',

        '**Corpo Adormecido, e o Pecado da Beleza Selada** — siga o Vidar a '
        '`273,610` e `285,584`; depois lute com a Giganta em `247,566`, de '
        'onde surge Laufey, a Giganta Bruxa, no Jardim de Flores Sinistras '
        '(`246,566`).',

        '**O Poder das Palavras, e o Silêncio da Sabedoria** — pelo Vidar, vá '
        'à Prisão dos Deuses (`215,582`), fale com Rhya (o Gato Preto) e o '
        'Vidar (`213,586`), e lute com a Gigante da Montanha (`216,583`).',

        '**Explorando a Segunda Raiz** — com o Vidar e Mímir em `246,595`, '
        'beba da Fonte da Sabedoria (`242,592`).',

        '**Os deuses de Quedanunca** — a linha volta a Quedanunca: fale com '
        'Frey, o deus da prosperidade (`220,532`), e com Hela, a Deusa do '
        'Submundo (`254,514`).',

        '**O Ragnarök** — pelo Gatinho Branco, encare os deuses: Odin e Fenrir '
        '(`228,486` → `233,488`), Týr e o Cão Garme (`278,496` → `282,492`), '
        'Thor e Jormungand (`209,508` → `213,508`), e o Nidhogg (em '
        'Quedanunca).',

        '**A Trombeta de Gjallarhorn** — feitas as quatro acima, cave a '
        'Trombeta de Gjallarhorn em `249,499` e fale com Vidar. Isso inicia '
        '*Céu: Antes da batalha* — a batalha final do Ragnarök.',
    ],
    'nota': '**Levantado do guia BR da Trivia (expansão Yggdrasil), recuperado '
            'pela Wayback Machine.** As três anedotas — Soberano, Crônica dos '
            'Deuses e Memória dos Gigantes — são ligadas: use a janela de '
            'missões (tecla `Q`) para seguir. Coordenadas do cliente BR. Viu '
            'diferente? [Discord](https://discord.gg/n5v3WdSJyg).',
    'pronto': True,
})


# Arcos extras — anedotas com nome próprio que a PWI não separa, recuperadas
# do guia BR da Trivia pela Wayback Machine. Cada um aponta o Céu a que
# pertence (`ceu`), e é isso que deixa o catálogo ser filtrado pelos dois
# eixos: o Céu Soberano, por exemplo, reúne três arcos do Yggdrasil.
ARCOS_EXTRA = [
    {
        'slug': 'cronica-dos-deuses',
        'nome': 'Crônica dos Deuses',
        'ceu': 'soberano',
        'requisito': 'Corre junto com o Céu Soberano (nível 102+)',
        'resumo': 'O arco gêmeo do Soberano no Yggdrasil: o Ragnarök pelo lado '
                  'dos deuses — Frey e a Abundância, a Arma Eterna refundida, '
                  'Hela, Thor, Tyr e Fenrir. Interligada ao Soberano e à '
                  'Memória dos Gigantes.',
        'comecar':
            'Corre junto com o Céu Soberano. Siga pela janela de missões '
            '(tecla `Q`); para invocar o Gatinho Branco ou o Vidar, há o Deus '
            'da Natureza Vidar em `247,501` (Trompa da Vitória).',
        'passos': [
            '**Céu · Guardião, e a Herança da Vontade** — pelo Gatinho Branco '
            '(`240,700`) e pelo Vidar, em Quedanunca.',

            '**Céu · Arrumar a Culpa** — no Esquilo Ratatosk, em `246,494` '
            '(Trompa da Vitória), seguida de "Galo do Topo da Árvore" e '
            '"Esquilo da Yggdrasil".',

            '**Céu · Deus Frei, e a Abundância I–III** — pelo Gatinho Branco, '
            'as três Abundâncias em `220,795`, `380,520` e `470,630`, até "A '
            'Promessa de Frey", com o deus Frey (`220,532`, no Destino dos '
            'Deuses).',

            '**A Arma Eterna** — "Refundida" (`230,490`) e depois "Forjando a '
            'Arma Eterna" com o Ancião Earl, em `598,674`, na cidade Rodentia.',

            '**O Ragnarök dos deuses** — a reta final encadeia a Senhora da '
            'Morte Hela, o Deus da Morte, a Serpente do Mundo, Thor, o Cão do '
            'Inferno e Tyr, até "A Batalha Começou" e a Queda do Céu Divino.',
        ],
        'nota': '**Arco do Yggdrasil, ligado ao Céu Soberano e à Memória dos '
                'Gigantes.** Levantado do guia BR da Trivia, recuperado pela '
                'Wayback Machine. Coords do cliente BR. Viu diferente? '
                '[Discord](https://discord.gg/n5v3WdSJyg).',
    },
    {
        'slug': 'memoria-dos-gigantes',
        'nome': 'Memória dos Gigantes',
        'ceu': 'soberano',
        'requisito': 'Corre junto com o Céu Soberano (nível 102+)',
        'resumo': 'O terceiro arco do Yggdrasil: a história pelos Gigantes — '
                  'o Ancestral, o do Mar, o da Montanha, o da Sabedoria e a '
                  'Giganta Feiticeira —, com Pedras Místicas, a Lança Eterna e '
                  'a Prisão de Loki. Interligada ao Soberano e à Crônica dos '
                  'Deuses.',
        'comecar':
            'Corre junto com o Céu Soberano. Siga pela janela de missões '
            '(tecla `Q`).',
        'passos': [
            '**Céu · Gigante Ancestral** — pelo Gatinho Branco (`285,584`), '
            'derrote `5` essências espalhadas por Quedanunca. Elas são imunes '
            'a dano comum: pegue a Pedra Mística do elemento certo (a Essência '
            'do Trovão em `280,584` cai com a Pedra Mística do Trovão, do '
            'Dragão Mutante) — a menos que você já cause dano daquele '
            'elemento.',

            '**Os Gigantes** — a linha passa pelos Gigantes do Mar, da '
            'Montanha e da Sabedoria, e pela Giganta Feiticeira, cada um com a '
            'sua missão (Nascimento, Bênção, Os Ossos…).',

            '**Céu: Lança Eterna, e a Prisão de Loki** — a reta final: a '
            'Batalha dos Gigantes, a Lança Eterna, a Prisão de Loki e o Salão '
            'dos Espíritos.',
        ],
        'nota': '**Arco do Yggdrasil, ligado ao Céu Soberano e à Crônica dos '
                'Deuses.** Levantado do guia BR da Trivia, recuperado pela '
                'Wayback Machine. Coords do cliente BR. Viu diferente? '
                '[Discord](https://discord.gg/n5v3WdSJyg).',
    },
    {
        'slug': 'primeiro-contato',
        'nome': 'Primeiro Contato',
        'ceu': 'real',
        'requisito': 'Acesso a Quedanunca (Bilhete de Quedanunca no inventário)',
        'resumo': 'O arco que abre Quedanunca (Neverfall): a viagem de barco do '
                  'Porto dos Sonhos até a cidade, passando por Niore e Wenham, '
                  'até as investigações de Althea. É fácil, mas longo — muita '
                  'gente se perde por não seguir a ordem.',
        'comecar':
            'Com o Bilhete de Quedanunca no inventário, vá ao barco **O Arcano '
            'de Sonhos**, atrás do Capitão Arcano de Sonhos, no Porto dos '
            'Sonhos (`671,357`), e clique nele para embarcar — não funciona sem '
            'o Bilhete. Perdeu o Bilhete? Compre outro por `1.000.000` de '
            'Moedas de Prata no mesmo Capitão. Depois fale com o Guarda do '
            'Porto.',
        'passos': [
            '**Para o oeste** — a linha leva você para o oeste, pelos '
            '"Estranhos Acontecimentos" e pela "História do Império da Luz".',

            '**As Pessoas de Niore, e a Crise em Niore** — a história passa pela '
            'vila de Niore.',

            '**Investigando Wenham** — e "As Pessoas de Wenham", até "Surge a '
            'Verdade".',

            '**Partindo para Quedanunca** — você chega à Magnífica Cidade '
            'Quedanunca, encontra o Executivo e começa "As Investigações de '
            'Althea" — que é o que abre a Guerra do Milênio.',
        ],
        'nota': '**Arco regional ("Área"), jogado ao chegar a Quedanunca.** O '
                'Céu aqui é aproximado: estes arcos não casam 1:1 com um '
                'Limite, marcamos pelo nível em que se jogam. Levantado do guia '
                'BR da Trivia (Wayback). Viu diferente? '
                '[Discord](https://discord.gg/n5v3WdSJyg).',
    },
    {
        'slug': 'guerra-do-milenio',
        'nome': 'Guerra do Milênio',
        'ceu': 'real',
        'requisito': 'Liberada no meio do Primeiro Contato, após "As '
                     'Investigações de Althea"',
        'resumo': 'Continuação do Primeiro Contato: uma viagem no tempo até o '
                  'ano de 1366, a Batalha do Vale das Uvas com a Fada Guardiã '
                  'Heki — até a Ascensão de Alexander.',
        'comecar':
            'A primeira missão, **Atlas do Tempo**, abre quando você conclui '
            '"As Investigações de Althea" do Primeiro Contato. Fale com Althea, '
            'Imperatriz da Luz, em `316,611` (Quedanunca).',
        'passos': [
            '**Atlas do Tempo** — por Althea (`316,611`), fale com o Executivo '
            'Michael (`316,615`) e com a Fada Guardiã Heki (`417,629`), e volte '
            'a Althea.',

            '**Cristais Temporais** — a Heki pede `3` Cristais Temporais na '
            'Montanha Ouronegro (`411,626`); junte-os e entregue a ela.',

            '**A Batalha do Vale das Uvas** — a Heki teleporta você ao ano de '
            '`1366`. Lá, "Atacando nas Sombras" (mate `3` Cavalos de Guerra e '
            '`3` Patrulheiros dos Savagianos, em `422,515`) e "Incendeie o '
            'Acampamento" (os `3` acampamentos dos Sentinelas).',

            '**A guerra, até a Ascensão** — a linha segue pelo Vale das Uvas e '
            'pela cavalaria da Luz, até a Arma de Usher e a Cerimônia de '
            'Ascensão de Alexander.',
        ],
        'nota': '**Arco regional, continuação do Primeiro Contato, em '
                'Quedanunca.** Céu aproximado, como no Primeiro Contato. '
                'Levantado do guia BR da Trivia (Wayback). Viu diferente? '
                '[Discord](https://discord.gg/n5v3WdSJyg).',
    },
]
