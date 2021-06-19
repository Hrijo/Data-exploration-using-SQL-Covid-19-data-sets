
--	Welcome to my SQL Exploratory Project !

-- I have downloaded the data used in this project from ourworldindata.org/coronavirus 


-- There are Five Parts to this project the

-- Part 1 has prelimanary querys for getting familiar with the data 
-- Part 2 demonstrates CTE's and Temp tables for more concentrated querys 
-- Part 3 demonstrates JOINS
-- Part 4 will demonstrate use of CASE statements
-- Part 5 Creating VIEWS for VISUALIZATION using Tableau, the visualisations and dashboards can be found in 
-- https://public.tableau.com/app/profile/hrishikesh5514/viz/Project_demo_dash/Dashboard1


------ Part 1 : General exploration -----

--DROP TABLE IF EXISTS Portfolio.dbo.Deaths
SELECT * 
FROM Deaths ;

SELECT * 
FROM Vaccinations ;

SELECT * 
FROM Hospitalisation ;

----- As the total_deaths column is of type nvarchar it has been cast as an Numeric Value -----

SELECT * ,
	cast(total_deaths as NUMERIC) as Totaldeaths
FROM Deaths
WHERE continent IS NOT NULL AND total_deaths IS NOT NULL  
ORDER BY Totaldeaths desc ;

--- Currently North America has the most deaths due to Covid-19 with 5,98,764 Deaths ---

SELECT * ,cast(total_deaths as Numeric) as Totaldeaths
FROM Deaths
WHERE location = 'India' 
	AND total_deaths IS NOT NULL
ORDER BY Totaldeaths DESC ;

--- As of 10-06-2021 India has 3,63,079 Deaths according to this data ---



--- Vaccinations info ---

SELECT * ,
	CAST(people_vaccinated as NUMERIC) as Vaccinated_People
FROM Vaccinations
WHERE continent IS NOT NULL 
	AND people_vaccinated IS NOT NULL
ORDER BY Vaccinated_People DESC ;



-- Finding out How many of people are vaccinated 

SELECT Location,
	population,total_cases,total_vaccinations,
	CAST(people_vaccinated as Numeric) as Vaccinated_People,
	CAST(people_vaccinated as Numeric)/population * 100 as PercentVaccinated
FROM Vaccinations
WHERE continent IS NOT NULL 
	AND people_vaccinated IS NOT NULL
ORDER BY 
	Vaccinated_People DESC ;



-- Percent Of People Vaccinated --

SELECT Location,
	population,
	total_cases,total_vaccinations, 
	CAST(people_vaccinated as Numeric) as Vaccinated_People, 
	CAST(people_vaccinated as Numeric)/population * 100 as PercentVaccinated
FROM Vaccinations
WHERE continent IS NOT NULL 
	AND people_vaccinated IS NOT NULL
ORDER BY PercentVaccinated DESC ;


--- Rolling Calculations for the sum of cases over time.

SELECT A.Date, 
	A.Total_patients_per_day ,
	SUM(A.Total_patients_per_day) over (order by A.Date ) as Cumulative_Patients
FROM
(
SELECT cast(date as date) as Date,  
	Sum(cast (icu_patients as Numeric)) as Total_patients_per_day	
From Hospitalisation
GROUP BY CAST(date AS DATE)
) A ;


--- Rolling Calculation for number of people Admitted throughout the pandemic

SELECT V.Date , 
	Admitted_people_per_day ,
	sum(V.Admitted_people_per_day) over (order by date) as Rolling_Sum
FROM 
(
SELECT CAST(date as DATE) as Date, sum((convert(Numeric,new_cases)) as Admitted_people_per_day
from Hospitalisation
group by date
) V ;




------ PART 2 : USING CTE's AND TEMP TABLES  ------ 
-- For the purpose of demonstration I have created the same query using a CTE and a TEMP TABLE


WITH MAXIMUM_VACCINATIONS --(location, MAXVACC) 
AS(
SELECT location, 
	MAX(CAST(people_vaccinated as Numeric)) OVER (PARTITION BY location) as MAXVACC
FROM Vaccinations
WHERE people_vaccinated IS NOT NULL 
	AND continent IS NOT NULL  
-- *** ORDER BY CANNOT BE USED IN A CTE *** 
)
SELECT * 
from MAXIMUM_VACCINATIONS
GROUP BY location, MAXVACC
ORDER BY MAXVACC DESC





--- TEMP TABLES ---

DROP TABLE IF EXISTS #MAXHOSPITALISATIONS
CREATE TABLE #MAXHOSPITALISATIONS 
( 
	Location nvarchar(255),
	MaxPeopleVaccinated NUMERIC
)

--SELECT * FROM #MAXHOSPITALISATIONS

INSERT INTO #MAXHOSPITALISATIONS
SELECT location, 
	MAX(CAST(people_vaccinated as Numeric)) OVER (PARTITION BY location) as MAXVACC
FROM Vaccinations
WHERE people_vaccinated IS NOT NULL 
	AND continent IS NOT NULL  
--Order by location

SELECT * FROM #MAXHOSPITALISATIONS
Group by location , MaxPeopleVaccinated
Order by MaxPeopleVaccinated DESC





----- PART 3 : Demonstrating Joins -----


SELECT CAST( D.date AS DATE) AS Date, D.[continent],D.[location],D.[population],D.[total_cases],D.[new_cases],
	V.[stringency_index],
	H.[icu_patients],H.[hosp_patients]
From Deaths D
JOIN Vaccinations V
ON D.date = V.date
	AND D.[continent]= V.[continent] 
	AND D.[location] = V.[location]

JOIN Hospitalisation H
ON V.date = H.date
	AND V.[continent] = H.continent
	AND V.[location] = H.location
--WHERE D.continent is not null
ORDER BY H.location, Date


-- The above query can also be written as


SELECT CAST( D.date AS DATE) AS Date, D.[continent],D.[location],D.[population],D.[total_cases],D.[new_cases],
	V.[stringency_index],V.[people_vaccinated],
	H.[total_tests]
From Deaths D
JOIN Vaccinations V
ON D.date = V.date
--	AND D.[continent]= V.[continent] 
	AND D.[location] = V.[location]

JOIN Hospitalisation H
ON V.date = H.date
--	AND V.[continent] = H.continent
	AND V.[location] = H.location
WHERE D.continent IS NOT NULL
ORDER BY H.location, Date





----- Creating a temp table to Calculate various insites -----

DROP TABLE IF EXISTS #CALTABLE
CREATE TABLE #CALTABLE 
(
	Date DATE,
	Continent NVARCHAR(255) ,
	Location NVARCHAR(255) ,
	Population NUMERIC,
	Total_Cases Numeric, 
	New_Cases Numeric, 
	New_Deaths Numeric,
	Stringency_Index Float,
	People_Vaccinated NUMERIC
) ;



INSERT INTO #CALTABLE
SELECT CAST( D.date AS DATE) AS Date, D.[continent] AS Continent,D.[location] AS Location,
	D.[population] As Population,D.[total_cases] AS Total_Cases,D.[new_cases] AS New_Cases,
	D.[new_deaths] AS New_Deaths,
	V.[stringency_index] AS Stringency_Index ,V.[people_vaccinated] AS People_Vaccinated
	
From Deaths D
JOIN Vaccinations V
ON D.date = V.date
	AND D.[continent]= V.[continent] 
	AND D.[location] = V.[location] ;





--- REVIEWING THE TABLE ---

SELECT * FROM #CALTABLE
ORDER BY Location, Date





----- PART 4 :  CALCULATED FIELDS AND CASE STATEMENTS -----

SELECT Continent,Location,
	--MAX(total_vaccinations) as People_Vaccinated,Population, 
	MAX(People_Vaccinated)/Population * 100 as Percent_Vaccinated,
	CASE 
		WHEN MAX(People_Vaccinated)/Population * 100 IS NULL THEN 'NOT ENOUGH VACCINATIONS'
		WHEN MAX(People_Vaccinated)/Population * 100 < 40 THEN 'NOT ENOUGH VACCINATIONS'		
		ELSE 'THE VACCINATIONS ARE GOING GOOD' 
	END 
	AS Vaccination_Status
FROM
#CALTABLE
GROUP BY  Location, Continent ,Population
--HAVING MAX(total_vaccinations)/Population * 100 < 40
ORDER BY  Percent_Vaccinated ;

--- This Data has total 229 Distinct locations out of which 7 are continents ---
--- 2 locations are given the names World and International ---




--- Part 5 : CREATING And DELETING Views ---
--- At the time of creating these calculation the data on stringency_index for evey country was not available,
--- So I selected 30th of May For my visualisation
--- BELOW IS THE COMMAND TO FIND STRINGENCY_INDEX FOR MAX DATE



SELECT date, location , stringency_index
FROM Vaccinations
WHERE 
	date = 
	(
		SELECT MAX(date)  
		FROM Vaccinations
			
    ) 
AND stringency_index is not null





DROP VIEW IF EXISTS STRINGENY_DATA

CREATE VIEW 
STRINGENY_DATA AS
(
SELECT CAST(date AS DATE) AS Date,location,stringency_index 
FROM Vaccinations
WHERE  CAST(date AS DATE) like '2021-05-31'
)





DROP VIEW IF EXISTS Vaccinated_People

CREATE VIEW
Vaccinated_People AS 
(

SELECT SUM (CONVERT(Numeric,M)) as VACCINATIONS_COUNT
FROM
(
SELECT MAX((convert(Numeric,people_vaccinated)) as M,location
FROM Vaccinations
GROUP BY location
) V

)

--SELECT * FROM Vaccinated_People





DROP VIEW IF EXISTS Total_Deaths

CREATE VIEW 
Total_Deaths As
(
SELECT SUM(convert(Numeric,MAXIMUM_DEATHS)) AS Death_Count
FROM(
SELECT MAX((convert(Numeric,total_deaths)) As MAXIMUM_DEATHS,location
FROM Deaths
GROUP BY location) D
)


