--VERIFYING TABLES WERE CREATED 

--SELECT *
--FROM dbo.CovidDeaths;

--SELECT *
--FROM dbo.CovidVaccinations;


SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM dbo.CovidDeaths 
ORDER BY 1,2;


-- total_cases vs total_deaths 
SELECT Location, date, total_cases, total_deaths, (cast(total_deaths as float)/cast(total_cases as float))*100 AS death_percentage
FROM dbo.CovidDeaths
ORDER BY 1,2;


-- total_cases vs population in US
SELECT Location, date, population, total_cases, (cast(total_cases as float)/cast(population as float))*100 AS infected_population_percentage
FROM dbo.CovidDeaths
WHERE location like '%states'
ORDER BY 1,2;

-- countries with highest infection rate compared to population
SELECT Location, MAX(total_cases) as highest_infection_count, MAX((cast(total_cases as float)/cast(population as float)))*100 AS  percent_population_infected
FROM dbo.CovidDeaths
GROUP BY location
ORDER BY percent_population_infected DESC;


-- countries with highest death count per population
SELECT Location, MAX(cast(total_deaths as int)) as total_death_count
FROM dbo.CovidDeaths
WHERE continent is not NULL --there are locations are not countries so this will remove those data out 
GROUP BY location
ORDER BY total_death_count DESC;

-- by continent
SELECT continent, MAX(cast(total_deaths as int)) as total_death_count
FROM dbo.CovidDeaths
WHERE continent is not NULL and location not like '%income%' 
GROUP BY continent
ORDER BY total_death_count DESC;


-- global
SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases) * 100 as death_percentage
FROM dbo.CovidDeaths
WHERE continent is not NULL
GROUP BY date
ORDER BY 1,2


SELECT  SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases) * 100 as death_percentage
FROM dbo.CovidDeaths
WHERE continent is not NULL
--GROUP BY date
ORDER BY 1,2

-- total population vs vacination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(numeric, vac.new_vaccinations)) OVER (Partition BY dea.location ORDER BY dea.location, 
dea.date) AS rolling_sum_people_vaccinated, 

FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY 2,3

--using CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_sum_people_vaccinated) --need to have same number of column for CTE
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(numeric, vac.new_vaccinations)) OVER (Partition BY dea.location ORDER BY dea.location, 
dea.date) AS rolling_sum_people_vaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent is not NULL and new_vaccinations is not NULL
--ORDER BY 2,3
)
SELECT *, (rolling_sum_people_vaccinated/population)*100
FROM PopvsVac

--TEMP Table
DROP Table if EXISTS Percent_Population_vaccinated
CREATE Table Percent_Population_vaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date DATETIME,
Population NUMERIC,
new_vaccinations NUMERIC,
rolling_sum_people_vaccinated NUMERIC)

INSERT INTO Percent_Population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(numeric, vac.new_vaccinations)) OVER (Partition BY dea.location ORDER BY dea.location, 
dea.date) AS rolling_sum_people_vaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent is not NULL and new_vaccinations is not NULL
--ORDER BY 2,3

SELECT *, (rolling_sum_people_vaccinated/population)*100
FROM Percent_Population_vaccinated


-- Create view to store data for visualization

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(numeric, vac.new_vaccinations)) OVER (Partition BY dea.location ORDER BY dea.location, 
dea.date) AS rolling_sum_people_vaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent is not NULL
--ORDER BY 2,3