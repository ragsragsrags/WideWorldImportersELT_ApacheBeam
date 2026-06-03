SELECT
    [StockItemID],
    [StockItemName],
    [SupplierID],
    [ColorID],
    [UnitPackageID],
    [OuterPackageID],
    [Brand],
    [Size],
    [LeadTimeDays],
    [QuantityPerOuter],
    [IsChillerStock],
    [Barcode],
    [TaxRate],
    [UnitPrice],
    [RecommendedRetailPrice],
    [TypicalWeightPerUnit],
    [MarketingComments],
    [InternalComments],
    [Photo],
    [CustomFields],
    [Tags],
    [SearchDetails],
    [LastEditedBy],
    [ValidFrom] = LEFT(CONVERT(NVARCHAR, ValidFrom, 121), 26), 
    [ValidTo] = LEFT(CONVERT(NVARCHAR, ValidTo, 121), 26),
    [LoadDate] = LEFT(CONVERT(NVARCHAR, CAST('<< NewCutoffDate >>' AS DATETIME2(6)), 121), 26)
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    ValidFrom > '<< LastCutoffDate >>'  AND	
    ValidFrom <= '<< NewCutoffDate >>'
ORDER BY
    StockItemID,
    ValidFrom,
    ValidTo

OFFSET 0 ROW