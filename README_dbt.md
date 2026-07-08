# dbt — FiberNet Analytics

As 10 queries analíticas do projeto foram migradas para **models dbt** com documentação
de colunas, testes de qualidade de dados e lineage automático.

---

## Por que dbt?

dbt transforma queries SQL avulsas em uma **camada de transformação documentada e testada**:
cada model tem descrição, os relacionamentos entre tabelas são rastreados automaticamente
(lineage), e erros de qualidade de dados (nulos inesperados, valores fora do domínio) quebram
o pipeline antes de chegarem ao consumidor final — dashboard ou modelo de ML.

---

## Pré-requisitos

```bash
pip install dbt-core dbt-postgres
# Para BigQuery (opcional):
pip install dbt-bigquery
```

Verificar versão:
```bash
dbt --version
```

---

## Setup

### 1. Banco de dados PostgreSQL

Certifique-se de que o banco `fibernet_analytics` está carregado:

```bash
psql -U postgres -c "CREATE DATABASE fibernet_analytics;"
psql -U postgres -d fibernet_analytics -f data/schema.sql
psql -U postgres -d fibernet_analytics -f data/seed.sql
```

### 2. profiles.yml

```bash
# Copiar o exemplo para o diretório dbt
cp profiles.yml.example ~/.dbt/profiles.yml

# Editar com suas credenciais
# (user/password do PostgreSQL local)
```

### 3. Testar conexão

```bash
dbt debug
# Esperado: "All checks passed!"
```

---

## Comandos principais

| Comando | O que faz |
|---------|-----------|
| `dbt debug` | Testa conexão e configuração |
| `dbt run` | Executa todos os models (cria views/tables) |
| `dbt test` | Roda todos os testes de qualidade |
| `dbt run --select staging.*` | Só os models de staging |
| `dbt run --select marts.*` | Só os marts analíticos |
| `dbt run --select clientes_em_risco` | Um model específico |
| `dbt docs generate` | Gera documentação estática |
| `dbt docs serve` | Abre documentação no browser (localhost:8080) |
| `dbt clean` | Remove arquivos de build (target/) |

Usando o Makefile (atalhos):
```bash
make run      # dbt run
make test     # dbt test
make docs     # generate + serve
make ci       # run + test (pipeline completo)
```

---

## Estrutura dos models

```
models/
├── staging/          -- 1:1 com as tabelas brutas (views)
│   ├── stg_clients.sql
│   ├── stg_contracts.sql
│   ├── stg_financial_receivables.sql
│   ├── stg_support_tickets.sql
│   └── schema.yml    -- descrições + testes de coluna
└── marts/            -- análises de negócio (tables)
    ├── mrr_mensal.sql
    ├── clientes_em_risco.sql
    ├── cohort_retencao.sql
    ├── ranking_vendedores.sql
    ├── ltv_estimado.sql
    └── schema.yml
```

**Staging:** limpeza de tipos, renomeação de colunas, filtros básicos.
Não fazem joins — são o espelho limpo das tabelas brutas.

**Marts:** análises de negócio completas com joins, CTEs e window functions.
Cada mart corresponde a uma das 10 queries analíticas do projeto.

---

## Testes incluídos

### Testes nativos dbt (schema.yml)
- `unique` + `not_null` em todas as PKs
- `accepted_values` em colunas de status/categoria
- `relationships` entre staging e sources

### Teste singular customizado
- `tests/assert_mrr_nao_negativo.sql` — falha se qualquer mês tiver crescimento líquido
  calculado de forma inválida (sanidade financeira básica)

---

## Documentação gerada

```bash
dbt docs generate && dbt docs serve
```

O comando abre um site local com:
- DAG completo de lineage (quais models dependem de quais tabelas)
- Descrição de cada coluna
- Resultados dos testes
- SQL compilado de cada model

---

## BigQuery (opcional)

Para rodar os mesmos models no BigQuery:

```bash
# Configurar profile bq em ~/.dbt/profiles.yml (ver profiles.yml.example)
dbt run --target bq
```

Ver também: `bigquery/` — versão manual da query de clientes em risco com anotações
de todas as diferenças de sintaxe PostgreSQL → BigQuery.
