IF NOT EXISTS (
    SELECT
        1
    FROM
        [<< Schema >>].[<< Table >>]
    WHERE
        [LoadDate] = '<< NewCutoffDate >>' 
) AND NOT EXISTS (
    SELECT
        1
    FROM
        STRING_SPLIT('<< Tables >>', ',', 0) T LEFT JOIN
        (
            SELECT 
                [TableName] = LH.[SchemaName] + '.' + LH.[TableName] 
            FROM 
                [<< SchemaWH >>].[<< TableWH >>] LH
            WHERE
                [LoadDate] = '<< NewCutoffDate >>' AND
                [Status] = 'Successful'
        ) T2 ON
            T2.[TableName] = T.value
    WHERE
        T2.[TableName] IS NULL
)
BEGIN

INSERT INTO [<< Schema >>].[<< Table >>] 
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
    CURRENT_TIMESTAMP,
    '<< ArchivePath >>'   
)

END