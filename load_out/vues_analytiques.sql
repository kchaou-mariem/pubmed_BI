
DROP VIEW IF EXISTS v_publications_par_annee; DROP VIEW IF EXISTS v_publications_par_mois; DROP VIEW IF EXISTS v_publications_par_revue; DROP VIEW IF EXISTS v_publications_par_pays_revue;
DROP VIEW IF EXISTS v_auteurs_publications; DROP VIEW IF EXISTS v_nb_auteurs_par_annee; DROP VIEW IF EXISTS v_publications_par_institution; DROP VIEW IF EXISTS v_publications_par_pays_affiliation;
DROP VIEW IF EXISTS v_collaborations_institutions; DROP VIEW IF EXISTS v_collaborations_pays; DROP VIEW IF EXISTS v_themes_mesh; DROP VIEW IF EXISTS v_mots_cles; DROP VIEW IF EXISTS v_substances;
DROP VIEW IF EXISTS v_types_publication; DROP VIEW IF EXISTS v_categories_publication;

-- Axe 1 : évolution temporelle
CREATE VIEW v_publications_par_annee AS
SELECT t.annee, SUM(f.nb_publications) AS nb_publications FROM article_fact f JOIN temps_dim t ON t.temps_key = f.temps_pub_key WHERE t.annee IS NOT NULL GROUP BY t.annee;
CREATE VIEW v_publications_par_mois AS            -- niveau « Mois » uniquement (le mois est inconnu pour les publications au niveau « Année »)
SELECT t.annee, t.mois, t.libelle_mois, t.trimestre, SUM(f.nb_publications) AS nb_publications
FROM article_fact f JOIN temps_dim t ON t.temps_key = f.temps_pub_key WHERE t.niveau = 'Mois' GROUP BY t.annee, t.mois, t.libelle_mois, t.trimestre;
-- Axe 2 : revues
CREATE VIEW v_publications_par_revue AS
SELECT r.revue_key, r.nlm_id, r.titre AS revue, p.pays AS pays_editeur, SUM(f.nb_publications) AS nb_publications, ROUND(AVG(f.nb_auteurs), 2) AS nb_moyen_auteurs
FROM article_fact f JOIN revue_dim r USING (revue_key) JOIN pays_dim p ON p.pays_key = r.pays_key GROUP BY r.revue_key, r.nlm_id, r.titre, p.pays;
CREATE VIEW v_publications_par_pays_revue AS
SELECT p.pays AS pays_editeur, SUM(f.nb_publications) AS nb_publications, COUNT(DISTINCT r.revue_key) AS nb_revues
FROM article_fact f JOIN revue_dim r USING (revue_key) JOIN pays_dim p ON p.pays_key = r.pays_key GROUP BY p.pays;
-- Axe 3 : auteurs, affiliations, collaborations
CREATE VIEW v_auteurs_publications AS
SELECT a.auteur_key, a.nom, a.initiales, a.type_auteur, COUNT(DISTINCT b.article_key) AS nb_publications, SUM(b.est_premier) AS nb_fois_premier, SUM(b.est_dernier) AS nb_fois_dernier
FROM article_auteur_bridge b JOIN auteur_dim a USING (auteur_key) GROUP BY a.auteur_key, a.nom, a.initiales, a.type_auteur;
CREATE VIEW v_nb_auteurs_par_annee AS
SELECT t.annee, ROUND(AVG(f.nb_auteurs), 2) AS nb_moyen_auteurs, ROUND(AVG(f.nb_auteurs - f.nb_collectifs), 2) AS nb_moyen_auteurs_individuels, SUM(f.nb_publications) AS nb_publications
FROM article_fact f JOIN temps_dim t ON t.temps_key = f.temps_pub_key WHERE t.annee IS NOT NULL GROUP BY t.annee;
CREATE VIEW v_publications_par_institution AS
SELECT i.institution_key, i.libelle AS institution, p.pays, COUNT(DISTINCT b.article_key) AS nb_publications, COUNT(DISTINCT b.auteur_key) AS nb_auteurs
FROM article_institution_bridge b JOIN institution_dim i USING (institution_key) JOIN pays_dim p ON p.pays_key = i.pays_key GROUP BY i.institution_key, i.libelle, p.pays;
CREATE VIEW v_publications_par_pays_affiliation AS
SELECT p.pays, COUNT(DISTINCT b.article_key) AS nb_publications FROM article_pays_bridge b JOIN pays_dim p USING (pays_key) GROUP BY p.pays;
CREATE VIEW v_collaborations_institutions AS      -- paires d'institutions présentes dans une même publication
WITH ia AS (SELECT DISTINCT article_key, institution_key FROM article_institution_bridge)
SELECT i1.libelle AS institution_1, i2.libelle AS institution_2, COUNT(*) AS nb_publications_communes
FROM ia a JOIN ia b ON a.article_key = b.article_key AND a.institution_key < b.institution_key
JOIN institution_dim i1 ON i1.institution_key = a.institution_key JOIN institution_dim i2 ON i2.institution_key = b.institution_key GROUP BY a.institution_key, b.institution_key;
CREATE VIEW v_collaborations_pays AS              -- paires de pays présentes dans une même publication
SELECT p1.pays AS pays_1, p2.pays AS pays_2, COUNT(*) AS nb_publications_communes
FROM article_pays_bridge a JOIN article_pays_bridge b ON a.article_key = b.article_key AND a.pays_key < b.pays_key
JOIN pays_dim p1 ON p1.pays_key = a.pays_key JOIN pays_dim p2 ON p2.pays_key = b.pays_key WHERE a.pays_key <> 0 AND b.pays_key <> 0 GROUP BY a.pays_key, b.pays_key;
-- Axe 4 : thématiques
CREATE VIEW v_themes_mesh AS
SELECT m.mesh_key, m.descripteur, m.est_geographique, COUNT(DISTINCT b.article_key) AS nb_publications, SUM(b.majeur) AS nb_fois_majeur
FROM article_mesh_bridge b JOIN mesh_dim m USING (mesh_key) GROUP BY m.mesh_key, m.descripteur, m.est_geographique;
CREATE VIEW v_mots_cles AS
SELECT k.motcle_key, k.libelle AS mot_cle, COUNT(DISTINCT b.article_key) AS nb_publications FROM article_motcle_bridge b JOIN motcle_dim k USING (motcle_key) GROUP BY k.motcle_key, k.libelle;
CREATE VIEW v_substances AS
SELECT s.substance_key, s.substance, s.registre, COUNT(DISTINCT b.article_key) AS nb_publications FROM article_substance_bridge b JOIN substance_dim s USING (substance_key) GROUP BY s.substance_key, s.substance, s.registre;
-- Axe 5 : types de publication
CREATE VIEW v_types_publication AS
SELECT t.type_key, t.libelle AS type_publication, COUNT(DISTINCT b.article_key) AS nb_publications FROM article_type_bridge b JOIN type_publication_dim t USING (type_key) GROUP BY t.type_key, t.libelle;
CREATE VIEW v_categories_publication AS
SELECT c.categorie, SUM(f.nb_publications) AS nb_publications FROM article_fact f JOIN categorie_dim c USING (categorie_key) GROUP BY c.categorie;
