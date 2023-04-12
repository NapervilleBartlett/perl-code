#!/bin/perl



# use strict;

use Time::localtime;
use Time::Local    ;
use Math::BigFloat;
use List::Util qw(first max maxstr min minstr reduce shuffle sum);

use Statistics::Basic qw(:all);





#  Every hr collect logs from UEs and analyze them


# Find date , time
my $t = localtime;
my ($year, $mon, $dayx, $hour) = ($t->year + 1900, $t->mon + 1, $t->mday,  $t->hour );
$month = sprintf ("%-2.2d",$mon);
$day   = sprintf ("%-2.2d",$dayx);
$hr    = sprintf ("%-2.2d",$hour);



%Total_Sector_bytes_DL = ();
%Total_Sector_bytes_UL = ();
%Total_Sector_ping_Pkts_Dropped = ();
%Total_Sector_Average_Delay	= ();

%Total_Sector_LostPings = ();
%Total_Sector_delay_ping  = ();
%Total_Sector_UL_tput_per_transfer  = ();
%Total_Sector_DL_tput_per_transfer  = ();


%UE_24Hr_FTP_Stat	= (); 
%UE_24Hr_Delay_Stat	= () ; 
%UE_24Hr_LostPkts_Stat	= (); 

%UE_24Hr_Delay_Stat_Reply_1 = () ; 
%UE_24Hr_Delay_Stat_Reply_3 = () ; 




$Num_UE = 0 ;

%UEs_in_Enb = () ;


%All_hr_pings_lost = ();
%All_hr_ping_delay = ();
%All_hr_ping_delay_Reply_1 = ();   # Used for Conntrol Plane Latency
%All_hr_ping_delay_Reply_3 = ();   # Used for Bearer   Plane Latency

%Total_Sector_delay_ping_Reply_1  = ();
%Total_Sector_delay_ping_Reply_3  = ();





###################  Get files from MuTT PCs

&Get_Files_From_MUTT_PCs();





###################  Parse the MUTT Files and store the data 

&Parse_Files_From_MUTT_PCs_and_Stored_Data();







###################  Create a consolidated file per UE 


# Look at the config file

my $res = `grep PSLTE_MUTT_ bin/MUTT_CONFIG.txt`;

foreach my $line (split('\n',$res) ) {

	my ($UE_Namex, $UE_Typex, $UE_PCx, $UE_IMSIx, $eNB_Sectx, $CPG_Serverx) = split(/\s+/,$line);

	&Create_ConsolidateFile_For_UE($UE_Namex, $eNB_Sectx) ;
}







###################  Create a eNB-Sector level consolidated file

&Create_ConsolidateFile_For_enb_sector();











###################  Create KPIs 

$DateTimeStr = &Create_DateTimeStr(); 
$Last_TimeStr = &Create_Final_DateTineStr();
&Create_KPI_For_Day();
























sub Get_Files_From_MUTT_PCs
{

	# Look at the config file
	open(MYINPUTFILE, "<bin/MUTT_CONFIG.txt") || die "unable to open MUTT_CONFIG.txt\n";
		
	while(<MYINPUTFILE>) {

		my($line) = $_;

		if ($line =~ /PSLTE_MUTT_/) {


			my ($UE_Name, $UE_Type, $UE_PC, $UE_IMSI, $eNB_Sect, $CPG_Server) = split(/\s+/,$line);


	
			# mkdir 
			$res = `if [ -e Logs/${year}_${month}_${day} ]; then sleep 1 ; else mkdir Logs/${year}_${month}_${day}; chmod -R 777 Logs/${year}_${month}_${day}; fi`;
			$res = `if [ -e Logs/${year}_${month}_${day}/${UE_Name} ]; then sleep 1 ; else mkdir Logs/${year}_${month}_${day}/${UE_Name} ; fi `;
	
			# FTP the log file

			$Logs_dir = "Logs/${year}_${month}_${day}/${UE_Name}" ;

			# expect Get_Logs_From_UE.exp   10.6.156.107           MUTT_Software\\MQ\\Logs\\2012_07_26\\* /tmp/
			$cmd = "expect bin/Get_Logs_From_UE.exp $UE_PC ". " MUTT_Software/MQ/Logs/${year}_${month}_${day}   $Logs_dir";
                
			# print "Idrees about toexecute cmd=$cmd=\n";           		
			$res=system("$cmd");

		}
	}

	close(MYINPUTFILE) ;
}










# Store the ftp and ping data on a per UE per hr basis


sub Parse_Files_From_MUTT_PCs_and_Stored_Data
{




	# Look at the config file
	open(MYINPUTFILE, "<bin/MUTT_CONFIG.txt") || die "unable to open MUTT_CONFIG.txt\n";

	print "Parse_Files_From_MUTT_PCs_and_Stored_Data  Starts \n";
		
	while(<MYINPUTFILE>) {

		my($line) = $_;


		if ($line =~ /PSLTE_MUTT_/) {

			my ($UE_Name, $UE_Type, $UE_PC, $UE_IMSI, $eNB_Sect, $CPG_Server) = split(/\s+/,$line);



			print "Parse_Files_From_MUTT_PCs_and_Stored_Data:: UE=$UE_Name= eNB_Sect=$eNB_Sect=\n";

                        # Save the eNB-UE mapping
                        push (@{$UEs_in_Enb{$eNB_Sect}},$UE_Name);




			my $Logs_dir = "Logs/${year}_${month}_${day}/${UE_Name}" ;


			foreach my $hrx ('00', '01', '02', '03', '04', '05', '06', '07', '08', '09', 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23) {


				$cmd = "grep -i -s \"bytes received\" ${Logs_dir}/ftp_result_${hrx}.txt" ;

				$All_hr_gets{$UE_Name}{$hrx} = `$cmd`; 



				$cmd = "grep -i -s \"bytes sent\" ${Logs_dir}/ftp_result_${hrx}.txt" ;

				$All_hr_puts{$UE_Name}{$hrx} = `$cmd`; 


				$cmd = "grep  -s \"Lost\" ${Logs_dir}/ftp_result_${hrx}.txt" ;

				$All_hr_pings_lost{$UE_Name}{$hrx} = `$cmd`; 


				$cmd = "grep  -s \"Average\" ${Logs_dir}/ftp_result_${hrx}.txt" ;

				$All_hr_ping_delay{$UE_Name}{$hrx} = `$cmd`; 

				$cmd =  'grep  "Reply\[1\]"' . "  ${Logs_dir}/ftp_result_${hrx}.txt" ;
				$All_hr_ping_delay_Reply_1{$UE_Name}{$hrx} = `$cmd`;

				$cmd =  'grep  "Reply\[3\]"' . "  ${Logs_dir}/ftp_result_${hrx}.txt" ;
				$All_hr_ping_delay_Reply_3{$UE_Name}{$hrx} = `$cmd`;



				$cmd = "grep  -s \"Address\" ${Logs_dir}/ftp_result_${hrx}.txt|egrep \"172.|192.|25.\"" ;
				$res = `$cmd`;





				# print "Idrees cmd=$cmd= res=$res=\n\n"; 

				$UE_IP="0.0.0.0";
				if    ($res =~ /(172.\d+.\d+.\d+)/ ) { $UE_IP=$1  ; }
				elsif ($res =~ /(192.\d+.\d+.\d+)/ ) { $UE_IP=$1  ; }
				elsif ($res =~ /(25.\d+.\d+.\d+)/ )  { $UE_IP=$1  ; }

				$All_hr_IP{$UE_Name}{$hrx} = $UE_IP;
				# print "Idrees UE_Name=$UE_Name= hrx=$hrx= UE_IP=$UE_IP=\n\n"; 

			}

		}
	}

	close(MYINPUTFILE);

	print "Parse_Files_From_MUTT_PCs_and_Stored_Data  Done \n\n\n";



}























# Returns pings lost as a string

sub Find_Total_UE_pings_Lost 
{

	local ($ue_name, $hr, $eNB_Sect) = @_ ;



	##############################     Find Lost pings 


	my @All_Lost_Pings = ();



	# Packets: Sent = 4, Received = 4, Lost = 0 (0% loss) 

	# NOv 08, 2013;  replace with % pkt lost
#	foreach my $lost_ping (split(/\n+/,$All_hr_pings_lost{$ue_name}{$hr})) {
#		$lost_ping =~ s/.*Lost = //g;
#		$lost_ping =~ s/ \(.*//g;
#		push (@All_Lost_Pings,$lost_ping) ;
#		push (@{$Total_Sector_LostPings{$eNB_Sect}{$hr}}, $lost_ping);
##	}
#	my $lost_ping_mean = sum 0, @All_Lost_Pings ;


	foreach my $lost_ping (split(/\n+/,$All_hr_pings_lost{$ue_name}{$hr})) {

		$lost_ping =~ s/.*\(//g;
		$lost_ping =~ s/%.*//;

		push (@All_Lost_Pings,$lost_ping) ;


		push (@{$Total_Sector_LostPings{$eNB_Sect}{$hr}}, $lost_ping);
	}

	# Round up 
	my $lost_ping_mean = int ( 0.5 + Old_mean (@All_Lost_Pings)) ;


	return $lost_ping_mean ;



}











# Returns pings average delay as a string

sub Find_UE_ping_Delay 
{

	local ($ue_name, $hr, $eNB_Sect) = @_ ;




	##############################     Find Average delay pings 


	my @All_Ping_Delays = ();


	# Minimum = 45ms, Maximum = 50ms, Average = 48ms      

	my $delay_ping = "" ;


	foreach $delay_ping (split(/\n+/,$All_hr_ping_delay{$ue_name}{$hr})) {


		$delay_ping =~ s/.*Average = //g;

		$delay_ping =~ s/ms//g;

		push (@All_Ping_Delays,$delay_ping) ;


		push (@{$Total_Sector_delay_ping{$eNB_Sect}{$hr}}, $delay_ping);

	}

	my $ping_av_delay = &Old_mean(@All_Ping_Delays) ;


	return $ping_av_delay ;



}












# Returns pings average delay of Reply[1] as a string

sub Find_UE_ping_Delay_Reply_1 
{

	local ($ue_name, $hr, $eNB_Sect) = @_ ;




	##############################     Find Average delay pings 


	my @All_Ping_Delays_Reply_1 = ();


	# 20:14:47.000 : Reply[1] from 26.186.104.134: bytes=32 time=27.7 ms TTL=57


	my $delay_ping = "" ;


	foreach $delay_ping (split(/\n+/,$All_hr_ping_delay_Reply_1{$ue_name}{$hr})) {


		$delay_ping =~ s/.*time=//g;

		$delay_ping =~ s/ms.*//g;

		push (@All_Ping_Delays_Reply_1,$delay_ping) ;


		push (@{$Total_Sector_delay_ping_Reply_1{$eNB_Sect}{$hr}}, $delay_ping);

	}

	my $ping_av_delay = &Old_mean(@All_Ping_Delays_Reply_1) ;


	return $ping_av_delay ;



}








# Returns pings average delay of Reply[3] as a string

sub Find_UE_ping_Delay_Reply_3 
{

	local ($ue_name, $hr, $eNB_Sect) = @_ ;




	##############################     Find Average delay pings 


	my @All_Ping_Delays_Reply_3 = ();


	# 20:14:47.000 : Reply[1] from 26.186.104.134: bytes=32 time=27.7 ms TTL=57


	my $delay_ping = "" ;


	foreach $delay_ping (split(/\n+/,$All_hr_ping_delay_Reply_3{$ue_name}{$hr})) {


		$delay_ping =~ s/.*time=//g;

		$delay_ping =~ s/ms.*//g;

		push (@All_Ping_Delays_Reply_3,$delay_ping) ;


		push (@{$Total_Sector_delay_ping_Reply_3{$eNB_Sect}{$hr}}, $delay_ping);

	}

	my $ping_av_delay = &Old_mean(@All_Ping_Delays_Reply_3) ;


	return $ping_av_delay ;



}


















sub RemoveElementFromArray
{

	local($element_omitted,  @In_Array) = @_ ;


	my @Out_Array = grep { $_ != $element_omitted } @In_Array;


	return @Out_Array ;


}
















#  Returns the UL and DL thput for a UE 
sub Find_UE_Thruput_In_an_Hr
{



	local ($ue_name,$hry, $eNB_Sec) = @_ ;


	##############################     Find UL thput 


	my $Total_Bytes_UL = 0; 

	my $Total_Bytes_DL = 0;

	my $Total_Secs     = 0;

	# ftp: 545000000 bytes received in 505.80Seconds 1077.51Kbytes/sec.

	foreach my $get_put (split(/\n+/,$All_hr_puts{$ue_name}{$hry})) {

		$get_put =~ /^.* (\d+) .* (.*Seconds).* (.*Kbytes\/sec).*/;

		$Total_Bytes_UL += $1;   $Total_Secs += $2; $Kbytes_Per_Sec=$3 ;

		# Kbytes/sec 
		$Kbytes_Per_Sec =~ s/Kbytes\/sec//g; 

		push (@{$Total_Sector_UL_tput_per_transfer{$eNB_Sec}{$hry}}, $Kbytes_Per_Sec);


	}

	if ($Total_Secs == 0) {$Total_Secs=1; }

	my $put_thput = int (8*$Total_Bytes_UL/(1024*$Total_Secs));





	##############################     Find DL thput


	$Total_Secs=0;

	foreach $get_put (split(/\n+/,$All_hr_gets{$ue_name}{$hry})) {

		$get_put =~ /^.* (\d+) .* (.*Seconds).* (.*Kbytes\/sec).*/;

		$Total_Bytes_DL += $1;   $Total_Secs += $2; $Kbytes_Per_Sec=$3 ;

                # Kbytes/sec
                $Kbytes_Per_Sec =~ s/Kbytes\/sec//g;

		push (@{$Total_Sector_DL_tput_per_transfer{$eNB_Sec}{$hry}}, $Kbytes_Per_Sec);
	}

	if ($Total_Secs == 0) {$Total_Secs=1; }

	$get_thput = int(8*$Total_Bytes_DL/(1024*$Total_Secs));





	############################### Increment the num of bytes sent or received by the sector

	$Total_Sector_bytes_DL{$eNB_Sec}{$hry} += $Total_Bytes_DL;

	$Total_Sector_bytes_UL{$eNB_Sec}{$hry} += $Total_Bytes_UL;


	# print "-- Idrees eNB_Sec=$eNB_Sec= hry=$hry= Total_Bytes_DL=$Total_Bytes_DL= Total_Bytes_UL=$Total_Bytes_UL= ; Total_Sector_bytes_DL=$Total_Sector_bytes_DL{$eNB_Sec}{$hry}= \n";



	$ret_str = "$get_thput/$put_thput" ;


	if ($get_thput < 1 ) { $ret_str = $All_hr_IP{$ue_name}{$hry} ; }



	return $ret_str ;




}























sub Create_ConsolidateFile_For_UE
{




	local ($ue_nme,$eNB_Sect) = @_ ;

	print "Create_ConsolidateFile_For_UE:: Starting  UE=$ue_nme=   sector=$eNB_Sect\n"; 


	my $Header_line= sprintf ("%-20.20s ", "Hrs "     );

	my $Final_Line = sprintf ("%-20.20s ", "DL/UL FTP Thput Kbps");  

	my $Pings_Lost_Line = sprintf ("%-20.20s ", "Average Pkts Lost %"); 

	my $Pings_Delay_Line 	      = sprintf ("%-20.20s ", "Avg Ping Delay  msec"); 
	my $Pings_Delay_Line_Reply_1  = sprintf ("%-20.20s ", "Control Latency msec"); 
	my $Pings_Delay_Line_Reply_3  = sprintf ("%-20.20s ", "Bearer  Latency msec"); 

	my $All_Gets_Puts_Delay_Lost_For_Day = "";

	my $Logs_dir = "Logs/${year}_${month}_${day}/${ue_nme}" ;

	

	foreach my $hrx ('00', '01', '02', '03', '04', '05', '06', '07', '08', '09', 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23) {

		my $get_put_thput = &Find_UE_Thruput_In_an_Hr($ue_nme, $hrx, $eNB_Sect) ;


		my $lost_pkts = &Find_Total_UE_pings_Lost($ue_nme, $hrx, $eNB_Sect);

		my $ping_delay = int ( &Find_UE_ping_Delay($ue_nme, $hrx, $eNB_Sect) ) ;

		my $ping_delay_Reply_1 = int ( &Find_UE_ping_Delay_Reply_1($ue_nme, $hrx, $eNB_Sect) ) ;
		my $ping_delay_Reply_3 = int ( &Find_UE_ping_Delay_Reply_3($ue_nme, $hrx, $eNB_Sect) ) ;


		$tmp = sprintf ("%-10.10s ", $hrx);                    	$Header_line .= $tmp ;

		$tmp = sprintf ("%-10.10s ", "$get_put_thput");        	$Final_Line .= $tmp;

		$tmp = sprintf ("%-10.10s ", "$lost_pkts");             $Pings_Lost_Line .= $tmp;

		$tmp = sprintf ("%-10.10s ", "$ping_delay");          	$Pings_Delay_Line .= $tmp;

		$tmp = sprintf ("%-10.10s ", "$ping_delay_Reply_1");   	$Pings_Delay_Line_Reply_1 .= $tmp;

		$tmp = sprintf ("%-10.10s ", "$ping_delay_Reply_3");   	$Pings_Delay_Line_Reply_3  .= $tmp;


		# Find all gets, puts in the hr and save them


		$cmd = "egrep -i -s \"bytes sent|bytes received\" ${Logs_dir}/ftp_result_${hrx}.txt" ;

		$res = `$cmd`;

		$All_Gets_Puts_Delay_Lost_For_Day .= " ---------------   HR=$hrx= --------------\n$res\n\n";



		$All_Gets_Puts_Delay_Lost_For_Day .= "$All_hr_pings_lost{$ue_nme}{$hrx} \n\n" ;

		$All_Gets_Puts_Delay_Lost_For_Day .= "$All_hr_ping_delay{$ue_nme}{$hrx} \n\n" ;

		$All_Gets_Puts_Delay_Lost_For_Day .= "$All_hr_ping_delay_Reply_1{$ue_nme}{$hrx} \n\n" ;
		$All_Gets_Puts_Delay_Lost_For_Day .= "$All_hr_ping_delay_Reply_3{$ue_nme}{$hrx} \n\n" ;



	}



	# Save every UEs final consolidated line

	$UE_24Hr_FTP_Stat{$ue_nme} = $Final_Line ;

	$UE_24Hr_Delay_Stat{$ue_nme} = $Pings_Delay_Line ;

	$UE_24Hr_LostPkts_Stat{$ue_nme} = $Pings_Lost_Line ;

	$UE_24Hr_Delay_Stat_Reply_1{$ue_nme} = $Pings_Delay_Line_Reply_1 ;
	$UE_24Hr_Delay_Stat_Reply_3{$ue_nme} = $Pings_Delay_Line_Reply_3 ;





	my $ConsolidatedFile = "${Logs_dir}/ConsolidatedFile.txt";

	open(MYOUTFILE, ">$ConsolidatedFile") || die "Create_ConsolidateFile_For_UE::Unable to open ConsolidatedFile.txt  in $Logs_dir\n";


	print MYOUTFILE "   =================================     MUTT stats in kbps for: ${year}_${month}_${day}    UE=$ue_nme";
	print MYOUTFILE "   =================================  \n\n";

	print MYOUTFILE "$Header_line\n\n";
	print MYOUTFILE "$Final_Line\n\n";

	print MYOUTFILE "$Pings_Lost_Line \n\n";

	print MYOUTFILE "$Pings_Delay_Line \n";
	print MYOUTFILE "$Pings_Delay_Line_Reply_1\n";
	print MYOUTFILE "$Pings_Delay_Line_Reply_3\n\n\n\n\n";
	print MYOUTFILE "-----------------------              Details               -------------------------------------------------------------- \n\n";
	print MYOUTFILE "$All_Gets_Puts_Delay_Lost_For_Day\n\n";



	close(MYOUTFILE) ;


	print "Create_ConsolidateFile_For_UE:: Exiting \n";

}





















# This will create a per enb-sect level consolidate statement of thput 

sub Create_ConsolidateFile_For_enb_sector
{


	print "Create_ConsolidateFile_For_enb_sector:: Starting \n";

	# Now print a enb_sector level stats
        # Create 1 hearer line and 1 line for each eNB_Sect

        my $eNB_Level_ConsolidatedFile = "Logs/${year}_${month}_${day}/MUTT_Stats.txt";

        open(MYOUTFILE1, ">$eNB_Level_ConsolidatedFile ") || die "Unable to open ConsolidatedFile.txt  in $eNB_Level_ConsolidatedFile\n";

        my $Thput_Title    = "Thruput DL/UL (kbps):: \n";  

        my $PktLos_Title   = "Average Pkts Lost % \n";

        my $Delay_Title    	   = "Av ping delay   msec:: \n";
        my $Delay_Title_Reply_1    = "Control Latency msec:: \n";
        my $Delay_Title_Reply_3    = "Bearer  Latency msec:: \n";




	$Thput_line  = "" ;
	$PktLos_line = "";
	$Delay_line  = "" ;
	$Delay_line_Reply_1  = "" ;
	$Delay_line_Reply_3  = "" ;

        foreach my $eNB_sect (sort keys %Total_Sector_bytes_DL) {

                        # Put the eNB-sect name for each line
                        $tmp        = sprintf ("%-20.20s ", $eNB_sect);                          
	
			$Thput_line  .= $tmp ;

			$PktLos_line .= $tmp ;

			$Delay_line  .= $tmp ;
			$Delay_line_Reply_1  .= $tmp ;
			$Delay_line_Reply_3  .= $tmp ;

			$Hour_Line = sprintf ("%-20.20s ", "Hour");
			
			foreach my $hrx ('00', '01', '02', '03', '04', '05', '06', '07', '08', '09', 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23) {


				$tmp = sprintf ("%-10.10s ", $hrx);	$Hour_Line .= $tmp ;


                                # Create UL/DL thput 

				# print "-- Create_ConsolidateFile_For_enb_sector:: eNB_sect=$eNB_sect= hrx=$hrx= Idrees Total_Sector_bytes_DL=$Total_Sector_bytes_DL{$eNB_sect}{$hrx}\n";

                                $Sector_Thput_DL = int(8*$Total_Sector_bytes_DL{$eNB_sect}{$hrx} / (1024*3600)) ;

                                $Sector_Thput_UL = int(8*$Total_Sector_bytes_UL{$eNB_sect}{$hrx} / (1024*3600)) ;

				$tmp = sprintf ("%-10.10s ", "$Sector_Thput_DL/$Sector_Thput_UL");      		$Thput_line .= $tmp ;
				# print "-- Create_ConsolidateFile_For_enb_sector:: Sector_Thput_DL=$Sector_Thput_DL= tmp=$tmp=\n";

				$tmp = sprintf ("%-10.2d ", &Old_mean ( @{$Total_Sector_LostPings {$eNB_sect}{$hrx}} )) ;  	$PktLos_line .= $tmp ;
				$tmp = sprintf ("%-10.2d ", &Old_mean ( @{$Total_Sector_delay_ping{$eNB_sect}{$hrx}} )) ; 	$Delay_line .= $tmp ;
				$tmp = sprintf ("%-10.2d ", &Old_mean ( @{$Total_Sector_delay_ping_Reply_1{$eNB_sect}{$hrx}} )) ; 	$Delay_line_Reply_1 .= $tmp ;
				$tmp = sprintf ("%-10.2d ", &Old_mean ( @{$Total_Sector_delay_ping_Reply_3{$eNB_sect}{$hrx}} )) ; 	$Delay_line_Reply_3 .= $tmp ;



                        }

                        $Thput_line  .= "\n";
			$PktLos_line .= "\n";
			$Delay_line .= "\n";
			$Delay_line_Reply_1 .= "\n";
			$Delay_line_Reply_3 .= "\n";




        }

	print MYOUTFILE1 "..........................   Cumulative stats for ${year}_${month}_${day}. MUTT's contribution to eNB thput / delay ..........................   \n\n"; 
	print MYOUTFILE1 "$Hour_Line\n\n"; 
	print MYOUTFILE1 "$Thput_Title" ;
        print MYOUTFILE1 "$Thput_line\n\n\n";


	print MYOUTFILE1 $PktLos_Title ;
        print MYOUTFILE1 "$PktLos_line \n\n\n";

	print MYOUTFILE1 $Delay_Title ;
        print MYOUTFILE1 "$Delay_line \n\n\n";

	print MYOUTFILE1 $Delay_Title_Reply_1 ;
        print MYOUTFILE1 "$Delay_line_Reply_1 \n\n\n";

	print MYOUTFILE1 $Delay_Title_Reply_3 ;
        print MYOUTFILE1 "$Delay_line_Reply_3 \n\n\n";





	#################  Now print details of every UE

	my $All_UE_FTP_Lines = "------------------------------------------------------        Details. UE FTP DL\/UL kbps thput per hr";
	$All_UE_FTP_Lines   .= "------------------------------------------------------ \n";


	$All_UE_Delay_Lines   = "\n\n......................................................  Average ping Pkt Delay        ...............................\n";

	$All_UE_PktLoss_Lines = "\n\n......................................................  Average Ping Pkt loss % per UE...............................\n";

	$All_UE_Delay_Lines_Reply_1   = "\n\n......................................................  Average ping Pkt Delay. Reply 1;  Control Latency  ..........\n";
	$All_UE_Delay_Lines_Reply_3   = "\n\n......................................................  Average ping Pkt Delay. Reply 3;  Bearer  Latency  ..........\n";




		
	foreach $eNB_sect (sort keys %UEs_in_Enb) {

		foreach my $ue (@{$UEs_in_Enb{$eNB_sect}}) {

			$tmp1        = sprintf ("%-20.20s ", $ue);

			$tmp = $UE_24Hr_FTP_Stat{$ue} ; 		$tmp =~ s/DL\/UL FTP Thput Kbps/$tmp1/; 	$All_UE_FTP_Lines     .= "$tmp\n";
			$tmp = $UE_24Hr_Delay_Stat{$ue}; 		$tmp =~ s/Avg Ping Delay  msec/$tmp1/; 	$All_UE_Delay_Lines   .= "$tmp\n";  
			$tmp = $UE_24Hr_LostPkts_Stat{$ue};		$tmp =~ s/Average Pkts Lost %/$tmp1/; 	$All_UE_PktLoss_Lines .=  "$tmp\n"; 
			$tmp = $UE_24Hr_Delay_Stat_Reply_1{$ue}; 	$tmp =~ s/Control Latency msec/$tmp1/; 	$All_UE_Delay_Lines_Reply_1   .= "$tmp\n";  
			$tmp = $UE_24Hr_Delay_Stat_Reply_3{$ue}; 	$tmp =~ s/Bearer  Latency msec/$tmp1/; 	$All_UE_Delay_Lines_Reply_3   .= "$tmp\n";  

		}
	}


	print MYOUTFILE1 "$All_UE_FTP_Lines\n\n";
	print MYOUTFILE1 "$All_UE_Delay_Lines \n\n";
	print MYOUTFILE1 "$All_UE_PktLoss_Lines \n\n";
	print MYOUTFILE1 "$All_UE_Delay_Lines_Reply_1 \n\n";
	print MYOUTFILE1 "$All_UE_Delay_Lines_Reply_3 \n\n";




	close (MYOUTFILE1) ;



        print "Create_ConsolidateFile_For_enb_sector:: Exit \n";


}























sub Old_mean {
         my(@data) = @_;

	if (@data) {}
	else	   {return 0; } 

         my $sum;
         foreach(@data) {
             $sum += $_;
         }
         return($sum / @data);
     }



sub Old_median {
         my(@data)=sort { $a <=> $b} @_;

        if (@data) {}
        else       {return 0; }


         if (scalar(@data) % 2) {
             return (int (($data[@data / 2])));
         } else {
             my($upper, $lower);
             $lower=$data[@data / 2];
             $upper=$data[@data / 2 - 1];
             return(int(mean($lower, $upper)));
         }
     }


sub Old_std_dev {
         my(@data)=@_;
         my($sq_dev_sum, $avg)=(0,0);
   
         $avg = mean(@data);
         foreach my $elem (@data) {
             $sq_dev_sum += ($avg - $elem) **2;
         }
         return(sqrt($sq_dev_sum / ( @data - 1 )));
     }













































# Return the sum if a seq of #s.  each # seperated by ,
# Return_Sum (10,20,30)
sub Return_Sum
{

	($All_Num) = @_ ;
	$xret=0;


	foreach $xi (split(',',$All_Num)) {
		$xret += $xi ;

	}


	return $xret ;

}












sub  Create_Final_DateTineStr
{

        $xtime = timelocal( 01, 01, 01, 01, 01, 2015-1900 );

        $retStr = $xtime . "000";

}







# Convert the date-time to seconds since the epoch
sub Create_DateTimeStr
{



	$xsec   = 01;
	$xmin   = 01;
	$xhour  = 01;
	$xmday  = $day ; 
	$xmon   = $month - 1;
	$xyear  = $year - 1900;
 
    	$xtime = timelocal( $xsec, $xmin, $xhour, $xmday, $xmon, $xyear );


	$retStr = $xtime . "000";

}



sub Create_KPI_For_Day
{




	# of FTPs done
	$cmd = "grep sent Logs/${year}_${month}_${day}/*/Con*" ;
	$res_ul_ftp=`$cmd`;

	$cmd = "grep received Logs/${year}_${month}_${day}/*/Con*" ;
	$res_dl_ftp=`$cmd`;

	$cmd = "grep Lost Logs/${year}_${month}_${day}/*/Con*" ;
	$res_pkt_loss =`$cmd`;

	$cmd = "grep Maximum Logs/${year}_${month}_${day}/*/Con*" ;
	$res_Ping_Delay =`$cmd`;


	$cmd = 'grep "Reply\[1\]"  ' . "Logs/${year}_${month}_${day}/*/Con*" ;
	$res_control_latency =`$cmd`;

	$cmd = 'grep "Reply\[3\]"  ' . "Logs/${year}_${month}_${day}/*/Con*" ;
	$res_bearer_latency =`$cmd`;


	$Global_Header_result_str  =  "------------           Values during the day ----------------------- \n\n"; 
	$Global_median_result_str  =  "------------   Median  Values during the day ----------------------- \n\n"; 
	$Global_mean_result_str    =  "------------   Mean    Values during the day ----------------------- \n\n"; 
	$Global_min_result_str     =  "------------   Minimum Values during the day ----------------------- \n\n"; 
	$Global_max_result_str     =  "------------   Maximum Values during the day ----------------------- \n\n"; 




	# Logs/2014_01_29/PSLTE_MUTT_016/ConsolidatedFile.txt:ftp: 109000 bytes sent in 0.28Seconds 387.90Kbytes/sec.

	@All_ul_ftp = split ('\n',$res_ul_ftp);
	@All_dl_ftp = split ('\n',$res_dl_ftp);
	$Num_Of_ul_ftp = $#All_ul_ftp;
	$Num_Of_dl_ftp = $#All_dl_ftp;


	if ($Num_Of_ul_ftp) { &Create_Entry_in_Json_File("Num_of_FTP_UL",$Num_Of_ul_ftp); } 
	if ($Num_Of_dl_ftp) { &Create_Entry_in_Json_File("Num_of_FTP_DL",$Num_Of_dl_ftp); } 

	$Global_Header_result_str  .= "Num of UL FTPs      $Num_Of_ul_ftp \n";
	$Global_Header_result_str  .= "Num of DL FTPs      $Num_Of_dl_ftp \n";





	# UL Thput
	
	@valid_ftp_Kbytes = () ;
	foreach $line (@All_ul_ftp) { 
	
		if ($line =~ /0\.00Seconds/) { }  
		else  { 
			$line =~ s/Kbyt.*//g;   
			$line =~ s/.*Seconds//g ;
			$line =~ s/\s+//g ;

			# Kbps 
			if ($line) { push (@valid_ftp_Kbytes,8*$line) ; }
		}
	}

	&Create_PM_Entry("Thput_UL            ","kbps",@valid_ftp_Kbytes);





	# DL Thput

        @valid_ftp_Kbytes = () ;
        foreach $line (@All_dl_ftp) {


                if ($line =~ /0\.00Seconds/) { }
                else  {
                        # print "Idrees;; $line\n";
                        $line =~ s/Kbyt.*//g;
                        $line =~ s/.*Seconds//g ;
                        $line =~ s/\s+//g ;

                        if ($line) { push (@valid_ftp_Kbytes,$line) ; }
                }
        }

	&Create_PM_Entry("Thput_DL            ","kbps",@valid_ftp_Kbytes);




	# Control plane latency
	# Logs/2014_01_29/PSLTE_MUTT_001/ftp_result_16.txt:16:46:28.768 : Reply[1] from 26.186.104.134: bytes=32 time=31.6 ms TTL=58

	@Control_Latency = split ('\n',$res_control_latency);
        @valid_lines = () ;
        foreach $line (@Control_Latency) {


                        # print "Idrees;; $line\n";
                        $line =~ s/.*time=//g;
                        $line =~ s/ms T.*//g;
			$line =~ s/\s+//g ;


                        if ($line) { push (@valid_lines,$line) ; }
        }

	&Create_PM_Entry("Control-Latency     ","msec",@valid_lines);









        # Bearer plane latency
        # Logs/2014_01_29/PSLTE_MUTT_001/ftp_result_16.txt:16:46:28.768 : Reply[1] from 26.186.104.134: bytes=32 time=31.6 ms TTL=58

        @Bearer_Latency = split ('\n',$res_bearer_latency);
        @valid_lines = () ;
        foreach $line (@Bearer_Latency) {

                        # print "Idrees;; $line\n";
                        $line =~ s/.*time=//g;
                        $line =~ s/ms T.*//g;
			$line =~ s/\s+//g ;


                        if ($line) { push (@valid_lines,$line) ; }
        }

	&Create_PM_Entry("Bearer-Latency      ","msec",@valid_lines);
















        # Ping Round Trip delay 
        # Logs/2014_01_29/PSLTE_MUTT_002/ConsolidatedFile.txt:    Minimum = 29.8 ms, Maximum = 32.5 ms, Average = 30.7 ms  

        @Ping_RTT = split ('\n',$res_Ping_Delay);
        @valid_lines = () ;
        foreach $line (@Ping_RTT) {

		if ($line =~ /Average = 0\.0 ms/) {} 
		else                    {
                        $line =~ s/.*Average =//g;
                        $line =~ s/m.*//g;
			$line =~ s/\s+//g ;


                        if ($line) { push (@valid_lines,$line) ; }
		}
        }

	&Create_PM_Entry("Ping__RTT           ","msec",@valid_lines);










        # Pkts Loss 
	# Logs/2014_01_29/PSLTE_MUTT_006/ConsolidatedFile.txt:    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss)

        @Ping_Lost_Pkts = split ('\n',$res_pkt_loss);
        @valid_lines = () ;
	$Total_Pkts_Lost = 0 ; $Total_Ping_Pkts_Sent= 1 ; 
        foreach $line (@Ping_Lost_Pkts) {


                if ($line =~ /Received/) {
                        # print "Idrees;; $line\n";
                        $line =~ s/.* Lost = //g;
                        $line =~ s/\(.*//g;

			$Total_Ping_Pkts_Sent += 4 ; 
                        $Total_Pkts_Lost += $line;

			# print "Younsu line=$line=\n";


                        # push (@valid_lines,$line) ;
                }
        }


	$Percentage_Ping_Pkts_Lost_in_Day = int ((100 * $Total_Pkts_Lost) / (4*$Total_Ping_Pkts_Sent)) ; 
        $Global_median_result_str .= "Ping__Pkts_Lost%    $Percentage_Ping_Pkts_Lost_in_Day \n";
        &Create_Entry_in_Json_File("Percentage_Ping_Pkts_Lost_in_Day",$Percentage_Ping_Pkts_Lost_in_Day);











	# Create the KPI File


	$FileName =  "Logs/${year}_${month}_${day}/All_Devices_KPI";

	open(DATAw, ">$FileName") or die "Create_KPI_For_Day:: Couldn't open file $FileName, $!";


	print DATAw  "$Global_Header_result_str \n\n\n"; 
	print DATAw  "$Global_median_result_str   \n\n\n"; 
	print DATAw  "$Global_mean_result_str\n\n\n"; 
	print DATAw  "$Global_min_result_str\n\n\n"; 
	print DATAw  "$Global_max_result_str\n\n\n"; 

	close(DATAw) ;

}










sub Old_Create_Entry_in_Json_File
{

	local ($PmName_xx, $val_xx) = @_ ;

	# ("Logs/Min_BearerLatency.json",    $min_v);

	$PmName_xx    =~ s/\s+//g ;

	$res = `mkdir -p Logs/JsonFiles; chmod 777 Logs/JsonFiles ` ;

	$JsonFileName = "Logs/JsonFiles/${PmName_xx}.json" ;


	# Create File if it does not exist
 	if (-e $JsonFileName) { } 
	else {

		open(DATAx, ">$JsonFileName") or die "Create_Entry_in_Json_File:: Couldn't open file $JsonFileName, $!";

		print DATAx "[\n";
		print DATAx "]";

		close(DATAx) ;

	}

	$res=`chmod 777 Logs/* $JsonFileName`;








        $chart_str = "[$DateTimeStr,  $val_xx]";
        $cmdx= "sed 's/]/],/g' $JsonFileName | sed 's/,,/,/g' |  sed '\$ c " . $chart_str . "' | sed '\$ a ]'  > Logs/junk";
        $res=`$cmdx;  cp Logs/junk $JsonFileName;  rm Logs/junk`;




}





sub Create_PM_Entry
{


	local ($PmName, $PmUnits, @All_PM_Values) = @_ ;


	if (@All_PM_Values) { 

       		$median_vx = int(median(@All_PM_Values)) ;
        	$mean_vx   = int(mean(@All_PM_Values)) ;
        	$max_vx    = int(max(@All_PM_Values)) ;
        	$min_vx    = int(min(@All_PM_Values));

        	$Global_median_result_str .= "$PmName $median_vx $PmUnits \n";
        	$Global_mean_result_str   .= "$PmName $mean_vx   $PmUnits \n";
        	$Global_min_result_str    .= "$PmName $min_vx    $PmUnits \n";
        	$Global_max_result_str    .= "$PmName $max_vx    $PmUnits \n";



        	&Create_Entry_in_Json_File("Median_$PmName", $median_vx);
        	&Create_Entry_in_Json_File("Mean_$PmName", $mean_vx);
        	&Create_Entry_in_Json_File("Max_$PmName", $max_vx);
        	&Create_Entry_in_Json_File("Min_$PmName", $min_vx);
	}

	else {
                $Global_median_result_str .= "$PmName -- No DATA available\n";
                $Global_mean_result_str   .= "$PmName -- No DATA available\n";
                $Global_min_result_str    .= "$PmName -- No DATA available\n";
                $Global_max_result_str    .= "$PmName -- No DATA available\n";


	}
     







}






sub Create_Entry_in_Json_File
{

	local ($PmName_xx, $val_xx) = @_ ;

	# ("Logs/Min_BearerLatency.json",    $min_v);

	$PmName_xx    =~ s/\s+//g ;

	$res = `mkdir -p Logs/JsonFiles; chmod 777 Logs/JsonFiles ` ;

	$JsonFileName = "Logs/JsonFiles/${PmName_xx}.json" ;


	%JsonValues = () ;


	# Read Json File contents

	open(DATA_Jr, "<$JsonFileName") ;
	while(<DATA_Jr>){
		$line_j = $_ ;
		chop ($line_j) ;	
		$line_j =~ s/\[|\]|,//g ;

		($time_St, $val) = split(/\s+/,$line_j) ;
		$JsonValues{$time_St} = $val ; 
	}
	close (DATA_Jr) ;


	$JsonValues{$DateTimeStr} = $val_xx ;

	# Write Json File back

	open(DATA_Jw, ">$JsonFileName") ;
	print DATA_Jw "[\n";
	
	foreach $key_j (sort keys %JsonValues) {
		if ($key_j =~ /0/) { print DATA_Jw "[$key_j, $JsonValues{$key_j}],\n"; }
	}
        # print DATA_Jw "[2494772300000,  -1]\n";
	print DATA_Jw "[$Last_TimeStr,  -1]\n";
	print DATA_Jw "]\n";
	close (DATA_Jw) ;




	$res=`chmod 777 $JsonFileName`;




}


