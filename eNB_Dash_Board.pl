#!/bin/perl

# Usage:  eNB_Dash_Board.pl  date        sniffer_PC             eNB_IP  
# Usage:  eNB_Dash_Board.pl  20111031    ltepc061.cig.mot.com   27.132.68.73

# This looks at the ParsePM_AllDay  file and extracts the RRC C1 Stats.
# It creates a directory C1_CallModel_Stats and an index.html file in that directory


$date1     =$ARGV[0];
$Sniffer_PC=$ARGV[1];
$eNB_IP    =$ARGV[2];



$DashBd_File        = "$date1/Dash_Board.html";
$ParsePM_AllDay_csv = "$date1/ParsePM_AllDay_$date1" . '.csv' ; 
$ManagersView_File  = "ParsePM_AllDay_ManagerView_$date1" . '.txt' ; 
$Alarms_File        = "Alarms_$date1" . '.txt' ;
$C1_RRC_Stats_File  = "C1_RRC_Stats_$date1"  . '.txt';

print "DashBd_File=$DashBd_File=\n ParsePM_AllDay_csv=$ParsePM_AllDay_csv=\n";





# Create file index.html 
open (OUT_FILE,">$DashBd_File") || die "Unable to open DashBd_File=$DashBd_File=\n";


$html_line = '<font color="blue">'; printf  OUT_FILE "$html_line\n";
printf  OUT_FILE  "<br><br><h3> Dash Board ;       eNB_IP=$eNB_IP;      Sniffer_PC=$Sniffer_PC   </h3>\n" ;
$html_line = '</font>'; printf  OUT_FILE "$html_line\n";




$html_lines = '
<li><a HREF="' . $ManagersView_File . '">Manager view </A>
<li><a HREF="http://' .  $Sniffer_PC . '/logs/' . $date1 . '/All_Day_Sniffer_C1_CallModel_' . $eNB_IP . '.txt">C1 Model Stats </A>
<li><a HREF="http://' .  $Sniffer_PC . '/logs/' . $date1 . '/All_Day_Sniffer_Summary_'      . $eNB_IP . '.txt">Other    Stats </A>
<li><a HREF="' . $C1_RRC_Stats_File  . '">C1 RRC Stats </A>
<li><a HREF="' . $Alarms_File        . '">Alarms       </A>
<li><a HREF="' . ". "    .                      '">Graphs </A>
' ;

printf OUT_FILE    "$html_lines"  ;


close (OUT_FILE);






&Create_ManagersView() ;
&Create_Alarms();
&Create_C1_RRC_Stats(); 











sub Create_C1_RRC_Stats
{



	$C1_Stats_File_Path = "$date1/$C1_RRC_Stats_File";


	# Create the C1 RRC Stats file
	open (IN_FILE,"<$ParsePM_AllDay_csv");
	open (OUT_FILE,">$C1_Stats_File_Path") || die "Unable to open =$C1_Stats_File_Path=\n";

	while (<IN_FILE>) {

		$line = $_ ;

        	if ($line =~ /CST/) { printf  OUT_FILE  "\n\n\n\n $line \n" ; }



        	$Val=0;
     		if ($line =~ /RRCConnReConfigSucc/) {
                        # RCConnReConfigSucc,10,20.30,40,50,60,70,80,90,100,110,120                        
                        ($Name,$val1,$val2,$val3,$val4,$val5,$val6,$val7,$val8,$val9,$val10,$val11,$val12) = split (/,/,$line);
                        $Val = ($val1 + $val2 + $val3 + $val4 + $val5 + $val6 + $val7 + $val8 + $val9 + $val10 + $val11 + $val12);

			printf  OUT_FILE "%-20.20s %-8.8s %-8.8s\n", $Name, "350000", $Val ;

		}

        	$Val=0;
     		if ($line =~ /HOIntraEnbOutSuccSum/) {
                        # RCConnReConfigSucc,10,20.30,40,50,60,70,80,90,100,110,120                        
                        ($Name,$val1,$val2,$val3,$val4,$val5,$val6,$val7,$val8,$val9,$val10,$val11,$val12) = split (/,/,$line);
                        $Val = ($val1 + $val2 + $val3 + $val4 + $val5 + $val6 + $val7 + $val8 + $val9 + $val10 + $val11 + $val12);

			printf  OUT_FILE "%-20.20s %-8.8s %-8.8s\n", $Name, "10000", $Val ;

		}
	}


	close(IN_FILE);
	close(OUT_FILE);

}






sub Create_ManagersView
{



	open (IN_FILE,"<$ParsePM_AllDay_csv");
	open (OUT_FILE,">$date1/$ManagersView_File") || die "Unable to open ManagerViewFile=$date1/$ManagersView_File=\n";
	
	while (<IN_FILE>) {
	
	        $line = $_ ;

	        if ($line =~ /CST/) { 
			printf  OUT_FILE  "\n\n\n\n$line \n" ; 
			printf OUT_FILE "%-20.20s %-8.8s %-8.8s %-8.8s %-8.8s %-8.8s %-8.8s %-8.8s %-8.8s %-8.8s %-8.8s %-8.8s %-8.8s\n",
					("Mins->",'0-5','5-10','10-15','15-20','20-25','25-30','30-35','35-40','40-45','45-50','50-55','55-00') ;
		}
	        if ($line =~ /RRCConnMean|RRUAvgPhyThroughputDl|RRUAvgPhyThroughputUl/) { 
				# print "Idrees line=$line=\n";
	                        # RCConnReConfigSucc,10,20.30,40,50,60,70,80,90,100,110,120
	                        ($Name,$val1,$val2,$val3,$val4,$val5,$val6,$val7,$val8,$val9,$val10,$val11,$val12) = split (/,/,$line);
				printf OUT_FILE "%-20.20s %-8.8s %-8.8s %-8.8s %-8.8s %-8.8s %-8.8s %-8.8s %-8.8s %-8.8s %-8.8s %-8.8s %-8.8s\n",
					($Name,$val1,$val2,$val3,$val4,$val5,$val6,$val7,$val8,$val9,$val10,$val11,$val12) ;
		}
	}
	close (IN_FILE);
	close (OUT_FILE);

}





sub Create_Alarms
{

	system("./health.sh $date1 > $date1/$Alarms_File"); 

}


