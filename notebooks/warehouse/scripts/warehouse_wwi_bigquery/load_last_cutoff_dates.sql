IF EXISTS (
    SELECT 
        1
    FROM 
        `<< Database >>`.`<< Schema >>`.INFORMATION_SCHEMA.TABLES
    WHERE 
      table_name = '<< Table >>'
) THEN

    SELECT
        TableName,
        SchemaName,
        CAST(MAX(LoadDate) AS TIMESTAMP) AS LastCutoffDate
    FROM
        `<< Database >>.<< Schema >>.<< Table >>`
    GROUP BY
        TableName,
        SchemaName;

ELSE

    SELECT
        TableName,
        SchemaName,
        LastCutoffDate
    FROM
        (
            SELECT
                "" AS TableName,
                "" AS SchemaName,
                CAST(NULL AS TIMESTAMP) AS LastCutoffDate
        )
    WHERE
        1 = 0;

END IF;