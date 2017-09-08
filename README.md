## PBStools: Tools for the efficient execution of onerous tasks ##

**PBStools** provides an R interface for algorithms commonly used in fisheries. The scope of this package is by no means comprehensive, having grown from the need to satisfy tasks specific to British Columbia (BC) ocean fisheries. Many of the functions provide a quick way to visualize data, and in some cases perform preliminary analyses. Though oriented to users at the Pacific Biological Station (PBS), these functions may provide a broad utility to users at other locales. The User Guide is organised into sections that loosely classify the functions by theme -- (1) Utility, (2) Biology, (3) Fishery, (4) Survey, (5) Spatial, (6) Temporal, and (7) Catch Reconstruction. Within each section, the functions are described alphabetically. 

**PBStools** depends heavily on two other R package: **PBSmapping** and **PBSmodelling**. We use the latter to implement several Graphical User Interfaces (GUIs) that facilitate a few select functions. Most functions, however, are designed for use on the command line or in sourced code. Windows users need to be mindful that the R-statistical language is case sensitive. 

Also available in the package directory `./library/PBStools/sql` we provide a number of useful SQL queries for DFO (Department of Fisheries and Oceans, a.k.a. Fisheries and Oceans Canada) commercial fisheries databases -- `PacHarvest` (trawl, 1996-2007), `PacHarvHL` (hook and line, 1994-2006), `GFCatch` (historical landings, 1954-1995), `GFBioSQL` (biological samples, 1946-2012), and `GFFOS` (integrated fisheries, 2002-2012). To launch SQL queries, **PBStools** relies on the R package **RODBC**. If you have access to the DFO network and have privileges to query these databases, the function `getData` can send the queries to the remote servers and return a data frame called `PBSdatin` the global environment. In the document, we highlight queries for DFO personnel using text with a background shaded `moccasin`. (Examples are shaded `aliceblue` and console output is shaded `honeydew`.) Note that many of these queries might act as useful templates for users outside DFO for similar purposes. Querying databases directly via SQL commands from R usually proves much more efficient than launching Microsoft Access Queries from a front-end database shell. 

Originally, **PBStools** evolved over time (2007-2012) within the R package **PBSfishery**, along with a convenient Graphical User Interface (GUI) tool for interacting with **PBSmapping** and useful datasets (regional boundaries, key codes, example data). In April 2012, we decided to split **PBSfishery** into three separate libraries -- **PBStools**, **PBSmapx**, and **PBSdata** -- for public distribution (see <a href="https://github.com/pbs-software">pbs-software</a>). The three packages experience different levels of change, with **PBStools** undergoing frequent revision, while **PBSdata** and **PBSmapx** remain unchanged for long periods of time.
