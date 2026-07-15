IF NOT EXISTS (
    SELECT
        1
    FROM
        `<< Database >>.<< Schema >>.<< Table >>` 
    WHERE
        LoadDate = '<< NewCutoffDate >>' 	
) AND NOT EXISTS (
    SELECT
        1
    FROM
        UNNEST(SPLIT('<< Tables >>', ',')) AS T LEFT JOIN
        (
            SELECT 
                CONCAT(LH.SchemaName, '.', LH.TableName) AS TableName 
            FROM 
                `<< Database >>.<< SchemaLH >>.<< TableLH >>` LH
            WHERE
                LoadDate = '<< NewCutoffDate >>' AND
                Status = 'Successful'
        ) T2 ON
            T2.TableName = T
    WHERE
        T2.TableName IS NULL
) THEN


    INSERT INTO `<< Database >>.<< Schema >>.<< Table >>` 
    (
        LoadDate,
        Status, 
        ProcessedDate,
        ArchivePath,
        Environment,
        ReleaseGithubRepo,
        ReleaseGithubBranch,
        ReleaseGithubTag
    )
    VALUES
    (
        '<< NewCutoffDate >>', 
        '<< Status >>', 
        CAST(CURRENT_TIMESTAMP() AS DATETIME),
        r'<< ArchivePath >>',
        '<< Environment >>',
        '<< ReleaseGithubRepo >>',
        '<< ReleaseGithubBranch >>',
        '<< ReleaseGithubTag >>'
    );

END IF;