INSERT INTO << Database >>.<< Schema >>.<< Table >>
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
    CAST(CURRENT_TIMESTAMP() AS DATETIME)
)