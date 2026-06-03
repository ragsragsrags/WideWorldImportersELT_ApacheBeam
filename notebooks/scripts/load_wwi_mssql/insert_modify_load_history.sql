INSERT INTO [<< Schema >>].[<< Table >>] 
(
    TableName, 
    LoadDate, 
    Status, 
    Details,
    ScriptName,
    ProcessedDate
)
VALUES
(
    '<< TableName >>', 
    '<< LastCutoffDate >>', 
    '<< Status >>', 
    '<< Details >>',
    '<< ScriptName >>',
    CURRENT_TIMESTAMP
)