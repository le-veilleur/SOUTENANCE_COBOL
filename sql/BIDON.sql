SET CURRENT SQLID = 'API8';
-- SET CURRENT SQLID = 'API3';
-- Suppression des tables (dans l'ordre inverse de création)
-- pour respecter les contraintes de clés étrangères

-- 1. Supprimer la table OPE (qui référence COMPTE)
-- DROP TABLE OPE;

-- 2. Supprimer la table COMPTE (qui référence CLIENT)
-- DROP TABLE COMPTE;

-- 3. Supprimer la table CLIENT
-- DROP TABLE CLIENT;

-- Vérification que les tables ont été supprimées
-- (ces commandes échoueront si les tables n'existent plus)
-- SELECT * FROM CLIENT;
-- SELECT * FROM COMPTE;
-- SELECT * FROM OPE;
