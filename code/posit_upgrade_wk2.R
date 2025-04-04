# Function to check and install rstudioapi if necessary
install_rstudioapi <- function() {
  if (!requireNamespace("rstudioapi", quietly = TRUE)) {
    cat("The 'rstudioapi' package is not installed. Installing it now...\n")
    install.packages("rstudioapi", quiet = TRUE)
    if (!requireNamespace("rstudioapi", quietly = TRUE)) {
      stop("Failed to install 'rstudioapi'. Please install it manually.")
    }
    cat("'rstudioapi' package has been successfully installed.\n")
  }
}

# Install rstudioapi if not present
install_rstudioapi()

# Get all installed packages
all_packages <- installed.packages()

# Get base packages (those installed with R by default)
base_packages <- rownames(installed.packages(priority = "base"))

# Filter out base packages
user_packages <- all_packages[!rownames(all_packages) %in% base_packages, ]

# Create a data frame with package names and versions
package_info <- data.frame(
  Package = rownames(user_packages),
  Version = user_packages[, "Version"],
  stringsAsFactors = FALSE
)

# Prompt user to select save location
save_path <- rstudioapi::selectFile(
  caption = "Select location to save CSV file",
  label = "Save",
  existing = FALSE,
  filter = "CSV files (*.csv)"
)

# Check if a file was selected
if (!is.null(save_path)) {
  # Ensure the file has a .csv extension
  if (!grepl("\\.csv$", save_path, ignore.case = TRUE)) {
    save_path <- paste0(save_path, ".csv")
  }
  
  # Write the data frame to the selected CSV file
  write.csv(package_info, file = save_path, row.names = FALSE)
  
  # Print a message to confirm the file has been created
  cat("CSV file has been saved to:", save_path, "\n")
} else {
  cat("File save cancelled.\n")
}
