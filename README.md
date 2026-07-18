# WideWorldImporters ELT in Apache Beam

This is an end-to-end ELT of Microsoft's sample WideWorldImporters (WWI) database.  The goals for this project are:
+ Apache Beam familiarization - This project uses Apache Beam to create pipelines for its ease of use and also for distributed capabilities.  The transformation is mostly done in the sql, to learn more of its built-in transformations, try this site: https://tour.beam.apache.org/
+ Changing table dimensions - This project also aims to solve the changing table dimensions.  If there were added or modified columns in the load or warehouse tables.
+ Using custom spark runner as this is good for migrating data in bulk specially to cloud storage such as bigquery.
+ Rollback to previous load - This project adds a process to rollback to a previous load in a different process.
+ CI/CD the ELT - This project attempts to CI/CD the process using github as the repository.

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
+ Github - repository for CI/CD

Pre-requisites to install
+ Python 3.12 - see Instructions for coding in Visual Studio Code using virtual environment in Windows 
+ Visual Studio Code - see Instructions for coding in Visual Studio Code using virtual environment in Windows
+ Docker Desktop - https://docs.docker.com/desktop/setup/install/windows-install/
+ SSMS - see Instructions for Sql Server and WWI databases
+ Sql Server 2025 Developer - see Instructions for Sql Server and WWI databases
+ Github Desktop

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
+ get_process_wwi_files - archive the load and warehouse pipelines for use in both ELT and rollback
+ load_wwi - extract and load data to warehouse database
+ single_task/single_task_1 - use as an empty connector task for list >> list process
+ warehouse_wwi_dimensionTables - transform data to dimension warehouse tables
+ warehouse_wwi_factTables - transform data to fact warehouse tables 

Workflow of Rollback ELT
![alt text](/resources/readme_images/process_wwi_rollback-graph.png)
+ rollback_load_wwi - rollback load data to the configured date
+ single_task/single_task_1 - use as an empty connector task for list >> list process
+ rollback_warehouse_wwi_dimensionTables - rollback warehouse dimension data to the configured date
+ rollback_warehouse_wwi_factTables - rollback warehouse fact data to the configured date

Workflow of Update Main DAG
![alt text](/resources/readme_images/process_wwi_update_main_dag-graph.png)
+ update_main_dag_task - update the process wwi main dag and it's dependencies (configured in the process_wwi.json): process_wwi.py, process_wwi.json, modules/dag_utilities.py and modules/process_wwi_common.py.

CI/CD
For ci/cd, I'm using github as my repository.
+ These are the branches:
    - main: for production
    - development: for development
+ High level design:
    - process_wwi_update_main_dag:
        + this will check if there is new release.
        + if new release is found, it will download the new release
        + if dag version of new release is > than the existing dag version, it will update the dag files and its dependencies.
    - process_wwi: this will have the following process:
        + it will check if github has a new release
        + if new release is found, it will download and archive the new release and use the archive as code base for the pipeline
        + if new release is not found, it will use the latest archive with the same release
+ For this project:
    - Changes goes to development first with series of version increments if there are a lot of changes when testing.  Then it goes to the main branch.
    - Releases should ideally not be removed and created with the same tag name but an increment of the version.  If you remove releases, you also need to remove the archive files in the /process_wwi_archive/releases folders.
    - Also, it is ideal to have one environment per branch so you can simulate development -> main.  The development branch should have "development" as it's environment in the application_settings.config while main branch should have "production".  In github desktop, you can easily switch from development to main so need to rebuild your docker compose, unless you have changes in your docker compose so you need to rebuild it.

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
        + process_wwi_update_main_dag - processes the update the dag files and it's dependencies 
    - The configuration of the process_wwi is set in the application_settings.json file based on the environment. For the specified file, the following configuration values:
        + version: This is the version of the dag to be used in the ci/cd of the pipelines. 
            - This should be manually updated when there are changes in the following files:
                + /dags/load_wwi.ipynb
                + /dags/load_wwi.json
                + /dags/modules/dag_utilities.py
                + /dags/modules/process_wwi_common.py
            - This 
        + environment: This is the environment of the config file.  
            - If value is "development_mssql_2013-01-01", it will reference the "/notebooks/load/load_wwi_development_mssql_2013-01-01.json" config file with it added as suffix to the base config file.
            - The following are sample environments/config files:
                + jdbc mssql 
                    + load
                        - development_mssql_2013-01-01: load_wwi_development_mssql_2013-01-01.json
                        - development_mssql_2014-01-01: load_wwi_development_mssql_2014-01-01.json
                        - development_mssql_latest: load_wwi_development_mssql_latest.json
                    + warehouse
                        - development_mssql_2013-01-01: warehouse_wwi_development_mssql_2013-01-01.json
                        - development_mssql_2014-01-01: warehouse_wwi_development_mssql_2014-01-01.json
                        - development_mssql_latest: warehouse_wwi_development_mssql_latest.json
                + spark mssql 
                    - load
                        + development_spark_mssql_2013-01-01: load_wwi_development_spark_mssql_2013-01-01.json
                        + development_spark_mssql_2014-01-01: load_wwi_development_spark_mssql_2014-01-01.json
                        + development_spark_mssql_latest: load_wwi_development_spark_mssql_latest.json
                    - warehouse
                        + development_spark_mssql_2013-01-01: warehouse_wwi_development_spark_mssql_2013-01-01.json
                        + development_spark_mssql_2014-01-01: warehouse_wwi_development_spark_mssql_2014-01-01.json
                        + development_spark_mssql_latest: warehouse_wwi_development_spark_mssql_latest.json
                + bigquery - combination of spark and bigquery client 
                    - load
                        + development_spark_bigquery_2013-01-01: load_wwi_development_spark_bigquery_2013-01-01.json
                        + development_spark_bigquery_2014-01-01: load_wwi_development_spark_bigquery_2014-01-01.json
                        + development_spark_bigquery_latest: load_wwi_development_spark_bigquery_latest.json
                    - warehouse
                        + development_spark_bigquery_2013-01-01: warehouse_wwi_development_spark_bigquery_2013-01-01.json
                        + development_spark_bigquery_2014-01-01: warehouse_wwi_development_spark_bigquery_2014-01-01.json
                        + development_spark_bigquery_latest: warehouse_wwi_development_spark_bigquery_latest.json
        + cutoffDate: Specifies the cutoffdate of the process.  The format is YYYY-MM-DD HH:MM:SS, e.g. "2013-01-01 00:00:00". To get the existing date, leave it blank. 
        + noOfWorkers: This is the number of concurrent workers per load or warehouse. If loading with spark, this should match the number of spark workers configured in the docker compose to avoid memory errors. 
        + newCutoffDate: Just leave this
        + loadDirectories: This is the copy configuration of load archive.
        + warehouseDirectories: This is the copy configuration of warehouse archive.
        + common: This is the configuration of common files/folders used in the pipelines. 
        + copyFilesType: This is the configuration of how you want to process the pipelines.  It can either be "local" for local copying or "github" if the files are from github release.
            - type: values should be "local" and "github"
            - tokenPath: path of your github token.  should have read access. 
            - owner: owner of the github account
            - repo: repository of the application 
            - branch: branch of the repository you want to fetch the release
        + releaseGithubTag: This is the tag of the latest github release during the date it was processed.  Just leave this.
        + raiseErrorWhenNewVersionFound: The value is either "true", to raise error when github latest release dag version is higher than the existing dag version. Or "false", to use the github release dag version with the same as the existing dag version.
        + dagInfo: This is the dag info used for updating the main dag pipeline.
        + releaseGithubReleases: This is where you want the github releases saved so it does not download everytime.
        + releaseGithubReleasesInfoPath: This is releases info path which contains the releases downloaded. 
    - The configuration of the process_wwi_rollback is also set in the application_settings.json. In the specified config file, the following main configuration values:
        + cutoffDate - the cutoff date to rollback the data.
        + noOfLoadTablesPerProcess - This is the number of load tables processed per process if you want it to load concurrently.  If you want to process all tables in 1 process then set this to 0 or the total number of load tables.
        + noOfWorkers - This is the number of concurrent workers per load or warehouse. If loading with spark, this should match the number of spark workers configured in the docker compose to avoid memory errors.

This project has 2 main pipelines inside the notebooks folder:
+ /notebooks/load/load_wwi.ipynb - loads and extracts data to warehouse database
+ /notebooks/warehouse/warehouse_wwi.ipynb - transforms data in the warehouse database to dimension and fact tables

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