# WideWorldImporters ELT in Apache Beam

This is an end-to-end ELT of Microsoft's sample WideWorldImporters (WWI) database.  The goals for this project are:
+ Apache Beam familiarization - This project uses Apache Beam to create pipelines for its ease of use and also for distributed capabilities.  The transformation is mostly done in the sql, to learn more of its built-in transformations, try this site: https://tour.beam.apache.org/
+ Changing table dimensions - This project also aims to solve the changing table dimensions.  If there were added or modified columns in the load or warehouse tables.
+ Using custom spark runner as this is good for migrating data in bulk specially to cloud storage such as bigquery.

This project has three types of data migration, for comparison:
+ mssql - Using the pyodbc library.
+ spark-mssql - Using the Apache Spark mssql to migrate data which is ideal for bulk data.
+ spark-bigquery - Using the Apache Spark bigquery and bigquery client to transfer data.  Bigquery client is used for updates and such

For this project, we are using the following technologies to ELT:
+ Apache Airflow - orchestration
+ Apache Beam - pipelines to orchestrate load and extract data. Also, transform data  
+ Sql/JDBC/Apache Spark - loading, saving and data transformation
+ Docker - containerization
+ Jupyter Notebook - coding file type
+ Papermill - airflow operator for jupyter notebook

Pre-requisites to install
+ Python 3.12 - see Instructions for coding in Visual Studio Code using virtual environment in Windows 
+ Visual Studio Code - see Instructions for coding in Visual Studio Code using virtual environment in Windows
+ Docker Desktop - https://docs.docker.com/desktop/setup/install/windows-install/
+ SSMS - see Instructions for Sql Server and WWI databases
+ Sql Server 2025 Developer - see Instructions for Sql Server and WWI databases

Relevant documents
+ Docker - https://docs.docker.com/get-started/
+ Apache Airflow in Docker - https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html
+ Apache Beam - https://beam.apache.org/get-started/
+ Papermill - https://airflow.apache.org/docs/apache-airflow-providers-papermill/stable/operators.html
+ Apache Spark - https://spark.apache.org/docs/latest/quick-start.html
+ BigQuery Spark - https://github.com/GoogleCloudDataproc/spark-bigquery-connector 

Workflow of ELT
![alt text](/resources/readme_images/image.png)
+ set_cutoff_date - set the cutoff date so both load and warehouse use the same cutoff date
+ load_wwi - extract and load data to warehouse database
+ warehouse_wwi - transform data to warehouse tables 

Instructions for Sql Server and WWI databases
+ Download and install SSMS from: https://learn.microsoft.com/en-us/ssms/install/install
+ Install Sql Server 2025
    - Download Standard Developer edition: (https://www.microsoft.com/en-us/sql-server/sql-server-downloads)
    - When installing select Custom installation so you can specify the Mixed Mode authentication option
    - During installation
        + In the Azure Extension for SQL Server step, uncheck the option to include it
        + In the Feature Selection step, check the Database Engine Services option
        + In the Database Engine Configuration step, select the Mixed Mode option for Authentication Mode (this is for sql server and windows authentication). Also, include the current user as administrator if you wish to.
+ Download and restore WWI database (WideWorldImporters-Full.bak) from: https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0

Instructions for coding in Visual Studio Code using virtual environment in Windows
+ Python 3.12:
    - Download Windows embeddable package (64-bit) from: https://www.python.org/downloads/windows/
    - Copy and unzip it
+ Download and install Visual Studio Code from: https://code.visualstudio.com/docs/setup/windows
+ Install Jupyter extension
+ To create a virtual environment 
    - Create a sample notebook file
    - Register Python 3.12 embeddable package: Select Kernel -> Python Environments -> Create Python Environments -> Enter Interpreter Path -> << path of the python.exe where you unzipped the Python 3.12 >>
    - Create the virtual environment with,  Select Kernel -> Python Environments -> Create Python Environments -> venv -> Python 3.12 -> skip the packages option
    - Install libararies in the new terminal:
        + apache-beam: pip install apache-beam==2.71.0
        + pyspark: pip install pyspark[pandas]==3.5.0
        + pyodbc: pip install pyodbc==5.3.0
        + pandas: pip install pandas==2.2.3
        + bigquery: pip install google-cloud-bigquery==3.41.0
        + setuptools: pip install setuptools==82.0.1

Instructions for Airflow Orchestration
+ Download and install Docker Desktop: https://docs.docker.com/desktop/setup/install/windows-install/
+ To build the application in Visual Studio Code:
    - In Terminal Window, build the application using this command: docker compose up -d --build
      or, if it's already built then this command: docker compose up -d 
    - You should be able see the process_wwi in http://localhost:8080/dags.  
    - The main configuration is the process_wwi.json. In this file, the following configuration values:
        + cutoffDate: Specifies the cutoffdate of the process.  The format is YYYY-MM-DD HH:MM:SS, e.g. "2013-01-01 00:00:00". To get the existing date, leave it blank. 
        + loadConfigPath: This is the path for the load pipeline. Samples inside the folder:
            - jdbc mssql 
                + process_wwi_load_mssql_2013-01-01.json - loads 2013-01-01 cutoff
                + process_wwi_load_msqql_2014-01-01.json - loads 2014-01-01 cutoff, this also has modified table in Cities and Cities_Archive table
                + process_wwi_load_mssql_current.json - load the current date
            - spark mssql
                + process_wwi_load_spark_mssql_2013-01-01.json - loads 2013-01-01 cutoff
                + process_wwi_load_spark_mssql_2014-01-01.json - loads 2014-01-01 cutoff, this also has modified table in Cities and Cities_Archive table
                + process_wwi_load_spark_mssql_current.json - load the current date
            - biquery - combination of spark and bigquery client
                + process_wwi_load_bigquery_2013-01-01.json - loads 2013-01-01 cutoff
                + process_wwi_load_bigquery_2014-01-01.json - loads 2014-01-01 cutoff, this also has modified table in Cities and Cities_Archive table
                + process_wwi_load_bigquery_current.json - load the current date
        + warehouseConfigPath: This is the path for the warehouse pipelines.  Samples inside the folder:
            - jdbc mssql
                + process_wwi_warehouse_mssql_2013-01-01.json - warehouse 2013-01-01 cutoff
                + process_wwi_warehouse_msqql_2014-01-01.json - warehouse 2014-01-01 cutoff, this also has modified table in DimCities
                + process_wwi_warehouse_mssql_current.json - warehouse the current date
            - spark mssql
                + process_wwi_warehouse_spark_mssql_2013-01-01.json - warehouse 2013-01-01 cutoff
                + process_wwi_warehouse_spark_mssql_2014-01-01.json - warehouse 2014-01-01 cutoff, this also has modified table in DimCities
                + process_wwi_warehouse_spark_mssql_current.json - warehouse the current date
            - bigquery - combination of spark and bigquery client
                + process_wwi_warehouse_bigquery_2013-01-01.json - warehouse 2013-01-01 cutoff
                + process_wwi_warehouse_bigquery_2014-01-01.json - warehouse 2014-01-01 cutoff, this also has modified table in DimCities
                + process_wwi_warehouse_bigquery_current.json - warehouse the current date
        + noOfLoadTablesPerProcess: This is the number of load tables processed per process if you want it to load concurrently.  If you want to process all tables in 1 process then set this to 0 or the total number of load tables.
        + noOfWarehouseDimensionTablesPerProcess: This is the number of dimension warehouse tables per process.  If you want to process all tables in 1 process then set this to 0 or the total number of dimension warehouse tables.
        + noOfWarehouseFactTablesPerProcess: This is the number of fact warehouse tables per process.  If you want to process all tables in 1 process then set this to 0 or the total number of fact warehouse tables.
        + newCutoffDate: Just leave this

This project has 2 main pipelines inside the notebooks folder:
+ load_wwi.ipynb - loads and extracts data to warehouse database
+ warehouse_wwi.ipynb - transforms data in the warehouse database to dimension and fact tables

This are the table to check for load/warehouse histories in the warehouse database:
+ LoadHistory - contains load history
+ ModifyLoadHistory - contains modified load history table dimension changes
+ WarehouseHistory - contains warehouse history
+ ModifyWarehouseHistory - contains modified warehouse history table dimension changes

Additional Notes:
+ If you are migrating to bigquery, be sure to add the bigquery credentials in resources/credentials/bigquery_token.json.  See this document for creation: https://developers.google.com/workspace/guides/create-credentials
+ You need to have at least 8gb avaiable memory