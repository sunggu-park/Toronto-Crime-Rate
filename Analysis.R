library(sf)
library(dplyr)
library(spdep)
library(ggplot2)
library(sp)
library(readxl)
library(spatialreg)
library(tidyr)
library(splm)
library(plm)
library(purrr)

# Reported assault counts
crime <- st_read("~/Documents/U of T/GGR376/Assignment/Final Project/data/Assault_Open_Data/ASSAULT_OPEN_DATA.shp");
# Demographic data
test <- read.csv("~/Documents/U of T/GGR376/Assignment/Final Project/data/wellbeing_toronto.csv");
# Toronto neighbourhood boundaries  
neighbour140 <- st_read("~/Documents/U of T/GGR376/Assignment/Final Project/data/Neighbourhoods(140)/Neighbourhoods - historical 140 - 4326.shp"); 

crime_summary <- crime %>% group_by(NEIGHBOU_1, REPORT_YEA) %>% summarise(Crime_Count = n(), .groups = "drop");

# Make AREA_NA7 compareable with Neighbourhood in demographic data
neighbour140$AREA_NA7 <- gsub(" \\(\\d+\\)$", "", neighbour140$AREA_NA7);

# Correct neighbourhood name in demographic 
test$Neighbourhood[test$Neighbourhood == "Mimico"] <- "Mimico (includes Humber Bay Shores)";
test$Neighbourhood[test$Neighbourhood == "Danforth-East York"] <- "Danforth East York";
test$Neighbourhood[test$Neighbourhood == "Weston-Pellam Park"] <- "Weston-Pelham Park";
test$Neighbourhood[test$Neighbourhood == "Dovercourt-Wallace Emerson-Juncti"] <- "Dovercourt-Wallace Emerson-Junction";

# Rename the columns in demographic data
colnames(test)[colnames(test) == "Total.Population"] <- "POP";
colnames(test)[colnames(test) == "With.Bachelor.Degree.or.Higher"] <- "EDUCATION";
colnames(test)[colnames(test) == "After.Tax.Household.Income"] <- "INCOME";
colnames(test)[colnames(test) == "X...Unemployed"] <- "UNEMPLOYED";
colnames(test)[colnames(test) == "Recent.Immigrants"] <- "IMMIGRANTS";
colnames(test)[colnames(test) == "High.Shelter.Costs"] <- "HOUSE_COST";

# Select only the variables of interest from demographic data and add them to boundary data
demographic <- neighbour140 %>% left_join(test[, -c(2, 3, 5)], by = c("AREA_NA7" = "Neighbourhood"));
demographic_subset <- demographic %>% select(AREA_DE8, POP, EDUCATION, INCOME, UNEMPLOYED, IMMIGRANTS, HOUSE_COST); 

# count total number of crime for each year in each neighbourhood in Toronto 
crime_counts <- crime %>%
  st_drop_geometry() %>%  
  group_by(REPORT_YEA, NEIGHBOU_1) %>%  
  summarise(count = n(), .groups = "drop") %>%
  tidyr::pivot_wider(names_from = REPORT_YEA,
                     values_from = count,
                     names_prefix = "count_",
                     values_fill = 0);

# add yearly crime counts to demographic data
cleaned_data <- left_join(demographic_subset, crime_counts, by = c("AREA_DE8" = "NEIGHBOU_1"));

# Save cleaned dataset as .shp
#st_write(cleaned_data, "~/Documents/U of T/GGR376/Assignment/Final Project/Processed Data/cleaned_data.shp", delete_dsn = TRUE);

###### Spatiotemporal modeling (SPLM) #####
# Duplicate each neighbourhood in demographic data for each year
years <- 2014:2024;
demographic_expanded <- demographic_subset %>% 
  slice(rep(1:n(), each = length(years))) %>% 
  mutate(REPORT_YEA = rep(years, times = nrow(demographic_subset)));

# Drop geometry column from crime_summary
crime_summary_df <- st_drop_geometry(crime_summary);
crime_summary_df$REPORT_YEA <- as.integer(crime_summary_df$REPORT_YEA);

model_data <- demographic_expanded %>%
  left_join(crime_summary_df, by = c("AREA_DE8" = "NEIGHBOU_1", "REPORT_YEA"));

# Create weights matrix (poly2nb() assumes each row is a unique spatial unit, so need to use wide data (demographic_subset) instead of long data format)
nb <- poly2nb(demographic_subset, queen = TRUE);
#summary(nb)
nbw <- nb2listw(nb, style = "W", zero.policy = TRUE);
#print(nbw, zero.policy = TRUE)

# Convert to pdata.frame
pdata <- pdata.frame(model_data, index = c("AREA_DE8", "REPORT_YEA"));

# Fit SPML model
spml_model <- spml(
  Crime_Count ~ POP + INCOME + EDUCATION + UNEMPLOYED + IMMIGRANTS + HOUSE_COST,
  data = pdata,
  listw = nbw,
  index = c("AREA_DE8", "REPORT_YEA"),
  model = "random",         
  spatial.error = "b"       
);

# Check the statistical summary, coefficients, and goodness of fit (AIC/BIC)
summary(spml_model);

# Attach model residuals to pdata
res_df <- data.frame(row_id = names(residuals(spml_model)), 
                     res_value = as.numeric(residuals(spml_model)));

pdata$residuals <- res_df$res_value[match(row.names(pdata), 
                                          res_df$row_id)]; # pdata row name = res_df row_id

head(pdata[, c("AREA_DE8", "REPORT_YEA", "residuals")]);

# Convert panel data residuals into a wide format for mapping by year
residuals_wide <- pdata %>%
  select(AREA_DE8, REPORT_YEA, residuals) %>%
  tidyr::pivot_wider(names_from = REPORT_YEA,
                     values_from = residuals,
                     names_prefix = "resid_");

# Attach the calculated residuals to the spatial boundary data
map_data <- demographic_subset %>%
  left_join(residuals_wide, by = "AREA_DE8");

# save residual data as shapefile
#st_write(map_data, "~/Desktop/model_residual/residual.shp", delete_dsn = TRUE);


###### Visualization #####
# pop vs crime_2016
ggplot(cleaned_data, aes(x = POP, y = count_2016)) +
  geom_point(color = "steelblue", alpha = 0.7) +   
  geom_smooth(method = "lm", se = TRUE, color = "darkred") + 
  labs(
    title = "Relationship Between Population and Assault Count in Toronto (2016)",
    x = "Population",
    y = "Reported Assault Cases"
  ) +
  theme_minimal()

# education vs crime_2016
ggplot(cleaned_data, aes(x = EDUCATION, y = count_2016)) +
  geom_point(color = "steelblue", alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, color = "darkred") +
  labs(
    title = "Relationship Between Education Level and Assault Count in Toronto (2016)",
    x = "Number of People with a Bachelor’s Degree or Higher",
    y = "Reported Assault Cases"
  ) +
  theme_minimal()

# income vs assault
ggplot(cleaned_data, aes(x = INCOME, y = count_2016)) +
  geom_point(color = "steelblue", alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, color = "darkred") +
  labs(
    title = "Relationship Between Household Income and Assault Count in Toronto (2016)",
    x = "Median After-Tax Household Income",
    y = "Reported Assault Cases"
  ) +
  theme_minimal()

# unemployment vs assault
ggplot(cleaned_data, aes(x = UNEMPLOYED, y = count_2016)) +
  geom_point(color = "steelblue", alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, color = "darkred") +
  labs(
    title = "Relationship Between Unemployment and Assault Count in Toronto (2016)",
    x = "Unemployment",
    y = "Reported Assault Cases"
  ) +
  theme_minimal()

# IMMIGRANTS vs assault
ggplot(cleaned_data, aes(x = IMMIGRANTS, y = count_2016)) +
  geom_point(color = "steelblue", alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, color = "darkred") +
  labs(
    title = "Relationship Between Immigrant and Assault Count in Toronto (2016)",
    x = "Number of Immigrants",
    y = "Reported Assault Cases"
  ) +
  theme_minimal()

# HOUSE_COST vs assault
ggplot(cleaned_data, aes(x = HOUSE_COST, y = count_2016)) +
  geom_point(color = "steelblue", alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, color = "darkred") +
  labs(
    title = "Relationship Between Housing Cost and Assault Count in Toronto (2016)",
    x = "Number of Households Spending 30% or More of Income on Shelter and Rent Costs",
    y = "Reported Assault Cases"
  ) +
  theme_minimal()

# Residual map for specific year 
ggplot(map_data) +
  geom_sf(aes(fill = resid_2016)) +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0, na.value = "grey90") +
  labs(
    title = "Model Residuals for Assault Occurrences (2016)",
    subtitle = "Red: Underestimated (Actual > Predicted) | Blue: Overestimated",
    fill = "Residual"
  ) +
  theme_minimal() +
  theme(plot.background = element_rect(fill = "white", color = NA));

# Generate residual maps for each year from 2014 to 2024
walk(years, function(yr) {
  # Construct the column name ("resid_2014" ~ "resid_2024")
  col_name <- paste0("resid_", yr)
  
  # Generate the plot
  p <- ggplot(map_data) +
    geom_sf(aes(fill = .data[[col_name]])) +
    scale_fill_gradient2(
      low = "blue", 
      mid = "white", 
      high = "red", 
      midpoint = 0,
      na.value = "grey90"
    ) +
    labs(
      title = paste("Model Residuals for Assault Occurrences (", yr, ")", sep = ""),
      subtitle = "Red: Underestimated (Actual > Predicted) | Blue: Overestimated",
      fill = "Residual"
    ) +
    theme_minimal()+
    theme(plot.background = element_rect(fill = "white", color = NA))
  
  # Display the plot
  print(p)
  
  # save plots as images
  #ggsave(filename = paste0("Toronto_Residual_", yr, ".png"), plot = p, width = 8, height = 6)
});

