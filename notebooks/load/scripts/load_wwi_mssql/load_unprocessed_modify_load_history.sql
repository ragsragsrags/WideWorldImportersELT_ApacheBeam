IF EXISTS 
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

        SELECT
            MS.*
        FROM
            (
                << ModifyTableScripts >>
            ) MS LEFT JOIN
            [<< Schema >>].[<< Table >>] MTH ON
                MTH.ScriptName = MS.Name AND
                MTH.[TableName] = '<< TableName >>' AND
                MTH.[SchemaName] = '<< SchemaName >>' AND
                MTH.[LoadDate] <= (
                    SELECT
                        MAX(LoadDate)
                    FROM 
                        [<< LHSchema >>].[<< LHTable >>] LH
                    WHERE
                        LH.[TableName] = '<< TableName >>' AND
                        LH.[SchemaName] = '<< SchemaName >>'  AND
                        LH.[Status] = 'Successful'
                ) AND
                MTH.[Status] = 'Successful'
        WHERE
            MTH.ScriptName IS NULL

    END
ELSE
    BEGIN

        SELECT
            MS.*
        FROM
            (
                << ModifyTableScripts >>
            ) MS 

    END

