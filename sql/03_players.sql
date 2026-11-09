-- =====================================================================
-- 03_players.sql : nettoyage de la table players
-- Source : raw_football.players (50 149 lignes)
-- Resultat : clean_football.players (50 149 lignes)
-- =====================================================================

-- ---------- 1. CONTROLES SUR LA TABLE BRUTE ----------
SELECT COUNT(*)                                    AS total,
       COUNT(DISTINCT player_id)                   AS ids_uniques,
       SUM(player_id NOT REGEXP '^[0-9]+$')        AS id_non_numerique,
       SUM(first_name = '')                        AS prenom_vide,
       SUM(date_of_birth = '')                     AS naissance_vide,
       SUM(height_in_cm = '')                      AS taille_vide,
       SUM(CAST(NULLIF(height_in_cm,'') AS DECIMAL(5,1)) < 140) AS taille_sous_140,
       SUM(market_value_in_eur = '')               AS valeur_vide,
       SUM(contract_expiration_date = '')          AS contrat_vide
FROM raw_football.players;

-- ---------- 2. CREATION DE LA TABLE PROPRE ----------
-- Colonnes retirees : image_url, url
-- Tailles < 140 cm (13 erreurs de saisie) -> NULL
USE clean_football;

DROP TABLE IF EXISTS players;

CREATE TABLE players AS
SELECT
    CAST(player_id AS SIGNED)                              AS player_id,
    NULLIF(TRIM(first_name), '')                           AS first_name,
    NULLIF(TRIM(last_name), '')                            AS last_name,
    TRIM(name)                                             AS name,
    CAST(last_season AS SIGNED)                            AS last_season,
    CAST(current_club_id AS SIGNED)                        AS current_club_id,
    NULLIF(TRIM(player_code), '')                          AS player_code,
    NULLIF(TRIM(country_of_birth), '')                     AS country_of_birth,
    NULLIF(TRIM(city_of_birth), '')                        AS city_of_birth,
    NULLIF(TRIM(country_of_citizenship), '')               AS country_of_citizenship,
    STR_TO_DATE(NULLIF(LEFT(TRIM(date_of_birth), 10), ''), '%Y-%m-%d') AS date_of_birth,
    NULLIF(TRIM(sub_position), '')                         AS sub_position,
    NULLIF(TRIM(position), '')                             AS position,
    NULLIF(TRIM(foot), '')                                 AS foot,
    CASE WHEN NULLIF(TRIM(height_in_cm), '') IS NULL THEN NULL
         WHEN CAST(height_in_cm AS DECIMAL(6,1)) < 140 THEN NULL
         ELSE CAST(height_in_cm AS DECIMAL(6,0)) END       AS height_in_cm,
    STR_TO_DATE(NULLIF(LEFT(TRIM(contract_expiration_date), 10), ''), '%Y-%m-%d') AS contract_expiration_date,
    NULLIF(TRIM(agent_name), '')                           AS agent_name,
    CAST(NULLIF(TRIM(international_caps), '') AS DECIMAL(6,0))        AS international_caps,
    CAST(NULLIF(TRIM(international_goals), '') AS DECIMAL(6,0))       AS international_goals,
    CAST(NULLIF(TRIM(current_national_team_id), '') AS DECIMAL(10,0)) AS current_national_team_id,
    NULLIF(TRIM(current_club_domestic_competition_id), '') AS current_club_domestic_competition_id,
    NULLIF(TRIM(current_club_name), '')                    AS current_club_name,
    CAST(NULLIF(TRIM(market_value_in_eur), '') AS DECIMAL(15,0))         AS market_value_in_eur,
    CAST(NULLIF(TRIM(highest_market_value_in_eur), '') AS DECIMAL(15,0)) AS highest_market_value_in_eur
FROM raw_football.players;

ALTER TABLE players
  MODIFY player_id                  INT NOT NULL,
  MODIFY first_name                 VARCHAR(50),
  MODIFY last_name                  VARCHAR(50),
  MODIFY name                       VARCHAR(80),
  MODIFY last_season                SMALLINT UNSIGNED,
  MODIFY current_club_id            INT,
  MODIFY player_code                VARCHAR(80),
  MODIFY country_of_birth           VARCHAR(60),
  MODIFY city_of_birth              VARCHAR(100),
  MODIFY country_of_citizenship     VARCHAR(60),
  MODIFY sub_position               VARCHAR(30),
  MODIFY position                   VARCHAR(20),
  MODIFY foot                       VARCHAR(10),
  MODIFY height_in_cm               SMALLINT UNSIGNED,
  MODIFY agent_name                 VARCHAR(100),
  MODIFY international_caps         SMALLINT UNSIGNED,
  MODIFY international_goals        SMALLINT UNSIGNED,
  MODIFY current_national_team_id   INT,
  MODIFY current_club_domestic_competition_id CHAR(4),
  MODIFY current_club_name          VARCHAR(100),
  MODIFY market_value_in_eur        BIGINT UNSIGNED,
  MODIFY highest_market_value_in_eur BIGINT UNSIGNED,
  ADD PRIMARY KEY (player_id),
  ADD INDEX idx_club (current_club_id),
  ADD INDEX idx_competition (current_club_domestic_competition_id);

-- ---------- 3. VALIDATION ----------
-- Attendu : 50149 | 3164 | 49 | 4378 | 8621 | 18569 | taille_min >= 140 | 210
SELECT COUNT(*)                              AS total,
       SUM(first_name IS NULL)               AS prenom_null,
       SUM(date_of_birth IS NULL)            AS naissance_null,
       SUM(height_in_cm IS NULL)             AS taille_null,
       SUM(market_value_in_eur IS NULL)      AS valeur_null,
       SUM(contract_expiration_date IS NULL) AS contrat_null,
       MIN(height_in_cm)                     AS taille_min,
       MAX(height_in_cm)                     AS taille_max
FROM clean_football.players;
