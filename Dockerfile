FROM apache/airflow:3.1.0-python3.12

USER airflow

RUN pip install --no-cache-dir apache-airflow==3.1.0
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY dags/ /opt/airflow/dags/
COPY notebooks/ /opt/airflow/notebooks/
COPY resources/ /opt/airflow/resources/

RUN airflow db migrate