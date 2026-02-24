############################################################
# FINAL MODEL SELECTION SCRIPT
# Sanitation & Undernutrition – NFHS Individual Data
############################################################

rm(list = ls())

############################################################
# 1. LOAD DATA
############################################################

data <- read.csv(
  "C:/Users/parth/OneDrive/Desktop/applied-econometrics-project/final_sanitation_bmi_dataset.csv"
)

data$age_sq <- data$age^2

############################################################
# 2. ESTIMATE MODELS
############################################################

# M3 – SES Core
M3 <- glm(underweight ~ improved_toilet + age + age_sq +
                          education_level + wealth + urban,
          family = binomial, data = data)

# M4 – Full + State FE
M4 <- glm(underweight ~ improved_toilet + age + age_sq +
                          education_level + wealth + urban +
                          caste + religion +
                          children_born + age_first_birth +
                          state,
          family = binomial, data = data)

# M5 – Wealth Interaction
M5 <- glm(underweight ~ improved_toilet * wealth +
                          age + age_sq +
                          education_level + urban +
                          caste + religion +
                          children_born + age_first_birth +
                          state,
          family = binomial, data = data)

# M7 – Environmental Bundle
M7 <- glm(underweight ~ improved_toilet +
                          water_source + toilet_shared +
                          cooking_fuel + electricity +
                          age + age_sq +
                          education_level + wealth + urban +
                          caste + religion +
                          children_born + age_first_birth +
                          state,
          family = binomial, data = data)

# M9 – Region FE (instead of State)
M9 <- glm(underweight ~ improved_toilet + age + age_sq +
                          education_level + wealth + urban +
                          caste + religion +
                          children_born + age_first_birth +
                          region,
          family = binomial, data = data)

############################################################
# 3. CLUSTER-ROBUST SE (for M4)
############################################################

cluster_vcov <- function(model, cluster){
  library(sandwich)
  library(lmtest)
  M <- length(unique(cluster))
  N <- length(cluster)
  K <- model$rank
  dfc <- (M/(M-1)) * ((N-1)/(N-K))
  uj  <- apply(estfun(model), 2,
               function(x) tapply(x, cluster, sum))
  vcovCL <- dfc * sandwich(model,
                           meat = crossprod(uj)/N)
  return(vcovCL)
}

vcov_cluster_M4 <- cluster_vcov(M4, data$cluster)
robust_M4 <- coeftest(M4, vcov_cluster_M4)

############################################################
# 4. FUNCTION TO EXTRACT RESULTS
############################################################

extract_results <- function(model, robust = NULL){

  pseudo_r2 <- 1 - (model$deviance / model$null.deviance)

  if(is.null(robust)){
    coef_val <- summary(model)$coefficients["improved_toilet", ]
    p_val <- coef_val[4]
  } else {
    coef_val <- robust["improved_toilet", ]
    p_val <- coef_val[4]
  }

  return(c(
    N           = nobs(model),
    AIC         = AIC(model),
    BIC         = BIC(model),
    PseudoR2    = pseudo_r2,
    Coefficient = coef_val[1],
    OddsRatio   = exp(coef_val[1]),
    p_value     = p_val
  ))
}

############################################################
# 5. BUILD FINAL COMPARISON TABLE
############################################################

results <- rbind(
  M3  = extract_results(M3),
  M4  = extract_results(M4),
  M5  = extract_results(M5),
  M7  = extract_results(M7),
  M9  = extract_results(M9),
  M10 = extract_results(M4, robust_M4)
)

results <- as.data.frame(results)

cat("\n================ FINAL MODEL SELECTION TABLE ================\n")
print(round(results, 4))
cat("=============================================================\n")