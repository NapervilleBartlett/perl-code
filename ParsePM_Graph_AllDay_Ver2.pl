#!/bin/perl


# Usage:  ParsePM_Graph_AllDay.pl   20101101


# looks into the /tmp/JUNK directtory for files 


use GD::Graph::lines;
use GD::Graph::bars;
use CGI qw(:standard);

use Image::Magick;



$My_TAC = "5103";
%PM = {};
%PM_per_time = {};

%Max_PM = {} ;
@Plotting_data = ([],[]) ; 

$My_Sector = 'eUtranGenericCellIndex' ; 

@Pm_Categories = (MMEpsAttachAttE,MMEpsAttachSuccE, MMEpsServiceReqAttTALvl, MMEpsServiceReqSuccTALvl, MMPagingEpsAtt, MMPagingEpsSucc, MMTauInterSgwAtt, MMTauInterSgwSucc, MMTauIntraSgwAtt, MMTauIntraSgwSucc, MMEpsDetachUeAtt, MMEpsDetachUeSucc , RRCConnEstabAttSum,RRCConnEstabSuccSum,S1SIGConnEstabAtt,S1SIGConnEstabSucc,RRCConnReConfigAtt,RRCConnReConfigSucc,SAEBEstabInitAttNbrSum,SAEBEstabInitSuccNbrSum,SAEBRelAttNbrSum,RRCConnReleaseSum,RRCConnMax,RRCConnMean,RRUAvgPhyThroughputDl,RRUAvgPhyThroughputUl,RRUMaxPhyThroughputDl,RRUMaxPhyThroughputUl);

@Pm_Categories = (MMEpsAttachAttE,MMEpsAttachSuccE, MMEpsServiceReqAttTALvl, MMEpsServiceReqSuccTALvl, MMPagingEpsAtt, MMPagingEpsSucc, MMTauInterSgwAtt, MMTauInterSgwSucc, MMTauIntraSgwAtt, MMTauIntraSgwSucc, MMEpsDetachUeAtt, MMEpsDetachUeSucc,
RRCConnMax 
, RRCConnMean 
, RRCConnEstabAttSum 
, RRCConnEstabSuccSum 
, RRCConnEstabAttMtAccess 
, RRCConnEstabTimeMeanSum 
, RRCConnEstabTimeMaxSum 
, RRCConnReEstabAttSum 
, RRCConnReEstabSuccSum 
, RRCConnReConfigAtt 
, RRCConnReConfigSucc 
, RRCConnReleaseSum 
, RRCConnReleaseNoUserActivity 
, SAEBEstabInitAttNbrSum 
, SAEBEstabInitSuccNbrSum 
, SAEBEstabTimeMaxSum 
, SAEBEstabTimeMeanSum 
, SAEBModQoSAttNbrSum 
, SAEBModQoSSuccNbrSum 
, DRBDRBUeScheduledNumDl 
, DRBDRBUeScheduledNumUl 
, DRBUEActiveDlSum 
, DRBUEActiveUlSum 
, DRBPdcpSduBitrateUlSum 
, DRBPdcpSduBitrateDlSum 
, DRBIpLateDlSum 
, MACULTimeAlignmentError 
, MMPagesSent 
, PAGETWSAtt 
, PAGETWSSucc 
, RRUPrbTotUl 
, RRUPrbTotDl 
, S1SIGConnEstabAtt 
, S1SIGConnEstabSucc 
, SAEBEstabInitAttNbrSum 
, SAEBEstabInitSuccNbrSum 
);


@Pm_Categories = (MMEpsAttachAttE,MMEpsAttachSuccE, MMEpsServiceReqAttTALvl, MMEpsServiceReqSuccTALvl, MMPagingEpsAtt, MMPagingEpsSucc, MMTauInterSgwAtt, MMTauInterSgwSucc, MMTauIntraSgwAtt, MMTauIntraSgwSucc, MMEpsDetachUeAtt, MMEpsDetachUeSucc,


, RRCConnEstabAttSum 
, RRCConnEstabSuccSum 
, RRCConnEstabTimeMaxSum
, RRCConnMean
, RRCConnReEstabSuccSum


, RRUAvgPhyThroughputDl
, RRUAvgPhyThroughputUl
, RRUAvgUsrScheduledDl
, RRUAvgUsrScheduledUl
, RRUPrbDlSum
, RRUPrbUlSum

, MACAvgMacThroughputDl
, MACAvgMacThroughputUl

, BHLKBytesULBackHaul
, BHLKBytesULDropped
, BHLKBytesDLBackHaul
, BHLKBytesDLDropped



, DRBPdcpSduBitrateUlSum
, DRBPdcpSduBitrateDlSum
, DRBDRBUeScheduledNumDl
, DRBDRBUeScheduledNumUl
, DRBIpLateDlSum


, EQPTMeanProcessorUsageBCU3
, EQPTPeakProcessorUsageBCU3

, SAEBEstabInitAttNbrSum 
, SAEBEstabInitSuccNbrSum 

, MACULTimeAlignmentError 
, MACMACPDUsRetransSum 
, MACMACPDUsRetransReqdSum 
, MACHARQDistRACH3Bin0 
, MACHARQDistRACH3Bin1 
, MACHARQDistRACH3Bin2 
, MACHARQDistRACH3Bin3 
, MACHARQDistRACH3Bin4 
, MACHARQDistRACH3Bin5 
, MACHARQDistRACH4Bin0 
, MACHARQDistRACH4Bin1 
, MACHARQDistRACH4Bin2 
, MACHARQDistRACH4Bin3 
, MACHARQDistRACH4Bin4 
, MACHARQDistRACH4Bin5 
, MACHARQDistRACH3Bin6 
, MACHARQDistRACH3Bin7 
, MACHARQDistRACH4Bin6 
, MACHARQDistRACH4Bin7 

, MACHARQDistPDSCHBin6 
, MACHARQDistPDSCHBin7 

, MACHARQDistPDSCHBin0 
, MACHARQDistPDSCHBin1 
, MACHARQDistPDSCHBin2 
, MACHARQDistPDSCHBin3 
, MACHARQDistPDSCHBin4 
, MACHARQDistPDSCHBin5 

, MACHARQDistPUSCHBin0 
, MACHARQDistPUSCHBin1 
, MACHARQDistPUSCHBin2 
, MACHARQDistPUSCHBin3 
, MACHARQDistPUSCHBin4 
, MACHARQDistPUSCHBin5 
, MACHARQDistPUSCHBin6 
, MACHARQDistPUSCHBin7 

, RLCRLCPDUsSentSum 
, RLCRLCPDUsRetransSum 

, UECNTXRelReqHardWareFailure 
, UECNTXRelReqNoUserActivity 
, UECNTXRelReqOMIntervention 
, UECNTXRelReqSoftWareFailure 
, UECNTXRelSuccNbr 

, HOIntraEnbOutAttSum
, HOIntraEnbOutSuccSum
, HOInterEnbOutAttSum
, HOInterEnbOutSuccSum
, HOX2DroppedBytes
);

# @Pm_Categories = (RRCConnMax);






$count = 0 ;




foreach $pat (@Pm_Categories) {$Max_PM{$pat} = 0 ; }

@min = ('00', '05', 10, 15, 20, 25, 30, 35, 40, 45, 50, 55,'00') ;


#  Use in summer
@hr  = ('05', '06', '07', '08', '09', 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,'00', '01', '02', '03', '04' );

#  use in winter
# @hr  = (      '06', '07', '08', '09', 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,'00', '01', '02', '03', '04', '05' );

for ($i=0;$i<12;$i++) { $Plotting_data[0][$i] = $min[$i]; }



$today    = $ARGV[0]   ;
$tomorrow = $ARGV[0]+1 ;

# for ($h=3;$h<=3;$h++)  {
for ($h=0;$h<24;$h++)  {


	# 18 in summer;  17 in winter
	if ($h > 18) { $today = $tomorrow};

	# 5 in summer; 6 in winter
	$cst_hr = $hr[$h]-5 ;
	if ($cst_hr < 0) { $cst_hr += 24 ; }

        # The file name MAY not have a 00_.. in it . So we need to rename the file
	# eg: KeyStatFile_EMS_20110525_045544_20110525_050044.xml   instaed of		Look at 44
	#     KeyStatFile_EMS_20110525_045500_20110525_050000.xml
        for ($i=0;$i<12;$i++) {
                $h1 = $h ;
                if ($i == 11) { $h1 = $h+1; }
                $FileName = "/tmp/JUNK/KeyStatFile_EMS_$today" . "_$hr[$h]$min[$i]" . "00_$today" . "_$hr[$h1]$min[$i+1]" . '00.xml' ;
                $FileName2 = "/tmp/JUNK/KeyStatFile_EMS_$today" . "_$hr[$h]$min[$i]" . '*' . "_$today" . "_$hr[$h1]$min[$i+1]" . '*.xml' ;
                $res=`mv $FileName2  $FileName`;
        }




        printf "\n\n\n#######   CST hr=$cst_hr   Date=$ARGV[0]     PM File Date = $today   UTC hr = $hr[$h];  \n" ;
        for ($i=0;$i<12;$i++) { print ",$min[$i]"; }


	foreach $pat (@Pm_Categories) {

   	printf "\n$pat,";


	for ($i=0;$i<12;$i++) {
		$h1 = $h ;
		if ($i == 11) { $h1 = $h+1; }

		# KeyStatFile_EMS_20101025_110000_20101025_110500.xml
		$FileName = "/tmp/JUNK/KeyStatFile_EMS_$today" . "_$hr[$h]$min[$i]" . "00_$today" . "_$hr[$h1]$min[$i+1]" . '00.xml' ; 
		# print "Idrees FileName=$FileName=\n";
		$Val= "" ;
		%PM = {};
		$PM{$pat} = $Val ;
		# print "Idrees pm=$PM{$pat},=\n";
		# open FILE, "$FileName" or  print "$Val,";
		open FILE, "$FileName"; 

		while (<FILE>) {

        		$line = $_;

        		chop ($line) ;

			# For MME PM
        		if ($line =~ /MKS:TAMMMeasEntry TAIndex=/) {
                		if ($line =~ /$My_TAC/) { $My_Tac_Found = " " ; }
                		else                    { $My_Tac_Found = ""  ; }
        		}

			# For eNB PM
        		if ($line =~ /eUtranGenericCellIndex=/) {
                		if ($line =~ /$My_Sector/) { $My_Tac_Found = " " ; }
                		else                       { $My_Tac_Found = ""  ; }
        		}


        		if ($My_Tac_Found) {}
        		else               {next;}


        		# <MKS:MMEpsAttachAttE isSuspected="false">0</MKS:MMEpsAttachAttE>
			# <EKS:RRCConnReConfigAtt isSuspected="false">844</EKS:RRCConnReConfigAtt>

               		if ($line =~ /$pat isSuspected/) {
                       		$Val = $line ;
                       		$Val =~ s/.*\">(\d+)<.*/$1/;
                       		$PM{$pat} += $Val ;

				# print "Idrees pat=$pat=  Val=$Val=  total=$PM{$pat}=\n";
				# PM Found; break out of loop
				# last ;
               		}
		}
		close(FILE);
		# print "$Val,";              
		# $Plotting_data[1][$i] = $Val; 
		$Plotting_data[1][$i] = $PM{$pat}; 
		print "$PM{$pat},";              
	}
	&Plot_PM($cst_hr,$pat) ;
    }
}



&Merge_PM_Plots ;





sub Plot_PM 
{

	($cst_hr1,$Pm_Name) = @_ ;

        if    ($Pm_Name =~ /RRCConnMean/) 		{ $y_max_val=200;   $y_min_val=0;$y_tick_num=40;   $y_label_skp=5 ;   $y_labl="Active UE"; }
	elsif ($Pm_Name =~ /RRUAvgPhyThroughputDl/) 	{ $y_max_val=200000;$y_min_val=0;$y_tick_num=40;   $y_label_skp=5 ;   $y_labl="Kbps"; }
	elsif ($Pm_Name =~ /RRUAvgPhyThroughputUl/) 	{ $y_max_val=200000;$y_min_val=0;$y_tick_num=40;   $y_label_skp=5 ;   $y_labl="Kbps"; }
	elsif ($Pm_Name =~ /EQPTMeanProcessorUsageBCU3/){ $y_max_val=100   ;$y_min_val=0;$y_tick_num=50;   $y_label_skp=5 ;   $y_labl="%"; }
	elsif ($Pm_Name =~ /RRUPrbDlSum/)		{ $y_max_val=100   ;$y_min_val=0;$y_tick_num=50;   $y_label_skp=5 ;   $y_labl="% "; }
	elsif ($Pm_Name =~ /RRUPrbUlSum/)		{ $y_max_val=100   ;$y_min_val=0;$y_tick_num=50;   $y_label_skp=5 ;   $y_labl="% "; }
        else                       {next   ; }


	# print "Idrees  Plot_PM;  cst_hr1=$cst_hr1=  Pm_Name=$Pm_Name=\n";


	for ($i=0;$i<12;$i++) {
		# print "Idrees i=$i=   0=$Plotting_data[0][$i]   1=$Plotting_data[1][$i]= \n";
	}

        # my $graph = GD::Graph::lines->new(800, 600);
        my $graph = GD::Graph::bars->new(800, 600);

  	$graph->set( 
      		x_label           => 'Time',
      		y_label           => $y_labl,   
      		title             => "$Pm_Name Hour=$cst_hr1" ,

      		# y_max_value       => 200,
      		# y_min_value       => 0,
      		# y_tick_number     => 40 ,
      		# y_label_skip      => 10

                y_max_value       => $y_max_val,
                y_min_value       => $y_min_val,
                y_tick_number     => $y_tick_num,
                y_label_skip      => $y_label_skp 


  	) or die $graph->error;

	# Good display
	# y_tick_number     => 200
	# y_label_skip      => 20

  	my $gd = $graph->plot(\@Plotting_data) or die $graph->error;

	$file_name = $Pm_Name . "_" . "$cst_hr1" . '.png' ;
  	open(IMG, ">$file_name") or die "Unable to create $file_name \n";
  	binmode IMG;
  	print IMG $gd->png;
  	close IMG;

	# print "Idrees created file=$file_name \n";

}





sub Merge_PM_Plots
{

   foreach $pat (@Pm_Categories) {

        if ($pat =~ /RRCConnMean|RRUAvgPhyThroughputDl|RRUAvgPhyThroughputUl|EQPTMeanProcessorUsageBCU3|RRUPrbDlSum|RRUPrbUlSum/) {}
        else                       {next   ; }

   	my $image = Image::Magick->new;
   	my $montage = Image::Magick->new;

	@Files_to_Read = ();
	for ($i=0;$i<24;$i++) {
		$FileName = $pat. "_$i" .".png";
		push(@Files_to_Read, $FileName);
	}
	# printf "Idrees Files_to_Read=@Files_to_Read=\n";

   	my $status = $image -> Read(@Files_to_Read);
   # my $status = $image -> Read("file_0.png", "file_1.png","file_2.png","file_3.png","file_4.png","file_5.png","file_6.png","file_8.png","file_9.png","file_10.png","file_11.png",
#			    "file_12.png","file_13.png","file_14.png","file_15.png","file_16.png","file_17.png","file_18.png","file_19.png","file_20.png","file_21.png","file_22.png","file_23.png");
	print STDERR $status;

	$out_file= "jpg:Allday_" . $pat . ".jpg";
   	$montage = $image -> Montage(mode=>Concatenate, tile=>1);
   	# $montage -> Write('jpg:orig$pat.jpg');
   	$montage -> Write($out_file);
   }

   system("chmod 777 *.jpg; rm *.png; mv *.jpg $ARGV[0] ");


}


