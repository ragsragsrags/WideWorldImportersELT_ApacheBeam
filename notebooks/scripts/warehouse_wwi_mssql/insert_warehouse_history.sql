INSERT INTO [<< Schema >>].[<< Table >>] 
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