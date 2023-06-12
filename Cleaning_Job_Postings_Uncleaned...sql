--Cleaning Process
SELECT *
FROM PersonalTutorial.dbo.Job_Postings_Uncleaned

--Dropping the 'index' column
ALTER TABLE Job_Postings_Uncleaned
DROP COLUMN [index]

--Renaming columns
EXEC sp_rename "Job_Postings_Uncleaned.Job Title", "Job_Title"
EXEC sp_rename "Job_Postings_Uncleaned.Salary Estimate", "Salary_Estimate"
EXEC sp_rename "Job_Postings_Uncleaned.Job Description", "Job_Description"
EXEC sp_rename "Job_Postings_Uncleaned.Company Name", "Company_Name"
EXEC sp_rename "Job_Postings_Uncleaned.Type of Ownership", "Type_of_Ownership"
GO

--Trimming the dollar signs and the letter 'K' from the Salary_Estimate column
UPDATE PersonalTutorial.dbo.Job_Postings_Uncleaned
SET Salary_Estimate = REPLACE (Salary_Estimate, '$', '')

UPDATE PersonalTutorial.dbo.Job_Postings_Uncleaned
SET Salary_Estimate = REPLACE (Salary_Estimate, 'K', '')


--Removing the ()
SELECT Salary_Estimate,
SUBSTRING(Salary_Estimate, 1, 7) AS Salary_Estimate_New
FROM PersonalTutorial.dbo.Job_Postings_Uncleaned

--OR 
SELECT 
	LEFT(Salary_Estimate, CHARINDEX('(', Salary_Estimate)-1) AS Salary_Estimate_New 
FROM PersonalTutorial.dbo.Job_Postings_Uncleaned

--OR
SELECT 
SUBSTRING(Salary_Estimate, 1, CHARINDEX('(', Salary_Estimate) -1) AS Salary_Estimate_New
FROM PersonalTutorial.dbo.Job_Postings_Uncleaned


--Adding the new column to the table
ALTER TABLE PersonalTutorial.dbo.Job_Postings_Uncleaned
ADD Salary_Estimate_New NVARCHAR(255)

UPDATE PersonalTutorial.dbo.Job_Postings_Uncleaned
SET Salary_Estimate_New = SUBSTRING(Salary_Estimate, 1, CHARINDEX('(', Salary_Estimate) -1)
WHERE CHARINDEX('(', Salary_Estimate) > 0


--Trimming the space in Salary
UPDATE PersonalTutorial.dbo.Job_Postings_Uncleaned
SET
Salary_Estimate_New = RTRIM(Salary_Estimate_New)


--Dropping the old Salary_Estimate column
ALTER TABLE PersonalTutorial.dbo.Job_Postings_Uncleaned
DROP COLUMN Salary_Estimate


--Removing duplicates ((Put Salary_Estimate))
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER () OVER (
		PARTITION BY Job_Description,			
				Company_Name,
				Salary_Estimate,
				Location,
				Headquarters
				ORDER BY Job_Description, Company_Name, Salary_Estimate
				) row_num
			FROM PersonalTutorial.dbo.Job_Postings_Uncleaned
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY Job_Description, Company_Name, Salary_Estimate

DELETE FROM RowNumCTE
WHERE row_num > 1


--Removing the numbers from the Company Name
SELECT REVERSE(SUBSTRING(REVERSE(Company_Name), PATINDEX('%[0-9]%', REVERSE(Company_Name)) + 4,
LEN(Company_Name)-PATINDEX('%[0-9]%', REVERSE(Company_Name)))) AS Company_Name_New
FROM PersonalTutorial.dbo.Job_Postings_Uncleaned

--Adding the new column to the table
ALTER TABLE PersonalTutorial.dbo.Job_Postings_Uncleaned
ADD Company_Name_New NVARCHAR(255)

UPDATE PersonalTutorial.dbo.Job_Postings_Uncleaned
SET Company_Name_New = REVERSE(SUBSTRING(REVERSE(Company_Name), PATINDEX('%[0-9]%', REVERSE(Company_Name)) + 4,
LEN(Company_Name)-PATINDEX('%[0-9]%', REVERSE(Company_Name))))

ALTER TABLE PersonalTutorial.dbo.Job_Postings_Uncleaned
DROP COLUMN Company_Name


--Breaking out the Location and Headquarters Address into different columns
SELECT Location
FROM PersonalTutorial.dbo.Job_Postings_Uncleaned

SELECT 
SUBSTRING(Location, 1, CHARINDEX(',', Location) - 1) as Location_City
, SUBSTRING(Location, CHARINDEX(',', Location) + 1, LEN(Location)) as Location_State
FROM PersonalTutorial.dbo.Job_Postings_Uncleaned
WHERE Location LIKE '%,%'


ALTER TABLE PersonalTutorial.dbo.Job_Postings_Uncleaned
ADD Location_City NVARCHAR(255)

UPDATE PersonalTutorial.dbo.Job_Postings_Uncleaned
SET Location_City = SUBSTRING(Location, 1, CHARINDEX(',', Location) - 1)
WHERE Location LIKE '%,%'

ALTER TABLE PersonalTutorial.dbo.Job_Postings_Uncleaned
ADD Location_State NVARCHAR(255)

UPDATE PersonalTutorial.dbo.Job_Postings_Uncleaned
SET Location_State = SUBSTRING(Location, CHARINDEX(',', Location) + 1, LEN(Location))
WHERE Location LIKE '%,%'


SELECT Headquarters
FROM PersonalTutorial.dbo.Job_Postings_Uncleaned

SELECT 
SUBSTRING(Headquarters, 1, CHARINDEX(',', Headquarters) - 1) as Headquarters_City
, SUBSTRING(Headquarters, CHARINDEX(',', Headquarters) + 1, LEN(Headquarters)) as Headquarters_State
FROM PersonalTutorial.dbo.Job_Postings_Uncleaned
WHERE Headquarters LIKE '%,%'

ALTER TABLE PersonalTutorial.dbo.Job_Postings_Uncleaned
ADD Headquarters_City NVARCHAR(255)

UPDATE PersonalTutorial.dbo.Job_Postings_Uncleaned
SET Headquarters_City = SUBSTRING(Headquarters, 1, CHARINDEX(',', Headquarters) - 1)
WHERE Headquarters LIKE '%,%'


--Populating and Replacing NULL values
SELECT *
FROM PersonalTutorial.dbo.Job_Postings_Uncleaned
WHERE Location_City IS NULL
ORDER BY Location

SELECT j.Location, j.Location_City, p.Location, p.Location_City, ISNULL (j.Location_City, p.Location_City)
FROM PersonalTutorial.dbo.Job_Postings_Uncleaned j
	JOIN PersonalTutorial.dbo.Job_Postings_Uncleaned p
	ON j.Location = p.Location 
	AND j.Company_Name_New <> p.Company_Name_New
WHERE j.Location_City IS NULL


UPDATE j
SET Location_City = ISNULL (j.Location, p.Location)
FROM PersonalTutorial.dbo.Job_Postings_Uncleaned j
	JOIN PersonalTutorial.dbo.Job_Postings_Uncleaned p
	ON j.Location = p.Location 
	AND j.Company_Name_New <> p.Company_Name_New
WHERE j.Location_City IS NULL


SELECT *
FROM PersonalTutorial.dbo.Job_Postings_Uncleaned
WHERE Location_State IS NULL
ORDER BY Location

SELECT j.Location, j.Location_State, p.Location, p.Location_State, ISNULL (j.Location_State, p.Location_State)
FROM PersonalTutorial.dbo.Job_Postings_Uncleaned j
	JOIN PersonalTutorial.dbo.Job_Postings_Uncleaned p
	ON j.Location = p.Location 
	AND j.Company_Name_New <> p.Company_Name_New
WHERE j.Location_State IS NULL


UPDATE j
SET Location_State = ISNULL (j.Location, p.Location)
FROM PersonalTutorial.dbo.Job_Postings_Uncleaned j
	JOIN PersonalTutorial.dbo.Job_Postings_Uncleaned p
	ON j.Location = p.Location 
	AND j.Company_Name_New <> p.Company_Name_New
WHERE j.Location_State IS NULL


--Changing '-1's to NULL values in the 'Founded' Column
UPDATE PersonalTutorial.dbo.Job_Postings_Uncleaned
SET Founded = NULL WHERE Founded = -1


--Dropping unused columns
ALTER TABLE PersonalTutorial.dbo.Job_Postings_Uncleaned
DROP COLUMN Location, Rating, Revenue, Competitors 