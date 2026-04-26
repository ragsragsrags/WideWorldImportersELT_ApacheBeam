DECLARE @MaxStockHoldingKey INT 
    
SELECT
    @MaxStockHoldingKey = ISNULL(MAX(StockHoldingKey), 0)
FROM
    {{ FctStockHoldings }}

IF OBJECT_ID('tempdb..#FctStockHoldings') IS NOT NULL
    DROP TABLE #FctStockHoldings

;WITH final AS (

	SELECT
		[StockHoldingKey] = 
			CASE
				WHEN FSH.StockHoldingKey IS NULL THEN @MaxStockHoldingKey + (ROW_NUMBER() OVER (ORDER BY FSH.StockHoldingKey, SI.StockItemKey))
				ELSE FSH.StockHoldingKey
			END,
		[StockItemKey] = ISNULL(SI.StockItemKey, 0),
		[QuantityOnHand] = SIH.QuantityOnHand,
		[BinLocation] = SIH.BinLocation,
		[LastStocktakeQuantity] = SIH.LastStocktakeQuantity,
		[LastCostPrice] = SIH.LastCostPrice,
		[ReorderLevel] = SIH.ReorderLevel,
		[TargetStockLevel] = SIH.TargetStockLevel,
		[LoadDate] = '<< NewCutoffDate >>',
		[Exists] = 
			CASE
				WHEN FSH.StockHoldingKey IS NULL THEN CAST(0 AS BIT)
				ELSE CAST(1 AS BIT)
			END
	FROM 
		{{ WarehouseStockItemHoldings }} SIH JOIN
		{{ DimStockItems }} SI ON
			SI.WWIStockItemID = SIH.StockItemID LEFT JOIN
		{{ FctStockHoldings }} FSH ON
			FSH.StockItemKey  = SI.StockItemKey
	WHERE 
		SIH.LastEditedWhen > '<< LastCutoffDate >>' AND
		SIH.LastEditedWhen <= '<< NewCutoffDate >>'
)

SELECT 
	*
INTO
	#FctStockHoldings
FROM
	final

BEGIN TRAN

-- Update Existing
UPDATE
	SH2
SET
	SH2.StockItemKey = SH.StockItemKey,
	SH2.QuantityOnHand = SH.QuantityOnHand,
	SH2.BinLocation = SH.BinLocation,
	SH2.LastStocktakeQuantity = SH.LastStocktakeQuantity,
	SH2.LastCostPrice = SH.LastCostPrice,
	SH2.ReorderLevel = SH.ReorderLevel,
	SH2.TargetStockLevel = SH.TargetStockLevel,
	SH2.LoadDate = SH.LoadDate
FROM
	#FctStockHoldings SH JOIN
	{{ FctStockHoldings }} SH2 ON
		SH2.StockItemKey = SH.StockItemKey
WHERE
	SH.[Exists] = 1

-- Insert New
INSERT INTO {{ FctStockHoldings }}
(
	StockHoldingKey,
	StockItemKey,
	QuantityOnHand,
	BinLocation,
	LastStocktakeQuantity,
	LastCostPrice,
	ReorderLevel,
	TargetStockLevel,
	LoadDate
)
SELECT
	SH.StockHoldingKey,
	SH.StockItemKey,
	SH.QuantityOnHand,
	SH.BinLocation,
	SH.LastStocktakeQuantity,
	SH.LastCostPrice,
	SH.ReorderLevel,
	SH.TargetStockLevel,
	SH.LoadDate
FROM
	#FctStockHoldings SH LEFT JOIN
	{{ FctStockHoldings }} SH2 ON
		SH2.StockItemKey = SH.StockItemKey
WHERE
	SH.[Exists] = 0
ORDER BY
	SH.StockHoldingKey

COMMIT TRAN