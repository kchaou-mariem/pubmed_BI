
CREATE TABLE IF NOT EXISTS pays_dim (
    pays_key INTEGER PRIMARY KEY, pays TEXT NOT NULL UNIQUE);
CREATE TABLE IF NOT EXISTS statut_dim (
    statut_key INTEGER PRIMARY KEY, statut_citation TEXT NOT NULL UNIQUE);
CREATE TABLE IF NOT EXISTS categorie_dim (
    categorie_key INTEGER PRIMARY KEY, categorie TEXT NOT NULL UNIQUE);
CREATE TABLE IF NOT EXISTS langue_dim (
    langue_key INTEGER PRIMARY KEY, code_langue TEXT NOT NULL UNIQUE, libelle TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS type_publication_dim (
    type_key INTEGER PRIMARY KEY, ui_type TEXT NOT NULL UNIQUE, libelle TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS mesh_dim (
    mesh_key INTEGER PRIMARY KEY, ui_mesh TEXT NOT NULL UNIQUE, descripteur TEXT NOT NULL,
    est_geographique INTEGER NOT NULL CHECK (est_geographique IN (0, 1)));
CREATE TABLE IF NOT EXISTS motcle_dim (
    motcle_key INTEGER PRIMARY KEY, cle_motcle TEXT NOT NULL UNIQUE, libelle TEXT NOT NULL, nb_publications INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS substance_dim (
    substance_key INTEGER PRIMARY KEY, ui_substance TEXT NOT NULL UNIQUE, substance TEXT NOT NULL, registre TEXT, nb_publications INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS temps_dim (
    temps_key INTEGER PRIMARY KEY,                       -- AAAAMM00 (mois), AAAA0000 (année seule), AAAAMMJJ (jour), 0 = inconnu
    annee INTEGER, mois INTEGER CHECK (mois BETWEEN 1 AND 12), jour INTEGER,
    niveau TEXT NOT NULL CHECK (niveau IN ('Jour', 'Mois', 'Année', 'Inconnu')), libelle_mois TEXT, trimestre INTEGER);
CREATE TABLE IF NOT EXISTS auteur_dim (
    auteur_key INTEGER PRIMARY KEY, cle_auteur TEXT NOT NULL UNIQUE,
    type_auteur TEXT NOT NULL CHECK (type_auteur IN ('Individuel', 'Collectif')),
    nom TEXT NOT NULL, prenom_frequent TEXT, initiales TEXT, orcid TEXT, nb_prenoms_distincts INTEGER, nb_publications INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS revue_dim (
    revue_key INTEGER PRIMARY KEY, nlm_id TEXT NOT NULL UNIQUE, titre TEXT NOT NULL, abrev TEXT, issn TEXT, issn_liaison TEXT,
    pays_key INTEGER NOT NULL REFERENCES pays_dim (pays_key));                      -- sous-dimension : pays de l'éditeur
CREATE TABLE IF NOT EXISTS institution_dim (
    institution_key INTEGER PRIMARY KEY, cle_institution TEXT NOT NULL UNIQUE, libelle TEXT NOT NULL,
    pays_key INTEGER NOT NULL REFERENCES pays_dim (pays_key), nb_publications INTEGER NOT NULL);   -- sous-dimension : pays de l'institution
CREATE TABLE IF NOT EXISTS article_dim (
    article_key INTEGER PRIMARY KEY, pmid TEXT NOT NULL UNIQUE, titre TEXT NOT NULL,
    titre_traduit INTEGER NOT NULL CHECK (titre_traduit IN (0, 1)), doi TEXT, resume_court TEXT,
    a_resume INTEGER NOT NULL CHECK (a_resume IN (0, 1)), est_indexe_mesh INTEGER NOT NULL CHECK (est_indexe_mesh IN (0, 1)),
    source_date_pub TEXT NOT NULL, source_fichier TEXT NOT NULL, niveau_reparation TEXT NOT NULL);

-- Tables de liaison (relations N-N de l'article)
-- Table de faits : clés étrangères + mesures uniquement
CREATE TABLE IF NOT EXISTS article_fact (
    article_key INTEGER PRIMARY KEY REFERENCES article_dim (article_key),
    revue_key INTEGER NOT NULL REFERENCES revue_dim (revue_key),
    temps_pub_key INTEGER NOT NULL REFERENCES temps_dim (temps_key), temps_creation_key INTEGER NOT NULL REFERENCES temps_dim (temps_key),
    categorie_key INTEGER NOT NULL REFERENCES categorie_dim (categorie_key), statut_key INTEGER NOT NULL REFERENCES statut_dim (statut_key),
    langue_key INTEGER NOT NULL REFERENCES langue_dim (langue_key), pays_premier_auteur_key INTEGER NOT NULL REFERENCES pays_dim (pays_key),
    nb_publications INTEGER NOT NULL CHECK (nb_publications = 1),
    nb_auteurs INTEGER NOT NULL CHECK (nb_auteurs >= 0), nb_collectifs INTEGER NOT NULL CHECK (nb_collectifs >= 0),
    nb_mesh INTEGER NOT NULL CHECK (nb_mesh >= 0), nb_mesh_majeurs INTEGER NOT NULL CHECK (nb_mesh_majeurs >= 0),
    nb_mots_cles INTEGER NOT NULL CHECK (nb_mots_cles >= 0), nb_pays INTEGER NOT NULL CHECK (nb_pays >= 0),
    nb_substances INTEGER NOT NULL CHECK (nb_substances >= 0), nb_institutions INTEGER NOT NULL CHECK (nb_institutions >= 0),
    mots_titre INTEGER NOT NULL CHECK (mots_titre >= 0), mots_resume INTEGER NOT NULL CHECK (mots_resume >= 0));

CREATE TABLE IF NOT EXISTS article_auteur_bridge (
    article_key INTEGER NOT NULL REFERENCES article_fact (article_key), auteur_key INTEGER NOT NULL REFERENCES auteur_dim (auteur_key),
    rang INTEGER NOT NULL CHECK (rang >= 1), est_premier INTEGER NOT NULL CHECK (est_premier IN (0, 1)), est_dernier INTEGER NOT NULL CHECK (est_dernier IN (0, 1)),
    PRIMARY KEY (article_key, auteur_key));
CREATE TABLE IF NOT EXISTS article_mesh_bridge (
    article_key INTEGER NOT NULL REFERENCES article_fact (article_key), mesh_key INTEGER NOT NULL REFERENCES mesh_dim (mesh_key),
    majeur INTEGER NOT NULL CHECK (majeur IN (0, 1)), PRIMARY KEY (article_key, mesh_key));
CREATE TABLE IF NOT EXISTS article_motcle_bridge (
    article_key INTEGER NOT NULL REFERENCES article_fact (article_key), motcle_key INTEGER NOT NULL REFERENCES motcle_dim (motcle_key),
    PRIMARY KEY (article_key, motcle_key));
CREATE TABLE IF NOT EXISTS article_type_bridge (
    article_key INTEGER NOT NULL REFERENCES article_fact (article_key), type_key INTEGER NOT NULL REFERENCES type_publication_dim (type_key),
    PRIMARY KEY (article_key, type_key));
CREATE TABLE IF NOT EXISTS article_langue_bridge (
    article_key INTEGER NOT NULL REFERENCES article_fact (article_key), langue_key INTEGER NOT NULL REFERENCES langue_dim (langue_key),
    est_principale INTEGER NOT NULL CHECK (est_principale IN (0, 1)), PRIMARY KEY (article_key, langue_key));
CREATE TABLE IF NOT EXISTS article_pays_bridge (
    article_key INTEGER NOT NULL REFERENCES article_fact (article_key), pays_key INTEGER NOT NULL REFERENCES pays_dim (pays_key),
    PRIMARY KEY (article_key, pays_key));
CREATE TABLE IF NOT EXISTS article_substance_bridge (
    article_key INTEGER NOT NULL REFERENCES article_fact (article_key), substance_key INTEGER NOT NULL REFERENCES substance_dim (substance_key),
    PRIMARY KEY (article_key, substance_key));
CREATE TABLE IF NOT EXISTS article_institution_bridge (                          -- binaire : article × institution (aucune clé d'une autre dimension)
    article_key INTEGER NOT NULL REFERENCES article_fact (article_key), institution_key INTEGER NOT NULL REFERENCES institution_dim (institution_key),
    PRIMARY KEY (article_key, institution_key));

-- Index sur les clés étrangères (jointures et agrégations)
CREATE INDEX IF NOT EXISTS ix_fact_revue ON article_fact (revue_key);
CREATE INDEX IF NOT EXISTS ix_fact_temps_pub ON article_fact (temps_pub_key);
CREATE INDEX IF NOT EXISTS ix_fact_temps_creation ON article_fact (temps_creation_key);
CREATE INDEX IF NOT EXISTS ix_fact_categorie ON article_fact (categorie_key);
CREATE INDEX IF NOT EXISTS ix_fact_pays_premier ON article_fact (pays_premier_auteur_key);
CREATE INDEX IF NOT EXISTS ix_auteur_bridge_auteur ON article_auteur_bridge (auteur_key);
CREATE INDEX IF NOT EXISTS ix_mesh_bridge_mesh ON article_mesh_bridge (mesh_key);
CREATE INDEX IF NOT EXISTS ix_motcle_bridge_motcle ON article_motcle_bridge (motcle_key);
CREATE INDEX IF NOT EXISTS ix_type_bridge_type ON article_type_bridge (type_key);
CREATE INDEX IF NOT EXISTS ix_pays_bridge_pays ON article_pays_bridge (pays_key);
CREATE INDEX IF NOT EXISTS ix_substance_bridge_substance ON article_substance_bridge (substance_key);
CREATE INDEX IF NOT EXISTS ix_institution_bridge_inst ON article_institution_bridge (institution_key);
CREATE INDEX IF NOT EXISTS ix_revue_pays ON revue_dim (pays_key);
CREATE INDEX IF NOT EXISTS ix_institution_pays ON institution_dim (pays_key);

-- Journal du chargement (BF09)
CREATE TABLE IF NOT EXISTS etl_log (
    run_id TEXT NOT NULL, table_name TEXT NOT NULL, lignes_source INTEGER NOT NULL, lignes_chargees INTEGER NOT NULL,
    duree_s REAL NOT NULL, statut TEXT NOT NULL, horodatage TEXT NOT NULL);
