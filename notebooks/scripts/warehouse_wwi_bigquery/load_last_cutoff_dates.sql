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
        CAST(MAX(LoadDate) AS TIMESTAMP) AS LastCutoffDate
    FROM
        `<< Database >>.<< Schema >>.<< Table >>`
    GROUP BY
        TableName;

ELSE

    SELECT
        TableName,
        LastCutoffDate
    FROM
        (
            SELECT
                "" AS TableName,
                CAST(NULL AS TIMESTAMP) AS LastCutoffDate
        )
    WHERE
        1 = 0;

END IF;