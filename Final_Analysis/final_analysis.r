############################################################
# ECON F342 – Applied Econometrics
# FINAL MODEL COMPARISON SCRIPT
# Sanitation & Women Nutrition – NFHS-5 India
#
# Top 3 OLS Specifications (side-by-side)
#
#   MODEL A  – Full Specification (amogh.r Model 5)
#   MODEL B  – Comprehensive Interaction (amogh2.r A5)
#   MODEL C  – Urban Heterogeneity with State FE (parth_ols M13) [PREFERRED]
#
# All models use BMI (continuous, kg/m²) as the dependent variable
# and improved_toilet (0/1) as the main explanatory variable.
############################################################


############################################################
# SECTION 1 : LOAD LIBRARIES
############################################################

required_packages <- c("car","lmtest","sandwich",
                       "stargazer","nortest","tseries","moments")

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.r-project.org",
                     dependencies = TRUE)
    library(pkg, character.only = TRUE)
  }
}


############################################################
# SECTION 2 : LOAD DATA
############################################################

# Use relative path (works from the project root)
data <- read.csv("../final_sanitation_bmi_dataset.csv")

cat("\n================================================================\n")
cat("  FINAL MODEL COMPARISON – Sanitation & BMI (NFHS-5)\n")
cat("================================================================\n")
cat("Total observations:", nrow(data), "\n")


############################################################
# SECTION 3 : SAMPLE DESCRIPTION
############################################################

cat("\n================ SAMPLE DESCRIPTION ================\n")

key_vars <- c("bmi","improved_toilet","urban",
              "education_level","wealth",
              "children_born","age_first_birth")

cat("\nMissing Values (Key Variables):\n")
print(colSums(is.na(data[key_vars])))

cont_vars <- c("bmi","age","children_born","age_first_birth")
cont_summary <- data.frame(
  Variable = cont_vars,
  Mean = sapply(data[cont_vars], mean, na.rm = TRUE),
  SD   = sapply(data[cont_vars], sd,   na.rm = TRUE),
  Min  = sapply(data[cont_vars], min,  na.rm = TRUE),
  Max  = sapply(data[cont_vars], max,  na.rm = TRUE)
)
cont_summary[, -1] <- round(cont_summary[, -1], 3)
print(cont_summary)

cat("\nProportion with Improved Toilet:",
    round(mean(data$improved_toilet, na.rm = TRUE), 3), "\n")
cat("\nUrban Distribution (%):\n")
print(round(prop.table(table(data$urban)) * 100, 2))
cat("\nEducation Distribution (%):\n")
print(round(prop.table(table(data$education_level)) * 100, 2))
cat("\nWealth Distribution (%):\n")
print(round(prop.table(table(data$wealth)) * 100, 2))
cat("====================================================\n")


############################################################
# SECTION 4 : VARIABLE CONSTRUCTION
############################################################

# --- Factor coding (shared by Model A and B) -----------------
factor_vars <- c("education_level","wealth","urban",
                 "caste","religion","state","region",
                 "cooking_fuel","water_source",
                 "electricity","toilet_shared")

data[factor_vars] <- lapply(data[factor_vars], as.factor)

data$age_squared <- data$age^2

# --- Extra variables for Model A (Full Spec) -----------------
# (uses education_years directly)

# --- Extra variables for Model B (Comprehensive Interaction) --
data$age_cubed           <- data$age^3
data$log_education       <- log(data$education_years + 1)
data$wealth_numeric      <- as.numeric(data$wealth)
data$clean_fuel          <- as.numeric(data$cooking_fuel %in% c(1, 2, 95))
data$improved_water      <- as.numeric(data$water_source %in%
                              c(11, 12, 13, 14, 21, 31, 32, 41))

# --- Centered variables for Model C (M13 – Preferred) --------
data$age_c      <- data$age - mean(data$age)
data$age_c2     <- data$age_c^2
data$children_c <- data$children_born - mean(data$children_born)
data$afb_c      <- data$age_first_birth - mean(data$age_first_birth)

# improved_toilet stays numeric (0/1) for Model C;
# factor version needed for Models A & B
data$improved_toilet_fac <- as.factor(data$improved_toilet)


############################################################
# SECTION 5 : VISUALISATIONS (M13-specific)
############################################################

# ──────────────────────────────────────────────────────────
# FIGURE 1 : Scatterplot Matrix with Linear Fits
#   Selected Maternal Health and Demographic Variables
#   (BMI, Age, Children Born, Age at First Birth)
#
#   Purpose: Examine pairwise relationships between
#   key continuous variables used in the M13 model.
#   Linear-fit lines and smoothed (loess) curves are
#   overlaid to reveal potential non-linearities.
#   A random sample (n = 5 000) is used for legibility.
# ──────────────────────────────────────────────────────────

cat("\n--- Figure 1: Scatterplot Matrix ---\n")

set.seed(123)
sample_data <- data[sample(1:nrow(data), 5000), ]

scatterplotMatrix(
  ~ bmi + age + children_born + age_first_birth,
  data    = sample_data,
  smooth  = TRUE,
  regLine = TRUE,
  pch     = 16,
  cex     = 0.4,
  col     = adjustcolor("steelblue", alpha.f = 0.35),
  main    = "Scatterplot Matrix with Linear Fits\nfor Selected Maternal Health and Demographic Variables"
)

# ──────────────────────────────────────────────────────────
# FIGURE 2 : BMI by Sanitation Access
#
#   Compares the distribution of BMI between women with
#   and without access to improved sanitation facilities.
#   Women with improved toilets exhibit a slightly higher
#   median BMI.  The IQR is also somewhat higher for the
#   improved-sanitation group, suggesting generally better
#   nutritional outcomes.  Both groups display substantial
#   variation and several high-BMI outliers, but the
#   distribution for the improved-sanitation group is
#   shifted upward — consistent with the positive
#   regression coefficient of improved_toilet in M13.
# ──────────────────────────────────────────────────────────

cat("--- Figure 2: BMI by Sanitation Access ---\n")

boxplot(bmi ~ improved_toilet,
        data      = data,
        col       = c("tomato","steelblue"),
        names     = c("No Improved Toilet","Improved Toilet"),
        main      = "BMI by Sanitation Access",
        ylab      = "BMI (kg/m²)",
        xlab      = "Sanitation Facility Type",
        outline   = TRUE,
        notch     = TRUE,
        border    = c("darkred","darkblue"),
        las       = 1)

# Add median labels
medians <- tapply(data$bmi, data$improved_toilet, median, na.rm = TRUE)
text(x = 1:2, y = medians + 0.3,
     labels = paste0("Median = ", round(medians, 2)),
     cex = 0.85, font = 2, col = c("darkred","darkblue"))

# Group sample sizes
n_counts <- table(data$improved_toilet)
mtext(paste0("n = ", format(n_counts, big.mark = ",")),
      side = 1, at = 1:2, line = 2, cex = 0.8)

legend("topright",
       legend = c("No Improved Toilet","Improved Toilet"),
       fill   = c("tomato","steelblue"),
       border = c("darkred","darkblue"),
       bty    = "n", cex = 0.85)

# ──────────────────────────────────────────────────────────
# FIGURE 3 : BMI by Sanitation and Urban Status
#
#   Examines BMI differences by sanitation access
#   separately for rural and urban women.
#   In RURAL areas, women with improved sanitation have
#   a noticeably higher median BMI compared to those
#   without improved toilets.
#   In URBAN areas, the difference between sanitation
#   groups appears smaller, indicating a weaker
#   association.  Overall BMI levels are also slightly
#   higher in urban areas relative to rural areas.
#   These patterns visually support the interaction-model
#   results (M13), which show that the positive
#   relationship between sanitation and BMI is stronger
#   in rural areas than in urban areas.
# ──────────────────────────────────────────────────────────

cat("--- Figure 3: BMI by Sanitation × Urban Status ---\n")

group_labels <- c("Rural\nNo Improved",
                  "Rural\nImproved",
                  "Urban\nNo Improved",
                  "Urban\nImproved")

group_cols   <- c("tomato","steelblue","orange","darkgreen")
group_border <- c("darkred","darkblue","darkorange4","darkgreen")

boxplot(bmi ~ improved_toilet * urban,
        data      = data,
        col       = group_cols,
        names     = group_labels,
        main      = "BMI by Sanitation Access and Urban/Rural Status",
        ylab      = "BMI (kg/m²)",
        xlab      = "",
        outline   = TRUE,
        notch     = TRUE,
        border    = group_border,
        las       = 1)

# Compute and label group medians
grp <- interaction(data$improved_toilet, data$urban)
grp_medians <- tapply(data$bmi, grp, median, na.rm = TRUE)
# Order: 0.0(rural-no), 1.0(rural-yes), 0.1(urban-no), 1.1(urban-yes)
med_ordered <- grp_medians[c("0.0","1.0","0.1","1.1")]
text(x = 1:4, y = med_ordered + 0.3,
     labels = paste0("Median = ", round(med_ordered, 2)),
     cex = 0.75, font = 2, col = group_border)

# Group sample sizes
n_grp <- table(grp)[c("0.0","1.0","0.1","1.1")]
mtext(paste0("n = ", format(n_grp, big.mark = ",")),
      side = 1, at = 1:4, line = 2.5, cex = 0.7)

legend("topright",
       legend = c("Rural – No Improved","Rural – Improved",
                  "Urban – No Improved","Urban – Improved"),
       fill   = group_cols,
       border = group_border,
       bty    = "n", cex = 0.8)


############################################################
# SECTION 6 : ESTIMATE THE THREE MODELS
############################################################

cat("\n================ ESTIMATING MODELS ================\n\n")

# ---- MODEL A : Full Specification (amogh.r Model 5) ----------
# Controls for age (quadratic), education, wealth, urban,
# children, electricity, cooking fuel, religion, caste.
# No state/region FE.

cat("--- Model A : Full Specification ---\n")
model_A <- lm(
  bmi ~ improved_toilet_fac +
    age + age_squared +
    education_years +
    wealth +
    urban +
    children_born +
    electricity +
    cooking_fuel +
    religion +
    caste,
  data = data
)

# ---- MODEL B : Comprehensive Interaction (amogh2.r A5) -------
# Adds cubic age, log-education, many interactions,
# clean fuel, improved water, region FE.

cat("--- Model B : Comprehensive Interaction ---\n")
model_B <- lm(
  bmi ~ improved_toilet_fac +
    age + age_squared + age_cubed +
    education_years +
    wealth +
    urban +
    children_born +
    improved_toilet_fac:wealth +
    improved_toilet_fac:education_years +
    improved_toilet_fac:urban +
    age:education_years +
    wealth:education_years +
    urban:wealth +
    electricity +
    clean_fuel +
    improved_water +
    religion +
    caste +
    region,
  data = data
)

# ---- MODEL C : Urban Heterogeneity + State FE (parth_ols M13)
# Preferred model.  Uses centered continuous vars,
# state fixed effects, and sanitation × urban interaction.

cat("--- Model C : M13 – Urban Heterogeneity + State FE [PREFERRED] ---\n")
model_C <- lm(
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

cat("All three models estimated.\n")


############################################################
# SECTION 7 : CLUSTER-ROBUST SE (Model C only)
############################################################

cat("\n--- Computing cluster-robust standard errors (Model C) ---\n")

cluster_vcov <- function(model, cluster) {
  M   <- length(unique(cluster))
  N   <- length(cluster)
  K   <- model$rank
  dfc <- (M / (M - 1)) * ((N - 1) / (N - K))
  uj  <- apply(estfun(model), 2,
               function(x) tapply(x, cluster, sum))
  vcovCL <- dfc * sandwich(model, meat = crossprod(uj) / N)
  return(vcovCL)
}

vcov_C  <- cluster_vcov(model_C, data$cluster)
robust_C <- coeftest(model_C, vcov_C)


############################################################
# SECTION 8 : ROBUST (HC3) SE (Models A & B)
############################################################

robust_A <- coeftest(model_A, vcov = vcovHC(model_A, type = "HC3"))
robust_B <- coeftest(model_B, vcov = vcovHC(model_B, type = "HC3"))


############################################################
# SECTION 9 : COMPREHENSIVE DIAGNOSTICS
############################################################

run_diagnostics <- function(model, model_name, robust_tbl = NULL) {

  s <- summary(model)

  cat("\n\n========================================================================\n")
  cat("  DIAGNOSTICS : ", model_name, "\n")
  cat("========================================================================\n")

  # ---- 9a. Model fit ---------------------------------------------------
  cat("\n--- MODEL FIT ---\n")
  cat("R-squared:          ", round(s$r.squared, 4), "\n")
  cat("Adjusted R-squared: ", round(s$adj.r.squared, 4), "\n")
  cat("AIC:                ", round(AIC(model), 2), "\n")
  cat("BIC:                ", round(BIC(model), 2), "\n")
  cat("RMSE:               ", round(sqrt(mean(residuals(model)^2)), 4), "\n")
  f_stat <- s$fstatistic
  cat("F-statistic:        ", round(f_stat[1], 2),
      " (df1 =", f_stat[2], ", df2 =", f_stat[3], ")\n")

  # ---- 9b. Key coefficient (improved_toilet) ---------------------------
  cat("\n--- KEY COEFFICIENT : improved_toilet ---\n")

  # Name differs depending on factor vs numeric coding
  toilet_names <- c("improved_toilet","improved_toilet1",
                    "improved_toilet_fac1")
  coef_name <- intersect(toilet_names, rownames(s$coefficients))[1]

  if (!is.na(coef_name)) {
    if (!is.null(robust_tbl)) {
      cv <- robust_tbl[coef_name, ]
    } else {
      cv <- s$coefficients[coef_name, ]
    }
    cat("Coefficient: ", round(cv[1], 4), "\n")
    cat("Std. Error:  ", round(cv[2], 4), "\n")
    cat("t-statistic: ", round(cv[3], 4), "\n")
    cat("p-value:     ", format(cv[4], scientific = TRUE), "\n")
    ci <- confint(model, coef_name, level = 0.95)
    cat("95% CI:      [", round(ci[1], 4), ",", round(ci[2], 4), "]\n")
  }

  # ---- 9c. Multicollinearity (VIF) ------------------------------------
  cat("\n--- MULTICOLLINEARITY (VIF) ---\n")
  max_vif_val <- NA
  tryCatch({
    vif_vals <- vif(model)
    if (is.matrix(vif_vals)) {
      max_vif_val <- max(vif_vals[, "GVIF^(1/(2*Df))"])
    } else {
      max_vif_val <- max(vif_vals)
    }
    cat("Max VIF:", round(max_vif_val, 2), "\n")
    if (max_vif_val > 10) cat("WARNING: Severe multicollinearity!\n")
    else if (max_vif_val > 5) cat("CAUTION: Moderate multicollinearity.\n")
    else cat("OK: No serious multicollinearity.\n")
  }, error = function(e) {
    cat("VIF computation skipped (aliased coefficients or interactions).\n")
  })

  # ---- 9d. Heteroskedasticity -----------------------------------------
  cat("\n--- HETEROSKEDASTICITY ---\n")
  bp <- bptest(model)
  cat("Breusch-Pagan p-value:", format(bp$p.value, scientific = TRUE), "\n")
  if (bp$p.value < 0.05) cat("DETECTED – robust SE used.\n")
  else cat("Not detected at 5%.\n")

  white <- bptest(model, ~ fitted(model) + I(fitted(model)^2))
  cat("White test p-value:   ", format(white$p.value, scientific = TRUE), "\n")

  # ---- 9e. Normality of residuals -------------------------------------
  cat("\n--- NORMALITY OF RESIDUALS ---\n")
  jb <- jarque.bera.test(residuals(model))
  cat("Jarque-Bera p-value:", format(jb$p.value, scientific = TRUE), "\n")
  cat("Skewness:           ", round(skewness(residuals(model)), 4), "\n")
  cat("Kurtosis:           ", round(kurtosis(residuals(model)), 4), "\n")

  resid_sample <- if (length(residuals(model)) > 5000) {
    sample(residuals(model), 5000)
  } else {
    residuals(model)
  }
  sw <- shapiro.test(resid_sample)
  cat("Shapiro-Wilk p-value:", format(sw$p.value, scientific = TRUE), "\n")

  # ---- 9f. Specification (RESET) --------------------------------------
  cat("\n--- SPECIFICATION (RESET TEST) ---\n")
  reset <- resettest(model, power = 2:3, type = "fitted")
  cat("RESET p-value:", format(reset$p.value, scientific = TRUE), "\n")
  if (reset$p.value < 0.05) cat("Model may be misspecified.\n")
  else cat("No evidence of misspecification.\n")

  # ---- 9g. Autocorrelation (Durbin-Watson) ----------------------------
  cat("\n--- AUTOCORRELATION (Durbin-Watson) ---\n")
  dw <- dwtest(model)
  cat("DW statistic:", round(dw$statistic, 4), "\n")
  cat("DW p-value:  ", format(dw$p.value, scientific = TRUE), "\n")

  # ---- 9h. Influential observations -----------------------------------
  cat("\n--- INFLUENTIAL OBSERVATIONS ---\n")
  cd <- cooks.distance(model)
  n_infl <- sum(cd > 4 / length(cd))
  cat("Cook's D > 4/n:", n_infl,
      "(", round(100 * n_infl / length(cd), 2), "%)\n")

  hat_v <- hatvalues(model)
  n_lev <- sum(hat_v > 2 * length(coef(model)) / length(hat_v))
  cat("High leverage:  ", n_lev,
      "(", round(100 * n_lev / length(hat_v), 2), "%)\n")

  # ---- 9i. Prediction accuracy ----------------------------------------
  cat("\n--- PREDICTION ACCURACY ---\n")
  r <- residuals(model)
  cat("MAE: ", round(mean(abs(r)), 4), "\n")
  cat("RMSE:", round(sqrt(mean(r^2)), 4), "\n")

  cat("\n========================================================================\n")

  # Return metrics for the comparison table
  return(list(
    name       = model_name,
    r2         = s$r.squared,
    adj_r2     = s$adj.r.squared,
    aic        = AIC(model),
    bic        = BIC(model),
    rmse       = sqrt(mean(r^2)),
    max_vif    = max_vif_val,
    bp_pval    = bp$p.value,
    reset_pval = reset$p.value,
    dw_stat    = dw$statistic
  ))
}

diag_A <- run_diagnostics(model_A, "Model A – Full Specification",       robust_A)
diag_B <- run_diagnostics(model_B, "Model B – Comprehensive Interaction", robust_B)
diag_C <- run_diagnostics(model_C, "Model C – M13 Urban Heterogeneity (PREFERRED)", robust_C)


############################################################
# SECTION 10 : SIDE-BY-SIDE COMPARISON TABLE
############################################################

cat("\n\n================================================================\n")
cat("          SIDE-BY-SIDE MODEL COMPARISON TABLE\n")
cat("================================================================\n")

all_diag <- list(diag_A, diag_B, diag_C)

comparison <- data.frame(
  Model        = sapply(all_diag, function(x) x$name),
  R2           = sapply(all_diag, function(x) round(x$r2, 4)),
  Adj_R2       = sapply(all_diag, function(x) round(x$adj_r2, 4)),
  AIC          = sapply(all_diag, function(x) round(x$aic, 1)),
  BIC          = sapply(all_diag, function(x) round(x$bic, 1)),
  Max_VIF      = sapply(all_diag, function(x) round(x$max_vif, 2)),
  RMSE         = sapply(all_diag, function(x) round(x$rmse, 4)),
  BP_pvalue    = sapply(all_diag, function(x) format(x$bp_pval, scientific = TRUE)),
  RESET_pvalue = sapply(all_diag, function(x) format(x$reset_pval, scientific = TRUE)),
  DW_stat      = sapply(all_diag, function(x) round(x$dw_stat, 4))
)

print(comparison, right = FALSE)

cat("\n--- INTERPRETATION GUIDE ---\n")
cat("R² / Adj R²  : Higher is better (variance explained)\n")
cat("AIC / BIC    : Lower is better (information criteria)\n")
cat("Max VIF      : Lower is better (<5 ideal, >10 severe multicollinearity)\n")
cat("RMSE         : Lower is better (prediction error)\n")
cat("BP p-value   : >0.05 preferred (no heteroskedasticity)\n")
cat("RESET p-value: >0.05 preferred (correct specification)\n")
cat("DW stat      : ≈2.0 preferred (no autocorrelation)\n")

cat("\n--- BEST MODEL BY EACH CRITERION ---\n")
cat("Highest R²:     ", comparison$Model[which.max(comparison$R2)], "\n")
cat("Highest Adj R²: ", comparison$Model[which.max(comparison$Adj_R2)], "\n")
cat("Lowest AIC:     ", comparison$Model[which.min(comparison$AIC)], "\n")
cat("Lowest BIC:     ", comparison$Model[which.min(comparison$BIC)], "\n")
cat("Lowest VIF:     ", comparison$Model[which.min(comparison$Max_VIF)],
    "(", min(comparison$Max_VIF), ")\n")
cat("Lowest RMSE:    ", comparison$Model[which.min(comparison$RMSE)], "\n")


############################################################
# SECTION 11 : COEFFICIENT TABLE (improved_toilet across models)
############################################################

cat("\n\n================================================================\n")
cat("     improved_toilet COEFFICIENT ACROSS MODELS (Robust SE)\n")
cat("================================================================\n")

extract_toilet <- function(robust_tbl, label) {
  toilet_names <- c("improved_toilet","improved_toilet1",
                    "improved_toilet_fac1")
  nm <- intersect(toilet_names, rownames(robust_tbl))[1]
  if (is.na(nm)) return(data.frame(Model = label,
      Coefficient = NA, SE = NA, t = NA, p = NA, Sig = "NA"))
  row <- robust_tbl[nm, ]
  sig <- if (row[4] < 0.001) "***" else if (row[4] < 0.01) "**" else
         if (row[4] < 0.05) "*" else "ns"
  data.frame(
    Model       = label,
    Coefficient = round(row[1], 4),
    SE          = round(row[2], 4),
    t_stat      = round(row[3], 4),
    p_value     = format(row[4], scientific = TRUE),
    Sig         = sig
  )
}

toilet_table <- rbind(
  extract_toilet(robust_A, "A – Full Specification"),
  extract_toilet(robust_B, "B – Comprehensive Interaction"),
  extract_toilet(robust_C, "C – M13 (Preferred)")
)

print(toilet_table, row.names = FALSE)

cat("\nNote: Model C reports the rural baseline coefficient.\n")
cat("Net urban effect = rural coef + interaction term.\n")

# Interaction term for Model C
inter_name <- grep("improved_toilet:urban", rownames(robust_C), value = TRUE)[1]
if (!is.na(inter_name)) {
  iv <- robust_C[inter_name, ]
  cat("\nModel C – Sanitation × Urban interaction:\n")
  cat("  Coefficient:", round(iv[1], 4), "\n")
  cat("  p-value:    ", format(iv[4], scientific = TRUE), "\n")
  cat("  Net urban effect ≈",
      round(robust_C["improved_toilet", 1] + iv[1], 4), "\n")
}


############################################################
# SECTION 12 : STARGAZER TABLE
############################################################

cat("\n\n================================================================\n")
cat("     REGRESSION TABLE (Stargazer – Text)\n")
cat("================================================================\n\n")

stargazer(model_A, model_B, model_C,
          type            = "text",
          title           = "OLS Results: Effect of Improved Sanitation on BMI",
          column.labels   = c("Full Spec","Interaction","M13 (Preferred)"),
          dep.var.labels  = "BMI (kg/m²)",
          omit            = c("state","region","religion","caste",
                              "cooking_fuel","water_source"),
          omit.labels     = c("State FE","Region FE","Religion",
                              "Caste","Cooking fuel","Water source"),
          star.cutoffs    = c(0.05, 0.01, 0.001),
          notes           = c("Robust SE in parentheses (HC3 for A,B; cluster for C)",
                              "*** p<0.001, ** p<0.01, * p<0.05"),
          se              = list(robust_A[, 2], robust_B[, 2], robust_C[, 2]),
          omit.stat       = c("ser"),
          notes.append    = FALSE)


############################################################
# SECTION 13 : ANOVA – NESTED MODEL COMPARISONS
############################################################

cat("\n\n================================================================\n")
cat("     ANOVA : NESTED MODEL COMPARISONS\n")
cat("================================================================\n")

cat("\n--- Model A vs Model B ---\n")
cat("(Do extra interactions / transforms improve fit?)\n")
tryCatch({
  print(anova(model_A, model_B))
}, error = function(e) {
  cat("Cannot compare (models are not strictly nested).\n")
  cat("Use AIC/BIC for non-nested comparison.\n")
})

cat("\n--- Comparing via AIC/BIC ---\n")
cat(sprintf("%-35s  AIC = %10.1f  BIC = %10.1f\n",
            "Model A – Full Specification",    AIC(model_A), BIC(model_A)))
cat(sprintf("%-35s  AIC = %10.1f  BIC = %10.1f\n",
            "Model B – Comprehensive Interaction", AIC(model_B), BIC(model_B)))
cat(sprintf("%-35s  AIC = %10.1f  BIC = %10.1f\n",
            "Model C – M13 (Preferred)",       AIC(model_C), BIC(model_C)))


############################################################
# SECTION 14 : DIAGNOSTIC PLOTS
############################################################

cat("\n\n================================================================\n")
cat("     DIAGNOSTIC PLOTS\n")
cat("================================================================\n")

# Residuals vs Fitted for all three models
par(mfrow = c(2, 3))
plot(model_A, which = 1, main = "Model A – Resid vs Fitted")
plot(model_B, which = 1, main = "Model B – Resid vs Fitted")
plot(model_C, which = 1, main = "Model C – Resid vs Fitted")
plot(model_A, which = 2, main = "Model A – Q-Q")
plot(model_B, which = 2, main = "Model B – Q-Q")
plot(model_C, which = 2, main = "Model C – Q-Q")
par(mfrow = c(1, 1))

# Residual histograms
par(mfrow = c(1, 3))
hist(residuals(model_A), breaks = 50, col = "steelblue",
     border = "white", main = "Model A – Residuals",
     xlab = "Residuals")
hist(residuals(model_B), breaks = 50, col = "darkorange",
     border = "white", main = "Model B – Residuals",
     xlab = "Residuals")
hist(residuals(model_C), breaks = 50, col = "darkgreen",
     border = "white", main = "Model C – Residuals",
     xlab = "Residuals")
par(mfrow = c(1, 1))


############################################################
# SECTION 15 : FINAL INTERPRETATION & CONCLUSION
############################################################

cat("\n\n================================================================\n")
cat("     FINAL INTERPRETATION & CONCLUSION\n")
cat("================================================================\n")

cat("
MODEL A – Full Specification (amogh.r, Model 5)
  Broad set of controls; no geographic fixed effects.
  Serves as a benchmark showing the sanitation–BMI
  relationship after controlling for socioeconomic,
  demographic, and household-infrastructure factors.

MODEL B – Comprehensive Interaction (amogh2.r, A5)
  Adds cubic age effects, many cross-interactions
  (sanitation×wealth, sanitation×education, etc.),
  clean-fuel and improved-water indicators, and
  Region fixed effects.  Captures non-linearities
  and heterogeneous treatment effects, at the cost
  of higher complexity and possible multicollinearity.

MODEL C – M13 Urban Heterogeneity + State FE [PREFERRED]
  Allows the sanitation effect to differ between
  rural and urban areas via an interaction term.
  State fixed effects absorb all time-invariant
  state-level unobservables.  Cluster-robust SE
  account for within-PSU correlation.

KEY FINDINGS (consistent across all three):
  1. Improved sanitation is positively and significantly
     associated with women's BMI at the 1% level.
  2. The rural sanitation effect (~0.26 BMI points)
     is substantially larger than in urban areas.
  3. Wealth and education remain the strongest
     predictors of BMI across all specifications.
  4. Cross-sectional results reflect conditional
     associations, not causal estimates.
  5. Heteroskedasticity is present in all models;
     robust standard errors are used throughout.

PREFERRED MODEL RATIONALE (M13):
  - Clean policy interpretation (rural vs urban).
  - State FE reduce omitted-variable bias.
  - Cluster-robust SE correct for survey design.
  - No severe multicollinearity (unlike the
    environmental-bundle specification M7).
")

cat("\n================================================================\n")
cat("     ANALYSIS COMPLETE\n")
cat("================================================================\n\n")
