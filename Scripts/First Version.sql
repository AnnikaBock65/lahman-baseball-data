-- 1. What range of years for baseball games played does the provided database cover? 1933 - 2016.

SELECT DISTINCT (yearid)
FROM allstarfull
ORDER BY yearid DESC;

-- 2. Find the name and height of the shortest player in the database. 
-- How many games did he play in? What is the name of the team for which he played?


SELECT playerid, namefirst, namelast, namegiven, height
FROM people
ORDER BY height ASC;

SELECT MIN(height)
FROM people;

SELECT playerid, namefirst, namelast, namegiven, height
FROM people
ORDER BY height ASC;


--4. Using the fielding table, group players into three groups based on their position: 
-- label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", 
--and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.


SELECT *
FROM fielding;


SELECT SUM(po),
		CASE 
		WHEN CAST(pos AS text)= 'OF' THEN 'Outfield'
		WHEN CAST(pos AS text) = 'SS' OR CAST(pos AS text) = '1B' OR CAST(pos AS text) = '2B' OR CAST(pos AS text)= '3B' THEN 'Infield'
		WHEN CAST(pos AS text)= 'P' OR CAST(pos AS text) ='C' THEN 'Battery' END as pos_category
FROM fielding
WHERE yearID = '2016'
GROUP BY pos_category;

---------------------------------

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 
-- (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. 
-- Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.


SELECT * 
FROM homegames;

SELECT *
FROM parks;

SELECT *
FROM teams;

---------------------- LEFT JOIN homesgames with parks with park as ID + LEFT JOIN teams with team = teamid

SELECT *
FROM homegames LEFT JOIN parks ON homegames.park = parks.park
LEFT JOIN teams ON homegames.team = teams.teamid;

----------------------

-- TOP 5:


WITH avg_attendance_per_team AS (SELECT DISTINCT (team), ROUND((AVG(attendance)/COUNT(games)), 2) AS avg_att_per_team_per_game
			 					FROM homegames
								GROUP BY team),								
avg_attendance_per_park AS (SELECT DISTINCT (park), team, ROUND((AVG(attendance)/COUNT(games)), 2) AS avg_att_per_park_per_game
								FROM homegames
								GROUP BY park, team)
							    
								
SELECT DISTINCT(t.teamid), t.name AS team_name, hg.attendance, hg.games, avg_att_per_team_per_game, avg_att_per_park_per_game, hg.year, hg.park, p.park_name
FROM homegames as hg
	LEFT JOIN parks as p
	ON hg.park = p.park
	LEFT JOIN teams as t
	ON hg.team = t.teamid
	INNER JOIN avg_attendance_per_team as avgpt
	ON avgpt.team = hg.team
	INNER JOIN avg_attendance_per_park as avgpp
	ON avgpp.team = hg.team
WHERE hg.year = '2016'
AND hg.games >= 10
ORDER BY avg_att_per_team_per_game DESC, avg_att_per_park_per_game DESC
LIMIT 5;



-- Lowest 5:

WITH avg_attendance_per_team AS (SELECT DISTINCT (team), ROUND((AVG(attendance)/COUNT(games)), 2) AS avg_att_per_team_per_game
			 					FROM homegames
								GROUP BY team),								
avg_attendance_per_park AS (SELECT DISTINCT (park), team, ROUND((AVG(attendance)/COUNT(games)), 2) AS avg_att_per_park_per_game
								FROM homegames
								GROUP BY park, team)
							    
								
SELECT DISTINCT(t.teamid), t.name AS team_name, hg.attendance, hg.games, avg_att_per_team_per_game, avg_att_per_park_per_game, hg.year, hg.park, p.park_name
FROM homegames as hg
	LEFT JOIN parks as p
	ON hg.park = p.park
	LEFT JOIN teams as t
	ON hg.team = t.teamid
	INNER JOIN avg_attendance_per_team as avgpt
	ON avgpt.team = hg.team
	INNER JOIN avg_attendance_per_park as avgpp
	ON avgpp.team = hg.team
WHERE hg.year = '2016'
AND hg.games >= 10
ORDER BY avg_att_per_team_per_game ASC, avg_att_per_park_per_game ASC
LIMIT 5;





