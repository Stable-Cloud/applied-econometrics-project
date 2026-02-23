############################################################
# ECON F342 – Applied Econometrics
# District-Level Sanitation & Child Health – NFHS-5 Telangana
############################################################

############################
# 1. Load Required Libraries
############################

library(car)      # For VIF and linearHypothesis
library(lmtest)   # For Breusch-Pagan and RESET tests


############################
# 2. Load Dataset
############################

nfhs <- read.csv("NFHS-5-TG-Telangana.csv", stringsAsFactors = FALSE)

# Basic inspection
str(nfhs)
cat("Number of districts:", length(unique(nfhs$District)), "\n")


############################
# 3. Reshape Data (Long → Wide)
############################

nfhs_clean <- nfhs[, c("District", "Indicator", "NFHS.5")]

nfhs_wide <- reshape(nfhs_clean,
                     idvar = "District",
                     timevar = "Indicator",
                     direction = "wide")

# Clean column names
colnames(nfhs_wide) <- gsub("NFHS.5.", "", colnames(nfhs_wide))

str(nfhs_wide)


############################
# 4. Create Final Dataset
############################

df <- data.frame(
  District = nfhs_wide$District,
  sanitation = nfhs_wide$`9. Population living in households that use an improved sanitation facility2 (%)`,
  stunting = nfhs_wide$`73. Children under 5 years who are stunted (height-for-age)18 (%)`,
  wasting = nfhs_wide$`74. Children under 5 years who are wasted (weight-for-height)18 (%)`,
  underweight = nfhs_wide$`76. Children under 5 years who are underweight (weight-for-age)18 (%)`,
  female_literacy = nfhs_wide$`14. Women who are literate4 (%)`,
  clean_fuel = nfhs_wide$`10. Households using clean fuel for cooking3 (%)`,
  drinking_water = nfhs_wide$`8. Population living in households with an improved drinking-water source1 (%)`,
  health_insurance = nfhs_wide$`12. Households with any usual member covered under a health insurance/financing scheme (%)`,
  diarrhoea = nfhs_wide$`61. Prevalence of diarrhoea in the 2 weeks preceding the survey (%)`
)

# Remove missing observations
df <- na.omit(df)

# Summary statistics
summary(df)


############################
# 5. Graph Matrix (Linearity Check)
############################

pairs(df[, -1],
      main = "Scatterplot Matrix",
      pch = 19,
      col = "blue")


############################
# 6. Baseline Regression – Stunting
############################

model_stunting <- lm(stunting ~ sanitation +
                     female_literacy +
                     clean_fuel +
                     drinking_water +
                     health_insurance +
                     diarrhoea,
                     data = df)

summary(model_stunting)


############################
# 7. Robustness Models
############################

# Wasting
model_wasting <- lm(wasting ~ sanitation +
                    female_literacy +
                    clean_fuel +
                    drinking_water +
                    health_insurance +
                    diarrhoea,
                    data = df)

summary(model_wasting)

# Underweight
model_underweight <- lm(underweight ~ sanitation +
                        female_literacy +
                        clean_fuel +
                        drinking_water +
                        health_insurance +
                        diarrhoea,
                        data = df)

summary(model_underweight)


############################
# 8. Multicollinearity Check
############################

vif(model_stunting)


############################
# 9. Heteroskedasticity Test
############################

bptest(model_stunting)


############################
# 10. Normality Check
############################

qqnorm(residuals(model_stunting))
qqline(residuals(model_stunting))

shapiro.test(residuals(model_stunting))


############################
# 11. Functional Form Test (RESET)
############################

resettest(model_stunting)


############################
# 12. Nonlinear Specification
############################

model_quad <- lm(stunting ~ sanitation +
                 I(sanitation^2) +
                 female_literacy +
                 clean_fuel +
                 drinking_water +
                 health_insurance +
                 diarrhoea,
                 data = df)

summary(model_quad)


############################
# 13. Joint Significance (F-test)
############################

linearHypothesis(model_stunting,
                 c("female_literacy = 0",
                   "clean_fuel = 0",
                   "drinking_water = 0"))