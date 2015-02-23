# FAOSTAT FBS Relationships
Tables of relationships between FAOSTAT Food Balance Sheet items

Create tables describing the intended relationship between FAOSTAT Food Balance Sheet (FBS) items.
The 'Processing' FBS element is intended to show the quantity of the food item that is listed as a derived/manufactured product
Using both Processing and Food elements can therefore result in double-counting if relationships between items are not taken into  account.

Two sources are used:
 1. The Food Balance Sheet classification
    (http://faostat3.fao.org/mes/classifications/E)
    This document lists the commodities that make up each food item
 2. The Definition and Classification of Commodities
    (http://www.fao.org/es/faodef/faodefe.htm)
    This document describes primary agricultural commodities and their 
    derived, processed products.
    
"fbs_processed.csv" has the following columns:
* IncludedInCode - FBS item code
* IncludedInName - FBS item name
* IncludedNames - list of FAOSTAT commodities included in that FBS item
* FoodInclProcessed - TRUE if the Food element definitely includes commodities that are considered processed. FALSE if the Food element definitely doesn't. NA if there's not enough information.
* DependsOnCode - Comma-separated codes for other FBS items on which this item depends, i.e. from which it is processed
* ProcessedAppearsInCode - Comma-separated codes for other FBS items which are processed forms of this item
* DependsOnName - Name corresponding to DependsOnCode if there's only one
* ProcessedAppearsInName - Name corresponding to ProcessedAppearsInCode if there's only one

It is worth noting:
- If ProcessedAppearsInCode is not empty, then the Processing element is intended to appear elsewhere, and there is therefore a risk of double-counting.
- If DependsOnCode is not empty, then the item is at least partially Processed from other items - there is also a risk of double-counting.
- If FoodInclProcessed is TRUE, then treating the item as fresh underestimates processing losses - but we don't have any information about proportion that is processed.


This table is automatically built from the two sources, with the intermediate products also provided in csv format.

1. Definition and Classification of Commodities - "derived_products.csv"
 * FAOSTATCODE - Commodity code, corresponding to ProductCode in the other tables here
 * COMMODITY - Name of the commodity
 * DEFINITION - Text given as definition for the commodity in this document
 * DerivedCode - If processed, the FAOSTATCODE from which the commodity is derived. If primary, the value 0. If processed and the commodity from which it is derived is unclear, the value -1.

2. The Food Balance Sheet classification - "fbs_classification.csv", to which data from the Definition and Classification of Commodities was then added.
 * ProductCode & ProductName - commodity
 * IncludedInCode & IncludedInName - FBS classification that the commodity belongs to.
 * DerivedCode: the ProductCode from which the commodity is derived
 * DerivedIncludedInCode: the corresponding IncludedInCode (FBS item code) from which the commodity is derived

These tables are provided without warranty. They are based on automatically processing publicly available documents.
As you'll probably notice, these tables are incomplete and still slightly inconsistent with the data. 
There are cases where Processing is greater than zero even though the product group is completely based on primary products, and it has no listed derived products, e.g. sweet potatoes.

