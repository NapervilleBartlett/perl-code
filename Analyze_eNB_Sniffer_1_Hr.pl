#!/bin/perl


# Usage:  Analyze_eNB_Sniffer_1_Hr.pl     date          $Hr                  eNB_IP        
# Usage:  Analyze_eNB_Sniffer_1_Hr.pl     20101101	11                    1.2.3.4





$today    = $ARGV[0]   ;
$hr       = $ARGV[1]   ;
$enb_ip   = $ARGV[2]   ;

@Stats_Tags =  ('Attach request', 'Attach complete', 'Detach request', 'Detach accept', InitialContextSetupRequest, InitialContextSetupResponse,PathSwitchRequest, PathSwitchRequestAcknowledge,'Tracking area update request','Tracking area update accept','PDN connectivity request','PDN disconnect request', UEContextReleaseRequest,UEContextReleaseCommand,UEContextReleaseComplete,Reset,Error,'Service Request',Paging);

%One_File_Stats = () ;

%All_Stats = (); 

if ($hr < 0) { return ; }




	print "\n\n\n#######   CST hr=$hr   Date=$ARGV[0]     \n" ;
	

	foreach $min ('00',15,30,45) {
		# 20110630/1430-1445/20110630_1430_ltepc061_Signalling_eth1.pcap.txt
		$cmd = "ls $today/$hr$min" . '*/*Sig*.txt' ;
		$In_file = `$cmd`;
		chop($In_file);
		# print "Idrees cmd=$cmd=    In_file=$In_file=  enb_ip=$enb_ip= \n";

		# $out_file = "/tmp/$today" . '_' . $hr . '_' . $min . '.txt';
	
		open (INFILE , $In_file) || next ; 
		%One_File_Stats = () ;
		# print "Idrees file opened=$In_file= enb_ip=$enb_ip= \n";
		&Initialize_One_File_Stats ;

		while( $line = <INFILE> ){
			if ($line =~ /$enb_ip/) {
				foreach $tag (@Stats_Tags) {
					if ($line =~ /$tag /)            { 
						$One_File_Stats{$tag}++ ;
						# print "Idrees tag=$tag=   count=$One_File_Stats{$tag}= enb_ip=$enb_ip= \n";
						last ; 
					}
				}
			}
		}
		close (INFILE);
		# print "Idrees closing file=$In_file=\n";

		foreach $stats_key (sort keys %One_File_Stats) {
			# print "Idrees stats_key=$stats_key   count=$One_File_Stats{$stats_key}=\n";
			$tmp_str = "";
			$tmp_str = sprintf(",%-10.10s",$One_File_Stats{$stats_key}); 
			$All_Stats{$stats_key} .= "$tmp_str";
		}
	}
	

printf "%-30.30s ","Interval";
foreach $min ('00-15','15-30','30-45','45-00') { printf ",%-10.10s",$min; }
print "\n";

foreach $stats_key (sort keys %All_Stats) {
	printf "%-30.30s $All_Stats{$stats_key} \n",$stats_key   ;
}


		


sub Initialize_One_File_Stats {

	foreach $tag (@Stats_Tags) {
		$One_File_Stats{$tag}=0;

	}
}

