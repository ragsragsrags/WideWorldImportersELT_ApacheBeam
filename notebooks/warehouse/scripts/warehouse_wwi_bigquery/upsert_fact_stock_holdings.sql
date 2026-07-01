DECLARE MaxStockHoldingKey INT64;

SET MaxStockHoldingKey = 
(
    SELECT
        IFNULL(MAX(StockHoldingKey), 0)
    FROM
        {{ FctStockHoldings }}
);

CREATE TEMP TABLE TempFctStockHoldings AS
WITH final AS (

	SELECT
		CASE
			WHEN FSH.StockHoldingKey IS NULL THEN CAST(MaxStockHoldingKey AS INTEGER) + (ROW_NUMBER() OVER (ORDER BY FSH.StockHoldingKey, SI.StockItemKey))
			ELSE FSH.StockHoldingKey
		END AS StockHoldingKey,
		IFNULL(SI.StockItemKey, 0) AS StockItemKey,
		SIH.QuantityOnHand AS QuantityOnHand,
		SIH.BinLocation AS BinLocation,
		SIH.LastStocktakeQuantity AS LastStocktakeQuantity,
		SIH.LastCostPrice AS LastCostPrice,
		SIH.ReorderLevel AS ReorderLevel,
		SIH.TargetStockLevel AS TargetStockLevel,
		CAST('<< NewCutoffDate >>' AS DATETIME) AS LoadDate,
		CASE
			WHEN FSH.StockHoldingKey IS NULL THEN CAST(FALSE AS BOOLEAN)
			ELSE CAST(TRUE AS BOOLEAN)
		END AS Exist
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
FROM
	final;

-- Update Existing
UPDATE
	{{ FctStockHoldings }} SH2
SET
	SH2.StockItemKey = SH.StockItemKey,
	SH2.QuantityOnHand = SH.QuantityOnHand,
	SH2.BinLocation = SH.BinLocation,
	SH2.LastStocktakeQuantity = SH.LastStocktakeQuantity,
	SH2.LastCostPrice = SH.LastCostPrice,
	SH2.ReorderLevel = SH.ReorderLevel,
	SH2.TargetStockLevel = SH.TargetStockLevel,
	SH2.LoadDate = SH.LoadDate,
	SH2.LastLoadDate = SH2.LoadDate
FROM
	TempFctStockHoldings SH 
WHERE
	SH.Exist = TRUE AND
	SH2.StockItemKey = SH.StockItemKey;

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
	LoadDate,
	LastLoadDate
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
	SH.LoadDate,
	CAST(NULL AS DATETIME)
FROM
	TempFctStockHoldings SH
WHERE
	SH.Exist = FALSE
ORDER BY
	SH.StockHoldingKey;