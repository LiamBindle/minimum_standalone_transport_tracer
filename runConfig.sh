#!/bin/bash

# runSettings.sh: Set run-time settings for GCHP and update all config
# files to use these settings. Pass optional argument --silent to suppress
# information of settings updated per file. Errors/warnings will still be printed.

# Usage: ./runConfig.sh [--silent]
#
# Initial version: E. Lundgren, 8/17/2017

#------------------------------------------------
#   Compute Resources
#------------------------------------------------
TOTAL_CORES=6
NUM_NODES=1
NUM_CORES_PER_NODE=6
# Set number of cores, number of nodes, and number of cores per node.
# Total cores must be divisible by 6. Cores per node must equal number
# of cores divided by number of nodes. Make sure you have these
# resources available.

#------------------------------------------------
#   Domain decomposition
#------------------------------------------------
NXNY_AUTO=ON
NX=1 # Ignore if NXNY_AUTO=ON
NY=6 # Ignore if NXNY_AUTO=ON
# Cores are distributed across each of the six cubed sphere faces using
# configurable parameters NX and NY. Each face is divided into NX by NY/6
# regions and each of those regions is processed by a single core 
# independent of which node it belongs to. Making NX by NY/6 as square
# as possible reduces communication overhead in GCHP.
#
# Set NXNY_AUTO to either auto-calculate NX and NY (ON) (recommended)
# or set them manually (OFF).

# Rules and tips for setting NX and NY manually (NXNY_AUTO=OFF):
#   1. NY must be an integer and a multiple of 6	  
#   2. NX*NY must equal total number of cores (NUM_NODES*NUM_CORES_PER_NODE)
#   3. Choose NX and NY to optimize NX x NY/6 squareness 
#         Good examples: (NX=4,NY=24)  -> 96  cores at 4x4
#                        (NX=6,NY=24)  -> 144 cores at 6x4
#         Bad examples:  (NX=8,NY=12)  -> 96  cores at 8x2
#                        (NX=12,NY=12) -> 144 cores at 12x2
#   4. Domain decomposition requires that CS_RES/NX >= 4 and CS_RES*6/NY >= 4,
#      which puts an upper limit on total cores per grid resolution.
#         c24: 216 cores   (NX=6,  NY=36 )
#         c48: 864 cores   (NX=12, NY=72 )
#         c90: 3174 cores  (NX=22, NY=132)
#        c180: 12150 cores (NX=45, NY=270)
#        c360: 48600 cores (NX=90, NY=540)
#      Using fewer cores may still trigger a domain decomposition error, e.g.:
#         c48: 768 cores   (NX=16, NY=48)  --> 48/16=3 will trigger FV3 error

#------------------------------------------------
#   Internal Cubed Sphere Resolution
#------------------------------------------------
CS_RES=6
STRETCH_GRID=OFF
STRETCH_FACTOR=2.0
TARGET_LAT=-45.0
TARGET_LON=170.0
# Primary resolution is an integer value
#   24 ~ 4x5, 48 ~ 2x2.25, 90 ~ 1x1.25, 180 ~ 1/2 deg, 360 ~ 1/4 deg
# Set stretched grid to ON or OFF. If ON, follow these rules for parameters:
#    (1) Minimum STRETCH_FACTOR is 1.0001
#    (2) Target lat and lon must be floats (contain decimal)
#    (3) Target lon must be in range [0,360)

#------------------------------------------------
#    Simulation Start, End, Duration, # runs
#------------------------------------------------
Start_Time="20190101 000000"
End_Time="20190102 000000"
Duration="00000001 000000"
Num_Runs=1
Monthly_Diag=0 # Only for use with multi-run script gchp.multirun.sh. Set to 1 to enable.
#
# The simplest run is a single segment run (Num_Runs=1). For this case
# duration should be less than or equal to the difference between start
# and end time. If end time is past start time plus duration, the simulation
# will end at start time plus duration rather than end time.
#
# Setting duration such that two or more durations can occur between start
# and end will enable multi-segmented runs. At the end of each run the 
# end time is stored as the new start time in output file cap_restart.
# Rerunning without removing or editing cap_restart will start at the
# start time in cap_restart rather than the start time set here. 
# Use this feature with the multi-segmented runs, what we call the
# multi-run option. Use this option as follows:
#
#   1. Set Num_Runs to total # of consecutive runs
#   2. Set durationto the duration of each INDIVIDUAL run
#   3. Set end date after start date to span ALL runs
#   4. Copy gchp.multirun.sh and gchp.multirun.run from runScriptSamples/
#      to run directory
#   5. Configure resources at the top of gchp.multirun.run (assumes SLURM).
#      This is the run script used for each individual run in the sequence.
#      It is important to use this since it contains necessary automatic
#      updates such as using the output restart file from one run as the
#      input restart file in the next.
#   6. Execute shell script gchp.multirun.sh at the command line
#         $ ./gchp.multirun.sh
#
#------------------------------------------------
#    Initial Restart File
#------------------------------------------------
INITIAL_RESTART=initial_GEOSChem_rst.c${CS_RES}_TransportTracers.nc

# By default the linked restart files in the run directories will be 
# used. Please note that HEMCO restart variables are stored in the same
# restart file as species concentrations. Initial restart files available 
# on gcgrid do not contain HEMCO variables which will have the same effect
# as turning the HEMCO restart file option off in GC classic. However, all 
# output restart files will contain HEMCO restart variables for your next run.
# You can specify a custom initial restart file by overwriting the default.

#------------------------------------------------
#    Turn Components On/Off
#------------------------------------------------
Turn_on_Chemistry=T
Turn_on_emissions=T
Turn_on_Dry_Deposition=T
Turn_on_Wet_Deposition=T
Turn_on_Transport=T
Turn_on_Cloud_Conv=T
Turn_on_PBL_Mixing=T
Turn_on_Non_Local_Mixing=T
# Automatically turns on/off GEOS-Chem components in input.geos.
# WARNING: these settings will override manual updates you make to input.geos!

#------------------------------------------------
#    Timesteps
#------------------------------------------------
if [[ $CS_RES -lt 180 ]]; then
    ChemEmiss_Timestep_sec=1200
    TransConv_Timestep_sec=600
    TransConv_Timestep_HHMMSS=001000
else
    ChemEmiss_Timestep_sec=600
    TransConv_Timestep_sec=300
    TransConv_Timestep_HHMMSS=000500
fi
RRTMG_Timestep_sec=10800
# Optimal timesteps are dependent on grid resolution and are automatically
# set based on the GCHP Working Group's recommendation below. To override
# these settings, comment out the code and manually define the following
# variables:
#    ChemEmiss_Timestep_sec     : chemistry timestep interval [s]
#    TransConv_Timestep_sec     : dynamic timestep interval [s]
#    TransConv_Timestep_HHMMSS  : dynamic timestep interval as HHMMSS string
#
# WARNING: Settings in this file will override settings in input.geos!
#
# NOTE: Default timesteps for c24 and c48, the cubed-sphere rough equivalents
# of 4x5 and 2x2.5, are the same as defaults timesteps in GEOS-Chem Classic

#------------------------------------------------
#    Output Restarts
#------------------------------------------------
Periodic_Checkpoint=OFF
Checkpoint_Freq="1680000"
Checkpoint_Ref_Date=START
Checkpoint_Ref_Time=START
# You can output restart files at regular or irregular intervals throughout
# your simulation. These restarts are in addition to the end-of-run restart
# which is always produced. To turn on periodic checkpoints, set
# Period_Checkpoint to ON; set to OFF to disable.
#
# To configure regular checkpoint files:
#  - Set Checkpoint_Freq to a string of format HHmmss. More than 2 digits for
#    hours string is permitted, e.g. 168000 for 7 days.
#  - Set Checkpoint_Ref_Date and Checkpoint_Ref_Date to START to use the run
#    start datetime as reference time; else set them to YYYYMMDD and HHmmss.
#  - WARNING: if using the run start datetime as reference time then a checkpoint
#    file will be output the first timestep. That happens before setting the
#    values from the restart files so it will contain all zeros.
#
# To configure irregular checkpoint files:
#  - Set Checkpoint_Freq to string of space-separated zeros with each zero
#    corresponding to a single checkpoint file (e.g. 0 0 0 for 3 checkpoints total)
#  - Set Checkpoint_Ref_Date to a string of space-separated YYYYMMDD values.
#  - Set Checkpoint_Ref_Time to a string of space-separated HHmmss values.
#  - WARNING: There is currently a limit of 9 irregular checkpoint values.

#------------------------------------------------
#    Output Diagnostics
#------------------------------------------------        
timeAvg_freq="240000"
timeAvg_dur="240000"
timeAvg_collections=(SpeciesConc    \
                     AerosolMass    \
                     Aerosols       \
                     Budget         \
                     CloudConvFlux  \
                     ConcAfterChem  \
                     DryDep         \
                     Emissions      \
                     JValues        \
                     KppDiags       \
                     LevelEdgeDiags \
                     Metrics        \
                     ProdLoss       \
                     RadioNuclide   \
                     RRTMG 	    \
                     StateChm	    \
                     StateMet       \
                     Transport	    \
                     WetLossConv    \
                     WetLossLS      \
)

# Instantaneous diagnostics
inst_freq="240000"
inst_dur="240000"
inst_collections=(ConcAboveSfc      \
)
# Set frequency and duration for time-averaged and instantaneous collections.
#
#   Frequency = frequency of diagnostic calculation (HHmmSS)
#   Duration  = frequency of diagnostic file  write (HHmmSS)
# 
# NOTES: 
#  1. Freq and duration hours may exceed 2 digits, e.g. 7440000 for 31 days
#  2. Collections excluded from the lists must be manually set in HISTORY.rc
#  3. To turn off collections comment them out in HISTORY.rc, not here.

#------------------------------------------------
#    Debug Options
#------------------------------------------------
MAPL_EXTDATA_DEBUG_LEVEL=0
MEMORY_DEBUG_LEVEL=0
# Set MAPL ExtData debug flag to 0 for no extra MAPL debug log output, or 1 to
# print information to log. Using this flag is most helpful for debugging
# issues with file read (MAPL ExtData).
#
# Set memory debug flag to 0 to print memory only once per timestep. Set to
# 1 to enable memory prints at additional locations throughout the run.
#
# For GEOS-Chem debug prints, turn on ND70 in input.geos manually.       
#
# WARNING: Turning on debug prints significantly slows down the model!

#------------------------------------------------------------------
#    Dust mass tuning factor (only if using HEMCO dust extension)
#------------------------------------------------------------------
dustEntry=$(grep "105.*DustDead" HEMCO_Config.rc)
dustSetting=(${dustEntry// / })
if [[ ${dustSetting[3]} = "on" ]]; then
    if [[ $CS_RES -eq 24 ]]; then
        Dust_SF=6.0e-4
    elif [[ $CS_RES -eq 48 ]]; then
        Dust_SF=5.0416e-4
    elif [[ $CS_RES -eq 90 ]]; then
        Dust_SF=4.0e-4
    elif [[ $CS_RES -eq 180 ]]; then
        Dust_SF=3.23e-4
    elif [[ $CS_RES -eq 360 ]]; then
        Dust_SF=2.35e-4
    elif [[ $CS_RES -eq 720 ]]; then
        Dust_SF=2.3e-4
    else
        echo "Dust scale factor not defined for this resolution. Please add the tuning factor you wish to use for the target resolution above."
        exit 1
    fi
fi
# Dust_SF sets mass tuning factor in HEMCO_Config.rc used in the
# DustDead extension. The mass tuning factor is resolution-dependent and must
# be defined here for the target resolution if using online dust.
# NOTE: the online dust extension is NOT recommended for use in GCHP

##########################################################
##########################################################
####        END OF CONFIGURABLES SECTION
##########################################################
##########################################################

###############################
####   ERROR CHECKS
###############################

#### Check that resource allocation makes sense
if (( ${TOTAL_CORES}%6 != 0 )); then
   echo "ERROR: TOTAL_CORES must be divisible by 6. Update value in runConfig.sh."
   exit 1    
fi
if (( ${TOTAL_CORES} != ${NUM_NODES}*${NUM_CORES_PER_NODE} )); then
   echo "ERROR: TOTAL_CORES must equal to NUM_NODES times NUM_CORES_PER_NODE. Update values in runConfig.sh."
   exit 1    
fi

#### If on, auto-calculate NX and NY to maximize squareness of core regions
if [[ ${NXNY_AUTO} == 'ON' ]]; then
   Z=$(( ${NUM_NODES}*${NUM_CORES_PER_NODE}/6 ))
   # Use "bash calculator" if available; Python if not; fail otherwise
   which bc &> /dev/null; bc_ok=$?
   which python &> /dev/null; py_ok=$?
   if [[ $bc_ok -eq 0 ]]; then
      # Use bash calculator
      SQRT=$(echo "sqrt (${Z})" | bc -l)  
      N=$(echo $SQRT | awk '{print int($1+0.999)}')
   elif [[ $py_ok -eq 0 ]]; then
      # Use system Python
      SQRT=$( python -c "import math; print(int(math.sqrt(${Z})))" )
      N=$SQRT
   else
      echo "Cannot auto-determine NX and NY (need either bc or python available)"
      exit 70
   fi
   while [[ "${N}" > 0 ]]; do
      if (( ${Z} % ${N} == 0 )); then
         NX=${N}
         NY=$((${Z}/${N}*6))
         break
      else
         N=$((${N}-1))
      fi
   done
fi

#### Check that NX and NY make sense
if (( ${NX}*${NY} != ${TOTAL_CORES} )); then
   echo "ERROR: NX*NY must equal TOTAL_CORES. Check values in runConfig.sh."
   exit 1    
fi
if (( ${NY}%6 != 0 )); then
   echo "ERROR: NY must be an integer divisible by 6. Check values in runConfig.sh."
   exit 1    
fi

#### Check that domain decomposition will not trigger a FV3 domain error
if [[ $(( ${CS_RES}/${NX} )) -lt 4 || $(( ${CS_RES}*6/${NY} )) -lt 4  ]]; then
   echo "ERROR: NX and NY are set such that face side length divided by NX or NY/6 is less than 4. The cubed sphere compute domain has a minimum requirement of 4 points in NX and NY/6. This problem occurs when grid resolution is too low for core count requested. Edit runConfig.sh to loower total number of cores or increase your grid resolution."
   exit 1
fi

#### Check if domains are square enough (NOTE: approx using integer division)
if [[ $(( ${NX}*6/${NY}*2 )) -ge 5 || $(( ${NY}/${NX}/6*2 )) -ge 5 ]] ; then
    echo "WARNING: NX and NY are set such that NX x NY/6 has side ratio >= 2.5. Consider adjusting resources in runConfig.sh to be more square. This will avoid negative effects due to excessive communication between cores."
fi

#### Give error if chem timestep is < dynamic timestep
if [[ ${ChemEmiss_Timestep_sec} -lt ${TransConv_Timestep_sec} ]]; then
    echo "ERROR: chemistry timestep must be >= dynamic timestep. Update values in runConfig.sh."
    exit 1
fi

## Check if restart file exists
if [[ ! -e ${INITIAL_RESTART} ]]; then
    printf 'ERROR: Restart file specified in runConfig.sh not found: %s\n' ${INITIAL_RESTART}
    exit 1
fi

#### Check transport setting. If okay, set binary indicator
if [[ ${Turn_on_Transport} == 'T' ]]; then
    ADVCORE_ADVECTION=1
elif [[ ${Turn_on_Transport} == 'F' ]]; then
    ADVCORE_ADVECTION=0
else
    echo "ERROR: Incorrect transport setting"
    exit 1
fi

#### If using stretched grid, check that target lat and lon have decimal
if [[ ${STRETCH_GRID} == 'ON' ]]; then
    if [[ ${TARGET_LAT} != *"."* ]]; then
	echo "ERROR: Stretched grid target latitude must be float. Edit entry in runConfig.sh."
	exit 1
    elif [[ ${TARGET_LON} != *"."* ]]; then
	echo "ERROR: Stretched grid target longitude must be float. Edit entry in runConfig.sh."
	exit 1
    fi
fi

##########################################
####   DEFINE FUNCTIONS TO UPDATE FILES
##########################################

#### Determine whether to print info about updates. Prints enabled by default.
verbose=1
if [ $# -ne 0 ]; then
    if [[ $1 = "--silent" ]]; then
        verbose=0
    fi
fi

#### Function to print message
print_msg() {
    if [[ ${verbose} = "1" ]]; then
        echo $1
    fi
}

#### Define function to replace values in .rc files
replace_val() {
    KEY=$1
    VAL=$2
    FILE=$3
    if [[ ${verbose} = "1" ]]; then
	printf '%-30s : %-20s %-20s\n' "${KEY//\\}" "${VAL}" "${FILE}"
    fi

    # Use : for delimiter by default, unless argument passed
    if [[ -z $4 ]]; then
	DELIMITER=:
    else
	DELIMITER=$4
    fi

    # replace value in line starting with 'whitespace + key + whitespace + : +
    # whitespace + value' where whitespace is variable length including none
    sed "s|^\([\t ]*${KEY}[\t ]*${DELIMITER}[\t ]*\).*|\1${VAL}|" ${FILE} > tmp
    mv tmp ${FILE}
}

#### Define function to uncomment line in config file
uncomment_line() {
    if [[ $(grep -c "^[\t ]*$1" $2) == "1" ]]; then
	return
    fi
    num_lines=$(grep -c "^[\t ]*#*[\t ]*$1" $2)
    if [[ $num_lines == "1" ]]; then
        sed -i -e "s|[\t ]*#*[\t ]*$1|$1|" $2
    elif [[ $num_lines == "0" ]]; then
	echo "ERROR: Entry for $1 missing in $2!"
        exit 1
    else
	echo "ERROR: Multiple entries for $1 found in $2!"
        exit 1
    fi
}

#### Define function to comment line in config file
comment_line() {
    if [[ $(grep -c "#.*$1" $2) == "1" ]]; then
	return
    fi
    num_lines=$(grep -c "^[\t ]*$1" $2)
    if [[ $num_lines == "1" ]]; then
        sed -i -e "s|[\t ]*$1|#$1|" $2
    elif [[ $num_lines > "1" ]]; then
	echo "ERROR: Multiple entries for $1 found in $2!"
        exit 1
    fi
}

#### Define function to replace met-field read frequency in ExtData.rc given var name
update_dyn_freq() {

    # String to search for
    str="^[\t ]*$1.*MetDir"

    # Check number of matches where first string is start of line, allowing for
    # whitespace. # matches should be one; otherwise exit with an error.
    numlines=$(grep -c "$str" $2)
    if [[ ${numlines} == "0" ]]; then
       echo "ERROR: met-field $1 missing in $2"
       #exit 1
    elif [[ ${numlines} > 1 ]]; then
       echo "ERROR: more than one entry in $1 in $2. Reduce to one so that read frequency can be auto-synced with dynamic timestep from runConfig.sh."
       exit 1
    fi
    
    # Get line number
    x=$(grep -n "$str" $2)
    linenum=${x%%:*}
    
    # Get current ExtData.rc frequency read string
    x=$(grep "$str" $2)
    z=${x%%;*}
    charnum=${#z}
    currentstr=${x[0]:${charnum}+1:6}
    
    # Replace string with configured dynamic timestep
    sed -i "${linenum}s/${currentstr}/${TransConv_Timestep_HHMMSS}/" $2

    # Print what just happened
    if [[ ${verbose} = "1" ]]; then
	printf '%-30s : %-20s %-20s\n' "$1 read frequency" "0;${TransConv_Timestep_HHMMSS}" "$2"
    fi
}

###############################
####   UPDATE FILES
###############################
print_msg " "
print_msg "============================================================"
print_msg "Auto-updating config files based on settings in runConfig.sh"
print_msg "============================================================"

#### Set # nodes, # cores, and shared memory option
print_msg " "
print_msg "Compute resources:"
print_msg "------------------"
replace_val NX            ${NX}                 GCHP.rc
replace_val NY            ${NY}                 GCHP.rc
replace_val CoresPerNode  ${NUM_CORES_PER_NODE} HISTORY.rc

#### If # cores exceeds 1000 then write restart via o-server
if [ ${TOTAL_CORES} -gt 1000 ]; then
   print_msg "WARNING: write restarts by o-server is enabled since >1000 cores"
   replace_val WRITE_RESTART_BY_OSERVER   YES   GCHP.rc
fi

####  set cubed-sphere resolution and related grid variables
print_msg " "
print_msg "Cubed-sphere resolution:"
print_msg "------------------------"
CS_RES_x_6=$((CS_RES*6))
replace_val GCHP.IM_WORLD  ${CS_RES}                     GCHP.rc
replace_val GCHP.IM        ${CS_RES}                     GCHP.rc
replace_val GCHP.JM        ${CS_RES_x_6}                 GCHP.rc
replace_val IM             ${CS_RES}                     GCHP.rc
replace_val JM             ${CS_RES_x_6}                 GCHP.rc
replace_val GCHP.GRIDNAME  PE${CS_RES}x${CS_RES_x_6}-CF  GCHP.rc
if [[ ${STRETCH_GRID} == "ON" ]]; then
    print_msg " "
    print_msg "WARNING: stretched grid is enabled"
    uncomment_line GCHP.STRETCH_FACTOR           GCHP.rc
    uncomment_line GCHP.TARGET_LAT               GCHP.rc
    uncomment_line GCHP.TARGET_LON               GCHP.rc
    sed -i -e "s|#\&fv#_core_nml|\&fv_core_nml|" input.nml
    uncomment_line do_schmidt                    input.nml
    uncomment_line stretch_fac                   input.nml
    uncomment_line target_lat                    input.nml
    uncomment_line target_lon                    input.nml
    replace_val GCHP.STRETCH_FACTOR ${STRETCH_FACTOR}  GCHP.rc
    replace_val stretch_fac,        ${STRETCH_FACTOR}, input.nml =
    replace_val GCHP.TARGET_LAT     ${TARGET_LAT}      GCHP.rc
    replace_val target_lat,         ${TARGET_LAT},     input.nml =
    replace_val GCHP.TARGET_LON     ${TARGET_LON}      GCHP.rc
    replace_val target_lon,         ${TARGET_LON}/     input.nml =
elif [[ ${STRETCH_GRID} == "OFF" ]]; then
    comment_line GCHP.STRETCH_FACTOR             GCHP.rc
    comment_line GCHP.TARGET_LAT                 GCHP.rc
    comment_line GCHP.TARGET_LON                 GCHP.rc
    sed -i -e "s|\&fv_core_nml|#\&fv#_core_nml|" input.nml
    comment_line do_schmidt                      input.nml
    comment_line stretch_fac                     input.nml
    comment_line target_lat                      input.nml
    comment_line target_lon                      input.nml
else
    print_msg "WARNING: unknown setting for GCHP.STRETCH_GRID."
    exit 1
fi

####  set input restart filename
print_msg " "
print_msg "Initial restart file:"
print_msg "---------------------"
replace_val GCHPchem_INTERNAL_RESTART_FILE "+${INITIAL_RESTART}" GCHP.rc

#### Set simulation start and end datetimes based on input.geos
print_msg " "
print_msg "Simulation start, end, duration:"
print_msg "--------------------------------"
replace_val BEG_DATE  "${Start_Time}" CAP.rc
replace_val END_DATE  "${End_Time}"   CAP.rc
replace_val JOB_SGMT  "${Duration}"   CAP.rc

#### Set debug level
print_msg " "
print_msg "Debug levels:"
print_msg "-------------"
replace_val DEBUG_LEVEL ${MAPL_EXTDATA_DEBUG_LEVEL} ExtData.rc
replace_val MEMORY_DEBUG_LEVEL ${MEMORY_DEBUG_LEVEL} GCHP.rc

##### Set commonly changed settings in input.geos
print_msg " "
print_msg "Components on/off:"
print_msg "------------------"
replace_val "Turn on Chemistry?"        ${Turn_on_Chemistry}        input.geos
replace_val "Turn on emissions?"	${Turn_on_emissions}        input.geos
replace_val "Turn on Transport"	        ${Turn_on_Transport}        input.geos
replace_val "Turn on Cloud Conv?"	${Turn_on_Cloud_Conv}       input.geos
replace_val "Turn on PBL Mixing?"	${Turn_on_PBL_Mixing}       input.geos
replace_val " => Use non-local PBL?"	${Turn_on_Non_Local_Mixing} input.geos
replace_val "Turn on Dry Deposition?"   ${Turn_on_Dry_Deposition}   input.geos
replace_val "Turn on Wet Deposition?"   ${Turn_on_Wet_Deposition}   input.geos
replace_val AdvCore_Advection           ${ADVCORE_ADVECTION}        GCHP.rc

#### Set timesteps. This includes updating ExtData.rc entries for PS2,
#### SPHU2, and TMPU2 such that read frequency matches dynamic frequency
print_msg " "
print_msg "Timesteps:"
print_msg "----------"
replace_val "Tran\/conv timestep \[sec\]"  ${TransConv_Timestep_sec} input.geos
replace_val "Chem\/emis timestep \[sec\]"  ${ChemEmiss_Timestep_sec} input.geos
replace_val "Radiation Timestep \[sec\]"   ${RRTMG_Timestep_sec}     input.geos
replace_val HEARTBEAT_DT  ${TransConv_Timestep_sec}  GCHP.rc
replace_val SOLAR_DT      ${TransConv_Timestep_sec}  GCHP.rc
replace_val IRRAD_DT      ${TransConv_Timestep_sec}  GCHP.rc
replace_val RUN_DT        ${TransConv_Timestep_sec}  GCHP.rc
replace_val GCHPchem_DT   ${ChemEmiss_Timestep_sec}  GCHP.rc
replace_val RRTMG_DT      ${RRTMG_Timestep_sec}      GCHP.rc
replace_val DYNAMICS_DT   ${TransConv_Timestep_sec}  GCHP.rc
replace_val HEARTBEAT_DT  ${TransConv_Timestep_sec}  CAP.rc
replace_val GCHPchem_REFERENCE_TIME ${TransConv_Timestep_HHMMSS} GCHP.rc
update_dyn_freq PS2   ExtData.rc
update_dyn_freq SPHU2 ExtData.rc
update_dyn_freq TMPU2 ExtData.rc

#### Set frequency of writing restart files
# Set to a very large number if turned off
print_msg " "
print_msg "Periodic checkpoints:"
print_msg "---------------------"
if [[ ${Periodic_Checkpoint} == "ON" ]]; then
    uncomment_line RECORD_FREQUENCY GCHP.rc
    uncomment_line RECORD_REF_DATE  GCHP.rc
    uncomment_line RECORD_REF_TIME  GCHP.rc
    use_start=1
    replace_val RECORD_FREQUENCY "${Checkpoint_Freq}" GCHP.rc
    if [[ ${Checkpoint_Ref_Date} == "START" ]]; then
        Checkpoint_Ref_Date="${Start_Time:0:8}"
    else
	use_start=0
    fi
    if [[ ${Checkpoint_Ref_Time} == "START" ]]; then
        Checkpoint_Ref_Time="${Start_Time:9:6}"
    else
	use_start=0
    fi
    replace_val RECORD_REF_DATE "${Checkpoint_Ref_Date}" GCHP.rc
    replace_val RECORD_REF_TIME "${Checkpoint_Ref_Time}" GCHP.rc
    if [[ ${use_start} == "1" ]]; then
        print_msg "WARNING: Checkpoint file written at simulation start will contain all zeros"
    fi
elif [[ ${Periodic_Checkpoint} == "OFF" ]]; then
    print_msg "WARNING: Periodic checkpoints are turned off"
    comment_line RECORD_FREQUENCY GCHP.rc
    comment_line RECORD_REF_DATE  GCHP.rc
    comment_line RECORD_REF_TIME  GCHP.rc
else
    print_msg "ERROR: unknown setting for Periodic_Checkpoint. Must be ON or OFF."
    exit 1
fi

#### Set output frequency, duration, and mode
print_msg " "
print_msg "Diagnostics:"
print_msg "------------"

if [[ ${#timeAvg_collections[@]} > 0 ]]; then
   for c in ${timeAvg_collections[@]}; do
      replace_val $c.mode        "'time-averaged'" HISTORY.rc
      replace_val $c.frequency   ${timeAvg_freq}   HISTORY.rc  
      replace_val $c.duration    ${timeAvg_dur}    HISTORY.rc
   done
fi
if [[ ${#inst_collections[@]} > 0 ]]; then
   for c in ${inst_collections[@]}; do
      replace_val $c.mode        "'instantaneous'" HISTORY.rc
      replace_val $c.frequency   ${inst_freq}      HISTORY.rc  
      replace_val $c.duration    ${inst_dur}       HISTORY.rc
   done
fi

#### Set options in HEMCO_Config.rc
print_msg ""
if [[ ${dustSetting[3]} = "on" ]]; then
    print_msg "HEMCO settings:"
    print_msg "---------------"
    replace_val "--> Mass tuning factor" ${Dust_SF} HEMCO_Config.rc
fi

exit 0

