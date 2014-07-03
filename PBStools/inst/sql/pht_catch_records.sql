-- Last modified by RH (2014-06-23)
SET NOCOUNT ON 

-- Get Trip_ID and Fishing_Event_ID
SELECT
  BT.HAIL_IN_NO,
  BF.FE_MAJOR_LEVEL_ID,
  MIN(BT.TRIP_ID) AS TRIP_ID,  -- get rid of duplicated Trip IDs
  MIN(BF.FISHING_EVENT_ID) AS FISHING_EVENT_ID
  INTO #TIDFID
  FROM
    GFBioSQL.dbo.B01_TRIP BT
    INNER JOIN GFBIOSQL.dbo.B02_FISHING_EVENT BF
    ON BT.TRIP_ID=BF.TRIP_ID
  WHERE 
    BT.HAIL_IN_NO Is Not Null 
  GROUP BY BT.HAIL_IN_NO, BF.FE_MAJOR_LEVEL_ID
  ORDER BY BT.HAIL_IN_NO, BF.FE_MAJOR_LEVEL_ID

-- Get unique Trip_ID per Hail_In
SELECT
	TF.HAIL_IN_NO,
	MIN(TF.TRIP_ID) AS TRIP_ID
	INTO #HAILTRIP
	FROM #TIDFID TF
	GROUP BY TF.HAIL_IN_NO

-- Create a Trip table with some defaults
SELECT
  H.HLIN_HAIL_IN_NO AS HAIL_IN_NO,
  HT.TRIP_ID,
  H.HLIN_VSL_CFV_NO AS VESSEL,
  COALESCE(H.HLIN_OFFLOAD_DT,H.HLIN_HAIL_IN_DT) AS [DATE],
  'DEF_LOG'=AVG(CASE isnull(E.OBFL_LOG_TYPE_CDE,0)
    WHEN 'FISHERLOG'  THEN 105  -- Change to codes used by FOS
    WHEN 'OBSERVRLOG' THEN 106
    ELSE 0 END ),
  'DEF_X'=AVG(COALESCE(-E.OBFL_START_LONGITUDE, -E.OBFL_END_LONGITUDE, 0)),
  'DEF_Y'=AVG(COALESCE(E.OBFL_START_LATITUDE, E.OBFL_END_LATITUDE, 0)), 
  'DEF_MAJOR'=CAST(AVG(isnull(E.OBFL_MAJOR_STAT_AREA_CDE,0)) AS INT),
  'DEF_MINOR'=CAST(AVG(isnull(E.OBFL_MINOR_STAT_AREA_CDE,0)) AS INT),
  'DEF_LOCALITY'=CAST(AVG(isnull(E.OBFL_LOCALITY_CDE,0)) AS INT),
  'DEF_PFMA'=CAST(AVG(isnull(E.OBFL_DFO_MGMT_AREA_CDE,0)) AS INT),
  'DEF_PFMS'=CAST(AVG(isnull(E.OBFL_DFO_MGMT_SUBAREA_CDE,0)) AS INT),
  'DEF_DEPTH'=CAST(AVG(isnull(E.Fishing_Depth,0)) AS INT),
  'DEF_GEAR'=AVG(isnull(E.OBFL_GEAR_SUBTYPE_CDE,0)),
  'DEF_SUCCESS'=AVG(isnull(E.OBFL_FE_SUCCESS_CDE,0)),
  'DEF_EFFORT'=AVG(isnull(E.Duration,0)) 
INTO #Trips
FROM
  (#HAILTRIP HT
  RIGHT OUTER JOIN B1_Hails H 
  ON H.HLIN_HAIL_IN_NO = HT.HAIL_IN_NO) 
  LEFT OUTER JOIN  B3_Fishing_Events E 
  ON H.HLIN_HAIL_IN_NO = E.OBFL_HAIL_IN_NO 
--WHERE H.HLIN_HAIL_IN_NO in ('26821957','98825047')
GROUP BY
  H.HLIN_HAIL_IN_NO, HT.TRIP_ID, H.HLIN_VSL_CFV_NO, COALESCE(H.HLIN_OFFLOAD_DT,H.HLIN_HAIL_IN_DT)

-- Create a temporary table with species catch and total catch
SELECT 
  M.HAIL_IN_NO, 
  M.SET_NO, 
  SPPCAT = Sum( CASE M.SPECIES_CODE
    WHEN @sppcode THEN M.LANDED + M.DISCARDED
    ELSE 0 END ),
  SPPDIS = Sum( CASE M.SPECIES_CODE
    WHEN @sppcode THEN M.DISCARDED
    ELSE 0 END ),
  TOTCAT = Sum(M.LANDED + M.DISCARDED)
INTO #Catch
FROM D_Merged_Catches M
WHERE
--  M.HAIL_IN_NO in ('26821957','98825047') AND
  M.SPECIES_CODE <> '004' -- remove inanimate objects
GROUP BY 
  M.HAIL_IN_NO, M.SET_NO

-- Link all catch events above to fishing events
SELECT 
  FID=1,
  COALESCE(TF.TRIP_ID,T.TRIP_ID,0) AS TID,
  ISNULL(TF.FISHING_EVENT_ID,0) AS FEID,
  C.HAIL_IN_NO AS hail,
  C.SET_NO AS [set],
  COALESCE(CASE E.OBFL_LOG_TYPE_CDE
    WHEN 'FISHERLOG'  THEN 105   -- Change to codes used by FOS
    WHEN 'OBSERVRLOG' THEN 106
    END,T.DEF_LOG) AS [log],
  CAST(ROUND(COALESCE(-E.OBFL_START_LONGITUDE, -E.OBFL_END_LONGITUDE, T.DEF_X),7) AS NUMERIC(15,7)) AS X, 
  CAST(ROUND(COALESCE(E.OBFL_START_LATITUDE, E.OBFL_END_LATITUDE, T.DEF_Y),7) AS NUMERIC(15,7)) AS Y,
--  IsNull(CONVERT(char(10),COALESCE(E.Start_FE,T.DATE), 20),Null) AS [date], 
  IsNull(COALESCE(E.Start_FE,T.DATE),Null) AS [date], 
  IsNull(Year(COALESCE(E.Start_FE,T.DATE)),9999) AS [year],
--  COALESCE(E.Fishing_Year,CASE 
--    WHEN Year(T.DATE)<1997 OR Month(T.DATE)>3 THEN Year(T.DATE)
--    WHEN Year(T.DATE)=1997 AND Month(T.DATE)<=3 THEN 97
--    WHEN Year(T.DATE)>1997 AND Month(T.DATE)<=3 THEN Year(T.DATE)-1
--    WHEN T.DATE IS NULL THEN 9999 END) AS fyear,
  COALESCE(E.OBFL_MAJOR_STAT_AREA_CDE,T.DEF_MAJOR) AS major,
  COALESCE(E.OBFL_MINOR_STAT_AREA_CDE,T.DEF_MINOR) AS minor,
  COALESCE(E.OBFL_LOCALITY_CDE,T.DEF_LOCALITY) AS locality,
  COALESCE(E.OBFL_DFO_MGMT_AREA_CDE,T.DEF_PFMA) AS pfma,
  COALESCE(E.OBFL_DFO_MGMT_SUBAREA_CDE,T.DEF_PFMS) AS pfms,
  NULLIF(CAST(COALESCE(E.Fishing_Depth,T.DEF_DEPTH) AS INT),0) AS depth,
  T.VESSEL AS vessel,
  COALESCE(E.OBFL_GEAR_SUBTYPE_CDE,T.DEF_GEAR)AS gear,  -- 1=bottom trawl, 3=midwater trawl
  COALESCE(E.OBFL_FE_SUCCESS_CDE,T.DEF_SUCCESS) AS success,
  CAST(ROUND(COALESCE(E.Duration,T.DEF_EFFORT),5) AS NUMERIC(15,5)) AS effort,  -- minutes
  C.SPPCAT AS catKg,
  C.SPPDIS/C.SPPCAT AS pdis, -- proportion discarded
  C.SPPCAT/C.TOTCAT AS pcat  -- proportion of total catch
FROM 
  ((#TIDFID TF 
  RIGHT OUTER JOIN B3_Fishing_Events E 
  ON E.OBFL_HAIL_IN_NO = TF.HAIL_IN_NO AND
     E.OBFL_SET_NO = TF.FE_MAJOR_LEVEL_ID) 
   RIGHT OUTER JOIN #Catch C 
   ON E.OBFL_HAIL_IN_NO = C.HAIL_IN_NO AND 
      E.OBFL_SET_NO = C.SET_NO ) 
   LEFT OUTER JOIN #Trips T 
   ON T.HAIL_IN_NO = C.HAIL_IN_NO 
WHERE
  C.SPPCAT > 0  -- select only positive catches for the chosen species
ORDER BY
  C.HAIL_IN_NO, C.SET_NO

-- getData("pht_catch_records.sql",strSpp="401")

