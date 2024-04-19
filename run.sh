#!/bin/bash

set -ex

# Work relative to script directory
cd "$(dirname "$0")"

# Global variables
declare -a SCHED=("ns3::PfFfMacScheduler" "ns3::RrFfMacScheduler" "ns3::FdBetFfMacScheduler" "ns3::FdMtFfMacScheduler")
declare -a LABEL=("pf" "rr" "bat" "mt")
declare -a CAPS_LABEL=("PF" "RR" "BAT" "MT")
declare -a SPEED=("0" "5")
declare -a BUFFER=("Non-full" "Full")
NUM_UES=20
FILE_SEP=","
FILE_EXT=".csv"

# Function to write average throughput to file (in Kbps)
function gen_avg_thr {
    for (( i = 0; i < ${#BUFFER[@]}; i++ ))
    do
        # Path of the data file
        DATAFILE="data/buf${i}/avg_thr${FILE_EXT}"
        # Set up the file header
        echo -n "Speed (m/s)" > "$DATAFILE"
        for label in "${CAPS_LABEL[@]}"
        do
            echo -n "$FILE_SEP$label" >> "$DATAFILE"
        done
        echo "" >> "$DATAFILE"
        for speed in "${SPEED[@]}"
        do
            # Write index of row
            echo -n "$speed" >> "$DATAFILE"
            for label in "${LABEL[@]}"
            do
                avg=$(awk -f scripts/avg_thr.awk $(find data/buf${i}/"${label}"/speed"${speed}" -type f -regex ".*DlRlcStats\.txt"))
                # Write datapoint
                echo -n "$FILE_SEP$avg" >> "$DATAFILE"
            done
            echo "" >> $DATAFILE
        done
    done
}

function plt_avg_thr {
    for (( i = 0; i < ${#BUFFER[@]}; i++ ))
    do
        # Path of the data file
        DATAFILE="../data/buf${i}/avg_thr${FILE_EXT}"
        # Path of the image file
        OUTFILE="../figs/buf${i}/avg_thr.png"
        # Create directory for image if not exists
        mkdir -p "figs/buf${i}"
        # Call gnuplot script
        gnuplot -e "plotfile='$OUTFILE'; plotdata='$DATAFILE'; plottitle='Average Aggregate Throughput (${BUFFER[$i]} Buffer)'" scripts/avg_thr.plt
    done
}

# Function to compute average throughput of a given UE IMSI for throughput CDF
# plot
function gen_ue_cdf {
    for (( i = 0; i < ${#BUFFER[@]}; i++ ))
    do 
        OUTFILE="data/buf${i}/ue_avg_thr${FILE_EXT}"
        # Set up the data file
        echo "Number of UEs" > "$OUTFILE"
        seq $NUM_UES | tee -a "$OUTFILE"
        # Add headers to data file
        for (( j = 0; j < ${#LABEL[@]}; j++ ))
        do
            label="${LABEL[$j]}"
            caps_label="${CAPS_LABEL[$j]}"
            for speed in "${SPEED[@]}"
            do
                echo "${caps_label} (${speed} m/s)" > tmp
                awk -v num_ues="$NUM_UES" -f scripts/ue_avg_thr.awk $(find data/buf${i}/"${label}"/speed"${speed}" -type f -regex ".*DlRlcStats\.txt") >> tmp
                paste -d"$FILE_SEP" "$OUTFILE" tmp > tmp1 && mv tmp1 "$OUTFILE"
            done
        done
    done
    rm tmp
}

function plt_ue_cdf {
    for (( i = 0; i < ${#BUFFER[@]}; i++ ))
    do
        # Setup data file and output image file
        DATAFILE="../data/buf${i}/ue_avg_thr${FILE_EXT}"
        OUTFILE="../figs/buf${i}/ue_avg_thr.png"
        # Create directory if not exists
        mkdir -p "figs/buf${i}"
        # Call gnuplot script
        gnuplot -e "plotfile='$OUTFILE'; plotdata='$DATAFILE'; plottitle='Throughput CDF for Various Schedulers'" scripts/ue_avg_thr.plt
    done
}

# Function to find instantaneous throughput for UE 1 in various scenarios
function gen_inst_thr {
    for (( i = 0; i < ${#BUFFER[@]}; i++ ))
    do
        for speed in "${SPEED[@]}"
        do
            # Set output file
            OUTFILE="data/buf${i}/ue1_inst_speed${speed}${FILE_EXT}"
            echo "Time (s)" > "$OUTFILE"
            # Add timestamps
            tail -n +2 "data/buf0/pf/speed0/1_DlRlcStats.txt" | cut -f1 | sort -nu | tee -a "$OUTFILE"
            for (( j = 0; j < ${#LABEL[@]}; j++ ))
            do
                label="${LABEL[$j]}"
                caps_label="${CAPS_LABEL[$j]}"
                # Set datafile
                DATAFILE="data/buf${i}/${label}/speed${speed}/1_DlRlcStats.txt"
                # Populate the temporary file
                echo "${caps_label}" > tmp
                awk -v imsi=1 -f scripts/ue_inst_thr.awk "$DATAFILE" | cut -d' ' -f2 | tee -a tmp
                # Append as column to output data file
                paste -d"${FILE_SEP}" "$OUTFILE" tmp > tmp1 && mv tmp1 "$OUTFILE"
            done
        done
    done
    rm tmp
}

# Function to find instantaneous SINR for UE 1 in various scenarios
function gen_inst_sinr {
    for (( i = 0; i < ${#BUFFER[@]}; i++ ))
    do
        for speed in "${SPEED[@]}"
        do
            # Set output file
            OUTFILE="data/buf${i}/ue1_sinr_speed${speed}${FILE_EXT}"
            echo "Time (s)" > "$OUTFILE"
            # Add timestamps
            tail -n +2 "data/buf0/pf/speed0/1_DlRsrpSinrStats.txt" | cut -f1 | sort -nu | tee -a "$OUTFILE"
            for (( j = 0; j < ${#LABEL[@]}; j++ ))
            do
                label="${LABEL[$j]}"
                caps_label="${CAPS_LABEL[$j]}"
                # Set datafile
                DATAFILE="data/buf${i}/${label}/speed${speed}/1_DlRsrpSinrStats.txt"
                # Populate the temporary file
                echo "${caps_label}" > tmp
                awk -v imsi=1 -f scripts/ue_inst_sinr.awk "$DATAFILE" | cut -d' ' -f2 | tee -a tmp
                # Append as column to output data file
                paste -d"${FILE_SEP}" "$OUTFILE" tmp > tmp1 && mv tmp1 "$OUTFILE"
            done
        done
    done
    rm tmp
}

function plt_ue_inst {
    for (( i = 0; i < ${#BUFFER[@]}; i++ ))
    do
        for speed in "${SPEED[@]}"
        do
            # Setup data file and output image file
            THRDATAFILE="../data/buf${i}/ue1_inst_speed${speed}${FILE_EXT}"
            SINRDATAFILE="../data/buf${i}/ue1_sinr_speed${speed}${FILE_EXT}"
            for (( j = 0; j < ${#CAPS_LABEL[@]}; j++ ))
            do
                OUTFILE="../figs/buf${i}/${LABEL[$j]}/ue1_inst_stat_speed${speed}.png"
                mkdir -p "figs/buf${i}/${LABEL[$j]}"
                # Call gnuplot script
                gnuplot -e "plotfile='$OUTFILE'; plotdata_thr='$THRDATAFILE'; plotdata_sinr='$SINRDATAFILE'; plottitle='UE 1 Instantaneous Throughput and SINR (${BUFFER[$i]}, ${speed} m/s, ${CAPS_LABEL[$j]})'; plotcol=$((j+2))" scripts/ue_inst.plt
            done
        done
    done
}

# Create directories for data and figures
if [[ -d data ]]
then
    rm -rf data
fi
if [[ -d figs ]]
then
    rm -rf figs
fi
mkdir -p data figs

# NS3 executable
NS3="../ns3"

# Name of script
NS3_SCRIPT="scripts/01-Asg1.cc"

# Generate REM
$NS3 run --cwd=data "$NS3_SCRIPT --generateRem=1"
gnuplot scripts/rem.plt

for (( i = 0; i < ${#BUFFER[@]}; i++))
do
    for (( j = 0; j < ${#SCHED[@]}; j++ ))
    do
        for k in "${SPEED[@]}"
        do
            CWD="data/buf${i}/${LABEL[$j]}/speed${k}"
            mkdir -p "$CWD"
            for (( r = 1; r <= 5; r++ ))
            do
                $NS3 run --cwd="$CWD" "$NS3_SCRIPT \
                         --schedulerType=${SCHED[$j]} \
                         --speed=$k \
                         --RngRun=$r \
                         --fullBufferFlag=$i \
                         --ns3::RadioBearerStatsCalculator::DlRlcOutputFilename=${r}_DlRlcStats.txt \
                         --ns3::RadioBearerStatsCalculator::UlRlcOutputFilename=${r}_UlRlcStats.txt \
                         --ns3::PhyStatsCalculator::DlRsrpSinrFilename=${r}_DlRsrpSinrStats.txt"
            done
        done
    done
done

# Remove unnecessary files
find data -type f -regex ".*UlRlcStats\.txt" -exec rm {} \;

# Generate data files
# Average aggregate system throughput
gen_avg_thr
# Throughput CDF
gen_ue_cdf
# Instantaneous throughput for UE 1 in one seed simulation
gen_inst_thr
# Instantaneous SINR for UE 1 in one seed simulation
gen_inst_sinr

# Plot data files
# Average aggregate system throughput
plt_avg_thr
# Throughput CDF
plt_ue_cdf
# Instantaneous Throughput and SINR for UE 1 in one seed simulation
plt_ue_inst
