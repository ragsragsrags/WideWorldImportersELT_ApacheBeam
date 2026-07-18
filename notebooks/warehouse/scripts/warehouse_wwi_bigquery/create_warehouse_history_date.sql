CREATE TABLE IF NOT EXISTS << Database >>.<< Schema >>.<< Table >> 
(
	LoadDate DATETIME,
	Status STRING, 
	ProcessedDate DATETIME,
	ArchivePath STRING,
	Environment STRING,
	ReleaseGithubRepo STRING,
	ReleaseGithubBranch STRING,
	ReleaseGithubTag STRING
)