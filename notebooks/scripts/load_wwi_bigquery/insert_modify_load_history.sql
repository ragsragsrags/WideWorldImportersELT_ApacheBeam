INSERT INTO `<< Database >>.<< Schema >>.<< Table >>`
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
    CAST(CURRENT_TIMESTAMP() AS DATETIME)
)