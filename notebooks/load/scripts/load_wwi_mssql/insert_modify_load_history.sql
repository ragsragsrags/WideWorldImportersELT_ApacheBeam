INSERT INTO [<< Schema >>].[<< Table >>] 
(
    TableName,
    SchemaName, 
    LoadDate, 
    Status, 
    Details,
    ScriptName,
    ProcessedDate
)
VALUES
(
    '<< TableName >>',
    '<< SchemaName >>', 
    '<< LastCutoffDate >>', 
    '<< Status >>', 
    '<< Details >>',
    '<< ScriptName >>',
    CURRENT_TIMESTAMP
)