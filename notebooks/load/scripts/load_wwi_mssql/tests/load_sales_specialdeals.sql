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
    [LastEditedWhen], 
    [LoadDate]
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'
ORDER BY
    SpecialDealID,
    LastEditedWhen

OFFSET 0 ROWS
FETCH NEXT << NumberOfRows >> ROWS ONLY