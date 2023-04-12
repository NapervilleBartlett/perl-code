#!/bin/perl


# Use to find the cause element in call flow from the kpi 




# 0Z">UEContextReleaseCommand</a> (10030)</><br>Cause: radioNetwork : release-due


while (<>) {

        $line = $_;

        if ($line =~ /Cause:/) {

                $cause = $line ;
                print "Cause=$cause=\n";


                $cause =~ s/.*>Cause:/Cause:/g;
                print "Cause=$cause=\n";
                $cause =~ s/<.*//g;
                print "Cause=$cause=\n";

        }

}


