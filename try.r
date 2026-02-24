############################################################
# ECON F342 – Model Comparison File
# Sanitation & Child Underweight – NFHS-5 Telangana
############################################################

############################
# 1. Load Required Libraries
############################

library(car)        # VIF
library(lmtest)     # BP test + coeftest
library(sandwich)   # Robust SE

############################
# 2. Load Dataset
############################

nfhs <- read.csv("NFHS-5-TG-Telangana.csv", stringsAsFactors = FALSE)

############################
# 3. Reshape Long → Wide
############################

nfhs_clean <- nfhs[, c("District", "Indicator", "NFHS.5")]

nfhs_wide <- reshape(nfhs_clean,
                     idvar = "District",
                     timevar = "Indicator",
                     direction = "wide")

colnames(nfhs_wide) <- gsub("NFHS.5.", "", colnames(nfhs_wide))

############################
# 4. Construct Master Dataset
############################

df <- data.frame(
  District = nfhs_wide$District,
  sanitation = nfhs_wide$`9. Population living in households that use an improved sanitation facility2 (%)`,
  underweight = nfhs_wide$`76. Children under 5 years who are underweight (weight-for-age)18 (%)`,
  female_literacy = nfhs_wide$`14. Women who are literate4 (%)`,
  clean_fuel = nfhs_wide$`10. Households using clean fuel for cooking3 (%)`,
  drinking_water = nfhs_wide$`8. Population living in households with an improved drinking-water source1 (%)`,
  health_insurance = nfhs_wide$`12. Households with any usual member covered under a health insurance/financing scheme (%)`,
  diarrhoea = nfhs_wide$`61. Prevalence of diarrhoea in the 2 weeks preceding the survey (%)`,
  maternal_bmi_low = nfhs_wide$`78. Women whose Body Mass Index (BMI) is below normal (BMI <18.5 kg/m2)21 (%)`,
  institutional_births = nfhs_wide$`42. Institutional births (%)`
)

df <- na.omit(df)

############################
# 5. Create Centered Variables (for interaction)
############################

df$san_c <- scale(df$sanitation, center = TRUE, scale = FALSE)
df$fuel_c <- scale(df$clean_fuel, center = TRUE, scale = FALSE)

############################################################
# 6. ESTIMATE MODELS
############################################################

# M1: Original Full Model
M1 <- lm(underweight ~ sanitation + female_literacy +
         clean_fuel + drinking_water +
         health_insurance + diarrhoea,
         data = df)

# M2: Reduced Core
M2 <- lm(underweight ~ sanitation + female_literacy +
         clean_fuel + drinking_water,
         data = df)

# M3: Trimmed
M3 <- lm(underweight ~ sanitation + female_literacy +
         clean_fuel,
         data = df)

# M4: Maternal BMI Model
M4 <- lm(underweight ~ sanitation +
         maternal_bmi_low,
         data = df)

# M5: Institutional Births Model
M5 <- lm(underweight ~ sanitation + clean_fuel +
         institutional_births,
         data = df)

# M6: Biological Core (Sanitation + BMI + Clean Fuel)
M6 <- lm(underweight ~ sanitation +
         maternal_bmi_low +
         clean_fuel,
         data = df)

# M7: Centered Interaction Model
M7 <- lm(underweight ~ san_c +
         fuel_c +
         san_c:fuel_c,
         data = df)

############################################################
# 7. FUNCTION TO PRINT MODEL DIAGNOSTICS
############################################################

model_diagnostics <- function(model, name) {
  
  cat("\n====================================\n")
  cat("Model:", name, "\n")
  cat("====================================\n")
  
  print(summary(model))
  
  cat("\n--- Robust Standard Errors ---\n")
  print(coeftest(model, vcov = vcovHC(model, type="HC1")))
  
  cat("\n--- VIF ---\n")
  print(vif(model))
  
  cat("\n--- Breusch-Pagan Test ---\n")
  print(bptest(model))
  
  cat("\nAIC:", AIC(model), "\n")
  cat("BIC:", BIC(model), "\n")
}

############################################################
# 8. RUN DIAGNOSTICS FOR ALL MODELS
############################################################

model_diagnostics(M1, "M1: Original Full")
model_diagnostics(M2, "M2: Reduced Core")
model_diagnostics(M3, "M3: Trimmed")
model_diagnostics(M4, "M4: Maternal BMI")
model_diagnostics(M5, "M5: Institutional Births")
model_diagnostics(M6, "M6: Biological Core")
model_diagnostics(M7, "M7: Interaction (Centered)")

############################################################
# 9. COMPARISON TABLE (Fit Statistics Only)
############################################################

comparison <- data.frame(
  Model = c("M1","M2","M3","M4","M5","M6","M7"),
  R2 = c(summary(M1)$r.squared,
         summary(M2)$r.squared,
         summary(M3)$r.squared,
         summary(M4)$r.squared,
         summary(M5)$r.squared,
         summary(M6)$r.squared,
         summary(M7)$r.squared),
  Adj_R2 = c(summary(M1)$adj.r.squared,
             summary(M2)$adj.r.squared,
             summary(M3)$adj.r.squared,
             summary(M4)$adj.r.squared,
             summary(M5)$adj.r.squared,
             summary(M6)$adj.r.squared,
             summary(M7)$adj.r.squared),
  AIC = c(AIC(M1), AIC(M2), AIC(M3),
          AIC(M4), AIC(M5), AIC(M6), AIC(M7)),
  BIC = c(BIC(M1), BIC(M2), BIC(M3),
          BIC(M4), BIC(M5), BIC(M6), BIC(M7))
)

cat("\n====================================\n")
cat("MODEL COMPARISON TABLE\n")
cat("====================================\n")
print(comparison)

model_final <- lm(underweight ~ sanitation +
                   maternal_bmi_low +
                   clean_fuel,
                   data = df)

summary(model_final)

# Robust SE
coeftest(model_final, vcov = vcovHC(model_final, type="HC1"))

# VIF
library(car)
vif(model_final)

# BP test
bptest(model_final)