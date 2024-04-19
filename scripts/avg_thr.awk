# Awk script to find the average DL throughput in Kbps from a list of DL RLC stats files
# 'tot' represents the total number of DL bytes to each UE
# 'min_t' represents the starting time of the trace
# 'max_t' represents the ending time of the trace
# 'scale_fac' represents the scaling factor for displaying the throughput in 
# suitable units such as Kbps or Mbps
BEGIN {
    tot = 0.0;
    min_t = 100000;
    max_t = -1;
    scale_fac = 1024*1024/8.0;
}
FNR == 1 {next;}
# Start time is in column 1
# End time is in column 2
# RxBytes is in column 10
{
    tot += $10;
    if ($1 < min_t) min_t = $1;
    if ($2 > max_t) max_t = $2;
}
# Print the average throughput
END {printf tot/(scale_fac*(max_t - min_t));}
