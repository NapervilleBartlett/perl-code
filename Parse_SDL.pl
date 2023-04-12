#!/bin/perl

use Switch;




$FileName = $ARGV[0] ;




%SDl_1_UE = () ;
%Release_Cause_Counter = () ;

&ResetVariables();


while (<>) {

	$line = $_ ;
	chop ($line) ;
	$line =~ s/\s+//g;

	# CSFB_TARGET_SECTOR_ID  is last entry in RRC record 
	if ($line =~ /CSFB_TARGET_SECTOR_ID/) { 
			$DL_rate =0 ; $UL_rate=0;
			if ($DL_SUBFRAME_COUNT > 0) { $DL_rate = sprintf("%-4.4f", 8 * 1000 * $DL_RLC_NEW_BYTES / (1024*1024*$DL_SUBFRAME_COUNT)) ; }
			if ($UL_SUBFRAME_COUNT > 0) { $UL_rate = sprintf("%-4.4f", 8 * 1000 * $UL_RLC_NEW_BYTES / (1024*1024*$UL_SUBFRAME_COUNT)) ; }

			$SDl_1_UE{$GUTI} .= "SDL:: $GUTI,$ENB_UE_S1AP_IDENTITY,$MME_UE_S1AP_IDENTITY,$ACCESS_TIMESTAMP,$RELEASE_TIMESTAMP,$DL_rate Mbps, $UL_rate Mbps, $LAST_USED_RRC_CAUSE,$LAST_USED_S1AP_CAUSE,$RRC_CONNECTION_RELEASE_CAUSE\n" ;
			&ResetVariables();
	}

	elsif ($line =~ /ACCESS_TIMESTAMP=/)    	{$ACCESS_TIMESTAMP=$';  $ACCESS_TIMESTAMP  =~ s/2011.*//g; } 
	elsif ($line =~ /RELEASE_TIMESTAMP=/)   	{$RELEASE_TIMESTAMP=$'; $RELEASE_TIMESTAMP =~ s/2011.*//g;  } 
	elsif ($line =~ /LAST_USED_RRC_CAUSE=/) 	{$LAST_USED_RRC_CAUSE=$'; } 
	elsif ($line =~ /LAST_USED_S1AP_CAUSE=/) 	{$LAST_USED_S1AP_CAUSE=$'; } 
	elsif ($line =~ /RRC_CONNECTION_RELEASE_CAUSE=/)	{
			$RRC_CONNECTION_RELEASE_CAUSE=$' ;
			$RRC_CONNECTION_RELEASE_CAUSE .= &Return_RRC_Connection_Rel_Cause($RRC_CONNECTION_RELEASE_CAUSE);} 
	elsif ($line =~ /GUTI=/) 			{$GUTI =$'; } 
	elsif ($line =~ /ENB_UE_S1AP_IDENTITY/) 	{$ENB_UE_S1AP_IDENTITY=$'; } 
	elsif ($line =~ /MME_UE_S1AP_IDENTITY/) 	{$MME_UE_S1AP_IDENTITY=$'; } 
	elsif ($line =~ /AM_DL_RLC_NEW_BYTES=|UM_DL_RLC_NEW_BYTES=/) 	{$DL_RLC_NEW_BYTES +=$'; } 
	elsif ($line =~ /AM_UL_RLC_NEW_BYTES=|UM_UL_RLC_NEW_BYTES=/) 	{$UL_RLC_NEW_BYTES +=$'; } 
	elsif ($line =~ /DL_SUBFRAME_COUNT=/) 		{$DL_SUBFRAME_COUNT=$'; } 
	elsif ($line =~ /UL_SUBFRAME_COUNT=/) 		{$UL_SUBFRAME_COUNT=$'; } 

}


&Print_OverallStats();
&Print_AllSDLs();



















sub Print_AllSDLs
{

	print "GUTI,ENB_UE_S1AP_IDENTITY,MME_UE_S1AP_IDENTITY,ACCESS_TIMESTAMP,RELEASE_TIMESTAMP,DL_Rate, UL_Rate, LAST_USED_RRC_CAUSE,LAST_USED_S1AP_CAUSE,RRC_CONNECTION_RELEASE_CAUSE\n";
	foreach $guti_key (sort keys %SDl_1_UE) { print "$SDl_1_UE{$guti_key} \n"; }

}





sub Print_OverallStats
{
	$total_records=0 ;
	foreach $cause_key (keys %Release_Cause_Counter) { $total_records += $Release_Cause_Counter{$cause_key} ; }
	print "\n\nFile=$FileName\n";
	printf "%-50.50s %-6d ;\n", "Total Records", $total_records ;

	foreach $cause_key (sort keys %Release_Cause_Counter) { 
		$percentage = (100 * $Release_Cause_Counter{$cause_key} / $total_records) ; 
		# print "$cause_key, $Release_Cause_Counter{$cause_key}, $percentage\n ";
		printf "%-50.50s %-6.1d %d%\n", $cause_key, $Release_Cause_Counter{$cause_key}, $percentage ;
	}

}










sub ResetVariables 
{

	$ACCESS_TIMESTAMP="";   $RELEASE_TIMESTAMP=""; $LAST_USED_RRC_CAUSE=""; $LAST_USED_S1AP_CAUSE="";
	$RRC_CONNECTION_RELEASE_CAUSE="";$GUTI="";
        $ENB_UE_S1AP_IDENTITY="";       
        $MME_UE_S1AP_IDENTITY="";       
        $DL_RLC_NEW_BYTES = 0 ;
        $UL_RLC_NEW_BYTES = 0 ;
	$DL_SUBFRAME_COUNT = "";
	$UL_SUBFRAME_COUNT = "";

}




sub Return_RRC_Connection_Rel_Cause 
{

	($rrc_con_rel_cause_in) = @_ ;

	# print "Idrees Return_RRC_Connection_Rel_Cause;   rrc_con_rel_cause_in=$rrc_con_rel_cause_in=\n";
	$ret = "" ;


	switch ($rrc_con_rel_cause_in) {
		case "0"	{$ret=":default"   }
		case "2000"	{$ret=":Inactivity ::SigOnly" }
		case "2010"	{$ret=":Inactivity::Bearer " }
		case "2020"	{$ret=":RF lost" }

		case "1000"	{$ret=":Normal Network Initiated Release" }

		case "3000"	{$ret=":InitCntxtSet:RRCReconfig Timeout" }
		case "3010"	{$ret=":InitCntxtSet:ReestablishRcvd_Cause_other" }
		case "3020"	{$ret=":InitCntxtSet:ReestablishRcvd_Cause_reconfigFail" }
		case "3030"	{$ret=":InitCntxtSet:UE Capability Timeout " }
		case "3040"	{$ret=":InitCntxtSet:UE State mismatch" }
		case "3050"	{$ret=":InitCntxtSet:TRrcSecurityMode timeout" }

		case "3060"	{$ret=":InitCntxtSet:TIntInitialUserUpdate timeout" }
		case "3070"	{$ret=":InitCntxtSet:TIntTunnelPairCreate timeout" }
		case "3080"	{$ret=":InitCntxtSet:TIntGtpTunnelConfig timeout" }
		case "3090"	{$ret=":InitCntxtSet:TIntEnableSecurity" }
		case "3100"	{$ret=":InitCntxtSet:TIntResetUser" }
		case "3110"	{$ret=":InitCntxtSet:TIntTunnelCleanup" }

		case "4000"	{$ret=":ERAB_SETUP::TO RRCReconfiguration" }
		case "4010"	{$ret=":ERAB_SETUP::ReestablishRcvd_Cause_other" }
		case "4020"	{$ret=":ERAB_SETUP::ReestablishRcvd_Cause_reconfigFail" }
		case "4030"	{$ret=":ERAB_SETUP::TIntCreateBearer" }
		case "4040"	{$ret=":ERAB_SETUP::TunnelPairCreateResponse error" }

		case "5000"	{$ret=":ERAB_MODIFY::TO TRrcConnectionReconfiguration" }
		case "5010"	{$ret=":ERAB_MODIFY::ReestablishRcvd_Cause_other" }
		case "5020"	{$ret=":ERAB_MODIFY::ReestablishRcvd_Cause_reconfigFail" }
		case "5030"	{$ret=":ERAB_MODIFY::TBearerModifyResponse" }
		case "5040"	{$ret=":ERAB_MODIFY::ModifyBearerResponse error" }

		case "6000"	{$ret=":ERAB_RLS_CMD::TO RRCReconfiguration" }
		case "6010"	{$ret=":ERAB_RLS_CMD::ReestablishRcvd_Cause_other" }
		case "6020"	{$ret=":ERAB_RLS_CMD::ReestablishRcvd_Cause_reconfigFail" }

		case "7000"	{$ret=":DL Rlc Max Retries Drb" }
		case "7010"	{$ret=":DL Rlc Max Retries Srb1" }
		case "7020"	{$ret=":DL Rlc Max Retries Srb2" }

		case "8000"	{$ret=":Lack of E-RAB IDs triggered HO::UE acquisition TO TRRCUEAcquisition " }
		case "8010"	{$ret=":Lack of E-RAB IDs triggered HO::Successful acquisition on TargetRRC" }
		case "8020"	{$ret=":Lack of E-RAB IDs triggered HO::Reestablish on Src Cell" }
		case "8030"	{$ret=":Lack of E-RAB IDs triggered HO::Reestablish on Other Cell" }

		case "9000"	{$ret=":Intra ENB Inter Cell HO SRC::UE acquisition TO TRRCUEAcquisition Expi" }
		case "9010"	{$ret=":Intra ENB Inter Cell HO SRC::Reestablish on Src Cell" }
		case "9020"	{$ret=":Intra ENB Inter Cell HO SRC::Reestablish on Tgt Cell" }
		case "9030"	{$ret=":Intra ENB Inter Cell HO SRC::Reestablish on Other Cell" }
		case "9040"	{$ret=":Intra ENB Inter Cell HO SRC::Successful acquisition on TargetRRC" }

		case "10000"	{$ret=":InitialUE::TO" }

		case "11000"	{$ret=":UEContextModify::UE acquisition TO TRRCUEAcquisition Expiry" }
		case "11010"	{$ret=":UEContextModify::Successful acquisition on TargetRRC" }
		case "11020"	{$ret=":UEContextModify::Reestablish" }
		case "11030"	{$ret=":UEContextModify::Reestablish on Other Cell" }
		case "11040"	{$ret=":UEContextModify::TIntModifyUser timer expired" }
		case "11050"	{$ret=":UEContextModify::Modem returned modification error" }

		case "12000"	{$ret=":PDCP Counter Threshold triggered HO::UE acquisition TO TRRCUEAcquisition" }
		case "12010"	{$ret=":PDCP Counter Threshold triggered HO::Successful acquisition on TargetRRC" }
		case "12020"	{$ret=":PDCP Counter Threshold triggered HO::Reestablish on Src Cell" }
		case "12030"	{$ret=":PDCP Counter Threshold triggered HO::Reestablish on Other Cell" }

		case "13000"	{$ret=":X2 Inter ENB HO SRC::X2:UE Context Rls Rcvd Successful acquisition on T" }
		case "13010"	{$ret=":X2 Inter ENB HO SRC::X2:UE Context Rls TOTX2EELOCoverall Expiry" }
		case "13020"	{$ret=":X2 Inter ENB HO SRC::Reestablish on Src Cell" }
		case "13030"	{$ret=":X2 Inter ENB HO SRC::Reestablish on Other Cell Src ENB" }

		case "14000"	{$ret=":X2 Inter ENB HO TGT::PDCP context not rcvd TPDCPContextRcvd Expiry" }
		case "14010"	{$ret=":X2 Inter ENB HO TGT::UE not acquired TRRCUEAcquisition Expiry" }
		case "14020"	{$ret=":X2 Inter ENB HO TGT::Path Switch Failure Rcvd" }
		case "14030"	{$ret=":X2 Inter ENB HO TGT::Path Switch Response TO TS1APPathSwitch Expiry" }
		case "14040"	{$ret=":X2 Inter ENB HO TGT::Reestablish on Tgt Cell" }
		case "14050"	{$ret=":X2 Inter ENB HO TGT::Reestablish on Other Cell Tgt ENB" }

		case "15000"	{$ret=":S1AP Inter ENB HO SRC::S1AP:UE Context Rls Cmd Rcvd" }
		case "15010"	{$ret=":S1AP Inter ENB HO SRC::S1AP:UE Context Rls Cmd TO TS1RELOCoverall Expi" }
		case "15020"	{$ret=":S1AP Inter-ENB HO SRC::Reestablish on Src Cell" }
		case "15030"	{$ret=":S1AP Inter ENB HO SRC::Reestablish on Other Cell Src ENB" }

		case "16000"	{$ret=":Network O&M Intervention" }
		case "16010"	{$ret=":eNB O&M Intervention" }

		case "17000"	{$ret=":S1AP Inter ENB HO TGT::PDCP context not rcvd TPDCPContextRcvd Expiry" }
		case "17010"	{$ret=":S1AP Inter ENB HO TGT::UE not acquired TRRCUEAcquisition Expir" }
		case "17020"	{$ret=":S1AP Inter ENB HO TGT::Reestablish on Tgt Cell" }
		case "17030"	{$ret=":S1AP Inter ENB HO TGT::Reestablish on Other Cell Tgt ENB" }

		case "18000"	{$ret=":UEContextRelease::with redirection to GERAN interRAT to GERAN" }
		case "18010"	{$ret=":UEContextRelease::with redirection to UTRA interRAT to UTRA" }
		case "18020"	{$ret=":UEContextRelease::active handover to eHRPD Release due to Opt-H.O" }
		case "18030"	{$ret=":UEContextRelease::active handover to eHRPD Release due to Opt-H.O." }
		case "18040"	{$ret=":UEContextRelease::with redirection to eHRPD Release due to Non-Opt-" }
		case "18050"	{$ret=":UEContextRelease::active handover to CSFB Release due to e1xCSFB ex" }
		case "18060"	{$ret=":UEContextRelease::active handover to CSFB Release due to e1xCSFB 2nd " }
		case "18070"	{$ret=":Reserved" }
		case "18080"	{$ret=":UEContextRelease::with redirection to CSFB Release due to Rel8CSFB " }
		case "18090"	{$ret=":UEContextRelease::with redirection to CSFB Release due to Rel8CSFB " }
		case "18100"	{$ret=":UEContextRelease::with redirection to CSFB Release due to Rel8CSFB " }
		case "18110"	{$ret=":UEContextRelease::with redirection to CSFB Release due to Rel8CSFB " }
		case "18120"	{$ret=":UEContextRelease::with redirection to CSFB Release due to Rel8CSFB " }
		case "18130"	{$ret=":UEContextRelease::with redirection to CSFB Release due to Rel8CSFB " }
		case "18140"	{$ret=":UEContextRelease::1xCSFB pre-condition check failure during re-establishment" }
		case "18150"	{$ret=":1xCSFB Reestablish on Src eNodeB" }
		case "18160"	{$ret=":1xCSFB Reestablish on Src eNodeB HO failure" }
		case "18170"	{$ret=":eHRPD Reestablish on Src Cell EhrpdConfig::TC2KRelocPrep timer is runnin" }
		case "18180"	{$ret=":eHRPD Reestablish on Src Cell HO failure" }
		case "18190"	{$ret=":eHRPD Reestablish on Other Cell Src ENB HO failure" }

		case "19000"	{$ret=":Release Context Invalid S1APID" }
		case "19010"	{$ret=":Release Context IWF error " }
		else		{$ret=":### Illegal  " }
	}

	$ret = "$rrc_con_rel_cause_in  $ret";
	 $Release_Cause_Counter{$ret}++ ;


	return $ret ;

}

