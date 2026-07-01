INSERT INTO modify_load_history_view
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