# Install required packages if not already installed
required_packages <- c("car", "lmtest", "sandwich", "stargazer", "MASS", 
                       "nortest", "tseries", "moments")

for(pkg in required_packages) {
  if(!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.r-project.org", quiet = TRUE)
    library(pkg, character.only = TRUE)
  }
}

# Now source the main analysis file
source("amogh.r")
