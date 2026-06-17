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

- Like `app.R`, `prep-pods.R` reads the active environment from `active_env` in `config.yml` — change it there to target a different bucket.
- The `status` field in `config.yml` controls which PBI files are loaded: `"curtailed"` picks the most recent dated file matching `ScottPBI-YYYYMMDD.xlsx`; `"default"` uses `ScottPBI-default.xlsx`.
- Set `save_s3 <- FALSE` at the top to skip the S3 upload.

## Architecture

### `app.R` Structure
The entire app lives in a single file organized in numbered sections:
1. Library loading
2. AWS environment setup — reads `active_env` from `config.yml` via `yaml::read_yaml()`, sets `R_CONFIG_ACTIVE`, then calls `config::get()`
3. Data loading (station CSV, MIF RData, PODs from S3 via `loadPods()`, shapefiles)
4. Support functions (all inline — see below)
5. Today's MIF lookup (filters `mifs` list by current month/day)
6. UI card definitions
7. `ui` using `bslib::page_fillable()` with `bs_theme(preset = "litera")`
8. `server` with reactive flow data, gauge renders, Leaflet map, 15-min auto-refresh, and a manual POD refresh button
9. `shinyApp(ui, server)`

### POD Data Loading & Refresh
- `loadPods()` (Section 3) fetches the `scott-shasta-monitoring-pods` object from S3, applies the curtailment color mapping, and returns a list of `pods` (data frame) and `prep_date`. It runs once at startup to seed the initial `pods`/`prep_date` globals.
- The server holds `pod_data` and `pod_prep_date` reactive values seeded from that startup load. The **"Refresh POD Data"** button (at the top of the About card body, `input$refresh_pods`) re-runs `loadPods()` and updates these reactives — so S3 changes are picked up **without restarting the app** (previously the only option). Errors are caught and shown via `showNotification()`.
- POD markers are redrawn via `leafletProxy()` (an `observeEvent(pod_data(), ignoreInit = TRUE)`), which preserves the current map view/zoom instead of fully re-rendering the map. The footer "last updated" date reads `pod_prep_date()`.
- This button refreshes **POD/curtailment data only**; CDEC gauge flow values are on the separate 15-min timer.

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
