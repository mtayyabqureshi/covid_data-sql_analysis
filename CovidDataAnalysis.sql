/*
Covid 19 Data Exploration 
Data Set Used: https://ourworldindata.org/covid-deaths
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

Select *
FROM CovidDeaths
WHERE continent IS NOT NULL
Order By 1,2


Select continent,location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL
Order By 1,2


-- Total Cases vs Total Deaths
-- Shows what percentage of population infected with Covid

Select continent, location, date, total_cases, total_deaths, ((total_deaths  /CAST (total_cases AS float)) * 100) AS DeathPercentage
FROM CovidDeaths
WHERE location like '%pakistan%' 
AND continent IS NOT NULL
Order By 1,2


-- Total Cases vs Population
-- Population percentage that got covid
Select continent,location, date,population, total_cases, total_cases / population *100  AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
Order By 1,2


-- Country with highest infection rate compared to population

Select  continent, location ,population,MAX(total_cases) AS HighestInfectionCount,MAX(total_cases / population *100)  AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent,location,population
Order By PercentPopulationInfected DESC


-- Countries with highest death count per population

Select continent, location ,MAX(CAST(total_deaths AS int)) AS TotalDeathCount 
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent,location
Order By TotalDeathCount desc


-- Continent with highest death count per population

Select continent ,MAX(CAST(total_deaths AS int)) AS TotalDeathCount 
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
Order By TotalDeathCount desc


--- Global Numbers


Select SUM(new_cases), SUM (new_deaths), 
Case When SUM(new_cases) = 0 THEN NULL
ELSE (SUM(new_deaths) /SUM (new_cases) * 100)  
END AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
Order By 1,2


-- Yearly total cases and total deaths
Select Year(date) AS CovidYear,MaX(total_cases) AS TotalCases, MAX(CAST(total_deaths AS int)) AS TotalDeathCount 
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Year(date)


-- Total population vs vaccination
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.population, vac.new_vaccinations
FROM CovidDeaths AS dea
Join CovidVaccinations AS vac
	On dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
Order by 1,2,3


Select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition By dea.location Order By dea.location, dea.date) AS RollingPeoleVaccinated
FROM CovidDeaths AS dea
Join CovidVaccinations AS vac
	On dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
Order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopVsVac (Continent, Location, Date, Population, New_Vaccination,RollingPeoleVaccinated) 
AS 
(
	Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition By dea.location Order By dea.location, dea.date ) AS RollingPeoleVaccinated
	FROM CovidDeaths AS dea
	Join CovidVaccinations AS vac
		On dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
)
Select *, (RollingPeoleVaccinated/Population) *100
FROM PopVsVac
Order by 2,3


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationCaccinated
Create Table #PercentPopulationCaccinated
(Continent nvarchar(255), Location nvarchar(255), Date datetime, 
	Population numeric, New_Vaccination numeric,RollingPeoleVaccinated numeric
)

Insert into #PercentPopulationCaccinated
	Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition By dea.location Order By dea.location, dea.date ) AS RollingPeoleVaccinated
	FROM CovidDeaths AS dea
	Join CovidVaccinations AS vac
		On dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL

Select *, (RollingPeoleVaccinated/Population) *100
FROM #PercentPopulationCaccinated
Order by 2,3


-- Creating View to store data for later visualization purposes

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

