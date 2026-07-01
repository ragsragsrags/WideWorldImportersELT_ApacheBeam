SELECT 
    COUNT(*)
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    ValidFrom > '<< LastCutoffDate >>' AND	
    ValidFrom <= '<< NewCutoffDate >>'