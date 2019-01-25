use strict;
use warnings;

my $input_f1 = "";
my $move_secs = 0;
if ($#ARGV >= 0) {
	$input_f1 = $ARGV[0];
	$move_secs = int($ARGV[1]);
	#print "File is: $input_f1\n";
	
	open(INFILE1, "<$input_f1") or die ("Unable to open first file");
	
	my $found_1;
	my $st_t_1;
	my $end_t_1;
	my $sub_1;
	my $pairs_found = 0;
	
	while( 1 )  { 
		my $counter_1 = 0;
		my $st_h_1 = 0;
		my $st_m_1 = 0;
		my $st_s_1 = 0;
		my $end_h_1 = 0;
		my $end_m_1 = 0;
		my $end_s_1 = 0;
		my $sub_1 = "";
		my $sub_num_1 = <INFILE1>;
		#print "sub 1 num is $sub_num_1";
		$counter_1++;
		exit(-1) if not defined $sub_num_1;
		if ($sub_num_1 =~ /\d+\r?\n$/) {
			$sub_num_1 =~ s/\r?\n//g;
			my $timestamps_1 = <INFILE1>;
			$counter_1++;
			return (0, 0, 0, 0) if not $timestamps_1;
			if ($timestamps_1 =~ /^(\d\d):(\d\d):(\d\d),(\d\d\d).*(\d\d):(\d\d):(\d\d),(\d\d\d)/) {
				$st_h_1 = $1;
				$st_m_1 = $2;
				$st_s_1 = int($3) + $move_secs;
				my $st_msecs = $4;
				$end_h_1 = $5;
				$end_m_1 = $6;
				$end_s_1 = int($7) + $move_secs;
				my $end_msecs = $8;
				my $st_t_1 = ($st_h_1 * 60 + $st_m_1) * 60 + $st_s_1;
				my $end_t_1 = ($end_h_1 * 60 + $end_m_1) * 60 + $end_s_1;
				$sub_1 = "";
				
				my $st_min = int($st_t_1 / 60);
				my $end_min = int($end_t_1 / 60);
				my $st_s = $st_t_1 - $st_min * 60;
				my $end_s = $end_t_1 - $end_min * 60;
				my $st_h = int($st_min / 60);
				my $end_h = int($end_min / 60);
				$st_min = $st_min - $st_h * 60;
				$end_min = $end_min - $end_h * 60;
				$sub_1 = "";
				my $s_time = sprintf("%02d:%02d:%02d,%03d", $st_h, $st_min, $st_s, $st_msecs);
				my $e_time = sprintf("%02d:%02d:%02d,%03d", $end_h, $end_min, $end_s, $end_msecs);
				while (1) {
					my $new_line = <INFILE1>;
					if (not $new_line) {
						print "$sub_num_1\n$s_time --> $e_time\n$sub_1\n\n";
						exit(0);
					}
					$counter_1++;
					$new_line =~ s/^ *//g;
					$new_line =~ s/[\r\n]//g;
					last if $new_line eq "";
					$sub_1 .= " $new_line";
				}
				#print "sub found. $st_h_1:$st_m_1:$st_s_1 $sub_1\n";
				print "$sub_num_1\n$s_time --> $e_time\n$sub_1\n\n";
			}
			else {
				print "timestamps for subtitle $sub_num_1 not found. Line $counter_1\n";
				return (0, 0, 0, 0);
			}
		}
	}
}
