library(sf)
library(dplyr)
library(spdep)
library(ggplot2)
library(sp)
library(readxl)
library(spatialreg)

# load data
assult <- st_read("ASSAULT_OPEN_DATA.shp");
boundary <- st_read("Toronto_Census_Boundaries.shp");
data <- read.csv("census.csv");
downtown_boundary <- st_read("Neighbourhoods v2_region.shp");
# change data type of a column
boundary$CTUID <- as.numeric(boundary$CTUID)
# merge two datasets
subset <- data[, c("COL0", "COL1", "COL3", "COL4", "COL5")]
merged <- merge(boundary, subset, by.x = "CTUID", by.y = "COL0", all.x = TRUE) 
# change column names
colnames(merged)[colnames(merged) == "COL1"] <- "POP";
colnames(merged)[colnames(merged) == "COL3"] <- "AVG_INCOME";
colnames(merged)[colnames(merged) == "COL4"] <- "EDUCATION";
colnames(merged)[colnames(merged) == "COL5"] <- "AVG_AGE";

# change coordinate systems
downtown_boundary_utm17 <- st_transform(downtown_boundary, crs = 26917);
merged_utm17 <- st_transform(merged, crs = 26917);
# filter out only toronto
toronto <- st_intersection(merged_utm17, downtown_boundary_utm17);
assult <- st_transform(assult, crs = st_crs(toronto)); # reproject to UMT Zone 17N
# merge toronto with assault
assault_joined <- st_join(assult, toronto);

assault_counts <- assault_joined %>%
  st_drop_geometry() %>%  
  group_by(REPORT_YEA, CTUID) %>%  
  summarise(count = n(), .groups = "drop") %>%
  tidyr::pivot_wider(names_from = REPORT_YEA,
                     values_from = count,
                     names_prefix = "count_",
                     values_fill = 0);

#assault_counts$count_total <- rowSums(assault_counts[grep("count_", names(assault_counts))]);

toronto_joined <- left_join(toronto, assault_counts, by = "CTUID");
# Check NAs
col_names <- c("POP", "AVG_INCOME", "EDUCATION", "AVG_AGE", paste0("count_", 2014:2024)); 
colSums(is.na(toronto_joined[, col_names]));

# Replace NA in count_ columns with zero 
toronto_joined$count_2014[is.na(toronto_joined$count_2014)] <- 0
toronto_joined$count_2015[is.na(toronto_joined$count_2015)] <- 0
toronto_joined$count_2016[is.na(toronto_joined$count_2016)] <- 0
toronto_joined$count_2017[is.na(toronto_joined$count_2017)] <- 0
toronto_joined$count_2018[is.na(toronto_joined$count_2018)] <- 0
toronto_joined$count_2019[is.na(toronto_joined$count_2019)] <- 0
toronto_joined$count_2020[is.na(toronto_joined$count_2020)] <- 0
toronto_joined$count_2021[is.na(toronto_joined$count_2021)] <- 0
toronto_joined$count_2022[is.na(toronto_joined$count_2022)] <- 0
toronto_joined$count_2023[is.na(toronto_joined$count_2023)] <- 0
toronto_joined$count_2024[is.na(toronto_joined$count_2024)] <- 0
# year_cols = count_2014 ... count_2024
year_cols <- grep("^count_\\d{4}$", names(toronto_joined), value = TRUE)
# convert count_ columns to numeric 
toronto_joined <- toronto_joined %>% mutate(across(all_of(year_cols), ~ as.numeric(.)))
# Recalculate count_total
toronto_joined$count_total <- rowSums(toronto_joined[, year_cols])

# Replace NA in POP, AVG_INCOME, EDUCATION, AVE_AGE with median value in that column
toronto_joined <- toronto_joined %>% mutate(across(c(POP, AVG_INCOME, EDUCATION, AVG_AGE), ~ ifelse(is.na(.), median(., na.rm = TRUE), .)))

# Save processed dataset as .shp file for ArcGIS
st_write(toronto_joined, "~/Desktop/Toronto Crime/Processed Data/Toronto_joined.shp", delete_dsn = TRUE); 

################################### Visualization #######################################

library(patchwork)
plot_2015 <- ggplot() +
  geom_sf(data = toronto_joined, aes(fill = count_2015), color = "black") +
  scale_fill_viridis_c(option = "C", direction = -1) +
  theme_minimal() +
  labs(title = "2015", fill = "Assault Count")

plot_2018 <- ggplot() +
  geom_sf(data = toronto_joined, aes(fill = count_2018), color = "black") +
  scale_fill_viridis_c(option = "C", direction = -1) +
  theme_minimal() +
  labs(title = "2018", fill = "Assault Count")

plot_2021 <- ggplot() +
  geom_sf(data = toronto_joined, aes(fill = count_2021), color = "black") +
  scale_fill_viridis_c(option = "C", direction = -1) +
  theme_minimal() +
  labs(title = "2021", fill = "Assault Count")

plot_2024 <- ggplot() +
  geom_sf(data = toronto_joined, aes(fill = count_2024), color = "black") +
  scale_fill_viridis_c(option = "C", direction = -1) +
  theme_minimal() +
  labs(title = "2024", fill = "Assault Count")

# Combine all plots in a grid
(plot_2015 | plot_2018) / (plot_2021 | plot_2024)

ggplot(data = toronto_joined) +
  geom_sf(fill = "lightblue", color = "black") +
  theme_minimal() +
  labs(title = "Boundary Map");


ggplot() +
  geom_sf(data = toronto, fill = "white", color = "black") +  # polygon
  geom_sf(data = assult, color = "red", size = 1, alpha = 0.6) +  # points
  theme_minimal() +
  labs(title = "Assault Locations in Toronto");

library(scales)
ggplot() +
  geom_sf(data = toronto_joined, aes(fill = AVG_INCOME), color = "black") +
  scale_fill_viridis_c(option = "C", direction = -1, labels = label_comma()) +
  theme_minimal() +
  labs(title = "Average Household Income in Toronto", fill = "Income ($)")
