DROP TABLE IF EXISTS corona;
DROP TABLE IF EXISTS codes_ages;
DROP TABLE IF EXISTS departements;
DROP TABLE IF EXISTS nomenclature_sos_medecins;

CREATE TABLE IF NOT EXISTS codes_ages(
    code INTEGER UNIQUE NOT NULL PRIMARY KEY,
    tranche_age VARCHAR NOT NULL
);

CREATE TABLE IF NOT EXISTS departements(
    num_dep VARCHAR(2) UNIQUE NOT NULL PRIMARY KEY,
    dep_name VARCHAR(30),
    region_name VARCHAR(40)
);

--nomenclature 
-- CREATE TABLE IF NOT EXISTS nomenclature_sos_medecins(
--     id SERIAL NOT NULL PRIMARY KEY,
--     colonne VARCHAR(10),
--     metadata_type VARCHAR(30),
--     description_fr VARCHAR(20),
--     description_en VARCHAR(20),
--     exemple VARCHAR(30)
-- );   

CREATE TABLE IF NOT EXISTS corona(
    id SERIAL NOT NULL PRIMARY KEY,
    departement VARCHAR(2),
    date_de_passage DATE NOT NULL,
    tranche_age INTEGER NOT NULL,
    nbre_pass_corona INTEGER NOT NULL, 
    nbre_pass_tot INTEGER NOT NULL, 
    nbre_hospit_corona INTEGER NOT NULL, 
    nbre_pass_corona_h INTEGER NOT NULL, 
    nbre_pass_corona_f INTEGER NOT NULL, 
    nbre_pass_tot_h INTEGER NOT NULL, 
    nbre_pass_tot_f INTEGER NOT NULL, 
    nbre_hospit_corona_h INTEGER NOT NULL, 
    nbre_hospit_corona_f INTEGER NOT NULL, 
    nbre_acte_corona INTEGER NOT NULL, 
    nbre_acte_tot INTEGER NOT NULL,
    nbre_acte_corona_h INTEGER NOT NULL, 
    nbre_acte_corona_f INTEGER NOT NULL, 
    nbre_acte_tot_h INTEGER NOT NULL, 
    nbre_acte_tot_f INTEGER NOT NULL,
    CONSTRAINT fk_departement
    FOREIGN KEY(departement) 
    REFERENCES departements(num_dep),
    CONSTRAINT fk_tranche_age
    FOREIGN KEY(tranche_age) 
    REFERENCES codes_ages(code)
);