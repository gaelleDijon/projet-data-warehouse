# projet-data-warehouse

Projet entrepot de données Sup De Vinci

## Nos objectifs :

Ce projet a pour but la mise en place d'un DAG Airflow permettant :

- D'extraire des données des sources disponibles sous data\raw
- De les transformer, c'est-à-dire de les nettoyer afin d'avoir des données de bonne qualité
- De créer les tables d'un entrepot de données
- D'alimenter notre entrepot de données

## Comment lancer notre projet ?

Docker doit être **installé et à jour sur votre système**. Si ce n'est pas déjà le cas, téléchargez et installez Docker depuis leur [site officiel](https://www.docker.com/get-started/).
Téléchargez manuellement les fichiers du projet ou clonez-les à l'aide de la commande :

```
git clone https://github.com/gaelleDijon/projet-data-warehouse.git
```

Si vous êtes sous une distribution Linux, assurez-vous d'avoir les permissions nécessaire, la commande :

```
echo -e "AIRFLOW_UID=$(id -u)" > .env
```

Il est également essentiel de créer les dossiers de logs et de données pour Airflow, avec la commande :

```
mkdir -p ./dags ./logs ./plugins ./config
```

Une fois les fichiers récupérés et les commandes exécutées, allez dans le répertoire du projet et **lancez Docker** puis chargez les images de Postgresql et Airflow, nécessaires pour tester notre projet avec la commande :

```
docker-compose up
```

Configurez une connexion postgres sur Airflow, avec pour id **postgres_connexion** et testez-la pour vous assurer de son bon fonctionnement.

Une fois la configuration terminée, vous pouvez activer le DAG nommé **ETL** et le déclencher pour tester l'extraction, la transformation et le chargement des données.

Pour arrêter Docker et nettoyer les volumes, utilisez la commande :

```
docker-compose down --volumes
```

Pour une démonstration plus complète de la configuration et du lancement de l'ETL, vous pouvez [consulter notre vidéo mise à disposition](https://drive.google.com/file/d/1FUznzLuSF982yfJsOpHPnYR9nhB80-gN/view?usp=drive_link).

## Choix des traitements de données

Afin que notre entrepot de données puisse répondre aux problématiques propres à notre cas d'utilisation, nous avons d'abord défini un schéma des données telles qu'elles seront enregistrées dans l'entrepôt final.
Nos données sont organisées en étoiles avec :

- **corona_records** : la table des faits, qui contient l'ensemble des enregistrements des urgences
- **codes_ages** : table de dimensions des tranches d'ages et de leurs codes
- **departements** : table des dimensions des départements
- **regions** : table des dimensions des régions

![schema de notre entrepot](https://drive.google.com/uc?export=view&id=1h_5He8zG_JQM9G0Xufhvt3D1ft0Im664)

Après extraction des fichiers CSV, JSON et TXT, nous avons nettoyé les données brutes et vérifié leur conformité avec les cas d'utilisaton, ces opérations ont pour but de faciliter l'exploitation des données, pour ce faire, nous avons :

- Remplacé les champs vides par des 0 : afin de ne pas générer d'erreurs lors des analyses, les champs vides du fichier des données des urgences, ont été remplacés par des 0. Nous avons privilégié cette méthode car dans ce cas, les enregistrements vides sont équivalents à null. Les calculs conservent leur cohérence.
- Fait un mapping des codes des tranches d'âge afin d'avoir la même nomenclature que dans les enregistrements des données des urgences.
- Effectué des opérations sur les colonnes telles que :
  - le renommage : notamment sur les colonnes des enregistrements des urgences, afin d'uniformiser le nom des colonnes et de leurs références et de les rendre plus lisible.
  - la suppression des colonnes non utilisées
  - la création, par exemple, pour faciliter l'analyse par la suite, des colonnes year, month et day ont été créées en séparant la colonne date des données des urgences
- Modifié le format des champs de certaines colonnes dans un but d'uniformisation pour le chargement dans des tables.

## Les analyses possibles

Plusieurs pistes sont possibles pour l'analyse de ces données :

- Quel est le pourcentage de passages aux urgences pour suspicion de covid-19 par rapport au nombre de passages total,
  pour les personnes âgées de plus de 65 ans, en 2023 ?

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

  | pourcentage |
  | ----------- |
  | 1.21        |

- Quel est le pourcentage de passages aux urgences pour suspicion de covid-19 par rapport au nombre de passages total,
  par tranche d’âge en 2022 ?

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

  | code_tranche_age | tranche_age | pourcentage |
  | ---------------- | ----------- | ----------- |
  | 0                | Tout âge    | 1.22        |
  | 1                | 0-4 ans     | 0.61        |
  | 2                | 5-14 ans    | 0.08        |
  | 3                | 15-44 ans   | 0.44        |
  | 4                | 45-64 ans   | 0.88        |
  | 5                | 65-74 ans   | 1.98        |
  | 6                | 75 et plus  | 3.65        |

- Quel est le pourcentage de passages aux urgences pour suspicion de covid-19 par rapport au nombre de passages total
  pour les hommes par an et par département ?

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

  | year | libelle                 | pourcentage |
  | ---- | ----------------------- | ----------- |
  | 2022 | Ain                     | 1.25        |
  | 2022 | Aisne                   | 1.69        |
  | 2022 | Allier                  | 1.97        |
  | 2022 | Alpes-de-Haute-Provence | 2.80        |
  | 2022 | Alpes-Maritimes         | 1.20        |
  | 2022 | Ardèche                 | 1.25        |
  | 2022 | Ardennes                | 0.73        |
  | 2022 | Ariège                  | 1.42        |
  | ...  | ...                     | ...         |

- Quel est le pourcentage de passages aux urgences pour suspicion de covid-19 par rapport au nombre de passages total
  pour les femmes par an et par département ?

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

  | year | libelle                 | pourcentage |
  | ---- | ----------------------- | ----------- |
  | 2022 | Ain                     | 1.22        |
  | 2022 | Aisne                   | 1.67        |
  | 2022 | Allier                  | 1.92        |
  | 2022 | Alpes-de-Haute-Provence | 2.16        |
  | 2022 | Alpes-Maritimes         | 1.30        |
  | 2022 | Ardèche                 | 1.87        |
  | 2022 | Ardennes                | 0.78        |
  | 2022 | Ariège                  | 1.45        |
  | ...  | ...                     | ...         |

- Quel est le pourcentage de passages aux urgences pour suspicion de covid-19 par rapport au nombre de passages total,
  par mois et par région ?

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

  | year | month | libelle                    | pourcentage |
  | ---- | ----- | -------------------------- | ----------- |
  | 2022 | 12    | Corse                      | 1.67        |
  | 2022 | 12    | Auvergne-Rhône-Alpes       | 1.23        |
  | 2022 | 12    | Hauts-de-France            | 1.27        |
  | 2022 | 12    | Nouvelle-Aquitaine         | 1.79        |
  | 2022 | 12    | La Réunion                 | 2.14        |
  | 2022 | 12    | Provence-Alpes-Côte d'Azur | 1.73        |
  | 2022 | 12    | Mayotte                    | 0           |
  | 2022 | 12    | Pays de la Loire           | 1.36        |
  | 2022 | 12    | Occitanie                  | 1.17        |
  | ...  | ...   | ...                        | ...         |

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

  | day | month | year | libelle                 | nb_femmes | nb_hommes | rapport |
  | --- | ----- | ---- | ----------------------- | --------- | --------- | ------- |
  | 1   | 1     | 2023 | Auvergne-Rhône-Alpes    | 10        | 15        | 1.5     |
  | 1   | 1     | 2023 | Bourgogne-Franche-Comté | 6         | 4         | 0.67    |
  | 1   | 1     | 2023 | Bretagne                | 7         | 10        | 1.43    |
  | 1   | 1     | 2023 | Centre-Val de Loire     | 3         | 2         | 0.67    |
  | 1   | 1     | 2023 | Corse                   | 0         | 0         | 0       |
  | 1   | 1     | 2023 | Grand Est               | 12        | 13        | 1.08    |
  | 1   | 1     | 2023 | Guadeloupe              | 0         | 1         | 0       |
  | 1   | 1     | 2023 | Guyane                  | 0         | 0         | 0       |
  | 1   | 1     | 2023 | Hauts-de-France         | 6         | 9         | 1.5     |

De cette façon, différents dashboards sont faisables, par exemple en utilisant matplotlib :

![Pourcentage de passages aux urgences pour suspicion de covid-19 par rapport au nombre de passages total, par tranche d'âge](https://drive.google.com/uc?export=view&id=1wcmiQoj6ufDiMWFBGkJMnAcOJej_JFyp)

![Pourcentage de passages aux urgences pour suspicion de COVID-19 par région chaque mois](https://drive.google.com/uc?export=view&id=1oCenc6-hvTAWoX2cCPHdb3dNcvxWOw5q)
