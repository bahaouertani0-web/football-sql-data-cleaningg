-- =====================================================================
-- 04_games.sql : nettoyage de la table games
-- Source : raw_football.games (88 958 lignes)
-- Resultat : clean_football.games (88 958 lignes)
-- =====================================================================

-- ---------- 1. CONTROLES SUR LA TABLE BRUTE ----------
SELECT COUNT(*)                                       AS total,
       COUNT(DISTINCT game_id)                        AS ids_uniques,
       SUM(game_id NOT REGEXP '^[0-9]+$')             AS id_non_numerique,
       SUM(STR_TO_DATE(date, '%Y-%m-%d') IS NULL)     AS date_invalide,
       SUM(referee = '')                              AS arbitre_vide,
       SUM(stadium = '')                              AS stade_vide,
       SUM(attendance = '')                           AS affluence_vide,
       SUM(home_club_position = '')                   AS position_dom_vide,
       SUM(home_club_formation = '')                  AS formation_dom_vide,
       SUM(competition_type = '')                     AS type_comp_vide
FROM raw_football.games;

-- ---------- 2. CREATION DE LA TABLE PROPRE ----------
-- Colonne retiree : url
-- Pas de cle etrangere vers competitions / clubs : de nombreux matchs
-- referencent des competitions ou des clubs absents de ces tables.
USE clean_football;

DROP TABLE IF EXISTS games;

CREATE TABLE games AS
SELECT
    CAST(game_id AS SIGNED)                                   AS game_id,
    TRIM(competition_id)                                      AS competition_id,
    CAST(season AS SIGNED)                                    AS season,
    NULLIF(TRIM(round), '')                                   AS round,
    STR_TO_DATE(TRIM(date), '%Y-%m-%d')                       AS date,
    CAST(home_club_id AS SIGNED)                              AS home_club_id,
    CAST(away_club_id AS SIGNED)                              AS away_club_id,
    CAST(home_club_goals AS DECIMAL(4,0))                     AS home_club_goals,
    CAST(away_club_goals AS DECIMAL(4,0))                     AS away_club_goals,
    CAST(NULLIF(TRIM(home_club_position), '') AS DECIMAL(4,0)) AS home_club_position,
    CAST(NULLIF(TRIM(away_club_position), '') AS DECIMAL(4,0)) AS away_club_position,
    NULLIF(TRIM(home_club_manager_name), '')                  AS home_club_manager_name,
    NULLIF(TRIM(away_club_manager_name), '')                  AS away_club_manager_name,
    NULLIF(TRIM(stadium), '')                                 AS stadium,
    CAST(NULLIF(TRIM(attendance), '') AS DECIMAL(10,0))       AS attendance,
    NULLIF(TRIM(referee), '')                                 AS referee,
    NULLIF(TRIM(home_club_formation), '')                     AS home_club_formation,
    NULLIF(TRIM(away_club_formation), '')                     AS away_club_formation,
    NULLIF(TRIM(home_club_name), '')                          AS home_club_name,
    NULLIF(TRIM(away_club_name), '')                          AS away_club_name,
    NULLIF(TRIM(aggregate), '')                               AS aggregate,
    NULLIF(TRIM(competition_type), '')                        AS competition_type
FROM raw_football.games;

ALTER TABLE games
  MODIFY game_id                 INT NOT NULL,
  MODIFY competition_id          CHAR(4) NOT NULL,
  MODIFY season                  SMALLINT UNSIGNED,
  MODIFY round                   VARCHAR(40),
  MODIFY home_club_id            INT NOT NULL,
  MODIFY away_club_id            INT NOT NULL,
  MODIFY home_club_goals         TINYINT UNSIGNED,
  MODIFY away_club_goals         TINYINT UNSIGNED,
  MODIFY home_club_position      TINYINT UNSIGNED,
  MODIFY away_club_position      TINYINT UNSIGNED,
  MODIFY home_club_manager_name  VARCHAR(60),
  MODIFY away_club_manager_name  VARCHAR(60),
  MODIFY stadium                 VARCHAR(80),
  MODIFY attendance              INT UNSIGNED,
  MODIFY referee                 VARCHAR(60),
  MODIFY home_club_formation     VARCHAR(50),
  MODIFY away_club_formation     VARCHAR(50),
  MODIFY home_club_name          VARCHAR(100),
  MODIFY away_club_name          VARCHAR(100),
  MODIFY aggregate               VARCHAR(10),
  MODIFY competition_type        VARCHAR(40),
  ADD PRIMARY KEY (game_id),
  ADD INDEX idx_competition (competition_id),
  ADD INDEX idx_home_club (home_club_id),
  ADD INDEX idx_away_club (away_club_id),
  ADD INDEX idx_date (date),
  ADD INDEX idx_season (season);

-- ---------- 3. VALIDATION ----------
-- Attendu : 88958 | 678 | 242 | 10803 | 25377 | 8200 | 1214 | 2006-06-09 | 2026-07-06
SELECT COUNT(*)                           AS total,
       SUM(referee IS NULL)               AS arbitre_null,
       SUM(stadium IS NULL)               AS stade_null,
       SUM(attendance IS NULL)            AS affluence_null,
       SUM(home_club_position IS NULL)    AS position_dom_null,
       SUM(home_club_formation IS NULL)   AS formation_dom_null,
       SUM(competition_type IS NULL)      AS type_comp_null,
       MIN(date)                          AS date_min,
       MAX(date)                          AS date_max
FROM clean_football.games;
