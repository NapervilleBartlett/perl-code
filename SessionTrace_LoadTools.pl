#!/bin/perl # This is used to start/stop sessin Trace for UEs in Ercom/Dyaptive/LMTS/DMS # Steps # # # 1. Enter the UE_Start and # of UE.  # 2. Enter the HssPort;    31002 for HSS3
# 3. To run:   perl SessionTrace_LoadTools.pl
# 4. to Stop it.   kill the process.

 
use IO::Socket::INET;


$No_Traces = 10 ;
$HssPort   = 31002;

my $Ercom_IMSI_START    = 460000333000300;
my $Ercom_NO_OF_SUBS    = 1600 ;
my $Ercom_Offset        = 0;
my $Ercom_TraceStr      = "" ;


my $Dyap_1_IMSI_START    = 46000604629326 ;
my $Dyap_1_NO_OF_SUBS    = 500 ;
my $Dyap_1_Offset        = 0;
my $Dyap_1_TraceStr      = "" ;

my $Dyap_2_IMSI_START    = 46000605629326 ;
my $Dyap_2_NO_OF_SUBS    = 500 ;
my $Dyap_2_Offset        = 0;
my $Dyap_2_TraceStr      = "" ;




# flush after every write
$| = 1;
# Connect to the main program
$HSS_sock = IO::Socket::INET->new(
        PeerAddr=> '127.0.0.1',
        PeerPort=>$HssPort,
        proto=>'tcp');




while (1) {

    ($Ercom_Offset, $Ercom_TraceStr)   = &Send_Trace_Cmds($Ercom_IMSI_START, $Ercom_NO_OF_SUBS, $Ercom_Offset, $Ercom_TraceStr);
    ($Dyap_1_Offset, $Dyap_1_TraceStr) = &Send_Trace_Cmds($Dyap_1_IMSI_START,$Dyap_1_NO_OF_SUBS,$Dyap_1_Offset,$Dyap_1_TraceStr);
    ($Dyap_2_Offset, $Dyap_2_TraceStr) = &Send_Trace_Cmds($Dyap_2_IMSI_START,$Dyap_2_NO_OF_SUBS,$Dyap_2_Offset,$Dyap_2_TraceStr);
    system("sleep 3600");
}







sub Send_Trace_Cmds 
{

   my ($IMSI_START, $NO_OF_SUBS, $Offset, $TraceCmds_String) = @_ ;
  

   # Look at the last TraceCmds_String, and convert it to a endtrace commands 
   $TraceCmds_String =~ s/starttrace/endtrace/g ;
   $TraceCmds_String =~ s/type=1//g ;
   # Send this string out 
   foreach my $Str (split (/\n/,$TraceCmds_String)) {
   	print $HSS_sock "$Str\n";
	system("sleep 1");
   }
   # print "$TraceCmds_String\n";
  

   my $IMSI_To_Be_Used = $IMSI_START + $Offset ;
   $TraceCmds_String = "";

 


   for ($j=0;$j<$No_Traces;$j++) {
		$Offset++ ;
		if ($Offset > $NO_OF_SUBS) {$IMSI_To_Be_Used = $IMSI_START ; $Offset=0;} 

		$TraceCmds_String .= "starttrace IMSI=$IMSI_To_Be_Used  type=1\n" ;
		$IMSI_To_Be_Used++ ;  
   }
   # Send this string out
   foreach my $Str (split (/\n/,$TraceCmds_String)) {
	print $HSS_sock "$Str\n";
	system("sleep 1");
   }
   # print "$TraceCmds_String\n";

  return ($Offset, $TraceCmds_String) ;
}



