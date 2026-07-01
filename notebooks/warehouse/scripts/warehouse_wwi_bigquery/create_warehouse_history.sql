CREATE TABLE IF NOT EXISTS << Database >>.<< Schema >>.<< Table >> 
(
	TableName STRING, 
	SchemaName STRING,
	LoadDate DATETIME,
	LastCutoffDate DATETIME, 
	Status STRING, 
	Details STRING,
	ProcessedDate DATETIME,
	TableSchema JSON,
	RollbackVersion INTEGER,
	LastRolledBackProcessedDate DATETIME
)