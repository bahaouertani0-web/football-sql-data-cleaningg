-- =====================================================================
-- 01_appearances.sql : nettoyage de la table appearances
-- Source : raw_football.appearances (1 894 350 lignes)
-- Resultat : clean_football.appearances (1 894 350 lignes)
-- =====================================================================

-- ---------- 1. CONTROLES SUR LA TABLE BRUTE ----------

-- Unicite de l'identifiant
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT appearance_id) AS unique_appearances
FROM raw_football.appearances;

-- Valeurs NULL dans les colonnes d'identification
SELECT SUM(appearance_id IS NULL) AS missing_appearance_id,
       SUM(game_id IS NULL)       AS missing_game_id,
       SUM(player_id IS NULL)     AS missing_player_id,
       SUM(date IS NULL)          AS missing_date
FROM raw_football.appearances;

-- Chaines vides (differentes de NULL)
SELECT SUM(player_name = '')    AS empty_player_names,
       SUM(competition_id = '') AS empty_competition_ids,
       SUM(goals = '')          AS empty_goals,
       SUM(assists = '')        AS empty_assists,
       SUM(minutes_played = '') AS empty_minutes
FROM raw_football.appearances;

-- Valeurs numeriques invalides
SELECT * FROM raw_football.appearances
WHERE goals NOT REGEXP '^[0-9]+$'
   OR assists NOT REGEXP '^[0-9]+$'
   OR minutes_played NOT REGEXP '^[0-9]+$'
LIMIT 10;

-- Dates invalides
SELECT * FROM raw_football.appearances
WHERE STR_TO_DATE(date, '%Y-%m-%d') IS NULL
LIMIT 10;

-- Minutes jouees minimales et maximales (0 et 148 : valeurs plausibles, conservees)
SELECT MIN(CAST(minutes_played AS UNSIGNED)) AS min_minutes,
       MAX(CAST(minutes_played AS UNSIGNED)) AS max_minutes
FROM raw_football.appearances;

-- ---------- 2. CREATION DE LA TABLE PROPRE ----------

USE clean_football;

DROP TABLE IF EXISTS appearances;

CREATE TABLE appearances AS
SELECT
    CAST(appearance_id AS CHAR(50))         AS appearance_id,
    CAST(game_id AS SIGNED)                 AS game_id,
    CAST(player_id AS SIGNED)               AS player_id,
    CAST(player_club_id AS SIGNED)          AS player_club_id,
    CAST(player_current_club_id AS SIGNED)  AS player_current_club_id,
    STR_TO_DATE(date, '%Y-%m-%d')           AS date,
    NULLIF(TRIM(player_name), '')           AS player_name,
    competition_id,
    CAST(yellow_cards AS SIGNED)            AS yellow_cards,
    CAST(red_cards AS SIGNED)               AS red_cards,
    CAST(goals AS SIGNED)                   AS goals,
    CAST(assists AS SIGNED)                 AS assists,
    CAST(minutes_played AS SIGNED)          AS minutes_played
FROM raw_football.appearances;

-- ---------- 3. FINITION : -1 -> NULL, TYPES, CLE PRIMAIRE, INDEX ----------

-- Desactive le mode "safe update" de Workbench (erreur 1175)
SET SQL_SAFE_UPDATES = 0;

-- -1 = club actuel inconnu -> NULL
UPDATE appearances
SET player_current_club_id = NULL
WHERE player_current_club_id = -1;

ALTER TABLE appearances
  MODIFY appearance_id   VARCHAR(20) NOT NULL,
  MODIFY game_id         INT NOT NULL,
  MODIFY player_id       INT NOT NULL,
  MODIFY player_club_id  INT NOT NULL,
  MODIFY competition_id  CHAR(4) NOT NULL,
  MODIFY yellow_cards    TINYINT UNSIGNED,
  MODIFY red_cards       TINYINT UNSIGNED,
  MODIFY goals           TINYINT UNSIGNED,
  MODIFY assists         TINYINT UNSIGNED,
  MODIFY minutes_played  SMALLINT UNSIGNED,
  ADD PRIMARY KEY (appearance_id),
  ADD INDEX idx_game (game_id),
  ADD INDEX idx_player (player_id),
  ADD INDEX idx_club (player_club_id);

-- ---------- 4. VALIDATION ----------
-- Attendu : 1 894 350 lignes, 2 valeurs inconnues, 0 valeur -1
SELECT COUNT(*) AS total_rows,
       SUM(player_current_club_id IS NULL) AS clubs_inconnus,
       SUM(player_current_club_id = -1)    AS encore_moins_un
FROM clean_football.appearances;
