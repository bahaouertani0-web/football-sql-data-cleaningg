-- =====================================================================
-- 07_competitions.sql : nettoyage de la table competitions
-- Source : raw_football.competitions (65 lignes)
-- Resultat : clean_football.competitions (65 lignes)
-- =====================================================================

-- ---------- 1. CONTROLES SUR LA TABLE BRUTE ----------
SELECT COUNT(*)                                  AS total,
       COUNT(DISTINCT competition_id)            AS ids_uniques,
       SUM(competition_id IS NULL)               AS id_null,
       SUM(country_id = '-1')                    AS pays_moins_un,
       SUM(country_name = '')                    AS pays_nom_vide,
       SUM(domestic_league_code = '')            AS ligue_vide,
       SUM(total_clubs = '')                     AS clubs_vide,
       SUM(sub_type = '')                        AS sous_type_vide,
       SUM(type = '')                            AS type_vide
FROM raw_football.competitions;

-- ---------- 2. CREATION DE LA TABLE PROPRE ----------
-- Colonne retiree : url
-- country_id = -1 (competitions internationales) -> NULL
USE clean_football;

DROP TABLE IF EXISTS competitions;

CREATE TABLE competitions AS
SELECT
    TRIM(competition_id)                                      AS competition_id,
    NULLIF(TRIM(competition_code), '')                        AS competition_code,
    NULLIF(TRIM(name), '')                                    AS name,
    NULLIF(TRIM(sub_type), '')                                AS sub_type,
    NULLIF(TRIM(type), '')                                    AS type,
    NULLIF(CAST(NULLIF(TRIM(country_id), '') AS DECIMAL(6,0)), -1) AS country_id,
    NULLIF(TRIM(country_name), '')                            AS country_name,
    NULLIF(TRIM(domestic_league_code), '')                    AS domestic_league_code,
    NULLIF(TRIM(confederation), '')                           AS confederation,
    CAST(NULLIF(TRIM(total_clubs), '') AS DECIMAL(4,0))       AS total_clubs
FROM raw_football.competitions;

ALTER TABLE competitions
  MODIFY competition_id        CHAR(4) NOT NULL,
  MODIFY competition_code      VARCHAR(40),
  MODIFY name                  VARCHAR(40),
  MODIFY sub_type              VARCHAR(40),
  MODIFY type                  VARCHAR(30),
  MODIFY country_id            INT,
  MODIFY country_name          VARCHAR(20),
  MODIFY domestic_league_code  CHAR(4),
  MODIFY confederation         VARCHAR(10),
  MODIFY total_clubs           TINYINT UNSIGNED,
  ADD PRIMARY KEY (competition_id),
  ADD INDEX idx_country (country_id);

-- ---------- 3. VALIDATION ----------
-- Attendu : 65 | 5 | 12 | 12 | 12 | 15
SELECT COUNT(*)                          AS total,
       COUNT(DISTINCT type)              AS types_distincts,
       SUM(country_id IS NULL)           AS pays_id_null,
       SUM(country_name IS NULL)         AS pays_nom_null,
       SUM(domestic_league_code IS NULL) AS ligue_null,
       SUM(total_clubs IS NULL)          AS clubs_null
FROM clean_football.competitions;

-- Matchs dont la competition est absente de la table competitions : attendu 1214
SELECT COUNT(*) AS matchs_sans_competition
FROM clean_football.games g
LEFT JOIN clean_football.competitions c
       ON g.competition_id = c.competition_id
WHERE c.competition_id IS NULL;
