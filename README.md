# projet-data-warehouse

Projet entrepot de données Sup De Vinci

## Nos objectifs :

Ce projet a pour but la mise en place d'un DAG Airflow permettant :

- D'extraire des données des sources disponibles sous data\raw
- De les transformer, c'est à dire de les nettoyer afin d'avoir des données de bonne qualité
- De créer les tables d'un entrepot de données
- D'alimenter notre entrepot de données

## Comment lancer notre projet ?

todo Gaelle

## Choix des traitements de données

todo Gaelle

## Les analyses possibles

Plusieurs pistes sont possibles pour l'analyse de ces données :

- Quel est le pourcentage de passages aux urgences pour suspicion de covid-19 par rapport au nombre de passages total, pour les personnes agées de plus de 65 ans, en 2023 ?
    ```sql
    SELECT
        CASE
            WHEN SUM(pass_tot) = 0 THEN 0
            ELSE SUM(pass_corona) / SUM(pass_tot) * 100
        END AS pourcentage
    FROM
        corona_records
        JOIN
            codes_ages
            USING (code_tranche_age)
    WHERE
          code_tranche_age IN (5, 6)
      AND year = 2023;
    ```

    | pourcentage               |
    |---------------------------|
    | 1.21                      |


- Quel est le pourcentage de passages aux urgences pour suspicion de covid-19 par rapport au nombre de passages total, par tranche d’âge en 2022 ?
    ```sql
    SELECT
        codes_ages.code_tranche_age,
        codes_ages.tranche_age,
        CASE
            WHEN SUM(pass_tot) = 0 THEN 0
            ELSE SUM(pass_corona) / SUM(pass_tot) * 100
        END AS pourcentage
    FROM
        corona_records
        JOIN
            codes_ages
            USING (code_tranche_age)
    WHERE
        year = 2022
    GROUP BY
        codes_ages.code_tranche_age,
        codes_ages.tranche_age
    ORDER BY
        codes_ages.code_tranche_age;
    ```

    | code_tranche_age | tranche_age | pourcentage               |
    | ---------------- | ------------| ------------------------- |
    | 0                | Tout âge    | 1.22                      |
    | 1                | 0-4 ans     | 0.61                      |
    | 2                | 5-14 ans    | 0.08                      |
    | 3                | 15-44 ans   | 0.44                      |
    | 4                | 45-64 ans   | 0.88                      |
    | 5                | 65-74 ans   | 1.98                      |
    | 6                | 75 et plus  | 3.65                      |

- Quel est le pourcentage de passages aux urgences pour suspicion de covid-19 par rapport au nombre de passages total pour les hommes par an et par département ?
    ```sql
    SELECT
        year,
        departements.libelle,
        CASE
            WHEN SUM(pass_tot_h) = 0 THEN 0
            ELSE SUM(pass_corona_h) / SUM(pass_tot_h) * 100
        END AS pourcentage
    FROM
        corona_records
        INNER JOIN
            departements
            ON corona_records.dep = departements.code
    GROUP BY
        year, departements.libelle
    ORDER BY
        year, departements.libelle;
    ```

    | year | libelle                  | pourcentage               |
    |------|--------------------------|---------------------------|
    | 2022 | Ain                      | 1.25                      |
    | 2022 | Aisne                    | 1.69                      |
    | 2022 | Allier                   | 1.97                      |
    | 2022 | Alpes-de-Haute-Provence  | 2.80                      |
    | 2022 | Alpes-Maritimes          | 1.20                      |
    | 2022 | Ardèche                  | 1.25                      |
    | 2022 | Ardennes                 | 0.73                      |
    | 2022 | Ariège                   | 1.42                      |
    | ...  | ...                      | ...                       |


- Quel est le pourcentage de passages aux urgences pour suspicion de covid-19 par rapport au nombre de passages total pour les femmes par an et par département ?
    ```sql
    SELECT
        year,
        departements.libelle,
        CASE
            WHEN SUM(pass_tot) = 0 THEN 0
            ELSE SUM(pass_corona) / SUM(pass_tot) * 100
        END AS pourcentage
    FROM
        corona_records
        INNER JOIN
            departements
            ON corona_records.dep = departements.code
    GROUP BY
        year, departements.libelle
    ORDER BY
        year, departements.libelle;
    ```

    | year | libelle                 | pourcentage               |
    |------|-------------------------|---------------------------|
    | 2022 | Ain                     | 1.22                      |
    | 2022 | Aisne                   | 1.67                      |
    | 2022 | Allier                  | 1.92                      |
    | 2022 | Alpes-de-Haute-Provence | 2.16                      |
    | 2022 | Alpes-Maritimes         | 1.30                      |
    | 2022 | Ardèche                 | 1.87                      |
    | 2022 | Ardennes                | 0.78                      |
    | 2022 | Ariège                  | 1.45                      |
    | ... | ... | ... |


- Quel est le pourcentage de passages aux urgences pour suspicion de covid-19 par rapport au nombre de passages total, par mois et par région ?
    ```sql
    SELECT
        year,
        month,
        regions.libelle,
        CASE
            WHEN SUM(pass_tot) = 0 THEN 0
            ELSE SUM(pass_corona) / SUM(pass_tot) * 100
        END AS pourcentage
    FROM
        corona_records
        INNER JOIN
            departements
            ON corona_records.dep = departements.code
        INNER JOIN
            regions
            ON departements.code_region = regions.code
    GROUP BY
        year, month, regions.libelle
    ORDER BY
        year, month;
    ```

    | year | month | libelle                   | pourcentage               |
    |------|-------|---------------------------|---------------------------|
    | 2022 | 12    | Corse                     | 1.67                      |
    | 2022 | 12    | Auvergne-Rhône-Alpes       | 1.23                      |
    | 2022 | 12    | Hauts-de-France            | 1.27                      |
    | 2022 | 12    | Nouvelle-Aquitaine         | 1.79                      |
    | 2022 | 12    | La Réunion                 | 2.14                      |
    | 2022 | 12    | Provence-Alpes-Côte d'Azur | 1.73                      |
    | 2022 | 12    | Mayotte                    | 0                         |
    | 2022 | 12    | Pays de la Loire           | 1.36                      |
    | 2022 | 12    | Occitanie                  | 1.17                      |
    | ...  | ...   | ...                       | ...                       |


- Quel est le rapport entre le nombre des hospitalisations des hommes et celui des femmes par jour et par région ?
    ```sql
    SELECT
        day,
        month,
        year,
        regions.libelle,
        SUM(hospit_corona_h) AS nb_femmes,
        SUM(hospit_corona_f) AS nb_hommes,
        CASE
            WHEN SUM(hospit_corona_h) = 0 THEN 0
            ELSE SUM(hospit_corona_f) / SUM(hospit_corona_h)
        END AS rapport
    FROM
        corona_records
        INNER JOIN
            departements
            ON corona_records.dep = departements.code
        INNER JOIN
            regions
            ON departements.code_region = regions.code
    GROUP BY
        day, month, year, regions.libelle
    ORDER BY
        day, month, year, regions.libelle;
    ```

    | day | month | year | libelle                   | nb_femmes | nb_hommes | rapport               |
    |-----|-------|------|---------------------------|-----------|-----------|-----------------------|
    | 1   | 1     | 2023 | Auvergne-Rhône-Alpes       | 10        | 15        | 1.5                   |
    | 1   | 1     | 2023 | Bourgogne-Franche-Comté    | 6         | 4         | 0.67                  |
    | 1   | 1     | 2023 | Bretagne                  | 7         | 10        | 1.43                  |
    | 1   | 1     | 2023 | Centre-Val de Loire        | 3         | 2         | 0.67                  |
    | 1   | 1     | 2023 | Corse                     | 0         | 0         | 0                     |
    | 1   | 1     | 2023 | Grand Est                  | 12        | 13        | 1.08                  |
    | 1   | 1     | 2023 | Guadeloupe                 | 0         | 1         | 0                     |
    | 1   | 1     | 2023 | Guyane                    | 0         | 0         | 0                     |
    | 1   | 1     | 2023 | Hauts-de-France            | 6         | 9         | 1.5                   |


De cette façon, différents dashboards sont faisables, par exemple en utilisant matplotlib :

![Pourcentage de passages aux urgences pour suspicion de covid-19 par rapport au nombre de passages total, par tranche d'âge](https://drive.google.com/uc?export=view&id=1wcmiQoj6ufDiMWFBGkJMnAcOJej_JFyp
)

![Pourcentage de passages aux urgences pour suspicison de COVID-19 par région chaque mois](https://drive.google.com/uc?export=view&id=1oCenc6-hvTAWoX2cCPHdb3dNcvxWOw5q
)