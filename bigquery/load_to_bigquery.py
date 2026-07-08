"""
Carrega as tabelas do FiberNet ISP para BigQuery a partir dos CSVs gerados
pelo seed.sql. Requer: pip install google-cloud-bigquery db-dtypes
"""

from google.cloud import bigquery
import pathlib

PROJECT   = "seu-projeto"          # substitua
DATASET   = "fibernet_analytics"
DATA_DIR  = pathlib.Path(__file__).parent.parent / "data" / "csv"

client  = bigquery.Client(project=PROJECT)
dataset = bigquery.Dataset(f"{PROJECT}.{DATASET}")
dataset.location = "US"
client.create_dataset(dataset, exists_ok=True)

# Schemas explícitos: PostgreSQL SERIAL → INTEGER, VARCHAR → STRING,
# NUMERIC(10,2) → NUMERIC, DATE → DATE, TIMESTAMP → TIMESTAMP
SCHEMAS = {
    "plans": [
        bigquery.SchemaField("id",         "INTEGER",   mode="REQUIRED"),
        bigquery.SchemaField("name",       "STRING",    mode="REQUIRED"),
        bigquery.SchemaField("speed_mbps", "INTEGER",   mode="REQUIRED"),
        bigquery.SchemaField("amount",     "NUMERIC",   mode="REQUIRED"),
    ],
    "sellers": [
        bigquery.SchemaField("id",   "INTEGER", mode="REQUIRED"),
        bigquery.SchemaField("name", "STRING",  mode="REQUIRED"),
    ],
    "clients": [
        bigquery.SchemaField("id",           "INTEGER", mode="REQUIRED"),
        bigquery.SchemaField("city",         "STRING",  mode="REQUIRED"),
        bigquery.SchemaField("neighborhood", "STRING",  mode="NULLABLE"),
        bigquery.SchemaField("created_at",   "DATE",    mode="REQUIRED"),
        bigquery.SchemaField("status",       "STRING",  mode="REQUIRED"),
    ],
    "contracts": [
        bigquery.SchemaField("id",                  "INTEGER", mode="REQUIRED"),
        bigquery.SchemaField("client_id",           "INTEGER", mode="REQUIRED"),
        bigquery.SchemaField("plan_id",             "INTEGER", mode="REQUIRED"),
        bigquery.SchemaField("seller_id",           "INTEGER", mode="NULLABLE"),
        bigquery.SchemaField("amount",              "NUMERIC", mode="REQUIRED"),
        bigquery.SchemaField("start_date",          "DATE",    mode="REQUIRED"),
        bigquery.SchemaField("cancellation_date",   "DATE",    mode="NULLABLE"),
        bigquery.SchemaField("status",              "STRING",  mode="REQUIRED"),
        bigquery.SchemaField("cancellation_reason", "STRING",  mode="NULLABLE"),
    ],
    "financial_receivables": [
        bigquery.SchemaField("id",          "INTEGER",   mode="REQUIRED"),
        bigquery.SchemaField("contract_id", "INTEGER",   mode="REQUIRED"),
        bigquery.SchemaField("amount",      "NUMERIC",   mode="REQUIRED"),
        bigquery.SchemaField("due_date",    "DATE",      mode="REQUIRED"),
        bigquery.SchemaField("paid_at",     "DATE",      mode="NULLABLE"),
        bigquery.SchemaField("competence",  "DATE",      mode="REQUIRED"),
    ],
    "tickets": [
        bigquery.SchemaField("id",          "INTEGER",   mode="REQUIRED"),
        bigquery.SchemaField("contract_id", "INTEGER",   mode="REQUIRED"),
        bigquery.SchemaField("protocol",    "STRING",    mode="REQUIRED"),
        bigquery.SchemaField("category",    "STRING",    mode="NULLABLE"),
        bigquery.SchemaField("status",      "STRING",    mode="REQUIRED"),
        bigquery.SchemaField("created_at",  "TIMESTAMP", mode="REQUIRED"),
        bigquery.SchemaField("closed_at",   "TIMESTAMP", mode="NULLABLE"),
        bigquery.SchemaField("sla_seconds", "INTEGER",   mode="NULLABLE"),
    ],
    "sales": [
        bigquery.SchemaField("id",            "INTEGER", mode="REQUIRED"),
        bigquery.SchemaField("contract_id",   "INTEGER", mode="REQUIRED"),
        bigquery.SchemaField("seller_id",     "INTEGER", mode="REQUIRED"),
        bigquery.SchemaField("sale_type",     "STRING",  mode="REQUIRED"),
        bigquery.SchemaField("sale_date",     "DATE",    mode="REQUIRED"),
        bigquery.SchemaField("amount_before", "NUMERIC", mode="NULLABLE"),
        bigquery.SchemaField("amount_after",  "NUMERIC", mode="REQUIRED"),
    ],
}

# Ordem garante que PKs existam antes das FKs
LOAD_ORDER = ["plans", "sellers", "clients", "contracts",
              "financial_receivables", "tickets", "sales"]

job_config = bigquery.LoadJobConfig(
    source_format=bigquery.SourceFormat.CSV,
    skip_leading_rows=1,
    write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
)

for table_name in LOAD_ORDER:
    csv_path = DATA_DIR / f"{table_name}.csv"
    if not csv_path.exists():
        print(f"[SKIP] {csv_path} não encontrado")
        continue

    table_ref = f"{PROJECT}.{DATASET}.{table_name}"
    job_config.schema = SCHEMAS[table_name]

    with open(csv_path, "rb") as f:
        job = client.load_table_from_file(f, table_ref, job_config=job_config)
    job.result()
    print(f"[OK]   {table_name} → {job.output_rows} linhas carregadas")

print("\nCarga concluída. Execute 08_clientes_em_risco_bq.sql no BigQuery console.")
