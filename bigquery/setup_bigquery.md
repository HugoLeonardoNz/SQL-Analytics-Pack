# Setup BigQuery — FiberNet Analytics

Passos para rodar as queries no BigQuery Free Tier (sem custo para datasets pequenos).

---

## 1. Criar conta e projeto

1. Acesse [console.cloud.google.com](https://console.cloud.google.com) → criar conta gratuita
2. Crie um projeto (ex: `fibernet-analytics-dev`)
3. Ative a BigQuery API: menu lateral → **BigQuery** → ela ativa automaticamente

---

## 2. Instalar dependências

```bash
pip install google-cloud-bigquery db-dtypes
```

Autenticar com sua conta Google:

```bash
gcloud auth application-default login
```

Se não tiver o gcloud CLI:

```bash
# Windows — instalar o Google Cloud CLI
# https://cloud.google.com/sdk/docs/install
```

---

## 3. Gerar CSVs a partir do seed.sql

O script `load_to_bigquery.py` espera CSVs em `data/csv/`. Gere-os via PostgreSQL:

```bash
# Exportar cada tabela como CSV (execute dentro do psql)
psql -U postgres -d fibernet_analytics -c "\COPY plans               TO 'data/csv/plans.csv'               CSV HEADER"
psql -U postgres -d fibernet_analytics -c "\COPY sellers             TO 'data/csv/sellers.csv'             CSV HEADER"
psql -U postgres -d fibernet_analytics -c "\COPY clients             TO 'data/csv/clients.csv'             CSV HEADER"
psql -U postgres -d fibernet_analytics -c "\COPY contracts           TO 'data/csv/contracts.csv'           CSV HEADER"
psql -U postgres -d fibernet_analytics -c "\COPY financial_receivables TO 'data/csv/financial_receivables.csv' CSV HEADER"
psql -U postgres -d fibernet_analytics -c "\COPY tickets             TO 'data/csv/tickets.csv'             CSV HEADER"
psql -U postgres -d fibernet_analytics -c "\COPY sales               TO 'data/csv/sales.csv'               CSV HEADER"
```

---

## 4. Carregar para BigQuery

```bash
# Editar PROJECT em load_to_bigquery.py antes de rodar
python bigquery/load_to_bigquery.py
```

Saída esperada:

```
[OK]   plans → 4 linhas carregadas
[OK]   sellers → 10 linhas carregadas
[OK]   clients → 300 linhas carregadas
[OK]   contracts → 300 linhas carregadas
[OK]   financial_receivables → 4241 linhas carregadas
[OK]   tickets → 892 linhas carregadas
[OK]   sales → 315 linhas carregadas
```

---

## 5. Executar a query

No BigQuery Console (ou via `bq` CLI):

```bash
bq query --use_legacy_sql=false < bigquery/08_clientes_em_risco_bq.sql
```

Ou cole o conteúdo do arquivo diretamente no editor do console.

---

## Diferença de custo

| Operação | PostgreSQL local | BigQuery Free Tier |
|----------|------------------|--------------------|
| Storage  | Disco local      | 10 GB gratuitos/mês |
| Queries  | Ilimitado        | 1 TB gratuito/mês   |
| Dataset  | ~2 MB            | Cabe na cota free   |
