INSERT INTO << Database >>.<< Schema >>.<< Table >>
(
    TableName, 
    SchemaName,
    LoadDate, 
    LastCutoffDate,
    Status, 
    Details,
    ProcessedDate,
    TableSchema,
    RollbackVersion,
    LastRolledBackProcessedDate
)
VALUES
(
    '<< TableName >>', 
    '<< SchemaName >>',
    '<< LoadDate >>',
    '<< LastCutoffDate >>', 
    '<< Status >>', 
    '<< Details >>',
    CAST(CURRENT_TIMESTAMP() AS DATETIME),
    (
        SELECT
            TO_JSON(ARRAY_AGG(STRUCT(Name, DataType, CharacterMaximumLength, IsNullable)))
        FROM
        (
            SELECT
                C.column_name AS Name,
                C.data_type AS DataType ,
                0 AS CharacterMaximumLength,
                C.is_nullable AS IsNullable 
            FROM 
                `<< Database >>.<< Schema >>.INFORMATION_SCHEMA.COLUMNS` C
            WHERE 
                table_name = '<< TableName >>' AND 
                table_schema = '<< Schema >>'
        ) C
    ),
    << RollbackVersion >>,
    NULL
)