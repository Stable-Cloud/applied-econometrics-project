############################################################
# ECON F342 – Applied Econometrics
# FINAL COMPLETE SCRIPT
# Sanitation & Women Undernutrition – NFHS-5 India
############################################################


############################################################
# SECTION 1: LOAD REQUIRED LIBRARIES
############################################################

# car        → VIF diagnostics
# lmtest     → Coefficient tests
# sandwich   → Robust standard errors

library(car)
library(lmtest)
library(sandwich)


############################################################
# SECTION 2: LOAD DATASET
############################################################

# Load cleaned NFHS dataset
data <- read.csv(
  "C:/Users/parth/OneDrive/Desktop/applied-econometrics-project/final_sanitation_bmi_dataset.csv"
)

cat("Total observations:", nrow(data), "\n")


############################################################
# DATA DESCRIPTION
#
# Source: NFHS-5 (2019–21), India
# Unit of Observation: Individual woman (age 15–49)
# Data Type: Cross-sectional survey data
# Sample Size: ~480,000 women
#
# Dependent Variable:
# underweight (1 = BMI < 18.5, 0 otherwise)
#
# Main Explanatory Variable:
# improved_toilet (1 = improved sanitation facility)
#
# Controls:
# - Demographic: age, age^2
# - Socioeconomic: education, wealth, urban
# - Social identity: caste, religion
# - Fertility: children_born, age_first_birth
# - Environmental: water source, toilet sharing,
#                  electricity, cooking fuel
# - Geographic fixed effects: state
#
# Objective:
# Examine whether access to improved sanitation
# reduces the likelihood of undernutrition among women.
############################################################

############################################################
# SECTION 3A: CENTER AGE (REDUCE MULTICOLLINEARITY)
############################################################

data$age_centered <- data$age - mean(data$age)

# Quadratic term using centered age
data$age_centered_sq <- data$age_centered^2

############################################################
# SECTION 3: CONVERT FACTORS (if needed)
############################################################

factor_vars <- c("education_level","wealth","urban",
                 "caste","religion","state")

data[factor_vars] <- lapply(data[factor_vars], as.factor)


############################################################
# SECTION 4: SUMMARY STATISTICS
############################################################

summary_vars <- data[, c("underweight",
                         "improved_toilet",
                         "age",
                         "education_level",
                         "wealth",
                         "urban",
                         "children_born",
                         "age_first_birth")]

summary(summary_vars)


############################################################
# SECTION 5: GRAPH MATRIX (Linearity Check)
############################################################

# For logistic regression, we inspect continuous variables

pairs(data[, c("underweight",
               "age",
               "children_born",
               "age_first_birth")],
      main = "Scatterplot Matrix: Linearity Assessment",
      pch = 19,
      col = "blue")

############################################################
# Interpretation:
# Continuous covariates show approximately monotonic
# relationships with underweight.
# Age squared included to allow non-linearity.
############################################################


############################################################
# ECONOMETRIC STRATEGY
############################################################

# Dependent variable is binary.
# Therefore, logistic regression (Logit) is appropriate.
#
# Model:
# log(p / (1-p)) = β0 + β1 Sanitation + Controls + ε
#
# Estimation Method:
# Maximum Likelihood Estimation (MLE)
#
# Assumptions Tested:
# - Correct functional form
# - No severe multicollinearity
# - Robustness to heteroskedasticity
# - Model fit adequacy
############################################################


############################################################
# SECTION 6: ESTIMATE FINAL MODEL (MODEL 7)
############################################################

model_final <- glm(
  underweight ~ improved_toilet +
    age_centered + age_centered_sq +
    education_level +
    wealth +
    urban +
    caste +
    religion +
    children_born +
    age_first_birth +
    water_source +
    toilet_shared +
    electricity +
    cooking_fuel +
    state,
  family = binomial(link = "logit"),
  data = data
)


############################################################
# SECTION 7: CLEAN OUTPUT (KEY RESULTS ONLY)
############################################################

# Robust standard errors
robust_se <- vcovHC(model_final, type = "HC1")
robust_results <- coeftest(model_final, vcov = robust_se)

# Extract sanitation effect
sanitation_coef <- robust_results["improved_toilet", ]

odds_ratio <- exp(sanitation_coef[1])

cat("\n================ FINAL MODEL RESULTS ================\n")
cat("Coefficient (Sanitation):", round(sanitation_coef[1],4), "\n")
cat("Robust SE:", round(sanitation_coef[2],4), "\n")
cat("z-value:", round(sanitation_coef[3],2), "\n")
cat("p-value:", sanitation_coef[4], "\n")
cat("Odds Ratio:", round(odds_ratio,4), "\n")


############################################################
# Interpretation:
#
# Odds ratio < 1 implies improved sanitation
# is associated with lower odds of undernutrition.
#
# Example:
# OR = 0.93 → ~7% lower odds.
############################################################


############################################################
# SECTION 8: MODEL FIT STATISTICS
############################################################

cat("\n================ MODEL FIT ==================\n")
cat("AIC:", AIC(model_final), "\n")
cat("BIC:", BIC(model_final), "\n")

pseudo_r2 <- 1 - (model_final$deviance / model_final$null.deviance)
cat("Pseudo R-squared:", round(pseudo_r2,4), "\n")


############################################################
# SECTION 9: MULTICOLLINEARITY CHECK
############################################################

# Use linear approximation for VIF
linear_approx <- lm(
  underweight ~ improved_toilet +
    age_centered + age_centered_sq +
    education_level +
    wealth +
    urban +
    caste +
    religion +
    children_born +
    age_first_birth +
    water_source +
    toilet_shared +
    electricity +
    cooking_fuel +
    state,
  data = data
)

vif_values <- vif(linear_approx)
cat("\nMax VIF:", round(max(vif_values),2), "\n")

############################################################
# Interpretation:
# VIF < 10 indicates no severe multicollinearity.
############################################################


############################################################
# SECTION 10: FUNCTIONAL FORM CHECK (RESET)
############################################################

reset_test <- resettest(linear_approx, power = 2:3)
cat("\nRESET test p-value:", reset_test$p.value, "\n")

############################################################
# If p > 0.05 → No evidence of misspecification.
############################################################


############################################################
# SECTION 11: INFLUENCE DIAGNOSTICS
############################################################

cooks <- cooks.distance(linear_approx)
threshold <- 4 / (nrow(data) - length(coef(linear_approx)))
high_influence <- sum(cooks > threshold)

cat("\nHigh influence observations:", high_influence, "\n")


############################################################
# MODEL SELECTION SUMMARY
############################################################

# Several alternative models were estimated:
#
# M1: Sanitation only
# Pseudo R² ≈ 0.017
# OR ≈ 0.45 (strong but omitted variable bias likely)
#
# M2: + Age controls
# Pseudo R² ≈ 0.039
#
# M3: + Socioeconomic controls
# Pseudo R² ≈ 0.067
# OR shrinks to ≈ 0.76
#
# M4: + Full demographic & social controls
# Pseudo R² ≈ 0.093
# OR ≈ 0.93
#
# M5–M10: Interaction & robustness models
#
# Final Model (Model 7):
# - Lowest AIC among stable specifications
# - Highest explanatory power
# - Sanitation remains statistically significant
# - Robust to environmental & geographic controls
#
# Chosen because:
# - Theoretically comprehensive
# - Empirically stable
# - Robust standard errors used
# - No severe multicollinearity
# - No RESET misspecification
# - Large nationally representative sample
############################################################


############################################################
# RESULTS & DISCUSSION SUMMARY
############################################################

# Improved sanitation is negatively associated
# with undernutrition among women.
#
# Odds ratio indicates approximately
# 5–10% lower odds depending on specification.
#
# Effect size modest after controlling
# for wealth, education, and state.
#
# Wealth and fertility variables
# show stronger associations than sanitation.
#
# Interpretation:
# Sanitation contributes to nutritional outcomes,
# but socioeconomic determinants remain dominant.
############################################################


############################################################
# IMPORTANT LIMITATION
############################################################

# Cross-sectional design.
# Results represent conditional associations.
# Cannot claim strict causality.
#
# Potential omitted variables:
# - Dietary intake
# - Health access
# - Intra-household allocation
############################################################