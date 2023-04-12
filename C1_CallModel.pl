#!/bin/perl

# This script looks at the NAS.txt and eNB_PM.txt file and compares the #s to the C1 call model #s

$C1 = "
RRC_CONNECTED 	480
Call Processing - Service Request (MO)	20,000
Call Processing - S1 Release	62000
Call Processing - Measurement Reports	40000
Mobility - IDLE mode - TA update (intra MME &  SGW)	40000
Intra-eNB handover	10000
Inter-eNB, intra-MME handover,intra-SGW	44000
Registration - UE Initiated Attach	1000
Registration - UE Initiated Detach	1000
PDN Connectivity Request 	20000
PDN Connectivity Release	20000
RRC Connection Reconfiguratio	350,000
";

$C1 =~ s/,//g;
chop ($C1);



@C1_1 = split(/\n/,$C1);

foreach $line (@C1_1) {
	# $line =~ /(\w+)( \d\d+)$/;
	if (length($line) > 5) { 
		$line =~ /\s+\d/;
		$Name = $`;
		$Val  = $&.$'; 
		print "1. Idrees line=$line= Name=$Name=  Val=$Val=\n";
		$C1_CallModel{$Name} = $Val ;
	}
}




print "\n\n\n";

foreach $key (keys %C1_CallModel) {

	print "2. Idrees key=$key=           val=$C1_CallModel{$key}= \n";

}





