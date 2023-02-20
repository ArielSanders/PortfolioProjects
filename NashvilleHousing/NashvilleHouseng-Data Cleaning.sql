/*
	Cleaning Data
*/

SELECT *
FROM NashvilleHousing;

--Standarize sale date format
SELECT 
	SaleDate,
	CONVERT(date, SaleDate) AS new_sales_date
FROM NashvilleHousing;

UPDATE NashvilleHousing
SET SaleDate = CONVERT(date, SaleDate);

--Or
ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate date;


--Populate property address
--Some of the parcel id's are linked to the same property address
SELECT *
FROM NashvilleHousing
ORDER BY ParcelID;

SELECT
	a.ParcelID,
	a.PropertyAddress,
	b.ParcelID,
	b.PropertyAddress,
	ISNULL(a.PropertyAddress, b.PropertyAddress) AS populated_address
FROM NashvilleHousing a
JOIN NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;


--Spliting property address into individual columns (address, city)
--Using substring. +1 and -1 makes sure the comma isn't included
SELECT PropertyAddress
FROM NashvilleHousing;

SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as city
FROM NashvilleHousing;

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress));


--Spliting owner address into individual columns (address, city, state)
--Using parsename. Parsename looks for periods for splits
SELECT OwnerAddress
FROM NashvilleHousing;

SELECT
	PARSENAME(REPLACE(OwnerAddress,',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress,',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)
FROM NashvilleHousing;

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',', '.'), 3);

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',', '.'), 2);


ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',', '.'), 1);


--Change Y and N to Yes and No in sold as vacant
SELECT 
	DISTINCT(SoldAsVacant)
FROM NashvilleHousing;

SELECT
	SoldAsVacant,
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END
FROM NashvilleHousing;

UPDATE NashvilleHousing
SET SoldAsVacant = 
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END;


--Remove Duplicates. Not a standard process for raw data
--Removes based off rows that shouldn't all be the same
WITH RowNumCTE AS(
	SELECT *,
		ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS row_num
	FROM NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

WITH RowNumCTE AS(
	SELECT *,
		ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS row_num
	FROM NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1;


--Delete unused columns. Not a standard process for raw data
SELECT *
FROM NashvilleHousing;

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress,
			OwnerAddress,
			TaxDistrict;