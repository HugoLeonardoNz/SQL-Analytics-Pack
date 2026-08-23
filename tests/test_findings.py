"""
Os números do findings.md, como asserção — SQL Analytics Pack

Execute com: pytest tests/ -v

POR QUE ESTE ARQUIVO EXISTE
---------------------------
`analysis/findings.md` cita dezenas de números tirados das dez queries: churn de
36,7% no plano básico, Betim com 27,43% da receita, Contagem com 34,1% de churn,
R$ 37.909,10 vencidos há mais de 90 dias, 174 contratos com sinal de risco.

O repositório já tinha `dbt test` cobrindo o MODELO (chaves, nulos, aceitos),
mas nada cobrindo as CONCLUSÕES. São coisas diferentes: o schema pode estar
íntegro e o texto continuar citando um número que a query deixou de devolver.

Este é o defeito mais caro deste portfólio e ele aconteceu de verdade em outros
repositórios: o texto e o código divergirem em silêncio porque número em Markdown
não executa. Aqui ele executa — as queries reais, sobre o mesmo seed, via DuckDB.

O DuckDB lê o MESMO `data/schema.sql` e o MESMO `data/seed.sql` do PostgreSQL,
em memória. Nenhuma query é reescrita: se precisasse reescrever, o teste estaria
verificando outra coisa.
"""

import os
import sys

import pytest

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, RAIZ)

from tools.run_query import load_db, find_query, QUERIES  # noqa: E402


@pytest.fixture(scope="module")
def con():
    """Uma carga so para todos os testes: mesmo schema.sql e mesmo seed.sql
    que o PostgreSQL usa, em memoria."""
    return load_db()


def _df(con, prefixo):
    """Roda a query real, sem reescrever nada — reescrever verificaria outra coisa."""
    sql = find_query(prefixo).read_text(encoding="utf-8")
    return con.execute(sql).fetchdf()


# ── 01 · Receita por cidade ───────────────────────────────────────────────────

def test_betim_lidera_receita(con):
    """findings.md: "Betim (27,4%)" como cidade de maior receita."""
    d = _df(con, "01")
    top = d.iloc[0]
    assert top["cidade"] == "Betim", f"Maior receita virou {top['cidade']}"
    assert 27.0 <= float(top["pct_receita"]) <= 27.9, (
        f"Betim com {top['pct_receita']}% da receita; o texto diz 27,43%"
    )


def test_duas_maiores_cidades_concentram_metade(con):
    """findings.md: "Betim e Contagem juntas respondem por 51,6% do MRR"."""
    d = _df(con, "01")
    duas = float(d.iloc[0]["pct_receita"]) + float(d.iloc[1]["pct_receita"])
    assert 50.0 <= duas <= 53.0, f"As duas somam {duas:.1f}%; o texto diz 51,6%"


# ── 02 · Churn por plano ──────────────────────────────────────────────────────

def test_churn_cai_conforme_o_plano_sobe(con):
    """O achado central da série: correlação inversa entre preço e churn.

    Não basta o 100MB ser o pior — a escada inteira precisa ser monotônica,
    senão a frase "correlação inversa" deixa de descrever o dado.
    """
    d = _df(con, "02").sort_values("valor_mensalidade")
    churn = [float(x) for x in d["churn_pct"]]
    assert churn == sorted(churn, reverse=True), (
        f"A escada quebrou: {list(zip(d['plano'], churn))}"
    )


def test_churn_do_plano_basico(con):
    """findings.md: "O plano básico perde 36,7% dos clientes"."""
    d = _df(con, "02").sort_values("valor_mensalidade")
    assert 36.0 <= float(d.iloc[0]["churn_pct"]) <= 37.5


def test_razao_entre_o_pior_e_o_melhor_plano(con):
    """findings.md: "mais de 3x a taxa do plano 1GB (10,2%)"."""
    d = _df(con, "02").sort_values("valor_mensalidade")
    razao = float(d.iloc[0]["churn_pct"]) / float(d.iloc[-1]["churn_pct"])
    assert razao > 3.0, f"Razao caiu para {razao:.1f}x; o texto afirma mais de 3x"


# ── 05 · Inadimplência ────────────────────────────────────────────────────────

def test_inadimplencia_concentrada_acima_de_90_dias(con):
    """findings.md: "R$ 37.909,10 de R$ 46.951,70", com média de 417 dias."""
    d = _df(con, "05")
    total = d["valor_em_aberto"].astype(float).sum()
    # "Acima de", nao apenas "90": ha duas faixas com 90 no rotulo — "61 a 90
    # dias" e "Acima de 90 dias" — e pegar a primeira selecionava a errada.
    pior = d[d["faixa"].str.contains("Acima")].iloc[0]
    # A faixa era generosa (46 mil a 47,5 mil) para um numero que o README
    # agora estampa na linha de total da tabela. Numero publicado exato pede
    # asserçao exata — a faixa larga deixava o texto envelhecer dentro dela.
    assert round(total, 2) == 46951.70, f"Total em aberto: {total:.2f}"
    concentracao = float(pior["valor_em_aberto"]) / total * 100
    assert round(concentracao, 1) == 80.7, f"Concentracao >90d: {concentracao:.1f}%"
    assert float(pior["media_dias_atraso"]) > 300, (
        "A media de atraso da pior faixa caiu; o texto fala em 417 dias"
    )


# ── 10 · Churn por cidade ─────────────────────────────────────────────────────

def test_contagem_e_a_cidade_de_maior_churn(con):
    """findings.md: "Contagem tem o maior churn absoluto e percentual (34,1%)".

    É o achado que sustenta a recomendação operacional do relatório. Se a
    cidade mudar, a recomendação aponta para o lugar errado.
    """
    d = _df(con, "10")
    top = d.iloc[0]
    assert top["cidade"] == "Contagem", f"Maior churn virou {top['cidade']}"
    assert 33.0 <= float(top["churn_pct"]) <= 35.5


def test_betim_tem_mais_receita_e_menos_churn_que_contagem(con):
    """A tensão que o relatório explora: 1º em MRR, 4º em churn."""
    d = _df(con, "10").set_index("cidade")
    assert float(d.loc["Betim", "churn_pct"]) < float(d.loc["Contagem", "churn_pct"])
    assert float(d.loc["Betim", "mrr_atual"]) > float(d.loc["Contagem", "mrr_atual"])


# ── Cobertura ─────────────────────────────────────────────────────────────────

def test_as_dez_queries_rodam(con):
    """O README promete dez queries que rodam sem PostgreSQL.

    Uma delas ja ficou um mes quebrada no CI por usar
    `count(distinct ...) over (partition by ...)`, que o PostgreSQL nao suporta.
    """
    arquivos = sorted(QUERIES.glob("*.sql"))
    assert len(arquivos) == 10, f"{len(arquivos)} queries encontradas, nao 10"
    for f in arquivos:
        d = _df(con, f.name[:2])
        assert len(d) > 0, f"{f.name} devolveu zero linhas"
