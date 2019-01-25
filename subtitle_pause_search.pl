use strict;
use warnings;

my $input_f1 = "";
my $threshold = 0;
if ($#ARGV >= 0) {
	$input_f1 = $ARGV[0];
	$threshold = int($ARGV[1]);
	print "File is: $input_f1\n";
	
	open(INFILE1, "<$input_f1") or die ("Unable to open first file");
	
	my $found_1;
	my $st_t_1;
	my $end_t_1;
	my $sub_1;
	
	($found_1, $st_t_1, $end_t_1, $sub_1) = find_next();
	die("no subs\n") if $found_1 == 0;
	my $longest_pause = 0;
	my $last_end = 0;

	my $diff = $st_t_1 - $last_end;
	if ($diff > $threshold) {
		print "long start: $diff\n";
	}
	
	while( 1 )  { 
		$last_end = $end_t_1;
		($found_1, $st_t_1, $end_t_1, $sub_1) = find_next();
		last if ($found_1 == 0);
		$diff = $st_t_1 - $last_end;
		if ($diff > $threshold) {
			print "pause before: $st_t_1 sec, length is: $diff sec\n";
		}
	}
}

sub find_next {
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
		return (0, 0, 0, 0) if not $sub_num_1;
		if ($sub_num_1 =~ /\d+\r?\n$/) {
			my $timestamps_1 = <INFILE1>;
			$counter_1++;
			return (0, 0, 0, 0) if not $timestamps_1;
			if ($timestamps_1 =~ /^(\d\d):(\d\d):(\d\d),\d\d\d.*(\d\d):(\d\d):(\d\d),\d\d\d/) {
				$st_h_1 = $1;
				$st_m_1 = $2;
				$st_s_1 = $3;
				$end_h_1 = $4;
				$end_m_1 = $5;
				$end_s_1 = $6;
				my $st_t_1 = ($st_h_1 * 60 + $st_m_1) * 60 + $st_s_1;
				my $end_t_1 = ($end_h_1 * 60 + $end_m_1) * 60 + $end_s_1;
				$sub_1 = "";
				while (1) {
					my $new_line = <INFILE1>;
					return (1, $st_t_1, $end_t_1, $sub_1) if not $new_line;
					$counter_1++;
					$new_line =~ s/^ *//g;
					$new_line =~ s/[\r\n]//g;
					last if $new_line eq "";
					$sub_1 .= " $new_line";
				}
				#print "sub found. $st_h_1:$st_m_1:$st_s_1 $sub_1\n";
				return (1, $st_t_1, $end_t_1, $sub_1);
			}
			else {
				print "timestamps for subtitle $sub_num_1 not found. Line $counter_1\n";
				return (0, 0, 0, 0);
			}
		}
	}
}
