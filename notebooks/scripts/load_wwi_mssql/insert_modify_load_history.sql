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
    '<< LoadDate >>', 
    '<< Status >>', 
    '<< Details >>',
    '<< ScriptName >>',
    CURRENT_TIMESTAMP
)