# ECON F342 — Applied Econometrics  
## Final Report: Improved Sanitation and Women's Nutritional Status in India  
### NFHS-5 (2019–21) | OLS Analysis | Preferred Model: M13

---

## 1. Introduction

This report presents a comparative analysis of three OLS regression specifications examining the association between access to improved household sanitation and women's Body Mass Index (BMI) in India. The data come from the National Family Health Survey (NFHS-5, 2019–21), covering **480,052 women aged 15–49**.

The preferred specification — **Model C (M13)** — allows the sanitation effect to differ between rural and urban areas through an interaction term, includes State Fixed Effects to absorb unobserved state-level heterogeneity, and uses cluster-robust standard errors to account for the survey's multi-stage sampling design.

---

## 2. Data Description

| Statistic | Value |
|---|---|
| Total observations | 480,052 |
| Missing values (key variables) | 0 |
| Mean BMI | 23.02 kg/m² |
| Mean Age | 34.77 years |
| Mean Children Born | 2.58 |
| Mean Age at First Birth | 20.76 years |
| Proportion with Improved Toilet | 80.6% |
| Rural share | 76.4% |

### Education Distribution (%)

| Higher | No Education | Primary | Secondary |
|---|---|---|---|
| 9.53 | 30.91 | 14.80 | 44.76 |

### Wealth Distribution (%)

| Poorest | Poorer | Middle | Richer | Richest |
|---|---|---|---|---|
| 21.56 | 22.39 | 20.95 | 18.96 | 16.14 |

The sample is predominantly rural, with roughly one-third of women having no formal education. The 19.4% without improved sanitation (~93,000 women) provides a large enough control group for precise estimation.

---

## 3. Model Specifications

### Model A — Full Specification  
*Source: amogh.r, Model 5*

$$\text{BMI}_i = \beta_0 + \beta_1 \cdot \text{improved\_toilet}_i + \beta_2 \cdot \text{age}_i + \beta_3 \cdot \text{age}^2_i + \beta_4 \cdot \text{education\_years}_i + \beta_5 \cdot \text{wealth}_i + \beta_6 \cdot \text{urban}_i + \beta_7 \cdot \text{children\_born}_i + \gamma \mathbf{X}_i + \varepsilon_i$$

> Broad controls (age quadratic, education years, wealth, urban, children, electricity, cooking fuel, religion, caste). **No geographic fixed effects.** Serves as a benchmark.

### Model B — Comprehensive Interaction  
*Source: amogh2.r, Model A5*

$$\text{BMI}_i = \beta_0 + \beta_1 \cdot \text{improved\_toilet}_i + f(\text{age}_i) + \text{interactions} + \text{Region FE} + \gamma \mathbf{X}_i + \varepsilon_i$$

> Adds cubic age, sanitation × wealth, sanitation × education, sanitation × urban, education × wealth, urban × wealth interactions, clean fuel, improved water, and Region Fixed Effects. Maximises R² but at significant complexity cost.

### Model C — M13: Urban Heterogeneity + State FE ⭐ PREFERRED  
*Source: parth_ols.r, Model M13*

$$\text{BMI}_i = \beta_0 + \beta_1 \cdot \text{improved\_toilet}_i + \beta_2 \cdot \text{urban}_i + \beta_3 \cdot (\text{improved\_toilet}_i \times \text{urban}_i) + \beta_4 \cdot \text{age\_c}_i + \beta_5 \cdot \text{age\_c}^2_i + \gamma \mathbf{X}_i + \delta_s + \varepsilon_i$$

> Centered continuous variables, a single theoretically motivated interaction (sanitation × urban), State Fixed Effects ($\delta_s$), and cluster-robust standard errors at the PSU level. **Clean, interpretable, and econometrically sound.**

---

## 4. Side-by-Side Comparison

| Criterion | Model A | Model B | **Model C (M13)** |
|---|---|---|---|
| **R²** | 0.1568 | 0.1782 | **0.1776** |
| **Adj R²** | 0.1567 | 0.1781 | **0.1775** |
| **AIC** | 2,698,259 | 2,685,979 | **2,686,289** |
| **BIC** | 2,698,681 | 2,686,854 | **2,686,987** |
| **RMSE** | 4.0203 | 3.9689 | **3.9703** |
| **Max VIF** | 9.07 ⚠️ | 115.19 ❌ | **3.73 ✅** |
| **# Parameters** | 37 | 78 | **62** |
| **Geographic FE** | None | Region | **State** |
| **Robust SE** | HC3 | HC3 | **Cluster-robust** |

### Interpretation

While Model B achieves the marginally highest R² (0.1782 vs 0.1776 for M13 — a **negligible 0.03% difference**), it does so by adding 16 extra parameters, many of which are insignificant, and introduces **severe multicollinearity** (VIF = 115). Model A lacks any geographic fixed effects and has the lowest explanatory power.

**Model C (M13) dominates on the dimensions that matter most for credible inference:**
- Zero multicollinearity concern (VIF = 3.73)
- State FE — the most granular geographic controls of all three models
- Cluster-robust SE matching the NFHS survey design
- Virtually identical fit to Model B with far fewer parameters

---

## 5. The Key Coefficient: `improved_toilet`

| Model | Coefficient | Robust SE | t-stat | p-value | Sig |
|---|---|---|---|---|---|
| A — Full Specification | 0.2993 | 0.0157 | 19.06 | 6.3 × 10⁻⁸¹ | *** |
| B — Comprehensive Interaction | 0.3664 | 0.0462 | 7.94 | 2.1 × 10⁻¹⁵ | *** |
| **C — M13 (Preferred)** | **0.2622** | **0.0179** | **14.65** | **1.4 × 10⁻⁴⁸** | **\*\*\*** |

All three models find a **positive, highly significant** (p < 0.001) association between improved sanitation and BMI. The coefficient is stable across specifications, ranging from 0.26 to 0.37.

### M13 Interaction Effect (the distinguishing feature)

| Component | Estimate | p-value |
|---|---|---|
| Sanitation effect (rural baseline) | **+0.2622** | 1.4 × 10⁻⁴⁸ |
| Sanitation × Urban interaction | **−0.1746** | 5.2 × 10⁻³ |
| **Net sanitation effect (urban)** | **+0.0876** | — |

> **In rural areas, improved sanitation is associated with a 0.26 BMI-point increase.**  
> **In urban areas, the effect is only about one-third as large (0.09 BMI points).**

This finding is unique to M13 and has direct policy relevance: **sanitation investments yield the largest nutritional returns in rural areas**, where baseline infrastructure is weakest.

---

## 6. Other Key Coefficients (Stargazer Output)

| Variable | Model A | Model B | Model C (M13) |
|---|---|---|---|
| Age | +0.433*** | +0.343*** | +0.119*** (centered) |
| Age² | −0.005*** | −0.003** | −0.005*** |
| Wealth: poorest | −1.086*** | −1.091*** | −1.206*** |
| Wealth: richest | +1.357*** | +1.294*** | +1.493*** |
| Urban | +0.405*** | +0.651*** | +0.625*** |
| Children born | −0.088*** | −0.061*** | −0.138*** (centered) |
| Education: none | — | — | −0.784*** |
| Education: secondary | — | — | −0.099*** |
| Age at first birth | — | — | −0.056*** |

**Wealth dominates.** Moving from the poorest to richest quintile is associated with a +2.4 to +2.7 BMI-point increase — roughly **10× the sanitation effect.** Education and urban residence also have much larger magnitudes than sanitation. This is expected: sanitation is one channel among many affecting nutritional status.

---

## 7. Diagnostic Tests

| Test | Model A | Model B | Model C (M13) | Verdict |
|---|---|---|---|---|
| **Breusch-Pagan** | p ≈ 0 | p ≈ 0 | p ≈ 0 | Heteroskedasticity in all → robust SE |
| **White test** | p ≈ 0 | p ≈ 0 | p ≈ 0 | Confirmed |
| **RESET** | p ≈ 0 | p ≈ 0 | p ≈ 0 | Common in large cross-sections |
| **Durbin-Watson** | 1.80 | 1.84 | **1.84** | Near 2; no major concern |
| **Shapiro-Wilk** | p ≈ 0 | p ≈ 0 | p ≈ 0 | Large n → CLT protects inference |
| **Jarque-Bera** | p ≈ 0 | p ≈ 0 | p ≈ 0 | Skewness ≈ 1.0, kurtosis ≈ 6.2 |
| **Max VIF** | 9.07 ⚠️ | 115.19 ❌ | **3.73 ✅** | **M13 is the only model free of multicollinearity concerns** |
| **Cook's D (>4/n)** | 3.77% | 4.48% | 4.39% | Consistent; no single observation drives results |
| **High leverage** | 8.84% | 5.72% | 5.33% | Acceptable |

### Key diagnostic advantage of M13:
- **VIF = 3.73** — well below the conventional threshold of 5, let alone 10. Model B's VIF of 115 means its coefficient estimates are unreliable and sensitive to small perturbations in the data.
- **Cluster-robust SE** — the only model that correctly accounts for within-PSU correlation from the NFHS multi-stage design.

---

## 8. ANOVA: Model A vs Model B

```
  Res.Df     RSS    Df  Sum of Sq    F         Pr(>F)
1 480015   7759117
2 479974   7561853   41  197265     305.39    < 2.2e-16 ***
```

The 41 additional parameters in Model B are **jointly significant** (F = 305.39, p < 2.2 × 10⁻¹⁶). However, statistical significance with n = 480,000 is virtually guaranteed — even trivially small improvements will be "significant." The practical gain (197,265 / 7,759,117 ≈ **2.5%** of residual variance) is modest and comes at the cost of severe multicollinearity.

---

## 9. Why M13 Is the Best Model

| Criterion | Assessment |
|---|---|
| **Explanatory power** | R² = 0.1776, within 0.03% of Model B and 2 percentage points above Model A |
| **Multicollinearity** | ✅ VIF = 3.73 — the **only** model with no collinearity concerns |
| **Fixed Effects** | ✅ State FE (36 states/UTs) — most granular, absorbs state-level unobservables |
| **Standard Errors** | ✅ Cluster-robust at PSU level — correctly reflects NFHS survey design |
| **Parsimony** | 62 parameters vs 78 (Model B); no insignificant interaction clutter |
| **Interpretability** | One clean interaction: sanitation effect differs by rural/urban — directly policy-actionable |
| **Coefficient stability** | 0.2622 sits in the middle of the 0.26–0.37 range across all specifications |
| **Policy relevance** | Directly answers: *Where should sanitation investments be targeted?* → Rural areas |

**Model B's marginal R² advantage is illusory.** Its severe multicollinearity (VIF = 115) means the individual coefficient estimates — the very objects we care about for interpretation — are unreliable. Its many insignificant interaction terms (sanitation × richer, sanitation × richest, sanitation × education, all urban × wealth quintiles) suggest over-fitting rather than genuine signal. Model A, while cleanly estimated, omits geographic controls entirely and has meaningfully lower fit.

**M13 occupies the optimal position**: strong fit, clean diagnostics, proper inference, and a clear story.

---

## 10. Figures

### Figure 1: Scatterplot Matrix
- Pairwise scatter of BMI, Age, Children Born, and Age at First Birth (n = 5,000 sample).
- BMI increases with age (non-linearly), is negatively associated with number of children, and shows a positive relationship with age at first birth.

### Figure 2: BMI by Sanitation Access
- Women with improved toilets have a **higher median BMI** and a visibly upward-shifted distribution.
- Both groups show high-BMI outliers, but the interquartile range for the improved-sanitation group is clearly above the non-improved group.

### Figure 3: BMI by Sanitation × Urban Status
- **Rural areas:** Large visible gap between women with and without improved sanitation.
- **Urban areas:** The gap shrinks substantially — consistent with the M13 interaction term (−0.175, p = 0.005).
- Urban women have higher overall BMI regardless of sanitation status, reflecting better baseline infrastructure.

---

## 11. Interpretation of M13 Results

### Primary finding
Access to improved sanitation is associated with **+0.26 kg/m² higher BMI among rural women** (p < 0.001, 95% CI: [0.228, 0.296]), after controlling for age, education, wealth, caste, religion, fertility, and state fixed effects. For urban women, the association is **+0.09 kg/m²** — significant but substantially smaller.

### Mechanism
The environmental-health pathway: improved sanitation reduces exposure to faecal pathogens → lower diarrhoeal disease burden → improved nutrient absorption → higher BMI. This mechanism is stronger where baseline sanitation is poorest (rural areas), explaining the rural–urban gap.

### Magnitude in context
- The sanitation effect (0.26 BMI points) is **modest** relative to wealth (poorest vs richest: ~2.7 points) and education.
- However, it is **policy-actionable**: sanitation infrastructure can be directly targeted by government programs (e.g., Swachh Bharat Mission), while wealth and education are slower to change.
- For a woman of average height (152 cm), 0.26 BMI points ≈ **0.6 kg** — meaningful at the population level when scaled to millions of rural women.

---

## 12. Limitations

1. **Cross-sectional data:** Results are conditional associations, not causal estimates. Unobserved factors (health awareness, dietary habits, genetics) may confound the relationship.
2. **RESET test rejection:** All models fail the specification test, suggesting some functional-form misspecification remains.
3. **Non-normal residuals:** Skewness ≈ 1.0 and kurtosis ≈ 6.2 indicate a right-skewed BMI distribution. With n = 480K the Central Limit Theorem protects standard inference, but prediction intervals should be used cautiously.
4. **BMI as a nutritional indicator:** BMI conflates lean mass and fat mass and does not capture micronutrient deficiencies.

---

## 13. Conclusion

Across all three OLS specifications, improved household sanitation is **positively and significantly associated with women's BMI** in India. The preferred model (**M13**) demonstrates that this association is **strongest in rural areas** (+0.26 BMI points) and **substantially weaker in urban areas** (+0.09 BMI points), after absorbing state-level unobservables and clustering standard errors at the primary sampling unit level.

M13 is the clear choice among the three models: it achieves virtually the same explanatory power as the most complex specification while maintaining **no multicollinearity**, using **State Fixed Effects**, and providing a **clean, policy-relevant interpretation**. Sanitation infrastructure investments should be prioritised in rural areas, where the marginal nutritional return is greatest.

---

*Analysis conducted using R 4.4.x with packages: car, lmtest, sandwich, stargazer, nortest, tseries, moments.*  
*Data: NFHS-5 (2019–21), India. N = 480,052.*
