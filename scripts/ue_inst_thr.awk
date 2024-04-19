# Awk script to find instantaneous DL throughput for a UE in Kbps from a list of DL RLC stats files
# 'imsi' : external variable to be set for UE whose throughput is to be calculated 
# 'tot' : array indexed by start time of total number of DL bytes to imsi
# 'time' : array indexed by start time of total amount of time imsi was receiving from DL
# 'scale_fac' : scaling factor for displaying the throughput in suitable units such as Kbps or Mbps
BEGIN {
    # Division by 8 to convert bytes to bits
    scale_fac = 1024*1024/8.0;
}
FNR == 1 {next;}
# Start time is in column 1
# End time is in column 2
# IMSI is in column 4
# RxBytes is in column 10
{
    if (!($1 in tot)) tot[$1] = 0;
    if (imsi == $4) tot[$1] += $10;
    time[$1] += ($2 - $1);
}
# Print the instantaneous throughputs
END {
    # Set array traversal order (ascending order of indices)
    PROCINFO["sorted_in"] = "@ind_num_asc"
    for (key in tot) {
        printf("%f %f\n", key, tot[key]/(scale_fac*time[key]));
    }
}
