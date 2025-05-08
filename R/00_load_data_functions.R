# R/00_load_data_functions.R

#' Load a pipe-delimited text file into a DuckDB table.
#'
#' @param con A DuckDB connection object.
#' @param file_path Character string: the full path to the .txt file.
#' @param col_names_vector A character vector of column names for the table.
#'                         The order must match the columns in the text file.
#' @param target_table_name Character string: the name for the new table in DuckDB.
#' @param delimiter Character: the delimiter used in the file (default is "|").
#'
#' @return TRUE if loading was successful, FALSE otherwise. Prints messages to console.
#'
load_pipe_delimited_file_to_duckdb <- function(con, 
                                               file_path, 
                                               col_names_vector, 
                                               target_table_name,
                                               delimiter = "|") {
  
  if (!requireNamespace("DBI", quietly = TRUE)) {
    stop("Package 'DBI' is required but not installed.")
  }
  if (!requireNamespace("duckdb", quietly = TRUE)) {
    stop("Package 'duckdb' is required but not installed.")
  }
  
  if (!file.exists(file_path)) {
    cat(paste0("<p style='color:red;'><strong>Error:</strong> File not found: `", 
               file_path, "`. Skipping table `", target_table_name, "`.</p>\n"))
    return(FALSE)
  }
  
  if (length(col_names_vector) == 0) {
    cat(paste0("<p style='color:red;'><strong>Error:</strong> No column names provided for `", 
               target_table_name, "`.</p>\n"))
    return(FALSE)
  }
  
  # Reading all as VARCHAR initially for robustness, types will be converted during cleaning.
  # DuckDB's read_csv 'columns' argument expects a struct/map like {'colA':'VARCHAR', 'colB':'INT'}
  # We construct this string dynamically.
  column_definitions_duckdb_char <- paste0("'", col_names_vector, "'", ":'VARCHAR'", collapse = ", ")
  column_definitions_duckdb_char <- paste0("{", column_definitions_duckdb_char, "}")
  
  # Ensure path uses forward slashes for SQL compatibility, even on Windows
  safe_file_path <- gsub("\\\\", "/", file_path)
  
  # Construct the SQL query for loading
  # Using 'read_csv' which is an alias for 'read_csv_auto' in newer DuckDB versions.
  # It can handle pipe delimiters and no headers if specified.
  load_query <- sprintf("
  CREATE OR REPLACE TABLE %s AS
  SELECT * FROM read_csv('%s',
      delim='%s',
      header=false,
      columns=%s,
      auto_detect=false, -- We specified types as VARCHAR to be safe initially
      sample_size=-1,    -- Use whole file for structure, though types are fixed here
      ignore_errors=true -- Be cautious: logs errors to stderr but continues. Inspect data if used.
                         -- Set to false if you want it to stop on any parsing error.
  );", target_table_name, safe_file_path, delimiter, column_definitions_duckdb_char)
  
  tryCatch({
    DBI::dbExecute(con, load_query)
    num_rows <- DBI::dbGetQuery(con, paste0("SELECT COUNT(*) AS count FROM ", target_table_name))$count
    num_cols <- length(DBI::dbListFields(con, target_table_name)) # More robust way to get actual columns loaded
    
    cat(paste0("Successfully loaded `", basename(file_path), "` into DuckDB table `", target_table_name, "`.\n"))
    cat(paste0("  Rows loaded: ", num_rows, ", Columns defined: ", length(col_names_vector), ", Columns in DB: ", num_cols, "\n\n"))
    
    if (length(col_names_vector) != num_cols && num_rows > 0) {
      cat(paste0("<p style='color:orange;'><strong>Warning:</strong> Number of columns defined (", length(col_names_vector), 
                 ") does not match number of columns loaded into `", target_table_name, "` (", num_cols, 
                 "). Please check your column name definitions and the raw file structure.</p>\n"))
    }
    return(TRUE)
  }, error = function(e) {
    cat(paste0("<p style='color:red;'><strong>Error loading `", target_table_name, "` from `", basename(file_path) ,"`:</strong> ", e$message, "</p>\n"))
    return(FALSE)
  })
}