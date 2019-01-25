use strict;
use warnings;

#I have faced some strange subtitle type, where lines of text go after
# "{132}{235}" timestamps. On a closer examination it turned out that
# one timestamp divided by 24 is rime in seconds.
#I have converted such files with regexp "\{(.*)\}\{(.*)\}(.*)" 
# to "1\n\1 --> \2\n\3\n"  in Notepad++ and now I want to set correct 
#numeration and timestamps. 
my $input_f1 = "";
if ($#ARGV >= 0) {
	$input_f1 = $ARGV[0];
	#print "File is: $input_f1\n";
	
	open(INFILE1, "<$input_f1") or die ("Unable to open first file");
	
	my $counter_1 = 0;
	my $sub_1 = "";
	while(1) {
		my $sub_num_1 = <INFILE1>;
		#print "sub 1 num is $sub_num_1";
		$counter_1++;
		exit(-1) if not $sub_num_1;
		if ($sub_num_1 =~ /\d+\r?\n$/) {
			my $timestamps_1 = <INFILE1>;
			exit(-5) if not $timestamps_1;
			if ($timestamps_1 =~ /^(\d+) --> (\d+)\r?\n/) {
				my $start__ = $1;
				my $end__ = $2;
				my $st_s = int($start__ / 24);
				my $end_s = int($end__ / 24);
				my $st_min = int($st_s / 60);
				my $end_min = int($end_s / 60);
				$st_s = $st_s - $st_min * 60;
				$end_s = $end_s - $end_min * 60;
				my $st_h = int($st_min / 60);
				my $end_h = int($end_min / 60);
				$st_min = $st_min - $st_h * 60;
				$end_min = $end_min - $end_h * 60;
				$sub_1 = "";
				my $s_time = sprintf("%02d:%02d:%02d,000", $st_h, $st_min, $st_s);
				my $e_time = sprintf("%02d:%02d:%02d,000", $end_h, $end_min, $end_s);
				while (1) {
					my $new_line = <INFILE1>;
					#print here if eof
					if (not $new_line) {
						print "$counter_1\n$s_time --> $e_time\n$sub_1\n\n";
						exit(0);
					}
					$new_line =~ s/^ *//g;
					$new_line =~ s/[\r\n]//g;
					last if $new_line eq "";
					$sub_1 .= " $new_line";
				}
				
				print "$counter_1\n$s_time --> $e_time\n$sub_1\n\n";
			}
			else {
				print "timestamps for subtitle $sub_num_1 not found. Line $counter_1\n\n";
				exit(-3);
			}
		}
	}
}

