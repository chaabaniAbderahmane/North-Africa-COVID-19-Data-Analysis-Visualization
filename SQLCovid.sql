--1-- select data that we are be using

SELECT  *
FROM [CovidProject].[dbo].[CovidDeaths]
order by location , date



-- 2 --locking at total case vs total death
-- showing linkhood of dying if you contract covid in your country


SELECT 
    location,
    FORMAT(CAST(date AS DATE), 'yyyy-MM-dd') AS Date,
    CAST(total_cases AS FLOAT) AS total_cases,
    CAST(total_deaths AS FLOAT) AS total_deaths,
    ROUND((CAST(total_deaths AS FLOAT) / NULLIF(CAST(total_cases AS FLOAT), 0)) * 100.0, 2) AS DeathsPercentage
FROM 
    [CovidProject].[dbo].[CovidDeaths]
ORDER BY 
    1,2;


-- 3 -- locking at total case vs population
-- showing porcebtage of population got covid

SELECT
    Location,
    date,
    Population,
    total_cases,
    FORMAT((total_cases * 1.0 / population) * 100, '0.0000') AS PercentPopulationInfected
FROM
    [CovidProject].[dbo].[CovidDeaths]
ORDER BY
    1, 2;




-- 4 Locking for countries zith highest infections Rate compered to population 

SELECT
    Location,
    Population,
    MAX(total_cases) AS HighestInfectionCount,
    Format(MAX((total_cases * 1.0 / population) * 100), '0.0000') AS MaxPercentPopulationInfected
FROM 
    [CovidProject].[dbo].[CovidDeaths]
GROUP BY 
    Location, Population
ORDER BY 
    MaxPercentPopulationInfected DESC;





--  5 Showing counties with highest death count per country and population

SELECT
    location,
	 population,
    max(cast(total_deaths as int )) as TotalPopulationDeathCount
FROM [CovidProject].[dbo].[CovidDeaths]
Group by location , population 
ORDER BY  
    3 DESC;



--  6 -- Global numbers
SELECT 
    SUM(CAST(new_cases AS INT)) as total_cases, 
    SUM(CAST(new_deaths AS INT)) as total_deaths, 
    CASE 
        WHEN SUM(CAST(new_cases AS INT)) = 0 THEN 0 -- Avoid division by zero error
        ELSE SUM(CAST(new_deaths AS INT)) * 100.0 / SUM(CAST(new_cases AS INT)) 
    END as DeathPercentage
FROM 
    [CovidProject].[dbo].[CovidDeaths];




-- 7 Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT
    dea.location,
    CONVERT(VARCHAR(10), dea.date, 23) AS Date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
FROM
    [CovidProject].[dbo].[CovidDeaths] dea
JOIN
    [CovidProject].[dbo].[CovidVaccination] vac ON 
	dea.location = vac.location AND dea.date = vac.date
where new_vaccinations is not null
ORDER BY
    1,2;





--8 Using CTE to perform Calculation on Partition By in previous query


-- Using CTE to perform Calculation on Partition By in previous query
WITH PopvsVac (Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
    SELECT
        dea.location,
        dea.date,
        dea.population,
        CAST(vac.new_vaccinations AS int), -- Explicit conversion to int
        SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
    FROM
        [CovidProject].[dbo].[CovidDeaths] dea
    INNER JOIN
        [CovidProject].[dbo].[CovidVaccination]  vac ON dea.location = vac.location AND dea.date = vac.date
    WHERE
        vac.new_vaccinations IS NOT NULL
)
SELECT
    *,
    
	   Format((RollingPeopleVaccinated * 1.0  / population) * 100, '0.0000') AS Percentage

FROM
    PopvsVac;



--9 Using Temp Table to perform Calculation on Partition By in previous query
-- 9 Using Temp Table to perform Calculation on Partition By in previous query
IF OBJECT_ID('tempdb..#PercentPopulationVaccinated') IS NOT NULL
    DROP TABLE #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    RollingPeopleVaccinated numeric
);

INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.location,
    dea.date,
    dea.population,
    CAST(vac.new_vaccinations AS int), -- Explicit conversion to int
    SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
FROM
    [CovidProject].[dbo].[CovidDeaths] dea
INNER JOIN
    [CovidProject].[dbo].[CovidVaccination] vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    vac.new_vaccinations IS NOT NULL;

SELECT *,
       FORMAT((RollingPeopleVaccinated / Population) * 100, '0.0000') AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated
ORDER BY location;



-- 10 Creating View to store data for later visualizations

-- Creating View to store data for later visualizations
USE CovidProject;
GO

CREATE VIEW PercentPopulationVaccinated
AS 
SELECT
    dea.location,
    dea.date,
    dea.population,
    CAST(vac.new_vaccinations AS int) AS NewVaccinations, -- Alias for the fourth column
    SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
FROM
    [CovidProject].[dbo].[CovidDeaths] dea
INNER JOIN
    [CovidProject].[dbo].[CovidVaccination] vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    vac.new_vaccinations IS NOT NULL;


	
--DROP VIEW [dbo].PercentPopulationVaccinatededd;




--SELECT * FROM sys.views;
