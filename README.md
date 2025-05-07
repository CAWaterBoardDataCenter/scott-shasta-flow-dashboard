# Scott and Shasta Rivers Flow Monitoring Dashboard

This Shiny web application provides real-time monitoring of stream flow and water diversion curtailment status for the Scott and Shasta Rivers in California. It supports water resource management by displaying current flow data, minimum instream flow (MIF) thresholds, and the curtailment status of points of diversion (PODs) on an interactive map.

## Features

-   **Live Streamflow Gauges:** Displays real-time flow data for:
    -   Scott River at Fort Jones (SFJ)
    -   Shasta River at Yreka (SRY)
-   **Minimum Instream Flow Comparison:** Each gauge includes visual indicators comparing recorded flows against MIF thresholds.
-   **Interactive Map:**
    -   Base layer options: Street, Topographic, Aerial
    -   POD markers colored by curtailment status (e.g., Not Curtailed, Curtailed)
    -   Clickable PODs with water right info and gauge locations with links to CDEC plots
-   **Custom Legend and Styling:** Colors and symbology reflect current curtailment status.
-   **Automatic Refresh:** Flow data updates every 15 minutes from California's CDEC.

## Data Sources

-   [California Data Exchange Center (CDEC)](https://cdec.water.ca.gov/) – Real-time streamflow data
-   AWS S3 – Hosts preprocessed POD data
-   Local shapefiles – Watershed and stream geometries

## Project Structure

-   `app.R` – Main Shiny application
-   `cdecFlowQuery.R` – Helper script to query CDEC
-   `data/` – Contains shapefiles, MIF lookup tables, and station metadata
-   `www/` – Custom CSS styling, image files

## Deployment

The app requires access to a `config.yml` file for AWS credentials and assumes that `aws.s3`, `shiny`, `leaflet`, `flexdashboard`, and related packages are installed.
