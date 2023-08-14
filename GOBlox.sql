-- Checking for duplicates

SELECT uid, dt, spent FROM activity
WHERE uid IN (SELECT uid FROM(SELECT DISTINCT (uid), COUNT(dt) 
FROM activity
GROUP by uid
HAVING COUNT(dt)>1
) As base);


-- How many users were in the control and treatment groups?

SELECT
SUM(CASE WHEN groups.group like 'A' THEN 1 ELSE 0 END) AS GroupA,
SUM(CASE WHEN groups.group like 'B' THEN 1 ELSE 0 END) AS GroupB
FROM groups;

-- What was the conversion rate of all users?

SELECT
round(100*count(distinct(activity.uid))*1.0/count(distinct(groups.uid)),2) ||'%'
From groups
LEFT JOIN activity ON groups.uid=activity.uid;


-- What is the user conversion rate for the control and treatment groups?

SELECT
ROUND(100*COUNT(DISTINCT(activity.uid)) FILTER (WHERE groups.group = 'A')*1.0/Count(groups.uid)FILTER (WHERE groups.group = 'A'),2) || '%' as conv_rt_A,
ROUND(100*COUNT(DISTINCT(activity.uid)) FILTER (WHERE groups.group = 'B')*1.0/Count(groups.uid)FILTER (WHERE groups.group = 'B'),2) || '%' as conv_rt_B
FROM groups
LEFT JOIN activity ON groups.uid=activity.uid;

-- What is the average amount spent per user for the control and treatment groups, including users who did not convert?

SELECT groups.group, SUM(activity.spent)/ Count(DISTINCT(groups.uid)) as avg_spnt
FROM groups
LEFT JOIN activity ON groups.uid=activity.uid 
GROUP BY groups.group;

-- Prepare CSV file to export for Vizualization in Tableau



WITH stats AS 
(SELECT DISTINCT(activity.uid), SUM(spent) AS expend, COUNT(DISTINCT(spent)) AS conver
  		FROM activity
  		GROUP BY activity.uid),
  
  diff_date AS 
(SELECT activity.uid, MIN(dt)-join_dt AS diff_days FROM activity
    		LEFT JOIN "groups" ON activity.uid = groups.uid
    		GROUP BY activity.uid,join_dt)
    
    
SELECT 	DISTINCT(id)  ,country,gender,groups.group, groups.device, join_dt, 
COALESCE(diff_days,0) AS days_diff, cOALESCE(expend,0) AS spent,
 		CASE WHEN conver>0 THEN 1 ELSE 0 END AS  converted,
CASE WHEN diff_days > 0 OR expend IS null THEN 0 ELSE 1 END AS novelty
 
 FROM users
 
 LEFT JOIN "groups" ON users.id = groups.uid
 LEFT JOIN stats ON users.id = stats.uid
 LEFT JOIN diff_date ON users.id = diff_date.uid
