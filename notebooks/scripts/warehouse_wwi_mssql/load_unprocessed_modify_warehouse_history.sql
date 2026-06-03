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
                MTH.[LoadDate] <= (
                    SELECT
                        MAX(LoadDate)
                    FROM 
                        [<< MHSchema >>].[<< MHTable >>]
                    WHERE
                        [TableName] = '<< TableName >>'
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