-- Get age readings from various readers
-- Last modified : RH 220427
-- AGE_READING_TYPE_CODE = AGE_READING_TYPE_DESC
-- 0 = Unknown; 1 = Final; 2 = Primary; 3 = Precision Test; 4 = Secondary

SET NOCOUNT ON

-- Q1: Create #TEC_SPP
SELECT --TOP 100
  T.TRIP_ID,
  FE.FISHING_EVENT_ID,
  C.CATCH_ID,
  SA.SAMPLE_ID,
  SP.SPECIMEN_ID,
  SP.SPECIMEN_SEX_CODE,
  IsNull(T.TRIP_SUB_TYPE_CODE,0) AS TRIP_SUB_TYPE_CODE,
  ISNULL(FE.MAJOR_STAT_AREA_CODE,'00') AS MAJOR_STAT_AREA_CODE,
  'Best_Long' = CASE
    WHEN FE.FE_START_LONGITUDE_DEGREE > 0 AND FE.FE_START_LONGITUDE_DEGREE IS NOT NULL AND 
      FE.FE_START_LONGITUDE_MINUTE IS NOT NULL AND FE.FE_END_LONGITUDE_DEGREE > 0 AND 
      FE.FE_END_LONGITUDE_DEGREE IS NOT NULL AND FE.FE_END_LONGITUDE_MINUTE IS NOT NULL THEN
      ((FE.FE_START_LONGITUDE_DEGREE + (FE.FE_START_LONGITUDE_MINUTE / 60.0)) + (FE.FE_END_LONGITUDE_DEGREE + (FE.FE_END_LONGITUDE_MINUTE / 60.0))) / 2.0
    WHEN FE.FE_START_LONGITUDE_DEGREE > 0 AND FE.FE_START_LONGITUDE_DEGREE IS NOT NULL AND FE.FE_START_LONGITUDE_MINUTE IS NOT NULL THEN
      FE.FE_START_LONGITUDE_DEGREE + (FE.FE_START_LONGITUDE_MINUTE / 60.0)
    WHEN FE.FE_END_LONGITUDE_DEGREE > 0 AND FE.FE_END_LONGITUDE_DEGREE IS NOT NULL AND FE.FE_END_LONGITUDE_MINUTE IS NOT NULL THEN
      FE.FE_END_LONGITUDE_DEGREE + (FE.FE_END_LONGITUDE_MINUTE / 60.0)
    ELSE NULL END,
  'Best_Lat' = CASE
    WHEN FE.FE_START_LATTITUDE_DEGREE > 0 AND FE.FE_START_LATTITUDE_DEGREE IS NOT NULL AND 
      FE.FE_START_LATTITUDE_MINUTE IS NOT NULL AND FE.FE_END_LATTITUDE_DEGREE > 0 AND 
      FE.FE_END_LATTITUDE_DEGREE IS NOT NULL AND FE.FE_END_LATTITUDE_MINUTE IS NOT NULL THEN
      ((FE.FE_START_LATTITUDE_DEGREE + (FE.FE_START_LATTITUDE_MINUTE / 60.0)) + (FE.FE_END_LATTITUDE_DEGREE + (FE.FE_END_LATTITUDE_MINUTE / 60.0))) / 2.0
    WHEN FE.FE_START_LATTITUDE_DEGREE > 0 AND FE.FE_START_LATTITUDE_DEGREE IS NOT NULL AND FE.FE_START_LATTITUDE_MINUTE IS NOT NULL THEN
      FE.FE_START_LATTITUDE_DEGREE + (FE.FE_START_LATTITUDE_MINUTE / 60.0)
    WHEN FE.FE_END_LATTITUDE_DEGREE > 0 AND FE.FE_END_LATTITUDE_DEGREE IS NOT NULL AND FE.FE_END_LATTITUDE_MINUTE IS NOT NULL THEN
      FE.FE_END_LATTITUDE_DEGREE + (FE.FE_END_LATTITUDE_MINUTE / 60.0)
    ELSE NULL END
INTO #TEC_SPP
FROM
  TRIP T INNER JOIN
  FISHING_EVENT FE ON 
    T.TRIP_ID = FE.TRIP_ID INNER JOIN
  B02L3_Link_Fishing_Event_Catch L23 ON 
    FE.FISHING_EVENT_ID = L23.FISHING_EVENT_ID INNER JOIN
  CATCH C ON
    L23.CATCH_ID = C.CATCH_ID INNER JOIN
  B03L4_Link_Catch_Sample L34 ON 
    C.CATCH_ID = L34.CATCH_ID INNER JOIN
  SAMPLE SA ON 
    L34.SAMPLE_ID = SA.SAMPLE_ID INNER JOIN
  SPECIMEN SP ON
    SA.SAMPLE_ID = SP.SAMPLE_ID
WHERE
  C.SPECIES_CODE IN (@sppcode)
ORDER BY
  T.TRIP_ID,
  FE.FISHING_EVENT_ID,
  C.CATCH_ID,
  SA.SAMPLE_ID,
  SP.SPECIMEN_ID

-- Q2: Create #FACTOR_MORPHO
-- Get the appropriate factor to convert lengths to cm and weight to kg (81135)
SELECT --TOP 40
  -- Need three key fields
  SM.SAMPLE_ID,
  SM.SPECIMEN_ID,
  SM.MORPHOMETRICS_ATTRIBUTE_CODE,
  SM.MORPHOMETRICS_UNIT_CODE,
  FACTOR = MAX(CASE
    WHEN SM.MORPHOMETRICS_UNIT_CODE IN (1,7,14) THEN 1.0  -- centimetre
    WHEN SM.MORPHOMETRICS_UNIT_CODE IN (2,13) THEN 0.1    -- millimetre
    WHEN SM.MORPHOMETRICS_UNIT_CODE IN (11) THEN 0.1      -- decimetre
    WHEN SM.MORPHOMETRICS_UNIT_CODE IN (4) THEN 1.0       -- kilogram
    WHEN SM.MORPHOMETRICS_UNIT_CODE IN (3) THEN 0.001     -- gram
    WHEN SM.MORPHOMETRICS_UNIT_CODE IN (8) THEN 0.000001  -- milligram
    WHEN SM.MORPHOMETRICS_UNIT_CODE IN (10) THEN 0.0001   -- decigram
    WHEN SM.MORPHOMETRICS_UNIT_CODE IN (9) THEN 0.01      -- dekagram
    WHEN SM.MORPHOMETRICS_UNIT_CODE IN (12) THEN 0.1      -- hectogram
    WHEN SM.MORPHOMETRICS_UNIT_CODE IN (5) THEN 0.453592  -- pound
    WHEN SM.MORPHOMETRICS_UNIT_CODE IN (6) THEN 0.0283495 -- ounce
    ELSE 0 END)
INTO #FACTOR_MORPHO
FROM 
  SPECIMEN_MORPHOMETRICS SM INNER JOIN
  #TEC_SPP AS SPID ON
    SPID.SAMPLE_ID = SM.SAMPLE_ID AND
    SPID.SPECIMEN_ID = SM.SPECIMEN_ID
WHERE
  SM.MORPHOMETRICS_ATTRIBUTE_CODE IN (1,2,4,6,10)
GROUP BY
  SM.SAMPLE_ID,
  SM.SPECIMEN_ID,
  SM.MORPHOMETRICS_ATTRIBUTE_CODE,
  SM.MORPHOMETRICS_UNIT_CODE

-- Q3: Create #BEST_MORPHO
-- Deteremine the Best Length and Round Weight for Specimens (causing errors) (57685)
SELECT --TOP 40
  SM.SAMPLE_ID,
  SM.SPECIMEN_ID,
  'Best_Length' = SUM(COALESCE(
    (CASE WHEN SM.MORPHOMETRICS_ATTRIBUTE_CODE IN (4) THEN SM.SPECIMEN_MORPHOMETRICS_VALUE * FM.FACTOR ELSE NULL END),  -- total length
    (CASE WHEN SM.MORPHOMETRICS_ATTRIBUTE_CODE IN (2) THEN SM.SPECIMEN_MORPHOMETRICS_VALUE * FM.FACTOR ELSE NULL END),  -- standard length
    (CASE WHEN SM.MORPHOMETRICS_ATTRIBUTE_CODE IN (1) THEN SM.SPECIMEN_MORPHOMETRICS_VALUE * FM.FACTOR ELSE NULL END),  -- fork length
    (CASE WHEN SM.MORPHOMETRICS_ATTRIBUTE_CODE IN (6) THEN SM.SPECIMEN_MORPHOMETRICS_VALUE * FM.FACTOR ELSE NULL END),0)), -- third dorsal length
  'Round_Weight'  = SUM(COALESCE(
    (CASE WHEN SM.MORPHOMETRICS_ATTRIBUTE_CODE IN (10) THEN SM.SPECIMEN_MORPHOMETRICS_VALUE * FM.FACTOR ELSE NULL END),0))  -- ***** this line was originally faulty
INTO #BEST_MORPHO
FROM 
  SPECIMEN_MORPHOMETRICS SM  INNER JOIN
  #FACTOR_MORPHO FM ON
    SM.SAMPLE_ID = FM.SAMPLE_ID AND
    SM.SPECIMEN_ID = FM.SPECIMEN_ID AND
    SM.MORPHOMETRICS_ATTRIBUTE_CODE = FM.MORPHOMETRICS_ATTRIBUTE_CODE
GROUP BY
  SM.SAMPLE_ID,
  SM.SPECIMEN_ID

-- Q4: Create #UNIQUE_AMETH
SELECT DISTINCT
  SA1.SAMPLE_ID,
  SA1.SPECIMEN_ID,
  STUFF(( SELECT '|' + CAST(SA2.AGEING_METHOD_CODE AS VARCHAR(20))
    FROM SPECIMEN_AGE SA2
    WHERE
      SA1.SAMPLE_ID = SA2.SAMPLE_ID AND
      SA1.SPECIMEN_ID = SA2.SPECIMEN_ID
    GROUP BY SA2.AGEING_METHOD_CODE
    FOR XML PATH('')), 1, 1, '') AS AGE_METHS
INTO #UNIQUE_AMETH
FROM SPECIMEN_AGE SA1

-- Q5: Create #READ_AGES
SELECT --TOP 40
  SA.SAMPLE_ID,
  SA.SPECIMEN_ID,
  UA.AGE_METHS,
  --AVG(TEC.SPECIMEN_SEX_CODE) AS SPECIMEN_SEX_CODE, -- could also group by
  --AVG(TEC.TRIP_SUB_TYPE_CODE) AS TRIP_TYPE_CODE,
  --AVG(TEC.MAJOR_STAT_AREA_CODE) AS MAJOR_STAT_AREA_CODE,
  TEC.SPECIMEN_SEX_CODE, -- could also group by
  TEC.TRIP_SUB_TYPE_CODE AS TRIP_TYPE_CODE,
  TEC.MAJOR_STAT_AREA_CODE,
  ISNULL(TEC.Best_Long, NULL) AS X,
  ISNULL(TEC.Best_Lat, NULL) AS Y,
  MAX(CASE WHEN SA.AGE_READING_TYPE_CODE IN (0) THEN ISNULL(SA.SPECIMEN_AGE,0) ELSE 0 END) as READ0,  -- Unknown
  MAX(CASE WHEN SA.AGE_READING_TYPE_CODE IN (1) THEN ISNULL(SA.SPECIMEN_AGE,0) ELSE 0 END) as READ1,  -- Final
  MAX(CASE WHEN SA.AGE_READING_TYPE_CODE IN (2) THEN ISNULL(SA.SPECIMEN_AGE,0) ELSE 0 END) as READ2,  -- Primary
  MAX(CASE WHEN SA.AGE_READING_TYPE_CODE IN (3) THEN ISNULL(SA.SPECIMEN_AGE,0) ELSE 0 END) as READ3,  -- Precision Test
  MAX(CASE WHEN SA.AGE_READING_TYPE_CODE IN (4) THEN ISNULL(SA.SPECIMEN_AGE,0) ELSE 0 END) as READ4   -- Secondary
INTO #READ_AGES
FROM
  SPECIMEN_AGE SA INNER JOIN
  #TEC_SPP TEC ON 
    SA.SAMPLE_ID = TEC.SAMPLE_ID AND
    SA.SPECIMEN_ID = TEC.SPECIMEN_ID
  INNER JOIN #UNIQUE_AMETH UA ON
    TEC.SAMPLE_ID = UA.SAMPLE_ID AND 
    TEC.SPECIMEN_ID = UA.SPECIMEN_ID
GROUP BY
  SA.SAMPLE_ID,
  SA.SPECIMEN_ID,
  UA.AGE_METHS,
  TEC.SPECIMEN_SEX_CODE,
  TEC.TRIP_SUB_TYPE_CODE,
  TEC.MAJOR_STAT_AREA_CODE,
  ISNULL(TEC.Best_Long, NULL),
  ISNULL(TEC.Best_Lat, NULL)

-- Q6: Create Output Results
SELECT
  RA.SAMPLE_ID AS SID,
  RA.SPECIMEN_ID AS SPID, 
  YEAR(SM.SAMPLE_DATE) AS year,
  RA.TRIP_TYPE_CODE AS ttype,
  RA.MAJOR_STAT_AREA_CODE AS major,
  RA.X,
  RA.Y,
  C.SPECIES_CODE AS spp, 
  RA.SPECIMEN_SEX_CODE as sex,
 --S.SPECIES_COMMON_NAME AS spn, 
  BB.Best_Length AS len,
  RA.READ0 AS read0,
  RA.READ1 AS read1,
  RA.READ2 AS read2,
  RA.READ3 AS read3,
  RA.READ4 AS read4,
  RA.AGE_METHS AS ameth
INTO #AGE_READINGS
FROM
  --AGEING_METHOD AM INNER JOIN
  --#READ_AGES RA ON
  --  AM.AGEING_METHOD_CODE = RA.AGEING_METHOD_CODE  -- Won't work because AGEING METHOD can be more than one type (e.g., 3 and 17)
  #READ_AGES RA 
  INNER JOIN #BEST_MORPHO BB ON
    RA.SAMPLE_ID = BB.SAMPLE_ID AND 
    RA.SPECIMEN_ID = BB.SPECIMEN_ID
  LEFT OUTER JOIN CATCH_SAMPLE CS ON
    RA.SAMPLE_ID = CS.SAMPLE_ID
  INNER JOIN SAMPLE SM ON 
    CS.SAMPLE_ID = SM.SAMPLE_ID 
  INNER JOIN CATCH C ON 
    CS.CATCH_ID = C.CATCH_ID
  INNER JOIN SPECIES S ON
    C.SPECIES_CODE = S.SPECIES_CODE
WHERE
  C.SPECIES_CODE IN (@sppcode)
ORDER BY
  RA.SAMPLE_ID,
  RA.SPECIMEN_ID

select * from #AGE_READINGS
--select TOP 40 * from #AGE_READINGS

--qu("gfb_ages_read.sql", dbName="GFBioSQL", strSpp="435")  BOR (191025)
--qu("gfb_ages_read.sql", dbName="GFBioSQL", strSpp=c("394","425"))  REBS (200204)
--qu("gfb_ages_read.sql", dbName="GFBioSQL", strSpp="440")  YMR (210128)
--qu("gfb_ages_read.sql", dbName="GFBioSQL", strSpp="437")  CAR (220502)
