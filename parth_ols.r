############################################################
# ECON F342 – Applied Econometrics
# FINAL COMPLETE SCRIPT (PREFERRED MODEL: M13)
# Sanitation & Women Nutrition – NFHS-5 India
############################################################


############################################################
# SECTION 1: LOAD REQUIRED LIBRARIES
############################################################

library(car)
library(lmtest)
library(sandwich)


############################################################
# SECTION 2: LOAD DATASET
############################################################

data <- read.csv(
  "C:/Users/parth/OneDrive/Desktop/applied-econometrics-project/final_sanitation_bmi_dataset.csv"
)

cat("Total observations:", nrow(data), "\n")


############################################################
# DATA DESCRIPTION
#
# Source: NFHS-5 (2019–21), India
# Unit of Observation: Individual woman (age 15–49)
# Sample Size: 480,052 women
#
# Dependent Variable:
# bmi (continuous, kg/m²)
#
# Main Explanatory Variable:
# improved_toilet (1 = improved sanitation facility)
#
# Key Feature of Final Model:
# Allows sanitation effect to differ between
# rural and urban areas (interaction model).
#
# Objective:
# Examine whether improved sanitation
# is associated with higher BMI,
# and whether this effect differs by residence.
############################################################
############################################################
# SECTION 2A: SAMPLE DATA DESCRIPTION OUTPUT
############################################################

cat("\n================ SAMPLE DESCRIPTION ================\n")

# Sample size
cat("Total observations:", nrow(data), "\n")

# Missing values summary
cat("\nMissing Values (Key Variables):\n")
key_vars <- c("bmi","improved_toilet","urban",
              "education_level","wealth",
              "children_born","age_first_birth")

print(colSums(is.na(data[key_vars])))

# Continuous variables summary
# Continuous variables summary
cat("\nContinuous Variables Summary:\n")

cont_vars <- c("bmi","age","children_born","age_first_birth")

cont_summary <- data.frame(
  Variable = cont_vars,
  Mean = sapply(data[cont_vars], mean, na.rm=TRUE),
  SD   = sapply(data[cont_vars], sd, na.rm=TRUE),
  Min  = sapply(data[cont_vars], min, na.rm=TRUE),
  Max  = sapply(data[cont_vars], max, na.rm=TRUE)
)

# Round only numeric columns
cont_summary[, -1] <- round(cont_summary[, -1], 3)

print(cont_summary)

# Proportion with improved sanitation
cat("\nProportion with Improved Toilet:",
    round(mean(data$improved_toilet, na.rm=TRUE),3), "\n")

cat("\nUrban Distribution (%):\n")
print(round(prop.table(table(data$urban))*100, 2))

# Education distribution
cat("\nEducation Distribution (%):\n")
print(round(prop.table(table(data$education_level))*100,2))

# Wealth distribution
cat("\nWealth Distribution (%):\n")
print(round(prop.table(table(data$wealth))*100,2))

cat("\n====================================================\n")

############################################################
# GRAPH MATRIX USING SAMPLE (FASTER)
############################################################

set.seed(123)

sample_data <- data[sample(1:nrow(data), 5000), ]

scatterplotMatrix(
  ~ bmi + age + children_born + age_first_birth,
  data = sample_data,
  smooth = TRUE,
  regLine = TRUE,
  pch = 16,
  cex = 0.5,
  main = "Scatterplot Matrix with Linear Fit (Sample)"
)
boxplot(bmi ~ improved_toilet,
        data = data,
        col = c("tomato","steelblue"),
        names = c("No Improved Toilet","Improved Toilet"),
        main = "BMI by Sanitation Access",
        ylab = "BMI (kg/m²)")

boxplot(bmi ~ improved_toilet * urban,
        data = data,
        col = c("tomato","steelblue","orange","darkgreen"),
        names = c("Rural-No","Rural-Yes","Urban-No","Urban-Yes"),
        main = "BMI by Sanitation and Urban Status",
        ylab = "BMI (kg/m²)")
############################################################
# SECTION 3: VARIABLE CONSTRUCTION
############################################################

# Center continuous variables (reduces multicollinearity)

data$age_c  <- data$age - mean(data$age)
data$age_c2 <- data$age_c^2

data$children_c <- data$children_born - mean(data$children_born)
data$afb_c <- data$age_first_birth - mean(data$age_first_birth)

# Convert categorical variables to factors

factor_vars <- c("education_level","wealth","urban",
                 "caste","religion","state")

data[factor_vars] <- lapply(data[factor_vars], as.factor)


############################################################
# ECONOMETRIC STRATEGY
############################################################

# Dependent variable is continuous → OLS appropriate.
#
# Identification strategy:
# - Compare women within the same state
# - Control for socioeconomic characteristics
# - Control for fertility and demographic factors
# - Include State Fixed Effects
# - Allow sanitation effect to vary by urban status
#
# Estimation:
# Ordinary Least Squares
# Cluster-robust standard errors (PSU level)
############################################################


############################################################
# SECTION 4: ESTIMATE PREFERRED MODEL (M13)
############################################################

M13 <- lm(
  bmi ~ improved_toilet * urban +
    age_c + age_c2 +
    education_level +
    wealth +
    caste +
    religion +
    children_c +
    afb_c +
    state,
  data = data
)


############################################################
# SECTION 5: CLUSTER-ROBUST STANDARD ERRORS
############################################################

cluster_vcov <- function(model, cluster){

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

vcov_M13 <- cluster_vcov(M13, data$cluster)
robust_M13 <- coeftest(M13, vcov_M13)


############################################################
# SECTION 6: OUTPUT RESULTS
############################################################

cat("\n================ PREFERRED MODEL (M13) RESULTS ================\n")

coef_rural <- robust_M13["improved_toilet", ]
coef_inter <- robust_M13[grep("improved_toilet:urban",
                              rownames(robust_M13)), ]

cat("Sanitation Effect (Rural baseline):",
    round(coef_rural[1],4), "\n")
cat("p-value:", coef_rural[4], "\n\n")

cat("Sanitation × Urban Interaction:",
    round(coef_inter[1],4), "\n")
cat("p-value:", coef_inter[4], "\n\n")

cat("R-squared:", round(summary(M13)$r.squared,4), "\n")
cat("Adjusted R-squared:",
    round(summary(M13)$adj.r.squared,4), "\n")
cat("AIC:", AIC(M13), "\n")
cat("BIC:", BIC(M13), "\n")

cat("\nMax VIF:", max(vif(M13)), "\n")


############################################################
# INTERPRETATION
############################################################

# Rural effect:
# Women in rural areas with improved sanitation
# have approximately 0.26 higher BMI units.

# Urban effect:
# Net effect = rural coefficient + interaction term.
# Approx. 0.26 − 0.17 ≈ 0.09 BMI units.

# Interpretation:
# Sanitation has substantially stronger nutritional
# association in rural areas than in urban areas,
# where baseline infrastructure is better.


############################################################
# MODEL COMPARISON SUMMARY (ALL SPECIFICATIONS)
############################################################

# OLS Models Estimated:

# M4 – Full controls + State FE
# R² ≈ 0.1776
# Coef ≈ 0.2465

# M7 – Environmental bundle + State FE
# R² ≈ 0.1787 (highest)
# AIC ≈ 2,685,674 (lowest)
# Coef ≈ 0.2373
# However, VIF ≈ 85 (high multicollinearity)

# M12 – Wealth interaction model
# R² ≈ 0.1776
# Coef ≈ 0.2971
# Interaction mostly insignificant except richest

# M13 – Urban heterogeneity model (Preferred)
# R² ≈ 0.1776
# AIC ≈ 2,686,289
# Coef (Rural) ≈ 0.2622
# Interaction significant (p < 0.01)
# Lower multicollinearity than M7
# Strong policy interpretation


############################################################
# PREVIOUS LOGIT SPECIFICATIONS (BINARY OUTCOME)
############################################################

# Logit Model (Underweight as DV):
# Pseudo R² ≈ 0.0937
# Odds Ratio ≈ 0.93
# Interpretation:
# Improved sanitation associated with
# ~7% lower odds of undernutrition.

# Simpler Logit (SES only):
# Pseudo R² ≈ 0.067
# Odds Ratio ≈ 0.76
# Larger apparent effect due to omitted variable bias.

# Conclusion:
# Logit and OLS tell consistent story:
# Sanitation effect shrinks with controls,
# remains statistically significant,
# economically modest.


############################################################
# FINAL CONCLUSION
############################################################

# Across both binary and continuous specifications,
# improved sanitation is positively associated
# with women’s nutritional status.

# Effect size:
# Approximately 0.24–0.26 BMI units in rural areas.
# Much smaller in urban areas.

# Socioeconomic factors (wealth, education)
# explain substantially more variation than sanitation.

# Cross-sectional data:
# Results reflect conditional associations,
# not causal estimates.
############################################################