INSERT INTO load_history_view 
(
    TableName, 
    LoadDate, 
    Status, 
    Details,
    ProcessedDate
)
VALUES
(
    '<< TableName >>', 
    '<< LoadDate >>', 
    '<< Status >>', 
    '<< Details >>',
    CURRENT_TIMESTAMP
)