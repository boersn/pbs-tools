-- Query catch gathered from multiple DBs and housed in GF_MERGED_CATCH
-- Query species catch from GFFOS on DFBCV9TWVASP001
-- Last modified: 2016-04-12 (RH)
SET NOCOUNT ON 

-- Mean species weight calculated using `gfb_mean_weight.sql', which emulates PJS algorithm for GFBIO data
@INSERT('meanSppWt.sql')  -- getData now inserts the specified SQL file assuming it's on the `path' specified in `getData'
-- Usage: SELECT FW.MEAN_WEIGHT FROM @MEAN_WEIGHT FW WHERE FW.SPECIES_CODE IN('222')

-- Gather catch of RRF, POP, ORF, TAR
SELECT --TOP 200
  MC.DATABASE_NAME,
  MC.TRIP_ID,
  MC.FISHING_EVENT_ID,
  --ISNULL(L.LOCALITY_DESCRIPTION,'MOOSE COUNTY') AS LOCAL_NAME,
  Sum(CASE
    WHEN MC.SPECIES_CODE IN (@sppcode) THEN COALESCE(NULLIF(MC.LANDED_KG,0), NULLIF(MC.LANDED_PCS*FW.MNWT,0), 0)
    ELSE 0 END) AS landed,
  Sum(CASE
    WHEN MC.SPECIES_CODE IN (@sppcode) THEN COALESCE(NULLIF(MC.DISCARDED_KG,0), NULLIF(MC.DISCARDED_PCS*FW.MNWT,0), 0)
    ELSE 0 END) AS discard,
  SUM(CASE
    WHEN MC.SPECIES_CODE IN ('396') THEN COALESCE(NULLIF(MC.LANDED_KG,0), NULLIF(MC.LANDED_PCS*FW.MNWT,0), 0)
    ELSE 0 END) AS POP,
  SUM(CASE  -- all rockfish other than POP
    WHEN MC.SPECIES_CODE IN (@orfcode) THEN COALESCE(NULLIF(MC.LANDED_KG,0), NULLIF(MC.LANDED_PCS*FW.MNWT,0), 0)
    ELSE 0 END) AS ORF,
  SUM(CASE  -- target landings reference for discard calculations
    WHEN MC.FISHERY_SECTOR IN ('GROUNDFISH TRAWL','JOINT VENTURE TRAWL') AND MC.SPECIES_CODE IN (@trfcode)
      THEN COALESCE(NULLIF(MC.LANDED_KG,0), NULLIF(MC.LANDED_PCS*FW.MNWT,0), 0)
    WHEN MC.FISHERY_SECTOR IN ('HALIBUT','HALIBUT AND SABLEFISH','K/L') AND MC.SPECIES_CODE IN ('614')
      THEN COALESCE(NULLIF(MC.LANDED_KG,0), NULLIF(MC.LANDED_PCS*FW.MNWT,0), 0)
    WHEN MC.FISHERY_SECTOR IN ('SABLEFISH') AND MC.SPECIES_CODE IN ('454','455')
      THEN COALESCE(NULLIF(MC.LANDED_KG,0), NULLIF(MC.LANDED_PCS*FW.MNWT,0), 0)
    WHEN MC.FISHERY_SECTOR IN ('SPINY DOGFISH') AND MC.SPECIES_CODE IN ('042','044')
      THEN COALESCE(NULLIF(MC.LANDED_KG,0), NULLIF(MC.LANDED_PCS*FW.MNWT,0), 0)
    WHEN MC.FISHERY_SECTOR IN ('LINGCOD') AND MC.SPECIES_CODE IN ('467')
      THEN COALESCE(NULLIF(MC.LANDED_KG,0), NULLIF(MC.LANDED_PCS*FW.MNWT,0), 0)
    WHEN MC.FISHERY_SECTOR IN ('SCHEDULE II') AND MC.SPECIES_CODE IN ('042','044','467')
      THEN COALESCE(NULLIF(MC.LANDED_KG,0), NULLIF(MC.LANDED_PCS*FW.MNWT,0), 0)
    WHEN MC.FISHERY_SECTOR IN ('ROCKFISH INSIDE','ROCKFISH OUTSIDE','ZN','K/ZN') AND MC.SPECIES_CODE IN ('424','407','431','433','442')
      THEN COALESCE(NULLIF(MC.LANDED_KG,0), NULLIF(MC.LANDED_PCS*FW.MNWT,0), 0)
    ELSE 0 END) AS TAR
INTO #CATCH_CORE
FROM 
  GF_MERGED_CATCH MC LEFT OUTER JOIN
  @MEAN_WEIGHT FW ON
    MC.SPECIES_CODE = FW.SPECIES_CODE
GROUP BY MC.DATABASE_NAME, MC.TRIP_ID, MC.FISHING_EVENT_ID


-- Collect area information (which can differ within a fishing event depending on the species)
-- This madness significantly increases the running time of the query!!!
SELECT --top 100
  MC.DATABASE_NAME, MC.TRIP_ID, MC.FISHING_EVENT_ID,
  ISNULL(MC.MAJOR_STAT_AREA_CODE,'0') AS MAJOR,
  ISNULL(MC.MINOR_STAT_AREA_CODE,'0') AS MINOR,
  ISNULL(MC.LOCALITY_CODE,'0') AS LOCALITY,
  COUNT(ISNULL(MC.MAJOR_STAT_AREA_CODE,'0')) OVER (PARTITION BY MC.DATABASE_NAME, MC.TRIP_ID, MC.FISHING_EVENT_ID, ISNULL(MC.MAJOR_STAT_AREA_CODE,'0')) AS COUNT_MAJOR,
  COUNT(ISNULL(MC.MINOR_STAT_AREA_CODE,'0')) OVER (PARTITION BY MC.DATABASE_NAME, MC.TRIP_ID, MC.FISHING_EVENT_ID, ISNULL(MC.MINOR_STAT_AREA_CODE,'0')) AS COUNT_MINOR,
  COUNT(ISNULL(MC.LOCALITY_CODE,'0')) OVER (PARTITION BY MC.DATABASE_NAME, MC.TRIP_ID, MC.FISHING_EVENT_ID, ISNULL(MC.LOCALITY_CODE,'0')) AS COUNT_LOCALITY
INTO #COUNT_DRACULA
FROM 
  GF_MERGED_CATCH MC
--WHERE
--  MC.TRIP_ID IN ('20905002','20905004','20905009')
ORDER BY MC.DATABASE_NAME, MC.TRIP_ID, MC.FISHING_EVENT_ID

--select * from #COUNT_DRACULA

-- Collect a unique major area for the fishing event (most frequently used)
SELECT T1.DATABASE_NAME, T1.TRIP_ID, T1.FISHING_EVENT_ID, T1.MAJOR
INTO #UNIQUE_MAJOR
FROM (SELECT ROW_NUMBER() OVER(PARTITION BY CD.DATABASE_NAME, CD.TRIP_ID, CD.FISHING_EVENT_ID ORDER BY CD.COUNT_MAJOR DESC) AS RN, * FROM #COUNT_DRACULA CD) T1
WHERE T1.RN<=1

-- Collect a unique minor area for the fishing event (most frequently used)
SELECT T2.DATABASE_NAME, T2.TRIP_ID, T2.FISHING_EVENT_ID, T2.MINOR
INTO #UNIQUE_MINOR
FROM (SELECT ROW_NUMBER() OVER(PARTITION BY CD.DATABASE_NAME, CD.TRIP_ID, CD.FISHING_EVENT_ID ORDER BY CD.COUNT_MINOR DESC) AS RN, * FROM #COUNT_DRACULA CD) T2
WHERE T2.RN<=1

-- Collect a unique locality for the fishing event (most frequently used)
SELECT T3.DATABASE_NAME, T3.TRIP_ID, T3.FISHING_EVENT_ID, T3.LOCALITY
INTO #UNIQUE_LOCALITY
FROM (SELECT ROW_NUMBER() OVER(PARTITION BY CD.DATABASE_NAME, CD.TRIP_ID, CD.FISHING_EVENT_ID ORDER BY CD.COUNT_LOCALITY DESC) AS RN, * FROM #COUNT_DRACULA CD) T3
WHERE T3.RN<=1

-- Tie the unique major, minor, and locilty areas together
SELECT
  UMAJ.DATABASE_NAME, UMAJ.TRIP_ID, UMAJ.FISHING_EVENT_ID,
  UMAJ.MAJOR AS MAJOR_STAT_AREA_CODE,
  UMIN.MINOR AS MINOR_STAT_AREA_CODE,
  ULOC.LOCALITY AS LOCALITY_CODE
INTO #AREAS
FROM 
  (#UNIQUE_MAJOR UMAJ INNER JOIN
  #UNIQUE_MINOR UMIN ON
    UMAJ.DATABASE_NAME = UMIN.DATABASE_NAME AND
    UMAJ.TRIP_ID = UMIN.TRIP_ID AND
    UMAJ.FISHING_EVENT_ID = UMIN.FISHING_EVENT_ID) INNER JOIN
  #UNIQUE_LOCALITY ULOC ON
    UMAJ.DATABASE_NAME = ULOC.DATABASE_NAME AND
    UMAJ.TRIP_ID = ULOC.TRIP_ID AND
    UMAJ.FISHING_EVENT_ID = ULOC.FISHING_EVENT_ID


-- Collect event information
SELECT --top 100
  MC.DATABASE_NAME,
  MC.TRIP_ID,
  MC.FISHING_EVENT_ID,
  (CASE
    WHEN MC.FISHERY_SECTOR IN ('GROUNDFISH TRAWL','JOINT VENTURE TRAWL') THEN 1
    WHEN MC.FISHERY_SECTOR IN ('HALIBUT','HALIBUT AND SABLEFISH','K/L') THEN 2
    WHEN MC.FISHERY_SECTOR IN ('SABLEFISH') THEN 3
    WHEN MC.FISHERY_SECTOR IN ('LINGCOD','SPINY DOGFISH','SCHEDULE II') THEN 4
    WHEN MC.FISHERY_SECTOR IN ('ROCKFISH INSIDE','ROCKFISH OUTSIDE','ZN','K/ZN') THEN 5
    WHEN MC.FISHERY_SECTOR IN ('FOREIGN') THEN 9
    ELSE 0 END) AS \"fid\",
  MC.FISHERY_SECTOR AS \"sector\",
  CASE
    WHEN MC.GEAR IN ('BOTTOM TRAWL','UNKNOWN TRAWL') THEN 1
    WHEN MC.GEAR IN ('TRAP') THEN 2
    WHEN MC.GEAR IN ('MIDWATER TRAWL') THEN 3
    WHEN MC.GEAR IN ('HOOK AND LINE') THEN 4
    WHEN MC.GEAR IN ('LONGLINE') THEN 5
    WHEN MC.GEAR IN ('LONGLINE OR HOOK AND LINE','TRAP OR LONGLINE OR HOOK AND LINE') THEN 8
    ELSE 0 END AS \"gear\",
  CASE
    WHEN MC.FISHING_EVENT_ID IN ('0') THEN 3   -- unidentified fishing events should all be DMP
    WHEN MC.LOG_TYPE IN ('OBSERVER LOG') THEN 1
    WHEN MC.LOG_TYPE IN ('FISHER LOG') THEN 2
    WHEN MC.LOG_TYPE IN ('DMP') THEN 3
    WHEN MC.LOG_TYPE IN ('UNKNOWN') THEN 0
    ELSE 0 END AS \"log\",
  --CONVERT(VARCHAR(10),COALESCE(MC.FE_START_DATE, MC.FE_END_DATE, MC.TRIP_START_DATE, MC.TRIP_END_DATE),20) as \"date\",
  CONVERT(VARCHAR(10),MC.BEST_DATE,20) as \"date\",
  ISNULL(A.MAJOR_STAT_AREA_CODE,'0') AS \"major\",
  ISNULL(A.MINOR_STAT_AREA_CODE,'0') AS \"minor\",
  ISNULL(A.LOCALITY_CODE,'0') AS \"locality\",
  --CC.LOCAL_NAME, -- for debugging locality names
  ISNULL(MC.BEST_DEPTH,0) AS \"fdep\",
  ISNULL(DATEDIFF(n,MC.FE_START_DATE,MC.FE_END_DATE),0) AS \"eff\"
INTO #EVENT_CORE
FROM 
  GF_MERGED_CATCH MC INNER JOIN 
  #AREAS A ON
    MC.DATABASE_NAME = A.DATABASE_NAME AND
    MC.TRIP_ID = A.TRIP_ID AND
    MC.FISHING_EVENT_ID = A.FISHING_EVENT_ID
--WHERE
  -- Langara Spit (Norm's choice based on the word "Langara" appearing in locality name)
  --(( MC.MAJOR_STAT_AREA_CODE IN (8) AND MC.MINOR_STAT_AREA_CODE IN (3) AND MC.LOCALITY_CODE IN (3) ) OR
  --( MC.MAJOR_STAT_AREA_CODE IN (9) AND MC.MINOR_STAT_AREA_CODE IN (35) AND MC.LOCALITY_CODE IN (1,2,4,5,6,7) ))
GROUP BY
  MC.DATABASE_NAME,
  MC.TRIP_ID,
  MC.FISHING_EVENT_ID,
  (CASE
    WHEN MC.FISHERY_SECTOR IN ('GROUNDFISH TRAWL','JOINT VENTURE TRAWL') THEN 1
    WHEN MC.FISHERY_SECTOR IN ('HALIBUT','HALIBUT AND SABLEFISH','K/L') THEN 2
    WHEN MC.FISHERY_SECTOR IN ('SABLEFISH') THEN 3
    WHEN MC.FISHERY_SECTOR IN ('LINGCOD','SPINY DOGFISH','SCHEDULE II') THEN 4
    WHEN MC.FISHERY_SECTOR IN ('ROCKFISH INSIDE','ROCKFISH OUTSIDE','ZN','K/ZN') THEN 5
    WHEN MC.FISHERY_SECTOR IN ('FOREIGN') THEN 9
    ELSE 0 END),
  MC.FISHERY_SECTOR,
  CASE
    WHEN MC.GEAR IN ('BOTTOM TRAWL','UNKNOWN TRAWL') THEN 1
    WHEN MC.GEAR IN ('TRAP') THEN 2
    WHEN MC.GEAR IN ('MIDWATER TRAWL') THEN 3
    WHEN MC.GEAR IN ('HOOK AND LINE') THEN 4
    WHEN MC.GEAR IN ('LONGLINE') THEN 5
    WHEN MC.GEAR IN ('LONGLINE OR HOOK AND LINE','TRAP OR LONGLINE OR HOOK AND LINE') THEN 8
    ELSE 0 END,
  CASE
    WHEN MC.FISHING_EVENT_ID IN ('0') THEN 3   -- unidentified fishing events should all be DMP
    WHEN MC.LOG_TYPE IN ('OBSERVER LOG') THEN 1
    WHEN MC.LOG_TYPE IN ('FISHER LOG') THEN 2
    WHEN MC.LOG_TYPE IN ('DMP') THEN 3
    WHEN MC.LOG_TYPE IN ('UNKNOWN') THEN 0
    ELSE 0 END,
  CONVERT(VARCHAR(10),MC.BEST_DATE,20),
  ISNULL(A.MAJOR_STAT_AREA_CODE,'0'),
  ISNULL(A.MINOR_STAT_AREA_CODE,'0'),
  ISNULL(A.LOCALITY_CODE,'0'),
  --CC.LOCAL_NAME, -- for debugging locality names
  ISNULL(MC.BEST_DEPTH,0),
  ISNULL(DATEDIFF(n,MC.FE_START_DATE,MC.FE_END_DATE),0)


-- Combine event information with catch
SELECT
  EC.DATABASE_NAME AS db,
  EC.TRIP_ID AS trip,
  EC.FISHING_EVENT_ID AS event,
  EC.fid,
  EC.sector,
  EC.gear,
  EC.log,
  EC.date,
  EC.major,
  EC.minor,
  EC.locality,
  --CC.LOCAL_NAME, -- for debugging locality names
  EC.fdep,
  EC.eff,
  CC.landed,
  CC.discard,
  CC.POP, CC.ORF, CC.TAR
--INTO #CATCH_EVENTS
FROM 
  #EVENT_CORE EC INNER JOIN
  #CATCH_CORE CC ON
    EC.DATABASE_NAME = CC.DATABASE_NAME AND
    EC.TRIP_ID = CC.TRIP_ID AND
    EC.FISHING_EVENT_ID = CC.FISHING_EVENT_ID 
WHERE
  CC.landed>0 OR CC.discard>0 OR CC.POP>0 OR CC.ORF>0 OR CC.TAR>0
--WHERE 
--  MC.SPECIES_CODE IN (@sppcode) --AND 
  --(MC.FISHERY_SECTOR IN ('GROUNDFISH TRAWL') OR 
  --(MC.FISHERY_SECTOR NOT IN ('GROUNDFISH TRAWL') AND ISNULL(MC.DATA_SOURCE_CODE,0) NOT IN (106,107)))
ORDER BY EC.TRIP_ID, EC.FISHING_EVENT_ID


-- getData("fos_mcatORF.sql","GFFOS",strSpp="442")
-- qu("fos_mcatORF.sql",dbName="GFFOS",strSpp="442")
-- qu("fos_mcatORF.sql",dbName="GFFOS",strSpp="228")



