FROM apache/airflow:3.1.0-python3.12

USER root

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         openjdk-17-jre-headless \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Define the command to run when the container starts
# This example starts the HDFS NameNode and DataNode in pseudo-distributed mode.
CMD ["bash", "-c", "hdfs namenode -format -force && start-dfs.sh && tail -f /dev/null"]

USER airflow

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

RUN pip install --no-cache-dir apache-airflow==3.1.0
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY dags/ /opt/airflow/dags/
COPY notebooks/ /opt/airflow/notebooks/
COPY resources/ /opt/airflow/resources/

RUN airflow db migrate