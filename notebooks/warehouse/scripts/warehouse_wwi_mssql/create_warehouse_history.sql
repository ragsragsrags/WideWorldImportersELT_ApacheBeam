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
		TableName NVARCHAR(50),
		SchemaName NVARCHAR(50), 
		LoadDate DATETIME2(6), 
		LastCutoffDate DATETIME2(6), 
		Status NVARCHAR(50), 
		Details NVARCHAR(1000),
		ProcessedDate DATETIME2(6),
		TableSchema JSON,
		RollbackVersion INT,
		LastRolledBackProcessedDate DATETIME2(6) NULL
	)

	END