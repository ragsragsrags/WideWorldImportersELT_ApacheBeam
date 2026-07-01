INSERT INTO `<< Database >>.<< Schema >>.<< Table >>`
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
    '<< LoadDate >>', 
    '<< Status >>', 
    '<< Details >>',
    '<< ScriptName >>',
    CAST(CURRENT_TIMESTAMP() AS DATETIME)
)