library(haven)
library(dplyr)

# ===============================
# STEP 1: Load Required Variables
# ===============================

data <- read_dta(
  "C:/Visual studios/IAIR7DFL.DTA",
  col_select = c(
    
    # --- Sanitation & Water ---
    "v116",    # toilet type
    "v113",    # water source
    "v115",    # time to get water
    "v127",    # shared toilet
    
    # --- Environment ---
    "v159",    # electricity
    "v161",    # cooking fuel
    
    # --- Anthropometry ---
    "v445",    # BMI (x100)
    "v438",    # height (cm)
    "v437",    # weight (kg)
    
    # --- Demographics ---
    "v012",    # age
    "v025",    # urban/rural
    "v024",    # state
    "v101",    # region
    
    # --- Socioeconomic ---
    "v106",    # education level
    "v133",    # years of education
    "v190",    # wealth index
    "v130",    # religion
    "v131",    # caste/tribe
    
    # --- Fertility ---
    "v201",    # children ever born
    "v212",    # age at first birth
    
    # --- Survey Design ---
    "v005",    # sample weight
    "v021",    # cluster
    "v022"     # strata
  )
)

# ===============================
# STEP 2: Rename Variables
# ===============================

data <- data %>%
  rename(
    toilet_type = v116,
    water_source = v113,
    water_time = v115,
    toilet_shared = v127,
    electricity = v159,
    cooking_fuel = v161,
    bmi_raw = v445,
    height_cm = v438,
    weight_kg = v437,
    age = v012,
    urban = v025,
    state = v024,
    region = v101,
    education_level = v106,
    education_years = v133,
    wealth = v190,
    religion = v130,
    caste = v131,
    children_born = v201,
    age_first_birth = v212,
    weight_raw = v005,
    cluster = v021,
    strata = v022
  )

# ===============================
# STEP 3: Clean BMI
# ===============================

data <- data %>%
  mutate(
    bmi = bmi_raw / 100,
    weight = weight_raw / 1000000
  )

# Remove biologically implausible BMI
data <- data %>%
  filter(bmi >= 12 & bmi <= 60)

# ===============================
# STEP 4: Undernutrition Indicator
# ===============================

data <- data %>%
  mutate(
    underweight = ifelse(bmi < 18.5, 1, 0)
  )

# ===============================
# STEP 5: Improved Sanitation Variable
# ===============================

data$toilet_type <- as_factor(data$toilet_type)

data <- data %>%
  mutate(
    improved_toilet = ifelse(
      grepl("no facility|open|pit without slab|other",
            tolower(as.character(toilet_type))),
      0, 1
    )
  )

# ===============================
# STEP 6: Convert to Factors
# ===============================

data <- data %>%
  mutate(
    urban = as_factor(urban),
    education_level = as_factor(education_level),
    wealth = as_factor(wealth),
    religion = as_factor(religion),
    caste = as_factor(caste),
    state = as_factor(state),
    region = as_factor(region)
  )

# ===============================
# STEP 7: Final Dataset
# ===============================

final_data <- data %>%
  select(
    bmi,
    underweight,
    improved_toilet,
    water_source,
    water_time,
    toilet_shared,
    electricity,
    cooking_fuel,
    age,
    education_level,
    education_years,
    wealth,
    religion,
    caste,
    children_born,
    age_first_birth,
    urban,
    state,
    region,
    weight,
    cluster,
    strata
  ) %>%
  na.omit()

# Check
dim(final_data)
head(final_data)