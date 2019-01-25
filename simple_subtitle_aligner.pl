use strict;
use warnings;

my $input_f1 = "";
my $input_f2 = "";
my $outfile_pref = "friends";
if ($#ARGV >= 0) {
	$input_f1 = $ARGV[0];
	$input_f2 = $ARGV[1];
	$outfile_pref = $ARGV[2];
	print "File is: $input_f1 and $input_f2\n";
	
	open(INFILE1, "<$input_f1") or die ("Unable to open first file");
	open(INFILE2, "<$input_f2") or die ("Unable to open second file");
	
	my $found_1;
	my $st_t_1;
	my $end_t_1;
	my $sub_1;
	my $found_2;
	my $st_t_2;
	my $end_t_2;
	my $sub_2;
	my $pairs_found = 0;
	
	($found_1, $st_t_1, $end_t_1, $sub_1) = find_next(1);
	die("pairs found: $pairs_found\n") if $found_1 == 0;
	($found_2, $st_t_2, $end_t_2, $sub_2) = find_next(2);
	die("pairs found: $pairs_found\n") if $found_2 == 0;
	
	while( 1 )  { 
		while ($end_t_1 < $st_t_2) {
			print "skipping $st_t_1:$end_t_1\n";
			($found_1, $st_t_1, $end_t_1, $sub_1) = find_next(1);
			last if $found_1 == 0;
		}
		while ($end_t_2 < $st_t_1) {
			print "skipping $st_t_2:$end_t_2\n";
			($found_2, $st_t_2, $end_t_2, $sub_2) = find_next(2);
			last if $found_2 == 0;
		}
		last if ($found_1 == 0 or $found_2 == 0);
		my $m_uni = union($st_t_1, $end_t_1, $st_t_2, $end_t_2);
		my $m_int = intersect($st_t_1, $end_t_1, $st_t_2, $end_t_2);
		#print "\n$st_t_1, $end_t_1, $st_t_2, $end_t_2, uni: $m_uni, inter: $m_int\n\n";
		
		if (1.0 * $m_int / $m_uni > 0.6) {
		#high intersection - saving
			#print "sub1 found. $st_t_1:$end_t_1 $sub_1\n";
			#print "sub2 found. $st_t_2:$end_t_2 $sub_2\n";
			open (MYFILE3, ">>$outfile_pref.ru"); 
			print MYFILE3 "$sub_1\n"; 
			close (MYFILE3);
			open (MYFILE4, ">>$outfile_pref.ab"); 
			print MYFILE4 "$sub_2\n"; 
			close (MYFILE4);
			$pairs_found++;
			
			($found_1, $st_t_1, $end_t_1, $sub_1) = find_next(1);
			last if $found_1 == 0;
			($found_2, $st_t_2, $end_t_2, $sub_2) = find_next(2);
			last if $found_2 == 0;
		}
		elsif ( $end_t_1 < $end_t_2 ) {
			#intersection is low and first sub ends earlier - try to get another sub1 and merge it with current
			my ($found__1, $st_t__1, $end_t__1, $sub__1) = find_next(1);
			last if $found__1 == 0;
			$m_uni = union($st_t_1, $end_t__1, $st_t_2, $end_t_2);
			$m_int = intersect($st_t_1, $end_t__1, $st_t_2, $end_t_2);
			
			if (1.0 * $m_int / $m_uni > 0.6) {
				#print "sub1 found. $st_t_1:$end_t_1 $sub_1 $sub__1\n";
				#print "sub2 found. $st_t_2:$end_t_2 $sub_2\n";
				open (MYFILE3, ">>$outfile_pref.ru"); 
				print MYFILE3 "$sub_1 $sub__1\n"; 
				close (MYFILE3);
				open (MYFILE4, ">>$outfile_pref.ab"); 
				print MYFILE4 "$sub_2\n"; 
				close (MYFILE4);
				$pairs_found++;
				
				($found_1, $st_t_1, $end_t_1, $sub_1) = find_next(1);
				last if $found_1 == 0;
				($found_2, $st_t_2, $end_t_2, $sub_2) = find_next(2);
				last if $found_2 == 0;
			}
			else {
				#check intersection of new sub__1 and sub_2
				$m_uni = union($st_t__1, $end_t__1, $st_t_2, $end_t_2);
				$m_int = intersect($st_t__1, $end_t__1, $st_t_2, $end_t_2);
				
				if (1.0 * $m_int / $m_uni > 0.6) {
					#print "sub1 found. $st_t__1:$end_t__1 $sub__1\n";
					#print "sub2 found. $st_t_2:$end_t_2 $sub_2\n";
					open (MYFILE3, ">>$outfile_pref.ru"); 
					print MYFILE3 "$sub__1\n"; 
					close (MYFILE3);
					open (MYFILE4, ">>$outfile_pref.ab"); 
					print MYFILE4 "$sub_2\n"; 
					close (MYFILE4);
					$pairs_found++;
					
					($found_1, $st_t_1, $end_t_1, $sub_1) = find_next(1);
					last if $found_1 == 0;
					($found_2, $st_t_2, $end_t_2, $sub_2) = find_next(2);
					last if $found_2 == 0;
				}
				elsif ( $end_t__1 > $end_t_2 ) {
					print "no correlation found for file 1 $st_t_1:$end_t__1 $sub_1 $sub__1 and file 2 $st_t_2:$end_t_2 $sub_2\n";
					($found_1, $st_t_1, $end_t_1, $sub_1) = ($found__1, $st_t__1, $end_t__1, $sub__1);
					($found_2, $st_t_2, $end_t_2, $sub_2) = find_next(2);
					last if $found_2 == 0;
				}
				else {
					print "skipping...";
					($found_2, $st_t_2, $end_t_2, $sub_2) = find_next(2);
					last if $found_2 == 0;
				}
			}
		}
		else { #
			#intersection is low and second sub ends earlier - try to get another sub2 and merge it with current
			my ($found__2, $st_t__2, $end_t__2, $sub__2) = find_next(2);
			last if $found__2 == 0;
			$m_uni = union($st_t_1, $end_t_1, $st_t_2, $end_t__2);
			$m_int = intersect($st_t_1, $end_t_1, $st_t_2, $end_t__2);
			
			if (1.0 * $m_int / $m_uni > 0.6) {
				#print "sub1 found. $st_t_1:$end_t_1 $sub_1\n";
				#print "sub2 found. $st_t_2:$end_t_2 $sub_2 $sub__2\n";
				open (MYFILE3, ">>$outfile_pref.ru"); 
				print MYFILE3 "$sub_1\n"; 
				close (MYFILE3);
				open (MYFILE4, ">>$outfile_pref.ab"); 
				print MYFILE4 "$sub_2 $sub__2\n"; 
				close (MYFILE4);
				$pairs_found++;
				
				($found_1, $st_t_1, $end_t_1, $sub_1) = find_next(1);
				last if $found_1 == 0;
				($found_2, $st_t_2, $end_t_2, $sub_2) = find_next(2);
				last if $found_2 == 0;
			}
			else {
				#check intersection of new sub__1 and sub_2
				$m_uni = union($st_t_1, $end_t_1, $st_t__2, $end_t__2);
				$m_int = intersect($st_t_1, $end_t_1, $st_t__2, $end_t__2);
				
				if (1.0 * $m_int / $m_uni > 0.6) {
					#print "sub1 found. $st_t_1:$end_t_1 $sub_1\n";
					#print "sub2 found. $st_t__2:$end_t__2 $sub__2\n";
					open (MYFILE3, ">>$outfile_pref.ru"); 
					print MYFILE3 "$sub_1\n"; 
					close (MYFILE3);
					open (MYFILE4, ">>$outfile_pref.ab"); 
					print MYFILE4 "$sub__2\n"; 
					close (MYFILE4);
					$pairs_found++;
					
					($found_1, $st_t_1, $end_t_1, $sub_1) = find_next(1);
					last if $found_1 == 0;
					($found_2, $st_t_2, $end_t_2, $sub_2) = find_next(2);
					last if $found_2 == 0;
				}
				elsif ( $end_t__2 > $end_t_1 ) {
					print "no correlation found for file 1 $st_t_1:$end_t_1 $sub_1 and file 2 $st_t_2:$end_t__2 $sub_2 $sub__2\n";
					($found_2, $st_t_2, $end_t_2, $sub_2) = ($found__2, $st_t__2, $end_t__2, $sub__2);
					($found_1, $st_t_1, $end_t_1, $sub_1) = find_next(1);
					last if $found_1 == 0;
				}
				else {
					print "skipping...";
					($found_1, $st_t_1, $end_t_1, $sub_1) = find_next(1);
					last if $found_1 == 0;
				}
			}
		}
	}
	print "pairs found: $pairs_found\n";
}

sub intersect {
	my $st_t_1 = shift;
	my $end_t_1 = shift;
	my $st_t_2 = shift;
	my $end_t_2 = shift;
	
	my $int_st = $st_t_1 > $st_t_2 ? $st_t_1 : $st_t_2;
	my $int_end = $end_t_1 < $end_t_2 ? $end_t_1 : $end_t_2;
	
	my $int_len = $int_end - $int_st;
	$int_len = $int_len > 0 ? $int_len : 0;
	
	return $int_len;
}

sub union {
	my $st_t_1 = shift;
	my $end_t_1 = shift;
	my $st_t_2 = shift;
	my $end_t_2 = shift;
	#print "\nuni:: $st_t_1, $end_t_1, $st_t_2, $end_t_2, \n";
	
	my $int_st = $st_t_1 < $st_t_2 ? $st_t_1 : $st_t_2;
	my $int_end = $end_t_1 > $end_t_2 ? $end_t_1 : $end_t_2;
	
	#print "\nuni::gap: $int_st, $int_end, \n";
	
	my $int_len = $int_end - $int_st;
	
	return $int_len;
}

#input is number of file: 1 or 2
sub find_next {
	my $file_num = shift; 
	if ($file_num == 1) {
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
	else {
		while( 1 )  { 
			my $counter_1 = 0;
			my $st_h_1 = 0;
			my $st_m_1 = 0;
			my $st_s_1 = 0;
			my $end_h_1 = 0;
			my $end_m_1 = 0;
			my $end_s_1 = 0;
			my $sub_1 = "";
			my $sub_num_1 = <INFILE2>;
			$counter_1++;
			return (0, 0, 0, 0) if not $sub_num_1;
			if ($sub_num_1 =~ /^\d+\r?\n$/) {
				my $timestamps_1 = <INFILE2>;
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
						my $new_line = <INFILE2>;
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
}
