#PART-1
# Required libraries
library(tidyverse)
library(GGally)
library(car)
library(lmtest)
library(sandwich)

# Load dataset
nfhs <- read.csv("NFHS-5-TG-Telangana.csv")

# Check structure
str(nfhs)

# Check number of districts
length(unique(nfhs$District))

# Summary of NFHS-5 column
summary(nfhs$NFHS.5)

#PART-2
# Keep only required columns
nfhs_clean <- nfhs %>%
  select(District, Indicator, NFHS.5)

# Convert to wide format
nfhs_wide <- nfhs_clean %>%
  pivot_wider(names_from = Indicator,
              values_from = NFHS.5)

# Inspect structure
str(nfhs_wide)

#PART-3
df <- nfhs_wide %>%
  select(
    District,
    sanitation = `9. Population living in households that use an improved sanitation facility2 (%)`,
    stunting = `73. Children under 5 years who are stunted (height-for-age)18 (%)`,
    wasting = `74. Children under 5 years who are wasted (weight-for-height)18 (%)`,
    underweight = `76. Children under 5 years who are underweight (weight-for-age)18 (%)`,
    female_literacy = `14. Women who are literate4 (%)`,
    clean_fuel = `10. Households using clean fuel for cooking3 (%)`,
    drinking_water = `8. Population living in households with an improved drinking-water source1 (%)`,
    health_insurance = `12. Households with any usual member covered under a health insurance/financing scheme (%)`,
    diarrhoea = `61. Prevalence of diarrhoea in the 2 weeks preceding the survey (%)`
  )

# Check summary statistics
summary(df)

# Check missing values
colSums(is.na(df))

#PART-4
ggpairs(df[, -1])   # exclude district column

#PART-5
model_stunting <- lm(stunting ~ sanitation +
                     female_literacy +
                     clean_fuel +
                     drinking_water +
                     health_insurance +
                     diarrhoea,
                     data = df)

summary(model_stunting)

#PART-6
model_wasting <- lm(wasting ~ sanitation +
                    female_literacy +
                    clean_fuel +
                    drinking_water +
                    health_insurance +
                    diarrhoea,
                    data = df)

summary(model_wasting)

#PART-7
model_underweight <- lm(underweight ~ sanitation +
                        female_literacy +
                        clean_fuel +
                        drinking_water +
                        health_insurance +
                        diarrhoea,
                        data = df)

summary(model_underweight)

#PART-8
vif(model_stunting)

#PART-9
bptest(model_stunting)

#coeftest(model_stunting, vcov = vcovHC(model_stunting, type = "HC1"))

#PART-10
qqnorm(residuals(model_stunting))
qqline(residuals(model_stunting))

shapiro.test(residuals(model_stunting))

#PART-11
resettest(model_stunting)

#PART-12
model_quad <- lm(stunting ~ sanitation +
                 I(sanitation^2) +
                 female_literacy +
                 clean_fuel +
                 drinking_water +
                 health_insurance +
                 diarrhoea,
                 data = df)

summary(model_quad)

#PART-13
linearHypothesis(model_stunting,
                 c("female_literacy = 0",
                   "clean_fuel = 0",
                   "drinking_water = 0"))