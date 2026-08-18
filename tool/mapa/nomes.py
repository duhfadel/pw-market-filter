"""Da minha região ao número e ao nome que o jogador vê.

A ponte é o mapa da wiki, em inglês: cada região minha tem um nome inglês, e a
legenda do 1.8.7 dá o nome português na ordem 01-52. A maioria é tradução
direta, o que torna o par verificável em vez de adivinhado - "Grande Muralha
Ancestral" só pode ser Ancient Wall.

`incerto` marca os pares que dependem de interpretação, não de tradução.
"""

# minha região → nome inglês (lido do mapa da wiki)
INGLES = {
    1:'The Harshlands', 8:'The Frozen Path', 3:'Avalanche Canyon',
    4:'Thousand Wood Ridge', 5:'Haunted Path', 6:'City of Misfortune',
    7:'Dawnglory', 9:'Ancient Peak', 10:'City of a Thousand Streams',
    12:'Broken Plain', 13:'Etherblade', 14:'Mount Lantern',
    16:'Immolation Camp', 17:'Windswept Grasslands', 18:'Plain of Farewells',
    19:'Tradewind Village', 21:'Dragon Wilderness', 22:'City of the Lost',
    23:'Silk Ridge', 24:'Wellspring Village', 25:'Archosaur',
    26:'Fragrant Hills', 27:'Sundown Highland', 28:'Courage Path',
    29:'The Great Lake', 30:'Dribbling Spring', 31:"Dragon's End",
    33:'Stairway to Heaven', 34:'Hidden Orchid', 35:'Sanctuary',
    36:'Deserted Sea', 37:'Vibrant Cliffs', 38:'City of the Plume',
    39:'Swamp of the Wraiths', 40:'Forest of Haze', 41:'Buried Bones',
    43:"King's Feast", 45:'Southern Stronghold', 47:'The White Ridge',
    48:'Black Mountain', 49:'Dreaming Cloud', 50:'Dreamweaver Port',
    51:'The Fissure', 52:'Starry Wilds', 53:'Tellus City',
    54:'Snowdragon Heights', 55:'Island of Broken Dreams',
    56:'Shattered Cloud Island', 57:'City of Raging Tides',
    101:'Walled Stronghold', 102:'Shining Tidewood', 104:'Ancient Wall',
}

# número do jogo → (nome português, inglês correspondente, é capital)
LEGENDA = [
    (1,'Terra Congelada','The Harshlands',0), (2,'Terra Gelada','The Frozen Path',0),
    (3,'Garganta da Avalanche','Avalanche Canyon',0), (4,'Montanha das Árvores','Thousand Wood Ridge',0),
    (5,'Terra de Hades','Haunted Path',0), (6,'Cidade da Perdição','City of Misfortune',0),
    (7,'Cidade Universal','City of a Thousand Streams',1), (8,'Grande Muralha Ancestral','Ancient Wall',0),
    (9,'Planície da Vitória','Broken Plain',0), (10,'Cidade das Espadas','Etherblade',1),
    (11,'Cidade Quadrada','Walled Stronghold',0), (12,'Montanha Desolada','Ancient Peak',0),
    (13,'Vila do Fogo','Immolation Camp',0), (14,'Campo dos Lírios','Plain of Farewells',0),
    (15,'Campo dos Ventos','Windswept Grasslands',0), (16,'Cidade do Vento Alísio','Tradewind Village',0),
    (17,'Tumba Verdejante','Shining Tidewood',0), (18,'Montanha do Farol','Mount Lantern',0),
    (19,'Terra dos Dragões','Dragon Wilderness',0), (20,'Planalto do Pôr-do-Sol','Sundown Highland',0),
    (21,'Nascente Fraca','Dribbling Spring',0), (22,'Cidade das Feras','City of the Lost',1),
    (23,'Declive do Dragão',"Dragon's End",0), (24,'Montanha da Seda','Silk Ridge',0),
    (25,'Cidade do Rio','Wellspring Village',0), (26,'Lago Celeste','The Great Lake',0),
    (27,'Cidade do Dragão','Archosaur',1), (28,'Vale das Orquídeas','Hidden Orchid',0),
    (29,'Monte Perfumado','Fragrant Hills',0), (30,'Castelo Flor de Pessegueiro','Sanctuary',0),
    (31,'Mar de Areia','Deserted Sea',0), (32,'Montanha dos Cisnes','Vibrant Cliffs',0),
    (33,'Caminho da Alegria','Courage Path',0), (34,'Cidade das Plumas','City of the Plume',1),
    (35,'Rochedo Celeste','Stairway to Heaven',0), (36,'Reino do Yu',"King's Feast",0),
    (37,'Pântano Desalmado','Swamp of the Wraiths',0), (38,'Selva Obscura','Forest of Haze',0),
    (39,'Cemitério','Buried Bones',0), (40,'Monte Nanping','Southern Stronghold',0),
    (41,'Montanha Branca','The White Ridge',0), (42,'Montanha Negra','Black Mountain',0),
    (43,'Montanha dos Sonhos','Dreaming Cloud',0), (44,'Porto dos Sonhos','Dreamweaver Port',1),
    (45,'Ilha Cirrus','Shattered Cloud Island',0), (46,'Ilha do Pesadelo','Island of Broken Dreams',0),
    (47,'Cidade das Tormentas','City of Raging Tides',1), (48,'A Fenda','The Fissure',0),
    (49,'Selva Estrelada','Starry Wilds',0), (50,'Cidade de Tellus','Tellus City',1),
    (51,'Montanha do Dragão de Gelo','Snowdragon Heights',0), (52,'Cidade da Névoa Sombria','Dawnglory',1),
]

# pares que dependem de interpretação e não de tradução direta
INCERTOS = {1, 2, 5, 11, 12, 17, 25, 30, 32, 35, 36, 45}

if __name__ == '__main__':
    por_ingles = {ing: (n, pt, cap) for n, pt, ing, cap in LEGENDA}
    faltando = [i for i in INGLES.values() if i not in por_ingles]
    sobrando = [i for i in por_ingles if i not in INGLES.values()]
    print(f'{len(INGLES)} regiões · {len(LEGENDA)} números na legenda')
    print('inglês sem par:', faltando or 'nenhum')
    print('legenda sem par:', sobrando or 'nenhum')
    saida = {}
    for reg, ing in INGLES.items():
        n, pt, cap = por_ingles[ing]
        saida[reg] = {'n': n, 'nome': pt, 'ingles': ing, 'capital': bool(cap),
                      'incerto': n in INCERTOS}
    import json; json.dump(saida, open('nomes.json', 'w'), ensure_ascii=False, indent=1)
    print(f'{sum(1 for v in saida.values() if v["incerto"])} pares marcados como incertos')
