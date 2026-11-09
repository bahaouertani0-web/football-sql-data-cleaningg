-- =====================================================================
-- 00_setup.sql : creation des bases de donnees
-- =====================================================================
-- raw_football   : donnees brutes importees depuis les CSV (jamais modifiees)
-- clean_football : donnees nettoyees (creees par les scripts 01 a 07)
--
-- Import des CSV dans raw_football (MySQL Workbench) :
--   clic droit sur le schema raw_football > Table Data Import Wizard
--   Importer les 7 fichiers : competitions, clubs, players, games,
--   appearances, player_valuations, transfers.
--   Toutes les colonnes sont importees en VARCHAR (texte) : la conversion
--   vers les bons types est faite dans les scripts de nettoyage.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS raw_football;
CREATE DATABASE IF NOT EXISTS clean_football;
