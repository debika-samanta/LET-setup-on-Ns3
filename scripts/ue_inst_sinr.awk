# Awk script to find instantaneous SINR for a UE in dBm from a list of DL SINR stats files
# 'imsi' : external variable to be set for UE whose throughput is to be calculated 
# 'sinr' : array indexed by timestamp of instantaneous SINR of imsi
# 'cnt' : array indexed by timestamp of total number of SINR readings taken at this time for the UE
BEGIN {}
FNR == 1 {next;}
# Time is in column 1
# IMSI is in column 3
# SINR is in column 6
$3 == imsi {
    sinr[$1] += $6;
    cnt[$1] += 1;
}
# Print the SINR in mW
END {
    # Set array traversal order (ascending order of indices)
    PROCINFO["sorted_in"] = "@ind_num_asc"
    for (key in sinr) {
        printf("%f %f\n", key, sinr[key]/cnt[key]);
    }
}
