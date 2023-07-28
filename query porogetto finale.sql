/*
Assignment Instructions
You will be working with the European Soccer Database, a collection of four individual CSV files 
that you will find in the 2.9.x European Soccer Database.zip compressed folder, containing: 
    • leagues.csv
    • match.csv
    • player.csv 
    • match.csv
*/

-- 3  How many days have passed from the oldest Match to the most recent one (dataset time interval)?
SELECT DATE_DIFF( MAX(date), MIN(date), day) FROM (
	SELECT season, date,  FROM `my-project-prova-384317.Final_Exercise.match` ORDER BY season, date
	);

-- 4 Produce a table which, for each Season and League Name, shows the following statistics about the home goals scored: 
SELECT *  FROM 
(SELECT
season, name, 
min( home_team_goal ) as minimo_goal, 
avg( home_team_goal ) as media_goal,
(max( home_team_goal )+min( home_team_goal ))/2 as mid_range,
max( home_team_goal ) as massimo_dei_goal, 
sum( home_team_goal ) as somma_dei_goal  
FROM 
(SELECT a.*, b.name
FROM `my-project-prova-384317.Final_Exercise.match` AS a
LEFT JOIN `my-project-prova-384317.Final_Exercise.leagues` AS b
on a.league_id = b.id ) 
GROUP BY season, name ORDER BY season)
ORDER BY somma_dei_goal DESC LIMIT 1
;

--5 Find out how many unique seasons there are in the Match table. 
Then write a query that shows, for each Season, the number of matches played by each League. Do you notice anything out of the ordinary?
SELECT season, league_id, COUNT( DISTINCT( match_api_id)) AS numero_match_giocati 
 FROM `my-project-prova-384317.Final_Exercise.match` GROUP BY season, league_id ORDER BY season, league_id;

 --6
   /*  
       Using Players as the starting point, create a new table (PlayerBMI) and add: 
        a. a new variable that represents the players’ weight in kg (divide the mass value by 2.205) and call it kg_weight; 
        b. a variable that represents the height in metres (divide the cm value by 100) and call it m_height; 
        c. a variable that shows the body mass index (BMI) of the player;
Hint: research how to calculate the formula of the BMI 
        d. Filter the table to show only the players with an optimal BMI (from 18.5 to 24.9). 
	How many rows does this table have? 
  	*/

CREATE TABLE my-project-prova-384317.Final_Exercise.PlayerBMI AS 
SELECT *, weight/2.205 kg_weight, height/100 m_height, (weight/2.205)/( (height/100)*(height/100)) BMI
FROM my-project-prova-384317.Final_Exercise.player;

SELECT * FROM my-project-prova-384317.Final_Exercise.PlayerBMI 
WHERE BMI>18.5 AND BMI<24.9 ORDER BY BMI

--7 How many players do not have an optimal BMI? 
SELECT count(id) FROM my-project-prova-384317.Final_Exercise.PlayerBMI 
WHERE BMI<18.5 AND BMI>24.9 

--8 Which Team has scored the highest total number of goals (home + away) during the most recent available season? How many goals has it scored?


/* Ho fatto una full outer join per collegare due tabelle da due colonne, da questa ho preso la prima colonna e sommato 3° e 4° colonna, 
e poi ho fatto una right join per collegare il nome esteso della squadra
*/
SELECT a.team_long_name, b.somma_goals FROM `my-project-prova-384317.Final_Exercise.team` AS a
RIGHT JOIN 
(
 SELECT home_team_api_id, ( home_goals + away_goals ) AS somma_goals
 FROM (
	SELECT a.*, b.* FROM
		(SELECT home_team_api_id, SUM(home_team_goal) AS home_goals, 
		FROM `my-project-prova-384317.Final_Exercise.match`
		WHERE season = (SELECT MAX(season) FROM `my-project-prova-384317.Final_Exercise.match`)
		GROUP BY home_team_api_id ORDER BY home_team_api_id ) AS a
	FULL OUTER JOIN 
		(SELECT away_team_api_id, SUM (away_team_goal) AS away_goals,
		FROM `my-project-prova-384317.Final_Exercise.match`
		WHERE season = (SELECT MAX(season) FROM `my-project-prova-384317.Final_Exercise.match`)
		GROUP BY away_team_api_id ORDER BY away_team_api_id ) AS b
	on a.home_team_api_id = b.away_team_api_id
	ORDER BY home_team_api_id
	)
 GROUP BY home_team_api_id, somma_goals 
 ORDER BY somma_goals DESC
 LIMIT 1 
) AS b 
on a.team_api_id = b.home_team_api_id

--9
/*
Create a query that, for each season, shows the name of the team that ranks first in terms of total goals scored 
(the output table should have as many rows as the number of seasons). 
Which team was the one that ranked first in most of the seasons? 
*/


/* Sulla scia dell’esercizio precedente, ho ottenuto la tabella con la somma dei goal per ciascuna squadra per stagione,
 poi con una right join ho inserito i nomi completi delle squadre. A questo punto con la funzione DENSE_RANK ho dato un rank all’interno
*/
 SELECT * FROM (
SELECT *, 
DENSE_RANK() OVER (PARTITION BY season ORDER BY  somma_goals DESC, season) AS score_rank FROM (

SELECT b.season, a.team_long_name, b.somma_goals FROM `my-project-prova-384317.Final_Exercise.team` AS a
RIGHT JOIN 
(
 SELECT season, home_team_api_id, ( home_goals + away_goals ) AS somma_goals
 FROM (
	SELECT a.*, b.away_team_api_id, b.away_goals FROM
		(SELECT season, home_team_api_id, SUM(home_team_goal) AS home_goals, 
		FROM `my-project-prova-384317.Final_Exercise.match`
    GROUP BY season, home_team_api_id ORDER BY season, home_team_api_id ) AS a
	FULL OUTER JOIN 
		(SELECT season, away_team_api_id, SUM (away_team_goal) AS away_goals,
		FROM `my-project-prova-384317.Final_Exercise.match`
		GROUP BY season, away_team_api_id ORDER BY season, away_team_api_id ) AS b
	on a.home_team_api_id = b.away_team_api_id AND a.season=b.season
	ORDER BY season, home_team_api_id
	)
 GROUP BY season, home_team_api_id, somma_goals 
 ORDER BY season, somma_goals DESC
 ) AS b
 on a.team_api_id = b.home_team_api_id
  ORDER BY season, somma_goals DESC
)
 ORDER BY season
)
WHERE (score_rank=1)

--10
/*
From the query above (question 8) create a new table (TopScorer) containing the top 10 teams in terms of total goals scored (hint: add the team id as well). 
Then write a query that shows all the possible “pair combinations” between those 10 teams. How many “pair combinations” did it generate? 
*/


CREATE TABLE my-project-prova-384317.Final_Exercise.TopScorer AS SELECT * FROM
(SELECT *, 
    ROW_NUMBER() OVER ( ORDER BY  somma_goals DESC) AS score_rank 
    FROM (
SELECT a.team_long_name, b.somma_goals FROM `my-project-prova-384317.Final_Exercise.team` AS a
RIGHT JOIN 
(
 SELECT home_team_api_id, ( home_goals + away_goals ) AS somma_goals
 FROM (
	SELECT a.*, b.* FROM
		(SELECT home_team_api_id, SUM(home_team_goal) AS home_goals, 
		FROM `my-project-prova-384317.Final_Exercise.match`
		WHERE season = (SELECT MAX(season) FROM `my-project-prova-384317.Final_Exercise.match`)
		GROUP BY home_team_api_id ORDER BY home_team_api_id ) AS a
	FULL OUTER JOIN 
		(SELECT away_team_api_id, SUM (away_team_goal) AS away_goals,
		FROM `my-project-prova-384317.Final_Exercise.match`
		WHERE season = (SELECT MAX(season) FROM `my-project-prova-384317.Final_Exercise.match`)
		GROUP BY away_team_api_id ORDER BY away_team_api_id ) AS b
	on a.home_team_api_id = b.away_team_api_id
	ORDER BY home_team_api_id
	)
 GROUP BY home_team_api_id, somma_goals 
 ORDER BY somma_goals DESC
 LIMIT 10
) AS b 
on a.team_api_id = b.home_team_api_id
) )
ORDER BY somma_goals DESC

-- COMBINAZIONI SENZA RIPETIZIONI , 45
SELECT * FROM (
SELECT * FROM (
  SELECT score_rank, 
  (SELECT team_long_name FROM `my-project-prova-384317.Final_Exercise.TopScorer`
  WHERE score_rank=1) AS team_di_casa ,
LEAD(team_long_name, 1 ) over (order by score_rank ) AS team_avversario
  FROM `my-project-prova-384317.Final_Exercise.TopScorer`
ORDER BY score_rank )
UNION ALL
SELECT * FROM (
SELECT score_rank, 
  (SELECT team_long_name FROM `my-project-prova-384317.Final_Exercise.TopScorer`
  WHERE score_rank=2) AS team_di_casa ,
LEAD(team_long_name, 2 ) over (order by score_rank ) AS team_avversario
  FROM `my-project-prova-384317.Final_Exercise.TopScorer`
ORDER BY score_rank )
UNION ALL
SELECT * FROM (
SELECT score_rank, 
  (SELECT team_long_name FROM `my-project-prova-384317.Final_Exercise.TopScorer`
  WHERE score_rank=3) AS team_di_casa ,
LEAD(team_long_name, 3 ) over (order by score_rank ) AS team_avversario
  FROM `my-project-prova-384317.Final_Exercise.TopScorer`
ORDER BY score_rank )
UNION ALL
SELECT * FROM (
SELECT score_rank, 
  (SELECT team_long_name FROM `my-project-prova-384317.Final_Exercise.TopScorer`
  WHERE score_rank=4) AS team_di_casa ,
LEAD(team_long_name, 4 ) over (order by score_rank ) AS team_avversario
  FROM `my-project-prova-384317.Final_Exercise.TopScorer`
ORDER BY score_rank )
UNION ALL
SELECT * FROM (
SELECT score_rank, 
  (SELECT team_long_name FROM `my-project-prova-384317.Final_Exercise.TopScorer`
  WHERE score_rank=5) AS team_di_casa ,
LEAD(team_long_name, 5 ) over (order by score_rank ) AS team_avversario
  FROM `my-project-prova-384317.Final_Exercise.TopScorer`
ORDER BY score_rank )
UNION ALL
SELECT * FROM (
SELECT score_rank, 
  (SELECT team_long_name FROM `my-project-prova-384317.Final_Exercise.TopScorer`
  WHERE score_rank=6) AS team_di_casa ,
LEAD(team_long_name, 6 ) over (order by score_rank ) AS team_avversario
  FROM `my-project-prova-384317.Final_Exercise.TopScorer`
ORDER BY score_rank )
UNION ALL
SELECT * FROM (
SELECT score_rank, 
  (SELECT team_long_name FROM `my-project-prova-384317.Final_Exercise.TopScorer`
  WHERE score_rank=7) AS team_di_casa ,
LEAD(team_long_name, 7 ) over (order by score_rank ) AS team_avversario
  FROM `my-project-prova-384317.Final_Exercise.TopScorer`
ORDER BY score_rank )
UNION ALL
SELECT * FROM (
SELECT score_rank, 
  (SELECT team_long_name FROM `my-project-prova-384317.Final_Exercise.TopScorer`
  WHERE score_rank=8) AS team_di_casa ,
LEAD(team_long_name, 8 ) over (order by score_rank ) AS team_avversario
  FROM `my-project-prova-384317.Final_Exercise.TopScorer`
ORDER BY score_rank )
UNION ALL
SELECT * FROM (
SELECT score_rank, 
  (SELECT team_long_name FROM `my-project-prova-384317.Final_Exercise.TopScorer`
  WHERE score_rank=9) AS team_di_casa ,
LEAD(team_long_name, 9 ) over (order by score_rank ) AS team_avversario
  FROM `my-project-prova-384317.Final_Exercise.TopScorer`
ORDER BY score_rank )
ORDER BY  team_di_casa, score_rank
) WHERE team_avversario IS NOT NULL



-- COMBINAZIONI CON RIPETIZIONI
SELECT * FROM (
SELECT * FROM (
  SELECT score_rank, 
  (SELECT team_long_name FROM `my-project-prova-384317.Final_Exercise.TopScorer`
  WHERE score_rank=1) AS team_di_casa ,
LEAD(team_long_name,0 ) over (order by score_rank ) AS team_avversario
  FROM `my-project-prova-384317.Final_Exercise.TopScorer`
ORDER BY score_rank )
UNION ALL
SELECT * FROM (
SELECT score_rank, 
  (SELECT team_long_name FROM `my-project-prova-384317.Final_Exercise.TopScorer`
  WHERE score_rank=2) AS team_di_casa ,
LEAD(team_long_name,0 ) over (order by score_rank ) AS team_avversario
  FROM `my-project-prova-384317.Final_Exercise.TopScorer`
ORDER BY score_rank )
UNION ALL
SELECT * FROM (
SELECT score_rank, 
  (SELECT team_long_name FROM `my-project-prova-384317.Final_Exercise.TopScorer`
  WHERE score_rank=3) AS team_di_casa ,
LEAD(team_long_name,0 ) over (order by score_rank ) AS team_avversario
  FROM `my-project-prova-384317.Final_Exercise.TopScorer`
ORDER BY score_rank )
UNION ALL
SELECT * FROM (
SELECT score_rank, 
  (SELECT team_long_name FROM `my-project-prova-384317.Final_Exercise.TopScorer`
  WHERE score_rank=4) AS team_di_casa ,
LEAD(team_long_name,0 ) over (order by score_rank ) AS team_avversario
  FROM `my-project-prova-384317.Final_Exercise.TopScorer`
ORDER BY score_rank )
UNION ALL
SELECT * FROM (
SELECT score_rank, 
  (SELECT team_long_name FROM `my-project-prova-384317.Final_Exercise.TopScorer`
  WHERE score_rank=5) AS team_di_casa ,
LEAD(team_long_name,0 ) over (order by score_rank ) AS team_avversario
  FROM `my-project-prova-384317.Final_Exercise.TopScorer`
ORDER BY score_rank )
UNION ALL
SELECT * FROM (
SELECT score_rank, 
  (SELECT team_long_name FROM `my-project-prova-384317.Final_Exercise.TopScorer`
  WHERE score_rank=6) AS team_di_casa ,
LEAD(team_long_name,0 ) over (order by score_rank ) AS team_avversario
  FROM `my-project-prova-384317.Final_Exercise.TopScorer`
ORDER BY score_rank )
UNION ALL
SELECT * FROM (
SELECT score_rank, 
  (SELECT team_long_name FROM `my-project-prova-384317.Final_Exercise.TopScorer`
  WHERE score_rank=7) AS team_di_casa ,
LEAD(team_long_name,0 ) over (order by score_rank ) AS team_avversario
  FROM `my-project-prova-384317.Final_Exercise.TopScorer`
ORDER BY score_rank )
UNION ALL
SELECT * FROM (
SELECT score_rank, 
  (SELECT team_long_name FROM `my-project-prova-384317.Final_Exercise.TopScorer`
  WHERE score_rank=8) AS team_di_casa ,
LEAD(team_long_name,0 ) over (order by score_rank ) AS team_avversario
  FROM `my-project-prova-384317.Final_Exercise.TopScorer`
ORDER BY score_rank )
UNION ALL
SELECT * FROM (
SELECT score_rank, 
  (SELECT team_long_name FROM `my-project-prova-384317.Final_Exercise.TopScorer`
  WHERE score_rank=9) AS team_di_casa ,
LEAD(team_long_name,0 ) over (order by score_rank ) AS team_avversario
  FROM `my-project-prova-384317.Final_Exercise.TopScorer`
ORDER BY score_rank )
UNION ALL
SELECT * FROM (
SELECT score_rank, 
  (SELECT team_long_name FROM `my-project-prova-384317.Final_Exercise.TopScorer`
  WHERE score_rank=10) AS team_di_casa ,
LEAD(team_long_name,0 ) over (order by score_rank ) AS team_avversario
  FROM `my-project-prova-384317.Final_Exercise.TopScorer`
ORDER BY score_rank )
ORDER BY team_di_casa, score_rank 
) WHERE (team_avversario IS NOT NULL ) AND ( team_di_casa != team_avversario)



