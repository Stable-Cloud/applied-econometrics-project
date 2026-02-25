# Install and load required packages
packages <- c("car", "lmtest", "sandwich", "stargazer", "MASS", "nortest", "tseries", "moments")

cat("Installing required packages...\n")
for(pkg in packages) {
  if(!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(paste("Installing", pkg, "...\n"))
    install.packages(pkg, repos = "https://cran.r-project.org", dependencies = TRUE)
  }
}

cat("\nAll packages installed. Running analysis...\n\n")

# Load data
setwd("c:/Users/Amogh/OneDrive/Desktop/BITS/Year 3/ECO + MAC 3-2/AE/Project")
data <- read.csv("final_sanitation_bmi_dataset.csv")

# Convert to factors
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
data$age_squared <- data$age^2

# Estimate all 8 models
cat("\n=== ESTIMATING MODELS ===\n")
model1 <- lm(bmi ~ improved_toilet, data = data)
model2 <- lm(bmi ~ improved_toilet + age + age_squared + children_born + age_first_birth, data = data)
model3 <- lm(bmi ~ improved_toilet + wealth + education_years + urban, data = data)
model4 <- lm(bmi ~ improved_toilet + electricity + cooking_fuel + water_source + toilet_shared, data = data)
model5 <- lm(bmi ~ improved_toilet + age + age_squared + education_years + wealth + urban + children_born + electricity + cooking_fuel + religion + caste, data = data)
model6 <- lm(bmi ~ improved_toilet * wealth + age + education_years + urban + children_born, data = data)
model7 <- lm(bmi ~ improved_toilet + age + education_years + wealth + region, data = data)
model8 <- lm(bmi ~ improved_toilet + age + education_years + wealth + urban + children_born, data = data)

cat("All models estimated!\n\n")

# Quick summary function
quick_summary <- function(model, name) {
  cat("\n========================================\n")
  cat(name, "\n")
  cat("========================================\n")
  
  s <- summary(model)
  cat("R-squared:", round(s$r.squared, 4), "\n")
  cat("Adj R-squared:", round(s$adj.r.squared, 4), "\n")
  cat("AIC:", round(AIC(model), 2), "\n")
  cat("BIC:", round(BIC(model), 2), "\n")
  
  # Toilet coefficient
  if("improved_toilet1" %in% names(coef(model))) {
    coef_val <- coef(model)["improved_toilet1"]
    p_val <- s$coefficients["improved_toilet1", "Pr(>|t|)"]
    sig <- if(p_val < 0.001) "***" else if(p_val < 0.01) "**" else if(p_val < 0.05) "*" else "ns"
    cat("Improved Toilet Coef:", round(coef_val, 4), "(p =", round(p_val, 4), ")", sig, "\n")
  }
  
  # Tests
  bp <- bptest(model)
  cat("Breusch-Pagan p-value:", round(bp$p.value, 4), 
      ifelse(bp$p.value < 0.05, " - Heteroskedasticity detected", " - Homoskedastic"), "\n")
  
  if(length(coef(model)) > 2) {
    tryCatch({
      vif_vals <- vif(model)
      cat("Max VIF:", round(max(vif_vals), 2), 
          ifelse(max(vif_vals) > 10, " - Severe multicollinearity!", 
                 ifelse(max(vif_vals) > 5, " - Moderate multicollinearity", " - OK")), "\n")
    }, error = function(e) {})
  }
  
  reset <- resettest(model, power = 2:3, type = "fitted")
  cat("RESET p-value:", round(reset$p.value, 4),
      ifelse(reset$p.value < 0.05, " - Misspecification detected", " - Specification OK"), "\n")
}

# Run summaries
quick_summary(model1, "MODEL 1: BASELINE")
quick_summary(model2, "MODEL 2: DEMOGRAPHIC CONTROLS")
quick_summary(model3, "MODEL 3: SOCIOECONOMIC")
quick_summary(model4, "MODEL 4: HOUSEHOLD INFRASTRUCTURE")
quick_summary(model5, "MODEL 5: FULL SPECIFICATION")
quick_summary(model6, "MODEL 6: INTERACTION MODEL")
quick_summary(model7, "MODEL 7: REGIONAL FIXED EFFECTS")
quick_summary(model8, "MODEL 8: PARSIMONIOUS")

# Comparison table
cat("\n\n========================================\n")
cat("MODEL COMPARISON TABLE\n")
cat("========================================\n")

comparison <- data.frame(
  Model = c("M1: Baseline", "M2: Demographic", "M3: Socioeconomic", "M4: Infrastructure",
            "M5: Full", "M6: Interaction", "M7: Regional FE", "M8: Parsimonious"),
  R2 = c(summary(model1)$r.squared, summary(model2)$r.squared, summary(model3)$r.squared,
         summary(model4)$r.squared, summary(model5)$r.squared, summary(model6)$r.squared,
         summary(model7)$r.squared, summary(model8)$r.squared),
  Adj_R2 = c(summary(model1)$adj.r.squared, summary(model2)$adj.r.squared, summary(model3)$adj.r.squared,
             summary(model4)$adj.r.squared, summary(model5)$adj.r.squared, summary(model6)$adj.r.squared,
             summary(model7)$adj.r.squared, summary(model8)$adj.r.squared),
  AIC = c(AIC(model1), AIC(model2), AIC(model3), AIC(model4), AIC(model5), AIC(model6), AIC(model7), AIC(model8))
)

comparison$R2 <- round(comparison$R2, 4)
comparison$Adj_R2 <- round(comparison$Adj_R2, 4)
comparison$AIC <- round(comparison$AIC, 1)

print(comparison)

cat("\n\nBEST MODELS:\n")
cat("Highest R²:", comparison$Model[which.max(comparison$R2)], "\n")
cat("Highest Adj R²:", comparison$Model[which.max(comparison$Adj_R2)], "\n")
cat("Lowest AIC:", comparison$Model[which.min(comparison$AIC)], "\n")

cat("\n\nANALYSIS COMPLETE!\n")
