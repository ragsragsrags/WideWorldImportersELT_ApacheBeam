# WideWorldImporters ELT in Apache Beam

This is an end-to-end ELT of Microsoft's sample WideWorldImporters (WWI) database.  The goals for this project are:
+ Apache Beam familiarization - This project uses Apache Beam to create pipelines for its ease of use and also for distributed capabilities.  The transformation is mostly done in the sql, to learn more of its built-in transformations, try this site: https://tour.beam.apache.org/
+ Changing table dimensions - This project also aims to solve the changing table dimensions.  If there were added or modified columns in the load or warehouse tables.
+ Using custom spark runner as this is good for migrating data in bulk specially to cloud storage such as bigquery.
+ Rollback to previous load - This project adds a process to rollback to a previous load in a different process.

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
![alt text](/resources/readme_images/process_wwi-graph.png)
+ set_cutoff_date - set the cutoff date so both load and warehouse use the same cutoff date
+ get_load_wwi_copy_files - archive the load pipeline for use in rollback
+ load_wwi - extract and load data to warehouse database
+ get_warehouse_wwi_copy_files - archive the warehouse pipeline for use in rollback 
+ warehouse_wwi_dimensionTables - transform data to dimension warehouse tables
+ warehouse_wwi_factTables - transform data to fact warehouse tables 

Workflow of Rollback ELT
![alt text](/resources/readme_images/process_wwi_rollback-graph.png)
+ rollback_load_wwi - rollback load data to the configured date
+ rollback_warehouse_wwi_dimensionTables - rollback warehouse dimension data to the configured date
+ rollback_warehouse_wwi_factTables - rollback warehouse fact data to the configured date

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
        + setuptools: pip install setuptools==81.0.0

Instructions for Airflow Orchestration
+ Download and install Docker Desktop: https://docs.docker.com/desktop/setup/install/windows-install/
+ To build the application in Visual Studio Code:
    - In Terminal Window, build the application using this command: docker compose up -d --build
      or, if it's already built then this command: docker compose up -d 
    - You should be able see the processes in http://localhost:8080/dags.  There are two processes:
        + process_wwi - processes the ELT
        + process_wwi_rollback - processes the rollback of ELT to previous date 
    - The configuration of the process_wwi is process_wwi.json. In this file, the following configuration values:
        + cutoffDate: Specifies the cutoffdate of the process.  The format is YYYY-MM-DD HH:MM:SS, e.g. "2013-01-01 00:00:00". To get the existing date, leave it blank. 
        + loadConfigPath: This is the path for the load pipeline. Samples inside the folder:
            - jdbc mssql 
                + process_wwi_load_mssql_2013-01-01.json - loads 2013-01-01 cutoff
                + process_wwi_load_msqql_2014-01-01.json - loads 2014-01-01 cutoff, this also has modified table in Cities and Cities_Archive table
                + process_wwi_load_mssql_latest.json - load the current date
            - spark mssql
                + process_wwi_load_spark_mssql_2013-01-01.json - loads 2013-01-01 cutoff
                + process_wwi_load_spark_mssql_2014-01-01.json - loads 2014-01-01 cutoff, this also has modified table in Cities and Cities_Archive table
                + process_wwi_load_spark_mssql_latest.json - load the current date
            - biquery - combination of spark and bigquery client
                + process_wwi_load_bigquery_2013-01-01.json - loads 2013-01-01 cutoff
                + process_wwi_load_bigquery_2014-01-01.json - loads 2014-01-01 cutoff, this also has modified table in Cities and Cities_Archive table
                + process_wwi_load_bigquery_latest.json - load the current date
        + warehouseConfigPath: This is the path for the warehouse pipelines.  Samples inside the folder:
            - jdbc mssql
                + process_wwi_warehouse_mssql_2013-01-01.json - warehouse 2013-01-01 cutoff
                + process_wwi_warehouse_msqql_2014-01-01.json - warehouse 2014-01-01 cutoff, this also has modified table in DimCities
                + process_wwi_warehouse_mssql_latest.json - warehouse the current date
            - spark mssql
                + process_wwi_warehouse_spark_mssql_2013-01-01.json - warehouse 2013-01-01 cutoff
                + process_wwi_warehouse_spark_mssql_2014-01-01.json - warehouse 2014-01-01 cutoff, this also has modified table in DimCities
                + process_wwi_warehouse_spark_mssql_current.json - warehouse the current date
            - bigquery - combination of spark and bigquery client
                + process_wwi_warehouse_bigquery_2013-01-01.json - warehouse 2013-01-01 cutoff
                + process_wwi_warehouse_bigquery_2014-01-01.json - warehouse 2014-01-01 cutoff, this also has modified table in DimCities
                + process_wwi_warehouse_bigquery_latest.json - warehouse the current date
        + noOfLoadTablesPerProcess: This is the number of load tables processed per process if you want it to load concurrently.  If you want to process all tables in 1 process then set this to 0 or the total number of load tables.
        + noOfWarehouseDimensionTablesPerProcess: This is the number of dimension warehouse tables per process.  If you want to process all tables in 1 process then set this to 0 or the total number of dimension warehouse tables.
        + noOfWarehouseFactTablesPerProcess: This is the number of fact warehouse tables per process.  If you want to process all tables in 1 process then set this to 0 or the total number of fact warehouse tables.
        + newCutoffDate: Just leave this
    - The configuration of the process_wwi_rollback is process_wwi_rollback.json (mssql) and process_wwi_rollback_bq.json (bigquery). In this file, the following main configuration values:
        + cutoffDate - the cutoff date to rollback the data.
        + noOfLoadTablesPerProcess - This is the number of load tables processed per process if you want it to load concurrently.  If you want to process all tables in 1 process then set this to 0 or the total number of load tables.
        + noOfWarehouseDimensionTablesPerProcess - This is the number of dimension warehouse tables per process.  If you want to process all tables in 1 process then set this to 0 or the total number of dimension warehouse tables.
        + noOfWarehouseFactTablesPerProcess - This is the number of fact warehouse tables per process.  If you want to process all tables in 1 process then set this to 0 or the total number of fact warehouse tables.

This project has 2 main pipelines inside the notebooks folder:
+ load_wwi.ipynb - loads and extracts data to warehouse database
+ warehouse_wwi.ipynb - transforms data in the warehouse database to dimension and fact tables

This are the table to check for load/warehouse histories in the warehouse database:
+ LoadHistory - contains load history
+ LoadHistoryDate - contains the load history batch date
+ ModifyLoadHistory - contains modified load history table dimension changes
+ WarehouseHistory - contains warehouse history
+ WarehouseHistoryDate - contains the warehouse history batch date
+ ModifyWarehouseHistory - contains modified warehouse history table dimension changes

Additional Notes:
+ If you are migrating to bigquery, be sure to add the bigquery credentials in resources/credentials/bigquery_token.json.  See this document for creation: https://developers.google.com/workspace/guides/create-credentials
+ You need to have at least 8gb avaiable memory
+ Increment rollbackVersion in the warehouse config if there is calculation changes but no added/deleted columns or if you want it to force it to the recreate table 