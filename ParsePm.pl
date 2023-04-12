#!/bin/perl


$My_TAC = "5103";
%PM = {};

$My_Sector = 'eUtranGenericCellIndex' ; 

@Pm_Categories = (MMEpsAttachAttE,MMEpsAttachSuccE, MMEpsServiceReqAttTALvl, MMEpsServiceReqSuccTALvl, MMPagingEpsAtt, MMPagingEpsSucc, MMTauInterSgwAtt, MMTauInterSgwSucc, MMTauIntraSgwAtt, MMTauIntraSgwSucc, MMEpsDetachUeAtt, MMEpsDetachUeSucc , RRCConnEstabAttSum,RRCConnEstabSuccSum,S1SIGConnEstabAtt,S1SIGConnEstabSucc,RRCConnReConfigAtt,RRCConnReConfigSucc,SAEBEstabInitAttNbrSum,SAEBEstabInitSuccNbrSum,SAEBRelAttNbrSum,RRCConnReleaseSum,RRCConnMax,RRCConnMean);


$count = 0 ;




while (<>) {

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

        foreach $pat (@Pm_Categories) {
                if ($line =~ /$pat isSuspected/) {
                        $Val = $line ;
                        $Val =~ s/.*\">(\d+)<.*/$1/;
                        $PM{$pat} += $Val ;
                        # print "Idrees pat=$pat=   total=$PM{$pat}= \n";

			if ($line =~ /RRCConnMax/) {$count++;}

                }
        }






}



foreach $pat (@Pm_Categories) {
        printf "%-30.30s %-10.10s\n", $pat,$PM{$pat};
}

@RRCConns=(RRCConnMax,RRCConnMean);
foreach $pat (@RRCConns) { printf "%-30.30s %-10.10s\n", $pat,$PM{$pat}/$count; }



