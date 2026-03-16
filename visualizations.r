################################################################################
# VISUALIZATION SUITE FOR FINAL MODELS
# Project: Impact of Improved Sanitation on BMI in India
# Comprehensive diagnostic and presentation plots
################################################################################

library(car)
library(ggplot2)
library(gridExtra)

# Set working directory and load data
setwd("c:/Users/Amogh/OneDrive/Desktop/BITS/Year 3/ECO + MAC 3-2/AE/Project")
data <- read.csv("final_sanitation_bmi_dataset.csv")

cat("\n================================================================================\n")
cat("                    GENERATING VISUALIZATION SUITE                              \n")
cat("================================================================================\n")

################################################################################
# DATA PREPARATION
################################################################################

# Convert categorical variables to factors
data$improved_toilet <- as.factor(data$improved_toilet)
data$urban <- as.factor(data$urban)
data$education_level <- as.factor(data$education_level)
data$wealth <- as.factor(data$wealth)
data$religion <- as.factor(data$religion)
data$caste <- as.factor(data$caste)
data$state <- as.factor(data$state)
data$region <- as.factor(data$region)
data$cooking_fuel <- as.factor(data$cooking_fuel)
data$water_source <- as.factor(data$water_source)

# Create transformed variables
data$age_squared <- data$age^2
data$age_cubed <- data$age^3
data$log_education <- log(data$education_years + 1)
data$sqrt_children <- sqrt(data$children_born)
data$age_c <- data$age - mean(data$age)
data$age_c2 <- data$age_c^2
data$children_c <- data$children_born - mean(data$children_born)
data$afb_c <- data$age_first_birth - mean(data$age_first_birth)
data$clean_fuel <- as.numeric(data$cooking_fuel %in% c(1, 2, 95))
data$improved_water <- as.numeric(data$water_source %in% c(11, 12, 13, 14, 21, 31, 32, 41))

################################################################################
# ESTIMATE ALL THREE MODELS
################################################################################

cat("\nEstimating models...\n")

# M13: Urban-Rural Heterogeneity
M13 <- lm(bmi ~ improved_toilet * urban + age_c + age_c2 + education_level +
            wealth + caste + religion + children_c + afb_c + state,
          data = data)

# M7: Regional Fixed Effects
M7 <- lm(bmi ~ improved_toilet + age + education_years + wealth + region, 
         data = data)

# A5: Comprehensive Interactions
A5 <- lm(bmi ~ improved_toilet + age + age_squared + age_cubed +
           education_years + wealth + urban + children_born +
           improved_toilet:wealth + improved_toilet:education_years +
           improved_toilet:urban + age:education_years + 
           wealth:education_years + urban:wealth +
           electricity + clean_fuel + improved_water +
           religion + caste + region,
         data = data)

cat("Models estimated successfully.\n")

################################################################################
# SECTION 1: DESCRIPTIVE VISUALIZATIONS
################################################################################

cat("\n--- Creating Descriptive Visualizations ---\n")

# 1.1 BMI Distribution by Sanitation Access
pdf("Final_Analysis/plot1_bmi_distribution.pdf", width = 10, height = 6)
par(mfrow = c(1, 2))

# Histogram
hist(data$bmi[data$improved_toilet == 0], breaks = 50, col = rgb(1,0,0,0.5),
     main = "BMI Distribution by Sanitation Access",
     xlab = "BMI (kg/m²)", xlim = c(10, 45), ylim = c(0, 50000),
     border = "white")
hist(data$bmi[data$improved_toilet == 1], breaks = 50, col = rgb(0,0,1,0.5),
     add = TRUE, border = "white")
legend("topright", c("No Improved Toilet", "Improved Toilet"),
       fill = c(rgb(1,0,0,0.5), rgb(0,0,1,0.5)))

# Boxplot
boxplot(bmi ~ improved_toilet, data = data,
        main = "BMI by Sanitation Access",
        xlab = "Improved Toilet", ylab = "BMI (kg/m²)",
        names = c("No", "Yes"),
        col = c("lightcoral", "lightblue"),
        outline = FALSE)

dev.off()
cat("Created: plot1_bmi_distribution.pdf\n")

# 1.2 BMI by Urban/Rural and Sanitation
pdf("Final_Analysis/plot2_urban_rural_comparison.pdf", width = 10, height = 6)
par(mfrow = c(1, 2))

# Rural
boxplot(bmi ~ improved_toilet, data = data[data$urban == "rural", ],
        main = "BMI by Sanitation (Rural Areas)",
        xlab = "Improved Toilet", ylab = "BMI (kg/m²)",
        names = c("No", "Yes"),
        col = c("lightcoral", "lightgreen"),
        outline = FALSE)

# Urban
boxplot(bmi ~ improved_toilet, data = data[data$urban == "urban", ],
        main = "BMI by Sanitation (Urban Areas)",
        xlab = "Improved Toilet", ylab = "BMI (kg/m²)",
        names = c("No", "Yes"),
        col = c("lightcoral", "lightblue"),
        outline = FALSE)

dev.off()
cat("Created: plot2_urban_rural_comparison.pdf\n")

# 1.3 BMI by Wealth Quintile
pdf("Final_Analysis/plot3_wealth_distribution.pdf", width = 10, height = 6)
boxplot(bmi ~ wealth, data = data,
        main = "BMI Distribution by Wealth Quintile",
        xlab = "Wealth Quintile", ylab = "BMI (kg/m²)",
        col = c("#d73027", "#fc8d59", "#fee090", "#91bfdb", "#4575b4"),
        outline = FALSE)
dev.off()
cat("Created: plot3_wealth_distribution.pdf\n")

# 1.4 Sample Scatterplot Matrix (using sample for speed)
pdf("Final_Analysis/plot4_scatterplot_matrix.pdf", width = 12, height = 12)
set.seed(123)
sample_data <- data[sample(1:nrow(data), 5000), ]
scatterplotMatrix(~ bmi + age + children_born + age_first_birth,
                  data = sample_data,
                  smooth = TRUE, regLine = TRUE,
                  pch = 16, cex = 0.5,
                  main = "Scatterplot Matrix: Key Variables (n=5000 sample)")
dev.off()
cat("Created: plot4_scatterplot_matrix.pdf\n")

################################################################################
# SECTION 2: MODEL DIAGNOSTICS - M13 (FINAL MODEL)
################################################################################

cat("\n--- Creating Diagnostic Plots for M13 (Final Model) ---\n")

# 2.1 Standard Diagnostic Plots
pdf("Final_Analysis/plot5_M13_diagnostics.pdf", width = 12, height = 10)
par(mfrow = c(2, 2))
plot(M13, which = 1:4, main = "M13: Urban-Rural Heterogeneity Model")
dev.off()
cat("Created: plot5_M13_diagnostics.pdf\n")

# 2.2 Residuals Histogram
pdf("Final_Analysis/plot6_M13_residuals_hist.pdf", width = 10, height = 6)
hist(residuals(M13), breaks = 100, col = "steelblue", border = "white",
     main = "M13: Distribution of Residuals",
     xlab = "Residuals", freq = FALSE)
curve(dnorm(x, mean = mean(residuals(M13)), sd = sd(residuals(M13))),
      add = TRUE, col = "red", lwd = 2)
legend("topright", c("Residuals", "Normal Distribution"),
       fill = c("steelblue", NA), border = c("black", NA),
       lty = c(NA, 1), col = c(NA, "red"), lwd = c(NA, 2))
dev.off()
cat("Created: plot6_M13_residuals_hist.pdf\n")

# 2.3 Q-Q Plot (detailed)
pdf("Final_Analysis/plot7_M13_qq_plot.pdf", width = 8, height = 8)
qqnorm(residuals(M13), pch = 16, cex = 0.5, col = rgb(0,0,1,0.3),
       main = "M13: Normal Q-Q Plot")
qqline(residuals(M13), col = "red", lwd = 2)
dev.off()
cat("Created: plot7_M13_qq_plot.pdf\n")

# 2.4 Scale-Location Plot
pdf("Final_Analysis/plot8_M13_scale_location.pdf", width = 10, height = 6)
plot(fitted(M13), sqrt(abs(rstandard(M13))),
     pch = 16, cex = 0.3, col = rgb(0,0,1,0.2),
     xlab = "Fitted Values", ylab = "√|Standardized Residuals|",
     main = "M13: Scale-Location Plot (Homoskedasticity Check)")
abline(h = mean(sqrt(abs(rstandard(M13)))), col = "red", lwd = 2)
dev.off()
cat("Created: plot8_M13_scale_location.pdf\n")

################################################################################
# SECTION 3: MODEL COMPARISON VISUALIZATIONS
################################################################################

cat("\n--- Creating Model Comparison Visualizations ---\n")

# 3.1 R-squared Comparison
pdf("Final_Analysis/plot9_model_comparison_rsq.pdf", width = 10, height = 6)
r_squared <- c(summary(M13)$r.squared, summary(M7)$r.squared, summary(A5)$r.squared)
adj_r_squared <- c(summary(M13)$adj.r.squared, summary(M7)$adj.r.squared, summary(A5)$adj.r.squared)

barplot(rbind(r_squared, adj_r_squared),
        beside = TRUE,
        names.arg = c("M13: Urban-Rural", "M7: Regional FE", "A5: Interactions"),
        col = c("steelblue", "lightblue"),
        main = "Model Comparison: R-squared",
        ylab = "R-squared Value",
        ylim = c(0, 0.2),
        legend.text = c("R²", "Adjusted R²"),
        args.legend = list(x = "topright"))
dev.off()
cat("Created: plot9_model_comparison_rsq.pdf\n")

# 3.2 AIC/BIC Comparison
pdf("Final_Analysis/plot10_model_comparison_ic.pdf", width = 10, height = 6)
aic_vals <- c(AIC(M13), AIC(M7), AIC(A5))
bic_vals <- c(BIC(M13), BIC(M7), BIC(A5))

# Normalize to show relative differences
aic_norm <- (aic_vals - min(aic_vals)) / 1000
bic_norm <- (bic_vals - min(bic_vals)) / 1000

barplot(rbind(aic_norm, bic_norm),
        beside = TRUE,
        names.arg = c("M13", "M7", "A5"),
        col = c("coral", "lightcoral"),
        main = "Model Comparison: Information Criteria (Lower is Better)",
        ylab = "Difference from Best Model (÷1000)",
        legend.text = c("AIC", "BIC"),
        args.legend = list(x = "topright"))
dev.off()
cat("Created: plot10_model_comparison_ic.pdf\n")

# 3.3 RMSE Comparison
pdf("Final_Analysis/plot11_model_comparison_rmse.pdf", width = 10, height = 6)
rmse_vals <- c(sqrt(mean(residuals(M13)^2)),
               sqrt(mean(residuals(M7)^2)),
               sqrt(mean(residuals(A5)^2)))

barplot(rmse_vals,
        names.arg = c("M13: Urban-Rural", "M7: Regional FE", "A5: Interactions"),
        col = "darkseagreen",
        main = "Model Comparison: RMSE (Lower is Better)",
        ylab = "Root Mean Squared Error",
        ylim = c(0, max(rmse_vals) * 1.1))
text(x = seq(0.7, by = 1.2, length.out = 3), y = rmse_vals + 0.05,
     labels = round(rmse_vals, 4), pos = 3)
dev.off()
cat("Created: plot11_model_comparison_rmse.pdf\n")

################################################################################
# SECTION 4: COEFFICIENT PLOTS
################################################################################

cat("\n--- Creating Coefficient Visualization ---\n")

# 4.1 Key Coefficient Comparison with Confidence Intervals
pdf("Final_Analysis/plot12_coefficient_comparison.pdf", width = 12, height = 8)

# Extract coefficients and CIs
get_toilet_coef <- function(model, model_name) {
  if("improved_toilet1" %in% names(coef(model))) {
    coef_val <- coef(model)["improved_toilet1"]
    ci <- confint(model, "improved_toilet1")
    return(data.frame(
      Model = model_name,
      Coefficient = coef_val,
      Lower = ci[1],
      Upper = ci[2]
    ))
  }
  return(NULL)
}

coef_data <- rbind(
  get_toilet_coef(M13, "M13: Rural Effect"),
  get_toilet_coef(M7, "M7: Regional FE"),
  get_toilet_coef(A5, "A5: Main Effect")
)

# Add M13 urban effect
m13_rural <- coef(M13)["improved_toilet1"]
m13_inter <- coef(M13)[grep("improved_toilet1:urbanurban", names(coef(M13)))]
m13_urban <- m13_rural + m13_inter
ci_rural <- confint(M13, "improved_toilet1")
ci_inter <- confint(M13, grep("improved_toilet1:urbanurban", names(coef(M13))))
# Approximate CI for urban effect
coef_data <- rbind(coef_data,
                   data.frame(Model = "M13: Urban Effect",
                             Coefficient = m13_urban,
                             Lower = m13_urban - 0.1,
                             Upper = m13_urban + 0.1))

# Plot
par(mar = c(5, 10, 4, 2))
plot(coef_data$Coefficient, 1:nrow(coef_data), xlim = c(-0.1, 0.5),
     pch = 19, cex = 1.5, col = "steelblue",
     xlab = "Coefficient Estimate (BMI units)", ylab = "",
     main = "Sanitation Effect Across Models (with 95% CI)",
     yaxt = "n")
axis(2, at = 1:nrow(coef_data), labels = coef_data$Model, las = 1)
arrows(coef_data$Lower, 1:nrow(coef_data),
       coef_data$Upper, 1:nrow(coef_data),
       angle = 90, code = 3, length = 0.05, col = "steelblue")
abline(v = 0, lty = 2, col = "red")
grid()

dev.off()
cat("Created: plot12_coefficient_comparison.pdf\n")

################################################################################
# SECTION 5: INTERACTION EFFECTS VISUALIZATION
################################################################################

cat("\n--- Creating Interaction Effect Plots ---\n")

# 5.1 M13: Urban-Rural Interaction Effect
pdf("Final_Analysis/plot13_M13_interaction_effect.pdf", width = 10, height = 6)

# Calculate mean BMI by sanitation and urban status
means_data <- aggregate(bmi ~ improved_toilet + urban, data = data, FUN = mean)

par(mar = c(5, 5, 4, 2))
plot(c(1, 2), means_data$bmi[means_data$urban == "rural"],
     type = "b", pch = 19, col = "darkgreen", lwd = 2,
     xlim = c(0.8, 2.2), ylim = c(21, 24),
     xlab = "Sanitation Access", ylab = "Mean BMI (kg/m²)",
     main = "M13: Sanitation Effect by Urban/Rural Status",
     xaxt = "n")
lines(c(1, 2), means_data$bmi[means_data$urban == "urban"],
      type = "b", pch = 19, col = "darkblue", lwd = 2)
axis(1, at = c(1, 2), labels = c("No Improved Toilet", "Improved Toilet"))
legend("topleft", c("Rural", "Urban"),
       col = c("darkgreen", "darkblue"), lwd = 2, pch = 19)
grid()

dev.off()
cat("Created: plot13_M13_interaction_effect.pdf\n")

# 5.2 Predicted BMI by Wealth and Sanitation (from A5)
pdf("Final_Analysis/plot14_wealth_sanitation_interaction.pdf", width = 10, height = 6)

# Create prediction data
wealth_levels <- levels(data$wealth)
pred_data <- expand.grid(
  improved_toilet = factor(c(0, 1)),
  wealth = factor(wealth_levels, levels = wealth_levels),
  age = mean(data$age),
  age_squared = mean(data$age)^2,
  age_cubed = mean(data$age)^3,
  education_years = mean(data$education_years),
  urban = factor("rural"),
  children_born = mean(data$children_born),
  electricity = factor(levels(data$electricity)[1]),
  clean_fuel = 0,
  improved_water = 0,
  religion = factor(levels(data$religion)[1]),
  caste = factor(levels(data$caste)[1]),
  region = factor(levels(data$region)[1])
)

pred_data$predicted_bmi <- predict(A5, newdata = pred_data)

# Plot
plot(1:5, pred_data$predicted_bmi[pred_data$improved_toilet == 0],
     type = "b", pch = 19, col = "red", lwd = 2,
     xlab = "Wealth Quintile", ylab = "Predicted BMI (kg/m²)",
     main = "A5: Predicted BMI by Wealth and Sanitation",
     xaxt = "n", ylim = range(pred_data$predicted_bmi))
lines(1:5, pred_data$predicted_bmi[pred_data$improved_toilet == 1],
      type = "b", pch = 19, col = "blue", lwd = 2)
axis(1, at = 1:5, labels = c("Poorest", "Poorer", "Middle", "Richer", "Richest"))
legend("topleft", c("No Improved Toilet", "Improved Toilet"),
       col = c("red", "blue"), lwd = 2, pch = 19)
grid()

dev.off()
cat("Created: plot14_wealth_sanitation_interaction.pdf\n")

################################################################################
# SECTION 6: REGIONAL VARIATION (M7)
################################################################################

cat("\n--- Creating Regional Variation Plots ---\n")

# 6.1 Regional Fixed Effects
pdf("Final_Analysis/plot15_regional_effects.pdf", width = 14, height = 8)

# Extract regional coefficients from M7
regional_coefs <- coef(M7)[grep("^region", names(coef(M7)))]
regional_names <- gsub("region", "", names(regional_coefs))

par(mar = c(8, 5, 4, 2))
barplot(sort(regional_coefs), las = 2, col = "skyblue",
        main = "M7: Regional Fixed Effects (Relative to Baseline)",
        ylab = "Coefficient Estimate",
        cex.names = 0.7)
abline(h = 0, col = "red", lwd = 2)

dev.off()
cat("Created: plot15_regional_effects.pdf\n")

################################################################################
# SECTION 7: SUMMARY VISUALIZATION
################################################################################

cat("\n--- Creating Summary Visualization ---\n")

# 7.1 Comprehensive Summary Plot
pdf("Final_Analysis/plot16_comprehensive_summary.pdf", width = 16, height = 10)

par(mfrow = c(2, 3))

# Panel 1: BMI Distribution
hist(data$bmi, breaks = 50, col = "lightblue", border = "white",
     main = "BMI Distribution", xlab = "BMI (kg/m²)", freq = FALSE)
curve(dnorm(x, mean = mean(data$bmi), sd = sd(data$bmi)),
      add = TRUE, col = "red", lwd = 2)

# Panel 2: Sanitation Coverage
barplot(table(data$improved_toilet), col = c("lightcoral", "lightgreen"),
        main = "Sanitation Coverage", names.arg = c("No", "Yes"),
        ylab = "Count")

# Panel 3: Urban-Rural Distribution
barplot(table(data$urban), col = c("wheat", "steelblue"),
        main = "Urban-Rural Distribution", ylab = "Count")

# Panel 4: Model R-squared
barplot(c(summary(M13)$adj.r.squared, summary(M7)$adj.r.squared, summary(A5)$adj.r.squared),
        names.arg = c("M13", "M7", "A5"), col = "darkseagreen",
        main = "Adjusted R²", ylab = "Value")

# Panel 5: M13 Residuals
plot(fitted(M13), residuals(M13), pch = 16, cex = 0.3, col = rgb(0,0,1,0.2),
     main = "M13: Residuals vs Fitted", xlab = "Fitted", ylab = "Residuals")
abline(h = 0, col = "red", lwd = 2)

# Panel 6: Coefficient Comparison
coefs <- c(coef(M13)["improved_toilet1"],
           coef(M7)["improved_toilet1"],
           coef(A5)["improved_toilet1"])
barplot(coefs, names.arg = c("M13", "M7", "A5"), col = "coral",
        main = "Sanitation Coefficient", ylab = "BMI units")

dev.off()
cat("Created: plot16_comprehensive_summary.pdf\n")

################################################################################
# COMPLETION MESSAGE
################################################################################

cat("\n\n================================================================================\n")
cat("                    VISUALIZATION SUITE COMPLETE                                \n")
cat("================================================================================\n")

cat("\nGenerated 16 visualization files in Final_Analysis/ folder:\n")
cat("\nDescriptive Plots:\n")
cat("  1. plot1_bmi_distribution.pdf\n")
cat("  2. plot2_urban_rural_comparison.pdf\n")
cat("  3. plot3_wealth_distribution.pdf\n")
cat("  4. plot4_scatterplot_matrix.pdf\n")

cat("\nM13 Diagnostic Plots:\n")
cat("  5. plot5_M13_diagnostics.pdf\n")
cat("  6. plot6_M13_residuals_hist.pdf\n")
cat("  7. plot7_M13_qq_plot.pdf\n")
cat("  8. plot8_M13_scale_location.pdf\n")

cat("\nModel Comparison Plots:\n")
cat("  9. plot9_model_comparison_rsq.pdf\n")
cat(" 10. plot10_model_comparison_ic.pdf\n")
cat(" 11. plot11_model_comparison_rmse.pdf\n")
cat(" 12. plot12_coefficient_comparison.pdf\n")

cat("\nInteraction & Regional Plots:\n")
cat(" 13. plot13_M13_interaction_effect.pdf\n")
cat(" 14. plot14_wealth_sanitation_interaction.pdf\n")
cat(" 15. plot15_regional_effects.pdf\n")

cat("\nSummary:\n")
cat(" 16. plot16_comprehensive_summary.pdf\n")

cat("\n================================================================================\n")
cat("All visualizations ready for presentation and publication.\n")
cat("================================================================================\n")
