# Projet EShop — Bases de Données Distribuées

Distributed database implementation of the EShop relational database across **3 Oracle 21c XE instances** (CDB/PDB architecture), using **database links**, **synonyms**, **triggers**, and **PL/SQL stored procedures** to synchronize data in real time.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              BDD GLOBALE (ESHOP_GLOBALE_PDB)                │
│        7 tables · 3 Triggers SYC_* (AFTER INSERT/           │
│                        DELETE/UPDATE)                       │
└───────────┬────────────────────────────────┬────────────────┘
            │  DB Link SITE_1                │  DB Link SITE_2
            ▼                                ▼
┌───────────────────────┐    ┌───────────────────────────────┐
│  SITE 1 (ESHOP_SITE1) │    │  SITE 2 (ESHOP_SITE2)         │
│  Tables _1            │    │  Tables _2                    │
│  3 Procédures PL/SQL  │    │  3 Procédures PL/SQL          │
└───────────────────────┘    └───────────────────────────────┘
```

## Two Scenarios

### `eshop_project_s1/` — Scenario 1: Fragmentation by Query

Routing based on **product category + quantity** (the most frequent queries determine data placement):

| Site   | Routing Rule                              | Description                    |
|--------|-------------------------------------------|--------------------------------|
| Site 1 | `idCategorie = 50 AND quantite > 100`    | Category 50, large quantities  |
| Site 2 | `idCategorie = 35 AND quantite > 50`     | Category 35, medium quantities |
| Neither| Everything else stays on Global only      |                                |

- Triggers fire `WHEN (NEW.QUANTITE > 50)`
- Site procedures **auto-insert** missing references (Commande, Client, Employé, Produit, Fournisseur, Catégorie) from Global via DB links
- Handles complex UPDATE transitions: same site, site-to-site, no longer qualifies, newly qualifies

### `eshop_project_s2/` — Scenario 2: Fragmentation by Volume

Routing based purely on **order quantity** (separating wholesale from retail):

| Site   | Routing Rule        | Description                          |
|--------|---------------------|--------------------------------------|
| Site 1 | `quantite >= 100`   | Gros volumes — Entrepôt Central      |
| Site 2 | `quantite < 100`    | Petits volumes — Magasins de Proximité |

- Triggers fire on **every** INSERT/DELETE/UPDATE (no WHEN clause)
- Site procedures **raise errors** if references are missing (no auto-insert)
- Uses `EXECUTE IMMEDIATE` for remote procedure calls

## Tech Stack

| Component           | Technology                                   |
|---------------------|----------------------------------------------|
| Database            | Oracle XE 21c (CDB/PDB)                      |
| Docker Image        | `gvenzl/oracle-xe:21-slim-faststart`         |
| Orchestration       | Docker Compose with healthchecks             |
| Cross-DB Access     | Database Links + Synonyms                    |
| Synchronization     | PL/SQL Triggers (AFTER INSERT/DELETE/UPDATE)  |
| Data Integrity      | PL/SQL Stored Procedures with exception handling |
| Optimization        | B-Tree Indexes + EXPLAIN PLAN analysis       |

## Project Structure

```
eshop_project_s1/  (or eshop_project_s2/)
├── globale_db/
│   ├── scripts/
│   │   ├── 01_schema_creation.sql        # PDB + users + privileges
│   │   ├── 02_sequence_creation.sql      # (s1) Sequences
│   │   ├── 03_table_creation.sql         # 7 global tables
│   │   ├── 11_FOURNISSEURS_DATA.sql      # Seed data
│   │   ├── 12_CATEGORIES_DATA.sql
│   │   ├── 13_EMPLOYES_DATA.sql
│   │   ├── 14_CLIENTS_DATA.sql
│   │   ├── 15_PRODUITS_DATA.sql
│   │   ├── 16_COMMANDES_DATA.sql
│   │   ├── 17_LIGNES_COMMANDES_DATA.sql
│   │   ├── 21_dblinks_creation.sql       # DB Links to Site 1 & Site 2
│   │   ├── 22_synonymes_creation.sql     # Synonyms for _1 and _2 tables
│   │   ├── 23_triggers_creation.sql      # 3 sync triggers
│   │   └── 99_init_complete.sql          # Healthcheck marker table
│   └── Dockerfile
├── site_1_db/
│   ├── 01_schema_creation.sql            # PDB + user creation
│   ├── 02_table_creation.sql             # _1 tables (all 7)
│   ├── 03_procedures_creation.sql        # insert/delete/update_ligne
│   ├── 04_dblinks_creation.sql           # DB Link to Global
│   ├── 05_synonymes_creation.sql         # _G synonyms → @GLOBALE
│   ├── 06_data_insertion.sql             # Initial data from Global
│   └── Dockerfile
├── site_2_db/                            # Same structure with _2 tables
│   └── ...
├── 100_demo_presentation.sql             # Demo/test script
└── docker-compose.yml
```

## Docker Setup

### Scenario 1 Ports

| Container    | Host Port | PDB Name            | IP Address     | Network        |
|--------------|-----------|---------------------|----------------|----------------|
| globale-db   | 1521      | ESHOP_GLOBALE_PDB   | 192.168.1.10   | 192.168.1.0/24 |
| site1-db     | 1522      | ESHOP_SITE1_PDB     | 192.168.1.11   | 192.168.1.0/24 |
| site2-db     | 1523      | ESHOP_SITE2_PDB     | 192.168.1.12   | 192.168.1.0/24 |

### Scenario 2 Ports

| Container    | Host Port | PDB Name            | IP Address     | Network        |
|--------------|-----------|---------------------|----------------|----------------|
| globale-db-s2| 1524      | ESHOP_GLOBALE_PDB   | 192.168.2.10   | 192.168.2.0/24 |
| site1-db-s2  | 1525      | ESHOP_SITE1_PDB     | 192.168.2.11   | 192.168.2.0/24 |
| site2-db-s2  | 1526      | ESHOP_SITE2_PDB     | 192.168.2.12   | 192.168.2.0/24 |

Both scenarios can run simultaneously since they use different ports and networks.

## Quick Start

```bash
# Start Scenario 1
cd eshop_project_s1
docker compose up -d --build

# Start Scenario 2 (can run in parallel)
cd eshop_project_s2
docker compose up -d --build
```

**Wait for all containers to be healthy** (~3-5 minutes for Oracle XE to initialize). The globale DB must be healthy before site DBs can start (enforced via `depends_on` + healthcheck).

### Connection Strings (Oracle SQL Developer)

```
# Scenario 1 - Global DB
User:     globale_user
Password: globale_password
Hostname: localhost
Port:     1521
Service:  ESHOP_GLOBALE_PDB

# Scenario 2 - Global DB
Same credentials, Port: 1524
```

## Important: Post-Startup Steps

Triggers are created during Docker init but may have compilation warnings because remote procedures don't exist yet. **Recompile after all containers are healthy:**

```sql
ALTER SESSION SET CONTAINER = ESHOP_GLOBALE_PDB;
ALTER SESSION SET CURRENT_SCHEMA = globale_user;

ALTER TRIGGER SYC_INSERT_LIGNE COMPILE;  -- or SYNC_INSERT_LIGNE for s2
ALTER TRIGGER SYC_DELETE_LIGNE COMPILE;  -- or SYNC_DELETE_LIGNE for s2
ALTER TRIGGER SYC_UPDATE_LIGNE COMPILE;  -- or SYNC_UPDATE_LIGNE for s2
```

## Demo Scripts

### `100_demo_presentation.sql`

Each scenario has a demo script that tests all DML operations and exception handling:

| Step | Description                                        |
|------|----------------------------------------------------|
| 1    | Verify DB Link connectivity                        |
| 2    | Prepare test data (parent tables + site references)|
| 3    | INSERT → route to Site 1 / Site 2                  |
| 4    | UPDATE → same site (quantity stays in range)       |
| 5    | UPDATE → site transition (crosses threshold)       |
| 6    | UPDATE → reverse transition or no longer qualifies |
| 7-8  | DELETE → from Site 1 / Site 2                      |
| 9-10 | Exception handling (invalid input, duplicates, etc)|
| 11   | Cleanup all test data                              |

Run from **Oracle SQL Developer** connected to the Global DB.

### Key Difference in Demo Scripts

- **S1**: Only needs parent data on Global DB. Site procedures auto-insert missing references.
- **S2**: Must **manually pre-populate** reference tables on both sites before triggers can route data, because procedures raise errors for missing references.

## Trigger Synchronization Flow

```
INSERT on Global LIGNES_COMMANDES
  → Trigger fires (AFTER INSERT)
    → Check routing criteria
      → Route to Site 1: INSERT_LIGNE@SITE_1(...)
      → Route to Site 2: INSERT_LIGNE@SITE_2(...)

UPDATE on Global LIGNES_COMMANDES
  → Trigger fires (AFTER UPDATE)
    → Evaluate OLD vs NEW routing
      → Same site:     UPDATE_LIGNE@site(...)
      → Site change:   DELETE@old_site + INSERT@new_site
      → No longer:     DELETE@old_site only
      → Newly:         INSERT@new_site only

DELETE on Global LIGNES_COMMANDES
  → Trigger fires (AFTER DELETE)
    → Check OLD routing criteria
      → DELETE_LIGNE@SITE_1 or DELETE_LIGNE@SITE_2
```

## Optimization

See `queries_and_optimization.sql` (in s2) for:

1. **Query**: Number of orders per client in 2026 (date range filter for index compatibility)
2. **EXPLAIN PLAN**: Identify costly operations (FTS, HASH JOIN, HASH GROUP BY)
3. **Indexes**: 
   - `IDX_COMMANDES_DATE` on `COMMANDES(DATE_COMMANDE)` → FTS replaced by Index Range Scan
   - `IDX_COMMANDES_CLIENT` on `COMMANDES(ID_CLIENT)` → Optimizes JOIN + avoids table locks
4. **Distributed Query**: CA per category using UNION ALL across both sites via synonyms

## Credentials

| User             | Password         | Scope          |
|------------------|------------------|----------------|
| globale_user     | globale_password | Global PDB     |
| site1_user       | site1_password   | Site 1 PDB     |
| site2_user       | site2_password   | Site 2 PDB     |
| SYS              | admin            | CDB root (all) |

## Shutdown

```bash
# Stop Scenario 1
cd eshop_project_s1
docker compose down

# Stop Scenario 2
cd eshop_project_s2
docker compose down
```
