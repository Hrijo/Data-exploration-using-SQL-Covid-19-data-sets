### Hi, This is a data exploration project. The data used was downloaded from Our WorldinData.org 
### This project intends to demonstrate basic understanding of SQL syntax, in the readme file you can find the key highlights. Please view the SQL_Sripts file for the complete script

--Calculated Fields

SELECT Location,
	population,total_cases,total_vaccinations,
	CAST(people_vaccinated as Numeric) as Vaccinated_People,
	CAST(people_vaccinated as Numeric)/population * 100 as PercentVaccinated
FROM Vaccinations
WHERE continent IS NOT NULL 
	AND people_vaccinated IS NOT NULL
ORDER BY 
	Vaccinated_People DESC ;

--Window Functions

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


-- Rolling Sums

SELECT V.Date , 
	Admitted_people_per_day ,
	sum(V.Admitted_people_per_day) over (order by date) as Rolling_Sum
FROM 
(
SELECT CAST(date as DATE) as Date, sum((convert(Numeric,new_cases)) as Admitted_people_per_day
from Hospitalisation
group by date
) V ;

--CTE

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


-- Temp Tables

DROP TABLE IF EXISTS #MAXHOSPITALISATIONS
CREATE TABLE #MAXHOSPITALISATIONS 
( 
	Location nvarchar(255),
	MaxPeopleVaccinated NUMERIC
)

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


-- Joins

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


-- Case statements

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
