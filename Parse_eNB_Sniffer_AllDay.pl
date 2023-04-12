#!/bin/perl


# Usage:  Parse_eNB_Sniffer_AllDay.pl   20101101





$today    = $ARGV[0]   ;
$enb_ip   = $ARGV[1]   ;
@Stats_Tags =  ('Attach request', 'Attach complete', InitialContextSetupRequest, InitialContextSetupResponse,Reset,Error);

%Stats = () ;



# Dissect the wireshark files
foreach $hr ('00','01','02','03','04','05','06','07','08','09',10,11,12,13,14,15,16,17,18,19,20,21,22,23) {
	foreach $min ('00',15,30,45) { 
		$out_file = "/tmp/$hr" . '_' . $min . "_$enb_ip" . '.txt';
		$cmd= 'tshark -R "s1ap && ip.addr==' . $enb_ip . '"  -r ' . $today . '/' . $hr . $min . '*/*Signalling*.pcap > ' . $out_file   ;
		print "Idrees cmd=$cmd=\n";
		$res =`$cmd`;
	}
}



# Analyze the files and create the csv file

foreach $hr ('00','01','02','03','04','05','06','07','08','09',10,11,12,13,14,15,16,17,18,19,20,21,22,23) {
	print "\n\n\n#######   CST hr=$hr   Date=$ARGV[0]     \n" ;

	foreach $min ('00',15,30,45) { print ",$min"; }
	print "\n";
	foreach $tag (@Stats_Tags) { 
		print "$tag"; 

		foreach $min ('00',15,30,45) {
			$out_file = "/tmp/$hr" . '_' . $min . "_$enb_ip" . '.txt';
			$Stats_tag=0;		
		
			open (INFILE , $out_file) || die "Error opening =$out_file= \n";
			while( $line = <INFILE> ){
				if ($line =~ /$tag/)            { $Stats_tag++; }
			}
			close (INFILE);
			print ",$Stats_tag";
		}
		print "\n";
	}
}


