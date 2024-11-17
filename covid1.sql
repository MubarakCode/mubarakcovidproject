Select * From mubarakdb..CovidDeaths$ where continent is not null order by 3,4
--Select * From mubarakdb..CovidVaccination$_xlnm#_FilterDatabase order by 3,4--
select location, date, total_cases, new_cases, total_deaths, population from mubarakdb..CovidDeaths$ order by 1,2

--Looking at Total cases vs Total Deaths--
--it's multiplied by 100 because of the decimal places and 'as' was used because we want to create a new column 

select location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from mubarakdb..CovidDeaths$
where location like'%Nigeria%'
order by 1,2


--Looking at Total cases vs Population
--shows the population that got covid
select location, date,population, total_cases,(total_cases/population)*100 as PercentofPopulationInfected 
from mubarakdb..CovidDeaths$
--where location like'%Nigeria%'
order by 1,2

--Looking at countries with highest infection rate vs Population
--order by descending order 
select location,population, Max(total_cases) as HighestInfectionRate ,Max((total_cases/population))*100 as PercentofPopulationInfected 
from mubarakdb..CovidDeaths$
--where location like'%Nigeria%'
Group by Location, population
order by PercentofPopulationInfected desc

--showing countries with Higest Death Count per Population
-- casting into int was done because of the datatype conversion 
select Location, Max(cast(Total_deaths as int)) as TotalDeathCount
from mubarakdb..CovidDeaths$
--where location like'%Nigeria%'
where continent is not null
Group by Location
order by TotalDeathCount desc

--let break things down by continent 

select continent, Max(cast(Total_deaths as int)) as TotalDeathCount
from mubarakdb..CovidDeaths$
--where location like'%Nigeria%'
where continent is not null
Group by continent
order by TotalDeathCount desc

--Let's Break things down by Continent
--showing continents with the highest death count per population

select continent, Max(cast(Total_deaths as int)) as TotalDeathCount
from mubarakdb..CovidDeaths$
--where location like'%Nigeria%'
where continent is not null
Group by continent
order by TotalDeathCount desc

--Global Numbers

select date,sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths,
sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage 
from mubarakdb..CovidDeaths$
--where location like'%Nigeria%'
where continent is not null
Group by date
order by 1,2

--joining two table together, dea and vac are abbreaviations of death and vaccinations 
with PopvsVac (continent, location, date, population, New_vaccinations, rollingpeoplevaccinated) as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
as rollingpeoplevaccinated
--,(rollingpeoplevaccinated/population)*100
From mubarakdb..CovidDeaths$ dea
join mubarakdb..CovidVaccinations$ vac
    on dea.location = vac.location
    and dea.date = vac.date 
where dea.continent is not null
--order by 1,2
)


WITH PopvsVac AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS rollingpeoplevaccinated
    FROM 
        mubarakdb..CovidDeaths$ dea
    JOIN 
        mubarakdb..CovidVaccinations$ vac
        ON dea.location = vac.location
        AND dea.date = vac.date 
    WHERE 
        dea.continent IS NOT NULL
)
-- Move the ORDER BY clause here, after the CTE
SELECT *,(rollingpeoplevaccinated/population)*100
FROM PopvsVac
ORDER BY continent, location;


--Temp Table

-- Drop the temporary table if it exists, this is done because of any future alterations 
DROP TABLE IF EXISTS #percentagepopulationvaccinated;

-- Create the temporary table
CREATE TABLE #percentagepopulationvaccinated (
    continent NVARCHAR(255),
    location NVARCHAR(255),
    date DATETIME,
    population NUMERIC,
    new_vaccination NUMERIC,
    rollingpeoplevaccinated NUMERIC
);

-- Insert data into the temporary table
INSERT INTO #percentagepopulationvaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(NUMERIC, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS rollingpeoplevaccinated
FROM 
    mubarakdb..CovidDeaths$ dea
JOIN 
    mubarakdb..CovidVaccinations$ vac
    ON dea.location = vac.location
    AND dea.date = vac.date 
WHERE 
    dea.continent IS NOT NULL;

-- Select from the temporary table and calculate the percentage
SELECT 
    continent, 
    location, 
    date, 
    population, 
    new_vaccination, 
    rollingpeoplevaccinated,
    (rollingpeoplevaccinated / NULLIF(population, 0)) * 100 AS PercentagePopulationVaccinated
FROM 
    #percentagepopulationvaccinated
ORDER BY 
    continent, location;

-- creating view to store for later visualization 

create view percentagepopulationvaccinated as

SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(NUMERIC, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS rollingpeoplevaccinated
FROM 
    mubarakdb..CovidDeaths$ dea
JOIN 
    mubarakdb..CovidVaccinations$ vac
    ON dea.location = vac.location
    AND dea.date = vac.date 
WHERE 
    dea.continent IS NOT NULL;

