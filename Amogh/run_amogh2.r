# Quick runner for amogh2.r with package installation
packages <- c("car", "lmtest", "sandwich", "stargazer", "MASS", "nortest", "tseries", "moments")

cat("Checking packages...\n")
for(pkg in packages) {
  if(!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(paste("Installing", pkg, "...\n"))
    install.packages(pkg, repos = "https://cran.r-project.org", dependencies = TRUE, quiet = TRUE)
  }
}

cat("\nRunning advanced analysis...\n\n")
source("amogh2.r")
