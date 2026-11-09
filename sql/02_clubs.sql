-- =====================================================================
-- 02_clubs.sql : nettoyage de la table clubs
-- Source : raw_football.clubs (796 lignes)
-- Resultat : clean_football.clubs (796 lignes)
-- =====================================================================

-- ---------- 1. CONTROLES SUR LA TABLE BRUTE ----------
SELECT COUNT(*)                                AS total,
       COUNT(DISTINCT club_id)                 AS ids_uniques,
       SUM(club_id NOT REGEXP '^[0-9]+$')      AS id_non_numerique,
       SUM(total_market_value = '')            AS valeur_marche_vide,
       SUM(coach_name = '')                    AS coach_vide,
       SUM(average_age = '')                   AS age_vide,
       SUM(average_age = '0')                  AS age_zero,
       SUM(foreigners_percentage = '')         AS pct_etrangers_vide,
       SUM(squad_size = '0')                   AS squad_zero,
       SUM(stadium_seats = '0')                AS stade_zero
FROM raw_football.clubs;

-- Formats de net_transfer_record (ex. +€2.69m, €-25.00m, +€40k)
SELECT net_transfer_record, COUNT(*) AS nb
FROM raw_football.clubs
GROUP BY net_transfer_record
ORDER BY nb DESC
LIMIT 10;

-- ---------- 2. CREATION DE LA TABLE PROPRE ----------
-- Colonnes retirees : total_market_value (vide partout), filename, url
-- net_transfer_record (texte) converti en euros : net_transfer_eur
USE clean_football;

DROP TABLE IF EXISTS clubs;

CREATE TABLE clubs AS
SELECT
    CAST(club_id AS SIGNED)                                      AS club_id,
    TRIM(club_code)                                              AS club_code,
    TRIM(name)                                                   AS name,
    NULLIF(TRIM(domestic_competition_id), '')                    AS domestic_competition_id,
    NULLIF(CAST(squad_size AS SIGNED), 0)                        AS squad_size,
    NULLIF(CAST(NULLIF(TRIM(average_age), '') AS DECIMAL(4,1)), 0) AS average_age,
    CASE WHEN CAST(squad_size AS SIGNED) = 0 THEN NULL
         ELSE CAST(foreigners_number AS SIGNED) END              AS foreigners_number,
    CAST(NULLIF(TRIM(foreigners_percentage), '') AS DECIMAL(5,1)) AS foreigners_percentage,
    CASE WHEN CAST(squad_size AS SIGNED) = 0 THEN NULL
         ELSE CAST(national_team_players AS SIGNED) END          AS national_team_players,
    NULLIF(TRIM(stadium_name), '')                               AS stadium_name,
    NULLIF(CAST(stadium_seats AS SIGNED), 0)                     AS stadium_seats,
    CASE WHEN TRIM(net_transfer_record) = '' THEN NULL
         ELSE (CASE WHEN net_transfer_record LIKE '%-%' THEN -1 ELSE 1 END)
              * CAST(REGEXP_REPLACE(net_transfer_record, '[^0-9.]', '') AS DECIMAL(12,2))
              * (CASE RIGHT(TRIM(net_transfer_record), 1)
                   WHEN 'm' THEN 1000000
                   WHEN 'k' THEN 1000
                   ELSE 1 END)
    END                                                          AS net_transfer_eur,
    NULLIF(TRIM(coach_name), '')                                 AS coach_name,
    CAST(last_season AS SIGNED)                                  AS last_season
FROM raw_football.clubs;

ALTER TABLE clubs
  MODIFY club_id                 INT NOT NULL,
  MODIFY club_code               VARCHAR(60),
  MODIFY name                    VARCHAR(100),
  MODIFY domestic_competition_id CHAR(4),
  MODIFY squad_size              SMALLINT UNSIGNED,
  MODIFY foreigners_number       SMALLINT UNSIGNED,
  MODIFY national_team_players   SMALLINT UNSIGNED,
  MODIFY stadium_name            VARCHAR(100),
  MODIFY stadium_seats           INT UNSIGNED,
  MODIFY net_transfer_eur        BIGINT,
  MODIFY coach_name              VARCHAR(100),
  MODIFY last_season             SMALLINT UNSIGNED,
  ADD PRIMARY KEY (club_id),
  ADD INDEX idx_competition (domestic_competition_id);

-- ---------- 3. VALIDATION ----------
-- Attendu : 796 | 393 | 42 | 42 | 1 | 0
SELECT COUNT(*)                          AS total,
       SUM(coach_name IS NULL)           AS coach_null,
       SUM(average_age IS NULL)          AS age_null,
       SUM(squad_size IS NULL)           AS squad_null,
       SUM(stadium_seats IS NULL)        AS stade_null,
       SUM(net_transfer_eur IS NULL)     AS transfert_null
FROM clean_football.clubs;

-- Le top 5 doit afficher des millions d'euros (ex. 144000000)
SELECT name, net_transfer_eur
FROM clean_football.clubs
ORDER BY net_transfer_eur DESC
LIMIT 5;
