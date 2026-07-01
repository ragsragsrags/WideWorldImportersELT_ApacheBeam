IF NOT EXISTS (
    SELECT
        1
    FROM
        `<< Database >>.<< Schema >>.<< Table >>`
    WHERE
        LoadDate = '<< NewCutoffDate >>' 
) AND NOT EXISTS (
    SELECT
        1
    FROM
        UNNEST(SPLIT('<< Tables >>', ',')) AS T LEFT JOIN
        (
            SELECT 
                CONCAT(WH.SchemaName, '.', WH.TableName) AS TableName 
            FROM 
                `<< Database >>.<< SchemaWH >>.<< TableWH >>` WH
            WHERE
                LoadDate = '<< NewCutoffDate >>' AND
                Status = 'Successful'
        ) T2 ON
            T2.TableName = T
    WHERE
        T2.TableName IS NULL
) THEN

    INSERT INTO `<< Database >>.<< Schema >>.<< Table >>`
    (
        LoadDate,
        Status, 
        ProcessedDate,
        ArchivePath
    )
    VALUES
    (
        '<< NewCutoffDate >>', 
        '<< Status >>', 
        CAST(CURRENT_TIMESTAMP() AS DATETIME),
        r'<< ArchivePath >>'   
    );

END IF;