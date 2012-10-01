-- Sales slip catch summary from PacHarv3 (HARVEST_V2_0)
SELECT * FROM
(SELECT
  (CASE  -- in order of priority
    WHEN TAR.GR_GEAR_CDE IN (50,51,57,59) THEN 1                                -- originally TRAWL (otter bottom, midwater, shrimp, herring)
    WHEN TAR.GR_GEAR_CDE IN (40) AND TAR.Target IN ('614') THEN 2               -- originally LONGLINE
    WHEN TAR.GR_GEAR_CDE IN (86,90,91,92,97,98) THEN 3                          -- originally TRAP (experimental, salmon, longline, shrimp & prawn, crab)
    WHEN TAR.GR_GEAR_CDE IN (40) AND TAR.Target IN ('455') THEN 3               -- originally LONGLINE
    WHEN TAR.GR_GEAR_CDE IN (30,31)  THEN 4                                     -- originally TROLL (salmon, freezer salmon)
    --WHEN TAR.GR_GEAR_CDE IN (36,40) AND TAR.Target IN ('044','467') THEN 4    -- originally JIG (hand non-salmon) and LONGLINE
    WHEN TAR.GR_GEAR_CDE IN (36,40) THEN 5                                      -- originally JIG (hand non-salmon) and LONGLINE
    --WHEN TAR.Target IN ('222','225','228','388','394','396','401','405','418','440','451','597','602','607','621','626','628','631') THEN 1
    WHEN TAR.Target IN ('455') THEN 3
    --WHEN TAR.Target IN ('044','467') THEN 4
    WHEN TAR.Target IN ('388','394','401','405','418','424','440','442','451') THEN 5
    ELSE 0 END) AS \"fid\",
  CS.STP_SPER_YR AS \"year\",
  (CASE
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (12,13,14,15,16,17,18,19,20,28,29,9200,9791,9792,9793,9794) THEN 1
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (9508) THEN 2
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (21,22,23,24,121,123,124,9210,9230,9240) THEN 3
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (25,26,27,125,126,127,9250,9260,9270) THEN 4
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (10,11,111,9100,9110) THEN 5
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (7,8,9,107,108,109,110,130,30,9070,9080,9090) THEN 6
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (6,102,106,8021,9021,9060) THEN 7
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (1,3,4,5,101,103,104,105,9010,9031,9032,9033,9040,9050) THEN 8
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (2,142,8022,9022) THEN 9
    ELSE 0 END) AS \"major\",
  (CASE
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (142) AND CS.SFA_SMALL_FA_CDE IN (1) THEN 34 -- for POP in Anthony Island
    ELSE 0 END) AS \"minor\",
  --CS.GR_GEAR_CDE AS \"gear\",
  --CS.SP_SPECIES_CDE,
  Sum(CASE
    WHEN CS.SP_SPECIES_CDE IN (@sppcode) AND CS.CU_CATCH_UTLZTN_CDE NOT IN (6,22,23,24,27,28)
    THEN CS.CATSUM_ROUND_LBS_WT
    ELSE 0 END)/2.20459 AS \"landed\",
  Sum(CASE
    WHEN CS.SP_SPECIES_CDE IN (@sppcode) AND CS.CU_CATCH_UTLZTN_CDE IN (6,22,23,24,27,28)
    THEN CS.CATSUM_ROUND_LBS_WT
    ELSE 0 END)/2.20459 AS \"discard\",
  Sum(CASE
    WHEN CS.SP_SPECIES_CDE IN ('396')    AND CS.CU_CATCH_UTLZTN_CDE NOT IN (6,22,23,24,27,28)
    THEN CS.CATSUM_ROUND_LBS_WT
    ELSE 0 END)/2.20459 AS POP,
  Sum(CASE
    WHEN CS.SP_SPECIES_CDE IN (@orfcode) AND CS.CU_CATCH_UTLZTN_CDE NOT IN (6,22,23,24,27,28)
    THEN CS.CATSUM_ROUND_LBS_WT
    ELSE 0 END)/2.20459 AS ORF,
  Sum(CASE
    WHEN CS.SP_SPECIES_CDE IN ('614')    AND CS.CU_CATCH_UTLZTN_CDE NOT IN (6,22,23,24,27,28)
    THEN CS.CATSUM_ROUND_LBS_WT
    ELSE 0 END)/2.20459 AS PAH,
  Sum(CASE
    WHEN CS.SP_SPECIES_CDE IN ('455')    AND CS.CU_CATCH_UTLZTN_CDE NOT IN (6,22,23,24,27,28)
    THEN CS.CATSUM_ROUND_LBS_WT
    ELSE 0 END)/2.20459 AS SBF,
  Sum(CASE
    WHEN CS.SP_SPECIES_CDE IN ('042','044','467')  AND CS.CU_CATCH_UTLZTN_CDE NOT IN (6,22,23,24,27,28)
    THEN CS.CATSUM_ROUND_LBS_WT
    ELSE 0 END)/2.20459 AS DOG,
  Sum(CASE
    WHEN CS.SP_SPECIES_CDE IN ('424','407','431','433','442')  AND CS.CU_CATCH_UTLZTN_CDE NOT IN (6,22,23,24,27,28)
    THEN CS.CATSUM_ROUND_LBS_WT
    ELSE 0 END)/2.20459 AS RFA

FROM
  @table.CATCH_SUMMARY CS INNER JOIN
  (SELECT
    ZC.STP_SPER_YR,
    ZC.STP_SPER_PERIOD_CDE,
    ZC.SFA_MSFA_MIDSIZE_FA_CDE,
    ZC.GR_GEAR_CDE,
    ZC.SumCat,
    MIN(ZC.SP_SPECIES_CDE) AS Target
  FROM
    (SELECT 
      CS.STP_SPER_YR,
      CS.STP_SPER_PERIOD_CDE,
      CS.SFA_MSFA_MIDSIZE_FA_CDE,
      CS.GR_GEAR_CDE,
      CS.SP_SPECIES_CDE,
      Sum(CS.CATSUM_ROUND_LBS_WT) AS SumCat
    FROM
      @table.CATCH_SUMMARY CS
    GROUP BY 
      CS.STP_SPER_YR, CS.STP_SPER_PERIOD_CDE,
      CS.SFA_MSFA_MIDSIZE_FA_CDE, CS.GR_GEAR_CDE, CS.SP_SPECIES_CDE) ZC -- Species catch by year, period, and area

  INNER JOIN
    (SELECT
      TC.STP_SPER_YR,
      TC.STP_SPER_PERIOD_CDE,
      TC.SFA_MSFA_MIDSIZE_FA_CDE,
      TC.GR_GEAR_CDE,
      Max(TC.SumCat) AS MaxCat
    FROM
      (SELECT 
        YC.STP_SPER_YR,
        YC.STP_SPER_PERIOD_CDE,
        YC.SFA_MSFA_MIDSIZE_FA_CDE,
        YC.GR_GEAR_CDE,
        YC.SP_SPECIES_CDE,
        Sum(YC.CATSUM_ROUND_LBS_WT) AS SumCat
      FROM
        @table.CATCH_SUMMARY YC
      GROUP BY 
        YC.STP_SPER_YR, YC.STP_SPER_PERIOD_CDE,
        YC.SFA_MSFA_MIDSIZE_FA_CDE, YC.GR_GEAR_CDE, YC.SP_SPECIES_CDE) TC   -- total catch
    GROUP BY 
      TC.STP_SPER_YR, TC.STP_SPER_PERIOD_CDE,
      TC.SFA_MSFA_MIDSIZE_FA_CDE, TC.GR_GEAR_CDE) MC ON                     -- maximum catch

    ZC.STP_SPER_YR = MC.STP_SPER_YR AND
    ZC.STP_SPER_PERIOD_CDE = MC.STP_SPER_PERIOD_CDE AND
    ZC.SFA_MSFA_MIDSIZE_FA_CDE = MC.SFA_MSFA_MIDSIZE_FA_CDE AND
    ZC.GR_GEAR_CDE = MC.GR_GEAR_CDE AND
    ZC.SumCat = MC.MaxCat
--  WHERE -- Test group
--    ZC.STP_SPER_YR IN (1995) AND
--    ZC.STP_SPER_PERIOD_CDE IN ('070') AND
--    ZC.SFA_MSFA_MIDSIZE_FA_CDE IN (9021)
  GROUP BY
    ZC.STP_SPER_YR,
    ZC.STP_SPER_PERIOD_CDE,
    ZC.SFA_MSFA_MIDSIZE_FA_CDE,
    ZC.GR_GEAR_CDE,
    ZC.SumCat) TAR ON                -- target species

    CS.STP_SPER_YR = TAR.STP_SPER_YR AND
    CS.STP_SPER_PERIOD_CDE = TAR.STP_SPER_PERIOD_CDE AND
    CS.SFA_MSFA_MIDSIZE_FA_CDE = TAR.SFA_MSFA_MIDSIZE_FA_CDE AND
    CS.GR_GEAR_CDE = TAR.GR_GEAR_CDE

  GROUP BY
  (CASE 
    WHEN TAR.GR_GEAR_CDE IN (50,51,57,59) THEN 1                                -- originally TRAWL (otter bottom, midwater, shrimp, herring)
    WHEN TAR.GR_GEAR_CDE IN (40) AND TAR.Target IN ('614') THEN 2               -- originally LONGLINE
    WHEN TAR.GR_GEAR_CDE IN (86,90,91,92,97,98) THEN 3                          -- originally TRAP (experimental, salmon, longline, shrimp & prawn, crab)
    WHEN TAR.GR_GEAR_CDE IN (40) AND TAR.Target IN ('455') THEN 3               -- originally LONGLINE
    WHEN TAR.GR_GEAR_CDE IN (30,31)  THEN 4                                     -- originally TROLL (salmon, freezer salmon)
    --WHEN TAR.GR_GEAR_CDE IN (36,40) AND TAR.Target IN ('044','467') THEN 4    -- originally JIG (hand non-salmon) and LONGLINE
    WHEN TAR.GR_GEAR_CDE IN (36,40) THEN 5                                      -- originally JIG (hand non-salmon) and LONGLINE
    --WHEN TAR.Target IN ('222','225','228','388','394','396','401','405','418','440','451','597','602','607','621','626','628','631') THEN 1
    WHEN TAR.Target IN ('455') THEN 3
    --WHEN TAR.Target IN ('044','467') THEN 4
    WHEN TAR.Target IN ('388','394','401','405','418','424','440','442','451') THEN 5
    ELSE 0 END),
  CS.STP_SPER_YR,
  (CASE
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (12,13,14,15,16,17,18,19,20,28,29,9200,9791,9792,9793,9794) THEN 1
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (9508) THEN 2
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (21,22,23,24,121,123,124,9210,9230,9240) THEN 3
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (25,26,27,125,126,127,9250,9260,9270) THEN 4
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (10,11,111,9100,9110) THEN 5
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (7,8,9,107,108,109,110,130,30,9070,9080,9090) THEN 6
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (6,102,106,8021,9021,9060) THEN 7
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (1,3,4,5,101,103,104,105,9010,9031,9032,9033,9040,9050) THEN 8
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (2,142,8022,9022) THEN 9
    ELSE 0 END),
  (CASE
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (142) AND CS.SFA_SMALL_FA_CDE IN (1) THEN 34 -- for POP in Anthony Island
    ELSE 0 END) --, 
  --CS.GR_GEAR_CDE,
  --CS.SP_SPECIES_CDE
  ) CSS
  WHERE
    CSS.\"landed\">0 OR CSS.\"discard\">0 OR CSS.POP>0 OR CSS.ORF>0 OR CSS.PAH>0 OR CSS.SBF>0 OR CSS.DOG>0 OR CSS.RFA>0
;

-- getData("ph3_fcatORF.sql",dbName="HARVEST_V2_0",strSpp="442",server="ORAPROD",type="ORA",trusted=FALSE,uid="",pwd="")

