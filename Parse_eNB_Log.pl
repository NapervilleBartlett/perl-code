#!/bin/perl


@S1AP = () ;
$SawS1AP = '';
%RRC_Messages = {};
%S1AP_Messages = {};
%RNTI_S1AP_Mapping = {} ;
$InitialUE_cRNTI="";

while (<>) {


        $line1 =$_ ;
        $line1 =~ s/^M//g ;
        chop ($line1) ;

        # 2009-10-02|11:23:16|        id 26,jkklj lkjklj
        # <E t="2011-07-30 04:38:46.189" es="0" ep="0x12005b" ei="0x0" ie="0x0" ii="0x0"><![CDATA[

        if (/2011-/) {
                $TimeStamp = $line1;
                $TimeStamp =~s/.*(2011-\d+-\d+ \d+:\d+:\d+\.\d+\").*/$1/g;
                chop($TimeStamp) ;
                $line = $2;

                # print "TimeStamp=$TimeStamp=\n";
        }


        if (/cRnti/) {
                # .callId.cRnti = 0x0077
                $cRnti = $';
                chop($cRnti);
                $cRnti =~ s/\s+//g;
                # print "Idrees cRnti=$cRnti=\n";
        }



        if (/value ENB-UE-S1AP-ID :/) {

                # value ENB-UE-S1AP-ID : 909
                $ENB_UE_S1AP_ID = $';
                chop($ENB_UE_S1AP_ID) ;
                $ENB_UE_S1AP_ID =~ s/\s+//g;

        }




        # S1AP Message
        # if ($line =~ /S1AP-PDU/) {$SawS1AP = " " ;}
        # if ($line =~ / value /) {$SawS1AP = " " ;}
        if ($line1 =~ /value S1AP-PDU ::=/) {$SawS1AP = " " ;}

        if ($SawS1AP) {
                push(@S1AP,$line1);
                if ($line1 =~ /^}/) {
                        $SawS1AP = ''; $Nas_Msg=""; $Cause="";
                        # print "S1AP = @S1AP=\n";
			# Find S1AP Message name
                        foreach $i (@S1AP) {
				#   value Paging :
                                if (($i =~ /value/) && ($i !~ /::/) ) {
                                        $S1AP_MsgName = $i ;
                                        $S1AP_MsgName =~ s/value /S1AP:/ ;
                                        last ;
                                }
                        }
			# Find NAS in S1AP
			# value NAS-PDU : '             0741710839521961402639470280800004 ...'H
			foreach $i (@S1AP) { 
				if ($i =~ /value NAS-PDU :/) { $Nas_Msg = &Return_NAS_MessageName($i) ; }
			}


			# cause radioNetwork : radio-resources-not-available


			foreach $i (@S1AP) {
				if ($i =~ /cause|value Cause/) { $Cause=$i ; $Cause=~ s/\s+//g; }
			}

			$Gap = " " ;
			$MsgStr = sprintf ("%-25.25s %-34.34s %-30.30s %-20.20s %-6.6s %s\n",  $TimeStamp, $Gap, $S1AP_MsgName, $Nas_Msg, $ENB_UE_S1AP_ID,$Cause);
			$S1AP_Messages{$ENB_UE_S1AP_ID} .= $MsgStr ;
			print "$MsgStr";
			$MsgStr = "";
			if ($S1AP_MsgName =~ /InitialUEMessage/) { 
				$RNTI_S1AP_Mapping{$InitialUE_cRNTI} = $ENB_UE_S1AP_ID ; 
				# print "Idrees InitialUE_cRNTI=$InitialUE_cRNTI= ENB_UE_S1AP_ID=$ENB_UE_S1AP_ID= \n"; 
				$InitialUE_cRNTI="";
			}
			@S1AP = () ;
			
                }
        }



	# RRC Message
        if ($line1 =~ /message c1/) {
                $line1 =~ s/message c1 :/RRC:/g;
                $line1 =~ s/rrcConnection/Con/g;
                $line1 =~ s/Reconfiguration/Reconfig/g;
                $MsgStr = sprintf ("%-25.25s %-30.30s %-10.10s \n",  $TimeStamp, $line1,  $cRnti) ;
		print "$MsgStr";
		$RRC_Messages{$cRnti} .= $MsgStr ;
		$MsgStr = "";      
		
		if ($line1 =~ /ConSetupComplete/) { $InitialUE_cRNTI=$cRnti ; } 

                # printf ("%02d divided by %2d is %6.3f\n",$val,$k,$r1);

        }

}


while ( ($crnti,$enb_s1ap_id) = each (%RNTI_S1AP_Mapping)   ) {

	print "\n\n\n=========================== Idrees crnti=$crnti= enb_s1ap_id=$enb_s1ap_id=\n";

	# print "$RRC_Messages{$crnti}\n";
	# print "$S1AP_Messages{$ENB_UE_S1AP_ID}\n";

	$OneCall= $RRC_Messages{$crnti} . $S1AP_Messages{$enb_s1ap_id} ;
	@OneCall_Array = split(/\n/,$OneCall);

	foreach $sorted_msg (sort @OneCall_Array) {
		print "$sorted_msg \n";
	}

	# Remove the messages after printing
	$RRC_Messages{$crnti} = "";
	$S1AP_Messages{$enb_s1ap_id} = "" ;
}


# Print remaining
print "\n\n\n=========================== Idrees:: The following messages could not be paired \n"; 
foreach $val (values %RRC_Messages) { print "$val \n"; }
foreach $val (values %S1AP_Messages) { print "$val \n"; }




# value NAS-PDU : '             0741710839521961402639470280800004 ...'H
#         value NAS-PDU : '270000000005074E03'H
sub Return_NAS_MessageName {

	my ($In_line) = @_;

	$Nas_MsgType = "";

	$In_line =~ s/value NAS-PDU|:|'|\s+//g;

	$In_line =~ s/(\w\w)/$1 /g;        # Add a space between bytes
	@Bytes = split(/\s+/,$In_line); 
	$Nas_MsgType = $Bytes[0] ;





        if    ($Bytes[0] =~ /07/)          { $Nas_MsgType = hex($Bytes[1]); $pd=hex($Bytes[0]);}
        elsif ($Bytes[0] =~ /17|27|37|47/) { $Nas_MsgType = hex($Bytes[7]); $pd=hex($Bytes[6]);}
        elsif ($Bytes[0] =~ /C7/)          { $Nas_MsgType = hex($Bytes[0]); $pd=0x07 ;}


        # EMM messages
        if (($pd & 0x0F) == 0x07)  {
                if    ($Nas_MsgType == 0xC7)    { $Nas_MsgName = "Service Req"; }
                elsif ($Nas_MsgType == 0x41)    { $Nas_MsgName = "Attach_request";}
                elsif ($Nas_MsgType == 0x42)    { $Nas_MsgName = "Attach_accept";}
                elsif ($Nas_MsgType == 0x43)    { $Nas_MsgName = "Attach_complete";}
                elsif ($Nas_MsgType == 0x44)    { $Nas_MsgName = "Attach_reject";}
                elsif ($Nas_MsgType == 0x45)    { $Nas_MsgName = "Detach_request";}
                elsif ($Nas_MsgType == 0x46)    { $Nas_MsgName = "Detach_accept";}
                elsif ($Nas_MsgType == 0x48)    { $Nas_MsgName = "TAU_request";}
                elsif ($Nas_MsgType == 0x49)    { $Nas_MsgName = "TAU_accept";}
                elsif ($Nas_MsgType == 0x4a)    { $Nas_MsgName = "TAU_complete";}
                elsif ($Nas_MsgType == 0x4b)    { $Nas_MsgName = "TAU_reject";}
                elsif ($Nas_MsgType == 0x4c)    { $Nas_MsgName = "Extended Servie Re";}
                elsif ($Nas_MsgType == 0x4e)    { $Nas_MsgName = "Servcice Rej";}

                elsif ($Nas_MsgType == 0x50)    { $Nas_MsgName = "GUTI_reallocation_command";}
                elsif ($Nas_MsgType == 0x51)    { $Nas_MsgName = "GUTI_reallocation_complete";}
                elsif ($Nas_MsgType == 0x52)    { $Nas_MsgName = "Auth_request";}
                elsif ($Nas_MsgType == 0x53)    { $Nas_MsgName = "Auth_response";}
                elsif ($Nas_MsgType == 0x54)    { $Nas_MsgName = "Auth_reject";}
                elsif ($Nas_MsgType == 0x5c)    { $Nas_MsgName = "Auth_failure";}
                elsif ($Nas_MsgType == 0x55)    { $Nas_MsgName = "Identity_request";}
                elsif ($Nas_MsgType == 0x56)    { $Nas_MsgName = "Identity_response";}
                elsif ($Nas_MsgType == 0x5d)    { $Nas_MsgName = "Security_mode_command";}
                elsif ($Nas_MsgType == 0x5e)    { $Nas_MsgName = "Security_mode_complete";}
                elsif ($Nas_MsgType == 0x5f)    { $Nas_MsgName = "Security_mode_reject";}
                elsif ($Nas_MsgType == 0x60)    { $Nas_MsgName = "EMM_status";}
                elsif ($Nas_MsgType == 0x61)    { $Nas_MsgName = "EMM_information";}
                elsif ($Nas_MsgType == 0x62)    { $Nas_MsgName = "DL_NAS_transp";}
                elsif ($Nas_MsgType == 0x63)    { $Nas_MsgName = "UL_NAS_transp";}
                elsif ($Nas_MsgType == 0x64)    { $Nas_MsgName = "CS Serv ";}
                else                            {
                        $Nas_MsgName = "Invalid NAS=$In_line= ; MT=".sprintf("%-2.2x",$Nas_MsgType);
                        print "Idrees Invalid NAS=$In_line=\n";
                }
        }

        # ESM Messahe
        if (($pd & 0x0F) == 0x02)  {

                $Nas_MsgType = hex($Bytes[8]);
                   if    ($Nas_MsgType == 0xc1) { $Nas_MsgName = "ActivateDefBear_Req";}
                elsif    ($Nas_MsgType == 0xc2) { $Nas_MsgName = "ActivateDefBear_Accpt";}
                elsif    ($Nas_MsgType == 0xc3) { $Nas_MsgName = "ActivateDefBear_Rejec";}
                elsif    ($Nas_MsgType == 0xc5) { $Nas_MsgName = "ActivateDedBear_Req";}
                elsif    ($Nas_MsgType == 0xc6) { $Nas_MsgName = "ActivateDedBear_Accpt";}
                elsif    ($Nas_MsgType == 0xc7) { $Nas_MsgName = "ActivateDedBear_Reject";}
                elsif    ($Nas_MsgType == 0xc9) { $Nas_MsgName = "ModifyBear_Req";}
                elsif    ($Nas_MsgType == 0xca) { $Nas_MsgName = "ModifyBear_Accpt";}
                elsif    ($Nas_MsgType == 0xcb) { $Nas_MsgName = "ModifyBear_Reject";}
                elsif    ($Nas_MsgType == 0xcd) { $Nas_MsgName = "DeactivateBear_Req";}
                elsif    ($Nas_MsgType == 0xce) { $Nas_MsgName = "DeactivateBear_Accpt";}

                elsif    ($Nas_MsgType == 0xd0) { $Nas_MsgName = "PDNconn_ request";}
                elsif    ($Nas_MsgType == 0xd1) { $Nas_MsgName = "PDNconn_ reject";}
                elsif    ($Nas_MsgType == 0xd2) { $Nas_MsgName = "PDN_discon_request";}
                elsif    ($Nas_MsgType == 0xd3) { $Nas_MsgName = "PDN_discon_reject";}
                elsif    ($Nas_MsgType == 0xd4) { $Nas_MsgName = "Bear_Res_Alloc_Req ";}
                elsif    ($Nas_MsgType == 0xd5) { $Nas_MsgName = "Bear_Res_Alloc_Reject ";}
                elsif    ($Nas_MsgType == 0xd6) { $Nas_MsgName = "Bear_Res_Mod_Req ";}
                elsif    ($Nas_MsgType == 0xd7) { $Nas_MsgName = "Bear_Res_Mod_Rej ";}
                elsif    ($Nas_MsgType == 0xd9) { $Nas_MsgName = "ESM_info_request";}
                elsif    ($Nas_MsgType == 0xda) { $Nas_MsgName = "ESM_info_response";}
                elsif    ($Nas_MsgType == 0xe8) { $Nas_MsgName = "ESM_status";}
                else                            {
                        $Nas_MsgName = "Invalid NAS=$In_line= ; MT=".sprintf("%-2.2x",$Nas_MsgType);
                        print "Idrees Invalid NAS=$In_line=\n";
                }

        }





	return $Nas_MsgName ;

	# print "Idrees In_line=$In_line=   Nas_MsgType=$Nas_MsgType= Nas_MsgName=$Nas_MsgName= 0=$Bytes[0]= 1=$Bytes[1]= 2=$Bytes[2]=  3=$Bytes[3]=  4=$Bytes[4]=  \n";

}


