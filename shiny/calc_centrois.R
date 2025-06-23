#set wd to file location
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# read in full data
full_data <- read_csv("../data/final_data.csv", show_col_types = FALSE)

# calculate centroids for each neighborhood
centroids <- full_data %>%
  group_by(Neighborhood) %>%
  summarise(
    Latitude_Centroid = mean(Latitude_Raw, na.rm = TRUE),
    Longitude_Centroid = mean(Longitude_Raw, na.rm = TRUE)
  )

# write centroids to csv in wd
write_csv(centroids, "./centroids.csv")