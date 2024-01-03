SELECT * FROM dbo.covid_deaths_trincan
WHERE (location='Canada' OR location='Trinidad and Tobago') 
AND total_deaths IS NOT NULL 
AND icu_patients IS NOT NULL 
AND hosp_patients IS NOT NULL 
AND icu_patients_per_million IS NOT NULL


--Total Cases vs Total Deaths
--Likelihood of dying if you contract covid in your country
---> Canada had a marginally greater overall mortality rate than Trinidad.

WITH MortalityRanked AS (
    SELECT
        location, date, total_cases, new_cases, total_deaths,
        (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS mortality,
        RANK() OVER (PARTITION BY location ORDER BY (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 DESC) AS rank_order
    FROM
        dbo.covid_deaths_trincan
    WHERE
        (location='Canada' OR location LIKE '%Trinidad%')
)
SELECT
    location, date, total_cases, new_cases, total_deaths, mortality
FROM
    MortalityRanked
WHERE
    rank_order <= 5
ORDER BY
    location, rank_order;


-- Highest Infection Rate compared to population
-- Trinidad:
-- Rank #128

-- Highest infection 191496 with infection percentage 12.507552041320851

-- Canada:
-- Rank #130

-- Highest infection 38454328 with infection percentage 12.336689383832166
SELECT location, population, MAX(total_cases) AS highest_infection, MAX(CONVERT(float, total_cases) / CONVERT(float, population))*100 as infection_percent
FROM dbo.covid_deaths_trincan
GROUP BY location, population
ORDER BY infection_percent desc



-- Total Population vs Vaccinations
-- Canada's vaccine distribution was significantly faster than Trinidad
SELECT dea.continent, dea.location, CONVERT(DATE, REPLACE(dea.date, ',', '-'), 105) AS date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vac_count
FROM dbo.covid_deaths_trincan dea
JOIN dbo.covid_vaccines_trincan vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND (dea.location='Canada' OR dea.location LIKE '%Trinidad%')
ORDER BY 1, 2, 3
