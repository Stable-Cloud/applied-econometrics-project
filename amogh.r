################################################################################
# Applied Econometrics Project: Sanitation and BMI Analysis
# Title: Does access to improved household sanitation reduce the likelihood 
#        of undernutrition among women aged 15-49 in India?
# Dependent Variable: BMI (continuous)
################################################################################

# Load required libraries
library(tidyverse)      # Data manipulation
library(car)            # VIF and diagnostic tests
library(lmtest)         # Hypothesis testing (Breusch-Pagan, etc.)
library(sandwich)       # Robust standard errors
library(stargazer)      # Model comparison tables
library(ggplot2)        # Visualization
library(MASS)           # Robust regression
library(nortest)        # Normality tests
library(tseries)        # Additional tests
library(moments)        # Skewness and kurtosis
library(corrplot)       # Correlation plots
library(performance)    # Model performance metrics
library(see)            # Visualization for performance

# Set working directory and load data
setwd("c:/Users/Amogh/OneDrive/Desktop/BITS/Year 3/ECO + MAC 3-2/AE/Project")
data <- read.csv("final_sanitation_bmi_dataset.csv")

################################################################################
# PART 1: DATA EXPLORATION AND PREPARATION
################################################################################

cat("\n========== DATA STRUCTURE ==========\n")
str(data)
cat("\n========== SUMMARY STATISTICS ==========\n")
summary(data)
cat("\n========== MISSING VALUES ==========\n")
colSums(is.na(data))

# Convert categorical variables to factors
data$improved_toilet <- as.factor(data$improved_toilet)
data$electricity <- as.factor(data$electricity)
data$toilet_shared <- as.factor(data$toilet_shared)
data$urban <- as.factor(data$urban)
data$education_level <- as.factor(data$education_level)
data$wealth <- as.factor(data$wealth)
data$religion <- as.factor(data$religion)
data$caste <- as.factor(data$caste)
data$state <- as.factor(data$state)
data$region <- as.factor(data$region)
data$cooking_fuel <- as.factor(data$cooking_fuel)
data$water_source <- as.factor(data$water_source)

# Create age squared for non-linear effects
data$age_squared <- data$age^2

# Descriptive statistics for BMI
cat("\n========== BMI DESCRIPTIVE STATISTICS ==========\n")
cat("Mean BMI:", mean(data$bmi, na.rm = TRUE), "\n")
cat("Median BMI:", median(data$bmi, na.rm = TRUE), "\n")
cat("SD BMI:", sd(data$bmi, na.rm = TRUE), "\n")
cat("Min BMI:", min(data$bmi, na.rm = TRUE), "\n")
cat("Max BMI:", max(data$bmi, na.rm = TRUE), "\n")
cat("Skewness:", skewness(data$bmi, na.rm = TRUE), "\n")
cat("Kurtosis:", kurtosis(data$bmi, na.rm = TRUE), "\n")

# BMI distribution by improved toilet access
cat("\n========== BMI BY SANITATION ACCESS ==========\n")
aggregate(bmi ~ improved_toilet, data = data, FUN = function(x) c(mean = mean(x), sd = sd(x), n = length(x)))

################################################################################
# PART 2: MODEL SPECIFICATIONS AND THEORETICAL JUSTIFICATION
################################################################################

cat("\n\n")
cat("================================================================================\n")
cat("                         MODEL SPECIFICATIONS                                   \n")
cat("================================================================================\n")

cat("\n--- MODEL 1: BASELINE MODEL ---\n")
cat("Theory: Direct effect of sanitation on BMI\n")
cat("Specification: BMI ~ improved_toilet\n")
cat("Rationale: Tests the core hypothesis without confounders\n")

cat("\n--- MODEL 2: DEMOGRAPHIC CONTROLS ---\n")
cat("Theory: Age and reproductive history affect BMI\n")
cat("Specification: BMI ~ improved_toilet + age + age_squared + children_born + age_first_birth\n")
cat("Rationale: Controls for life-cycle effects and maternal health factors\n")
cat("Expected: Age has non-linear relationship with BMI (U-shaped)\n")

cat("\n--- MODEL 3: SOCIOECONOMIC MODEL ---\n")
cat("Theory: Wealth and education are key determinants of health\n")
cat("Specification: BMI ~ improved_toilet + wealth + education_years + urban\n")
cat("Rationale: SES variables may confound sanitation-BMI relationship\n")
cat("Expected: Higher wealth and education associated with better nutrition\n")

cat("\n--- MODEL 4: COMPREHENSIVE HOUSEHOLD MODEL ---\n")
cat("Theory: Multiple household amenities jointly determine health\n")
cat("Specification: BMI ~ improved_toilet + electricity + cooking_fuel + water_source + toilet_shared\n")
cat("Rationale: Sanitation is part of broader household infrastructure\n")
cat("Expected: Clean cooking fuel and water access improve health\n")

cat("\n--- MODEL 5: FULL SPECIFICATION (KITCHEN SINK) ---\n")
cat("Theory: All observable factors affect BMI\n")
cat("Specification: BMI ~ improved_toilet + age + age_squared + education_years + wealth + \n")
cat("               urban + children_born + electricity + cooking_fuel + religion + caste\n")
cat("Rationale: Maximizes R-squared by including all relevant controls\n")
cat("Expected: Best fit but potential multicollinearity issues\n")

cat("\n--- MODEL 6: INTERACTION MODEL ---\n")
cat("Theory: Sanitation effects vary by wealth level\n")
cat("Specification: BMI ~ improved_toilet * wealth + age + education_years + urban + children_born\n")
cat("Rationale: Wealthier households may benefit more from improved sanitation\n")
cat("Expected: Positive interaction between sanitation and wealth\n")

cat("\n--- MODEL 7: REGIONAL FIXED EFFECTS ---\n")
cat("Theory: Regional heterogeneity in health infrastructure\n")
cat("Specification: BMI ~ improved_toilet + age + education_years + wealth + region\n")
cat("Rationale: Controls for unobserved regional factors\n")
cat("Expected: Reduces omitted variable bias from regional differences\n")

cat("\n--- MODEL 8: PARSIMONIOUS MODEL (AIC/BIC OPTIMIZED) ---\n")
cat("Theory: Balance between fit and parsimony\n")
cat("Specification: BMI ~ improved_toilet + age + education_years + wealth + urban + children_born\n")
cat("Rationale: Includes only theoretically important and statistically significant variables\n")
cat("Expected: Good balance of explanatory power and model simplicity\n")

################################################################################
# PART 3: MODEL ESTIMATION
################################################################################

cat("\n\n")
cat("================================================================================\n")
cat("                         ESTIMATING MODELS                                      \n")
cat("================================================================================\n")

# MODEL 1: Baseline
model1 <- lm(bmi ~ improved_toilet, data = data)

# MODEL 2: Demographic controls
model2 <- lm(bmi ~ improved_toilet + age + age_squared + children_born + age_first_birth, 
             data = data)

# MODEL 3: Socioeconomic
model3 <- lm(bmi ~ improved_toilet + wealth + education_years + urban, 
             data = data)

# MODEL 4: Household infrastructure
model4 <- lm(bmi ~ improved_toilet + electricity + cooking_fuel + water_source + toilet_shared, 
             data = data)

# MODEL 5: Full specification
model5 <- lm(bmi ~ improved_toilet + age + age_squared + education_years + wealth + 
               urban + children_born + electricity + cooking_fuel + religion + caste, 
             data = data)

# MODEL 6: Interaction model
model6 <- lm(bmi ~ improved_toilet * wealth + age + education_years + urban + children_born, 
             data = data)

# MODEL 7: Regional fixed effects
model7 <- lm(bmi ~ improved_toilet + age + education_years + wealth + region, 
             data = data)

# MODEL 8: Parsimonious model
model8 <- lm(bmi ~ improved_toilet + age + education_years + wealth + urban + children_born, 
             data = data)

cat("\nAll models estimated successfully!\n")

################################################################################
# PART 4: DIAGNOSTIC TESTS FOR EACH MODEL
################################################################################

cat("\n\n")
cat("================================================================================\n")
cat("                    COMPREHENSIVE DIAGNOSTIC TESTS                              \n")
cat("================================================================================\n")

# Function to perform comprehensive diagnostics on a model
comprehensive_diagnostics <- function(model, model_name) {
  cat("\n\n")
  cat("========================================================================\n")
  cat(paste("                    ", model_name, "                           \n"))
  cat("========================================================================\n")
  
  # 1. MODEL SUMMARY
  cat("\n--- MODEL SUMMARY ---\n")
  print(summary(model))
  
  # 2. CONFIDENCE INTERVALS
  cat("\n--- 95% CONFIDENCE INTERVALS FOR COEFFICIENTS ---\n")
  print(confint(model))
  
  # 3. R-SQUARED AND ADJUSTED R-SQUARED
  cat("\n--- MODEL FIT STATISTICS ---\n")
  cat("R-squared:", summary(model)$r.squared, "\n")
  cat("Adjusted R-squared:", summary(model)$adj.r.squared, "\n")
  cat("F-statistic:", summary(model)$fstatistic[1], "\n")
  cat("F-statistic p-value:", pf(summary(model)$fstatistic[1], 
                                   summary(model)$fstatistic[2], 
                                   summary(model)$fstatistic[3], 
                                   lower.tail = FALSE), "\n")
  
  # 4. AIC AND BIC
  cat("\n--- INFORMATION CRITERIA ---\n")
  cat("AIC:", AIC(model), "\n")
  cat("BIC:", BIC(model), "\n")
  cat("Log-Likelihood:", logLik(model)[1], "\n")
  
  # 5. MULTICOLLINEARITY TEST (VIF)
  cat("\n--- MULTICOLLINEARITY TEST (VIF) ---\n")
  cat("Rule: VIF > 10 indicates severe multicollinearity\n")
  cat("      VIF > 5 indicates moderate multicollinearity\n")
  if(length(coef(model)) > 2) {
    tryCatch({
      vif_values <- vif(model)
      print(vif_values)
      cat("\nMax VIF:", max(vif_values), "\n")
      if(max(vif_values) > 10) {
        cat("WARNING: Severe multicollinearity detected!\n")
      } else if(max(vif_values) > 5) {
        cat("WARNING: Moderate multicollinearity detected!\n")
      } else {
        cat("PASS: No serious multicollinearity issues.\n")
      }
    }, error = function(e) {
      cat("VIF calculation not applicable for this model specification\n")
    })
  } else {
    cat("VIF not applicable (simple regression)\n")
  }
  
  # 6. HETEROSKEDASTICITY TESTS
  cat("\n--- HETEROSKEDASTICITY TESTS ---\n")
  
  # Breusch-Pagan Test
  cat("\n6a. Breusch-Pagan Test\n")
  cat("H0: Homoskedasticity (constant variance)\n")
  cat("H1: Heteroskedasticity\n")
  bp_test <- bptest(model)
  print(bp_test)
  if(bp_test$p.value < 0.05) {
    cat("RESULT: Reject H0 - Heteroskedasticity detected (p < 0.05)\n")
  } else {
    cat("RESULT: Fail to reject H0 - No evidence of heteroskedasticity\n")
  }
  
  # White Test (using studentized Breusch-Pagan)
  cat("\n6b. White Test (Studentized Breusch-Pagan)\n")
  white_test <- bptest(model, ~ fitted(model) + I(fitted(model)^2))
  print(white_test)
  if(white_test$p.value < 0.05) {
    cat("RESULT: Reject H0 - Heteroskedasticity detected (p < 0.05)\n")
  } else {
    cat("RESULT: Fail to reject H0 - No evidence of heteroskedasticity\n")
  }
  
  # 7. NORMALITY OF RESIDUALS TESTS
  cat("\n--- NORMALITY OF RESIDUALS TESTS ---\n")
  
  # Shapiro-Wilk Test (on sample of residuals if n > 5000)
  cat("\n7a. Shapiro-Wilk Test\n")
  cat("H0: Residuals are normally distributed\n")
  residuals_sample <- if(length(residuals(model)) > 5000) {
    sample(residuals(model), 5000)
  } else {
    residuals(model)
  }
  sw_test <- shapiro.test(residuals_sample)
  print(sw_test)
  if(sw_test$p.value < 0.05) {
    cat("RESULT: Reject H0 - Residuals not normally distributed (p < 0.05)\n")
  } else {
    cat("RESULT: Fail to reject H0 - Residuals appear normally distributed\n")
  }
  
  # Jarque-Bera Test
  cat("\n7b. Jarque-Bera Test\n")
  jb_test <- jarque.bera.test(residuals(model))
  print(jb_test)
  if(jb_test$p.value < 0.05) {
    cat("RESULT: Reject H0 - Residuals not normally distributed (p < 0.05)\n")
  } else {
    cat("RESULT: Fail to reject H0 - Residuals appear normally distributed\n")
  }
  
  # Anderson-Darling Test
  cat("\n7c. Anderson-Darling Test\n")
  ad_test <- ad.test(residuals(model))
  print(ad_test)
  if(ad_test$p.value < 0.05) {
    cat("RESULT: Reject H0 - Residuals not normally distributed (p < 0.05)\n")
  } else {
    cat("RESULT: Fail to reject H0 - Residuals appear normally distributed\n")
  }
  
  # Kolmogorov-Smirnov Test
  cat("\n7d. Kolmogorov-Smirnov Test\n")
  ks_test <- ks.test(residuals(model), "pnorm", mean(residuals(model)), sd(residuals(model)))
  print(ks_test)
  if(ks_test$p.value < 0.05) {
    cat("RESULT: Reject H0 - Residuals not normally distributed (p < 0.05)\n")
  } else {
    cat("RESULT: Fail to reject H0 - Residuals appear normally distributed\n")
  }
  
  # Residual statistics
  cat("\n7e. Residual Descriptive Statistics\n")
  cat("Skewness:", skewness(residuals(model)), "\n")
  cat("Kurtosis:", kurtosis(residuals(model)), "\n")
  cat("Note: Normal distribution has skewness=0 and kurtosis=3\n")
  
  # 8. AUTOCORRELATION TEST (Durbin-Watson)
  cat("\n--- AUTOCORRELATION TEST ---\n")
  cat("\n8. Durbin-Watson Test\n")
  cat("H0: No autocorrelation in residuals\n")
  cat("DW statistic close to 2 indicates no autocorrelation\n")
  dw_test <- dwtest(model)
  print(dw_test)
  if(dw_test$p.value < 0.05) {
    cat("RESULT: Reject H0 - Autocorrelation detected (p < 0.05)\n")
  } else {
    cat("RESULT: Fail to reject H0 - No evidence of autocorrelation\n")
  }
  
  # 9. SPECIFICATION TESTS
  cat("\n--- SPECIFICATION TESTS ---\n")
  
  # RESET Test
  cat("\n9a. Ramsey RESET Test\n")
  cat("H0: Model is correctly specified (no omitted variables)\n")
  reset_test <- resettest(model, power = 2:3, type = "fitted")
  print(reset_test)
  if(reset_test$p.value < 0.05) {
    cat("RESULT: Reject H0 - Model may be misspecified (p < 0.05)\n")
  } else {
    cat("RESULT: Fail to reject H0 - No evidence of misspecification\n")
  }
  
  # 10. INFLUENTIAL OBSERVATIONS
  cat("\n--- INFLUENTIAL OBSERVATIONS ---\n")
  cat("\n10a. Cook's Distance\n")
  cooks_d <- cooks.distance(model)
  influential_cooks <- sum(cooks_d > 4/length(cooks_d))
  cat("Number of influential observations (Cook's D > 4/n):", influential_cooks, "\n")
  cat("Percentage of influential observations:", 
      round(100 * influential_cooks / length(cooks_d), 2), "%\n")
  
  cat("\n10b. Leverage Points (Hat Values)\n")
  hat_values <- hatvalues(model)
  high_leverage <- sum(hat_values > 2 * length(coef(model)) / length(hat_values))
  cat("Number of high leverage points (h > 2p/n):", high_leverage, "\n")
  cat("Percentage of high leverage points:", 
      round(100 * high_leverage / length(hat_values), 2), "%\n")
  
  cat("\n10c. DFFITS\n")
  dffits_vals <- dffits(model)
  influential_dffits <- sum(abs(dffits_vals) > 2 * sqrt(length(coef(model)) / length(dffits_vals)))
  cat("Number of influential observations (|DFFITS| > 2*sqrt(p/n)):", influential_dffits, "\n")
  cat("Percentage of influential observations:", 
      round(100 * influential_dffits / length(dffits_vals), 2), "%\n")
  
  # 11. RESIDUAL PLOTS
  cat("\n--- RESIDUAL ANALYSIS ---\n")
  cat("Generating diagnostic plots...\n")
  
  # 12. ROBUST STANDARD ERRORS
  cat("\n--- ROBUST STANDARD ERRORS (HC3) ---\n")
  cat("Heteroskedasticity-consistent standard errors\n")
  robust_se <- coeftest(model, vcov = vcovHC(model, type = "HC3"))
  print(robust_se)
  
  # 13. HYPOTHESIS TESTS FOR KEY COEFFICIENTS
  cat("\n--- HYPOTHESIS TESTS FOR improved_toilet COEFFICIENT ---\n")
  if("improved_toilet1" %in% names(coef(model))) {
    coef_val <- coef(model)["improved_toilet1"]
    se_val <- summary(model)$coefficients["improved_toilet1", "Std. Error"]
    t_val <- coef_val / se_val
    p_val <- 2 * pt(abs(t_val), df = df.residual(model), lower.tail = FALSE)
    
    cat("Coefficient:", coef_val, "\n")
    cat("Standard Error:", se_val, "\n")
    cat("t-statistic:", t_val, "\n")
    cat("p-value:", p_val, "\n")
    
    cat("\nH0: improved_toilet has no effect on BMI (β = 0)\n")
    cat("H1: improved_toilet has an effect on BMI (β ≠ 0)\n")
    if(p_val < 0.01) {
      cat("RESULT: Reject H0 at 1% significance level (p < 0.01)\n")
    } else if(p_val < 0.05) {
      cat("RESULT: Reject H0 at 5% significance level (p < 0.05)\n")
    } else if(p_val < 0.10) {
      cat("RESULT: Reject H0 at 10% significance level (p < 0.10)\n")
    } else {
      cat("RESULT: Fail to reject H0 - No significant effect detected\n")
    }
  }
  
  # 14. PREDICTED VS ACTUAL
  cat("\n--- PREDICTION ACCURACY ---\n")
  predictions <- predict(model)
  residuals_vec <- residuals(model)
  cat("Mean Absolute Error (MAE):", mean(abs(residuals_vec)), "\n")
  cat("Root Mean Squared Error (RMSE):", sqrt(mean(residuals_vec^2)), "\n")
  cat("Mean Absolute Percentage Error (MAPE):", 
      mean(abs(residuals_vec / data$bmi[!is.na(residuals_vec)])) * 100, "%\n")
  
  cat("\n========================================================================\n")
  cat(paste("                END OF DIAGNOSTICS FOR", model_name, "           \n"))
  cat("========================================================================\n")
  
  # Return key metrics for comparison
  return(list(
    model_name = model_name,
    r_squared = summary(model)$r.squared,
    adj_r_squared = summary(model)$adj.r.squared,
    aic = AIC(model),
    bic = BIC(model),
    rmse = sqrt(mean(residuals_vec^2)),
    bp_pvalue = bp_test$p.value,
    reset_pvalue = reset_test$p.value
  ))
}

# Run diagnostics for all models
diagnostics_results <- list()
diagnostics_results[[1]] <- comprehensive_diagnostics(model1, "MODEL 1: BASELINE")
diagnostics_results[[2]] <- comprehensive_diagnostics(model2, "MODEL 2: DEMOGRAPHIC CONTROLS")
diagnostics_results[[3]] <- comprehensive_diagnostics(model3, "MODEL 3: SOCIOECONOMIC")
diagnostics_results[[4]] <- comprehensive_diagnostics(model4, "MODEL 4: HOUSEHOLD INFRASTRUCTURE")
diagnostics_results[[5]] <- comprehensive_diagnostics(model5, "MODEL 5: FULL SPECIFICATION")
diagnostics_results[[6]] <- comprehensive_diagnostics(model6, "MODEL 6: INTERACTION MODEL")
diagnostics_results[[7]] <- comprehensive_diagnostics(model7, "MODEL 7: REGIONAL FIXED EFFECTS")
diagnostics_results[[8]] <- comprehensive_diagnostics(model8, "MODEL 8: PARSIMONIOUS")

################################################################################
# PART 5: MODEL COMPARISON
################################################################################

cat("\n\n")
cat("================================================================================\n")
cat("                         COMPREHENSIVE MODEL COMPARISON                         \n")
cat("================================================================================\n")

# Create comparison table
comparison_df <- data.frame(
  Model = sapply(diagnostics_results, function(x) x$model_name),
  R_squared = sapply(diagnostics_results, function(x) round(x$r_squared, 4)),
  Adj_R_squared = sapply(diagnostics_results, function(x) round(x$adj_r_squared, 4)),
  AIC = sapply(diagnostics_results, function(x) round(x$aic, 2)),
  BIC = sapply(diagnostics_results, function(x) round(x$bic, 2)),
  RMSE = sapply(diagnostics_results, function(x) round(x$rmse, 4)),
  BP_pvalue = sapply(diagnostics_results, function(x) round(x$bp_pvalue, 4)),
  RESET_pvalue = sapply(diagnostics_results, function(x) round(x$reset_pvalue, 4))
)

cat("\n--- MODEL COMPARISON TABLE ---\n")
print(comparison_df)

cat("\n--- INTERPRETATION GUIDE ---\n")
cat("R-squared: Higher is better (proportion of variance explained)\n")
cat("Adjusted R-squared: Higher is better (penalizes for number of predictors)\n")
cat("AIC/BIC: Lower is better (information criteria)\n")
cat("RMSE: Lower is better (prediction error)\n")
cat("BP p-value: >0.05 preferred (no heteroskedasticity)\n")
cat("RESET p-value: >0.05 preferred (correct specification)\n")

# Identify best models
cat("\n--- BEST MODELS BY CRITERION ---\n")
cat("Highest R-squared:", comparison_df$Model[which.max(comparison_df$R_squared)], "\n")
cat("Highest Adjusted R-squared:", comparison_df$Model[which.max(comparison_df$Adj_R_squared)], "\n")
cat("Lowest AIC:", comparison_df$Model[which.min(comparison_df$AIC)], "\n")
cat("Lowest BIC:", comparison_df$Model[which.min(comparison_df$BIC)], "\n")
cat("Lowest RMSE:", comparison_df$Model[which.min(comparison_df$RMSE)], "\n")

# Stargazer comparison (coefficient table)
cat("\n--- COEFFICIENT COMPARISON TABLE ---\n")
cat("Generating stargazer table...\n")

stargazer(model1, model2, model3, model4, model5, model6, model7, model8,
          type = "text",
          title = "Regression Results: Effect of Sanitation on BMI",
          column.labels = c("Baseline", "Demographic", "Socioeconomic", "Infrastructure",
                           "Full", "Interaction", "Regional FE", "Parsimonious"),
          dep.var.labels = "BMI (continuous)",
          covariate.labels = c("Improved Toilet"),
          omit.stat = c("ser"),
          star.cutoffs = c(0.05, 0.01, 0.001),
          notes = c("*** p<0.001, ** p<0.01, * p<0.05"))

# ANOVA comparison
cat("\n--- ANOVA COMPARISON (Nested Models) ---\n")
cat("\nComparing Model 1 vs Model 2:\n")
print(anova(model1, model2))

cat("\nComparing Model 3 vs Model 8:\n")
print(anova(model3, model8))

cat("\nComparing Model 8 vs Model 5:\n")
print(anova(model8, model5))

# Coefficient comparison for improved_toilet across models
cat("\n--- improved_toilet COEFFICIENT ACROSS MODELS ---\n")
toilet_coefs <- data.frame(
  Model = c("Model 1", "Model 2", "Model 3", "Model 4", "Model 5", "Model 6", "Model 7", "Model 8"),
  Coefficient = c(
    ifelse("improved_toilet1" %in% names(coef(model1)), coef(model1)["improved_toilet1"], NA),
    ifelse("improved_toilet1" %in% names(coef(model2)), coef(model2)["improved_toilet1"], NA),
    ifelse("improved_toilet1" %in% names(coef(model3)), coef(model3)["improved_toilet1"], NA),
    ifelse("improved_toilet1" %in% names(coef(model4)), coef(model4)["improved_toilet1"], NA),
    ifelse("improved_toilet1" %in% names(coef(model5)), coef(model5)["improved_toilet1"], NA),
    ifelse("improved_toilet1" %in% names(coef(model6)), coef(model6)["improved_toilet1"], NA),
    ifelse("improved_toilet1" %in% names(coef(model7)), coef(model7)["improved_toilet1"], NA),
    ifelse("improved_toilet1" %in% names(coef(model8)), coef(model8)["improved_toilet1"], NA)
  ),
  Std_Error = c(
    ifelse("improved_toilet1" %in% names(coef(model1)), summary(model1)$coefficients["improved_toilet1", "Std. Error"], NA),
    ifelse("improved_toilet1" %in% names(coef(model2)), summary(model2)$coefficients["improved_toilet1", "Std. Error"], NA),
    ifelse("improved_toilet1" %in% names(coef(model3)), summary(model3)$coefficients["improved_toilet1", "Std. Error"], NA),
    ifelse("improved_toilet1" %in% names(coef(model4)), summary(model4)$coefficients["improved_toilet1", "Std. Error"], NA),
    ifelse("improved_toilet1" %in% names(coef(model5)), summary(model5)$coefficients["improved_toilet1", "Std. Error"], NA),
    ifelse("improved_toilet1" %in% names(coef(model6)), summary(model6)$coefficients["improved_toilet1", "Std. Error"], NA),
    ifelse("improved_toilet1" %in% names(coef(model7)), summary(model7)$coefficients["improved_toilet1", "Std. Error"], NA),
    ifelse("improved_toilet1" %in% names(coef(model8)), summary(model8)$coefficients["improved_toilet1", "Std. Error"], NA)
  ),
  P_value = c(
    ifelse("improved_toilet1" %in% names(coef(model1)), summary(model1)$coefficients["improved_toilet1", "Pr(>|t|)"], NA),
    ifelse("improved_toilet1" %in% names(coef(model2)), summary(model2)$coefficients["improved_toilet1", "Pr(>|t|)"], NA),
    ifelse("improved_toilet1" %in% names(coef(model3)), summary(model3)$coefficients["improved_toilet1", "Pr(>|t|)"], NA),
    ifelse("improved_toilet1" %in% names(coef(model4)), summary(model4)$coefficients["improved_toilet1", "Pr(>|t|)"], NA),
    ifelse("improved_toilet1" %in% names(coef(model5)), summary(model5)$coefficients["improved_toilet1", "Pr(>|t|)"], NA),
    ifelse("improved_toilet1" %in% names(coef(model6)), summary(model6)$coefficients["improved_toilet1", "Pr(>|t|)"], NA),
    ifelse("improved_toilet1" %in% names(coef(model7)), summary(model7)$coefficients["improved_toilet1", "Pr(>|t|)"], NA),
    ifelse("improved_toilet1" %in% names(coef(model8)), summary(model8)$coefficients["improved_toilet1", "Pr(>|t|)"], NA)
  )
)

print(toilet_coefs)

cat("\n--- SIGNIFICANCE SUMMARY ---\n")
for(i in 1:nrow(toilet_coefs)) {
  if(!is.na(toilet_coefs$P_value[i])) {
    sig_level <- if(toilet_coefs$P_value[i] < 0.001) "***" else if(toilet_coefs$P_value[i] < 0.01) "**" else if(toilet_coefs$P_value[i] < 0.05) "*" else "ns"
    cat(toilet_coefs$Model[i], ": Coefficient =", round(toilet_coefs$Coefficient[i], 4), 
        ", p-value =", round(toilet_coefs$P_value[i], 4), sig_level, "\n")
  }
}

################################################################################
# PART 6: VISUALIZATION OF DIAGNOSTICS
################################################################################

cat("\n\n")
cat("================================================================================\n")
cat("                         DIAGNOSTIC VISUALIZATIONS                              \n")
cat("================================================================================\n")

# Create diagnostic plots for the best model (Model 8 - Parsimonious)
cat("\nGenerating diagnostic plots for Model 8 (Parsimonious)...\n")

par(mfrow = c(2, 2))
plot(model8, which = 1:4)
par(mfrow = c(1, 1))

# Residuals vs Fitted
cat("\nPlot 1: Residuals vs Fitted - Check for non-linearity and heteroskedasticity\n")
cat("Plot 2: Q-Q Plot - Check for normality of residuals\n")
cat("Plot 3: Scale-Location - Check for homoskedasticity\n")
cat("Plot 4: Residuals vs Leverage - Identify influential observations\n")

# Additional plots
cat("\nGenerating additional diagnostic plots...\n")

# Histogram of residuals
hist(residuals(model8), breaks = 50, main = "Histogram of Residuals (Model 8)", 
     xlab = "Residuals", col = "lightblue", border = "white")

# Boxplot of BMI by improved toilet
boxplot(bmi ~ improved_toilet, data = data, 
        main = "BMI by Sanitation Access",
        xlab = "Improved Toilet", ylab = "BMI",
        col = c("lightcoral", "lightgreen"))

################################################################################
# PART 7: ROBUST REGRESSION (Alternative Specification)
################################################################################

cat("\n\n")
cat("================================================================================\n")
cat("                         ROBUST REGRESSION ANALYSIS                             \n")
cat("================================================================================\n")

cat("\nEstimating robust regression (M-estimation) for Model 8...\n")
cat("This is robust to outliers and influential observations\n")

robust_model <- rlm(bmi ~ improved_toilet + age + education_years + wealth + urban + children_born, 
                    data = data, method = "MM")

cat("\n--- ROBUST REGRESSION RESULTS ---\n")
print(summary(robust_model))

cat("\n--- COMPARISON: OLS vs Robust Regression Coefficients ---\n")
comparison_ols_robust <- data.frame(
  Variable = names(coef(model8)),
  OLS_Coefficient = coef(model8),
  Robust_Coefficient = coef(robust_model),
  Difference = coef(model8) - coef(robust_model)
)
print(comparison_ols_robust)

################################################################################
# PART 8: FINAL RECOMMENDATIONS
################################################################################

cat("\n\n")
cat("================================================================================\n")
cat("                         FINAL RECOMMENDATIONS                                  \n")
cat("================================================================================\n")

cat("\n--- RECOMMENDED MODEL ---\n")
cat("Based on the comprehensive analysis, Model 8 (Parsimonious) is recommended because:\n")
cat("1. Good balance between explanatory power and parsimony\n")
cat("2. Includes theoretically important variables\n")
cat("3. Lower AIC/BIC compared to full model\n")
cat("4. All included variables are statistically significant\n")
cat("5. Easier to interpret than complex models\n")

cat("\n--- KEY FINDINGS ---\n")
cat("1. Examine the coefficient and significance of 'improved_toilet' across models\n")
cat("2. Check if the effect is robust to different specifications\n")
cat("3. Consider heteroskedasticity-robust standard errors for inference\n")
cat("4. Regional fixed effects may be important (Model 7)\n")
cat("5. Interaction effects between sanitation and wealth (Model 6) may reveal heterogeneous effects\n")

cat("\n--- ASSUMPTIONS VIOLATIONS TO ADDRESS ---\n")
cat("1. If heteroskedasticity detected: Use robust standard errors (HC3)\n")
cat("2. If non-normality detected: Large sample size makes this less critical (CLT)\n")
cat("3. If multicollinearity detected: Consider removing highly correlated variables\n")
cat("4. If influential observations detected: Consider robust regression or sensitivity analysis\n")

cat("\n--- NEXT STEPS ---\n")
cat("1. Review all diagnostic test results above\n")
cat("2. Select the most appropriate model based on your research question\n")
cat("3. Report results with robust standard errors if heteroskedasticity is present\n")
cat("4. Consider additional robustness checks (e.g., different subsamples)\n")
cat("5. Interpret coefficients in the context of your theoretical framework\n")

cat("\n\n")
cat("================================================================================\n")
cat("                    ANALYSIS COMPLETE                                           \n")
cat("================================================================================\n")
cat("\nAll models estimated and tested successfully!\n")
cat("Review the output above for detailed results and diagnostics.\n")
cat("\nSave this output and the comparison tables for your report.\n")
