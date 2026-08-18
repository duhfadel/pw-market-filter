# Brasões das guildas

Uma arte por guilda, e o nome do arquivo vai na coluna `brasao` da tabela
`guildas`, no Supabase. Não há lista aqui dentro que precise ser mantida: a
página pede `icones/<o que estiver na coluna>`.

**Quadrado, fundo transparente, PNG ou SVG.** No mapa o brasão é desenhado
entre 10 e 20 px de lado — o tamanho sai da forma do território, calculado por
`tool/mapa/ancoras.py` — então o que sobrevive ali é silhueta e cor, não
detalhe. Vale olhar a arte reduzida a 20 px antes de subir.

Um `brasao` vazio, ou um arquivo que não existe, deixa o território com a cor
da guilda e sem símbolo. Nunca quebra o mapa: é por isso que a coluna pode
ficar em branco enquanto a arte não fica pronta.

Acrescentar uma arte nova é um commit e um deploy de uns três minutos — é a
única parte das guerras que ainda passa por CI, e é a que muda menos. Trocar
qual arquivo uma guilda usa continua sendo editar uma linha no painel.
