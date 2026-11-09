-- =====================================================================
-- 05_transfers.sql : nettoyage de la table transfers
-- Source : raw_football.transfers (175 165 lignes)
-- Resultat : clean_football.transfers (175 165 lignes)
-- =====================================================================

-- ---------- 1. CONTROLES SUR LA TABLE BRUTE ----------
SELECT COUNT(*)                                          AS total,
       SUM(STR_TO_DATE(transfer_date, '%Y-%m-%d') IS NULL) AS date_invalide,
       SUM(transfer_date > CURDATE())                    AS date_future,
       SUM(transfer_fee = '')                            AS frais_vide,
       SUM(transfer_fee = '0' OR transfer_fee = '0.0')   AS frais_zero,
       SUM(market_value_in_eur = '')                     AS valeur_vide,
       SUM(player_name = '')                             AS nom_vide,
       SUM(from_club_id = to_club_id)                    AS meme_club
FROM raw_football.transfers;

-- ---------- 2. CREATION DE LA TABLE PROPRE ----------
-- is_future = 1 pour les transferts dates apres la creation de la table
--             (475 lignes, jusqu'en 2030) : filtrer avec WHERE is_future = 0
-- transfer_fee = 0 : transfert gratuit ; NULL : frais inconnus
-- transfer_id : cle primaire creee (la table n'a pas d'identifiant propre)
USE clean_football;

DROP TABLE IF EXISTS transfers;

CREATE TABLE transfers AS
SELECT
    CAST(player_id AS SIGNED)                                    AS player_id,
    STR_TO_DATE(TRIM(transfer_date), '%Y-%m-%d')                 AS transfer_date,
    NULLIF(TRIM(transfer_season), '')                            AS transfer_season,
    CAST(from_club_id AS SIGNED)                                 AS from_club_id,
    CAST(to_club_id AS SIGNED)                                   AS to_club_id,
    NULLIF(TRIM(from_club_name), '')                             AS from_club_name,
    NULLIF(TRIM(to_club_name), '')                               AS to_club_name,
    CAST(NULLIF(TRIM(transfer_fee), '') AS DECIMAL(15,0))        AS transfer_fee,
    CAST(NULLIF(TRIM(market_value_in_eur), '') AS DECIMAL(15,0)) AS market_value_in_eur,
    NULLIF(TRIM(player_name), '')                                AS player_name,
    CASE WHEN STR_TO_DATE(TRIM(transfer_date), '%Y-%m-%d') > CURDATE()
         THEN 1 ELSE 0 END                                       AS is_future
FROM raw_football.transfers;

ALTER TABLE transfers
  MODIFY player_id            INT NOT NULL,
  MODIFY transfer_date        DATE NOT NULL,
  MODIFY transfer_season      VARCHAR(5),
  MODIFY from_club_id         INT NOT NULL,
  MODIFY to_club_id           INT NOT NULL,
  MODIFY from_club_name       VARCHAR(100),
  MODIFY to_club_name         VARCHAR(100),
  MODIFY transfer_fee         BIGINT UNSIGNED,
  MODIFY market_value_in_eur  BIGINT UNSIGNED,
  MODIFY player_name          VARCHAR(100),
  MODIFY is_future            TINYINT UNSIGNED NOT NULL,
  ADD COLUMN transfer_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST,
  ADD INDEX idx_player (player_id),
  ADD INDEX idx_from_club (from_club_id),
  ADD INDEX idx_to_club (to_club_id),
  ADD INDEX idx_date (transfer_date);

-- ---------- 3. VALIDATION ----------
-- Attendu : 175165 | 61526 | 96085 | 68160 | 475 | 1993-07-01 | 2030-06-30 | 222000000
SELECT COUNT(*)                          AS total,
       SUM(transfer_fee IS NULL)         AS frais_null,
       SUM(transfer_fee = 0)             AS frais_zero,
       SUM(market_value_in_eur IS NULL)  AS valeur_null,
       SUM(is_future)                    AS futurs,
       MIN(transfer_date)                AS date_min,
       MAX(transfer_date)                AS date_max,
       MAX(transfer_fee)                 AS frais_max
FROM clean_football.transfers;

-- Les transferts gratuits doivent etre aussi nombreux dans la table brute (96085)
SELECT SUM(CAST(NULLIF(transfer_fee,'') AS DECIMAL(15,2)) = 0) AS frais_zero_raw
FROM raw_football.transfers;
