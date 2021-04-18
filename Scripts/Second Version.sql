-- 1. What range of years for baseball games played does the provided database cover? 1933 - 2016.

SELECT DISTINCT (yearid)
FROM allstarfull
ORDER BY yearid DESC;

-----------

select min(yearid), max(yearid)
from appearances;

select min(yearid), max(yearid)
from collegeplaying;

select min(c.yearid), max(a.yearid)
from appearances as a full join collegeplaying as c 
	on a.yearid = c.yearid;


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

----------------

SELECT ppl.namefirst, ppl.namelast, app.g_all AS games, t.name AS team
FROM people AS ppl
LEFT JOIN appearances AS app
ON ppl.playerid = app.playerid
RIGHT JOIN teams AS t
ON app.teamid = t.teamid
WHERE ppl.height IN (SELECT MIN(height) FROM people)
AND t.yearid = '1951';

--- 3.

WITH income_per_player AS
	(SELECT playerid, SUM(salary) AS income_per_player
	FROM salaries
	GROUP BY playerid)
SELECT DISTINCT ppl.playerid, sch.schoolname, ppl.namefirst, ppl.namelast, ipp.income_per_player::numeric::money
FROM people as ppl
	 INNER JOIN salaries as s
	 ON ppl.playerid = s.playerid
	 INNER JOIN collegeplaying as cp
	 ON ppl.playerid = cp.playerid
	 INNER JOIN schools as sch
	 ON cp.schoolid = sch.schoolid
	 INNER JOIN income_per_player AS ipp
	 ON ipp.playerid = ppl.playerid
WHERE sch.schoolname = 'Vanderbilt University'
ORDER BY ipp.income_per_player::numeric::money DESC;

-------------------

SELECT ppl.namefirst as first, ppl.namelast as last, SUM(sal.salary) as lifetime_salary
FROM people as ppl
INNER JOIN salaries as sal ON ppl.playerid = sal.playerid
INNER JOIN collegeplaying as clp ON ppl.playerid = clp.playerid
INNER JOIN schools as sch ON clp.schoolid = sch.schoolid
WHERE sch.schoolname ILIKE 'Vanderbilt University'
GROUP BY  ppl.namefirst, ppl.namelast
ORDER BY lifetime_salary DESC;

----------------- correct:

WITH vandy_salaries as (SELECT DISTINCT namefirst AS namefirst, namelast, schoolid, salaries.yearid AS yearid, salary
						 FROM people INNER JOIN collegeplaying USING(playerid)
						 INNER JOIN salaries USING(playerid)
						 WHERE schoolid = 'vandy'
						 ORDER BY namefirst, namelast, yearid)
SELECT namefirst, namelast, schoolid, SUM(salary)::text::money AS total_salary
FROM vandy_salaries
GROUP BY namefirst, namelast, schoolid
ORDER BY total_salary DESC;





--4. Using the fielding table, group players into three groups based on their position: 
-- label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", 
--and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.


SELECT *
FROM fielding;

SELECT SUM(po) AS putouts,
		CASE 
		WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos = 'SS' OR pos = '1B' OR pos = '2B' OR pos = '3B' THEN 'Infield'
		WHEN pos = 'P' OR pos ='C' THEN 'Battery' END as pos_category
FROM fielding
WHERE yearID = '2016'
GROUP BY pos_category;


------correct:

WITH calculation AS (
		SELECT playerid, pos,
			CASE WHEN pos = 'OF' THEN 'Outfield'
			WHEN pos = 'SS' OR pos ='1B' OR pos = '2B' OR pos = '3B' THEN 'Infield'
			ELSE 'Battery' END AS position,
			po AS PutOut,
			yearid
		FROM fielding
		WHERE yearid = '2016')
SELECT position, SUM(putout) AS number_putouts
FROM calculation
GROUP BY position;

----5:


SELECT ROUND(AVG(soa), 2) AS strikeouts, ROUND(AVG(hr), 2) AS homeruns,
CASE WHEN yearid BETWEEN 1920 AND 1929 THEN '1920s'
WHEN yearid BETWEEN 1930 AND 1939 THEN '1930s'
WHEN yearid BETWEEN 1940 AND 1949 THEN '1940s'
WHEN yearid BETWEEN 1950 AND 1959 THEN '1950s'
WHEN yearid BETWEEN 1960 AND 1969 THEN '1960s'
WHEN yearid BETWEEN 1970 AND 1979 THEN '1970s'
WHEN yearid BETWEEN 1980 AND 1989 THEN '1980s'
WHEN yearid BETWEEN 1990 AND 1999 THEN '1990s'
WHEN yearid BETWEEN 2000 AND 2009 THEN '2000s'
ELSE '2010s' END AS games_by_decades
FROM teams
GROUP BY games_by_decades
ORDER BY games_by_decades ASC;

---------------------------------

SELECT teams.yearid /10*10 as decade, sum(so) AS total_strike_out,
	   Sum(g) as total_games,
	   round(sum(so)::decimal / sum(g),2)::decimal as average_strike_out
	   FROM teams
	   WHERE yearid >= '1920'
	   GROUP BY yearid/10*10
	   ORDER BY decade DESC
	   
-- Home Runs
SELECT teams.yearid /10*10 as decade, sum(hr) AS homerun,
	   Sum(g) as total_games,
	   round(sum(hr)::decimal / sum(g),2)::decimal as average_homerun
	   FROM teams
	   WHERE yearid >= '1920'
	   GROUP BY yearid/10*10
	   ORDER BY decade DESC


---------------


SELECT yearid/10*10 as decade,
	   ROUND(AVG(HR/g), 2) as avg_HR_per_game,
	   ROUND(AVG(so/g), 2) as avg_so_per_game
FROM teams
WHERE yearid>=1920
GROUP BY decade
ORDER BY decade

--6.

WITH steal_attempts AS
	(SELECT DISTINCT playerid, cs AS caught_stealing, sb AS stolen_bases,
	 (cs + sb) AS steal_attempts
	 FROM batting
	 WHERE cs + sb <> 0 AND yearid = 2016), -- there are no playerid duplicates here, math adding up
    success_rate AS
	(SELECT DISTINCT bs.playerid, sa.caught_stealing, 
	 sa.stolen_bases, ROUND((sa.stolen_bases::decimal/sa.steal_attempts::decimal)::decimal, 4) AS success_rate
	FROM batting AS bs
	INNER JOIN steal_attempts AS sa
	ON bs.playerid = sa.playerid
	WHERE cs + sb <> 0 AND yearid = 2016)
SELECT DISTINCT bs.playerid, ppl.namelast, ppl.namefirst, sa.steal_attempts, sr.success_rate, bs.cs AS caught_stealing, bs.sb AS stolen_bases, bs.yearid, bs.teamid
FROM batting as bs
	 INNER JOIN people as ppl
	 ON bs.playerid = ppl.playerid
	 INNER JOIN steal_attempts as sa
	 ON bs.playerid = sa.playerid
	 INNER JOIN success_rate as sr
	 ON bs.playerid = sr.playerid
WHERE bs.yearid = 2016 AND sa.steal_attempts >= 20
ORDER BY sr.success_rate DESC, sa.steal_attempts DESC;



---------------------


SELECT DISTINCT b.playerid, 
				CONCAT(p.namefirst,' ',p.namelast) AS player_name, 
				(b.sb) AS stolen_bases, 
				(b.cs) AS caught_stealing, 
				b.sb+b.cs AS sb_cs, 
				ROUND(CAST(float8 (b.sb/(b.sb+b.cs)::float*100) AS NUMERIC),2) AS successful_stolen_bases_percent
FROM batting AS b
LEFT JOIN people AS p 
ON b.playerid = p.playerid
WHERE b.yearid = '2016'
GROUP BY b.playerid, p.namefirst, p.namelast, b.sb, b.cs
HAVING SUM(b.sb+b.cs) >= 20
ORDER BY successful_stolen_bases_percent DESC

----------------------

select  distinct(p.playerid),
		p.namefirst, p.namelast,
		a.yearid, b.sb,
		cast(b.sb as numeric) + cast(b.cs as numeric) as total_attempts,
		round(cast(b.sb as numeric) /(cast(b.sb as numeric) + cast(b.cs as numeric)),2) as percentage_stole
from people as p left join appearances as a
	on p.playerid = a.playerid 
	left join batting as b
	on p.playerid = b.playerid
where	a.yearid = 2016
		and b.yearid =2016
		and cast(b.sb as numeric) + cast(b.cs as numeric) >= 20
order by percentage_stole desc;


--7.

SELECT yearid, teamid, MIN(w) as min_wins
FROM teams
WHERE 
	yearid BETWEEN 1970 AND 2016
	AND teamid IN (
	SELECT teamid
	FROM teams
	WHERE wswin = 'Y' 
	AND yearid BETWEEN 1970 AND 2016)
GROUP BY yearid, teamid
ORDER BY MIN(w)
LIMIT 1;


SELECT yearid, teamid, MAX(w) as max_wins
FROM teams
WHERE 
	yearid BETWEEN 1970 AND 2016
	AND teamid NOT IN (
	SELECT teamid
	FROM teams
	WHERE wswin = 'Y' 
	AND yearid >= 1970 AND yearid <=2016)
GROUP BY yearid, teamid
ORDER BY MAX(w)DESC
LIMIT 1;






--SELECT yearid, teamid, MIN(w) as min_wins
--FROM teams
--WHERE (yearid BETWEEN 1970 AND 1980 OR yearid BETWEEN 1982 AND 2016)
	--AND teamid IN (
	--SELECT teamid
	--FROM teams
	--WHERE wswin = 'Y' 
	--AND yearid BETWEEN 1970 AND 2016)
--GROUP BY yearid, teamid
--ORDER BY MIN(w)
--LIMIT 1;


-- correct: with and without 1981


WITH most_no_win AS (SELECT name, w, wswin, yearid
					 FROM teams
					 WHERE yearid BETWEEN 1970 AND 2016
					 	   AND wswin = 'N'
					 	   --AND yearid <> 1981
					 ORDER BY w DESC
					 LIMIT 1),
	 least_win AS (SELECT name, w, wswin, yearid
				   FROM teams
				   WHERE yearid BETWEEN 1970 AND 2016
				   	   	 AND wswin = 'Y'
					 	 --AND yearid <> 1981
				   ORDER BY w
				   LIMIT 1)
SELECT *
FROM most_no_win
UNION ALL
SELECT *
FROM least_win;


--- 7. Part 2: 


WITH ws_wins AS (SELECT name, w, wswin, yearid
					 FROM teams
					 WHERE yearid BETWEEN 1970 AND 2016
					 	   AND wswin = 'Y'
					 ORDER BY w DESC),
	 most_wins AS (SELECT MAX(w) AS w, yearid
				   FROM teams
				   WHERE yearid BETWEEN 1970 AND 2016
				   GROUP BY yearid)
SELECT 2016-1970 AS total_seasons, COUNT(*) AS most_win_ws, (COUNT(*)::float/(2016-1970)::float)*100 AS pct_ws_most
FROM most_wins INNER JOIN ws_wins USING(yearid)
WHERE most_wins.w = ws_wins.w;


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


-- Top5:

select sum(homegames.attendance)/sum(homegames.games) as average_max_attendance, parks.park_name, teams.name
from homegames inner join parks
on homegames.park = parks.park
inner join teams
on teams.teamid = homegames.team
where games > 10
and year = '2016'
group by parks.park_name, teams.name
order by average_max_attendance desc
limit 5;

-- Lowest 5:
select sum(homegames.attendance)/sum(homegames.games) as average_min_attendance, parks.park_name, teams.name
from homegames inner join parks
on homegames.park = parks.park
inner join teams
on teams.teamid = homegames.team
where games > 10
and year = '2016'
group by parks.park_name, teams.name
order by average_min_attendance asc
limit 5;




-- correct:



WITH avg_attend AS (SELECT park, team, attendance/games AS avg_attendance
					FROM homegames
					WHERE year = 2016
						  AND games >= 10),
	 avg_attend_full AS (SELECT park_name, name as team_name, avg_attendance
						 FROM avg_attend INNER JOIN teams ON avg_attend.team = teams.teamid
						 	  INNER JOIN parks ON avg_attend.park = parks.park
						 WHERE teams.yearid = 2016
						 GROUP BY park_name, avg_attendance, name),
	 top_5 AS (SELECT *, 'top_5' AS category
			   FROM avg_attend_full
			   ORDER BY avg_attendance DESC
			   LIMIT 5),
	 bottom_5 AS (SELECT *, 'bottom_5' AS category
			      FROM avg_attend_full
			      ORDER BY avg_attendance
			      LIMIT 5)
SELECT *
FROM top_5
UNION ALL
SELECT *
FROM bottom_5;


--9.


WITH mngr_list AS (SELECT playerid, awardid, COUNT(DISTINCT lgid) AS lg_count
				   FROM awardsmanagers
				   WHERE awardid = 'TSN Manager of the Year'
				   		 AND lgid IN ('NL', 'AL')
				   GROUP BY playerid, awardid
				   HAVING COUNT(DISTINCT lgid) = 2),
	 mngr_full AS (SELECT playerid, awardid, lg_count, yearid, lgid
				   FROM mngr_list INNER JOIN awardsmanagers USING(playerid, awardid))
SELECT DISTINCT namegiven, namelast, name AS team_name, mngr_full.lgid, mngr_full.yearid
FROM mngr_full INNER JOIN people USING(playerid)
	 INNER JOIN managers USING(playerid, yearid, lgid)
	 INNER JOIN teams ON mngr_full.yearid = teams.yearid AND mngr_full.lgid = teams.lgid AND managers.teamid = teams.teamid;



-- 10.

WITH tn_schools AS (SELECT schoolname, schoolid
					FROM schools
					WHERE schoolstate = 'TN'
					GROUP BY schoolname, schoolid)
SELECT schoolname, COUNT(DISTINCT playerid) AS player_count, SUM(salary)::text::money AS total_salary, (SUM(salary)/COUNT(DISTINCT playerid))::text::money AS money_per_player
FROM tn_schools INNER JOIN collegeplaying USING(schoolid)
	 INNER JOIN people USING(playerid)
	 INNER JOIN salaries USING(playerid)
GROUP BY schoolname
ORDER BY money_per_player DESC;


---------

WITH income_per_player AS
	(SELECT playerid, SUM(salary) AS income_per_player
	FROM salaries
	GROUP BY playerid),
	income_per_school AS
	(SELECT cp.schoolid AS schoolid, SUM(salary) AS income_per_school
	FROM salaries as s
	 INNER JOIN collegeplaying as cp
	 ON s.playerid = cp.playerid
	 INNER JOIN schools as sch
	 ON cp.schoolid = sch.schoolid
	 GROUP BY cp.schoolid)
SELECT DISTINCT cp.schoolid, sch.schoolname, MAX(ips.income_per_school::numeric::money) AS income_per_school,
	MAX(ipp.income_per_player::numeric::money) AS max_income_perplayer, COUNT(DISTINCT ppl.playerid) AS players_to_majors,
	(MAX(ips.income_per_school)/COUNT(DISTINCT ppl.playerid))::numeric::money AS college_income_per_majors_player,
	MIN(s.yearid) AS first_salariedin_majors, MAX(s.yearid) AS latest_salariedin_majors--, COUNT(hof.playerid)
FROM people as ppl
	 INNER JOIN salaries as s
	 ON ppl.playerid = s.playerid
	 INNER JOIN collegeplaying as cp
	 ON ppl.playerid = cp.playerid
	 INNER JOIN schools as sch
	 ON cp.schoolid = sch.schoolid
	 INNER JOIN income_per_player AS ipp
	 ON ipp.playerid = ppl.playerid
	 INNER JOIN income_per_school AS ips
	 ON cp.schoolid = ips.schoolid
	-- INNER JOIN halloffame as hof
	-- ON ppl.playerid = hof.playerid
WHERE sch.schoolstate = 'TN'
GROUP BY cp.schoolid, sch.schoolname
ORDER BY MAX(ips.income_per_school::numeric::money) DESC, MAX(ipp.income_per_player::numeric::money) DESC;


--11.


WITH team_year_sal_w AS (SELECT teamid, yearid, SUM(salary) AS total_team_sal, AVG(w)::integer AS w
						 FROM salaries INNER JOIN teams USING(yearid, teamid)
						 WHERE yearid >= 2000
						 GROUP BY yearid, teamid)
SELECT yearid, CORR(total_team_sal, w) AS sal_win_corr
FROM team_year_sal_w
GROUP BY yearid
ORDER BY yearid;

--12.-- In this question, you will explore the connection between number of wins and attendance.
-- Does there appear to be any correlation between attendance at home games and number of wins?
-- Do teams that win the world series see a boost in attendance the following year?
-- What about teams that made the playoffs?
-- Making the playoffs means either being a division winner or a wild card winner.
SELECT CORR(homegames.attendance, w) AS corr_attend_w
FROM teams INNER JOIN homegames ON teamid = team AND yearid = year
WHERE homegames.attendance IS NOT NULL
---
SELECT AVG(hg_2.attendance - hg_1.attendance) AS avg_attend_increase,
	   stddev_pop(hg_2.attendance - hg_1.attendance) AS stdev_attend_increase,
	   MAX(hg_2.attendance - hg_1.attendance) AS max_attend_increase,
	   MIN(hg_2.attendance - hg_1.attendance) AS min_attend_increase
FROM teams INNER JOIN homegames AS hg_1 ON teams.yearid = hg_1.year AND teams.teamid = hg_1.team
	 	   INNER JOIN homegames AS hg_2 ON teams.yearid + 1 = hg_2.year AND teams.teamid = hg_2.team
WHERE wswin = 'Y'
	  AND hg_1.attendance > 0
	  AND hg_2.attendance > 0;
---
SELECT AVG(hg_2.attendance - hg_1.attendance) AS avg_attend_increase,
	   stddev_pop(hg_2.attendance - hg_1.attendance) AS stdev_attend_increase,
	   MAX(hg_2.attendance - hg_1.attendance) AS max_attend_increase,
	   MIN(hg_2.attendance - hg_1.attendance) AS min_attend_increase
FROM teams INNER JOIN homegames AS hg_1 ON teams.yearid = hg_1.year AND teams.teamid = hg_1.team
	 INNER JOIN homegames AS hg_2 ON teams.yearid + 1 = hg_2.year AND teams.teamid = hg_2.team
WHERE (divwin = 'Y' OR wcwin = 'Y')
	  AND hg_1.attendance > 0
	  AND hg_2.attendance > 0;

--13.
It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective.
-- Investigate this claim and present evidence to either support or dispute this claim.
-- First, determine just how rare left-handed pitchers are compared with right-handed pitchers.
-- Are left-handed pitchers more likely to win the Cy Young Award?
-- Are they more likely to make it into the hall of fame?
WITH pitchers AS (SELECT *
				  FROM people INNER JOIN pitching USING(playerid)
				 	   INNER JOIN awardsplayers USING(playerid)
				 	   INNER JOIN halloffame USING(playerid))
SELECT (SELECT COUNT(DISTINCT playerid)::float
		FROM pitchers WHERE throws = 'L')/COUNT(DISTINCT playerid)::float AS pct_left_pitch,
	   (SELECT COUNT(DISTINCT playerid)::float
		FROM pitchers WHERE awardid = 'Cy Young Award')/COUNT(DISTINCT playerid)::float AS pct_pitch_cy_young,
	   ((SELECT COUNT(DISTINCT playerid)::float
		 FROM pitchers WHERE awardid = 'Cy Young Award')/COUNT(DISTINCT playerid)::float) * ((SELECT COUNT(DISTINCT playerid)::float
																							  FROM pitchers WHERE throws = 'L')/COUNT(DISTINCT playerid)::float) AS calc_pct_left_cy_young,
	   (SELECT COUNT(DISTINCT playerid)::float
		FROM pitchers WHERE awardid = 'Cy Young Award' AND throws = 'L')/COUNT(DISTINCT playerid)::float AS actual_pct_left_cy_young,
	   (SELECT COUNT(DISTINCT playerid)::float
		FROM pitchers WHERE inducted = 'Y')/COUNT(DISTINCT playerid)::float AS pct_hof,
	   ((SELECT COUNT(DISTINCT playerid)::float
		 FROM pitchers WHERE inducted = 'Y')/COUNT(DISTINCT playerid)::float) * ((SELECT COUNT(DISTINCT playerid)::float
																				  FROM pitchers WHERE throws = 'L')/COUNT(DISTINCT playerid)::float) AS calc_pct_left_hof,
	   (SELECT COUNT(DISTINCT playerid)::float
		FROM pitchers WHERE inducted = 'Y' AND throws = 'L')/COUNT(DISTINCT playerid)::float AS actual_pct_left_hof
FROM pitchers;
