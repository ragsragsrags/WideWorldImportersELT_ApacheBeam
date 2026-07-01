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
    [ValidFrom],
    [ValidTo],
    [LoadDate] = CAST('<< NewCutoffDate >>' AS DATETIME2(6))
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