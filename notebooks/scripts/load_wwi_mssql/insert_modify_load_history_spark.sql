INSERT INTO modify_load_history_view
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