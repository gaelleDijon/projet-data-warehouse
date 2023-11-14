from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator

from datetime import datetime, timedelta
import pandas as pd
import os

default_args = {
    'owner': 'Gaelle & Charlotte',
    'depends_on_past': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=3)
}

def transform_and_load():
    # Regions
    df_regions = pd.read_csv(
        os.path.expandvars("${AIRFLOW_HOME}/data/raw/regions.txt"),
        sep=","
    )

    # Tranches d'age
    df_tranches_age = pd.read_csv(
        os.path.expandvars("${AIRFLOW_HOME}/data/raw/code-tranches-dage-donnees-urgences.csv"),
        sep=";"
    )
    df_tranches_age.columns = ["code_tranche_age", "tranche_age"]
    age_codes = {
        "0": 0,
        "A": 1,
        "B": 2,
        "C": 3,
        "D": 4,
        "E": 5,
        "F": 6
    }
    df_tranches_age["code_tranche_age"] = df_tranches_age["code_tranche_age"].map(age_codes)

    # Départements
    df_departements = pd.read_json(
        os.path.expandvars("${AIRFLOW_HOME}/data/raw/departements-region.json")
    )
    df_departements = df_departements.rename(columns={"region_name": "nom_region"})
    df_departements = df_departements.merge(df_regions, on="nom_region", how="left")
    df_departements = df_departements.drop(columns=["nom_region"])
    df_departements.columns = ["code", "libelle", "code_region"]

    df_regions.columns = ["code", "libelle"]

    # Urgences
    df_urgences = pd.read_csv(
        os.path.expandvars("${AIRFLOW_HOME}/data/raw/donnees-urgences-SOS-medecins.csv"),
        sep=";"
    )
    df_urgences = df_urgences.fillna(0)
    df_urgences = df_urgences.rename(columns={"sursaud_cl_age_corona": "code_tranche_age"})
    df_urgences["date_de_passage"] = pd.to_datetime(df_urgences["date_de_passage"])
    df_urgences["year"] = df_urgences["date_de_passage"].dt.year
    df_urgences["month"] = df_urgences["date_de_passage"].dt.month
    df_urgences["day"] = df_urgences["date_de_passage"].dt.day

    columns_to_keep = [
    "year", "month", "day", "dep", "code_tranche_age",
    "pass_tot", "pass_tot_h", "pass_tot_f",
    "pass_corona", "pass_corona_h", "pass_corona_f",
    "hospit_corona", "hospit_corona_h", "hospit_corona_f"
    ]
    df_urgences = df_urgences[columns_to_keep]

    # to be completed once Gaelle pushes the sql instructions

    return


with DAG(
        'ETL',
        default_args=default_args,
        start_date=datetime(2021, 1, 1),
        catchup=False
) as dag:
    extract = BashOperator(
        task_id='extract',
        bash_command='curl --keepalive-time 6000 -o ${AIRFLOW_HOME}/data/raw/regions.txt https://static.data.gouv.fr/resources/regions-de-france/20190531-094805/regions-france.csv',
        dag=dag
    )



    transform_load = PythonOperator(
        task_id='transform_and_load',
        python_callable=transform_and_load,
        dag=dag
    )


    create_table = PostgresOperator(
        task_id="create_table",
        postgres_conn_id="postgres_connexion",
        sql='sql/create-table.sql'
    )

    #todo insert fct


    extract >> [transform_load, create_table]
