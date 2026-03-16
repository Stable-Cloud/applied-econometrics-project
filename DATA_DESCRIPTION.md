# Final Sanitation & BMI Dataset - Data Description

## Dataset Overview

**File**: `final_sanitation_bmi_dataset.csv`  
**Sample Size**: 480,052 observations  
**Population**: Women aged 15-49 in India  
**Source**: NFHS-5 (National Family Health Survey), 2019-21  
**Geographic Scope**: Telangana state (based on original NFHS-5-TG-Telangana.csv)  
**Unit of Analysis**: Individual woman

---

## Variable Descriptions

### Outcome Variable

| Variable | Type | Description | Values/Range |
|----------|------|-------------|---------------|
| **bmi** | Continuous (Numeric) | Body Mass Index (kg/m²) | Float; measured from height and weight |
| **weight** | Continuous (Numeric) | Body weight in kilograms | Float; used to calculate BMI |
| **underweight** | Binary/Categorical | Indicator for underweight status | Likely 0 = Not underweight, 1 = Underweight (BMI < 18.5) |

---

### Primary Explanatory Variable

| Variable | Type | Description | Values/Range |
|----------|------|-------------|---------------|
| **improved_toilet** | Binary/Categorical | Access to improved toilet facility | 0 = No, 1 = Yes (includes flush/pit latrines, ventilated pit latrines) |

---

### Infrastructure & Sanitation Variables

| Variable | Type | Description | Values/Range |
|----------|------|-------------|---------------|
| **water_source** | Categorical | Source of drinking water | Coded categories (e.g., 11=piped water, 12=public tap, 21=tubewell, 31=hand pump, 41=protected well, etc.) |
| **water_time** | Continuous (Numeric) | Time to collect water | Minutes; 0 = water available on premises |
| **toilet_shared** | Binary/Categorical | Whether toilet is shared | 0 = Not shared/own toilet, 1 = Shared with other households |
| **electricity** | Binary/Categorical | Household has electricity | 0 = No, 1 = Yes |
| **cooking_fuel** | Categorical | Type of cooking fuel used | Multiple categories (1=electricity, 2=LPG/natural gas, 3=coal, 4=wood, 5=other; 95=clean fuels) |

---

### Socio-Demographic Variables

| Variable | Type | Description | Values/Range |
|----------|------|-------------|---------------|
| **age** | Continuous (Numeric) | Woman's age | 15-49 years (NFHS reproductive age sample) |
| **age_first_birth** | Continuous (Numeric) | Age at first childbirth | Numeric; years |
| **education_level** | Categorical | Highest education level attained | Categorical codes (likely: no education, primary, secondary, higher) |
| **education_years** | Continuous (Numeric) | Years of formal education completed | 0+ years |
| **children_born** | Continuous (Numeric) | Total number of children ever born | 0+ (count variable) |

---

### Socio-Economic Variables

| Variable | Type | Description | Values/Range |
|----------|------|-------------|---------------|
| **wealth** | Categorical/Ordinal | Household wealth quintile | 5 categories: Poorest, Poorer, Middle, Richer, Richest |
| **religion** | Categorical | Household religion | Categories (e.g., Hindu, Muslim, Christian, Sikh, Buddhist, Jain, etc.) |
| **caste** | Categorical | Social caste/ethnic group | Categories (SC=Scheduled Caste, ST=Scheduled Tribe, OBC=Other Backward Class, General, etc.) |

---

### Geographic Variables

| Variable | Type | Description | Values/Range |
|----------|------|-------------|---------------|
| **urban** | Binary/Categorical | Urban vs. rural residence | 0 = Rural, 1 = Urban |
| **state** | Categorical | State of residence | Fixed effects variable; Telangana state with district breakdown |
| **region** | Categorical | Geographic region within state | Regional classifications within Telangana |
| **cluster** | Categorical/Integer | Survey cluster identifier | Used for cluster-robust standard errors |
| **strata** | Categorical | Survey stratum | Stratification variable for survey design |

---

## Variable Type Summary

### Numeric/Continuous Variables (9)
- `bmi` — Body Mass Index
- `weight` — Body weight
- `age` — Woman's age
- `age_first_birth` — Age at first birth
- `education_years` — Years of education
- `water_time` — Time to collect water
- `children_born` — Number of children
- `cluster` — Survey cluster ID
- `strata` — Survey stratum

### Categorical/Factor Variables (13)
**Binary (2 categories)**:
- `underweight` — BMI < 18.5
- `improved_toilet` — Access to improved toilet
- `toilet_shared` — Shared toilet facility
- `electricity` — Electricity access
- `urban` — Urban/rural residence

**Multicategory**:
- `water_source` — Type of drinking water source
- `cooking_fuel` — Type of cooking fuel
- `education_level` — Education attainment level
- `wealth` — Wealth quintile (5-category ordinal)
- `religion` — Religion category
- `caste` — Caste/ethnic group
- `state` — State (geographic region)
- `region` — Region within state

---

## Data Quality

### Missing Values
- **No missing values detected** in the dataset
- All 480,052 observations are complete across all 22 variables

### Applied Transformations (in analysis)
The following derived variables are created during analysis:
- `age_squared` — Age²
- `age_cubed` — Age³
- `log_education` — ln(education_years + 1)
- `sqrt_children` — √(children_born)
- `age_c` — Centered age (age - mean)
- `age_c2` — Centered age squared
- `children_c` — Centered children born
- `afb_c` — Centered age at first birth
- `clean_fuel` — Indicator for clean cooking fuels (=1 if cooking_fuel ∈ {1, 2, 95})
- `improved_water` — Indicator for improved water source (=1 if water_source ∈ {11, 12, 13, 14, 21, 31, 32, 41})

---

## Analysis Context

This dataset is used to analyze **the impact of improved sanitation on BMI** with three econometric models:

1. **M13** (Primary Model) — Urban-Rural Heterogeneity Model
   - Tests whether sanitation effects differ between urban and rural areas
   - Specification: `BMI ~ improved_toilet × urban + age + education + wealth + caste + religion + children + state FE`

2. **M7** — Regional Fixed Effects Model
   - Controls for regional unobserved heterogeneity
   - Specification: `BMI ~ improved_toilet + age + education + wealth + region FE`

3. **A5** — Comprehensive Interaction Model
   - Captures non-linear and heterogeneous effects
   - Includes multiple interaction terms and infrastructure variables

---

## Survey Design Notes

- **Cluster**: Survey enumeration clusters (used for cluster-robust inference)
- **Strata**: Survey stratification for sampling design
- **NFHS-5 Coverage**: All-India nationally representative sample of women aged 15-49
- **Telangana Focus**: This dataset is subset to Telangana state from the full NFHS-5

---

*Last Updated: 2026-03-16*
