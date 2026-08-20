"""
Roda qualquer query do pacote sem PostgreSQL.

O repositorio nasceu para PostgreSQL, e o schema continua sendo o de producao.
Mas exigir um banco no ar para ver o resultado de uma query e uma barreira que
nao entrega nada: quem abre o repositorio quer ler o SQL e ver o que ele
devolve. O DuckDB le o MESMO `data/schema.sql` e o MESMO `data/seed.sql`, em
memoria, sem instalar servidor.

    python tools/run_query.py                          # lista as queries
    python tools/run_query.py 01                       # imprime o resultado
    python tools/run_query.py 01 --png docs/img/01.png # gera a imagem do README

A unica diferenca em relacao ao PostgreSQL e o tipo `SERIAL`, que o DuckDB nao
tem: ele vira `INTEGER` na carga. Nenhuma query e reescrita — se precisasse
reescrever, o exercicio perderia a graca.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import duckdb

ROOT    = Path(__file__).resolve().parent.parent
SCHEMA  = ROOT / "data" / "schema.sql"
SEED    = ROOT / "data" / "seed.sql"
QUERIES = ROOT / "queries"


# Mapa de padroes do to_char do PostgreSQL para o strftime do DuckDB. A ordem
# importa: YYYY antes de MM, senao o "YY" de dentro de "YYYY" seria consumido.
# Sentinela para proteger o literal entre aspas. Qualquer caractere que nao
# apareca num formato de data serve.
_SENT = "\x01"

_TO_CHAR = [
    ("YYYY", "%Y"), ("MM", "%m"), ("DD", "%d"),
    ("HH24", "%H"), ("MI", "%M"), ("SS", "%S"),
]


def _to_char(valor, fmt: str) -> str:
    """Implementa o to_char(data, formato) do PostgreSQL.

    O DuckDB nao tem `to_char`, e duas das dez queries usam — justamente a 03
    (cohort trimestral) e a 07 (crescimento mensal), que sao as que alguem
    abriria primeiro. A alternativa era reescrever as duas para strftime, mas o
    schema deste pacote e de PostgreSQL e o README promete que nenhuma query e
    reescrita para rodar aqui. Entao o que se adapta e o motor, nao a consulta.

    Trata o literal entre aspas do PostgreSQL ('YYYY "Q"Q') com um sentinela,
    senao o Q literal seria substituido junto com o Q de trimestre.
    """
    if valor is None:
        return None
    fora = []

    def _guardar(m):
        fora.append(m.group(1))
        return f"{_SENT}{len(fora) - 1}{_SENT}"

    saida = re.sub(r'"([^"]*)"', _guardar, fmt)
    for pg, py in _TO_CHAR:
        saida = saida.replace(pg, valor.strftime(py))
    # Q (trimestre) nao existe no strftime; e conta sobre o mes.
    saida = saida.replace("Q", str((valor.month - 1) // 3 + 1))
    for i, literal in enumerate(fora):
        saida = saida.replace(f"{_SENT}{i}{_SENT}", literal)
    return saida


def load_db() -> duckdb.DuckDBPyConnection:
    con = duckdb.connect(":memory:")
    # Assinatura por nome de tipo: `duckdb.typing` nao existe em todas as
    # versoes do pacote, e o repositorio nao fixa a versao do DuckDB.
    con.create_function("to_char", _to_char, ["TIMESTAMP", "VARCHAR"], "VARCHAR")
    ddl = SCHEMA.read_text(encoding="utf-8")
    ddl = re.sub(r"\bSERIAL\b", "INTEGER", ddl)
    con.execute(ddl)
    seed = SEED.read_text(encoding="utf-8")
    # `setval` reposiciona a sequencia do SERIAL depois da carga — sem SERIAL,
    # nao ha sequencia para reposicionar. As linhas ja trazem id explicito.
    seed = re.sub(r"^SELECT setval\(.*$", "", seed, flags=re.M)
    con.execute(seed)
    return con


def find_query(prefix: str) -> Path:
    hits = sorted(QUERIES.glob(f"{prefix}*.sql"))
    if not hits:
        sys.exit(f"nenhuma query comeca com {prefix!r} em {QUERIES}")
    return hits[0]


def to_png(df, dest: Path, titulo: str, subtitulo: str) -> None:
    """Renderiza o resultado como tabela. Sem print de terminal: o que vai para o
    README e o dado, nao a janela onde ele foi digitado."""
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    INK, INK_MUT, LINE, BAND = "#1B1D21", "#5B616B", "#E5E8EC", "#F6F8FA"

    n_rows, n_cols = len(df), len(df.columns)
    fig_w = min(2.0 + n_cols * 1.9, 16)
    fig_h = 1.5 + n_rows * 0.42
    fig, ax = plt.subplots(figsize=(fig_w, fig_h), dpi=200)
    ax.axis("off")
    fig.patch.set_facecolor("white")

    fig.text(0.02, 0.965, titulo, ha="left", va="top",
             fontsize=13, fontweight="bold", color=INK)
    fig.text(0.02, 0.905, subtitulo, ha="left", va="top", fontsize=9, color=INK_MUT)

    tabela = ax.table(
        cellText=[[f"{v}" for v in row] for row in df.itertuples(index=False)],
        colLabels=[c.replace("_", " ") for c in df.columns],
        cellLoc="right", colLoc="right", loc="upper center",
        bbox=[0, 0, 1, 0.86],
    )
    tabela.auto_set_font_size(False)
    tabela.set_fontsize(9)
    for (linha, coluna), celula in tabela.get_celld().items():
        celula.set_linewidth(0)
        celula.set_edgecolor(LINE)
        if linha == 0:
            celula.set_text_props(color=INK_MUT, fontweight="bold")
            celula.set_facecolor("white")
            celula.visible_edges = "B"
            celula.set_linewidth(1)
        else:
            celula.set_text_props(color=INK)
            # Faixa alternada: em tabela longa o olho perde a linha no caminho.
            celula.set_facecolor(BAND if linha % 2 == 0 else "white")
        if coluna == 0:
            celula.set_text_props(ha="left")

    dest.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(dest, bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print(f"PNG: {dest.relative_to(ROOT)}")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("query", nargs="?", help="prefixo do arquivo, ex.: 01")
    ap.add_argument("--png", help="tambem grava o resultado como imagem")
    args = ap.parse_args()

    if not args.query:
        print("Queries disponiveis:\n")
        for f in sorted(QUERIES.glob("*.sql")):
            print(f"  {f.stem}")
        return

    caminho = find_query(args.query)
    sql = caminho.read_text(encoding="utf-8")
    con = load_db()
    df = con.execute(sql).fetchdf()

    print(f"\n{caminho.name}\n{'=' * len(caminho.name)}")
    print(df.to_string(index=False))
    print(f"\n{len(df)} linhas")

    if args.png:
        # A primeira linha de comentario da query e o titulo; a que comeca com
        # "Objetivo:" vira o subtitulo.
        linhas = [l.strip("- ").strip() for l in sql.splitlines() if l.startswith("--")]
        titulo = next((l for l in linhas if l.endswith(".sql")), caminho.name)
        titulo = titulo.replace(".sql", "").split("_", 1)[-1].replace("_", " ").capitalize()
        # O objetivo costuma ocupar duas ou tres linhas de comentario; pegar so a
        # primeira corta a frase no meio ("...receita gerada e").
        objetivo = ""
        for i, l in enumerate(linhas):
            if l.lower().startswith("objetivo"):
                resto = []
                for prox in linhas[i + 1:]:
                    if not prox or set(prox) <= {"=", "-"}:
                        break
                    resto.append(prox)
                objetivo = " ".join([l] + resto)
                break
        to_png(df, ROOT / args.png, titulo, objetivo or "resultado sobre o seed do repositório")


if __name__ == "__main__":
    main()
