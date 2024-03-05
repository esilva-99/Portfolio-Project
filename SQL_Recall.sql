--Vehicle Recall Data Exploration Project.
--Skills Used: Window Functions, Aggregate Functions, CTEs, Converting Data Types, and CASE expressions.


USE Project1
select *
from dbo.recall
order by Report_Received_Date ASC

--Is NHTSA_ID a unique ID?
SELECT COUNT(DISTINCT NHTSA_ID), count(NHTSA_ID)
FROM dbo.Recall

--Converting report received date
ALTER TABLE  dbo.recall
ADD report_received_date_converted DATE;

UPDATE dbo.Recall
SET report_received_date_converted = CONVERT(DATE, report_received_date)



-- Check all the dates are there
SELECT report_received_date, report_received_date_converted
from dbo.Recall


--Extract year from date
SELECT YEAR(report_received_date_converted)
FROM DBO.recall


--How many vehicle recalls from each manufacture have a 'do not drive advirosry' per year?
SELECT do_not_drive_advisory AS do_not_drive,  
	   manufacturer, 
	   YEAR(report_received_date_converted) AS year_report_received, 
	   COUNT(do_not_drive_advisory)  AS number_of_recalls
FROM project1.dbo.recall
WHERE do_not_drive_advisory LIKE 'yes' AND recall_type = 'vehicle'
GROUP BY  do_not_drive_advisory, manufacturer, YEAR(report_received_date_converted)
ORDER BY manufacturer, year_report_received ASC

--Which car manufacturer has the highest number of vehicle recalls in the last 5 years (2017-2022)?

WITH CTE AS (SELECT  *, ROW_NUMBER() OVER(PARTITION BY manufacturer, number_of_recalls ORDER BY manufacturer) AS number
FROM (SELECT YEAR(report_received_date_converted) AS year_report_received, manufacturer, recall_type,
			COUNT(*) OVER(PARTITION BY manufacturer) AS number_of_recalls
	FROM dbo.recall
	WHERE YEAR(report_received_date_converted) IN ('2017','2018','2019','2020','2021','2022') AND recall_type='vehicle') AS tab
)

SELECT manufacturer, recall_type,number_of_recalls
FROM CTE
WHERE number=1
ORDER BY number_of_recalls DESC

-- What is the top problem with cars from each manufacturer?
WITH CTE AS (

SELECT manufacturer, recall_type, component, COUNT(component) AS number_of_recalls, DENSE_RANK() OVER(PARTITION BY manufacturer order by COUNT(component) DESC) AS rank
FROM dbo.Recall
WHERE recall_type LIKE 'vehicle'
 GROUP BY manufacturer, recall_type, component
 
 )

 SELECT Manufacturer, Recall_Type, Component, number_of_recalls
 FROM CTE
 WHERE rank =1
 ORDER BY number_of_recalls DESC

 --What are the number of recalls for each component across the years?

 SELECT manufacturer, recall_type, component,YEAR(report_received_date_converted) AS year, COUNT(component) AS number_of_recalls
 FROM dbo.Recall
 WHERE recall_type LIKE 'vehicle' AND YEAR(report_received_date_converted) IN ('2017','2018','2019','2020','2021','2022')
 GROUP BY manufacturer, recall_type, component, YEAR(report_received_date_converted)
 ORDER BY Manufacturer, year, number_of_recalls DESC

 --What component has been recalled the most in the last 5 years across all manufacturers?
SELECT component, COUNT(component) AS number_of_recalls
FROM dbo.recall
WHERE YEAR(report_received_date_converted) IN ('2017','2018','2019','2020','2021','2022') AND recall_type='vehicle'
GROUP BY component
ORDER BY COUNT(component) DESC


 --Which manufacturer has the highest number of vehicles affected by a 'do not drive' advisory recalls in the last 5 years?
SELECT    
	   manufacturer,  
	   SUM(potentially_affected) AS affected_vehicles
FROM dbo.recall
WHERE do_not_drive_advisory LIKE 'yes' AND recall_type = 'vehicle' AND YEAR(report_received_date_converted)> '2017'
GROUP BY  manufacturer
ORDER BY affected_vehicles DESC


-- What percentage of each manufacturer's recalls have a do 'do not drive advisory'?

WITH CTE AS (
SELECT manufacturer, 
	   SUM(CASE WHEN do_not_drive_advisory LIKE 'yes'THEN 1 
			ELSE 0 END)  AS count_no_drive,
	   SUM(CASE WHEN do_not_drive_advisory LIKE 'no' then 1
			ELSE 0 END) AS count_yes_drive,
	   COUNT( NHTSA_ID) AS total
FROM dbo.recall 
group by Manufacturer
HAVING SUM(CASE WHEN do_not_drive_advisory LIKE 'yes'THEN 1 
			ELSE 0 END)>0
)
SELECT  manufacturer, 
	    (100*(CAST(count_no_drive AS float)/CAST(total AS float))) AS percent_do_not_drive
FROM CTE
WHERE  100*(CAST(count_no_drive AS float)/CAST(total AS float))> 0 
ORDER BY percent_do_not_drive DESC
