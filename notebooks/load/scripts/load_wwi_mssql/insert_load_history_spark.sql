INSERT INTO load_history_view 
(
    TableName,
    SchemaName, 
    LoadDate, 
    LastCutoffDate,
    Status, 
    Details,
    ProcessedDate
)
VALUES
(
    '<< TableName >>', 
    '<< SchemaName >>',
    '<< LoadDate >>',
    '<< LastCutoffDate >>', 
    '<< Status >>', 
    '<< Details >>',
    CURRENT_TIMESTAMP
)