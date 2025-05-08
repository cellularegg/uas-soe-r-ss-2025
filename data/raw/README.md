## Dataset Description

**Source:**
- Data and Data Description: [Pierce County Data Downloads](https://www.piercecountywa.gov/736/Data-Downloads)
- Format: Pipe-delimited text files with accompanying PDF metadata
- Update Frequency: Weekly updates available from Pierce County
- **Date Extracted: 05/02/2025**

**Dataset Overview:**

| Table Name | Description | Columns | Key Fields |
|------------|-------------|---------|------------|
| `sale.txt` | Property transactions | 13 | ETN, Parcel_Number |
| `appraisal_account.txt` | Property characteristics | 24 | Parcel_Number |
| `improvement.txt` | Building details | 25 | Parcel_Number, Building_ID |
| `improvement_detail.txt` | Specific improvement features | 5 | Parcel_Number, Building_ID, Detail_Type |
| `improvement_builtas.txt` | Construction details | 26 | Parcel_Number, Building_ID, Built_As_Number |
| `land_attribute.txt` | Land characteristics | 3 | Parcel_Number, Attribute_Key |
| `seg_merge.txt` | Property boundary changes | 6 | Seg_Merge_Number, Parcel_Number |
| `tax_account.txt` | Tax information | 28 | Parcel_Number |
| `tax_description.txt` | Legal descriptions | 3 | Parcel_Number, Line_Number |