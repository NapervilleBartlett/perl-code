#!/bin/perl


# Usage:  c1.pl  All_Day_Sniffer_Summary_27.132.68.73.txt

# This will look at the All_Day_Sniffer_Summary_27.132.68.73.txt     file and 
# compare the #s to the C1 call model #s.

$Sniffer_Summary_FileName = $ARGV[0];


# Call model 
# Attach			1000
# UE Initiated Detach		1000
# PDN Connectivity Request 	20000
# PDN Connectivity Release	20000
# Service Request (MO)		20,000
# TA update (intra MME &  SGW)	40000
# S1 Release			62000
# HO Inter-eNB         		44000


# C1_Stats_Name					C1_Stats_Values

$C1_Stats_Values{'Attach'} 			= 1000;
$C1_Stats_Values{'UE Initiated Detach'} 	= 1000;
$C1_Stats_Values{'PDN Connectivity Request'}   	= 20000;
$C1_Stats_Values{'PDN Connectivity Release'}   	= 20000;
$C1_Stats_Values{'Service Request'}          	= 20000;
$C1_Stats_Values{'TA update' } 			= 40000;
$C1_Stats_Values{'S1 Release'}                 	= 62000;
$C1_Stats_Values{'HO Inter eNB'}               	= 44000;

$Sniffer_Stats_Name{'Attach'} 				= "Attach complete"; 
$Sniffer_Stats_Name{'UE Initiated Detach'} 		= "Detach request"; 
$Sniffer_Stats_Name{'PDN Connectivity Request'}   	= "PDN connectivity request"; 
$Sniffer_Stats_Name{'PDN Connectivity Release'}   	= "PDN disconnect request"; 
$Sniffer_Stats_Name{'Service Request'}          	= "Service Request";
$Sniffer_Stats_Name{'TA update' } 			= "Tracking area update accept";
$Sniffer_Stats_Name{'S1 Release'}                 	= "UEContextReleaseComplete";
$Sniffer_Stats_Name{'HO Inter eNB'}               	= "PathSwitchRequestAcknowledge";






# Look for CST | Interval
open (INFILE , "< $Sniffer_Summary_FileName") ;

while (<INFILE>) {
	$line = $_ ;
	
	if ($line =~ /CST/) { 
		print "\n\n\n$line\n"; 
		printf ("%-20.20s %-8.8s %-18.18s\n","  " , "C1 ", "Current Hr" );
	}




	# Look for Attach                        1000
	# $Pat="Attach complete"; 
	# $C1_Stat_Name = "Attach";
	
	$Val=0;
	foreach $C1_Stats_Name (keys %C1_Stats_Values) {
		if ($line =~ /$Sniffer_Stats_Name{$C1_Stats_Name}/) { 
			# Attach complete                ,339       ,0         ,339       ,0  
			($Name,$val1,$val2,$val3,$val4) = split (/,/,$line);
			$Val = ($val1 + $val2 + $val3 + $val4);
			printf ("%-20.20s %-8.8s %-8.8s\n",$C1_Stats_Name, $C1_Stats_Values{$C1_Stats_Name}, $Val);
		}
	}

}


close (INFILE);

