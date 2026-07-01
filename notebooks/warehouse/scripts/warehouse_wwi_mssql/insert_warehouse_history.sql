INSERT INTO [<< Schema >>].[<< Table >>] 
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
    CURRENT_TIMESTAMP,
    (
        SELECT
            [Name] = C.COLUMN_NAME,
            [DataType] = C.DATA_TYPE,
            [CharacterMaximumLength] = ISNULL(C.CHARACTER_MAXIMUM_LENGTH, -1),
            [IsNullable] = C.IS_NULLABLE
        FROM 
            INFORMATION_SCHEMA.COLUMNS C
        WHERE 
            TABLE_NAME = '<< TableName >>' AND 
            TABLE_SCHEMA = '<< Schema >>'
        FOR JSON PATH
    ),
    '<< RollbackVersion >>',
    NULL
)