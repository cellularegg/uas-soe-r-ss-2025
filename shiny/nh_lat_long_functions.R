# function for converting lat/long to neighborhoods
#' Convert latitude and longitude to neighborhood
#' @param lat Latitude
#' @param long Longitude
#' @return Neighborhood name
#' #' @examples
#' #' lat_long_to_neighborhood(42.995, -71.467)
lat_long_to_neighborhood <- function(lat, long) {
  # Read in centroids
  centroids <- read.csv("./centroids.csv")
  
  # Calculate distances to each centroid
  distances <- sqrt((centroids$Latitude_Centroid - lat)^2 + (centroids$Longitude_Centroid - long)^2)
  
  # Find the index of the minimum distance
  min_index <- which.min(distances)
  
  # Return the neighborhood name
  return(centroids$Neighborhood[min_index])
}

#' Convert neighborhood to latitude and longitude
#' @param neighborhood Neighborhood name
#' @return The latitude and longitude of the neighborhood centroid
#' #' @examples
#' #' neighborhood_to_lat_long("010201")
neighborhood_to_lat_long <- function(neighborhood) {
  # Read in centroids
  centroids <- read.csv("./centroids.csv")
  
  # Find the row corresponding to the neighborhood
  row <- centroids[centroids$Neighborhood == neighborhood, ]
  
  # Return the latitude and longitude as a list
  return(list(Latitude = row$Latitude_Centroid, Longitude = row$Longitude_Centroid))
}