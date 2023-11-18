DROP TABLE IF EXISTS corona_records;
DROP TABLE IF EXISTS codes_ages;
DROP TABLE IF EXISTS departements;
DROP TABLE IF EXISTS regions;

CREATE TABLE IF NOT EXISTS codes_ages(
    code INTEGER UNIQUE NOT NULL PRIMARY KEY,
    tranche_age VARCHAR NOT NULL
);

CREATE TABLE IF NOT EXISTS regions(
    id INTEGER UNIQUE NOT NULL PRIMARY KEY,
    region_name VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS departements(
    code VARCHAR(3) UNIQUE NOT NULL PRIMARY KEY,
    dep_name VARCHAR(30),
    id_region INTEGER,
    CONSTRAINT fk_region
    FOREIGN KEY(id_region) 
    REFERENCES regions(id)
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

CREATE TABLE IF NOT EXISTS corona_records(
    id SERIAL NOT NULL PRIMARY KEY,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    day INTEGER NOT NULL,
    dep VARCHAR(3) NOT NULL,
    code_tranche_age INTEGER NOT NULL,
    pass_tot FLOAT NOT NULL,
    pass_tot_h FLOAT NOT NULL, 
    pass_tot_f FLOAT NOT NULL,
    pass_corona FLOAT NOT NULL, 
    pass_corona_h FLOAT NOT NULL, 
    pass_corona_f FLOAT NOT NULL, 
    hospit_corona FLOAT NOT NULL, 
    hospit_corona_h FLOAT NOT NULL, 
    hospit_corona_f FLOAT NOT NULL, 
    CONSTRAINT fk_departement
    FOREIGN KEY(dep) 
    REFERENCES departements(code),
    CONSTRAINT fk_tranche_age
    FOREIGN KEY(code_tranche_age) 
    REFERENCES codes_ages(code)
);