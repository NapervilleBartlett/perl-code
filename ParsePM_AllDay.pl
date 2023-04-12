#!/bin/perl


# Usage:  ParsePM_Graph_AllDay.pl   20101101


# looks into the /tmp/JUNK directtory for files 


# use GD::Graph::lines;
# use GD::Graph::bars;
# use CGI qw(:standard);

# use Image::Magick;



$My_TAC = "5103";
%PM = {};
%Max_PM = {} ;

$My_Sector = 'eUtranGenericCellIndex' ; 


@Pm_Categories = (MMEpsAttachAttE,MMEpsAttachSuccE, MMEpsServiceReqAttTALvl, MMEpsServiceReqSuccTALvl, MMPagingEpsAtt, MMPagingEpsSucc, MMTauInterSgwAtt, MMTauInterSgwSucc, MMTauIntraSgwAtt, MMTauIntraSgwSucc, MMEpsDetachUeAtt, MMEpsDetachUeSucc,


, RRCConnEstabAttSum
, RRCConnEstabSuccSum
, RRCConnEstabTimeMaxSum
, RRCConnMean
, RRCConnReEstabSuccSum
, RRCConnReleaseSum
, RRCConnUsageTime  
, RRCConnEstabTimeMeanSum
, RRCConnReConfigAtt
, RRCConnReConfigSucc
, RRCConnReEstabAttSum


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



, DRBPdcpSduBitrateDl 
, DRBPdcpSduBitrateUl












);

# @Pm_Categories = (RRCConnMax);









foreach $pat (@Pm_Categories) {$Max_PM{$pat} = 0 ; }

@min = ('00', '05', 10, 15, 20, 25, 30, 35, 40, 45, 50, 55,'00') ;
#  Use in summer
@hr  = ('05', '06', '07', '08', '09', 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,'00', '01', '02', '03', '04' );
#  Use in winter
# @hr  = (      '06', '07', '08', '09', 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,'00', '01', '02', '03', '04', '05' );




$today    = $ARGV[0]   ;
$tomorrow = $ARGV[0]+1 ;




# for ($h=3;$h<=3;$h++)  {
for ($h=0;$h<24;$h++)  {

        # if ($h > 17) { $today = $tomorrow};   # Use in winter
        if ($h > 18) { $today = $tomorrow};     # Use in summer

	# $cst_hr = $hr[$h]-5 ;    use in winter
	$cst_hr = $hr[$h]-5 ;	   # Use in summer
	if ($cst_hr < 0) { $cst_hr += 24 ; }

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
		print "$PM{$pat},";              
	}
    }
}








