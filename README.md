# 📊 Spatiotemporal Analysis of Assault Occurrences in Toronto (2015-2024)


This project investigates how neighborhood-level socioeconomic characteristics influence assault crime across **140 Toronto neighborhoods** over time.

Using a **Spatial Panel Model by Maximum Likelihood (SPML)**, the analysis explicitly accounts for:

- 📍 **Spatial dependence** (crime spillover across adjacent neighborhoods)  
- ⏳ **Temporal variation** (2015, 2018, 2021, 2024)  

The goal is to determine whether demographic and socioeconomic factors can explain spatial and temporal variations in assault crime.

> 🔎 Interactive visualization available on the **[ArcGIS Dashboard](https://www.arcgis.com/apps/dashboards/11f4e9841569476f88dee74f221006bd)**
<img width="1431" height="807" alt="sc" src="https://github.com/user-attachments/assets/c6337e31-3ff0-4e4d-a8da-3faa26cb8b15" />

---

## 🎯 Research Motivation

Toronto is one of North America’s largest metropolitan areas, with a population exceeding 3 million. While often ranked among the safest major cities, assault rates have increased in recent years.

Urban crime is rarely spatially random.  
It reflects structural inequalities, housing pressures, labor market conditions, and demographic composition.

This study applies spatial econometric methods to examine:

- Do neighborhood socioeconomic conditions significantly influence assault crime?
- Are crime patterns spatially clustered?
- Does incorporating spatial structure improve inference?

---

## 📂 Data Overview

### Spatial Unit
- 140 City-designated social planning neighborhoods  
- Consistent boundary version used across all years  

### Temporal Scope
- 2015  
- 2018  
- 2021  
- 2024  

### Final Panel Structure
- 140 neighborhoods × 4 years  
- **560 observations**

---

## 📟 Data Sources

### 1️⃣ Assault Incidents (2014–2024)  
[Toronto Police Service Open Data](https://data.torontopolice.on.ca/pages/open-data)  
Point-level crime occurrences aggregated to yearly neighborhood counts.

### 2️⃣ Neighborhood Boundaries  
[City of Toronto Open Data](https://open.toronto.ca/dataset/neighbourhoods/)  
Polygon shapefile used for spatial joins and weight matrix construction.

### 3️⃣ Demographic & Socioeconomic Variables (Census-based)  
[Wellbeing Toronto dataset](https://www.toronto.ca/city-government/data-research-maps/neighbourhoods-communities/wellbeing-toronto/):

- Total population  
- Median after-tax household income  
- Education level (Bachelor’s degree or higher)  
- Unemployment  
- Immigrant population  
- Housing cost burden (>30% of income on shelter)

---

# 🛠 Data Preprocessing

Because the datasets originated from different sources and formats, extensive preprocessing was required.

## Key Steps

- Unified coordinate system to **WGS84 / UTM Zone 17N (EPSG:32617)**
- Corrected neighborhood naming inconsistencies
- Joined demographic data to neighborhood polygons
- Aggregated point-level assault records → yearly counts
- Converted cross-sectional census data → long-format panel
- Duplicated neighborhood rows across time periods
- Constructed spatial weights matrix (Queen contiguity)

The resulting dataset contains:

- 560 observations  
- 6 demographic predictors  
- Assault crime count (response variable)  
- Polygon geometry  

---

## 📈 Exploratory Analysis

Simple linear regressions between each predictor and assault count show:

### Positive relationships:
- Unemployment
<img width="500" height="500" alt="employ" src="https://github.com/user-attachments/assets/d612b1e6-7c8f-4239-8370-8c38738becdb" />

- Housing cost burden
<img width="500" height="500" alt="housing" src="https://github.com/user-attachments/assets/c72e9c2f-452f-4e94-b1dd-a0570b22d179" />
 
- Population
<img width="500" height="500" alt="pop" src="https://github.com/user-attachments/assets/20fe9da6-7a43-451e-8264-1a06f2047c44" />
  
- Immigrant population
<img width="500" height="500" alt="immigrant" src="https://github.com/user-attachments/assets/216e4da3-5f4a-450c-8c3e-3a09c4ed45c1" />

- Education level
<img width="500" height="500" alt="edu" src="https://github.com/user-attachments/assets/0a8abeb3-2559-49ab-bbc4-c6d261b4bcb3" />
  
### Negative relationship:
- Income
<img width="500" height="500" alt="income" src="https://github.com/user-attachments/assets/e94daca1-b1e1-4ab2-bbe0-88c5a25e8c2c" />

Population, unemployment, and housing cost exhibit the clearest linear patterns.

However, these bivariate relationships do not account for spatial dependence.

---

## 🧠 Modeling Approach

### Spatial Panel Model by Maximum Likelihood (SPML)
Urban crime data typically exhibit two important characteristics:

1. **Temporal dependence** — crime levels change over time.
2. **Spatial dependence** — neighboring areas tend to display similar crime patterns.

A traditional cross-sectional regression would ignore temporal dynamics, while a standard panel model would assume spatial independence across neighborhoods. Because both assumptions are unrealistic in an urban setting, a **Spatial Panel Model (SPML)** was adopted.

This approach allows the analysis to simultaneously account for:
- Repeated observations across time (panel structure)
- Geographic interdependence between neighborhoods (spatial structure)

### Predictors
- Population  
- Income  
- Education  
- Unemployment  
- Immigrant population  
- Housing cost burden  

### Spatial Weights
- Queen contiguity matrix based on neighborhood adjacency

### Response Variable
- Assault crime count
  
---

## 📊 Model Results

```
> summary(spml_model);
ML panel with , random effects, spatial error correlation 

Call:
spreml(formula = formula, data = data, index = index, w = listw2mat(listw), 
    w2 = listw2mat(listw2), lag = lag, errors = errors, cl = cl)

Residuals:
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
-264.72  -40.04   -2.04   -0.02   29.00  592.79 

Error variance parameters:
    Estimate Std. Error t-value  Pr(>|t|)    
phi 3.013888   0.389565  7.7366 1.021e-14 ***
rho 0.402123   0.031909 12.6023 < 2.2e-16 ***

Coefficients:
               Estimate  Std. Error t-value  Pr(>|t|)    
(Intercept) -2.7652e+01  3.3152e+01 -0.8341  0.404228    
POP         -6.4636e-03  2.6031e-03 -2.4830  0.013029 *  
INCOME       2.7315e-04  5.4326e-04  0.5028  0.615105    
EDUCATION   -1.3361e-02  4.4703e-03 -2.9890  0.002799 ** 
UNEMPLOYED   2.0404e-01  5.5204e-02  3.6960  0.000219 ***
IMMIGRANTS  -6.0077e-02  8.7722e-03 -6.8485 7.462e-12 ***
HOUSE_COST   9.0789e-02  1.2335e-02  7.3606 1.831e-13 ***
---
Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
```

<p align="center">
  <table>
    <tr>
      <td align="center"><br><img src="https://github.com/user-attachments/assets/12ef1c24-ce78-40ab-bb3c-20377299af04" width="700"></td>
      <td align="center"><br><img src="https://github.com/user-attachments/assets/c1acce2e-20ba-4704-ba08-f0e48bda3c49" width="700"></td>
    </tr>
    <tr>
      <td align="center"><br><img src="https://github.com/user-attachments/assets/3c9619a0-299f-4b2b-9cae-41c53dbad49c" width="500"></td>
      <td align="center"><br><img src="https://github.com/user-attachments/assets/60a3ef97-4dc0-430a-bc2d-faede1545f33" width="500"></td>
    </tr>
  </table>
</p>


### 🔹 Spatial Dependence

The estimated spatial autocorrelation parameter (ρ ≈ 0.40, p < 0.001) is positive and highly statistically significant. This indicates that assault crime exhibits strong spatial clustering across Toronto neighborhoods. In other words, crime levels in one neighborhood are systematically associated with crime levels in adjacent neighborhoods. 

This result confirms that the assumption of independent spatial units would be inappropriate. Ignoring spatial dependence could lead to biased coefficient estimates and misleading inference. The significance of ρ validates the use of a spatial panel specification rather than a traditional panel regression model.

### 🔹 Effects of Socioeconomic Predictors

After controlling for spatial dependence and random effects, several socioeconomic variables remain statistically significant at the 1% level.

Unemployment shows a positive and significant association with assault crime. Neighborhoods with higher numbers of unemployed residents tend to experience higher assault counts, suggesting that labor market stress may contribute to crime risk.

Housing cost burden (households spending more than 30% of income on shelter) also demonstrates a positive and statistically significant effect. This indicates that economic pressure related to housing affordability may be an important structural driver of assault crime.

Education (number of residents with a bachelor’s degree or higher) exhibits a negative and significant relationship with crime. This suggests that higher educational attainment may function as a protective factor at the neighborhood level.

Interestingly, the immigrant population variable shows a negative and significant association with assault crime. Once spatial structure and other socioeconomic factors are controlled for, neighborhoods with larger immigrant populations tend to have lower assault counts. This finding challenges common assumptions and highlights the importance of multivariate spatial modeling.

In contrast, total population and median after-tax household income are not statistically significant predictors in the full spatial panel model. Although these variables appeared related to crime in simple bivariate analysis, their effects diminish once spatial dependence and other covariates are incorporated. This suggests that structural socioeconomic stressors may be more informative than sheer population size or aggregate income levels.

### 🔹 Residual Diagnostics and Model Behavior

The mean residual of the model is approximately zero (−0.02), indicating that predictions are unbiased on average. However, the range of residuals (from −264.72 to 592.79) suggests that prediction errors can be substantial for certain neighborhoods and time periods.

Residual maps reveal a consistent pattern of underestimation across many neighborhoods. Positive residuals dominate, meaning that the observed assault counts are often higher than predicted by the model. This systematic underprediction suggests that important explanatory variables may be missing from the specification.

Spatially, higher residuals are concentrated in northwestern, eastern, and southwestern areas of Toronto, while central and western neighborhoods tend to show smaller residual magnitudes. The persistence of these spatial patterns over multiple time periods implies that localized structural factors—such as policing intensity, community infrastructure, or social services—may play an additional role beyond the demographic variables included in the model.

### 🔹 Overall Interpretation

Taken together, the results indicate that assault crime in Toronto is shaped by both spatial spillover effects and neighborhood-level socioeconomic conditions. Structural stress indicators—particularly unemployment and housing affordability—are robust predictors, while education appears to mitigate crime risk.

The statistically significant spatial parameter confirms that crime dynamics cannot be understood without accounting for geographic interdependence. Although the model explains a meaningful portion of spatial and temporal variation, residual patterns suggest that further model refinement could improve predictive performance.

---

## 🔎 Key Insights

1️⃣ Assault crime in Toronto exhibits significant spatial clustering, confirming that neighborhood outcomes are geographically interdependent.

2️⃣ Structural socioeconomic stressors (unemployment, housing burden) are strong and consistent predictors of assault crime.

3️⃣ Higher levels of educational attainment are associated with lower assault counts, suggesting a protective neighborhood-level effect.

4️⃣ Population size and median income lose significance once spatial dependence is incorporated, highlighting the importance of modeling geographic structure.

5️⃣ Persistent residual hotspots indicate that additional contextual factors (e.g., age distribution, household crowding) may further improve model performance.

