# -*- coding: utf-8 -*-
"""The seventeen Hero Sagas, as data.

Three sources were crossed to build this, and the crossing is what the pages
are worth: the Wiki PW and the Trivia PW have a page per class in Portuguese,
and the PWpedia has all sixteen of the PWI ones in English on a single page —
which is the only place that says the experience stops scaling at level 100,
and the only way the class mapping could be checked at all.

Two things that mapping corrected, both recorded on the hub page:
the Arcano's hero is Mu Suiliang, whom the PWpedia publishes as the *Seeker* —
translating the class name would have paired him with the Paladino; and the
Paladino's own saga (Tian Yi) is in neither English source, so both Portuguese
pages for it carry the same test-server disclaimer and it is one source, not
two.

A arte de cada classe **não é um campo**: é `<slug>.webp`, derivado. Era um
campo até 29/10/2026, e nesse dia uma expressão regular que o preenchia
atravessou registos e deu ao Ceifador a arte do Guerreiro — o mesmo facto
escrito em dois sítios, a divergir pela primeira vez que alguém lhe tocou.
`baixar_arte.py` grava um ficheiro por slug e `pagina.py` exige que exista.

`passos` is one entry per mission, in the order the game hands them over.
`**bold**`, `` `code` `` and `[text](url)` are the only marks.
"""

GERAL = [
    {
        'titulo': 'Três coisas que a janela não diz',
        'paragrafos': [
            '**Espere o nível 100.** A experiência de cada missão cresce com o seu '
            'nível e para de crescer no 100. A saga abre no 80 e o mascote é o mesmo, '
            'mas quem faz no 80 troca milhões de experiência por pressa. É o único '
            'conselho aqui que nenhuma das fontes em português dá — está na PWpedia.',

            '**A ordem entre as sagas não importa, e você não precisa ser da classe.** '
            'O retrato do Guerreiro abre para qualquer um. O que amarra é o nível e o '
            'cultivo, não a classe do personagem.',

            '**O mascote é cosmético.** Ele não luta, não some com o tempo e só '
            'aparece depois de entrar no Códice. O que vale em atributo é o título: '
            '+100 de HP, e eles acumulam — dezessete sagas são +1700 de HP.',
        ],
    },
    {
        'titulo': 'Duas linhas que ainda não estão conferidas',
        'paragrafos': [
            '**O Paladino tem uma fonte só.** As duas páginas em português dizem a '
            'mesma coisa e trazem o mesmo aviso — o texto saiu do servidor de testes '
            'da Level Up durante a expansão, e nomes podem ter mudado desde então. A '
            'PWpedia não tem o Paladino. Então trate essa linha como provável, não '
            'como medida.',

            '**O Ceifador diverge entre as fontes.** Em português o ovo é o do '
            '*Tianshou Pequeno* e o título é *Outono do Mundo*; em inglês a PWpedia '
            'registra *Tevin Pet Egg* e *Undefeated*. Não são traduções uma da outra. '
            'Ficamos com a versão em português, que é a do nosso cliente — mas a '
            'divergência fica escrita aqui em vez de escondida.',

            'Se você fez alguma delas e viu diferente, conte no '
            '[Discord](https://discord.gg/n5v3WdSJyg). Uma correção de quem jogou '
            'vale mais do que três sites concordando.',
        ],
    },
]

SAGAS = []

SAGAS.append({
    'slug': 'guerreiro',
    'classe': 'Guerreiro',
    'heroi': 'General Chung',
    'ovo': 'Mini Chung',
    'titulo': 'Época Passada',
    'resumo': 'A vida do General Chung em três tempos: o menino, a unificação e a '
              'guerra. É uma saga de cidade — quase tudo acontece dentro da Cidade '
              'das Espadas, e boa parte dela você joga transformado no próprio Chung, '
              'sem as suas habilidades.',
    'comecar': 'Abra a Saga do Herói, clique no Guerreiro e fale com o **Ancião '
               'Recluso** na Cidade do Dragão Norte, em `572,677`. Ele teleporta você '
               'para `565,677`, onde a criança humana dá a primeira missão.',
    'avisos': [
        '**Você vira o Chung, e perde o seu personagem.** Durante os trechos de '
        'memória não dá para usar itens, habilidades de classe nem gênio — só as três '
        'habilidades da barra do meio, que pode ser arrastada para onde você quiser.',
        '**Não pule as cenas.** Pular não adianta: a missão continua rodando o '
        'cronômetro dela até o fim de qualquer jeito.',
    ],
    'passos': [
        '**Criança Humana** — fale com a criança humana e pegue a missão seguinte.',
        '**Encontrando Chung** — leve a criança até a Cidade das Espadas e fale com o General Chung em `430,887`.',
        '**Herói** — pegue a missão no Velho General Chung e use a ação *agradecer*.',
        '**Sono Profundo** — pegue a missão e use a ação *acenar*.',
        '**Cristal da Memória** — fale com o Velho General outra vez e cave o cristal ao lado.',
        '**Entrando na Memória** — use a ação *recuperação zen* e devolva a missão no Velho General.',
        '**Reversão do tempo** — encontre Loyan e conclua.',
        '**Loyan** — fale com ela de novo.',
        '**Companhia até em casa** — leve Loyan até a casa dela, em `437,889`.',
        '**Vá para o Distrito Sul** — vá até `441,870`, na Cidade das Espadas.',
        '**Encontrando Leecin** — fale com Leecin ali perto e use a ação *dar de ombros*.',
        '**Coragem** — colete a Arma na armaria, em `442,898`, vá para `495,885`, mate o monstro que aparece e fale com Leecin.',
        '**Peixe Assado** — siga para `509,877`, cave o item em `511,877`, cave a fogueira em `508,878`. Você volta para a cidade; pegue a próxima no Espírito do Velho General.',
        '**Esperando por Loyan** — vá até `430,877`, encontre Loyan e entregue.',
        '**Saindo Zangado** — vá para `441,870`.',
        '**Ficar Emburrado** — use a ação *zangado*.',
        '**Afeição Profunda** — Loyan em `430,878`, depois `441,870`, depois Leecin, depois Tian Yao em `447,880`.',
        '**Desafiando Tian Yao** — vença Tian Yao, entregue nele e volte a falar com Loyan.',
        '**A Discussão** — vá para `434,857`, use a ação *triste* e fale com Leecin, que aparece.',
        '**Decepção** — fale com Leecin, leve-a até `469,880`, entregue, cave a caixa ali perto, espere 3 segundos e fale com ela. Depois volte ao Espírito do Velho General.',
        '**Retornando a Realidade** — fale com o Velho General.',
        '**Morte de Loyan** — cave o túmulo de Loyan e espere 10 segundos, três vezes.',
        '**Amolar** — fale com Leecin, que estará perto.',
        '**Retornando a Realidade** — fale com o Velho General.',
        '**Entrando na Memória** — fale com o Pai de Chung.',
        '**Gu Hensin** — vá a `559,885`, fale com Lua da Neve, procure Gu Hensin, siga para `555,901`, esconda-se com ele, espere a missão seguinte, vá a `557,902`, elimine a Fera Alfa e fale com Gu Hensin.',
        '**De volta a Cidade das Espadas** — fale com o Pai de Chung.',
        '**Lio Gianni** — vá a `636,782` e encontre Lio Gianni. Volte ao Pai de Chung, fale com Gu Hensin, siga para `625,804`, fale com o Velho, continue até `624,792`, fale com o NPC, derrote os comerciantes e fale com Lio Gianni.',
        '**Anseio em Comum** — fale com Lio Gianni e espere voltar para a Cidade das Espadas.',
        '**De volta a Cidade das Espadas** — fale com o Pai de Chung.',
        '**Cordilheira dos Mil Rios** — vá a `481,947`, encontre o Asceta Mo, depois `469,945`, `460,936`, `429,941` e `406,952`. Fale com Tsen, o Enviado do Céu.',
        '**Tsen o Enviado do Céu** — vá falar com Fen, o Vitorioso, no topo da montanha. **A primeira subida falha de propósito** — o personagem é telado antes de chegar e uma missão nova aparece para subir outra vez. Na segunda, fale com Tsen e depois com Fen.',
        '**Indo embora da montanha** — pegue a missão com Fen, ali perto.',
        '**Retornando a Realidade** — fale com o Velho General Chung.',
        '**Juramento da Irmandade** — encontre Fen, o Vitorioso, e fale com os NPCs.',
        '**Retornando a Realidade** — fale com o Velho General Chung.',
        '**Resgatando Leecin** — fale com o Batedor, depois com os Generais, vá a `414,552`, fale com Leecin, liberte-a cavando o interruptor, vá a `422,566` e fale com o Campeão Alado.',
        '**Triste** — fale com Fen, cave a cesta de flores, leve as flores à lápide, use a ação *deprimido* e entregue na lápide. Pegue a próxima com Fen.',
        '**Diagrama Voador** — colete Ferro Fino do Veio da Terra, Granito Vulcânico, Energia Eólica e Energia Magnética. Depois vá a `450,879`, cave a fundição imortal de espadas e entregue em Fen.',
        '**Retornando a Realidade** — fale com o Velho General Chung.',
    ],
})

SAGAS.append({
    'slug': 'mago',
    'classe': 'Mago',
    'heroi': 'Tensa',
    'ovo': 'Mini Tensa',
    'titulo': 'Uma História Memorável',
    'resumo': 'A mais longa das sagas antigas, e a que mais faz você andar: Heshin '
              'desaparece, o bibliotecário pede ajuda, e a procura atravessa meio '
              'mapa — Caverna de Fogo, Acampamento de Sumor, Galpão dos Lenhadores e '
              'de volta ao Altar da Espada, várias vezes.',
    'comecar': 'Abra a Saga do Herói, clique no Mago e fale com o **Bibliotecário '
               'Cheng Zigeng** em `531,684(22)`, no Distrito Norte da Cidade do '
               'Dragão. Ele dá a missão *Algo em Mente*.',
    'avisos': [
        '**Guarde duas senhas:** o baú esotérico em `498,956` abre com **6 2 3 6**.',
        '**A Patrulha Alada causa HK.** Na missão *História: Pílula Rejuvenescedora*, '
        'em `197,384(69)`, passar no campo de visão dela mata — desvie.',
        '**O Altar da Espada é o elevador da saga.** Sempre que a missão disser para '
        'voltar, é ir a `428,890` e usar a ação *jogar moeda*.',
    ],
    'passos': [
        '**Algo em Mente** — depois de falar com o bibliotecário, abra a Carta Deixada por Heshin no inventário com o botão direito.',
        '**Desaparecimento de Heshin** — aceite no Cheng Zigeng e use a ação *dar de ombros*.',
        '**Tomo Antigo** — fale com Cheng Zigeng e encontre o Bibliotecário Yua no Pináculo do Despertar, em `158,251(3)`.',
        '**Escama do Dragão Púrp. de Elite** — abra o Livro Antigo no inventário, espere 5 segundos e procure o Arqueologista Jian Zhukong em `138,672(45)`, perto da Cidade de Fei Wei.',
        '**Altar da Espada** — mate o Dragão Púrpura de Elite que voa sobre a Terra dos Dragões em `185,646(60)` para pegar a escama, volte ao Jian Zhukong e depois fale com o Ancião da Cidade das Espadas em `433,887(27)`.',
        '**Falando com o Ancião** — fale com o Ancião e encontre Heshin em `384,562`, dentro da Caverna de Fogo.',
        '**Gruta do Rochedo de Fogo** — pegue o Enxofre do Submundo em `419,542(33)`, volte a Heshin e depois ao Ancião.',
        '**De volta ao Passado** — fale com o Ancião e aceite.',
        '**Altar da Espada** — vá a `428,890(27)` e use a ação *jogar moeda*.',
        '**Falando com a Guia** — fale com a Guia em `421,835(21)` e vá a `432,861(21)`.',
        '**Sussurro de Heshin** — aceite no Heshin, que estará seguindo você, e espere.',
        '**Encontrando Tensa** — depois de falar com Tensa, fale com Heshin e com o Garoto Pastor.',
        '**Falando com Tensa** — fale com Tensa, use a ação *Ataque1*, fale de novo, cave a Água da Fonte em `435,866(21)` perto da cachoeira. **Saia da água** para conseguir falar com Heshin, e depois volte à Guia em `422,835(21)`.',
        '**Entregando os Remédios** — fale com a Guia e vá ao Boticário Peregor Dungar em `425,740`, na Cidade do Vento Alísio.',
        '**A Dor da Guerra** — pegue no Boticário, siga para a Vila do Unicórnio em `436,766` e fale com Heshin.',
        '**Sussurro de Heshin** — fale com Heshin ali perto.',
        '**A Dor na Guerra** — retome e fale com o Soldado Estranho em `439,763`.',
        '**Parando a Chuva** — fale com o Aldeão Ergo em `439,763`, espere 3 segundos e fale com Tensa.',
        '**Fênix do Banho de Sangue** — elimine 10 Fênix Flamejante perto da Vila do Fogo, em `169,790`, e volte ao Aldeão Ergo.',
        '**Depois da Chuva** — fale com Ergo, use a ação *refletir* e fale com Tensa.',
        '**Sussurro de Heshin** — fale com Heshin.',
        '**Procurando por Lorzhan** — fale com Tensa, encontre Lorzhan em `330,824`, no Acampamento de Sumor, veja a cena e fale com o Guarda La Tu em `332,824`.',
        '**Encontrando o Guarda La Tu** — fale com ele, espere 3 segundos, fale com Enhaz e lute contra os Guardas.',
        '**Derrotando os Guardas** — fale com Enhaz.',
        '**Encontre Heshin** — vá a `340,842`, depois `341,852`, depois `327,844`, e fale com Heshin.',
        '**Sutra Essencial** — pegue o Sutra Essencial em `323,844` e fale com ele.',
        '**Derrotando o Guardas** — encontre a Maga Tensa em `331,824`.',
        '**Enviando o Alado** — fale com Tensa duas vezes e vá a `393,467`.',
        '**O Sábio Misterioso** — fale com Enhaz, vá a `410,471`, fale com Enhaz de novo e depois com Tensa.',
        '**Sussurro Heshin** — fale com Heshin.',
        '**Colhendo Ervas** — pegue com Tensa, fale com o Sábio Misterioso no Galpão dos Lenhadores em `497,964`, colha Neve Feérica na Montanha das Árvores em `483,962` e entregue ao Boticário Hitzerin Reut em `498,964`.',
        '**História: Pílula Rejuvenescedora** — fale com o Sábio, vá a `197,384(69)` e encontre Aeon Luminator em `188,370(69)`. Derrote o monstro e volte ao Sábio.',
        '**Uma Nova Arma** — fale com o Sábio, vá a `300,912(12)`, pegue 5 Neve Fria dos Wyvern Mordedor (eles voam), cave 5 Turquesa Cintilante no chão, espere 5 segundos e entregue ao Sábio.',
        '**Sussurro de Heshin** — pegue as duas missões de Heshin.',
        '**Esotérica no Baú** — fale com o Sábio, cave o esoterismo em `498,956`, use a senha **6 2 3 6**, cave o baú e volte ao Sábio.',
        '**Salvando a Garota** — fale com o Boticário, depois com o Observador Noturno em `417,884`. Pule no rio, vá a `417,884(20)`, mate 2 Natrix Barbatana e fale com Saki — ela fica escondida num tronco no fundo do rio, com uma passagem em `405,884(20)`. **Volte à terra firme** para encontrá-la outra vez.',
        '**Garota Extraordinária** — leve Saki de volta à Vila do Nada em `656,598` e encontre o Aldeão Panhai no Monte Perfumado, em `670,613`.',
        '**Para o Santuário** — encontre o Sábio Misterioso em `622,528`.',
        '**Ir para Casa** — pegue Enxofre do Submundo na Caverna de Fogo em `421,543` e volte ao Sábio em `622,528`.',
        '**Sussurro de Heshin** — fale com Heshin.',
        '**Altar da Espada** — vá a `428,890`, use *jogar moeda* e fale com o Ancião da Cidade das Espadas.',
        '**Carta de Heshin** — abra a Carta de Heshin no inventário, vá a `623,527`, cave a Carta do Sábio em `622,528`, use-a e espere 30 segundos.',
        '**Conte a Cheng** — fale com o Bibliotecário Cheng em `531,684`.',
        '**Encontrando Heshin** — fale com o Cheng outra vez.',
        '**Extraia Enxofre do Submundo** — volte à Caverna de Fogo pelo enxofre, vá ao Altar em `384,563` e use *jogar moeda*. Encontre Heshin em `532,686` — **depois de falar com ele você é atacado e toma HK**; volte à cidade e confirme o popup. Fale com o Cheng em `531,684(22)`, volte à Caverna por 3 enxofres e use o Altar outra vez.',
        '**Encontrar Heshin** — fale com Heshin em `528,686`.',
        '**Samsara** — fale com Heshin em `528,687(22)`, depois com o Cheng em `531,684(22)` e encontre o Bibliotecário Yua em `158,251(13)`.',
        '**Memória do Tomo** — leia a Carta de Heshin, espere a cena e mais 4 segundos. Volte ao Altar da Espada e use *jogar moeda*.',
    ],
})

SAGAS.append({
    'slug': 'feiticeira',
    'classe': 'Feiticeira',
    'heroi': 'Yeona',
    'ovo': 'Mini Yeona',
    'titulo': 'Um Grão no Universo',
    'resumo': 'A mais curta das sagas antigas e a única que é, de ponta a ponta, '
              'sobre domar. Yeona ensina a capturar, o Gigante Celestial Hércules '
              'aparece três vezes, e no fim você dá nome a ele.',
    'comecar': 'Abra a Saga do Herói, clique na Feiticeira e pegue a missão *Um '
               'Pedido* com **Krast Nerion**, em `249,652(26)`, na Cidade das Feras.',
    'avisos': [
        '**Tire o equipamento antes de capturar as lebres.** Com o equipamento posto '
        'você mata a lebre em vez de pegá-la. O buff da Yeona é que causa o dano — '
        'use a jaula quando o HP da lebre estiver abaixo de 50%.',
        '**O buff da Yeona expira.** Se acabar antes de você pegar as cinco, volte '
        'nela e renove.',
    ],
    'passos': [
        '**Um Pedido** — pegue com Krast Nerion em `249,652(26)`, na Cidade das Feras.',
        '**Aceitar o Pedido** — fale com Krast Nerion e encontre Yeona na Vila Langour, em `668,636(21)`.',
        '**Resolvendo a Crise** — fale com Yeona e depois com Susanna.',
        '**Cortando a Grama** — cave 5 Feno perto de `675,633(21)` e entregue a Yeona.',
        '**Conhecendo Hércules** — fale com Yeona e feche o diálogo.',
        '**Aprendendo a Domar** — capture 5 lebres com a jaula do inventário e entregue a Yeona em `669,636(21)`. Tire o equipamento primeiro.',
        '**Retorne a Cidade das Feras** — entregue no Escorpião com Varizes Cookie, em `250,651(25)`.',
        '**Ventos da Verdade** — pegue com Yeona e fale com o Alquimista.',
        '**Coragem** — pegue no Alquimista e encontre a Vovó Nanda Morris na Cidade do Dragão Sul, em `586,620(22)`.',
        '**Além do Esperado** — fale com a Vovó e espere 10 segundos, depois mais alguns.',
        '**Começar a Aprimorar** — pegue na Vovó, continue com Yeona e volte à Vovó.',
        '**O Coração da Direção** — pegue na Vovó, vá à Vila do Nada em `668,637` e fale com Yeona.',
        '**Encontrando o Hércules de Novo** — fale com o Gigante Celestial Hércules e use a ação *acenar*.',
        '**Evento Inesperado** — depois da cena, pegue a missão no Biscoitinho e vá à Vovó Nanda Morris.',
        '**Proibição de Gênesis** — fale com a Vovó e encontre o Demônio Imortal Jeffrey em `467,548`, no Grande Lago.',
        '**A Longa Conversa** — fale com Jeffrey e vá a `452,568`.',
        '**Encontrando Susanna** — fale com Susanna, colete 5 Erva Euforia perto de `433,557` e entregue ao Dodo em `452,568`.',
        '**Estereótipo** — fale com Levado e volte ao Demônio Imortal Jeffrey em `467,548`.',
        '**Destino** — pegue com Jeffrey, fale com Yeona depois do teleporte, mate 10 Sombrio Antílope ou Ave Elísio e encontre o Escorpião em `472,518`.',
        '**A Coleira** — fale com o Gigante Celestial Hércules e encontre o Sombrio: Gigante Celestial em `477,510`.',
        '**O Plano** — fale com o Sombrio, cave o Fragmento de Recipiente em `467,510`, fale com ele outra vez, mate o Sombrio: Caniçal em `474,507` e pegue a missão no círculo azul em `474,505`.',
        '**Caminho de Volta** — depois de pegar no portal, fale com o Escorpião.',
        '**Os Velhos Tempos** — fale com a Vovó Nanda Morris, vá a `669,636`, fale com Yeona e depois com Levado.',
        '**Yeona: o Diário** — fale com ela duas vezes e, depois das lembranças, fale com o Gigante.',
        '**Sob a Muralha Ancestral** — vá a `275,836`, fale com Yeona e pegue a próxima com o Gigante.',
        '**Acompanhar** — vá até a Vovó Nanda Morris, na Cidade do Dragão.',
        '**Um Novo Começo** — fale com a Vovó e dê nome ao Gigante: escreva **Hércules (Yeona)**.',
    ],
})

SAGAS.append({
    'slug': 'atiradora',
    'classe': 'Atiradora',
    'heroi': 'Atiya, a Sorridente',
    'ovo': 'Mini Atiya',
    'titulo': 'Tempo Aproveitado',
    'resumo': 'Começa com um cervo e três bilhetes, e é a saga com mais minijogo de '
              'todas: pedra-papel-tesoura, um canhão com balões, uma fada com limite '
              'de dano e duas senhas de baú. Tem também a única escolha da saga que '
              'rende um título extra.',
    'comecar': 'Abra a Saga do Herói, clique na Atiradora e inicie *Encontre um '
               'Filhote de Cervo*. Vá até `442,795(21)`, espere a conclusão e fale '
               'com o **Cauda Branca**, que passa a seguir você.',
    'avisos': [
        '**O canhão some em 1 minuto.** Na missão *Canhão Poderoso* ele demora a '
        'aparecer e desaparece depressa. Se perder a janela, aborte a missão e fale '
        'com Atiya outra vez.',
        '**A Fada Floral Clone tem teto de dano:** 10.000 por golpe, e três minutos '
        'de prazo.',
        '**As senhas:** a Pederneira Inextinguível abre com **1 4 2 3**.',
        '**Na *Flor de Pessegueiro* você escolhe, e os dois caminhos dão título.** '
        '*Eu mesmo pego* leva você a cavar o Ramo em `650,562(24)` e dá o título '
        '*Flores para Vinho*; *Eu tenho muito dinheiro* custa 20.000 Moedas de Prata '
        'e dá *É Apenas Dinheiro*. Nenhum dos dois dá atributo.',
    ],
    'passos': [
        '**Segredo 1** — abra a Nota Lambida por Cervo, cave o baú em `333,679(21)` e aceite a próxima com o Cauda Branca.',
        '**Segredo 2** — abra a Nota com Odor de Orquídea Suja, vá a `551,376`, confirme o popup e siga para `547,377(22)`.',
        '**Uma Promessa** — fale com o Pé Pequeno em `549,374(22)` e vença numa melhor de 3. Depois fale com ele, cave o Baú Misterioso em `553,371(22)` e abra a Noz de Embrulho de Papel.',
        '**Segredo 3** — aceite com o Cauda Branca, cave o Baú Misterioso em `442,904(26)` na Cidade das Espadas, abra o Papel Seco e pegue a próxima com ele.',
        '**A Bela do Lago** — siga para `492,890`. **Você entra em modo escolta**: não dá para voar, correr, teleportar nem montar. Chegando, fale com o Dizzy.',
        '**Sem Nenhuma Palavra** — procure Atiya, a Sorridente, do outro lado do rio, em `500,904(21)`.',
        '**1 Episódio** — fale com Atiya de novo.',
        '**Fogo Infernal** — continue falando com Atiya até ela pedir para esperar 10 segundos.',
        '**Canhão Poderoso** — vá a `503,906(21)`, espere, suba na Bateria Simples e acerte cinco balões. Depois desça e fale com Atiya.',
        '**As Palavras do Ancião** — fale com o Ancião da Cidade das Espadas, em `433,887(27)`.',
        '**Perguntando a um Alcoólatra** — fale com Alaor Haaden em `443,891(26)`.',
        '**Remédio para Ressaca** — fale com o Boticário Trevor Emirad em `444,897(26)` e volte ao Alaor.',
        '**Flor de Pessegueiro** — na Cidade de Arcádia, fale com o Comerciante Lash Abigor em `649,564(21)` e escolha. Depois vá a `585,566(23)`, na Vila das Orquídeas, use a ação *olhar em volta* e fale com Seraos Distan em `586,566(23)`.',
        '**Rio do Céu** — vá a `565,530(21)` e espere o popup.',
        '**Fada Floral** — fale com a Fada em `564,530(21)`, use a ação *dançar*, fale de novo e derrote a Fada Floral Clone em menos de 3 minutos.',
        '**Descobertas Inesperadas** — fale com Fon Sen em `562,530(21)`.',
        '**Pedra Flamejante** — encontre o Chefe da Vila do Fogo em `133,756(22)`, fale com o Matemático Resmungão em `133,754(21)` e cave a Pederneira Inextinguível usando a senha **1 4 2 3**.',
        '**Cabine do Caçador** — vá a `460,839(21)`, espere o popup e fale com Atiya no mesmo lugar.',
        '**Caixa da Memória** — fale com Fon Sen e espere a próxima missão.',
        '**Distração** — cave o Seixo de Beira de Estrada em `416,624(11)`, clique nele para mirar e aperte **Espaço** para atirar.',
        '**Infiltração** — vá a `417,627(11)`, abra o Baú de Madeira atacando-o, no segundo andar do Palácio, e vista o Traje Dificilmente Utilizável.',
        '**Sendo Pego** — vá a `417,626(11)` e fale com Rancia.',
        '**A Beleza** — fale com Lorsien e depois com Baniel, em `414,623(11)`.',
        '**Insatisfeito** — depois da cena, fale com Atiya em `460,839(21)`, no Subúrbio da Cidade das Espadas.',
        '**Velhos Dias** — encontre Atiya no Palácio, em `417,628(11)`, depois em `411,623(11)`, depois em `418,622(11)`, e confirme o popup.',
        '**Tesouro** — fale com Atiya em `460,839(21)`.',
        '**Bebendo Alegremente** — fale com Fon Sen, com Atiya, com o Ferreiro Yfrien Leider e use a ação *fraco*.',
        '**O Passado e o Presente** — vá a `442,903(26)`.',
        '**Posição Merecida** — fale com a Mestre Atiradora Atiya em `442,903(26)`.',
    ],
})

SAGAS.append({
    'slug': 'barbaro',
    'classe': 'Bárbaro',
    'heroi': 'Viensa',
    'ovo': 'Mini Viensa',
    'titulo': 'Façanhas de Um Herói',
    'resumo': 'Começa com um item no inventário e termina numa transferência de alma. '
              'É uma saga de estrada — Vila da Nascente, Passagem Lunar, Vale do '
              'Sopro do Dragão, Porto dos Sonhos — e dá um título extra pelo caminho.',
    'comecar': 'Abra a Saga do Herói e clique no Bárbaro. Você recebe o **Guardião de '
               'Estame** no inventário; clique nele para ser transportado.',
    'avisos': [
        '**O Banquete de Peixe envenena.** Clicar nele dá o título *Sentimental* e '
        'deixa o personagem com veneno por alguns segundos — com pouco HP dá para '
        'morrer ali.',
        '**O baú das Docas abre com 40000.**',
        '**No Vale do Sopro do Dragão a missão seguinte não aparece sozinha.** Depois '
        'de cavar os três Pesares é preciso **clicar nos itens no inventário** para '
        'destravar.',
    ],
    'passos': [
        '**Suspiro da Memória** — clique no Guardião de Estame no inventário e espere a história.',
        '**Gourmet** — vá até `545,627` e fale com o Homem Misterioso.',
        '**Nas Docas** — fale com o Homem Misterioso, vá a `426,647` na Vila da Nascente, fale com o Comerciante Remids Plovern, cave o baú com a senha **40000** e entregue nele.',
        '**No Pátio** — encontre Viensa em `440,650` e fale com ele.',
        '**Longe da Cidade Natal** — espere alguns segundos, fale com Viensa, clique no Tempero Especial e depois no macarrão Dandan. Fale com o Homem Misterioso.',
        '**Soltando a Música** — fale com o Homem Misterioso, elimine o Peão de Chang San e fale com Viensa.',
        '**Destinado a Serem Amigos** — fale com Viensa duas vezes, vá a `398,691` e fale com ele outra vez.',
        '**Na Chuva** — fale com Viensa, siga para `412,689`, fale com o Soldado Ginta, pegue 5 Zanro no rio e **saia da água** para falar com Viensa. Espere e fale de novo.',
        '**Viensa cobiça a Alma** — vá a `412,689` e fale com Viensa.',
        '**A Jornada de Volta** — vá a `386,677`, fale com a Mãe Aflita em `384,676`, colete 2 Néctar, 2 Agerato e 2 Eufórbio ali perto, entregue e continue o diálogo.',
        '**Tumbas Abandonadas** — fale com Viensa, vá a `369,672`, fale com ele, espere, fale outra vez e use a ação *agradecer*.',
        '**Restos Mortais de um Herói** — pegue com Viensa, cave o Esqueleto Decadente perto do túmulo e fale com ele.',
        '**Sinal com Emoção** — pegue com Viensa, vá a `330,670`, entregue e clique no Esqueleto Decadente no inventário.',
        '**Passagem Lunar** — fale com Viensa e vá a `320,647`.',
        '**Impedido Pela Ponte** — fale com Viensa, vá a `312,652` e fale com o Guarda Sark.',
        '**Outono do Rio** — encontre o General Viensa em `307,662`.',
        '**Á Meia Noite** — fale com o General e depois com o Tenente Kuray.',
        '**Matando Monstros** — pegue com Kuray, fale com o soldado Kandon, mate 20 aparições ali perto e volte ao Kuray.',
        '**Parente do General** — pegue com Kuray e fale com o General Viensa.',
        '**Passado Extraordinário** — fale com o General e espere a próxima.',
        '**Vale do Sopro do Dragão** — fale com Viensa, vá a `279,638`, pegue a próxima com ele e cave os três Pesares: *Juventude Viajante* ali perto, *Corações Unidos* em `285,630` e *Desejos Gêmeos* em `294,634`. Depois clique nos três no inventário.',
        '**A Alegria do Casamento** — pegue com Viensa, espere e fale com ele de novo.',
        '**Sonho Sobre o Passado** — fale com Viensa, vá a `253,633` e fale com ele.',
        '**Chegando a Cidade** — fale com o Guarda Delgor em `252,634`.',
        '**Perdendo o Controle** — fale com Viensa, vá a `248,645` e fale com ele.',
        '**Sonho à Distância** — fale com o Homem Misterioso Redmoon.',
        '**Aroma Ilusório** — vá a `369,673`, fale com o Homem Misterioso, cave o esqueleto decadente ali perto e entregue nele.',
        '**Voltando Para Casa** — fale com o Homem Misterioso e depois com Viensa.',
        '**Pedra no Vazio** — fale com Viensa, vá a `330,670`, clique no esqueleto decadente no inventário e fale com ele.',
        '**A Busca** — vá a `664,369` e encontre o Homem Misterioso em `655,370`, no Porto dos Sonhos.',
        '**Jovem Mulher** — pegue com ele, mate 50 monstros na Ilha Uivante (entra pelo portal do barco, no Porto dos Sonhos) e volte a `655,370`.',
        '**Transferência de Alma** — pegue com o Homem Misterioso, espere e fale com ele outra vez.',
        '**Amor Eterno** — fale com Qin Yu nos arredores da Nascente Fraca e, depois dos diálogos, use a Transferência de Alma no inventário.',
    ],
})

SAGAS.append({
    'slug': 'sacerdote',
    'classe': 'Sacerdote',
    'heroi': 'Yuusa',
    'ovo': 'Ovo de Jadezinho Sonoro',
    'titulo': 'Destinado à Lua',
    'resumo': 'A saga alada, e a única com três provas cronometradas seguidas — voo, '
              'sensibilidade e tambor. Nenhuma é difícil, mas todas falham se você '
              'parar no meio, e as três se refazem sem custo.',
    'comecar': 'Abra a Saga do Herói, clique no Sacerdote e fale com **Mu Yunze** em '
               '`322,434`. Depois fale com o Soldado da Fronteira em `329,444`.',
    'avisos': [
        '**As três provas do Nitinen têm relógio:** capacidade **5 minutos**, '
        'sensibilidade **10**, tambor **3**. Falhar não custa nada — cancele e pegue '
        'de novo com ele.',
        '**Na prova de sensibilidade, as esferas azuis tiram o buff.** Você precisa '
        'juntar 10 camadas passando pelas **vermelhas**; encostar numa azul dissipa o '
        'que já tinha.',
    ],
    'passos': [
        '**Saga Sonho de Dia** — fale com Mu Yunze em `322,434` e depois com o Soldado da Fronteira em `329,444`.',
        '**Procurando a Cura** — fale com o Soldado outra vez e vá a `307,435`.',
        '**Jade – Uma Viagem ao Norte** — fale com o barco e espere chegar.',
        '**Tambor de Jade – Esperando** — pegue a missão na Flor de Mil Pétalas, ali perto.',
        '**Yuusa – Preparada para tudo** — vá ao portal em `412,593` e cave.',
        '**Jade – Compaixão Médica** — fale com o Homem de Preto, ali perto.',
        '**Jade – Uma sensação Perigosa** — fale com ele de novo e vá a `412,589`.',
        '**O Tambor de Jade chegou!** — cave a Flor de Mil Pétalas.',
        '**Eco – Retornar a Cidade** — fale com Ewlen, ali perto.',
        '**Eco – Uma Mentira Bondosa** — fale com Ewlen, vá a `321,446`, cave a terra e encontre o Sacerdote Mu Feng em `322,434`.',
        '**Jade – Amor Profundo** — fale com Mu Feng e vá a `312,428`.',
        '**Eco de Jade – Reencontrando** — fale com Mu Xingchen, ali perto.',
        '**Relato da Batalha** — fale com o Soldado Mensageiro e relate ao Sacerdote Mu Feng.',
        '**Retorno à Origem – Jade** — fale com Mu Yunze e vá a `318,442`.',
        '**O Canto de Yuusaa** — fale com a florzinha murcha, cave ali perto e fale com Mu Yunze.',
        '**Voo de exercício** — fale com Mu Yunze e espere alguns segundos.',
        '**Relátório da Batalha de Jade** — fale com o Soldado Mensageiro duas vezes.',
        '**Jade – Atrás do Inimigo** — fale com Mu Yunze.',
        '**Yuusaa era Você** — fale com Xingchen, ali perto.',
        '**Sopro – A Cidade das Plumas** — fale com Ewlen e vá a `299,398`.',
        '**Voz do Jade – Reorganizando** — fale com o Ancião da Cidade Yi Yulan e encontre Nitinen em `297,395`.',
        '**Teste de Voo** — fale com Nitinen.',
        '**Saga – Teste de Capacidade** — fale com Nitinen. São **5 minutos**: cave as bandeiras nos pontos que a missão indica e volte a ele.',
        '**Saga – Teste de Sensibilidade** — fale com Nitinen e vá a `297,385`. São **10 minutos**: junte 10 camadas de buff nas esferas vermelhas, desviando das azuis, e volte a ele.',
        '**Teste do Tambor de Jade** — fale com Nitinen. São **3 minutos**: vá a `311,387`, elimine 5 Homens de Madeira e volte.',
        '**Chegando a Linha de Frente** — fale com Mu Yunze e encontre Nitinen no campo de batalha.',
        '**Saga da Yuusaa – Briga** — fale com Mu Xingchen e vá a `381,768`.',
        '**Saga – Reconciliação** — espere 30 segundos e fale com Mu Yunze.',
        '**Procura do Yuusa** — fale com Mu Yunze, vá ao acampamento humano em `352,805`, depois `346,804` e `338,809`.',
        '**Saga de Yuusa – O Fim da Vida** — encontre Mu Yunze em `343,819` e fale com ela.',
        '**Saga – Yuusa em Batalha** — fale com Mu Yunze.',
        '**Jade Echo – O Último Presente** — fale com Mu Yunze, depois com Nitinen, e espere a história acabar.',
        '**Voz do Jade – Florescer o Mar** — fale com Ewlen e vá a `318,442`.',
        '**Jade Chorus : Colheita** — fale com Mu Yunze e cave uma Flor de Mil Pétalas.',
        '**Troca de Cristal de Jade** — fale com Mu Yunze outra vez.',
    ],
    'nota': '**Esta é das que o wikipw marca como vindas do servidor de testes.** Os '
            'nomes batem com a PWpedia, que registra a mesma Cleric Yuusa e o mesmo '
            'título — *Lunar Destined* — então a recompensa está confirmada por duas '
            'fontes. Os detalhes de coordenada é que podem ter mudado no caminho.',
})

SAGAS.append({
    'slug': 'arqueiro',
    'classe': 'Arqueiro',
    'heroi': 'Yi Yunyang',
    'ovo': 'Ovo de mini Yunyang',
    'titulo': 'Sopra o Vento da Paz',
    'resumo': 'A saga de guerra dos alados, contada mil anos atrás. É quase toda '
              'conversa — fala com Yi Yunyang, com Renfeng, com o Gênio da Árvore — '
              'e por isso corre depressa para o tamanho que tem.',
    'comecar': 'Abra a Saga do Herói e clique no Arqueiro. Fale com o **Cupido** na '
               'Cidade dos Dragões Oeste.',
    'avisos': [
        '**Se você sair do mapa do passado, a volta é pela Anciã da Cidade das '
        'Plumas.** É o único jeito de reentrar, e nada na tela diz isso.',
        '**No Gênio da Árvore, responda a segunda opção.** A primeira não avança.',
    ],
    'passos': [
        '**Saga: Pedido do Deus** — fale com o Cupido, na Cidade dos Dragões Oeste.',
        '**Saga: A busca pela Árvore** — vá a `652,572`, na Cidade de Arcádia.',
        '**Saga: Consultar a Árvore** — fale com a Árvore do Carma.',
        '**Saga: Fale com o Gênio da Árvore** — fale com ele e escolha a **segunda opção**.',
        '**Saga: Mil anos atrás** — pegue e espere o teleporte. Fale com o NPC e siga até `231,353`.',
        '**Saga de Yi Yunyang: Guerra** — fale com o Tesourinho.',
        '**Saga: Recrutamento** — fale com o Soldado conscrito.',
        '**Saga de Yi Yunyang: Soberano** — fale com Yi Yunyang.',
        '**Saga de Yi Yunyang: Luta** — fale com Yi Yunyang.',
        '**Saga de Yi Yunyang: Decisão** — fale com ele outra vez e vá a `259,404`.',
        '**Saga de Yi Yunyang: Socorro** — fale com a Violeta e mate o Osso do Imperador Irado.',
        '**Saga de Yi Yunyang: Resgate** — fale com o Gênio da Árvore, vá até Yi Yunyang em `284,410` e fale com ele.',
        '**Saga de Yi Yunyang: Guerra** — fale com Yi Yunlan.',
        '**Saga: Árvore do Carma** — fale com Violeta e vá a `652,572`, na Cidade de Arcádia.',
        '**Saga de Yi Yunyang: Oração** — fale com a Árvore do Carma e vá a `648,566`.',
        '**Saga de Yi Yunyang: Juramento** — fale com o Gênio da Árvore e espere alguns segundos.',
        '**Saga de Yi Yunyang: Sozinho** — fale com o Gênio da Árvore e depois com Violeta, perto da Árvore do Carma.',
        '**Saga de Yi Yunyang: Presente** — fale com o Gênio da Árvore.',
        '**Saga de Yi Yunyang: Sono** — fale com o Gênio da Árvore.',
        '**Saga: Outra Metade** — fale com a Anciã da Cidade das Plumas.',
        '**Saga de Yi Yunyang: Destino** — fale com a Anciã outra vez.',
        '**Saga de Yi Yunyang: Perda** — fale com Yi Yunlan.',
        '**Saga: Terra Natal** — fale com Yi Yunlan, pegue um punhado de terra em `208,421` e fale com Violeta.',
        '**Saga: Reencontro** — encontre Renfeng ali perto e espere alguns segundos.',
        '**Saga: Amor Platônico** — fale com Renfeng.',
        '**Buscando vestígios** — vá a `326,411`, depois `343,409`, e encontre Renfeng em `330,429(28)` — **em cima da árvore**.',
        '**Saga: Descoberta** — fale com Yi Yunyang.',
        '**Saga: Sacrificio** — fale com Yi Yunyang e espere alguns segundos.',
        '**Saga: General Renfeng** — fale com a General Renfeng.',
        '**Saga de Yi Yunyang: Sussurro** — vá a `372,815` e fale com a General Renfeng.',
        '**Saga: General Renfeng** — fale com a General Renfeng e depois com o soldado mensageiro.',
        '**Saga de Yi Yunyang: Crise** — depois do mensageiro, fale com a Tropa de Yi Nanzhen.',
        '**Saga de Yi Yunyang: Aliança** — fale com Yi Yunyang.',
        '**Saga: Fora do Plano** — fale com a General Renfeng.',
        '**Saga de Yi Yunyang: Combate** — fale com o soldado mensageiro.',
        '**Saga de Yi Yunyang: Nunca mais** — fale com Renfeng e vá até Zichun.',
        '**Saga de Yi Yunyang: Comando** — fale com Yi Yunyang, espere, e fale com Renfeng.',
        '**Saga de Yi Yunyang: Reforços** — fale com o soldado mensageiro e depois com Mu Zhanshan.',
        '**Saga de Yi Yunyang: Fim** — fale com a Anciã da Cidade das Plumas.',
        '**Saga de Yi Yunyang: Homenagem** — fale com a Anciã, vá a `339,425` e use a ação *recuperação zen*.',
        '**Saga de Yi Yunyang: Saudade** — fale com Renfeng, ali perto.',
    ],
})

SAGAS.append({
    'slug': 'andarilho',
    'classe': 'Andarilho',
    'heroi': 'Syvos',
    'ovo': 'Ovo de Syvos Pequeno',
    'titulo': 'Flor de Pessegueiro Primaveril',
    'resumo': 'A primeira que o servidor recebeu, e a mais curta de todas: vinte e '
              'cinco missões, quase todas de conversa, contando a infância de Syvos '
              'numa vila. Termina numa escolha que não muda a recompensa.',
    'comecar': 'Esta ativa sozinha ao chegar ao **nível 80 com cultivo Mahayana**: '
               'você recebe uma **Carta Emergente** no inventário e abre quando '
               'quiser. O primeiro aviso manda falar com o **Ancião da Cidade '
               'Perdida**, na Cidade das Feras, em `247,646(26)`.',
    'avisos': [
        '**É a única que entrega o título por um item, e não pelo baú.** A **Flor de '
        'Pessegueiro Primaveril** vem junto com o ovo e desbloqueia o título no '
        'momento em que você a obtém.',
        '**Se você abortar *A pequena vila* antes de confirmar o popup**, volte a '
        '`643,565(21)` para se transformar no jovem Syvos outra vez.',
    ],
    'passos': [
        '**O Pedido** — encontre o Ancião da Cidade Perdida, na Cidade das Feras, em `247,646(26)`.',
        '**O Médico** — fale com o Doutor Zivien em `239,654(28)`.',
        '**A Erva** — vá ao Vale dos Dragões em `246,624(25)`, cave o Incenso de Bychi e volte ao Doutor Zivien.',
        '**A Receita** — de frente para o Syvos Inconsciente em `246,624(25)`, aperte **E** e use a ação *recuperação zen*. Fale com o Doutor e espere a erva queimar.',
        '**A pequena vila** — você é teleportado para `643,565(21)`, na Cidade de Arcádia, e vira o jovem Syvos.',
        '**O Bolo de Doces** — vá a `641,564(21)` e cave o Bolo de Doces.',
        '**A Adoção** — fale com Lyo Zosi em `643,566(21)`.',
        '**O Melhor Amigo** — fale com Chang Dong em `643,562(21)`.',
        '**O Professor** — fale com Pu Sonpo em `635,566(21)`.',
        '**A Namoradinha de Infância** — fale com Pu Yilin em `637,564(21)`.',
        '**A Busca** — vá a `636,565(21)`, cave a Caixa de Presilhas e a Lancheira Adorável, e abra a lancheira.',
        '**A Floresta de Bambu** — você vai para `646,555(22)` como Andarilho. Fale com o Coelho Ferido e depois com Pu Yilin em `636,572(22)`.',
        '**Conforto** — fale com Pu Yilin outra vez. Depois da história você vira Andarilho e tem poucos segundos para derrotar três monstros.',
        '**O Professor** — fale com o Ancião Gwan, leve-o até `581,563(22)` e pergunte quem ele é. Depois você vai para a vila dos pescadores, encontrar Chan Yen em `645,845(21)`.',
        '**O Cavalo de Ferro** — fale com Chan Yen, vá a `642,847(21)` conhecer a casa e volte a `644,847(21)` para outra conversa.',
        '**Toca dos Lobos Raivosos** — na Cordilheira da Seda, fale com o Ancião Gwan em `373,620(30)`, entre na Toca e derrote 15 monstros. Você sai da DG e conclui falando com ele.',
        '**A Determinação** — volte ao Ancião da Cidade Perdida, na Cidade das Feras.',
        '**O Antigo Refúgio** — conclui sozinha; confirme o popup.',
        '**Os Vizinhos** — vá a `651,563(21)`, na Cidade de Arcádia, e ouça a Fofoqueira.',
        '**A Carta** — vá a `633,565(21)`, cave a Carta no chão e **espere 50 segundos**.',
        '**A Mudança** — você vai para `621,570(24)`; fale com Pu Yilin.',
        '**O Sonho** — fale com o Doutor Zivien em `239,654(28)`.',
        '**A Visita** — fale com Syvos, que agora despertou.',
        '**O Reconhecimento** — fale com o Ancião da Cidade das Feras.',
        '**A Escolha** — fale com o Ancião e escolha: *contar a verdade para Syvos* ou *deixar que viva com uma mentira*. **A recompensa é a mesma nas duas.** Depois fale com Syvos e feche com o Ancião, que entrega as Cartas Não Enviadas.',
    ],
})

SAGAS.append({
    'slug': 'mercenario',
    'classe': 'Mercenário',
    'heroi': 'Dongfang Lie',
    'ovo': 'Ovo de Pequeno Dongfang Lie',
    'titulo': 'Dança da Lua e Maré',
    'resumo': 'A guerra dos abissais contra os yakshas, contada por seis páginas de '
              'desenho que você usa como portas para o passado. Toda a saga gira em '
              'volta do Rei Dong Fanghuan, no Templo das Nuvens.',
    'comecar': 'Abra a Saga do Herói, clique no Mercenário e vá a `657,144(25)`, na '
               'Cidade das Tormentas, falar com o **Ancião das Tormentas**.',
    'avisos': [
        '**As Páginas de desenho são o elevador da saga.** Sempre que travar, volte '
        'ao Rei Dong Fanghuan em `663,134(41)` e use a próxima no inventário.',
        '**Em *Concessão* não dá para voar até `686,214(22)`.** É preciso entrar pela '
        'boca da caverna em `689,225(22)`: passando por ela, o Guarda Lu Wuqiong fica '
        'à esquerda e a passagem que serve fica à direita.',
        '**Os Vanguarda Yaksha têm teto de 12.000 de dano por golpe.**',
    ],
    'passos': [
        '**Dongfang Lie: Convocação** — fale com o Ancião das Tormentas em `657,144(25)`.',
        '**Dongfang Lie: Investigação** — fale com o Ancião e vá a `578,120(29)`.',
        '**Dongfang Lie: Reforço** — cave os quatro Selos da Maré Sombria: *Vento* em `578,120(31)`, *Água* em `569,116(31)`, *Fogo* em `578,111(31)` e *Céu* em `575,116(30)`.',
        '**Dongfang Lie: Som repentino** — vá a `579,101(22)`, receba o Sinalizador e clique nele com o botão direito.',
        '**Dongfang Lie: Guerra** — vá a `578,103(22)`, derrote 10 Vanguarda Yaksha e fale com o General Lu Guihai em `579,102(22)`.',
        '**Dongfang Lie: Dispositivo** — pegue no General Lu Guihai, cave o Dispositivo exótico em `584,94(19)` e entregue ao Ancião das Tormentas em `657,144(25)`.',
        '**Dongfang Lie: Rei dos Abissai** — fale com o Ancião, entre no portal giratório em `656,147(25)` e procure o Rei Dong Fanghuan em `663,134(41)`, no Templo das Nuvens.',
        '**Dongfang Lie: Álbum** — fale com o Rei, cave o Álbum de desenhos antigo em `663,135(41)`, fale com ele outra vez e use a **Página de desenho I**.',
        '**Dongfang Lie: vento na Ilha** — fale com Dongfang Lie em `656,145(25)`.',
        '**Dongfang Lie: Infância** — fale com Xiyue em `656,146(25)` e depois com Donfang Huan, que segue você.',
        '**Dongfang Lie: Crescer** — conclui sozinha depois da cena.',
        '**Dongfang Lie: Primeira missão** — fale com o Rei em `663,134(41)` e use a **Página de desenho II**.',
        '**Posto das Lanças Cegas** — fale com Donfang Huan, que segue você.',
        '**Dongfang Lie: Certo e Errado** — fale com o Major Lu Xing em `517,159(24)` e depois com Donfang Huan.',
        '**Dongfang Lie: Místicos** — fale com o Rei em `663,134(41)` e use a **Página de desenho III**.',
        '**Preparação para a batalha** — fale com o Ancião Abissal em `617,107(21)`.',
        '**Dongfang Lie: Novamissão** — fale com o Líder do Pavilhão em `617,106(21)` e depois com Donfang Huan.',
        '**Dongfang Lie: Pista secreta** — abra o Mapa Secreto no inventário e siga até `646,219(21)`.',
        '**Dongfang Lie: Cooperação** — fale com a Garota Misteriosa em `645,219(21)` e vá a `658,204(21)`, na Vila da Presa do Dragão.',
        '**Dongfang Lie: Investigação** — volte a `645,219(21)`, fale com a Garota Misteriosa e vá a `659,209(21)`.',
        '**Dongfang Lie: Alvo** — vá a `659,209(21)` e espere o teleporte.',
        '**Dongfang Lie: Fuga** — espere a cena terminar.',
        '**Dongfang Lie· Até breve** — vá a `651,281(24)` e fale com a Garota Misteriosa.',
        '**Dongfang Lie: Tensão** — fale com o Rei em `663,134(41)` e use a **Página de desenho IV**.',
        '**Dongfang Lie: Briga** — fale com o Líder do Pavilhão em `617,106(21)`.',
        '**Dongfang Lie: Interrogatório** — fale com Xijue em `617,106(21)`.',
        '**Dongfang Lie: Concessão** — fale com Donfang Huan e chegue a `686,214(22)` pela entrada da caverna em `689,225(22)`.',
        '**Dongfang Lie: Piorar** — fale com Xijue em `686,215(21)`, vá a `616,120(22)` e fale com Feng Xing.',
        '**Dongfang Lie: Última guerra** — fale com o Rei em `663,134(41)` e use a **Página de desenho V**.',
        '**Campo de batalha** — use a Página de desenho e espere o teleporte para a Terra dos Sussurros.',
        '**Dongfang Lie: Preparação** — fale com Feng Xing em `689,272(22)`, cave 5 Bombas Fogo da Terra ali e fale com Donfang Huan.',
        '**Dongfang Lie: Amor** — fale com Xijue em `687,270(22)`.',
        '**Dongfang Lie: Defesa** — fale com Xijue e encha a barra até **100 pontos**: Yaksha com Lança e Mago das Trevas Yaksha dão 10 cada, Vanguarda Yaksha dá 20. Depois fale com ele.',
        '**Dongfang Lie: Ação** — fale com Xijue em `687,270(22)` e vá a `567,136(24)`.',
        '**Dongfang Lie: Plano secreto** — fale com Dongfang Lie, vá a `568,124(22)` e derrote 10 entre Escrava Yaksha, Batedor Espinho Noturno, Mago Yaksha, Guarda Yaksha e Oficial Espinho Noturno. Fale com Donfang Huan, vá a `583,133(25)` e fale com ele outra vez.',
        '**Dongfang Lie: Assassinato** — fale com Donfang Lie em `583,135(25)`.',
        '**Dongfang Lie: Soberano** — espere a cena.',
        '**Dongfang Lie: Sonho I** — fale com o Rei em `663,134(41)` e use a **Página de desenho VI**.',
        '**Dongfang Lie: Sonho II** — clique na Página de desenho VI no inventário e, depois do teleporte, fale com o NPC em `667,125(41)`.',
        '**Dongfang Lie: Sucessão** — fale com o Rei Dong Fanghuan em `663,134(41)`.',
    ],
})

SAGAS.append({
    'slug': 'espiritualista',
    'classe': 'Espiritualista',
    'heroi': 'Dongfang Meng',
    'ovo': 'Ovo de Pequena Dongfang Meng',
    'titulo': 'Grou e Humano Unidos',
    'resumo': 'A mais estranha das dezessete, e a única que abre com sete minijogos '
              'seguidos — pedra-papel-tesoura, digitação, cartas, um quebra-cabeça de '
              'deslizar — para arrancar os versos de um poema. Depois vira ritual.',
    'comecar': 'Abra a Saga do Herói, clique na Espiritualista e use a ação '
               '*refletir* no local que a missão indica.',
    'avisos': [
        '**O quebra-cabeça do Xizhi é o único de verdade.** As peças não giram: as '
        'horizontais só andam na horizontal e as verticais só na vertical. O objetivo '
        'é levar a peça de cor diferente até a seta da direita. *Atualizar* embaralha '
        'tudo; *Replay* devolve ao estado inicial.',
        '**No desafio de digitação do Xijie, cinco erros falham.** Fale com ele de '
        'novo para recomeçar.',
        '**Tetos de dano:** Caracol **15.000** (30% de chance de largar a Pasta), '
        'Baleia **12.000**, Água-Viva **15.000**.',
    ],
    'passos': [
        '**Dongfang Meng: canção onírica** — use a ação *refletir* no local indicado.',
        '**“O grou branco e o peixe” I** — vá a `661,130(23)`, fale com o Residente abissal Xiji e **ganhe 3 vezes** no pedra-papel-tesoura. Depois fale com ele.',
        '**“O grou branco e o peixe” II** — vá a `659,123(23)`, fale com Xijie e digite as letras na ordem que aparecerem. Cinco erros falham.',
        '**“O grou branco e o peixe” III** — vá a `672,119(23)` e fale com Xijun. Escolha uma das cinco cartas viradas; ganha quem tiver mais estrelas. Empate ou derrota: aceite de novo.',
        '**“O grou branco e o peixe” IV** — vá a `674,128(23)` e fale com Xizhi. Resolva o quebra-cabeça de deslizar.',
        '**“O grou branco e o peixe” V** — vá a `674,34(23)` e fale com Xibai.',
        '**“O grou branco e o peixe” VI** — vá a `660,135(23)`, fale com Xirong, mate Caracóis em `620,104(21)` no Santuário Marinho até largar a Pasta de Caracol e volte a ele.',
        '**“O grou branco e o peixe” VII** — vá a `666,142(25)`, fale com Xizong, e ele se esconde: encontre-o em `668,134(23)`.',
        '**O grou branco e o peixe** — digite os doze versos, um a um: *Qual é a maior distância que existe do mundo? / Aquela que separa a estrela do fundo do mar / A estrela cadente rasga o céu / Mas nunca mergulha até o fundo do mar / Qual é a maior distância que existe do mundo? / Aquela que separa o grou branco do peixe / Eles eram originalmente um só / Mas por causa das asas e das barbatanas / Estão eternamente separados / Toda estrela carrega um peixe / E todo peixe... / Tem asas para voar*. Depois vá a `663,132(41)`, no Templo das Nuvens — o Teleportador Lore Wesley em `668,124(23)` leva você.',
        '**Dongfang Meng: Memórias** — use a ação *refletir* e fale com o Grou branco.',
        '**Dongfang Meng: Retorno** — cave a Profecia de cem anos atrás em `662,135(41)`.',
        '**Dongfang Meng: Controvérsia** — fale com o Ministro Lu Jiuxi e com a Espiritualista Sha Juaing em `663,133(41)`, e feche com o Sacerdote Yun Kongji em `662,134(41)`.',
        '**Conversa pai e filha** — conclui sozinha.',
        '**Dongfang Meng: Aprendendo** — vá a `662,137(41)` e fale com o Sacerdote Yun Kongji.',
        '**Dongfang Meng: Redação** — ache **1 Inspiração**. A *Dança da Paz* fica em `656,137(23)`, na Cidade das Tormentas; há também *Orquídea* e *Vinho*. Cave e volte ao Wencheng.',
        '**Dongfang Meng: Música** — fale com Yinyuan em `662,139(32)` e com Wuqi em `659,148(25)`. Mate 5 Baleias em `600,100(20)` pelas Barbas, volte ao Wuqi; mate 5 Água-Viva em `641,102(19)` pelas Películas, volte ao Wuqi. Feche com Yinyuan.',
        '**Dongfang Meng: Performances** — vá a `656,138(23)`, fale com Chige e aceite *Que tipo de criatura é você?* com os quatro: Sha Feiqiong em `664,123(23)`, Feng Wuying em `666,122(23)`, o Alfaiate em `662,120(23)` e Donfang Huan em `663,135(41)`. Volte ao Chige.',
        '**Dongfang Meng: Rituais** — vá a `673,115(23)` e fale com Simen do Ministério dos Rituais.',
        '**Ritos de Passagem** — fale com Wuqi em `659,148(25)`, Wencheng em `670,118(24)`, Yinyuan em `662,139(32)`, Chige em `656,138(23)` e Simen em `673,115(23)`. Feche com o Sacerdote Yun Kongji em `652,152(25)`.',
        '**Dongfang Meng: Ministérios** — fale com Donfang Huan em `663,135(41)`.',
        '**A Sereia e o Grou** — vá a `635,123(28)`, fale com Dongfang Meng e com o Grou branco que passa a seguir você. Depois fale com Donfang Meng no Mar de Areia, em `625,982(22)` na Pedra de Gelo e em `131,787` na Terra da Preocupação. Volte a `633,123(28)` e feche com Donfang Meng em `635,123(28)`.',
        '**Dongfang Meng: Despertar** — vá a `635,123(28)` e fale com Donfang Huan.',
        '**Dongfang Meng: Ritual** — fale com o Sacerdote Yun Kongji em `662,134(41)`, depois com Wencheng, Yinyuan, Chige e Simen (todos entre `656,145(41)` e `657,146(41)`), e termine com Wencheng de novo.',
        '**Dongfang Meng: Rompimento** — fale com Dongfang Meng em `657,145(41)` duas vezes e feche com Wencheng, no mesmo lugar.',
        '**Dongfang Meng: Oferenda (I)** — fale com Dongfang Meng, depois com Wencheng, cave a Orquídea de Baunilha em `657,146(41)` e **clique nela no inventário**.',
        '**Dongfang Meng: Oferenda (II)** — fale com Dongfang Meng, com Wencheng, com Dongfang Meng de novo, cave o Vinho maravilhoso de néctar em `658,146(41)` e clique nele.',
        '**Dongfang Meng: Oferenda (III)** — fale com Dongfang Meng, com Wencheng e com Dongfang Meng outra vez.',
        '**Dongfang Meng: Reverências** — fale com Dongfang Meng, com Wencheng e com Dongfang Meng mais duas vezes.',
        '**Ritual Proibido** — fale com o Sacerdote Yun Kongji em `662,134(41)`.',
        '**Dongfang Meng: Honrando Votos** — fale com Dongfang Meng em `657,145(41)`, com o Jovem grou branco ali, com Donfang Huan em `662,136(41)` e volte ao Jovem grou branco.',
        '**Dongfang Meng: Fim** — fale com o Grou branco em `663,134(41)`.',
        '**Dongfang Meng: Sereia** — conclui sozinha depois da cena.',
        '**Dongfang Meng: Ao Sol** — fale com o Grou branco em `663,134(41)`, vá a `548,376(22)` na Vila dos Sonhos e fale com ele.',
        '**Dongfang Meng: À Lua** — fale com o Grou branco, vá a `374,350(21)` na Vila do Bambu e fale com ele.',
        '**Dongfang Meng: À Estrela** — fale com o Grou branco, vá a `648,541(22)` no Bosque da Flor do Pêssego e fale com ele.',
        '**Estrela Cadente** — fale com o Grou branco.',
    ],
})

SAGAS.append({
    'slug': 'bardo',
    'classe': 'Bardo',
    'heroi': 'Dongfang Liqing',
    'ovo': 'Ovo de Pequena Liqing',
    'titulo': 'Lua ao Som Magnífico',
    'resumo': 'A mais longa das dezessete — quarenta e oito missões — e a que mais '
              'usa cena em tela cheia. Cinco volumes de um livro antigo levam você a '
              'cinco lugares, e o Esc é a tecla que você mais vai apertar.',
    'comecar': 'Abra a Saga do Herói e clique no Bardo. O **Acordo da Brisa Suave** '
               'aparece no inventário; clique nele.',
    'avisos': [
        '**Saiu do mapa? Volte pelo Ancião das Tormentas**, em `657,144(25)`, na '
        'missão *Retornar ao livro antigo*. Vale para o Fundo do Mar da Desilusão e '
        'para a Ilha do Orvalho Místico.',
        '**O baú dos livros antigos abre com 1 0 2 3.**',
        '**Duas missões pedem para você digitar.** Em *Contrato*, escreva '
        '`Dongfang Liqing`; em *Melodia*, `Ilha do Orvalho Místico`. Sem aspas, nas '
        'duas.',
        '**A Essência da Folha dá 70% das vezes.** São 5, e cavar as Folhas Branco de '
        'Pérola perto de `288,519(23)` é o que repõe.',
    ],
    'passos': [
        '**Dongfang Liqing: Brisa** — clique no Acordo da Brisa Suave no inventário.',
        '**Dongfang Liqing: História** — feche a cena com **Esc** e vá ao Ancião das Tormentas em `657,143(25)`.',
        '**Dongfang Liqing: Marés** — vá a `656,145(25)`, cave o Baú contendo livros antigos com a senha **1 0 2 3** e clique no Volume I – Viagem.',
        '**Dongfang Liqing: Pergaminho** — feche a cena com Esc.',
        '**Anos Dourados** — vá a `658,143(25)`, na Cidade das Tormentas, e espere o popup.',
        '**Dongfang Liqing: Silêncio** — conclui sozinha.',
        '**Dongfang Liqing: Vontade** — vá a `616,107(21)`, no Santuário Marinho, fale com Dongfang Yu e feche a cena com Esc.',
        '**Dongfang Liqing: Sinceridade** — vá a `668,123`, fale com o Jovem Yanxu em `665,125(23)`, depois com a Amiga de Luoluo, com Jinhe e com o Familiar do Ancião, no mesmo lugar.',
        '**Dongfang Liqing: Renome** — derrote o Civil abissal Tang Jiang usando as habilidades **1, 2 e 3** (Explosão Espiritual, Ataque de Impacto, Espírito da Terra). Fale com ele depois e feche a cena com Esc.',
        '**Dongfang Liqing: Estrelas** — espere os 30 segundos da cena.',
        '**Dongfang Liqing: Passado** — conclui sozinha.',
        '**Dongfang Liqing: Despedida** — feche a cena com Esc e clique no Volume II – Dificuldades no inventário. Feche a cena nova com Esc.',
        '**Dongfang Liqing: Inacabado** — feche a cena com Esc. Você é teleportado ao Fundo do Mar da Desilusão.',
        '**Dongfang Liqing: Dificuldade** — conclui sozinha.',
        '**Dongfang Liqing: Folha** — vá a `283,520(21)`, fale com o Médico Xia Ying e consiga **5 Essência da Folha** clicando nas Folhas Branco de Pérola que você cava perto de `288,519(23)`. Volte a ele e espere 5 segundos.',
        '**Dongfang Liqing: Medicina** — clique no Pó da Folha Branco de Pérola, adicione a Poção medicinal pura na janela de Combinar e clique em **Iniciar** para obter a Pasta medicinal.',
        '**Acalmar o povo** — conclui sozinha.',
        '**Dongfang Liqing: Desbloqueio** — vá a `289,541(22)` e derrote a Fera das Profundezas.',
        '**Dongfang Liqing: Crise** — verifique as pistas em `287,536(22)`, `285,531(22)` e `281,526(22)`, e fale com o Líder Yuehua em `284,522(21)`.',
        '**Dongfang Liqing: Divisão** — espere e fale com o Líder Zhen’an, no mesmo lugar.',
        '**Dongfang Liqing: Cerca** — cave o Ponto de disposição em `282,523(21)` e em `284,527(21)`, e espere 5 segundos.',
        '**Dongfang Liqing: Inimigos** — vá a `297,533(22)`.',
        '**Dongfang Liqing: Armadilha** — conclui sozinha.',
        '**Dongfang Liqing: Vitória** — vá a `293,518(23)`, no Mar da Desilusão, e derrote 10 monstros.',
        '**Dongfang Liqing: Pertences** — vá a `289,522(21)`, fale com o Guarda Shanghe e clique nas três relíquias no inventário — Luoluo, Qiushi e Baiyan. Fale com ele outra vez.',
        '**Dongfang Liqing: Mártires** — vá a `277,511(21)`, cave o Descanso Eterno dos Mártires e feche a cena com Esc.',
        '**Dongfang Liqing: Dragão** — clique no Volume III – Dragão no inventário e feche a cena com Esc.',
        '**Dongfang Liqing: Linhagem** — fale com o Guarda Shanghe em `315,550(21)`, espere 5 segundos e vá a `337,550(22)`.',
        '**Dongfang Liqing: Ancestral** — vá a `341,550(21)`, fale com o Criado Divino Xuanwu e feche a cena com Esc.',
        '**Dongfang Liqing: Dia Comum** — fale com o Operador Logístico Yiran em `337,551(21)`, depois com a Criança e com Xuanwu, e feche com Esc.',
        '**Dongfang Liqing: Amizade** — vá a `341,550(21)` e fale com Xuanwu.',
        '**Dongfang Liqing: Contrato** — escreva **Dongfang Liqing** e envie. Espere 19 segundos e feche a cena com Esc.',
        '**Dongfang Liqing: Intenção** — vá a `341,550(21)` e fale com Xuanwu.',
        '**Dongfang Liqing: Fim** — vá a `341,550(21)` e fale com Xuanwu.',
        '**Dongfang Liqing: Dragão** — espere a cena.',
        '**Laço do Destino** — clique no Volume IV – Ilha do Orvalho no inventário e feche a cena com Esc.',
        '**Dongfang Liqing: Sonho** — você é teleportado à Ilha do Orvalho Místico.',
        '**Ilha do Orvalho Místico** — vá a `323,563(28)`, `324,569(29)` e `319,575(31)`, nessa ordem.',
        '**Dongfang Liqing: Melodia** — fale com Cenxi em `320,577(31)`, escreva **Ilha do Orvalho Místico** e envie. Depois vá a `316,566(28)` e fale com Xiaofeng.',
        '**Dongfang Liqing: Cítara** — cave a Jade em `317,568(28)` e feche a cena com Esc.',
        '**Dongfang Liqing: Compreensão** — fale com Cenxi em `320,575(31)`, vá a `294,584(28)` e feche a cena com Esc.',
        '**Dongfang Liqing: Sucessão** — fale com Cenxi em `294,584(28)` e feche a cena com Esc.',
        '**Dongfang Liqing: Canção** — clique no Volume V – Pássaro no inventário.',
        '**Dongfang Liqing: Pássaro** — vá a `310,570(28)`.',
        '**Dongfang Liqing: Descanso** — fale com Dongfang Liqing em `311,570(28)`.',
        '**Dongfang Liqing: Mar** — feche a cena com Esc.',
        '**Dongfang Liqing: Epílogo** — fale com o Ancião das Tormentas em `657,144(25)`.',
        '**Dongfang Liqing: Sem nome** — você recebe o Papel entre as folhas; feche a cena com Esc.',
    ],
})

SAGAS.append({
    'slug': 'mistico',
    'classe': 'Místico',
    'heroi': 'Yuan Ruo',
    'ovo': 'Ovo de Pequeno Yuan Ruo',
    'titulo': 'Fragrância da Memória',
    'resumo': 'Uma carta secreta no Pináculo do Despertar que termina em Tellus, '
              'quarenta e uma missões depois. Pede duas palavras escritas e fecha com '
              'o único minijogo de teclas de toda a saga.',
    'comecar': 'Abra a Saga do Herói, clique no Místico e vá a `149,245(13)`.',
    'avisos': [
        '**Duas missões pedem para escrever no papel:** em *Jiashu*, escreva `Jiashu`; '
        'em *Folhas e flores*, `Ye Zhenzhen`.',
        '**A *Melodia* é por tempo.** São três sequências de teclas aleatórias, e são '
        'permitidos até **5 erros em cada**.',
    ],
    'passos': [
        '**Yuan Ruo: Carta secreta** — vá a `149,245(13)`.',
        '**Yuan Ruo: Ação secreta** — fale com o Vidente do Vazio em `148,245(13)`, no Pináculo do Despertar, e vá a `114,215(13)`.',
        '**Yuan Ruo: Evitar inimigo (I)** — derrote 5 Guerreiro Almas Estilhaçadas perto de `114,215(13)` e vá a `112,210(13)`.',
        '**Yuan Ruo: Jiashu** — fale com o Arcano recém-nascido em `112,209(13)` e escreva **Jiashu** no papel.',
        '**Yuan Ruo: Amizade** — fale com o Arcano recém-nascido e vá a `135,276(13)`.',
        '**Yuan Ruo: Evitar inimigo (II)** — derrote 5 Guerreiro Alma Estilhaçadas em `136,227(13)` e vá a `130,273(13)`.',
        '**Yuan Ruo: Folhas e flores** — vá a `136,227(13)`, fale com o Místico recém-nascido e escreva **Ye Zhenzhen**.',
        '**Yuan Ruo: Ancião** — fale com o Místico recém-nascido e vá a `392,229(27)`.',
        '**Yuan Ruo: Deja-vu** — fale com o Ancião Star de Tellus em `394,230(27)`, depois com o Ancião Yashimo em `397,230(28)`, espere 10 segundos, fale com Yashimo de novo e feche no Star de Tellus.',
        '**Yuan Ruo: Os mais próximos** — fale com o Ancião Star de Tellus, depois com a Mestre Mística Cheng He em `376,243(23)`, com o Mestre Arcano Liang em `382,243(23)`, e volte ao Star de Tellus.',
        '**Cítara da Purificação** — fale com o Star de Tellus, vá a `398,230(26)`, fale com Ye Zhenzhen e volte a ele.',
        '**Yuan Ruo: Cultivo** — fale com o Star de Tellus e espere o teleporte.',
        '**Yuan Ruo: Fortalecimento** — fale com Proteção de Ferro em `156,206(21)`, na Planície Minuano, e espere 10 segundos.',
        '**Yuan Ruo: Avanço** — fale com Proteção de Ferro e vá a `193,218(21)`.',
        '**Yuan Ruo: Companhia** — fale com Jiashu em `194,220(21)`, derrote a Tarântula da Obsidiana em `206,229(21)` e vá a `214,227(21)`.',
        '**Confusão de identidade?** — fale com Anchoret Alexandria em `215,228(21)` e siga até `233,230`.',
        '**Planta de Procriação da Alma** — fale com o Guardião Ancestral Shawn em `233,231(22)` e espere 10 segundos.',
        '**Yuan Ruo: Efeito colateral** — fale com Jiashu, que segue você, e espere 10 segundos.',
        '**Memórias Distorcidas** — fale com Ye Zhenzhen, vá a `218,256(22)`, fale com Jiashu, vá a `210,254(21)`, fale com Ye Zhenzhen, derrote 5 Formigas Mutantes e fale com a Formiga-rainha das trevas em `247,277(23)`.',
        '**Formiga-rainha das trevas** — fale com ela em `247,277(23)` e derrote-a no mesmo lugar.',
        '**Yuan Ruo: Fuga** — fale com a Formiga-rainha e vá a `252,252(21)`.',
        '**Yuan Ruo: Brilhando** — fale com Ye Zhenzhen, cave a Pedra estabilizadora em `260,240(26)` e fale com o Sábio de Wildwood em `257,238(22)`.',
        '**Yuan Ruo: Tumba** — fale com o Sábio de Wildwood e use o Pergaminho de teletransporte do inventário.',
        '**Yuan Ruo: Chamada misteriosa** — fale com Ye Jiashu e vá a `315,206(21)`.',
        '**Mémorias da vida passada** — fale com Zhenzhen em `316,207(21)` e siga até `310,235(22)`.',
        '**Yuan Ruo: Wanwan** — fale com Sharen, o Ritualista, em `311,234(22)` e espere 30 segundos.',
        '**Descoberta acidental** — fale com Ye Zhenzhen e vá a `416,229(22)`.',
        '**Yuan Ruo: Alma solitária** — fale com a Alma Solitária em `416,230(32)` e espere o teleporte.',
        '**Yuan Ruo: Sombras** — fale com Joyce em `422,219(26)`, vá a `405,255(23)` nas Ruínas Antigas, derrote 5 Dríade Errante e 5 Dríade Ladrão, e siga para `413,275(23)`.',
        '**Yuan Ruo: Nome** — espere os 30 segundos da cena; você vai para o Santuário Esquecido.',
        '**Mémorias da vida passada** — fale com Ye Zhenzhen.',
        '**Yuan Ruo: Retorno** — fale com o Capitão da Guarda Clarinda em `472,270(17)` e, depois do teleporte, vá a `364,230(24)`, na Cidade de Tellus.',
        '**Yuan Ruo: Unidos** — fale com Mu Suiliang em `365,234(24)`, vá a `362,231(23)` e derrote 5 Aparição.',
        '**Yuan Ruo: Força!** — fale com Jiashu em `365,232(24)`.',
        '**Yuan Ruo: Câmara secreta** — fale com Zhenzhen em `365,230(24)` e vá a `388,216(24)`, depois `380,209(22)` e `363,215(20)`.',
        '**Yuan Ruo: Reconstituição** — espere os 30 segundos da cena.',
        '**Yuan Ruo: Retorno** — fale com Yuanruo em `361,219(23)` e vá a `362,229(24)`.',
        '**Yuan Ruo: Melodia** — digite as **três sequências de teclas** antes do tempo acabar, errando no máximo 5 vezes em cada.',
        '**Yuan Ruo: Paz** — fale com o Ancião de Tellus Mu Xingchen em `265,230(24)`.',
        '**Yuan Ruo: Dissipação** — fale com Qing Chenghe em `366,230(24)` e vá a `449,451(57)`.',
        '**Yuan Ruo: Começo e fim** — fale com O Honrado de Espírito Precios em `449,451(57)`, espere 50 segundos de cena e feche falando com Jiashu, que segue você.',
    ],
})

SAGAS.append({
    'slug': 'arcano',
    'classe': 'Arcano',
    'heroi': 'Mu Suiliang',
    'ovo': 'Ovo de Pequeno Mu Suiliang',
    'titulo': 'Espada do Renascimento',
    'resumo': 'Um soldado comum do Acampamento dos Aliados que acaba forjando uma '
              'arma divina e fundando uma raça. Duas missões aqui escondem o destino '
              'e mandam você procurar pela cor do minimapa.',
    'comecar': 'Abra a Saga do Herói, clique no Arcano e vá a `382,243(23)` falar com '
               'o **Mestre Arcano Liang**.',
    'avisos': [
        '**Duas missões não dão coordenada exata — dão o minimapa.** Em *Conspiração* '
        'e em *Mestre-discípulo*, ande pela área enquanto o minimapa do canto '
        'superior direito muda de cor: **vermelho é perto**.',
        '**O Guardião de Obsidiana não aparece sozinho.** Em *Crise*, derrote os '
        '*Trabalhadores selvagens esquisitos* em `320,268(22)` até ele se revelar.',
    ],
    'passos': [
        '**Mu Suiliang: Mestre Arcano** — vá a `382,243(23)` e fale com o Mestre Arcano Liang.',
        '**Mu Suiliang: Passado** — fale com ele outra vez e espere o teleporte para o Acampamento dos Aliados.',
        '**Acampamento dos Aliados** — fale com o Guarda Dommer Jirek em `619,723(22)`.',
        '**Mu Suiliang: Ervas** — fale com o Guarda, cave 1 Erva medicinal em `215,222(21)` e espere 6 segundos.',
        '**Mu Suiliang: Lingyao** — fale com Lingyao, que segue você, e espere o teleporte.',
        '**Mu Suiliang: Acampamento** — conclui sozinha.',
        '**Mu Suiliang: Conspiração** — fale com o Guarda Dommer Jirek, e no Pântano Corrompido procure a Ordem do general perto de `211,256(21)` **pela cor do minimapa**. Chegando, derrote 3 Formigas Mutantes e fale com Lingyao.',
        '**Mu Suiliang: Virada** — fale com Lingyao e feche a cena com **Esc**.',
        '**Mu Suiliang: Mestre-discípulo** — ache o ponto combinado perto de `342,242(21)`, de novo pela cor do minimapa, e fale com Lingyao em `342,244(21)`.',
        '**Mu Suiliang: Meses depois** — conclui sozinha.',
        '**Mu Suiliang: Sucesso** — conclui sozinha.',
        '**Mu Suiliang: Arma divina** — fale com Lingyao em `342,244(21)` e vá a `240,212(21)`.',
        '**Mu Suiliang: Cervo** — fale com o Cervo em `239,213(21)`, derrote 3 Crocodilos de Escamas Vermelhas perto de `243,207(21)` e volte a ele.',
        '**Mu Suiliang: Encontro** — repita com o Cervo, depois vá a `249,203(20)`, cave o Ferro milenar e volte à margem do lago, em `242,213(21)`.',
        '**Mu Suiliang: Forjar espada** — fale com Zhaoyao em `239,213(21)` e vá falando com ela a cada teleporte, até a Garganta do Avalanche. Vá a `325,975(23)` e fale com ela.',
        '**Substância carbonácea** — fale com Zhaoyao, vá a `292,950(21)` e cave a Substância carbonácea.',
        '**Cidade das Espadas** — fale com Zhaoyao e, depois do teleporte, fale com o Ancião da Cidade das Espadas em `433,887(27)` e procure o Ferreiro Medaline em `442,899(26)`. Espere 10 segundos.',
        '**Mu Suiliang: Símbolo** — fale com o Ferreiro Medaline, espere 10 segundos, fale com o Ancião em `433,887(27)` e com Zhaoyao.',
        '**Mu Suiliang: Símbolo** — há uma **segunda missão com o mesmo nome**: pegue no Lingyao, em `342,244(21)`, e fale com Zhaoyao.',
        '**Mu Suiliang: Crise** — fale com Lingyao, vá a `317,275(21)` e depois `320,269(22)`. Derrote os *Trabalhadores selvagens esquisitos* em `320,268(22)` para revelar os 2 Guardião de Obsidiana, derrote-os e fale com o Trabalhador selvagem machucado em `312,275(22)`.',
        '**Mu Suiliang: Guerra** — fale com o Trabalhador machucado e vá a `367,275(21)`.',
        '**Mu Suiliang: Símbolo** — espere os 50 segundos da cena.',
        '**Mu Suiliang: Resgate** — fale com Lingyao em `342,244(21)`, vá a `247,267(21)` e fale com o Sobrevivente da Expedição.',
        '**Mu Suiliang: Obsidiano** — espere a cena.',
        '**Mu Suiliang: Mártir** — fale com Lingyao em `342,244(21)`.',
        '**Mu Suiliang: Renascimento** — fale com Lingyao e, nos Bosques Telepáticos, fale com ele de novo. Cave o Espelho de Seleção em `348,208(21)`, fale com ele, vá a `334,208(21)` e fale uma última vez.',
        '**Mu Suiliang: Guardião** — fale com Lingyao em `342,244(21)`.',
        '**Mu Suiliang: Seleção** — fale com Lingyao, cave 3 Alma do herói espalhadas por `344,257(21)` e fale com Qingfeng em `349,255(22)`.',
        '**Mu Suiliang: Qingfeng** — fale com Qingfeng, vá a `347,207`, espere 10 segundos, fale com ele e volte a `341,244(21)` para falar com Lingyao.',
        '**Mu Suiliang: Mestre-discípulo** — fale com Lingyao em `342,244(21)`.',
        '**Mu Suiliang: Anos depois** — conclui sozinha.',
        '**Mu Suiliang: Aprimoramento** — fale com Qingfeng.',
        '**Mu Suiliang: Ruínas Antigas** — fale com Qingfeng, vá a `413,278(23)` e derrote as Espadas gêmeas destruidora.',
        '**Mu Suiliang: Ensinamento** — fale com Espadas gêmeas destruidora em `413,281(23)`.',
        '**Energia da espada** — fale com Espadas gêmeas destruidora e cave a Energia da espada no mesmo lugar.',
        '**Mu Suiliang: Treinamento** — fale com Qingfeng, vá a `317,200(21)`, derrote o Lobo Marrom Escuro duas vezes pela Afinidade da Lâmina e o Bruto Corrupto pela Transfiguração.',
        '**Mu Suiliang: Cinco Elementos** — fale com Qingfeng, vá a `276,267(21)`, fale com o Exilado da Floresta Chimei e cave as cinco Forças: Metal em `280,278(23)`, Madeira em `280,277(23)`, Água em `281,276(23)`, Fogo em `282,276(23)` e Terra em `284,276(23)`. Feche com Qingfeng.',
        '**Mu Suiliang: Ancião** — fale com Qingfeng, espere o teleporte para `256,238(21)` e fale com o Sábio de Wildwood.',
        '**Pináculo do Despertar** — fale com o Sábio de Wildwood e feche com o Bibliotecário Yua em `158,251(13)`.',
        '**Mu Suiliang: Voo** — fale com Yua, vá a `152,253(13)` e fale com ele. Cave o Esqueleto do voo dos guardiões em `167,280(13)` e o Poder da natureza em `127,272(13)`, e volte ao Yua.',
        '**Mu Suiliang: Mestre Arcano** — espere a cena.',
    ],
})

SAGAS.append({
    'slug': 'paladino',
    'classe': 'Paladino',
    'heroi': 'Tian Yi',
    'ovo': 'Ovo de Mini Tian Yi',
    'titulo': 'Os verdadeiros heróis!',
    'resumo': 'A mais longa de todas em número de missões — cinquenta e duas — e a '
              'única que se passa quase inteira dentro do Inferno antigo. Tem quatro '
              'duelos seguidos contra o próprio Tian Yi e cinco baús de pista.',
    'comecar': 'Abra a Saga do Herói, clique no Paladino e fale com **Goh, o Velho '
               'Contador**, na Cidade do Dragão Leste, em `585,641`.',
    'avisos': [
        '**Saiu do modo história? A porta de volta é o Goh.** Falar com ele em '
        '`585,641(21)` é o único jeito de reentrar no Inferno antigo, e isso vale '
        'para a saga toda.',
        '**Nos quatro duelos, o Tian Yi bate muito.** Em *Espada Comum*, *Segunda '
        'Arma*, *Terceira Arma* e *Espada e Escudo* ele ataca você de verdade — se '
        'demorar, morre. Falhando, pegue de novo no Mestre Artesão.',
        '**Em *Coletando Pistas* é preciso ter espaço no inventário.** O mapa com a '
        'pista vai para lá; se não aparecer, cancele e pegue de novo.',
        '**No mapa dos Paredões não dá para voar** — montaria sim.',
        '**O *Treinamento diário* tem 30 minutos.** Falhando, saia do mapa e entre no '
        'Inferno antigo outra vez.',
    ],
    'passos': [
        '**O Jovem Paladino** — fale com Goh, o Velho Contador, em `585,641`.',
        '**As coisas nas histórias** — fale com Goh. Depois da história você vai para `155,834`, na Cidade de Arcádia do Inferno: confirme o popup e fale com Tian Yi em `157,832`.',
        '**Familiar e Estranho** — fale com Tian Yi.',
        '**As pessoas da história** — fale com Tian Yi.',
        '**Tirar a pipa** — cave a pipa em `157,832(19)`, **no alto, em cima da asa da estátua**, e fale com Ying Xin em `157,832`.',
        '**Evite as abelhas** — vá a `163,828`. As abelhas machucam; com pouco HP, cuidado.',
        '**Fugir das Abelhas** — vá a `172,824`.',
        '**Primeiro encontro** — fale com Tian Yi, ali perto.',
        '**Os sete filhos despedaçados** — fale com Ying Xin perto de `173,824` e depois com Tian Yi.',
        '**Ajuda a caminho** — fale com Chong Guang e depois com Ying Xin.',
        '**Treinamento diário** — fale com Tian Yi. São **30 minutos**.',
        '**Procurando Paredões** — vá a `157,823` e encontre Tian Yi em `155,816(29)`.',
        '**Trilha suspeita** — fale com Tian Yi e vá até a Flor de Pessegueiro.',
        '**Salvando a Flor de Pêssego** — fale com a Flor de Pessegueiro.',
        '**Recompensa Inesperada** — fale com Tian Yi, cave o Pedaço de Ferro em `163,806`, fale com ele e procure Ying Xin perto de `163,809`.',
        '**A Cauda Inabalável** — fale com Ying Xin e encontre o Mestre Artesão em `168,817` — aqui já dá para voar.',
        '**Condições do Artesão** — fale com o Artesão. Depois **saia do Inferno antigo** e vá à DG 89 God, na Terra dos Imortais.',
        '**Derrotando Brahma** — mate Brahma na Terra dos Imortais.',
        '**Desejo de Vida** — fale com o Espírito de Brahma, que **só aparece depois do boss morto**, e espere 10 segundos.',
        '**Voo em dupla** — fale com o Fogo Demoníaco.',
        '**O Último Sacrifício** — fale com Ying Xin, cave a Lâmina Partida perto de `384,591`, volte ao Inferno antigo pelo Goh e fale com o Mestre Artesão.',
        '**Cumprimento da Promessa** — fale com o Mestre Artesão e espere 10 segundos.',
        '**Espada Comum** — fale com o Artesão. Tian Yi ataca: derrote-o e volte a falar com o Artesão.',
        '**Segunda Arma** — fale com o Artesão, derrote Tian Yi de novo e volte a ele.',
        '**Terceira Arma** — fale com o Artesão, derrote Tian Yi e volte a ele.',
        '**Espada e Escudo** — fale com o Artesão e derrote Tian Yi.',
        '**Renascimento** — fale com o Artesão.',
        '**Sorte Inesperada** — vá a `150,802`, mate Maléfico Terral até largar o Pergaminho de Habilidade e fale com Tian Yi.',
        '**Pergaminho Secreto** — fale com Tian Yi e vá à Biblioteca, em `123,802`.',
        '**Emprestando Livros** — fale com a Biblioteca e espere.',
        '**Memória Extraordinária** — fale com a Biblioteca e encontre Chong Guang em `174,824`.',
        '**Acumulo de Experiência** — fale com Chong Guang e encontre Shen Tulie em `158,828`.',
        '**Coletando Pistas** — fale com Shen Tulie. O mapa com a primeira pista vai para o inventário — **precisa de espaço**.',
        '**Encontrando Pistas** — clique no mapa, vá a `146,768` e cave o baú que aparece.',
        '**Primeira Pista** — fale com Tian Yi; a próxima pista chega ao inventário.',
        '**Encontrando Pistas (2)** — clique no mapa, vá a `126,784` e cave o baú.',
        '**Segunda Pista** — fale com Ying Xin; a próxima pista chega ao inventário.',
        '**Encontrando Pistas (3)** — clique no mapa, vá a `140,806` e cave o baú.',
        '**Terceira Pista** — fale com Ying Xin.',
        '**Encontrando Pistas (4)** — clique no mapa, vá a `123,823` e cave o baú.',
        '**Quarta Pista** — fale com Ying Xin.',
        '**Encontrando Pistas (5)** — clique no mapa, vá a `113,806` e cave o baú.',
        '**A Verdade** — fale com a Flor de Pessegueiro perto de `114,807` e depois com Shen Tulie.',
        '**Mensagem do Amor** — fale com Shen Tulie.',
        '**Abrindo a Carta** — abra a Carta no inventário.',
        '**Chamado do Senhor Demônio** — fale com Shen e encontre o Lorde dos Demônios em `160,837`.',
        '**Prova do Senhor Demônio** — fale com o Lorde e depois com Tian Yi.',
        '**Voltar a Vila** — vá a `172,825`.',
        '**Preparação para Altar** — fale com Chong Guang e espere.',
        '**Explorando o Templo** — fale com Shen Tulie, veja a cena e fale com Ying Xin.',
        '**Fama ao redor do mundo** — depois dos diálogos, fale com o Jovem dos Alados.',
        '**Um despertar de Sonhos** — fale com Goh, o Velho Contador de histórias.',
    ],
    'nota': '**Esta é a página mais fraca das dezessete, e a razão está escrita.** As '
            'duas fontes em português trazem o mesmo texto e o mesmo aviso — saiu do '
            'servidor de testes da Level Up durante a expansão — e a PWpedia, que é '
            'a fonte em inglês, **não tem o Paladino**. Ou seja: é uma fonte só, e de '
            'teste. Se você fez e viu diferente, conte no '
            '[Discord](https://discord.gg/n5v3WdSJyg).',
})

SAGAS.append({
    'slug': 'tormentador',
    'classe': 'Tormentador',
    'heroi': 'Ye Hansu',
    'ovo': 'Ovo de Pequena Hansu',
    'titulo': 'Rigidez com ternura',
    'resumo': 'Quase toda dentro da Cidade Muyi, uma cidade que só existe dentro '
              'desta saga. Termina do jeito mais inesperado de todas as dezessete: '
              'gritando uma frase no chat com um Alto-Falante.',
    'comecar': 'Abra a Saga do Herói, clique no Tormentador e clique no item **Ye '
               'Hansu** que chega ao inventário. Feche a cena com **Esc**, vá a '
               '`775,953(33)` e fale com o **Senhor do Veredito Shosan**, no Templo '
               'da Ilusão — isso conclui *Ye Hansu: Último desejo*, que não faz parte '
               'da saga mas tem de ser feita. Fale com ele de novo para a saga '
               'começar de verdade.',
    'avisos': [
        '**Saiu da Cidade Muyi? A volta é pela Borboleta Muyi**, em `755,939(22)`, na '
        'missão *Entrar na Cidade Muyi*.',
        '**O baú antigo abre com 2 2 4 4.**',
        '**O mob Luobai tem teto de 12.000 de dano por golpe.**',
        '**A última missão é no chat.** Em *Esperança* é preciso usar **1 '
        'Alto-Falante** e escrever: *Mestre! Estou com saudades!*',
    ],
    'passos': [
        '**Ye Hansu: Heroína** — fale com o Senhor do Veredito Shosan em `775,953(33)`, vá a `753,939(22)` e fale com Mo Sechin.',
        '**Ye Hansu: Memórias de Muxi** — fale com Mo Sechin em `753,939(22)`. Na Cidade Muyi, vá a `500,549(75)`, `499,545(75)`, `506,548(75)`, `506,540(75)`, `514,531(75)`, `520,532(75)` e `528,520(75)`, espere 3 segundos, feche a cena com Esc e fale com Luobai em `529,517(78)`.',
        '**Ye Hansu: Anos passados** — espere 25 segundos de cena.',
        '**Ye Hansu: Laços eternos** — fale com Luobai em `529,517(78)`, depois com a Tia em `532,530(77)`. Vá a `506,526(74)`, derrote 1 Borboleta Fênix Muyi e fale com o Comerciante Wang Shifeng em `532,530(77)`. Feche a cena com Esc.',
        '**Ye Hansu: História 1** — fale com Wang Shifeng em `532,530(77)` e feche a cena com Esc.',
        '**Ye Hansu: História 2** — fale com Wang Shifeng e feche a cena com Esc.',
        '**Ye Hansu: História 3** — fale com Wang Shifeng e feche a cena com Esc.',
        '**Ye Hansu: Surpresa** — fale com a Tia em `531,530(77)` e depois com Luobai em `529,517(78)`.',
        '**Ye Hansu: Querido Mestre** — fale com Luobai, depois com o Tio Yu em `490,532(75)`. Derrote a Serpente de Escamas de Ouro em `730,848(25)`, nas Ruínas Obscuras do mapa principal, pelo Fígado da Serpente Dourado, e pegue as essências elementais em `762,897(26)`, na Floresta da Miragem. Volte pela Borboleta Muyi, fale com o Velho Mestre das Ervas em `490,532(75)` e depois com Luobai em `529,517(78)`.',
        '**Ye Hansu: Insistência** — vá a `496,550(75)`.',
        '**Ye Hansu: Mudança de ideia** — fale com Luobai em `497,550(75)`.',
        '**Ye Hansu: Mistério** — fale com Modi em `531,519(78)`, depois com Jiang Ming em `508,515(75)`. Cave a Caixa bastante antiga em `494,513(75)` com a senha **2 2 4 4** e volte ao Jiang Ming.',
        '**Ye Hansu: Encontrando mestre** — fale com Luobai em `478,522(75)`, espere 30 segundos e fale com ele outra vez.',
        '**Ye Hansu: Ideal** — fale com Modi em `531,519(78)`.',
        '**Ye Hansu: Pedido** — fale com Luobai em `529,516(78)`, vá a `513,535(75)` e fale com o Tio Gui. Volte ao Luobai, espere 25 segundos, fale com ele, cave o Acender lanterna em `527,521(77)` e fale com ele de novo.',
        '**Ye Hansu: Transformação** — fale com Luobai em `529,516(78)`, derrote o mob Luobai que é invocado e fale com o NPC Luobai no mesmo lugar.',
        '**Ye Hansu: Conhecimento** — fale com Mo Sechin em `753,939(22)`, depois com o Senhor do Veredito Shosan em `775,953(33)`, o Senhor Wan em `776,958(33)`, o Ancião da Névoa Sombria em `754,851(18)`, o Eremita em `730,860(25)`, e feche com Mo Sechin.',
        '**Ye Hansu: Perplexidade** — fale com Mo Sechin em `753,939(22)` e depois com o Guia Espiritual de 71 geração em `774,954(33)`.',
        '**Ye Hansu: Missão** — fale com o Guia Espiritual, vá a `744,974(24)`, `735,976(22)` e `727,971(22)`. Em `726,971(22)` há uma fumaça: cave-a pela Amostra da árvore milenar.',
        '**Ye Hansu: Missão Cumprida** — vá a `774,954(33)`, fale com o Guia Espiritual, depois com o Senhor Wan em `776,958(33)`, espere 30 segundos e fale com ele outra vez.',
        '**Ye Hansu: Verdade** — fale com o Senhor Wan em `776,958(33)`. Vá a `367,576(23)`, no *Inferno* pelo portal da Cidade Universal, e colete 5 Água do Poço Mágico; depois a `462,621(17)`, no *Céu*, e derrote 49 Carpa Celestial pelos Corações do peixe celestial. Volte ao Senhor Wan.',
        '**Ye Hansu: Sonho Realizado** — fale com Mo Sechin em `753,939(22)` e espere o teleporte para a Cidade Muyi.',
        '**Ye Hansu: Pedir Satisfação** — fale com Modi em `526,517(78)`.',
        '**Ye Hansu: Tristeza** — fale com Zhao Xiaolou em `526,517(78)`.',
        '**Ye Hansu: Contemplar o Mar** — vá a `482,521(76)`.',
        '**Ye Hansu: Flores do Passado** — fale com Mo Sechin em `753,939(22)` e espere o teleporte.',
        '**Ye Hansu: Ressentimento** — vá a `482,520(75)` e espere as cenas.',
        '**Ye Hansu: Onde está ele?** — vá a `500,505(75)`.',
        '**Ye Hansu: Esperança** — use **1 Alto-Falante** e escreva no chat: *Mestre! Estou com saudades!*',
    ],
})

SAGAS.append({
    'slug': 'retalhador',
    'classe': 'Retalhador',
    'heroi': 'Feng Jie’ao',
    'ovo': 'Ovo de Pequeno Feng Jie’ao',
    'titulo': 'Andarilho solitário',
    'resumo': 'A infância, a rebeldia e a vingança de Feng Jie’ao, com a Anciã da '
              'Névoa Sombria como porta entre a memória e o mundo real. Tem pescaria, '
              'peixe assado e um duelo com teto de dano.',
    'comecar': 'Abra a Saga do Herói, clique no Retalhador e vá ao Tronco Ancião '
               'falar com **Nanko Ki**, em `750,887(27)`.',
    'avisos': [
        '**A Anciã da Névoa Sombria em `754,851(28)` é a porta.** Toda vez que a saga '
        'diz *mundo real*, é com ela que se fala.',
        '**O Mago da Aparição tem teto de 12.000 de dano por golpe.**',
    ],
    'passos': [
        '**Primeiro Retalhador** — vá ao Tronco Ancião e fale com Nanko Ki em `750,887(27)`.',
        '**Feng Jie’ao: Ancião** — fale com Nanko Ki e depois com a Anciã da Névoa Sombria em `754,851(28)`.',
        '**Primeiro Encontro** — fale com a Criança Feng Jie’ao em `628,797(21)` e cave o Trigo em `629,797(22)`.',
        '**Feng Jie’ao: Encontro** — fale com a Criança, vá a `644,833(21)` e fale com o Sr. Zhang.',
        '**Origem desconhecida** — fale com o Sr. Zhang em `628,797(21)` duas vezes.',
        '**Feng Jie’ao: Viagem** — fale com a Criança Feng Jie’ao a cada teleporte, por várias cidades, até a missão fechar.',
        '**Feng Jie’ao: Voo** — fale com a Criança, vá a `350,405(45)`, fale com ela, siga para `360,367(65)` e fale outra vez.',
        '**Feng Jie’ao: Lago de lótus** — fale com a Criança, vá a `360,362(21)` e pesque uma Carpa no Ponto de pesca.',
        '**Feng Jie’ao: Assar peixe** — fale com a Criança e asse o peixe na Fogueira em `369,359(22)`.',
        '**Feng Jie’ao: Retorno** — fale com a Criança e depois com o Sr. Zhang em `628,797(21)`.',
        '**Feng Jie’ao: Mundo real** — fale com a Anciã da Névoa Sombria em `754,851(28)`.',
        '**Feng Jie’ao: Rebeldia** — fale com o Jovem Feng Jie’ao em `645,835(21)` e depois com o Sr. Zhang em `628,797(21)`.',
        '**Feng Jie’ao: Confiança** — fale com o Sr. Zhang e volte ao Jovem Feng Jie’ao em `645,835(21)`.',
        '**Feng Jie’ao: Investigação** — fale com o Jovem Feng Jie’ao e depois com Meng Jiuchuan em `635,835(21)`.',
        '**Feng Jie’ao: Sair** — fale com o Jovem Feng Jie’ao em `645,835(21)`.',
        '**Feng Jie’ao: Sabre** — fale com o Jovem Feng Jie’ao, vá a `595,761(29)`, fale com ele e cave o Sabre em `596,763(29)`.',
        '**Feng Jie’ao: Proteção** — fale com ele e derrote 2 Escudeiro Minotauro em `596,762(29)`.',
        '**Feng Jie’ao: Teste** — fale com ele e derrote 2 Centopéia-Rei Coral em `589,753(27)`.',
        '**Primeiro sinal** — fale com ele e vá a `545,653(24)`, na Cidade do Dragão.',
        '**Feng Jie’ao: Mestre** — fale com o Matador de Feras em `545,653(24)`.',
        '**Feng Jie’ao: Mundo real** — fale com a Anciã da Névoa Sombria em `754,851(28)`.',
        '**Feng Jie’ao: Meditação** — fale com o Matador de Feras em `545,653(24)` e espere a cena.',
        '**Feng Jie’ao: Reencontro** — fale com o Matador de Feras e vá a `428,457(22)`.',
        '**Feng Jie’ao: Herói** — fale com o Proprietário da Vila das Espadas em `428,458(22)` e depois com o Cocheiro Wang Li em `419,455(23)`.',
        '**Feng Jie’ao: Ir atrás** — vá a `422,448(22)`, cave o Vestígio da vida e siga para `644,383(23)`, no Porto dos Sonhos.',
        '**Feng Jie’ao: Guerreiro ferido** — fale com o Soldado Ferido em `644,383(23)` e vá a `665,366(22)`.',
        '**Feng Jie’ao: Pescador** — fale com o Pescador Porto dos Sonhos em `665,366(22)` e vá a `680,370(24)`.',
        '**Feng Jie’ao: Engano** — fale com Li Perneta em `679,370(24)` e depois com Feng Jie’ao em `683,371(21)`.',
        '**Feng Jie’ao: Mistério** — fale com Feng Jie’ao em `683,371(21)`.',
        '**Feng Jie’ao: Decisão final** — fale com Feng Jie’ao e depois com o Matador de Feras em `545,653(24)`.',
        '**Feng Jie’ao: Retorno** — fale com Feng Jie’ao, vá a `645,834(21)`, fale com ele e depois com o Boticário Borgus Iliter em `639,830(21)`.',
        '**Feng Jie’ao: Inspiração** — fale com Feng Jie’ao, vá a `725,922(22)` e fale com o Capitão Jack.',
        '**Brilho misterioso** — fale com Feng Jie’ao a cada parada: `742,921(24)`, `759,921(24)` e `777,924(25)`. Depois cave o Encaixe misterioso em `777,935(25)` pelo Pingente.',
        '**Feng Jie’ao: Revelação** — fale com Feng Jie’ao e use a ação *refletir*.',
        '**Feng Jie’ao: Vingança** — fale com Feng Jie’ao, vá a `733,946(22)` e fale com Weno Giu em `730,947(23)`.',
        '**Feng Jie’ao: Emboscada** — fale com Feng Jie’ao e vá a `737,949(22)`.',
        '**Feng Jie’ao: Assassinato** — fale com Feng Jie’ao e derrote o Mago da Aparição que é invocado.',
        '**Feng Jie’ao: Convocação** — fale com Feng Jie’ao e volte ao Nanko Ki, em `750,887(27)`.',
        '**Feng Jie’ao: Missão** — fale com Nanko Ki, vá a `737,947(23)`, derrote 5 Monges do Apocalipce, fale com Feng Jie’ao, vá a `731,955(22)`, fale com ele e espere 10 segundos.',
        '**Feng Jie’ao: Missão cumprida** — fale com Feng Jie’ao e depois com Nanko Ki em `750,887(27)`.',
        '**Feng Jie’ao: Mundo real** — fale com a Anciã da Névoa Sombria em `754,851(28)`.',
    ],
})

SAGAS.append({
    'slug': 'ceifador',
    'classe': 'Ceifador',
    'heroi': 'Tianshou',
    'ovo': 'Ovo de Mascote Tianshou Pequeno',
    'titulo': 'Outono do Mundo',
    'resumo': 'A mais recente das dezessete, e quase toda dentro do Pátio de '
              'Exercício. Conta a vida de Tianshou — o selo, o massacre, os três '
              'amigos — e termina de volta no Pináculo do Despertar.',
    'comecar': 'Abra a Saga do Herói, clique no Ceifador e vá a `156,260(13)`.',
    'avisos': [
        '**Saiu do Pátio de Exercício? Fale com a Lenda de Tianshou**, em '
        '`149,244(13)`, no Pináculo do Despertar, e escolha *Local de Cultivo*.',
        '**O Xiaoyi fica em cima de um tronco.** Em `169,275(16)` é preciso girar a '
        'câmera ou subir até a altura certa para vê-lo.',
        '**Em *Vestígio* você escreve na tela:** `Caçador Celestial`.',
    ],
    'passos': [
        '**Encontro Inesperado** — vá a `156,260(13)` e espere a cena.',
        '**Objeto Perdido** — fale com o Espírito Encantado de Passagem em `159,262(13)`, no Vale das Ilusões, cave a bolsa em `158,262(13)` pelo Sachê de Perfume Caído e fale com ele. Depois vá a `158,266(13)` e a `166,272(13)`.',
        '**Saga de Tianshou: Ceifador** — fale com Xiaoyi em `169,275(16)`, **em cima de um tronco**, e clique no Manuscrito Fragmentado no inventário.',
        '**Saga de Tianshou: Origem** — fale com Xiaoyi em `169,275(16)` e espere o teleporte para o Pátio de Exercício.',
        '**Saga de Tianshou: Abismo** — vá a `389,409(27)`, dentro do Pátio, e fale com Xiaoyi.',
        '**Terra Desconhecida** — vá a `427,423(11)`, espere, fale com Tianshou e aguarde cerca de 25 segundos até os NPCs chegarem.',
        '**Velho Conhecido** — fale com Qitao em `428,424(11)`.',
        '**Retorno ao Mundo** — fale com Canzi em `369,428(12)` e espere.',
        '**Saga de Tianshou: Perda** — vá a `374,432(12)` e espere a história.',
        '**Saga de Tianshou: Massacre** — vá a `439,481(14)` e fale com o Oficial conversando; depois com o Oficial nervoso em `434,480(14)`, com O grande sábio Sun Zhihuai em `436,483(14)` e com a Imperatriz em `436,485(14)`. Confirme os popups.',
        '**Saga de Tianshou: Conflito** — conclui sozinha.',
        '**Saga de Tianshou: Amigo** — fale com Jiuji em `420,427(11)`.',
        '**Saga de Tianshou: Alegria** — vá a `426,424(11)`, pegue o livro sobre a mesa pela Mensagem, clique nela no inventário e vá a `427,421(11)`.',
        '**Saga de Tianshou: Garoa** — fale com Momida em `418,422(11)`.',
        '**Saga de Tianshou: Neve** — fale com Qitao em `430,423(11)` e espere a história.',
        '**Aurora e Crepúsculo** — conclui sozinha.',
        '**Saga de Tianshou: Batalha** — conclui sozinha.',
        '**Saga de Tianshou: Fim** — fale com Momida em `400,407(31)`: você vira um Ceifador e precisa derrotar o mob Momida ali mesmo.',
        '**Saga de Tianshou: Sacrifício** — derrote 20 mobs *Aparição* perto de `400,407(31)`.',
        '**Graça e Encontro** — fale com a Senhora em `427,424(11)`.',
        '**Construindo um Lar** — fale com Tianshou em `427,424(11)`.',
        '**Saga de Tianshou: Sozinho** — fale com Qitao em `428,425(11)` e espere a história.',
        '**Saga de Tianshou: Confronto** — fale com Tianshou em `388,410(27)`.',
        '**Saga de Tianshou: Chunchu** — fale com Canzi em `369,428(12)`.',
        '**Saga de Tianshou: Caos** — conclui sozinha.',
        '**Saga de Tianshou: Despertar** — fale com Tianshou em `388,406(28)`.',
        '**Saga de Tianshou: Dúvida** — fale com Tianshou em `388,406(28)`.',
        '**Saga de Tianshou: Causa** — fale com Xiaoyi em `388,406(28)`, cave o Pó Estranho ali mesmo e volte a ele.',
        '**Saga de Tianshou: Culpado** — fale com Xiaoyi em `388,406(28)`.',
        '**Saga de Tianshou: Regras** — fale com o Discípulo do Ceifador em `388,406(28)`, use a ação *refletir* e fale com Tianshou.',
        '**Transformação** — fale com Tianshou em `388,406(28)` e espere 5 segundos.',
        '**Retrospectiva** — fale com Xiaoyi em `388,406(28)`.',
        '**Saga de Tianshou: Melancolia** — fale com Tianshou em `403,407(31)`.',
        '**Saga de Tianshou: Vestígio** — fale com Xiaoyi em `401,406(31)`, escreva **Caçador Celestial** e envie. Feche falando com o Estudante.',
        '**Saga de Tianshou: Nascimento** — fale com Xiaoyi em `401,406(31)` e espere o teleporte de volta ao mapa principal.',
        '**Saga de Tianshou: Passado** — fale com Tianshou em `147,245(13)`, no Pináculo do Despertar, use a Página de papel desgastada do inventário e fale com ele outra vez.',
        '**Saga de Tianshou: Início** — vá a `122,236(13)` e fale com Tianshou.',
        '**Saga de Tianshou: Herança** — fale com Xiaoyi em `123,237(13)`.',
        '**Saga de Tianshou: Fim** — conclui sozinha.',
    ],
    'nota': '**As fontes discordam sobre esta.** Em português o ovo é o do *Tianshou '
            'Pequeno* e o título é *Outono do Mundo*; a PWpedia, em inglês, registra '
            '*Tevin Pet Egg* e *Undefeated* para a mesma classe. Não são traduções '
            'uma da outra, então ou são sagas diferentes entre as versões, ou o '
            'Ceifador não é o *Edgerunner*. Ficamos com a versão em português, que é '
            'a do nosso cliente — mas fica escrito.',
})
