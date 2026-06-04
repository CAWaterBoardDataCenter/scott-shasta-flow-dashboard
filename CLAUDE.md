# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

An R Shiny dashboard for monitoring stream flow and water diversion curtailment status for the Scott and Shasta Rivers (Northern California). It displays real-time CDEC gauge data, minimum instream flow (MIF) thresholds, and a Leaflet map of Points of Diversion (PODs) colored by curtailment status.

## Running the App

```r
# From RStudio: open app.R and click "Run App", or:
shiny::runApp()
```

The app loads from two data sources on startup:
1. **POD data** — fetched live from AWS S3 (`scott-shasta-monitoring-pods` object)
2. **MIF tables** — loaded from `data/mif-tables.RData`

Real-time flow values are then fetched from CDEC every 15 minutes during the session.

## Required Local Files (Not in Git)

- **`config.yml`** — AWS credentials and active environment; gitignored. Must exist locally. Template:
  ```yaml
  active_env: default   # or "development" or "production"

  default:
    aws:
      bucket: "dwr-enf-shiny"
      access_key: "..."
      secret_key: "..."
      region: "us-west-2"
  production:
    aws:
      bucket: "dwr-shiny-apps"
      access_key: "..."
      secret_key: "..."
      region: "us-gov-west-1"
  development:
    inherits: default
  status: curtailed   # or "default"
  ```
- **`aws-data/`** — Raw Excel PBI exports; gitignored. Needed only when re-running `prep-pods.R`.

## Data Preparation Scripts (Run Manually, Not Part of the App)

### `prep-pods.R`
Run this whenever POD curtailment data needs updating. Reads Excel files from `aws-data/`, combines Scott and Shasta POD data, saves to `pods.RData`, and uploads to S3.

- `R_CONFIG_ACTIVE` is hardcoded to `"development"` inside `prep-pods.R` — change it there to target a different bucket.
- The `status` field in `config.yml` controls which PBI files are loaded: `"curtailed"` picks the most recent dated file matching `ScottPBI-YYYYMMDD.xlsx`; `"default"` uses `ScottPBI-default.xlsx`.
- Set `save_s3 <- FALSE` at the top to skip the S3 upload.

### `prep-mif-tables.R`
Run infrequently when MIF thresholds change. Reads `mifs-sfj.csv` and `mifs-sry.csv` (not in repo — obtain from source), produces `data/mif-tables.RData`.

## Architecture

### `app.R` Structure
The entire app lives in a single file organized in numbered sections:
1. Library loading
2. AWS environment setup — reads `active_env` from `config.yml` via `yaml::read_yaml()`, sets `R_CONFIG_ACTIVE`, then calls `config::get()`
3. Data loading (station CSV, MIF RData, PODs from S3, shapefiles)
4. Support functions (all inline — see below)
5. Today's MIF lookup (filters `mifs` list by current month/day)
6. UI card definitions
7. `ui` using `bslib::page_fillable()` with `bs_theme(preset = "litera")`
8. `server` with reactive flow data, gauge renders, Leaflet map, and 15-min auto-refresh
9. `shinyApp(ui, server)`

### CDEC Query Functions (Section 4 of `app.R`)
- `cdecFlowQuery()` — top-level wrapper; fetches yesterday→tomorrow and returns the latest non-NA row for a station
- `cdecQuery()` — builds the CDEC CSV API URL and fetches/renames columns
- `basic_query()` — raw HTTP fetch via `curl`, parses CSV response
- `cder_handle()` / `col_spec` — curl handle and readr column spec used by `basic_query()`
- `roundUpAuto()` — rounds a flow value up to a clean axis maximum for gauge display
- `sameMonthDay()` — compares month/day of two dates; used to filter today's MIF row

### POD Curtailment Color Mapping
```r
"Not Curtailed"           → "green"
"Conditionally Suspended" → "chartreuse"
"Conditionally Curtailed" → "yellow"
"Curtailed"               → "red"
(unknown)                 → "gray"
```

### Gauge Sectors (MIF Thresholds)
Each `flexdashboard::gauge()` uses `gaugeSectors()` with `success`/`warning`/`danger` bands driven by columns in the MIF lookup tables (`success_lo`, `warning_lo`, `warning_hi`, `danger_hi`, `mif`).

## Deployment

Deployed to **shinyapps.io** via rsconnect. To deploy against the production S3 bucket (`dwr-shiny-apps`, `us-gov-west-1`), set `active_env: production` in `config.yml` before deploying.
