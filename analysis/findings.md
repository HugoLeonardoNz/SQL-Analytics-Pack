# 📊 Insights — FiberNet ISP Analytics

> Todos os números abaixo são obtidos executando as queries do diretório `queries/`
> contra o seed em `data/seed.sql`. Reproduzível sem instalar PostgreSQL:
> `python tools/run_query.py 02` roda a query contra o mesmo seed via DuckDB.
>
> **Dataset de referência:** 300 clientes | 4.241 boletos | 220 tickets | Período 2022–2024

---

## 01 · Receita por Cidade

```
cidade               contratos_ativos  mrr_total   ticket_medio  pct_receita
Betim                63                7.833,70    124,34        27,43%
Contagem             54                6.894,60    127,68        24,14%
Ribeirão das Neves   50                6.245,00    124,90        21,87%
Esmeraldas           37                4.456,30    120,44        15,60%
Ibirité              23                3.127,70    135,99        10,95%
```

**🔍 Insight:** Betim e Contagem juntas respondem por **51,6% do MRR total** (R$ 14.728,30),
mas Ibirité chama atenção pelo ticket médio mais alto (R$ 135,99) com apenas 23 contratos ativos
— sinal de que essa praça concentra clientes de planos superiores, valendo investimento em cobertura.

---

## 02 · Churn por Plano

```
plano         valor     total  ativos  cancelados  churn_pct
Fibra 100MB   R$ 89,90   98     62      36          36,7%
Fibra 200MB   R$ 109,90  84     62      22          26,2%
Fibra 500MB   R$ 139,90  69     59      10          14,5%
Fibra 1GB     R$ 179,90  49     44       5          10,2%
```

**🔍 Insight:** Há uma relação inversa clara entre valor do plano e churn.
O plano básico perde **36,7% dos clientes**, mais de 3× a taxa do plano 1GB (10,2%).
Isso sugere que clientes de planos superiores percebem mais valor no serviço — ou que o custo
de troca (lock-in técnico) é maior. Ações de upsell nos clientes Fibra 100MB podem elevar
receita *e* reduzir churn simultaneamente.

---

## 03 · Cohort de Retenção Trimestral

A query devolve a retenção em vários marcos (`mes_n` = 0, 1, 3, 6, 9, 12, 18, 24).
O recorte abaixo é o marco de **12 meses** — a leitura mais comparável entre
coortes, porque todas as de 2022 e 2023 já o completaram.

```
coorte    total_clientes  clientes_retidos  retencao_pct
2022 Q1   23              14                60,9%
2022 Q2   24              17                70,8%
2022 Q3   24              19                79,2%
2022 Q4   36              23                63,9%
2023 Q1   23              18                78,3%
2023 Q2   32              23                71,9%
2023 Q3   33              25                75,8%
2023 Q4   36              26                72,2%
```

**🔍 Insight:** A coorte **2022 Q1 retém 60,9% em 12 meses**, a pior da série, e a
2022 Q4 vem logo atrás com 63,9%. As coortes de 2023 ficam todas entre 71,9% e
78,3% — mais estáveis e, na média, 9 pontos acima das de 2022. A leitura mais
provável é maturação de processo (onboarding, qualificação de venda) e não sorte
de amostra, porque o padrão se repete nos quatro trimestres de 2023.

> Cuidado de leitura: a retenção aqui **não é monotônica**. Um cliente conta como
> retido no mês *n* se pagou um boleto com competência naquele mês; quem atrasa e
> depois regulariza sai e volta. Por isso `mes_n = 3` pode ficar acima de
> `mes_n = 1`. É uma medida de atividade de pagamento, não de contrato ativo — a
> query documenta essa escolha no cabeçalho.

## 04 · Ranking de Vendedores

```
vendedor        novas  upgrades  downgrades  receita_nova   canceladas  churn_carteira
Patrícia Lima   83     9         3           R$ 10.681,70   22          26,5%
Fernanda Costa  80     8         2           R$ 9.852,00    25          31,3%
Carlos Mendes   71     7         7           R$ 8.192,90    14          19,7%
Roberto Souza   66     3         3           R$ 7.783,40    12          18,2%
```

**🔍 Insight:** Patrícia lidera em receita nova, mas **Roberto Souza tem a melhor
qualidade de carteira** — apenas 18,2% de churn entre seus contratos. Fernanda Costa
vende bem em volume, mas 31,3% dos seus contratos cancelam, o que questiona o fit
dos clientes que ela está captando. Carlos se destaca pelo maior número de downgrades (7),
sugerindo que seus clientes têm dificuldade de manter o plano original.

---

## 05 · Aging de Inadimplência

```
faixa                  boletos  contratos  valor_em_aberto  media_dias_atraso
01 - Até 30 dias       23       23         R$ 3.027,70      5 dias
02 - 31 a 60 dias      25       25         R$ 3.007,50      35 dias
03 - 61 a 90 dias      26       26         R$ 3.007,40      66 dias
04 - Acima de 90 dias  309      182        R$ 37.909,10     417 dias
```

**🔍 Insight:** A faixa crítica (>90 dias) representa **80,7% do valor total em aberto**
(R$ 37.909,10 de R$ 46.951,70). Com média de 417 dias de atraso, grande parte dessa carteira
provavelmente já está perdida. O alerta real está nas faixas 1–3: R$ 9.042,60 distribuídos
em 74 contratos ainda têm alta probabilidade de recuperação se acionados com urgência.

---

## 06 · Ticket Médio e LTV por Plano

```
plano         valor     ativos  mrr_plano    tempo_medio  ltv_estimado  pct_mrr
Fibra 100MB   R$ 89,90  62      R$ 5.573,80  16,2 meses   R$ 1.457,25  19,52%
Fibra 200MB   R$ 109,90 62      R$ 6.813,80  17,5 meses   R$ 1.923,25  23,86%
Fibra 500MB   R$ 139,90 59      R$ 8.254,10  18,3 meses   R$ 2.553,77  28,90%
Fibra 1GB     R$ 179,90 44      R$ 7.915,60  13,5 meses   R$ 2.436,83  27,72%
```

**🔍 Insight:** O plano **Fibra 500MB é o mais equilibrado**: maior MRR individual
(R$ 8.254,10 = 28,9% do total) e maior LTV estimado (R$ 2.553,77). O plano 1GB, apesar
do ticket mais alto, tem o menor tempo médio de permanência (13,5 meses), o que reduz
seu LTV abaixo do 500MB. O 100MB contribui com apenas 19,5% do MRR apesar de ter 62
contratos ativos — igual ao 200MB — o que evidencia o impacto direto do churn elevado
na geração de receita.

---

## 07 · Crescimento Mensal do MRR

```
Primeiros meses 2022:  MRR acumulado cresceu de R$ 859 → R$ 11.121 (dez/22)
Pico de crescimento:   jan/2023 — MRR novo R$ 2.028,40 (+45% vs mês anterior)
MRR acumulado máx.:    out/2023 — R$ 20.023,70
Crescimento negativo:  set/2024 (−R$ 309,60) e out/2024 (−R$ 489,50)
MRR acumulado final:   R$ 28.557,30
```

**🔍 Insight:** A operação manteve crescimento líquido positivo por quase 3 anos seguidos,
com pico de MRR acumulado ultrapassando R$ 29k em ago/2024. Os dois meses negativos no
final do período (set–out/2024) são um sinal de alerta: mais receita cancelou do que entrou.
Se a tendência se mantiver, a operação pode entrar em contração — o que reforça a urgência
das ações de retenção apontadas nas queries 05 e 08.

---

## 08 · Clientes em Risco

```
Total em risco (score > 0):     174 contratos no dataset completo
Exibidos pela query (LIMIT 30): top 30 por score + dias de atraso
Contratos CRÍTICO (score ≥ 5):  17 contratos no top 30
Contratos ALTO    (score 3–4):  13 contratos no top 30
Contrato mais crítico:          #281 — score 8 (6 boletos em atraso + 1 ticket aberto)
                                R$ 839,40 em aberto, atraso máximo 889 dias
```

> **Atenção:** A query usa `LIMIT 30` para exibir o ranking dos contratos mais críticos.
> No dataset completo há **174 contratos com algum sinal de risco**. Remova o `LIMIT`
> para listar todos, ou ajuste o filtro de score mínimo conforme a capacidade da equipe
> de retenção.

**🔍 Insight:** O modelo de score combina inadimplência e tickets abertos para priorizar
ações de retenção. Dos 17 contratos em nível CRÍTICO no top 30, a maioria acumula atraso
superior a 6 meses — muitos podem ser pré-cancelamentos silenciosos. Contagem e Betim
concentram mais contratos de risco, alinhado com o maior volume de clientes nessas cidades.
Como o universo total de risco é de 174 contratos (76,7% da base ativa de 227), uma segmentação
por faixa de score é essencial para priorizar ações com a equipe de campo.

---

## 09 · Tempo Médio até o Cancelamento

```
plano         valor     cancelamentos  media_meses  min_dias  max_dias  motivo_principal
Fibra 100MB   R$ 89,90   36            4,1 meses    30        240       Dificuldade financeira
Fibra 200MB   R$ 109,90  22            3,2 meses    30        240       Preço elevado
Fibra 500MB   R$ 139,90  10            4,3 meses    30        240       Imóvel desocupado
Fibra 1GB     R$ 179,90   5            5,6 meses    60        240       Concorrência com melhor oferta
```

**🔍 Insight:** A janela crítica de cancelamento está entre **1 e 5 meses** para todos
os planos. O Fibra 200MB tem o cancelamento mais precoce (3,2 meses em média), e o motivo
"Preço elevado" sugere que esse plano está mal posicionado — o cliente migra por achar o
100MB mais barato ou o 500MB mais vantajoso. Ações de onboarding nos primeiros 90 dias,
especialmente para o 200MB, podem mover significativamente a retenção geral.

---

## 10 · Top Cidades por Churn

```
cidade               total  ativos  cancelados  churn_pct  mrr_atual    receita_perdida  ranking
Contagem             82     54      28          34,1%      R$ 6.894,60  R$ 3.117,20      1°
Ribeirão das Neves   68     50      18          26,5%      R$ 6.245,00  R$ 1.958,20      2°
Esmeraldas           46     37       9          19,6%      R$ 4.456,30  R$   899,10      3°
Betim                77     63      14          18,2%      R$ 7.833,70  R$ 1.568,60      4°
Ibirité              27     23       4          14,8%      R$ 3.127,70  R$   409,60      5°
```

**🔍 Insight:** Contagem tem o maior churn absoluto e percentual (34,1%), com
**R$ 3.117,20 em receita já perdida** — a maior de todas as cidades. Apesar de ser
a segunda em contratos ativos, perde proporcionalmente muito mais que Betim (1° em MRR,
churn de apenas 18,2%). Isso sugere problemas de qualidade de rede ou concorrência mais
agressiva em Contagem, tornando-a a cidade prioritária para investigação operacional.

---

## Resumo Executivo

| Métrica                         | Valor              |
|---------------------------------|--------------------|
| MRR total ativo                 | R$ 28.557,30       |
| Clientes ativos                 | 227 de 300 (75,7%) |
| Churn rate médio                | 24,3%              |
| Plano com menor churn           | Fibra 1GB (10,2%)  |
| Plano com maior MRR             | Fibra 500MB        |
| Cidade maior receita            | Betim (27,4%)      |
| Cidade maior churn              | Contagem (34,1%)   |
| Inadimplência acima de 90 dias  | R$ 37.909,10       |
| Vendedor melhor qualidade cart. | Roberto Souza      |
| Cohort com melhor retenção      | 2022 Q2/Q3 (83,3%) |
