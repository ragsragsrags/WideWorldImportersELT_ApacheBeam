SELECT
    [SpecialDealID],
    [StockItemID],
    [CustomerID],
    [BuyingGroupID],
    [CustomerCategoryID],
    [StockGroupID],
    [DealDescription],
    [StartDate],
    [EndDate],
    [DiscountAmount],
    [DiscountPercentage],
    [UnitPrice],
    [LastEditedBy],
    [LastEditedWhen] = LEFT(CONVERT(NVARCHAR, LastEditedWhen, 121), 26),
    [LoadDate] = LEFT(CONVERT(NVARCHAR, CAST('<< NewCutoffDate >>' AS DATETIME2(6)), 121), 26)
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    SpecialDealID,
    LastEditedWhen

OFFSET 0 ROW