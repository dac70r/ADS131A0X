# Legal Notice: (C)2025 Altera Corporation. All rights reserved.  Your
# use of Altera Corporation's design tools, logic functions and other
# software and tools, and its AMPP partner logic functions, and any
# output files any of the foregoing (including device programming or
# simulation files), and any associated documentation or information are
# expressly subject to the terms and conditions of the Altera Program
# License Subscription Agreement or other applicable license agreement,
# including, without limitation, that your use is for the sole purpose
# of programming logic devices manufactured by Altera and sold by Altera
# or its authorized distributors.  Please refer to the applicable
# agreement for further details.

#**************************************************************
# Timequest JTAG clock definition
#   Uncommenting the following lines will define the JTAG
#   clock in TimeQuest Timing Analyzer
#**************************************************************

#create_clock -period 10MHz {altera_reserved_tck}
#set_clock_groups -asynchronous -group {altera_reserved_tck}

#**************************************************************
# Set TCL Path Variables 
#**************************************************************

set 	ADS131A0X_NIOS_cpu 	ADS131A0X_NIOS_cpu:*
set 	ADS131A0X_NIOS_cpu_oci 	ADS131A0X_NIOS_cpu_nios2_oci:the_ADS131A0X_NIOS_cpu_nios2_oci
set 	ADS131A0X_NIOS_cpu_oci_break 	ADS131A0X_NIOS_cpu_nios2_oci_break:the_ADS131A0X_NIOS_cpu_nios2_oci_break
set 	ADS131A0X_NIOS_cpu_ocimem 	ADS131A0X_NIOS_cpu_nios2_ocimem:the_ADS131A0X_NIOS_cpu_nios2_ocimem
set 	ADS131A0X_NIOS_cpu_oci_debug 	ADS131A0X_NIOS_cpu_nios2_oci_debug:the_ADS131A0X_NIOS_cpu_nios2_oci_debug
set 	ADS131A0X_NIOS_cpu_wrapper 	ADS131A0X_NIOS_cpu_debug_slave_wrapper:the_ADS131A0X_NIOS_cpu_debug_slave_wrapper
set 	ADS131A0X_NIOS_cpu_jtag_tck 	ADS131A0X_NIOS_cpu_debug_slave_tck:the_ADS131A0X_NIOS_cpu_debug_slave_tck
set 	ADS131A0X_NIOS_cpu_jtag_sysclk 	ADS131A0X_NIOS_cpu_debug_slave_sysclk:the_ADS131A0X_NIOS_cpu_debug_slave_sysclk
set 	ADS131A0X_NIOS_cpu_oci_path 	 [format "%s|%s" $ADS131A0X_NIOS_cpu $ADS131A0X_NIOS_cpu_oci]
set 	ADS131A0X_NIOS_cpu_oci_break_path 	 [format "%s|%s" $ADS131A0X_NIOS_cpu_oci_path $ADS131A0X_NIOS_cpu_oci_break]
set 	ADS131A0X_NIOS_cpu_ocimem_path 	 [format "%s|%s" $ADS131A0X_NIOS_cpu_oci_path $ADS131A0X_NIOS_cpu_ocimem]
set 	ADS131A0X_NIOS_cpu_oci_debug_path 	 [format "%s|%s" $ADS131A0X_NIOS_cpu_oci_path $ADS131A0X_NIOS_cpu_oci_debug]
set 	ADS131A0X_NIOS_cpu_jtag_tck_path 	 [format "%s|%s|%s" $ADS131A0X_NIOS_cpu_oci_path $ADS131A0X_NIOS_cpu_wrapper $ADS131A0X_NIOS_cpu_jtag_tck]
set 	ADS131A0X_NIOS_cpu_jtag_sysclk_path 	 [format "%s|%s|%s" $ADS131A0X_NIOS_cpu_oci_path $ADS131A0X_NIOS_cpu_wrapper $ADS131A0X_NIOS_cpu_jtag_sysclk]
set 	ADS131A0X_NIOS_cpu_jtag_sr 	 [format "%s|*sr" $ADS131A0X_NIOS_cpu_jtag_tck_path]

#**************************************************************
# Set False Paths
#**************************************************************

set_false_path -from [get_keepers *$ADS131A0X_NIOS_cpu_oci_break_path|break_readreg*] -to [get_keepers *$ADS131A0X_NIOS_cpu_jtag_sr*]
set_false_path -from [get_keepers *$ADS131A0X_NIOS_cpu_oci_debug_path|*resetlatch]     -to [get_keepers *$ADS131A0X_NIOS_cpu_jtag_sr[33]]
set_false_path -from [get_keepers *$ADS131A0X_NIOS_cpu_oci_debug_path|monitor_ready]  -to [get_keepers *$ADS131A0X_NIOS_cpu_jtag_sr[0]]
set_false_path -from [get_keepers *$ADS131A0X_NIOS_cpu_oci_debug_path|monitor_error]  -to [get_keepers *$ADS131A0X_NIOS_cpu_jtag_sr[34]]
set_false_path -from [get_keepers *$ADS131A0X_NIOS_cpu_ocimem_path|*MonDReg*] -to [get_keepers *$ADS131A0X_NIOS_cpu_jtag_sr*]
set_false_path -from *$ADS131A0X_NIOS_cpu_jtag_sr*    -to *$ADS131A0X_NIOS_cpu_jtag_sysclk_path|*jdo*
set_false_path -from sld_hub:*|irf_reg* -to *$ADS131A0X_NIOS_cpu_jtag_sysclk_path|ir*
set_false_path -from sld_hub:*|sld_shadow_jsm:shadow_jsm|state[1] -to *$ADS131A0X_NIOS_cpu_oci_debug_path|monitor_go
