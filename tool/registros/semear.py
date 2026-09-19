#!/usr/bin/env python3
"""Lê a planilha dos registros e escreve o SQL que semeia a tabela.

A planilha é a única fonte dos bônus: a cadeia no jogo é
`Página de Registro: Assimilação` → `Registro: <lugar>` → títulos → atributos,
e o banco do The Classic indexa **itens**, não títulos — procurar
"Mestre Desbravador" lá responde "Nenhum item encontrado". Então os números
existem só onde alguém os digitou.

Depois desta carga a planilha sai de cena e a tabela passa a ser a fonte.
Este script fica versionado para a carga ser refazível, não para ser rotina.

    python3 tool/registros/semear.py > registros.sql
"""

import html
import io
import re
import sys
import unicodedata
import urllib.request
import zipfile

PLANILHA = "1nN0cUkxMXS3eOP8ajNpGJjGZWDAgXP3VJLD7LwV-IOA"

# Como cada aba se chama no jogo. A planilha abrevia duas delas, e é o nome do
# NPC que a pessoa vai procurar na tela.
NOMES_DE_ABA = {
    "Area 1": "Área 1",
    "Area 2": "Área 2",
    "Coletar": "Coletar",
    "Avançado": "Avançado",
    "MA": "M/A",
    "Casal": "Casal",
}

# As sete colunas de atributo, na ordem em que a tela as mostra.
ATRIBUTOS = {
    "atk f": "atk_f",
    "atk m": "atk_m",
    "def f": "def_f",
    "def m": "def_m",
    "acerto": "acerto",
    "esquiva": "esquiva",
    "hp": "hp",
}

# Tolerante de propósito: o texto é escrito à mão e traz "Atk f" minúsculo,
# "Def F + 29" com espaço, "esquiva" sem maiúscula e ponto no lugar da vírgula.
BONUS = re.compile(
    r"(atk\s+[fm]|def\s+[fm]|acerto|esquiva|hp)\s*\+?\s*(\d+)"
)


def sem_acento(texto):
    decomposto = unicodedata.normalize("NFD", texto.lower())
    return "".join(c for c in decomposto if unicodedata.category(c) != "Mn")


def baixar_planilha():
    url = f"https://docs.google.com/spreadsheets/d/{PLANILHA}/export?format=xlsx"
    pedido = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(pedido, timeout=60) as resposta:
        return zipfile.ZipFile(io.BytesIO(resposta.read()))


def abas(livro):
    """Cada aba do caderno, na ordem em que a planilha as guarda.

    Pelo caderno inteiro e não por `export?format=csv`, que devolve uma aba só
    — foi assim que a primeira leitura relatou seis abas como se fosse uma.
    """
    wb = livro.read("xl/workbook.xml").decode("utf-8")
    rels = dict(
        re.findall(
            r'Id="rId(\d+)"[^>]*Target="(worksheets/sheet\d+\.xml)"',
            livro.read("xl/_rels/workbook.xml.rels").decode("utf-8"),
        )
    )
    partilhadas = [
        "".join(re.findall(r"<t[^>]*>([^<]*)</t>", bloco))
        for bloco in re.findall(
            r"<si>(.*?)</si>",
            livro.read("xl/sharedStrings.xml").decode("utf-8"),
            re.S,
        )
    ]

    for nome, _, rid in re.findall(
        r'<sheet state="visible" name="([^"]+)" sheetId="(\d+)" r:id="rId(\d+)"', wb
    ):
        xml = livro.read("xl/" + rels[rid]).decode("utf-8")
        linhas = []
        for linha in re.findall(r"<row[^>]*>(.*?)</row>", xml, re.S):
            celulas = {}
            for c in re.finditer(r'<c r="([A-Z]+)\d+"([^>]*)>(.*?)</c>', linha, re.S):
                valor = re.search(r"<v>([^<]*)</v>", c.group(3))
                if not valor:
                    continue
                cru = (
                    partilhadas[int(valor.group(1))]
                    if 't="s"' in c.group(2)
                    else valor.group(1)
                )
                celulas[c.group(1)] = html.unescape(cru).strip()
            if celulas:
                linhas.append(celulas)
        yield nome, linhas


def ler_bonus(texto):
    """Os sete atributos, ou None quando o texto não diz nada de útil.

    Devolver None é o que vira `sem_dados` na tabela, e a diferença importa:
    uma fileira de zeros **afirma** que a receita não dá nada, e ninguém
    conferiu isso. Zero é resposta; ausência é confissão.
    """
    if not texto:
        return None

    achados = BONUS.findall(sem_acento(texto))
    if not achados:
        return None

    # O que sobrou depois de tirar tudo que foi entendido. Se sobrar conteúdo,
    # o texto diz algo que este script não sabe ler — e calar seria pior.
    resto = re.sub(r"[\s,.\-+]", "", BONUS.sub("", sem_acento(texto)))
    if resto:
        print(f"-- AVISO: não entendi {resto!r} em {texto!r}", file=sys.stderr)

    pontos = dict.fromkeys(ATRIBUTOS.values(), 0)
    for atributo, valor in achados:
        pontos[ATRIBUTOS[re.sub(r"\s+", " ", atributo)]] = int(valor)
    return pontos


def aspas(texto):
    return "'" + texto.replace("'", "''") + "'"


def main():
    livro = baixar_planilha()
    linhas_sql, vazias, total = [], 0, 0

    for nome_aba, linhas in abas(livro):
        aba = NOMES_DE_ABA.get(nome_aba, nome_aba)
        ordem = 0
        for celulas in linhas:
            receita = celulas.get("A", "")
            if not receita.startswith("Registro"):
                continue
            ordem += 1
            total += 1

            # Casal guarda a contagem em B; as demais põem o bônus em B e a
            # contagem em C.
            if nome_aba == "Casal":
                texto_bonus, paginas = "", celulas.get("B")
            else:
                texto_bonus, paginas = celulas.get("B", ""), celulas.get("C")

            pontos = ler_bonus(texto_bonus)
            if pontos is None:
                vazias += 1

            colunas = [
                aspas(aba),
                str(ordem),
                aspas(" ".join(receita.split())),
                str(int(float(paginas))) if paginas else "null",
                "true" if pontos is None else "false",
                *[str(pontos[c]) if pontos else "0" for c in ATRIBUTOS.values()],
            ]
            linhas_sql.append("  (" + ", ".join(colunas) + ")")

    print("-- Gerado por tool/registros/semear.py. Não edite à mão: para")
    print("-- corrigir um valor, edite a linha no painel do Supabase.")
    print(f"-- {total} receitas, {vazias} ainda sem bônus conhecido.")
    print()
    print("insert into public.registros")
    print("  (aba, ordem, nome, paginas, sem_dados,")
    print("   " + ", ".join(ATRIBUTOS.values()) + ")")
    print("values")
    print(",\n".join(linhas_sql) + ";")

    print(f"\n-- {total} receitas · {vazias} sem bônus", file=sys.stderr)


if __name__ == "__main__":
    main()
