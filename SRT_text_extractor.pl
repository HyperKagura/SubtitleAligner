use strict;
use warnings;

my $input_f1 = "";
my $move_secs = 0;
if ($#ARGV >= 0) {
	$input_f1 = $ARGV[0];
	#print "File is: $input_f1\n";
	
	open(INFILE1, "<$input_f1") or die ("Unable to open first file");
	
	while( 1 )  { 
		my $counter_1 = 0;
		my $sub_1 = "";
		my $sub_num_1 = <INFILE1>;
		$counter_1++;
		exit(-1) if not defined $sub_num_1;
		if ($sub_num_1 =~ /\d+\r?\n$/) {
			$sub_num_1 =~ s/\r?\n//g;
			my $timestamps_1 = <INFILE1>;
			$counter_1++;
			exit if not $timestamps_1;
			if ($timestamps_1 =~ /^(\d\d):(\d\d):(\d\d),(\d\d\d).*(\d\d):(\d\d):(\d\d),(\d\d\d)/) {
				while (1) {
					my $new_line = <INFILE1>;
					if (not $new_line) {
						print "$sub_1\n";
						exit(0);
					}
					$counter_1++;
					$new_line =~ s/^ *//g;
					$new_line =~ s/[\r\n]//g;
					last if $new_line eq "";
					$sub_1 .= " $new_line";
				}
				print "$sub_1\n";
			}
			else {
				print STDERR "ERROR: timestamps for subtitle $sub_num_1 not found. Line $counter_1\n";
				exit;
			}
		}
	}
}
