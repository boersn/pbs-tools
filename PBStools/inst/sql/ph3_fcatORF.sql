-- Sales slip catch summary from PacHarv3 (HARVEST_V2_0) (RH: 2015-06-16)
-- May need to refresh 'tnsnames.ora' in C:\Oracle\12.2.0\cli\network\admin
-- Norm transferred records for 1952-1992 to GFFOS as table 'PH3_CATCH_SUMMARY (NO 211215)
-- PH3_CATCH_SUMMARY emmpty, Norm transferring again (RH 221222)
-- Converted Oracle SQL code to SQL server code, mostly unpacking two nested queries into temporary tables #PMFC and #TARGET (RH 221222)

SET NOCOUNT ON -- Needed in SQL queries to prevent time-out

-- Attempt to convert PFMA areas to PMFC areas--------------
SELECT FA.CATSUM_ID,   -- 703,475 unique IDs
 (CASE
  WHEN FA.SFA_MSFA_MIDSIZE_FA_CDE IN (13,14,15,16,17,18,19,20,28,29,9200,9791,9792,9793,9794) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (11) AND FA.SFA_SMALL_FA_CDE BETWEEN 3 AND 10) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (12) AND FA.SFA_SMALL_FA_CDE NOT IN (12,14,15))  THEN 1
  WHEN FA.SFA_MSFA_MIDSIZE_FA_CDE IN (21,22,23,24,121,123,9210,9230,9240) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (124) AND FA.SFA_SMALL_FA_CDE BETWEEN 0 AND 3) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (125) AND FA.SFA_SMALL_FA_CDE IN (6) )  THEN 3
  WHEN FA.SFA_MSFA_MIDSIZE_FA_CDE IN (25,26,126,9250,9260) OR 
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (27) AND FA.SFA_SMALL_FA_CDE NOT IN (1)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (124) AND FA.SFA_SMALL_FA_CDE IN (4)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (125) AND FA.SFA_SMALL_FA_CDE BETWEEN 0 AND 5) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (127) AND FA.SFA_SMALL_FA_CDE IN (0,1,2))  THEN 4
  WHEN FA.SFA_MSFA_MIDSIZE_FA_CDE IN (111,9110,9270) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (10) AND FA.SFA_SMALL_FA_CDE IN (1)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (11) AND FA.SFA_SMALL_FA_CDE IN (0,1,2)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (12) AND FA.SFA_SMALL_FA_CDE IN (12,14,15)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (27) AND FA.SFA_SMALL_FA_CDE IN (1)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (127) AND FA.SFA_SMALL_FA_CDE IN (3,4)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (130) AND FA.SFA_SMALL_FA_CDE IN (1))  THEN 5
  WHEN FA.SFA_MSFA_MIDSIZE_FA_CDE IN (8,9,108,109,110,9021,9070,9080,9090,9100) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (2) AND FA.SFA_SMALL_FA_CDE IN (18,19)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (7) AND FA.SFA_SMALL_FA_CDE IN (0,1,17,18,19,20,21,23,25,26,27,28)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (10) AND FA.SFA_SMALL_FA_CDE NOT IN (1)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (102) AND FA.SFA_SMALL_FA_CDE IN (0,3)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (107) AND FA.SFA_SMALL_FA_CDE NOT IN (1)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (130) AND FA.SFA_SMALL_FA_CDE NOT IN (1))  THEN 6
  WHEN FA.SFA_MSFA_MIDSIZE_FA_CDE IN (6,106,9060) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (2) AND FA.SFA_SMALL_FA_CDE BETWEEN 2 AND 17) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (5) AND FA.SFA_SMALL_FA_CDE IN (13,16,17,18,19,22,24)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (7) AND FA.SFA_SMALL_FA_CDE BETWEEN 2 AND 16) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (7) AND FA.SFA_SMALL_FA_CDE IN (22,24,29,30,31,32)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (102) AND FA.SFA_SMALL_FA_CDE IN (2)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (105) AND FA.SFA_SMALL_FA_CDE IN (2)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (107) AND FA.SFA_SMALL_FA_CDE IN (1))  THEN 7
  WHEN FA.SFA_MSFA_MIDSIZE_FA_CDE IN (3,4,103,104,8021,9031,9032,9033,9040,9050) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (1) AND FA.SFA_SMALL_FA_CDE NOT IN (1)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (2) AND FA.SFA_SMALL_FA_CDE IN (1)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (5) AND FA.SFA_SMALL_FA_CDE BETWEEN 0 AND 12) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (5) AND FA.SFA_SMALL_FA_CDE IN (14,15,20,21,23)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (101) AND FA.SFA_SMALL_FA_CDE BETWEEN 4 AND 10) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (102) AND FA.SFA_SMALL_FA_CDE IN (1)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (105) AND FA.SFA_SMALL_FA_CDE IN (0,1))  THEN 8
  WHEN FA.SFA_MSFA_MIDSIZE_FA_CDE IN (142,8022,9010,9022) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (1) AND FA.SFA_SMALL_FA_CDE IN (1)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (2) AND FA.SFA_SMALL_FA_CDE IN (0)) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (2) AND FA.SFA_SMALL_FA_CDE BETWEEN 31 AND 100) OR
      (FA.SFA_MSFA_MIDSIZE_FA_CDE IN (101) AND FA.SFA_SMALL_FA_CDE IN (0,1,2,3))  THEN 9
  ELSE 0 END) AS PMFC,
  (CASE
  WHEN FA.SFA_MSFA_MIDSIZE_FA_CDE IN (142) AND FA.SFA_SMALL_FA_CDE IN (1) THEN 34  -- for POP in Anthony Island (606 records)
  ELSE 0 END) AS ANTHONY
INTO #PMFC
FROM PH3_CATCH_SUMMARY FA

-- Find target species -------------------------------------
-- Revised Target species code now returns 192,206 unique partitions (vs. 193,512 previously -> potential inflation)
-- See Frank Schmitt answer (110601) -- http://stackoverflow.com/questions/6198320/how-to-use-partition-by-or-max
SELECT
  YC.STP_SPER_YR,
  YC.STP_SPER_PERIOD_CDE,
  YC.SFA_MSFA_MIDSIZE_FA_CDE,
  YC.SFA_SMALL_FA_CDE,
  YC.GR_GEAR_CDE,
  YC.SP_SPECIES_CDE AS Target,
  YC.CATSUM_ROUND_LBS_WT,
  ROW_NUMBER()
  OVER
  (PARTITION BY YC.STP_SPER_YR, YC.STP_SPER_PERIOD_CDE, YC.SFA_MSFA_MIDSIZE_FA_CDE, YC.SFA_SMALL_FA_CDE, YC.GR_GEAR_CDE ORDER BY YC.CATSUM_ROUND_LBS_WT DESC) RN
INTO #TROWS
FROM PH3_CATCH_SUMMARY YC

SELECT * 
  INTO #TARGET
  FROM #TROWS TR
  WHERE TR.RN = 1

-- Gather the catch mess------------------------------------
SELECT
  (CASE  -- in order of priority
    -- originally TRAWL (otter bottom, midwater, shrimp, herring)
    WHEN TAR.GR_GEAR_CDE IN (50,51,57,59) THEN 1
    -- Partition LONGLINE
    WHEN TAR.GR_GEAR_CDE IN (40) AND TAR.Target IN ('614') THEN 2
    WHEN TAR.GR_GEAR_CDE IN (40) AND TAR.Target IN ('455') THEN 3
    WHEN TAR.GR_GEAR_CDE IN (40) AND TAR.Target IN ('044','467') THEN 4
    WHEN TAR.GR_GEAR_CDE IN (40) AND TAR.Target NOT IN ('614','455','044','467') THEN 5
    -- Partition TROLL (salmon, freezer salmon)
    WHEN TAR.GR_GEAR_CDE IN (30,31) AND TAR.Target IN ('614') THEN 2
    WHEN TAR.GR_GEAR_CDE IN (30,31) AND TAR.Target IN ('455') THEN 3
    WHEN TAR.GR_GEAR_CDE IN (30,31) AND TAR.Target IN ('044','467') THEN 4
    WHEN TAR.GR_GEAR_CDE IN (30,31) AND TAR.Target  NOT IN ('614','455','044','467') THEN 5
    -- Partition JIG (hand non-salmon)
    WHEN TAR.GR_GEAR_CDE IN (36) AND TAR.Target IN ('614') THEN 2
    WHEN TAR.GR_GEAR_CDE IN (36) AND TAR.Target IN ('455') THEN 3
    WHEN TAR.GR_GEAR_CDE IN (36) AND TAR.Target IN ('044','467') THEN 4
    WHEN TAR.GR_GEAR_CDE IN (36) AND TAR.Target  NOT IN ('614','455','044','467') THEN 5
    -- originally TRAP (experimental, salmon, longline, shrimp & prawn, crab)
    WHEN TAR.GR_GEAR_CDE IN (86,90,91,92,97,98) THEN 3
    -- Unassigned Trawl, Halibut, Sablefish, Dogfish-Lingcod, H&L Rockfish
    WHEN TAR.Target IN ('394','396','405','418','440','451') THEN 1
    WHEN TAR.Target IN ('614') THEN 2
    WHEN TAR.Target IN ('455') THEN 3
    WHEN TAR.Target IN ('044','467') THEN 4
    WHEN TAR.Target IN ('388','401','407','424','431','433','442') THEN 5
    ELSE 0 END) AS \"fid\",
  CS.STP_SPER_YR AS \"year\",
  AREA.PMFC AS \"major\",
  AREA.ANTHONY AS \"minor\",
  Sum(CASE
    WHEN CS.SP_SPECIES_CDE IN (@sppcode) AND CS.CU_CATCH_UTLZTN_CDE NOT IN (6,22,23,24,27,28)
    THEN CS.CATSUM_ROUND_LBS_WT
    ELSE 0 END)/2.20459 AS \"landed\",
  Sum(CASE
    WHEN CS.SP_SPECIES_CDE IN (@sppcode) AND CS.CU_CATCH_UTLZTN_CDE IN (6,22,23,24,27,28)
    THEN CS.CATSUM_ROUND_LBS_WT
    ELSE 0 END)/2.20459 AS \"discard\",
  Sum(CASE
    WHEN CS.SP_SPECIES_CDE IN ('396') AND CS.CU_CATCH_UTLZTN_CDE NOT IN (6,22,23,24,27,28)
    THEN CS.CATSUM_ROUND_LBS_WT
    ELSE 0 END)/2.20459 AS POP,
  Sum(CASE
    WHEN CS.SP_SPECIES_CDE IN (@orfcode) AND CS.CU_CATCH_UTLZTN_CDE NOT IN (6,22,23,24,27,28)
    THEN CS.CATSUM_ROUND_LBS_WT
    ELSE 0 END)/2.20459 AS ORF,
  Sum(CASE
    WHEN CS.SP_SPECIES_CDE IN ('614') AND CS.CU_CATCH_UTLZTN_CDE NOT IN (6,22,23,24,27,28)
    THEN CS.CATSUM_ROUND_LBS_WT
    ELSE 0 END)/2.20459 AS PAH,
  Sum(CASE
    WHEN CS.SP_SPECIES_CDE IN ('454','455') AND CS.CU_CATCH_UTLZTN_CDE NOT IN (6,22,23,24,27,28)
    THEN CS.CATSUM_ROUND_LBS_WT
    ELSE 0 END)/2.20459 AS SBF,
  Sum(CASE
    WHEN CS.SP_SPECIES_CDE IN ('042','044') AND CS.CU_CATCH_UTLZTN_CDE NOT IN (6,22,23,24,27,28)
    THEN CS.CATSUM_ROUND_LBS_WT
    ELSE 0 END)/2.20459 AS DOG,
  Sum(CASE
    WHEN CS.SP_SPECIES_CDE IN ('465','467') AND CS.CU_CATCH_UTLZTN_CDE NOT IN (6,22,23,24,27,28)
    THEN CS.CATSUM_ROUND_LBS_WT
    ELSE 0 END)/2.20459 AS LIN,
  Sum(CASE
    WHEN CS.SP_SPECIES_CDE IN ('424','407','431','433','442') AND CS.CU_CATCH_UTLZTN_CDE NOT IN (6,22,23,24,27,28)
    THEN CS.CATSUM_ROUND_LBS_WT
    ELSE 0 END)/2.20459 AS IRF
INTO #CATMESS
FROM
  PH3_CATCH_SUMMARY CS INNER JOIN
  #PMFC AREA ON
    CS.CATSUM_ID = AREA.CATSUM_ID INNER JOIN
  #TARGET TAR ON
    CS.STP_SPER_YR = TAR.STP_SPER_YR AND
    CS.STP_SPER_PERIOD_CDE = TAR.STP_SPER_PERIOD_CDE AND
    CS.SFA_MSFA_MIDSIZE_FA_CDE = TAR.SFA_MSFA_MIDSIZE_FA_CDE AND
    CS.SFA_SMALL_FA_CDE = TAR.SFA_SMALL_FA_CDE AND
    CS.GR_GEAR_CDE = TAR.GR_GEAR_CDE
WHERE
  --CS.CU_CATCH_UTLZTN_CDE NOT IN (6,22,23,24,27,28) AND
  CS.CATSUM_FISHERY_TYPE_CDE IN ('01','02','03','25') -- 1=commercial, 2=test, 3=research, 25=recreational
GROUP BY
  (CASE 
    -- originally TRAWL (otter bottom, midwater, shrimp, herring)
    WHEN TAR.GR_GEAR_CDE IN (50,51,57,59) THEN 1
    -- Partition LONGLINE
    WHEN TAR.GR_GEAR_CDE IN (40) AND TAR.Target IN ('614') THEN 2
    WHEN TAR.GR_GEAR_CDE IN (40) AND TAR.Target IN ('455') THEN 3
    WHEN TAR.GR_GEAR_CDE IN (40) AND TAR.Target IN ('044','467') THEN 4
    WHEN TAR.GR_GEAR_CDE IN (40) AND TAR.Target NOT IN ('614','455','044','467') THEN 5
    -- Partition TROLL (salmon, freezer salmon)
    WHEN TAR.GR_GEAR_CDE IN (30,31) AND TAR.Target IN ('614') THEN 2
    WHEN TAR.GR_GEAR_CDE IN (30,31) AND TAR.Target IN ('455') THEN 3
    WHEN TAR.GR_GEAR_CDE IN (30,31) AND TAR.Target IN ('044','467') THEN 4
    WHEN TAR.GR_GEAR_CDE IN (30,31) AND TAR.Target  NOT IN ('614','455','044','467') THEN 5
    -- Partition JIG (hand non-salmon)
    WHEN TAR.GR_GEAR_CDE IN (36) AND TAR.Target IN ('614') THEN 2
    WHEN TAR.GR_GEAR_CDE IN (36) AND TAR.Target IN ('455') THEN 3
    WHEN TAR.GR_GEAR_CDE IN (36) AND TAR.Target IN ('044','467') THEN 4
    WHEN TAR.GR_GEAR_CDE IN (36) AND TAR.Target  NOT IN ('614','455','044','467') THEN 5
    -- originally TRAP (experimental, salmon, longline, shrimp & prawn, crab)
    WHEN TAR.GR_GEAR_CDE IN (86,90,91,92,97,98) THEN 3
    -- Unassigned Trawl, Halibut, Sablefish, Dogfish-Lingcod, H&L Rockfish
    WHEN TAR.Target IN ('394','396','405','418','440','451') THEN 1
    WHEN TAR.Target IN ('614') THEN 2
    WHEN TAR.Target IN ('455') THEN 3
    WHEN TAR.Target IN ('044','467') THEN 4
    WHEN TAR.Target IN ('388','401','407','424','431','433','442') THEN 5
    ELSE 0 END),
  CS.STP_SPER_YR,
  AREA.PMFC,
  AREA.ANTHONY

SELECT * FROM #CATMESS CM
WHERE
  --CSS.\"landed\">0 OR CSS.\"discard\">0 OR CSS.POP>0 OR CSS.ORF>0 OR CSS.PAH>0 OR CSS.SBF>0 OR CSS.DOG>0 OR CSS.IRF>0
  CM.landed>0 OR CM.discard>0 OR CM.POP>0 OR CM.ORF>0 OR CM.PAH>0 OR CM.SBF>0 OR CM.DOG>0 OR CM.IRF>0


-- getData("ph3_fcatORF.sql",dbName="HARVEST_V2_0",strSpp="442",server="ORAPROD",type="ORA",trusted=FALSE,uid="",pwd="")
-- getData("ph3_fcatORF.sql",dbName="HARVEST_V2_0",strSpp="394",path=.getSpath(),server="ORAPROD",type="ORA",trusted=FALSE,uid="haighr",pwd="haighr")
-- qu("ph3_fcatORF.sql",dbName="HARVEST_V2_0",strSpp="442",server="ORAPROD",type="ORA",trusted=FALSE,uid="haighr",pwd="haighr")
-- qu("ph3_fcatORF.sql",dbName="HARVEST_V2_0",strSpp="394",server="ORAPROD",type="ORA",trusted=FALSE,uid="haighr",pwd="haighr")
-- qu("ph3_fcatORF.sql",dbName="HARVEST_V2_0",strSpp="440",server="ORAPROD",type="ORA",trusted=FALSE,uid="haighr",pwd="haighr")

-- As of 2012-01-15, use ORAPROD.WORLD (added to C:\Oracle\12.2.0\cli\network\admin\tnsnames.ora)
-- qu("ph3_fcatORF.sql",dbName="HARVEST_V2_0",strSpp="424",server="ORAPROD.WORLD",type="ORA",trusted=FALSE,uid="haighr",pwd="haighr")

-- As of 2021-12-15, use FOS_V1_1.WORLD.WORLD (although you can probably use any alias you want)

--# Norm Olsen (accesses HARVEST_V2_0 aka PACHARV3)
--FOS_V1_1.WORLD = 
--  (DESCRIPTION = 
--     (ADDRESS = 
--       (PROTOCOL = TCP)
--       (Host = VSBCIOSXP75.ENT.DFO-MPO.CA)
--       (Port = 1521)
--     )
--     (CONNECT_DATA = (SERVICE_NAME = PROD1)
--     )
--  )
-- qu("ph3_fcatORF.sql",dbName="HARVEST_V2_0",strSpp="437",server="FOS_V1_1.WORLD",type="ORA",trusted=FALSE,uid="haighr",pwd="haighr")

-- Try querying GFFOS copy PH3_CATCH_SUMMARY
-- qu("ph3_fcatORF.sql",dbName="GFFOS",strSpp="396")





