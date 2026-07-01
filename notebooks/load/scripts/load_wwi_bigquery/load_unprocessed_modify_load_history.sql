DECLARE LastCutoffDate DATETIME;

SET LastCutoffDate = 
(
    SELECT
        MAX(LoadDate)
    FROM 
        `<< Database >>.<< LHSchema >>.<< LHTable >>`
    WHERE
        TableName = '<< TableName >>' AND
        SchemaName = '<< SchemaName >>' AND
        Status = 'Successful'
);

IF EXISTS (
    SELECT 
        1
    FROM 
        `<< Database >>`.`<< Schema >>`.INFORMATION_SCHEMA.TABLES
    WHERE 
      table_name = '<< Table >>'
) THEN

    SELECT
        MS.*
    FROM
        (
            << ModifyTableScripts >>
        ) MS LEFT JOIN
        `<< Database >>.<< Schema >>.<< Table >>` MTH ON
            MTH.ScriptName = MS.Name AND
            MTH.TableName = '<< TableName >>' AND
            MTH.SchemaName = '<< SchemaName >>' AND
            MTH.LoadDate <= CAST(LastCutoffDate AS DATETIME) AND
            MTH.Status = 'Successful'
    WHERE
        MTH.ScriptName IS NULL;

ELSE

    SELECT
        MS.*
    FROM
        (
            << ModifyTableScripts >>
        ) MS;

END IF;