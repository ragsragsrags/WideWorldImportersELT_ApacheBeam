IF NOT EXISTS 
(
	SELECT 
		1 
	FROM
		INFORMATION_SCHEMA.TABLES T  
	WHERE
		T.TABLE_CATALOG = '<< Database >>' AND
		T.TABLE_SCHEMA = '<< Schema >>' AND
		T.TABLE_NAME = '<< Table >>'
)
	BEGIN

	CREATE TABLE [<< Schema >>].[<< Table >>] 
	(
        WarehouseHistoryDateID INT IDENTITY(1, 1),
		LoadDate DATETIME2(6),
		Status NVARCHAR(50), 
		ProcessedDate DATETIME2(6),
		ArchivePath NVARCHAR(500)
	)

	END