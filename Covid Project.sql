/*
	Data from Our World in Data. Date range is early Feb 2020 to early Feb 2023
*/

--Covid Deaths Table
SELECT * 
FROM CovidDeaths 
WHERE continent IS NOT NULL
ORDER BY 3, 4;

--Select Data that we are going to be using
SELECT
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

--Total Cases vs Total Deaths
--Shows historical liklihood of death if one was to contract covid in their country
SELECT
	location,
	date,
	total_cases,
	total_deaths,
	ROUND(((total_deaths/total_cases)*100), 2) as death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

--Total Cases vs Population
--Shows the historical percentage of population that contracted covid
SELECT
	location,
	date,
	population,
	total_cases,
	ROUND(((total_cases/population)*100), 2) as positve_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

--Countries with the highest case rate compared to population
SELECT
	location,
	population,
	MAX(total_cases) as highest_case_count,
	ROUND(MAX(((total_cases)/population)*100), 2) as population_infected_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY population_infected_percentage DESC;

SELECT
	location,
	population,
	date,
	MAX(total_cases) as highest_case_count,
	ROUND(MAX(((total_cases)/population)*100), 2) as population_infected_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population, date
ORDER BY population_infected_percentage DESC;

--Countries with the highest death count
SELECT
	location,
	MAX(CAST(total_deaths as int)) as total_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;

--Continents total death counts
SELECT
	location as continent,
	MAX(CAST(total_deaths as int)) as total_death_count
FROM CovidDeaths
WHERE continent IS NULL
	AND location NOT IN ('World', 'European Union', 'High Income', 'Upper middle income', 'Lower middle income', 'Low income', 'International')
GROUP BY location
ORDER BY total_death_count DESC;

--Continents highest death, will be able to drill down to locations in visuals
SELECT
	continent,
	MAX(CAST(total_deaths as int)) as total_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;

--Global Numbers
SELECT
	date,
	SUM(new_cases) as total_cases,
	SUM(CAST(new_deaths as int)) as total_deaths,
	ROUND((SUM(CAST(new_deaths as int))/SUM(new_cases)*100), 2) as death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1;

SELECT
	SUM(new_cases) as total_cases,
	SUM(CAST(new_deaths as int)) as total_deaths,
	ROUND((SUM(CAST(new_deaths as int))/SUM(new_cases)*100), 2) as death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL;

--Covid Vaccinations Table
SELECT *
FROM CovidVaccinations;

SELECT *
FROM CovidVaccinations vac
JOIN CovidDeaths dea
	ON vac.location = dea.location
		AND vac.date = dea.date;

--Total Population vs Vaccination with a cte
WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_count_vaccinated) AS
(
	SELECT 
		dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_count_vaccinated
	FROM CovidVaccinations vac
	JOIN CovidDeaths dea
		ON vac.location = dea.location
			AND vac.date = dea.date
	WHERE dea.continent IS NOT NULL
)
SELECT *, ROUND(((rolling_count_vaccinated/population)*100), 3) as vaccinated_percentage
FROM pop_vs_vac;

--Total Population vs Vaccination with a temp table
DROP TABLE IF EXISTS #percent_pop_vaccinated;
CREATE TABLE #percent_pop_vaccinated (
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	rolling_count_vaccinated numeric);

INSERT INTO #percent_pop_vaccinated
SELECT 
		dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_count_vaccinated
FROM CovidVaccinations vac
JOIN CovidDeaths dea
	ON vac.location = dea.location
		AND vac.date = dea.date
WHERE dea.continent IS NOT NULL;

SELECT *, ROUND(((rolling_count_vaccinated/population)*100), 3) as vaccinated_percentage
FROM #percent_pop_vaccinated;

--Creating view to store data for later visuals
CREATE VIEW PercentPopVaccinated AS
SELECT 
		dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_count_vaccinated
FROM CovidVaccinations vac
JOIN CovidDeaths dea
	ON vac.location = dea.location
		AND vac.date = dea.date
WHERE dea.continent IS NOT NULL;

SELECT *
FROM PercentPopVaccinated;