SELECT location, date, total_cases, new_cases, total_deaths, population
FROM public."CovidDeaths"
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Considering Total Deaths vs Total Cases (Worldwide)

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM public."CovidDeaths"
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Considering Total Deaths vs Total Cases (India)

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM public."CovidDeaths"
WHERE location = 'India'
ORDER BY location, date;

-- Considering Total Cases vs Population (Worldwide)

SELECT location, date, total_cases, population, (total_cases/population)*100 AS cases_percentage
FROM public."CovidDeaths"
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Considering Total Cases vs Population (India)

SELECT location, date, total_cases, population, (total_cases/population)*100 AS cases_percentage
FROM public."CovidDeaths"
WHERE location = 'India'
ORDER BY location, date;

-- Highest infection rates with respect to population

SELECT location, population, MAX(total_cases) AS highest_infection_count, (MAX(total_cases)/population)*100 AS infected_percentage
FROM public."CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY infected_percentage DESC NULLS LAST;

-- Highest death counts with respect to population

SELECT location, MAX(total_deaths) AS total_death_count
FROM public."CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC NULLS LAST;

-- Highest death counts with respect to continent

SELECT location, MAX(total_deaths) AS total_death_count
FROM public."CovidDeaths"
WHERE continent IS NULL AND location NOT IN ('World', 'European Union')
GROUP BY location
ORDER BY total_death_count DESC NULLS LAST;

-- Continent-wise highest death counts with respect to population 

SELECT location, population, MAX(total_deaths)AS total_death_count, (MAX(total_deaths)/population)*100 AS deaths_percentage
FROM public."CovidDeaths"
WHERE continent IS NULL AND location NOT IN ('World', 'European Union')
GROUP BY location, population
ORDER BY deaths_percentage DESC NULLS LAST;

--Global death by cases percentage

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths,
       (SUM(new_deaths)/NULLIF(SUM(new_cases),0))*100 AS death_percentage
FROM public."CovidDeaths"
WHERE continent IS NULL AND location = 'World'
GROUP BY date
ORDER BY date DESC NULLS LAST;

-- JOINING deaths and vaccinations tables

SELECT *
FROM public."CovidDeaths" AS deaths
JOIN public."CovidVaccinations" AS vaccs
     ON deaths.date = vaccs.date
ORDER BY deaths.date;

-- Total populations vs Vaccinations
-- Including date-by-date RollingVaccinated

SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccs.new_vaccinations,
       SUM(vaccs.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date)
	   AS rolling_people_vaccinated
FROM public."CovidDeaths" AS deaths
JOIN public."CovidVaccinations" AS vaccs
     ON deaths.location = vaccs.location 
	 AND deaths.date = vaccs.date
WHERE deaths.continent IS NOT NULL
ORDER BY deaths.location, deaths.date;

-- USE CTE

With PopvsVacc (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccs.new_vaccinations,
       SUM(vaccs.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date)
	   AS rolling_people_vaccinated
FROM public."CovidDeaths" AS deaths
JOIN public."CovidVaccinations" AS vaccs
     ON deaths.location = vaccs.location 
	 AND deaths.date = vaccs.date
WHERE deaths.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated/population)*100 AS rolling_vaccinated_percentage
FROM PopvsVacc

-- TEMP Table

-- IN case modification to table needed, 
-- DROP TABLE IF EXISTS PercentPopulationVaccinated

CREATE TABLE PercentPopulationVaccinated
(
continent varchar (255),
	location varchar (255),
	date date,
	population bigint,
	new_vaccinations bigint,
	rolling_people_vaccinated numeric
);

INSERT INTO PercentPopulationVaccinated
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccs.new_vaccinations,
       SUM(vaccs.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date)
	   AS rolling_people_vaccinated
FROM public."CovidDeaths" AS deaths
JOIN public."CovidVaccinations" AS vaccs
     ON deaths.location = vaccs.location 
	 AND deaths.date = vaccs.date
WHERE deaths.continent IS NOT NULL
);

SELECT *, (rolling_people_vaccinated/population)*100 AS rolling_vaccinated_percentage
FROM PercentPopulationVaccinated;

-- Creating a view to store data for later visualization

CREATE VIEW PercentPopuationVaccinated  AS
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccs.new_vaccinations,
       SUM(vaccs.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date)
	   AS rolling_people_vaccinated
FROM public."CovidDeaths" AS deaths
JOIN public."CovidVaccinations" AS vaccs
     ON deaths.location = vaccs.location 
	 AND deaths.date = vaccs.date
WHERE deaths.continent IS NOT NULL;

SELECT *
FROM PercentPopulationVaccinated;

-- Analysis of hospital bed capacity country wise

SELECT location, MAX(hospital_beds_per_thousand) AS hosp_beds_per_thousand
FROM public."CovidVaccinations"
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY MAX(hospital_beds_per_thousand) DESC NULLS LAST;

-- Comparing Country's death rate with its GDP

SELECT deaths.location, deaths.population, MAX(deaths.total_deaths) AS total_death_count,
       (MAX(deaths.total_deaths)/population)*100 AS deaths_percentage, vaccs.gdp_per_capita
FROM public."CovidDeaths" AS deaths
JOIN public."CovidVaccinations" AS vaccs
     ON deaths.location = vaccs.location
WHERE deaths.continent IS NOT NULL
GROUP BY deaths.location, deaths.population, vaccs.gdp_per_capita
ORDER BY vaccs.gdp_per_capita DESC NULLS LAST;

-- Comparing Country's death rate with its HDI

SELECT deaths.location, deaths.population, MAX(deaths.total_deaths) AS total_death_count,
       (MAX(deaths.total_deaths)/population)*100 AS deaths_percentage, vaccs.human_development_index
FROM public."CovidDeaths" AS deaths
JOIN public."CovidVaccinations" AS vaccs
     ON deaths.location = vaccs.location
WHERE deaths.continent IS NOT NULL
GROUP BY deaths.location, deaths.population, vaccs.human_development_index
ORDER BY vaccs.human_development_index DESC NULLS LAST;
