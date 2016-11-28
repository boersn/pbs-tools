-- Last modified by RH (2014-06-23)
-- Query species catch from GFFOS on DFBCV9TWVASP001
SET NOCOUNT ON 

-- Trip Hail
SELECT
  H.TRIP_ID,
  Min(H.HAIL_NUMBER) AS HAIL_NUMBER
INTO #TRIP_HAIL
FROM  GF_HAIL_NUMBER H 
WHERE H.HAIL_TYPE='OUT'
GROUP BY  H.TRIP_ID
ORDER BY  H.TRIP_ID

-- HAIL & SET HS
SELECT
  FE.TRIP_ID,
  FE.FISHING_EVENT_ID,
  ISNULL(TH.HAIL_NUMBER,0) AS HAIL_NUMBER,
  ISNULL(FE.SET_NUMBER,9999) AS SET_NUMBER,
  ISNULL(TS.SUCCESS_CODE,0) AS SUCCESS_CODE
INTO #HAIL_SET
FROM
  #TRIP_HAIL TH RIGHT OUTER JOIN
  GF_FISHING_EVENT FE ON
    TH.TRIP_ID = FE.TRIP_ID LEFT OUTER JOIN 
  GF_FE_TRAWL_SPECS TS
    ON FE.FISHING_EVENT_ID = TS.FISHING_EVENT_ID
ORDER BY FE.TRIP_ID, FE.FISHING_EVENT_ID

-- MEAN SPECIES WEIGHT MW
SELECT
  MW.spp as \"spp\",
  Avg(CASE
    WHEN MW.unit='PND' THEN MW.mnwt/2.20459  -- standardises mean species weight in kg
    ELSE MW.mnwt END) as \"mnwt\",
  Sum(MW.n) as \"n\"
INTO #MEAN_WEIGHT
FROM
  (SELECT  -- inline view calculates empirical mean weights for species (in lbs and/or kg)
    C.SPECIES_CODE AS spp,
    C.WEIGHT_UNIT_CODE AS unit,
    Sum(C.CATCH_WEIGHT) AS wt,
    Sum(C.CATCH_COUNT) AS n,
    ISNULL(Avg(C.CATCH_WEIGHT/C.CATCH_COUNT),0) AS mnwt
    FROM GF_FE_CATCH C
    WHERE
      (C.CATCH_WEIGHT>0 And C.CATCH_WEIGHT Is Not Null) AND 
      (C.CATCH_COUNT>1 And C.CATCH_COUNT Is Not Null) AND    -- only calculate means from records with more than one fish
      C.WEIGHT_UNIT_CODE IN ('PND','KGM')
    GROUP BY C.SPECIES_CODE, C.WEIGHT_UNIT_CODE) MW
GROUP BY MW.spp
ORDER BY MW.spp

-- SPECIES CATCH CC
SELECT
  OC.TRIP_ID,
  OC.FISHING_EVENT_ID,
  Sum(CASE
    WHEN OC.SPECIES_CODE IN (@sppcode) THEN ISNULL(OC.LANDED_ROUND_KG,0)
    ELSE 0 END) AS landed,
  Sum(CASE
    WHEN OC.SPECIES_CODE IN (@sppcode) THEN
      COALESCE(OC.TOTAL_RELEASED_ROUND_KG,
      (ISNULL(OC.SUBLEGAL_RELEASED_COUNT,0) + ISNULL(OC.LEGAL_RELEASED_COUNT,0)) * FW.MNWT, 0)
    ELSE 0 END) AS released,
  Sum(CASE
    WHEN OC.SPECIES_CODE IN (@sppcode) THEN
      (ISNULL(OC.SUBLEGAL_LICED_COUNT,0) + ISNULL(OC.LEGAL_LICED_COUNT,0)) * FW.MNWT
    ELSE 0 END) AS liced,
  Sum(CASE
    WHEN OC.SPECIES_CODE IN (@sppcode) THEN
      (ISNULL(OC.SUBLEGAL_BAIT_COUNT,0) + ISNULL(OC.LEGAL_BAIT_COUNT,0)) * FW.MNWT
    ELSE 0 END) AS bait,
  Sum(
    ISNULL(OC.LANDED_ROUND_KG,0) +
    COALESCE(OC.TOTAL_RELEASED_ROUND_KG,
    (ISNULL(OC.SUBLEGAL_RELEASED_COUNT,0) + ISNULL(OC.LEGAL_RELEASED_COUNT,0)) * FW.MNWT, 0) +
    (ISNULL(OC.SUBLEGAL_LICED_COUNT,0) + ISNULL(OC.LEGAL_LICED_COUNT,0)) * FW.MNWT +
    (ISNULL(OC.SUBLEGAL_BAIT_COUNT,0) + ISNULL(OC.LEGAL_BAIT_COUNT,0)) * FW.MNWT
  ) AS totcat
INTO #SPECIES_CATCH
FROM GF_D_OFFICIAL_FE_CATCH OC INNER JOIN
  -- FISH WEIGHTS FW
  #MEAN_WEIGHT FW ON
    OC.SPECIES_CODE = FW.SPP
  GROUP BY OC.TRIP_ID, OC.FISHING_EVENT_ID 

SELECT
  (CASE
    WHEN FC.FISHERY_SECTOR IN ('GROUNDFISH TRAWL') THEN 1
    WHEN FC.FISHERY_SECTOR IN ('HALIBUT','HALIBUT AND SABLEFISH') THEN 2
    WHEN FC.FISHERY_SECTOR IN ('SABLEFISH') THEN 3
    WHEN FC.FISHERY_SECTOR IN ('LINGCOD','SPINY DOGFISH') THEN 4
    WHEN FC.FISHERY_SECTOR IN ('ROCKFISH INSIDE','ROCKFISH OUTSIDE') THEN 5
    ELSE 0 END) AS FID,
  FC.TRIP_ID AS TID,
  FC.FISHING_EVENT_ID AS FEID,
  HS.HAIL_NUMBER AS \"hail\",
  HS.SET_NUMBER  AS \"set\",
  ISNULL(FC.DATA_SOURCE_CODE,0) AS \"log\",
  CASE WHEN FC.LON IS NULL THEN NULL ELSE CAST(ROUND(FC.LON,7) AS NUMERIC(15,7)) END AS X,
  CASE WHEN FC.LAT IS NULL THEN NULL ELSE CAST(ROUND(FC.LAT,7) AS NUMERIC(15,7)) END AS Y,
  FC.BEST_DATE AS \"date\", 
  CASE WHEN FC.BEST_DATE IS NULL THEN '9999' ELSE CAST(YEAR(FC.BEST_DATE) AS CHAR(4)) END AS \"year\",
  ISNULL(FC.MAJOR_STAT_AREA_CODE,'0') AS \"major\",
  ISNULL(FC.MINOR_STAT_AREA_CODE,'0') AS \"minor\",
  ISNULL(FC.LOCALITY_CODE,0) AS \"locality\",
  ISNULL(FC.DFO_STAT_AREA_CODE,'0') AS \"pfma\",
  ISNULL(FC.DFO_STAT_SUBAREA_CODE,0) AS \"pfms\",
  ISNULL(FC.BEST_DEPTH_FM,0) * 6. * 0.3048 AS \"depth\",  -- convert fathoms to metres
  ISNULL(FC.VESSEL_REGISTRATION_NUMBER,0) AS \"vessel\",
  CASE
    WHEN FC.GEAR IN ('TRAWL') AND FC.GEAR_SUBTYPE NOT IN ('MIDWATER TRAWL') THEN 1
    WHEN FC.GEAR IN ('TRAP') THEN 2
    WHEN FC.GEAR IN ('TRAWL') AND FC.GEAR_SUBTYPE IN ('MIDWATER TRAWL') THEN 3
    WHEN FC.GEAR IN ('HOOK AND LINE') THEN 4
    WHEN FC.GEAR IN ('LONGLINE') THEN 5
    WHEN FC.GEAR IN ('LONGLINE OR HOOK AND LINE','TRAP OR LONGLINE OR HOOK AND LINE') THEN 8
    ELSE 0 END AS \"gear\",
  ISNULL(HS.SUCCESS_CODE,0) AS \"success\",
  CASE WHEN FC.START_DATE IS NOT NULL AND FC.END_DATE IS NOT NULL THEN
    DATEDIFF(n,FC.START_DATE,FC.END_DATE) ELSE 0 END AS \"effort\",   --effort in minutes
  CC.landed+CC.released+CC.liced+CC.bait AS \"catKg\",
  CASE
    WHEN (CC.landed+CC.released+CC.liced+CC.bait) = 0 THEN 0
    ELSE (CC.released+CC.liced+CC.bait)/(CC.landed+CC.released+CC.liced+CC.bait)
    END AS \"pdis\",  -- proportion discarded
  CASE
    WHEN CC.totcat = 0 THEN 0
    ELSE (CC.landed+CC.released+CC.liced+CC.bait)/CC.totcat
    END AS \"pcat\"   -- proportion of total catch
FROM 
  -- HAIL SET HS
  #HAIL_SET HS INNER JOIN

  -- OFFICIAL CATCH FC
  GF_D_OFFICIAL_FE_CATCH FC
    ON FC.TRIP_ID = HS.TRIP_ID AND
    FC.FISHING_EVENT_ID = HS.FISHING_EVENT_ID INNER JOIN

  -- SPECIES CATCH CC
  #SPECIES_CATCH CC ON
    FC.TRIP_ID = CC.TRIP_ID AND
    FC.FISHING_EVENT_ID = CC.FISHING_EVENT_ID 

WHERE 
  FC.SPECIES_CODE IN (@sppcode) AND 
  (FC.FISHERY_SECTOR IN ('GROUNDFISH TRAWL') OR 
  (FC.FISHERY_SECTOR NOT IN ('GROUNDFISH TRAWL') AND ISNULL(FC.DATA_SOURCE_CODE,0) NOT IN (106,107)))

ORDER BY FC.TRIP_ID, FC.FISHING_EVENT_ID


-- getData("fos_catch_records.sql","GFFOS",strSpp="401")

