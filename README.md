# 📊 Spatiotemporal Analysis of Assault Occurrences in Toronto (2015-2024)

> **✨ Interactive Visualization:** View the full analysis and geographic patterns on my **[ArcGIS Dashboard](https://www.arcgis.com/apps/dashboards/11f4e9841569476f88dee74f221006bd)**.

This project conducts an advanced **Spatiotemporal Analysis** to investigate how socioeconomic factors influence assault occurrences across 140 Toronto neighborhoods. By leveraging **Spatial Panel Model by Maximum Likelihood (SPML)**, the study accounts for both temporal dynamics and spatial dependencies.

## 📌 Project Objective
*   **Identify Key Drivers:** Analyze the impact of socioeconomic indicators (Income, Education, Unemployment, etc.) on crime rates.
*   **Account for Spatial Spillover:** Measure how crime in one neighborhood is spatially correlated with its neighbors.
*   **Temporal Dynamics:** Observe changes in crime patterns over a 10-year period (2015-2024).

## 🛠 Tech Stack & Methodology
*   **Language:** R
*   **Spatial Analysis:** `sp` (Classes and Methods for Spatial Data), `sf` (Simple Features), `spatialreg` (Spatial Regression Analysis)
*   **Statistical Modeling:** `splm` (Spatial Panel Model), `plm` (Linear Models for Panel Data), `spdep` (Spatial Dependence: Weighting Schemes, Statistics)
*   **Visualization:** `ggplot2`, `ArcGIS Dashboards`
*   **Core Methodology:** 
    *   **Spatial Weights Matrix:** Developed a Queen-contiguity based weights matrix (`poly2nb`) to model spatial adjacency.
    *   **SPML:** Fitted a Random Effects model with a Spatial Error structure to handle spatiotemporal autocorrelation.

## 📂 Data Sources
*   **Toronto Police Service:** [Assault Open Data (Reported incidents from 2014–2024)](https://data.torontopolice.on.ca/pages/open-data).
*   **City of Toronto Open Data:** [Neighbourhoods Boundary Data](https://open.toronto.ca/dataset/neighbourhoods/)
*   **Wellbeing Toronto (City of Toronto):** [Neighborhood-level demographic data](https://www.toronto.ca/city-government/data-research-maps/neighbourhoods-communities/wellbeing-toronto/) including:
    *   `POP`: Total Population
    *   `INCOME`: After-tax Household Income
    *   `EDUCATION`: Population with Bachelor's Degree or higher
    *   `UNEMPLOYED`: Unemployment rate
    *   `IMMIGRANTS`: Recent immigrant population
    *   `HOUSE_COST`: Households spending >30% of income on shelter

## ⚙️ Key Implementation Details
*   **Data Integration:** Integrated disparate datasets by aligning neighborhood boundaries and correcting inconsistent naming conventions.
*   **Spatiotemporal Expansion:** Transformed cross-sectional demographic data into a long-format panel structure to enable 10-year time-series analysis.
*   **Index Matching:** Ensured data integrity by precisely matching model residuals with spatial indices for accurate mapping and error analysis.

## 🚀 Key Results & Insights
*   **Statistical Significance:** Confirmed that socioeconomic variables such as unemployment rate, immigrant population, housing cost, and education level have a statistically significant impact on assault counts.
*   **Spatial Integrity:** Successfully captured spatial dependencies using the **Spatial Panel Model**, accounting for regional clustering that traditional models overlook.
*   **Anomaly Detection:** Identified geographic "hotspots" where actual crime significantly deviated from socioeconomic predictions through **Residual Mapping**.

## 🖼 Visualization
*   **Exploratory Analysis:** Correlation plots between demographic variables and crime counts.
*   **Residual Map:** Geographic visualization of model errors to identify spatial patterns in unexplained variance.
*   **Live Dashboard:** For an in-depth exploration of the geographic data, please visit the **[ArcGIS Dashboard](https://www.arcgis.com/apps/dashboards/11f4e9841569476f88dee74f221006bd)**.
