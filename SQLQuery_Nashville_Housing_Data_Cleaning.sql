-- Standardise the Date Format

Select SaleDate, CONVERT(Date,Saledate) --showing the two date formats
From Nashville_Housing_Project.dbo.NashvilleHousing

Update NashvilleHousing --updating the table with the new sales date format using convert
SET SaleDate = CONVERT(Date, Saledate) -- Using convert here but could use the ALTER I do later to change the SoldAsVacant?

Select *
FROM NashvilleHousing
ORDER BY Saledate

-- Populate Property Address Data

Select *
From Nashville_Housing_Project.dbo.NashvilleHousing
Where PropertyAddress is Null -- you can see the properties that have no property address input

---- you can also see from the data that there is a unique parcel ID for each property address 
---- so if there is a property address associated to the parcel ID you can fill in any property 
---- address blanks for subsequent parcel IDs. 

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress) --use the ISNULL to say if the value is null then replace a.propertyaddress with b.property address
From Nashville_Housing_Project.dbo.NashvilleHousing as a --joining the table to itself using the parcel ID
JOIN Nashville_Housing_Project.dbo.NashvilleHousing as b
    ON a.ParcelID = b.ParcelID
    and a.[uniqueID] <> b.[UniqueID] -- this says where the unique IDs are NOT equal
Where a.PropertyAddress is NULL -- this only cares about the ones where the values in a are null

----To update the table we use update and then set to change to the new values.
update a --using the table alias
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From Nashville_Housing_Project.dbo.NashvilleHousing as a --joining the table to itself using the parcel ID
JOIN Nashville_Housing_Project.dbo.NashvilleHousing as b
    ON a.ParcelID = b.ParcelID
    and a.[uniqueID] <> b.[UniqueID]
Where a.PropertyAddress is NULL

-- Breaking out Address into Individual Columns (Address, City, State)

Select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as address -- the substring here asks for the column, the start and then the end position. 
-- The end position is set using CHARINDEX to locate the comma 
-- so the new substring is from position 1 until this comma i.e. removing anything after. 
-- The -1 then selects everything before the comma and if not include then the new substring will have a comma attached to it.
FROM NashvilleHousing

Select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, len(propertyaddress)) as CityAddress
FROM NashvilleHousing

--create 2 new columns to add values in
---- Add column for Split Address and Split City
ALTER TABLE NashvilleHousing 
ADD PropertySplitAddress NVARCHAR(255) -- adding New column to the end of the table

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255)

----Set the values for the new columns
Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) 

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, len(propertyaddress))



-- Using parsename to sort the owner address column
Select
parsename (Replace(OwnerAddress,',', '.') ,3),
parsename (Replace(OwnerAddress,',', '.') ,2),
parsename (Replace(OwnerAddress,',', '.') ,1)
From Nashville_Housing_Project.dbo.NashvilleHousing


----Adding new columns and values
ALTER TABLE NashvilleHousing 
ADD 
OwnerSplitAddress NVARCHAR(255), 
OwnerSplitCity NVARCHAR(255),
OwnerSplitState NVARCHAR(255)

Select*
FROM NashvilleHousing

UPDATE NashvilleHousing
SET 
OwnerSplitAddress = parsename (Replace(OwnerAddress,',', '.') ,3),
OwnerSplitCity = parsename (Replace(OwnerAddress,',', '.') ,2),
OwnerSplitState = parsename (Replace(OwnerAddress,',', '.') ,1)

--ALTER TABLE NashvilleHousing DROP COLUMN OwnerSplitAddress, OwnerSpiltCity, OwnerSplitState -- Removing columns to rename without spelling error

--Change Y and N to Yes and No

----CAST(expression AS datatype(length))
Select Distinct(cast(SoldAsVacant AS varchar(255)))
from Nashville_Housing_Project.dbo.NashvilleHousing

----Updating the table to change the variable type for the SoldAsVacant column permanently
ALTER TABLE Nashville_Housing_Project.dbo.NashvilleHousing
ALTER COLUMN SoldAsVacant varchar(255)

----ALTER TABLE <dbo.YourTableHere>
----ALTER COLUMN <YourTextColumnHere> VARCHAR(MAX)

Select SoldAsVacant
, CASE when SoldAsVacant = 'Y' Then 'Yes'
       when SoldAsVacant = 'N' Then 'No'
       Else SoldAsVacant
       END
from Nashville_Housing_Project.dbo.NashvilleHousing

Update NashvilleHousing
Set SoldAsVacant = CASE when SoldAsVacant = 'Y' Then 'Yes'
       when SoldAsVacant = 'N' Then 'No'
       Else SoldAsVacant
       END
    from Nashville_Housing_Project.dbo.NashvilleHousing

Select distinct(SoldAsVacant), count(SoldAsVacant)
From NashvilleHousing
Group By SoldAsVacant
order by 2

--Remove Duplicates

----Again, you can't do certain things with TEXT type so change these to Varchar
ALTER TABLE Nashville_Housing_Project.dbo.NashvilleHousing
ALTER COLUMN SalePrice nvarchar(255)
--ALTER COLUMN LegalReference varchar(255) or Uniqueidentifier ?? Can't get this to work with Partition by below so removed it from argument...

Select*
From NashvilleHousing

WITH RowNumCTE AS (
Select *,
    ROW_NUMBER() OVER (
        PARTITION BY ParcelID,
                     PropertyAddress,
                     SalePrice,
                     SaleDate
                     ORDER BY 
                        UniqueID
                        ) as row_num
    From Nashville_Housing_Project.dbo.NashvilleHousing
)

SELECT * 
From RowNumCTE
Where row_num >1 

-- Delete Unused Columns
----Don't do this to raw data or tables without permission

ALTER TABLE Nashville_Housing_Project.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress