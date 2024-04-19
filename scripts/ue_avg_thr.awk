# Awk script to find the average DL throughput for all UEs from a list of DL RLC stats files
# 'num_ues': total number of UEs present
# 'tot' : total number of DL bytes to an imsi
# 'time' : total amount of time an imsi was receiving from DL
# 'scale_fac' : scaling factor for displaying the throughput in suitable units such as Kbps or Mbps
BEGIN {
    scale_fac = 1024*1024/8.0;
    for (i = 1; i <= num_ues; i++) tot[i] = 0.0;
}
FNR == 1 {next;}
# Start time is in column 1
# End time is in column 2
# IMSI is in column 4
# RxBytes is in column 10
{
    tot[$4] += $10;
    time[$4] += ($2 - $1);
}
# Print the average throughput for all UEs
END {
    PROCINFO["sorted_in"] = "@val_num_desc"
    for (key in tot) {
        print time[key]?tot[key]/(scale_fac*time[key]):0;
    }
}
