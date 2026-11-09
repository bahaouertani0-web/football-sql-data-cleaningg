-- =====================================================================
-- 08_analyses.sql : 5 analyses sur les donnees nettoyees
-- Les resultats sont presentes dans le README.
-- =====================================================================

-- 1. Les 10 meilleurs buteurs de la base
SELECT player_name, SUM(goals) AS buts, SUM(assists) AS passes, COUNT(*) AS matchs
FROM clean_football.appearances
GROUP BY player_id, player_name
ORDER BY buts DESC
LIMIT 10;

-- 2. Les 10 joueurs les plus chers (derniere saison de la base)
SELECT name, position, current_club_name, market_value_in_eur
FROM clean_football.players
WHERE last_season = (SELECT MAX(last_season) FROM clean_football.players)
ORDER BY market_value_in_eur DESC
LIMIT 10;

-- 3. Les 10 plus gros transferts (hors transferts futurs)
SELECT player_name, from_club_name, to_club_name, transfer_date, transfer_fee
FROM clean_football.transfers
WHERE is_future = 0
ORDER BY transfer_fee DESC
LIMIT 10;

-- 4. Depenses de transferts par annee (frais connus et superieurs a 0)
SELECT YEAR(transfer_date) AS annee,
       COUNT(*) AS transferts_payants,
       ROUND(SUM(transfer_fee) / 1000000) AS depenses_millions_eur
FROM clean_football.transfers
WHERE is_future = 0 AND transfer_fee > 0
GROUP BY YEAR(transfer_date)
ORDER BY annee;

-- 5. Moyenne de buts par match en Premier League, par saison
SELECT season,
       COUNT(*) AS matchs,
       ROUND(AVG(home_club_goals + away_club_goals), 2) AS buts_par_match
FROM clean_football.games
WHERE competition_id = 'GB1'
GROUP BY season
ORDER BY season;
