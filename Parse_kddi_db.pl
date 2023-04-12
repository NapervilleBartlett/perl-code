#!/bin/perl


# Usage:  perl Parse_kddi_db.pl  FileName    >  /tmp/FileName.cmd 


# BandwidthConfig,srsBandwidthConfig,"Index=1 : 0
# Index=2 : 0
#       |-- 2 is the End Of MocIndex 

&printHeader ();

while (<>) {

	my $line = $_ ;

	chop($line);


	if ($line =~ /^Index=/) {
		my $tmp_line = $';
		$tmp_line =~ s/\s+//g ;
		($End_Of_MocIndex,$value) = split(/:/,$tmp_line) ;
		# print "------------ Idrees line=$line=  End_Of_MocIndex=$End_Of_MocIndex= value=$value=\n"; 
	}

	else {
		($moc, $Parameter, $value) = split(/,/,$line) ;
		
		if ($value =~ /Index=/) {
			 my $tmp_line = $';
			$tmp_line =~ s/\s+//g ;
			($End_Of_MocIndex,$value) = split(/:/,$tmp_line) ;
		}
		else { $End_Of_MocIndex = "" ; }

		# print "#### Idrees line=$line= moc=$moc= Parameter=$Parameter= value=$value= End_Of_MocIndex=$End_Of_MocIndex=\n";

	}



	# print "moc=$moc=  Parameter=$Parameter=  value=$value=\n";

	print "\n\n";

	# print "## Line=$line= moc=$moc=  Parameter=$Parameter=  value=$value=\n";
	print "### Line=$line\n";
	# Find the moc index using the display cmd. 
	$MocIdFileName = '/tmp/' . $moc . "_$Parameter" . "_$End_Of_MocIndex" ; 
	# $cmd = "./mmcli show  -moc     $moc     | grep       $Parameter     | cut -d \" \" -f 1 > $MocIdFileName";
	my $cmd = "./mmcli show  -moc     $moc     | grep       $Parameter     | cut -d \" \" -f 1 | grep \"$End_Of_MocIndex\$\" > $MocIdFileName";

	print "$cmd\n" ; 

$cmd = 'for moc_id in `cat   ' . $MocIdFileName .  '  `
do
./mmcli modify -phase submit -moc ' . $moc .  '   -id  $moc_id    '  . $Parameter . '=' . $value .'
done
./mmcli commit -state Pending
';
	print "$cmd \n" ;


}






sub printHeader
{

  $PrintComments = '

#!/bin/bash
#
cd /usr/MotoAgent
source /usr/MotoAgent/startup.sh /repl/MotoAgent 
export CLI_HOME=/usr/MotoAgent/agent
export LIB_PATH_SET=1
export COLUMNS
export CLI_HOME
cd /usr/MotoAgent/agent/bin

echo "Starting provisioning ...."
echo "Y" > Y
./mmcli checkout 
./mmcli abort Configuration

echo "Its OK if abort Configuration command is FAILING."
echo "Wait 10s ..."
sleep 10

echo "This script is for standalone/MT/DT bench"
sleep 2 

echo "For script issue contact: Idrees.qasim@nsn.com

sleep 2

./mmcli abort Configuration
sleep 5';


   print "$PrintComments\n\n\n";

}


