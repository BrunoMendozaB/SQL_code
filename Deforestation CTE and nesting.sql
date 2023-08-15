-- Pre planning
CREATE VIEW forestation AS
	SELECT fa.country_code, fa.country_name, fa.year, fa.forest_area_sqkm, la.total_area_sq_mi,r.region, r.income_group, forest_area_sqkm*100/(total_area_sq_mi*2.59) AS frst_percent
	FROM forest_area AS fa
	INNER JOIN land_area AS la ON fa.country_code = la.country_code AND fa.year = la.year
	INNER JOIN regions As r	ON fa.country_code = r.country_code
--Gives us 5886 records, many records have missing values on the forest_area_sqkm field. 

CREATE VIEW forestation AS
SELECT fa.country_code, fa.country_name, fa.year, fa.forest_area_sqkm, la.total_area_sq_mi,r.region, r.income_group, forest_area_sqkm*100/(total_area_sq_mi*2.59) AS frst_percent
FROM forest_area AS fa
INNER JOIN land_area AS la
ON fa.country_code = la.country_code AND fa.year = la.year
INNER JOIN regions As r	ON fa.country_code = r.country_code
WHERE forest_area_sqkm IS NOT NULL
--Gives us 5570 records, 

-- 1. GLOBAL SITUATION

SELECT forest_area_sqkm
 FROM forestation
WHERE region = 'World' and year = 2016

SELECT forest_area_sqkm
FROM forestation
WHERE region = 'World' and year = 1990

-- Difference of sq km between 1990 and 2016
SELECT 	sum(CASE WHEN year = 1990 THEN forest_area_sqkm WHEN year = 2016 THEN forest_area_sqkm * -1	ELSE 0	END)/
	sum( CASE WHEN year = 1990	THEN forest_area_sqkm ELSE 0 END)
FROM forestation
WHERE region = 'World'

-- Which country equals the area lost
SELECT country_name, total_area_sq_mi*2.59
FROM forestation
WHERE year = 2016 AND total_area_sq_mi*2.59 between 1200000 and 1300000

--2. REGIONAL OUTLOOK

-- Percentage of world forestation
SELECT sum(forest_area_sqkm)*100/sum(total_area_sq_mi*2.59) as perc_forest
FROM forestat_corr
WHERE year = 1990


--Percentage of forestation group by region
SELECT region, sum(forest_area_sqkm)*100/sum(total_area_sq_mi*2.59) AS perc_forest
FROM forestation
WHERE year = 1990
GROUP BY region
ORDER BY perc_forest 


--Totals by region (SELF JOIN)
SELECT f.region, sum(f.forest_area_sqkm)*100/sum(f.total_area_sq_mi*2.59) AS perc_forest90, sum(f2.forest_area_sqkm)*100/sum(f2.total_area_sq_mi*2.59) AS perc_forest16
FROM forestat_corr f
INNER JOIN forestat_corr f2 ON f.country_name = f2.country_name
WHERE f.year = 1990 and f2.year =2016
GROUP BY f.region

--To  select the regions that have diminished its forest area, we add the following clause:
--WHERE perc_forest90> perc_forest16

--3. COUNTRY-LEVEL DETAIL

--Differences, ranking in deforestation

WITH noventas AS
	(SELECT country_name,region, forest_area_sqkm as fa90
	FROM forestat_corr
	WHERE year = 1990),

    dieciseis AS
	(SELECT country_name,region, forest_area_sqkm as fa16
	FROM forestat_corr
	WHERE year = 2016)

SELECT noventas.country_name, noventas.region,fa90-fa16 AS diff
FROM noventas
INNER JOIN dieciseis ON noventas.country_name = dieciseis.country_name
ORDER BY diff

-- Diferrence as percentage by country

WITH noventas AS
	(SELECT country_name, sum(forest_area_sqkm)*100/sum(total_area_sq_mi*2.59) AS perc_forest90
	FROM forestation
	WHERE year = 1990
	GROUP BY country_name),

dieciseis AS
	(SELECT country_name, sum(forest_area_sqkm)*100/sum(total_area_sq_mi*2.59) as perc_forest16
	FROM forestation
	WHERE year = 2016
	GROUP BY country_name)

SELECT noventas.country_name, perc_forest90, perc_forest16, perc_forest90-perc_forest16 AS diff
FROM noventas
INNER JOIN dieciseis ON noventas.country_name = dieciseis.country_name
ORDER BY diff



WITH noventas AS
	(SELECT country_name,region, forest_area_sqkm as fa90
	FROM forestat_corr
	WHERE year = 1990),
dieciseis AS
	(SELECT country_name,region, forest_area_sqkm as fa16
	FROM forestat_corr
	WHERE year = 2016)

SELECT noventas.country_name, fa16, fa90, (fa16-fa90)/fa90*100 AS diff
FROM noventas
INNER JOIN dieciseis ON noventas.country_name = dieciseis.country_name
ORDER BY diff desc


-- Quartiles
SELECT quart, count(*)
FROM (
	WITH db1 AS (
		SELECT f.country_name, forest_area_sqkm as forarea, total_area_sq_mi*2.59 AS  totarea,
		forest_area_sqkm*100/(total_area_sq_mi*2.59) AS perc_forest
		FROM forestat_corr f
		WHERE year = 2016
		GROUP BY country_name,forest_area_sqkm,total_area_sq_mi
  	HAVING forest_area_sqkm*100/(total_area_sq_mi*2.59)<>0),

	db2 AS
		(SELECT max(perc_forest) AS maxi, min(perc_forest) AS mini
		FROM db1)

	SELECT db1.country_name,perc_forest,
	CASE	WHEN perc_forest<=(sum(maxi)-sum(mini))/4 THEN 1 
		WHEN perc_forest<=2*(sum(maxi)-sum(mini))/4 THEN 2 
		WHEN perc_forest<=3*(sum(maxi)-sum(mini))/4 THEN 3        
		WHEN perc_forest>3*(sum(maxi)-sum(mini))/4 THEN 4 END AS quart                              
	FROM db1,db2
	GROUP BY db1.country_name,db1.perc_forest) AS db3
GROUP BY quart
ORDER BY quart

--Countries in the fourth  quartile

WITH db1 AS (
	SELECT f.country_name, region, forest_area_sqkm AS forarea, total_area_sq_mi*2.59 AS  totarea, forest_area_sqkm*100/(total_area_sq_mi*2.59) AS perc_forest
	FROM forestat_corr f
	WHERE year = 2016
	GROUP BY country_name,region,forest_area_sqkm,total_area_sq_mi
  	HAVING forest_area_sqkm*100/(total_area_sq_mi*2.59)<>0),

db2 AS (
	SELECT max(perc_forest)AS maxi,min(perc_forest) AS mini
	FROM db1)

SELECT  country_name,region,perc_forest
FROM(
	SELECT db1.country_name,perc_forest,region,
		CASE WHEN perc_forest<=(sum(maxi)-sum(mini))/4 THEN 1 
		WHEN perc_forest<=2*(sum(maxi)-sum(mini))/4 THEN 2 
		WHEN perc_forest<=3*(sum(maxi)-sum(mini))/4 THEN 3        
		WHEN perc_forest>3*(sum(maxi)-sum(mini))/4 THEN 4 END AS quart
        FROM db1,db2
	GROUP BY db1.country_name,db1.perc_forest,region) AS db4
WHERE quart = 4 
ORDER BY perc_forest desc
