-- =====================================================================
-- 06_player_valuations.sql : nettoyage de la table player_valuations
-- Source : raw_football.player_valuations (656 301 lignes)
-- Resultat : clean_football.player_valuations (656 301 lignes)
-- =====================================================================

-- ---------- 1. CONTROLES SUR LA TABLE BRUTE ----------
SELECT COUNT(*)                                          AS total,
       SUM(STR_TO_DATE(date, '%Y-%m-%d') IS NULL)        AS date_invalide,
       SUM(market_value_in_eur = '')                     AS valeur_vide,
       SUM(CAST(NULLIF(market_value_in_eur,'') AS DECIMAL(15,2)) = 0) AS valeur_zero,
       SUM(current_club_name = 'Unknown')                AS club_unknown,
       SUM(current_club_name = '')                       AS club_vide,
       SUM(player_club_domestic_competition_id = '')     AS competition_vide
FROM raw_football.player_valuations;

-- Doublons sur (player_id, date) : attendu 0 -> cle primaire composite possible
SELECT COUNT(*) AS lignes_en_double
FROM (
    SELECT player_id, date
    FROM raw_football.player_valuations
    GROUP BY player_id, date
    HAVING COUNT(*) > 1
) AS d;

-- ---------- 2. CREATION DE LA TABLE PROPRE ----------
-- 'Unknown' et cellules vides -> NULL ; valeur a 0 (1 ligne) -> NULL
USE clean_football;

DROP TABLE IF EXISTS player_valuations;

CREATE TABLE player_valuations AS
SELECT
    CAST(player_id AS SIGNED)                                    AS player_id,
    STR_TO_DATE(TRIM(date), '%Y-%m-%d')                          AS date,
    NULLIF(CAST(NULLIF(TRIM(market_value_in_eur), '') AS DECIMAL(15,0)), 0) AS market_value_in_eur,
    CASE WHEN TRIM(current_club_name) IN ('', 'Unknown') THEN NULL
         ELSE TRIM(current_club_name) END                        AS current_club_name,
    CAST(NULLIF(TRIM(current_club_id), '') AS SIGNED)            AS current_club_id,
    NULLIF(TRIM(player_club_domestic_competition_id), '')        AS player_club_domestic_competition_id
FROM raw_football.player_valuations;

ALTER TABLE player_valuations
  MODIFY player_id                          INT NOT NULL,
  MODIFY date                               DATE NOT NULL,
  MODIFY market_value_in_eur                INT UNSIGNED,
  MODIFY current_club_name                  VARCHAR(60),
  MODIFY current_club_id                    INT,
  MODIFY player_club_domestic_competition_id CHAR(4),
  ADD PRIMARY KEY (player_id, date),
  ADD INDEX idx_club (current_club_id),
  ADD INDEX idx_date (date);

-- ---------- 3. VALIDATION ----------
-- Attendu : 656301 | 41528 | 1 | 3199 | 92973 | 2000-01-20 | 2026-06-12 | 200000000
SELECT COUNT(*)                                          AS total,
       COUNT(DISTINCT player_id)                         AS joueurs,
       SUM(market_value_in_eur IS NULL)                  AS valeur_null,
       SUM(current_club_name IS NULL)                    AS club_nom_null,
       SUM(player_club_domestic_competition_id IS NULL)  AS competition_null,
       MIN(date)                                         AS date_min,
       MAX(date)                                         AS date_max,
       MAX(market_value_in_eur)                          AS valeur_max
FROM clean_football.player_valuations;
