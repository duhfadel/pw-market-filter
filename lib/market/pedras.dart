/// As pedras de encaixe, por id.
///
/// **Escrita à mão, como `card_combos.dart`, e pelo mesmo motivo**: é uma
/// coisa que o índice não consegue dar. A página do personagem traz a pedra
/// como imagem e como texto, mas o coletor guarda só o id — e ensiná-lo a
/// guardar o nome carimbaria todo o estado como velho, obrigando a reler
/// 1.666 páginas do servidor deles por 79 nomes que são do jogo e não do
/// mercado.
///
/// `tool/pedras.dart` colhe-os em 32 páginas e imprime esta tabela; o que
/// está aqui foi conferido à mão antes de entrar.
///
/// **O texto é o que a página mostra, junto.** `Pedra do Olho Vermelho Ataque
/// +75` é uma linha só no tooltip, e separar o nome do efeito exigiria
/// adivinhar onde um acaba — a regra desta casa é imprimir o que o site
/// imprime.
///
/// Uma pedra que não esteja aqui desenha a arte sem legenda, nunca um nome
/// inventado. `pedras_test` confere os ids do mercado contra esta tabela e
/// **avisa sem reprovar**: pedra nova é facto sobre o mercado deles, não
/// defeito nosso — a mesma linha que `confirmedCountedItems` já traça.
///
/// **Quatro coisas que a colheita mostrou e que vale conhecer antes de
/// estranhar um nome na tela.** Sete pedras saem do jogo sem tradução —
/// `TS_p02 Ataque +75` é o que a página imprime, e inventar-lhes um nome
/// seria pior do que repetir o que lá está. Duas pedras têm nome repetido em
/// ids diferentes — `Pedra de Nu Wa` é 12637 e 200376 —, exactamente como as
/// runas, onde `Áurea 5` também é dois ids. Os dez `Espírito` só se
/// distinguem pelo nível, e quatro deles dizem `Nível 0`, portanto o texto
/// não os separa. E `Pedra da Sabedoria Atributo #3806 +4` carrega um
/// atributo que o próprio site não sabe nomear, impresso como o número — que
/// é a regra desta casa a funcionar, não um defeito.
///
/// Uma pedra ficou de fora, `38404`: ninguém das 32 páginas a mostrou com
/// tooltip. Desenha a arte sem legenda, que é o recuo certo.
const nomesDasPedras = <int, String>{
  1998: 'TS_p02 Ataque +75',
  2000: 'TS_p04 Ataque +100',
  2003: 'TS_q02 Ataque Mágico +75',
  2004: 'TS_q03 Ataque Mágico +100',
  2012: 'TS_s01 Ataque mágico com madeira e dano contínuo. +25',
  2013: 'TS_s02 HP +115',
  2014: 'TS_s03 HP +150',
  6367: 'Pedra Vermelha Ardente Nv. 7 Def +41',
  6368: 'Pedra Vermelha Ardente Nv.8 Def +53',
  6370: 'Pedra Vermelha Ardente Nv.9 Ataque +40',
  6385: 'Pedra Amarela Nv.7 HP +40',
  6387: 'Pedra Amarela Nv.9 HP +62',
  12637: 'Pedra de Nu Wa Constituição +10',
  12638: 'Pedra de Xuan Yuan Constituição +10',
  21377: 'Diamante do Tigre Nível de Ataque +1',
  21378: 'Diamante do Dragão Nível de Defesa +1',
  25154: 'Jade Preciosa Nível de Defesa +2',
  38153: 'Pedra da Divindade Nível de Ataque +2',
  38154: 'Pedra do Demônio Nível de Ataque +3',
  38155: 'Pedra da Serenidade Nível de Defesa +3',
  38405: 'Pedra Amarela Nv.10 HP +75',
  38406: 'Pedra Vermelha Ardente Nv.10 Def +85',
  40987: 'Frag Vermelho-granada Comum Def +20',
  40988: 'Fragmento Granada Lindo Def +33',
  40989: 'Frag Vermelho-granada Imaculado Def +53',
  40991: 'Fragmento de Safira Comum Ataque Mágico +12',
  40992: 'Fragmento de Safira Lindo Ataque Mágico +20',
  40993: 'Fragmento de Safira Imaculado Ataque Mágico +32',
  40995: 'Fragmento Citrino Comum HP +20',
  40996: 'Fragmento Citrino Lindo HP +32',
  40997: 'Fragmento Citrino Imaculado HP +50',
  47256: 'Pedra Luminosa Avançada Defesa Física +80',
  47257: 'Pedra Luminosa Perfeita Defesa Física +100',
  47259: 'Pedra da Benção Defesa Física + 160',
  47261: 'Pedra da Inundação Avançada Defesa Elemental +80',
  47264: 'Pedra Divina Defesa Elemental +160',
  47266: 'Pedra de Sangue Avançada Constituição +8',
  47267: 'Pedra de Sangue Perfeita Constituição +10',
  47268: 'Pedra do Brilho Solar Constituição +13',
  47269: 'Pedra do Céu Vermelho Constituição +16',
  47271: 'Pedra da Clareza Avançada Espiríto +16',
  47272: 'Pedra da Clareza Perfeita Espiríto +20',
  47273: 'Pedra Astral Espiríto +25',
  47274: 'Pedra da Ravina Espiríto +32',
  47275: 'Pedra do Combate Nível de Ataque +1',
  47276: 'Pedra da Perfeição Nível de Ataque +2',
  47277: 'Pedra da Proteção Nível de Defesa +1',
  47278: 'Pedra do Soberano Nível de Defesa +2',
  51111: 'Pedra da Nevasca Ataque Mágico +75',
  51112: 'Pedra do Olho Vermelho Def +125',
  51113: 'Pedra Verdejante HP +115',
  58680: 'Pedra do Brilho Flamejante Ataque +130',
  58681: 'Pedra da Essência Gélida Ataque Mágico +130',
  58682: 'Pedra dos Princípios Canalização +4',
  58683: 'Pedra do Esplen. Ociden. Canalização +5',
  58684: 'Pedra do Primogênito Constituição +12',
  58685: 'Pedra dos Primórdios Crítico +3',
  58686: 'Pedra Suprema Frouxo: Reduz a velocidade de invocação do alvo. +200',
  59713: '【Cristal do Luar】',
  59758: 'Espírito Nobre: Nível 0',
  59759: 'Espírito Nobre: Nível 0',
  59760: 'Espírito Nobre: Nível 0',
  59761: 'Espírito Nobre: Nível 0',
  59763: 'Espírito Real: Nível 1',
  59764: 'Espírito Real: Nível 3',
  59765: 'Espírito Real: Nível 3',
  59766: 'Espírito Real: Nível 1',
  59767: 'Espírito Sagrado: Nível 2',
  62130: '【Cristal do Luar】',
  68151: 'Pedra Bi Fang Defesa física +200',
  68152: 'Pedra Zhu Yin Defesa Elemental +200',
  68153: 'Pedra de Zhong Hua Constituição +20',
  68154: 'Pedra de Coragem Espírito +48',
  68155: 'Pedra de Yan Luo Nível de ataque +3',
  68156: 'Pedra de Montanha Nível de defesa +3',
  78141: 'Pedra da Sabedoria Atributo #3806 +4',
  78143: 'Pedra do Despertar',
  200376: 'Pedra de Nu Wa Constituição +10',
  200377: 'Pedra de Xuan Yuan Constituição +10',
};
