-- ============================================================
-- SCHEMA — FiberNet ISP Analytics
-- Projeto de portfólio baseado em estrutura real de ISP.
-- Banco de dados: PostgreSQL 14+
-- ============================================================

-- ========================
-- PLANOS DE INTERNET
-- ========================
CREATE TABLE plans (
    id         SERIAL        PRIMARY KEY,
    name       VARCHAR(50)   NOT NULL,
    speed_mbps INT           NOT NULL,
    amount     NUMERIC(10,2) NOT NULL
);

-- ========================
-- VENDEDORES
-- ========================
CREATE TABLE sellers (
    id   SERIAL       PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- ========================
-- CLIENTES
-- ========================
CREATE TABLE clients (
    id           SERIAL       PRIMARY KEY,
    city         VARCHAR(100) NOT NULL,
    neighborhood VARCHAR(100),
    created_at   DATE         NOT NULL,
    status       VARCHAR(20)  NOT NULL  -- 'active' | 'cancelled'
);

-- ========================
-- CONTRATOS
-- ========================
CREATE TABLE contracts (
    id                  SERIAL        PRIMARY KEY,
    client_id           INT           NOT NULL REFERENCES clients(id),
    plan_id             INT           NOT NULL REFERENCES plans(id),
    seller_id           INT           REFERENCES sellers(id),
    amount              NUMERIC(10,2) NOT NULL,
    start_date          DATE          NOT NULL,
    cancellation_date   DATE,
    status              VARCHAR(20)   NOT NULL,  -- 'active' | 'cancelled'
    cancellation_reason VARCHAR(200)
);

-- ========================
-- BOLETOS / RECEBÍVEIS
-- ========================
CREATE TABLE financial_receivables (
    id          SERIAL        PRIMARY KEY,
    contract_id INT           NOT NULL REFERENCES contracts(id),
    amount      NUMERIC(10,2) NOT NULL,
    due_date    DATE          NOT NULL,
    paid_at     DATE,                   -- NULL = não pago (inadimplente)
    competence  DATE          NOT NULL  -- mês de referência
);

-- ========================
-- TICKETS DE SUPORTE
-- ========================
CREATE TABLE tickets (
    id          SERIAL      PRIMARY KEY,
    contract_id INT         NOT NULL REFERENCES contracts(id),
    protocol    VARCHAR(20) NOT NULL,
    category    VARCHAR(100),
    status      VARCHAR(20) NOT NULL,   -- 'open' | 'closed'
    created_at  TIMESTAMP   NOT NULL,
    closed_at   TIMESTAMP,
    sla_seconds INT
);

-- ========================
-- MOVIMENTAÇÕES COMERCIAIS
-- (nova venda, upgrade, downgrade)
-- ========================
CREATE TABLE sales (
    id            SERIAL        PRIMARY KEY,
    contract_id   INT           NOT NULL REFERENCES contracts(id),
    seller_id     INT           NOT NULL REFERENCES sellers(id),
    sale_type     VARCHAR(20)   NOT NULL,  -- 'NEW' | 'UPGRADE' | 'DOWNGRADE'
    sale_date     DATE          NOT NULL,
    amount_before NUMERIC(10,2),           -- NULL em nova venda
    amount_after  NUMERIC(10,2) NOT NULL
);
