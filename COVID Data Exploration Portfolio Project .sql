--SELECT *
--FROM PortfolioProject1..CovidDeaths
--ORDER BY 3,4

-- SELECT *
-- FROM PortfolioProject1..CovidVaccines
-- ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject1..CovidDeaths
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths

SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    CASE 
        WHEN total_cases = NULL THEN NULL  -- CASE Statement: This checks if total_cases is zero. If it is, the query returns NULL.
        ELSE (total_deaths / CAST(total_cases AS FLOAT)) * 100 
    END AS DeathRatePercentage
FROM PortfolioProject1..CovidDeaths
ORDER BY location, date;

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidDeaths';

SELECT *
FROM PortfolioProject1..CovidDeaths
WHERE 
    ISNUMERIC(total_cases) = 0 OR 
    ISNUMERIC(total_deaths) = 0 OR 
    ISNUMERIC(population) = 0 OR 
    ISNUMERIC(new_cases) = 0 OR 
    ISNUMERIC(new_deaths) = 0 OR 
    ISNUMERIC(icu_patients) = 0 OR 
    ISNUMERIC(hosp_patients) = 0 OR 
    ISNUMERIC(weekly_icu_admissions) = 0 OR 
    ISNUMERIC(weekly_hosp_admissions) = 0;


BEGIN TRANSACTION;   -- converting  problematic columns from nvarchar to Float.

ALTER TABLE PortfolioProject1..CovidDeaths
ALTER COLUMN total_cases FLOAT;

ALTER TABLE PortfolioProject1..CovidDeaths
ALTER COLUMN total_deaths FLOAT;

ALTER TABLE PortfolioProject1..CovidDeaths
ALTER COLUMN population FLOAT;

ALTER TABLE PortfolioProject1..CovidDeaths
ALTER COLUMN new_cases FLOAT;

ALTER TABLE PortfolioProject1..CovidDeaths
ALTER COLUMN new_deaths FLOAT;

ALTER TABLE PortfolioProject1..CovidDeaths
ALTER COLUMN icu_patients FLOAT;

ALTER TABLE PortfolioProject1..CovidDeaths
ALTER COLUMN hosp_patients FLOAT;

ALTER TABLE PortfolioProject1..CovidDeaths
ALTER COLUMN weekly_icu_admissions FLOAT;

ALTER TABLE PortfolioProject1..CovidDeaths
ALTER COLUMN weekly_hosp_admissions FLOAT;

COMMIT TRANSACTION;

SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    CASE 
        WHEN total_cases = 0 THEN 0
        ELSE (total_deaths / total_cases) * 100 
    END AS DeathRatePercentage
FROM PortfolioProject1..CovidDeaths
ORDER BY location, date;

SELECT location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage -- Calculating death percentage of total cases and ordering by location and death percentage.
FROM PortfolioProject1..CovidDeaths
ORDER BY 1,6

SELECT location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 as PercentOfPopulationInfected
FROM PortfolioProject1..CovidDeaths
WHERE [location] LIKE '%Kingdom%'
ORDER BY 1,3

-- Countries with Highest Infection Rate compared to Population 

SELECT location, population, Max(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as PercentOfPopulationInfected
FROM PortfolioProject1..CovidDeaths
--WHERE [location] LIKE '%Kingdom%'
Group by location, population
ORDER BY PercentOfPopulationInfected DESC

-- Countries with Highest Death Count per Population
SELECT location, MAX(Total_deaths) as TotalDeathCount
FROM PortfolioProject1..CovidDeaths
WHERE continent is NOT NULL
GROUP BY location
ORDER by TotalDeathCount DESC

-- Continent breakdown

-- Highest Death Count by Continent 
SELECT continent, MAX(Total_deaths) as TotalDeathCount
FROM PortfolioProject1..CovidDeaths
WHERE continent is not NULL
GROUP BY continent
ORDER by TotalDeathCount DESC


-- Global
SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, Sum(new_deaths)/Sum(new_cases)*100 as DeathPercentage
FROM PortfolioProject1..CovidDeaths
WHERE continent is not null
order by 1,2

--Vaccinations

SELECT * 
FROM PortfolioProject1..CovidDeaths dth
JOIN PortfolioProject1..CovidVaccines vac 
on dth.[location] = vac.[location]
and dth.[date] = vac.[date]

-- total population vs Vaccinations 
SELECT dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dth.location order by dth.location, dth.date) as RollingVaccinations 
FROM PortfolioProject1..CovidDeaths dth
JOIN PortfolioProject1..CovidVaccines vac
on dth.[location] = vac.[location]
and dth.[date] = vac.[date]
WHERE dth.continent is not NULL
order by 2,3 

-- Using CTE

With PopVsVac (continent,location, date, population, new_vaccinations, RollingVaccinations)
AS
(
    SELECT dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dth.location order by dth.location, dth.date) as RollingVaccinations 
FROM PortfolioProject1..CovidDeaths dth
JOIN PortfolioProject1..CovidVaccines vac
on dth.[location] = vac.[location]
and dth.[date] = vac.[date]
WHERE dth.continent is not NULL
-- order by 2,3 
)
SELECT *, (RollingVaccinations/population)*100 as VaccinationRate
FROM PopVsVac

-- Using Temp Table
DROP TABLE if EXISTS #PopulationVaccinationRate
CREATE TABLE #PopulationVaccinationRate
(
    Continent nvarchar(255),
    location nvarchar(255),
    date DATETIME,
    population NUMERIC, 
    new_vaccinations int,
    RollingVaccinations int
)

INSERT into #PopulationVaccinationRate
SELECT dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dth.location order by dth.location, dth.date) as RollingVaccinations 
FROM PortfolioProject1..CovidDeaths dth
JOIN PortfolioProject1..CovidVaccines vac
on dth.[location] = vac.[location]
and dth.[date] = vac.[date]
WHERE dth.continent is not NULL
-- order by 2,3 

SELECT *, (RollingVaccinations/population)*100 as VaccinationRate
FROM #PopulationVaccinationRate



-- Creating View for Tableau viz 

CREATE VIEW PopulationVaccinationRate as 
SELECT dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dth.location order by dth.location, dth.date) as RollingVaccinations 
FROM PortfolioProject1..CovidDeaths dth
JOIN PortfolioProject1..CovidVaccines vac
on dth.[location] = vac.[location]
and dth.[date] = vac.[date]
WHERE dth.continent is not NULL
-- order by 2,3 

SELECT *
FROM PopulationVaccinationRate