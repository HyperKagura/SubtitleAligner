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
	open(INFILE1, "<:utf8","$input_f1") or die ("Unable to open first file");
	open(INFILE2, "<$input_f2") or die ("Unable to open second file");
	
	my $m_thres = 9;
	my @gaps_1 = get_gaps($m_thres, 1);
	exit(-5) if !@gaps_1;
	my @gaps_2 = get_gaps($m_thres, 2);
	exit(-5) if !@gaps_2;
	my @result_gaps;
	
	my $end_time_1 = pop @gaps_1;
	my $end_time_2 = pop @gaps_2;
	if (abs($end_time_1 - $end_time_2) <= 10) {
		print "no gap align needed - alike lengthes\n";
	}
	else {
		print "aligning_gaps...\n";
		my @aligner_input;
		while (1) {
			my $time_val_1 = shift @gaps_1;
			my $time_val_2 = shift @gaps_2;
			last if (not defined $time_val_1) and (not defined $time_val_2);
			if (not defined $time_val_1) {
				push @aligner_input, 0;
				push @aligner_input, 0;
			}
			else {
				my $gap_len_1 = shift @gaps_1;
				push @aligner_input, $gap_len_1;
				push @aligner_input, $time_val_1;
			}
			if (not defined $time_val_2) {
				push @aligner_input, 0;
				push @aligner_input, 0;
			}
			else {
				my $gap_len_2 = shift @gaps_2;
				push @aligner_input, $gap_len_2;
				push @aligner_input, $time_val_2;
			}
		}
		my $input_len = @aligner_input;
		@result_gaps = gap_aligner($end_time_1 - $end_time_2, @aligner_input);
		my $output_len = @result_gaps;
		die("no gaps aligned\n") if $output_len == 0;
		die("too few aligns\n") if ($input_len / 2 / $output_len > 1.3);
			
		print "gap aligning done\n";
	}
	
	close(INFILE1);
	close(INFILE2);
	#exit(0);
	
	
	#align subs
	open(INFILE1, "<:utf8", "$input_f1") or die ("Unable to open first file");
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
	my $gap_x1;
	my $gap_k = 1;
	my $gap_x0;
	my $gap_1_start = 0;
	my $gap_2_start = 0;
	
	$gap_x0 = $gap_1_start;
	$gap_x1 = $gap_2_start;
	$gap_1_start = shift @result_gaps;
	$gap_2_start = shift @result_gaps;
	#transform 2 file to match 1
	if (defined $gap_2_start) {
		$gap_k = ($gap_1_start - $gap_x0) / ($gap_2_start - $gap_x1);
	}
	
	
	($found_1, $st_t_1, $end_t_1, $sub_1) = find_next(1);
	die("pairs found: $pairs_found\n") if $found_1 == 0;
	if (defined $gap_1_start) {
		while ($st_t_1 < $gap_1_start) {
			print "gap skipping first file $st_t_1:$end_t_1\n";
			($found_1, $st_t_1, $end_t_1, $sub_1) = find_next(1);
			die("pairs found: $pairs_found\n") if $found_1 == 0;
		}
		$gap_x0 = $gap_1_start;
		$gap_x1 = $gap_2_start;
		$gap_1_start = shift @result_gaps;
		$gap_2_start = shift @result_gaps;
		#transform 2 file to match 1
		if (defined $gap_2_start) {
			$gap_k = ($gap_1_start - $gap_x0) / ($gap_2_start - $gap_x1);
		}
	}
	($found_2, $st_t_2, $end_t_2, $sub_2) = find_next(2, $gap_x1, $gap_k, $gap_x0);
	die("pairs found: $pairs_found\n") if $found_2 == 0;
	
	while( 1 )  { 
		while ($end_t_1 < $st_t_2) {
			print "skipping first file $st_t_1:$end_t_1\n";
			($found_1, $st_t_1, $end_t_1, $sub_1) = find_next(1);
			last if $found_1 == 0;
			if (defined $gap_1_start) {
				if ($st_t_1 > $gap_1_start) {
					$gap_x0 = $gap_1_start;
					$gap_x1 = $gap_2_start;
					$gap_1_start = shift @result_gaps;
					$gap_2_start = shift @result_gaps;
					#transform 2 file to match 1
					if (defined $gap_2_start) {
						$gap_k = ($gap_1_start - $gap_x0) / ($gap_2_start - $gap_x1);
					}
				}
			}
		}
		while ($end_t_2 < $st_t_1) {
			print "skipping second file $st_t_2:$end_t_2\n";
			($found_2, $st_t_2, $end_t_2, $sub_2) = find_next(2, $gap_x1, $gap_k, $gap_x0);
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
			open (MYFILE3, ">>:utf8", "$outfile_pref.ru"); 
			print MYFILE3 "$sub_1\n"; 
			close (MYFILE3);
			open (MYFILE4, ">>$outfile_pref.ab"); 
			print MYFILE4 "$sub_2\n"; 
			close (MYFILE4);
			$pairs_found++;
			
			($found_1, $st_t_1, $end_t_1, $sub_1) = find_next(1);
			last if $found_1 == 0;
			if (defined $gap_1_start) {
				if ($st_t_1 > $gap_1_start) {
					$gap_x0 = $gap_1_start;
					$gap_x1 = $gap_2_start;
					$gap_1_start = shift @result_gaps;
					$gap_2_start = shift @result_gaps;
					#transform 2 file to match 1
					if (defined $gap_2_start) {
						$gap_k = ($gap_1_start - $gap_x0) / ($gap_2_start - $gap_x1);
					}
				}
			}
			($found_2, $st_t_2, $end_t_2, $sub_2) = find_next(2, $gap_x1, $gap_k, $gap_x0);
			last if $found_2 == 0;
		}
		elsif ( $end_t_1 < $end_t_2 ) {
			#intersection is low and first sub ends earlier - try to get another sub1 and merge it with current
			my ($found__1, $st_t__1, $end_t__1, $sub__1) = find_next(1);
			last if $found__1 == 0;
			if (defined $gap_1_start) {
				if ($st_t__1 > $gap_1_start) {
					$gap_x0 = $gap_1_start;
					$gap_x1 = $gap_2_start;
					$gap_1_start = shift @result_gaps;
					$gap_2_start = shift @result_gaps;
					#transform 2 file to match 1
					if (defined $gap_2_start) {
						$gap_k = ($gap_1_start - $gap_x0) / ($gap_2_start - $gap_x1);
					}
				}
			}
			$m_uni = union($st_t_1, $end_t__1, $st_t_2, $end_t_2);
			$m_int = intersect($st_t_1, $end_t__1, $st_t_2, $end_t_2);
			
			if (1.0 * $m_int / $m_uni > 0.6) {
				#print "sub1 found. $st_t_1:$end_t_1 $sub_1 $sub__1\n";
				#print "sub2 found. $st_t_2:$end_t_2 $sub_2\n";
				open (MYFILE3, ">>:utf8", "$outfile_pref.ru"); 
				print MYFILE3 "$sub_1 $sub__1\n"; 
				close (MYFILE3);
				open (MYFILE4, ">>$outfile_pref.ab"); 
				print MYFILE4 "$sub_2\n"; 
				close (MYFILE4);
				$pairs_found++;
				
				($found_1, $st_t_1, $end_t_1, $sub_1) = find_next(1);
				last if $found_1 == 0;
				if (defined $gap_1_start) {
					if ($st_t_1 > $gap_1_start) {
						$gap_x0 = $gap_1_start;
						$gap_x1 = $gap_2_start;
						$gap_1_start = shift @result_gaps;
						$gap_2_start = shift @result_gaps;
						#transform 2 file to match 1
						if (defined $gap_2_start) {
							$gap_k = ($gap_1_start - $gap_x0) / ($gap_2_start - $gap_x1);
						}
					}
				}
				($found_2, $st_t_2, $end_t_2, $sub_2) = find_next(2, $gap_x1, $gap_k, $gap_x0);
				last if $found_2 == 0;
			}
			else {
				#check intersection of new sub__1 and sub_2
				$m_uni = union($st_t__1, $end_t__1, $st_t_2, $end_t_2);
				$m_int = intersect($st_t__1, $end_t__1, $st_t_2, $end_t_2);
				
				if (1.0 * $m_int / $m_uni > 0.6) {
					#print "sub1 found. $st_t__1:$end_t__1 $sub__1\n";
					#print "sub2 found. $st_t_2:$end_t_2 $sub_2\n";
					open (MYFILE3, ">>:utf8", "$outfile_pref.ru"); 
					print MYFILE3 "$sub__1\n"; 
					close (MYFILE3);
					open (MYFILE4, ">>$outfile_pref.ab"); 
					print MYFILE4 "$sub_2\n"; 
					close (MYFILE4);
					$pairs_found++;
					
					($found_1, $st_t_1, $end_t_1, $sub_1) = find_next(1);
					last if $found_1 == 0;
					if (defined $gap_1_start) {
						if ($st_t_1 > $gap_1_start) {
							$gap_x0 = $gap_1_start;
							$gap_x1 = $gap_2_start;
							$gap_1_start = shift @result_gaps;
							$gap_2_start = shift @result_gaps;
							#transform 2 file to match 1
							if (defined $gap_2_start) {
								$gap_k = ($gap_1_start - $gap_x0) / ($gap_2_start - $gap_x1);
							}
						}
					}
					($found_2, $st_t_2, $end_t_2, $sub_2) = find_next(2, $gap_x1, $gap_k, $gap_x0);
					last if $found_2 == 0;
				}
				elsif ( $end_t__1 > $end_t_2 ) {
					print "no correlation found for file 1 $st_t_1:$end_t__1 $sub_1 $sub__1 and file 2 $st_t_2:$end_t_2 $sub_2\n";
					($found_1, $st_t_1, $end_t_1, $sub_1) = ($found__1, $st_t__1, $end_t__1, $sub__1);
					($found_2, $st_t_2, $end_t_2, $sub_2) = find_next(2, $gap_x1, $gap_k, $gap_x0);
					last if $found_2 == 0;
				}
				else {
					print "skipping first file $st_t_1:$end_t__1 and second file $st_t_2:$end_t_2\n";
					($found_2, $st_t_2, $end_t_2, $sub_2) = find_next(2, $gap_x1, $gap_k, $gap_x0);
					last if $found_2 == 0;
				}
			}
		}
		else { #
			#intersection is low and second sub ends earlier - try to get another sub2 and merge it with current
			my ($found__2, $st_t__2, $end_t__2, $sub__2) = find_next(2, $gap_x1, $gap_k, $gap_x0);
			last if $found__2 == 0;
			$m_uni = union($st_t_1, $end_t_1, $st_t_2, $end_t__2);
			$m_int = intersect($st_t_1, $end_t_1, $st_t_2, $end_t__2);
			
			if (1.0 * $m_int / $m_uni > 0.6) {
				#print "sub1 found. $st_t_1:$end_t_1 $sub_1\n";
				#print "sub2 found. $st_t_2:$end_t_2 $sub_2 $sub__2\n";
				open (MYFILE3, ">>:utf8", "$outfile_pref.ru"); 
				print MYFILE3 "$sub_1\n"; 
				close (MYFILE3);
				open (MYFILE4, ">>$outfile_pref.ab"); 
				print MYFILE4 "$sub_2 $sub__2\n"; 
				close (MYFILE4);
				$pairs_found++;
				
				($found_1, $st_t_1, $end_t_1, $sub_1) = find_next(1);
				last if $found_1 == 0;
				if (defined $gap_1_start) {
					if ($st_t_1 > $gap_1_start) {
						$gap_x0 = $gap_1_start;
						$gap_x1 = $gap_2_start;
						$gap_1_start = shift @result_gaps;
						$gap_2_start = shift @result_gaps;
						#transform 2 file to match 1
						if (defined $gap_2_start) {
							$gap_k = ($gap_1_start - $gap_x0) / ($gap_2_start - $gap_x1);
						}
					}
				}
				($found_2, $st_t_2, $end_t_2, $sub_2) = find_next(2, $gap_x1, $gap_k, $gap_x0);
				last if $found_2 == 0;
			}
			else {
				#check intersection of new sub__1 and sub_2
				$m_uni = union($st_t_1, $end_t_1, $st_t__2, $end_t__2);
				$m_int = intersect($st_t_1, $end_t_1, $st_t__2, $end_t__2);
				
				if (1.0 * $m_int / $m_uni > 0.6) {
					#print "sub1 found. $st_t_1:$end_t_1 $sub_1\n";
					#print "sub2 found. $st_t__2:$end_t__2 $sub__2\n";
					open (MYFILE3, ">>:utf8", "$outfile_pref.ru"); 
					print MYFILE3 "$sub_1\n"; 
					close (MYFILE3);
					open (MYFILE4, ">>$outfile_pref.ab"); 
					print MYFILE4 "$sub__2\n"; 
					close (MYFILE4);
					$pairs_found++;
					
					($found_1, $st_t_1, $end_t_1, $sub_1) = find_next(1);
					last if $found_1 == 0;
					if (defined $gap_1_start) {
						if ($st_t_1 > $gap_1_start) {
							$gap_x0 = $gap_1_start;
							$gap_x1 = $gap_2_start;
							$gap_1_start = shift @result_gaps;
							$gap_2_start = shift @result_gaps;
							#transform 2 file to match 1
							if (defined $gap_2_start) {
								$gap_k = ($gap_1_start - $gap_x0) / ($gap_2_start - $gap_x1);
							}
						}
					}
					($found_2, $st_t_2, $end_t_2, $sub_2) = find_next(2, $gap_x1, $gap_k, $gap_x0);
					last if $found_2 == 0;
				}
				elsif ( $end_t__2 > $end_t_1 ) {
					print "no correlation found for file 1 $st_t_1:$end_t_1 $sub_1 and file 2 $st_t_2:$end_t__2 $sub_2 $sub__2\n";
					($found_2, $st_t_2, $end_t_2, $sub_2) = ($found__2, $st_t__2, $end_t__2, $sub__2);
					($found_1, $st_t_1, $end_t_1, $sub_1) = find_next(1);
					last if $found_1 == 0;
					if (defined $gap_1_start) {
						if ($st_t_1 > $gap_1_start) {
							$gap_x0 = $gap_1_start;
							$gap_x1 = $gap_2_start;
							$gap_1_start = shift @result_gaps;
							$gap_2_start = shift @result_gaps;
							#transform 2 file to match 1
							if (defined $gap_2_start) {
								$gap_k = ($gap_1_start - $gap_x0) / ($gap_2_start - $gap_x1);
							}
						}
					}
				}
				else {
					print "skipping file 1 $st_t_1:$end_t_1 and file 2 $st_t_2:$end_t__2...";
					($found_1, $st_t_1, $end_t_1, $sub_1) = find_next(1);
					last if $found_1 == 0;
					if (defined $gap_1_start) {
						if ($st_t_1 > $gap_1_start) {
							$gap_x0 = $gap_1_start;
							$gap_x1 = $gap_2_start;
							$gap_1_start = shift @result_gaps;
							$gap_2_start = shift @result_gaps;
							#transform 2 file to match 1
							if (defined $gap_2_start) {
								$gap_k = ($gap_1_start - $gap_x0) / ($gap_2_start - $gap_x1);
							}
						}
					}
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

#input is a threshold and a number of file: 1 or 2
#output is not defined if no subs found; [gap_start,gap_end,gap_start,gap_end,..,last_sub_end_time]
sub get_gaps {
	my $threshold = shift;
	my $f_num = shift;
	print "f_num is: $f_num\n";
	
	my $found_1;
	my $st_t_1;
	my $end_t_1;
	my $sub_1;
	
	my @ret_list;
	
	($found_1, $st_t_1, $end_t_1, $sub_1) = find_next($f_num);
	return (@ret_list) if $found_1 == 0;
	my $longest_pause = 0;
	my $last_end = 0;
	my $last_end_t = $end_t_1;

	my $diff = $st_t_1 - $last_end;
	if ($diff > $threshold) {
		print "long start: $diff\n";
	}
	
	while( 1 )  { 
		$last_end = $end_t_1;
		($found_1, $st_t_1, $end_t_1, $sub_1) = find_next($f_num);
		last if ($found_1 == 0);
		$last_end_t = $end_t_1;
		$diff = $st_t_1 - $last_end;
		if ($diff > $threshold) {
			push @ret_list, $st_t_1;
			push @ret_list, $diff;
			print "pause before: $st_t_1 sec, length is: $diff sec\n";
		}
	}
	push @ret_list, $last_end_t;
	return @ret_list;
}

#input is an array of form expected_time_gap,[gap1_1, time1_1, gap2_1, time2_1, gap1_2, time1_2, 
#			gap2_2, time2_2, gap1_3, time1_3, gap2_3, time2_3,..]
#where expected_time_gap is expected first_list_time - second_list_time;
#gap1_* are lengthes of gaps in gap_1 list, gap2_* are lengthes of gaps in gap_2 list;
#lists are of equal length, so put zeros where needed.
#returns an array of pairs of times for aligned gaps [a_time1_1, atime2_1, atime1_2, 
#			atime2_2,..]
sub gap_aligner {
	my $exp_t_diff = shift;
	my @ret_list;
	my @first_list;
	my @first_times;
	my @second_list;
	my @second_times;
	my $next_elem = shift;
	return @ret_list if not defined $next_elem;
	my $largest = $next_elem;
	my $is_in_first = 1;
	my $i = 0;
	my $row_counter = 0;
	my $m_time = shift;
	push @first_list, $next_elem;
	push @first_times, $m_time;
	$next_elem = shift;
	$m_time = shift;
	push @second_list, $next_elem;
	push @second_times, $m_time;
	if ($largest < $next_elem) {
		$largest = $next_elem;
		$is_in_first = 0;
	}
	$row_counter++;
	while (1) {
		$next_elem = shift;
		last if ! defined $next_elem;
		$m_time = shift;
		push @first_list, $next_elem;
		push @first_times, $m_time;
		if ($largest < $next_elem) {
			$largest = $next_elem;
			$is_in_first = 1;
			$i = $row_counter;
		}
		$next_elem = shift;
		$m_time = shift;
		push @second_list, $next_elem;
		push @second_times, $m_time;
		if ($largest < $next_elem) {
			$largest = $next_elem;
			$is_in_first = 0;
			$i = $row_counter;
		}
		$row_counter++;
	}
	#print "input array length is: $row_counter\n";
	#print "first gaps: @first_list\n";
	#print "second gaps: @second_list\n";
	return @ret_list if $largest == 0;
	if ($is_in_first) {
		my $align_i = 0;
		#my $gap_penalty = 1; #"percent of difference in length" -> the worst is 100% => 1
		#my $time_penalty = 36000; #10 hours -> potential max_len
		my $res_penalty = 36000; #$gap_penalty * $time_penalty
		if ($second_list[$i] != 0) {
			if ($largest / $second_list[$i] < 1.2) {
				$align_i = $i;
				my $g_pen = ($largest - $second_list[$i]) / $largest;
				my $t_pen = abs($exp_t_diff - ($first_times[$i] - $second_times[$i]));
				$res_penalty = $g_pen * $t_pen;
			}
		}
		if ($i != 0) { #check one before
			if ($second_list[$i-1] != 0) {
				if ($largest / $second_list[$i-1] < 1.2) {
					my $g_pen = ($largest - $second_list[$i-1]) / $largest;
					my $t_pen = abs($exp_t_diff - ($first_times[$i] - $second_times[$i-1]));
					if ($res_penalty > $g_pen * $t_pen) {
						$align_i = $i-1;
						$res_penalty = $g_pen * $t_pen;
					}
				}
			}
		}
		if ($i < $row_counter - 1) { #check one after
			if ($second_list[$i+1] != 0) {
				if ($largest / $second_list[$i+1] < 1.2) {
					my $g_pen = ($largest - $second_list[$i+1]) / $largest;
					my $t_pen = abs($exp_t_diff - ($first_times[$i] - $second_times[$i+1]));
					if ($res_penalty > $g_pen * $t_pen) {
						$align_i = $i+1;
						$res_penalty = $g_pen * $t_pen;
					}
				}
			}
		}
		return @ret_list if $res_penalty == 36000;
		if ($i > 0) {
			#get upper part
			my $upper_exp_diff = int(($exp_t_diff + $first_times[$i] - $second_times[$align_i]) / 2);
			my @upper_input;
			my $counter = 0;
			while ($counter < $i-1) {
				push @upper_input, $first_list[$counter];
				push @upper_input, $first_times[$counter];
				push @upper_input, $second_list[$counter];
				push @upper_input, $second_times[$counter];
				$counter++;
			}
			#$counter++ is i-1;
			push @upper_input, $first_list[$counter];
			push @upper_input, $first_times[$counter];
			if ($align_i < $i) {
				push @upper_input, 0;
				push @upper_input, 0;
			}
			elsif ($align_i == $i) {
				push @upper_input, $second_list[$counter];
				push @upper_input, $second_times[$counter];
			}
			else { # $align_i > $i
				push @upper_input, $second_list[$counter];
				push @upper_input, $second_times[$counter];
				push @upper_input, 0;
				push @upper_input, 0;
				push @upper_input, $second_list[$i];
				push @upper_input, $second_times[$i];
			}
			@ret_list = gap_aligner($upper_exp_diff, @upper_input);
			#print "upper l: $upper_exp_diff; @upper_input\n";
		}
		print "$largest to $second_list[$align_i]; $first_times[$i] to $second_times[$align_i];\ti: $i, align_i: $align_i; rows: $row_counter\n";
		push @ret_list, $first_times[$i];
		push @ret_list, $second_times[$align_i];
		if ($i < $row_counter - 1) {
			#get lower part
			my $counter = $i + 1;
			#$counter++ is i+1
			return @ret_list if $counter >= $row_counter;
			my $lower_exp_diff = $first_times[$i] - $second_times[$align_i];
			my @lower_input;
			if ($align_i < $i) {
				push @lower_input, 0;
				push @lower_input, 0;
				push @lower_input, $second_list[$i];
				push @lower_input, $second_times[$i];
			}
			push @lower_input, $first_list[$counter];
			push @lower_input, $first_times[$counter];
			if ($align_i > $i) {
				push @lower_input, 0;
				push @lower_input, 0;
			}
			else {
				push @lower_input, $second_list[$counter];
				push @lower_input, $second_times[$counter];
			}
			$counter++;
			while ($counter < $row_counter) {
				push @lower_input, $first_list[$counter];
				push @lower_input, $first_times[$counter];
				push @lower_input, $second_list[$counter];
				push @lower_input, $second_times[$counter];
				$counter++;
			}
			#print "lower l: $lower_exp_diff; @lower_input\n";
			push @ret_list, gap_aligner($lower_exp_diff, @lower_input);
		}
		return @ret_list;
	}
	else {
		my $align_i = 0;
		#my $gap_penalty = 1; #"percent of difference in length" -> the worst is 100% => 1
		#my $time_penalty = 36000; #10 hours -> potential max_len
		my $res_penalty = 36000; #$gap_penalty * $time_penalty
		if ($first_list[$i] != 0) {
			if ($largest / $first_list[$i] < 1.2) {
				$align_i = $i;
				my $g_pen = ($largest - $first_list[$i]) / $largest;
				my $t_pen = abs($exp_t_diff - ($first_times[$i] - $second_times[$i]));
				$res_penalty = $g_pen * $t_pen;
			}
		}
		if ($i != 0) { #check one before
			if ($first_list[$i-1] != 0) {
				if ($largest / $first_list[$i-1] < 1.2) {
					my $g_pen = ($largest - $first_list[$i-1]) / $largest;
					my $t_pen = abs($exp_t_diff - ($first_times[$i-1] - $second_times[$i]));
					if ($res_penalty > $g_pen * $t_pen) {
						$align_i = $i-1;
						$res_penalty = $g_pen * $t_pen;
					}
				}
			}
		}
		if ($i < $row_counter - 1) { #check one after
			if ($first_list[$i+1] != 0) {
				if ($largest / $first_list[$i+1] < 1.2) {
					my $g_pen = ($largest - $first_list[$i+1]) / $largest;
					my $t_pen = abs($exp_t_diff - ($first_times[$i+1] - $second_times[$i]));
					if ($res_penalty > $g_pen * $t_pen) {
						$align_i = $i+1;
						$res_penalty = $g_pen * $t_pen;
					}
				}
			}
		}
		return @ret_list if $res_penalty == 36000;
		if ($i > 0) {
			#get upper aligns
			my $upper_exp_diff = int(($exp_t_diff + $first_times[$align_i] - $second_times[$i]) / 2);
			my @upper_input;
			my $counter = 0;
			while ($counter < $i-1) {
				push @upper_input, $first_list[$counter];
				push @upper_input, $first_times[$counter];
				push @upper_input, $second_list[$counter];
				push @upper_input, $second_times[$counter];
				$counter++;
			}
			#$counter is i-1
			if ($align_i < $i) {
				push @upper_input, 0;
				push @upper_input, 0;
			}
			else {
				push @upper_input, $first_list[$counter];
				push @upper_input, $first_times[$counter];
			}
			push @upper_input, $second_list[$counter];
			push @upper_input, $second_times[$counter];
			if ($align_i > $i) {
				push @upper_input, $first_list[$i];
				push @upper_input, $first_times[$i];
				push @upper_input, 0;
				push @upper_input, 0;
			}
			@ret_list = gap_aligner($upper_exp_diff, @upper_input);
			#print "upper r: $upper_exp_diff; @upper_input\n";
		}
		print "$first_list[$align_i] to $largest; $first_times[$align_i] to $second_times[$i];\ti: $i, align_i: $align_i; rows: $row_counter\n";
		push @ret_list, $first_times[$align_i];
		push @ret_list, $second_times[$i];
		if ($i < $row_counter - 1) {
			#get lower part
			my $counter = $i + 1;
			#$counter++ is i+1
			return @ret_list if $counter >= $row_counter;
			my $lower_exp_diff = $first_times[$align_i] - $second_times[$i];
			my @lower_input;
			if ($align_i < $i) {
				push @lower_input, $first_list[$i];
				push @lower_input, $first_times[$i];
				push @lower_input, 0;
				push @lower_input, 0;
			}
			if ($align_i > $i) {
				push @lower_input, 0;
				push @lower_input, 0;
			}
			else {
				push @lower_input, $first_list[$counter];
				push @lower_input, $first_times[$counter];
			}
			push @lower_input, $second_list[$counter];
			push @lower_input, $second_times[$counter];
			
			$counter++;
			while ($counter < $row_counter) {
				push @lower_input, $first_list[$counter];
				push @lower_input, $first_times[$counter];
				push @lower_input, $second_list[$counter];
				push @lower_input, $second_times[$counter];
				$counter++;
			}
			#print "lower r: $lower_exp_diff; @lower_input\n";
			push @ret_list, gap_aligner($lower_exp_diff, @lower_input);
		}
		return @ret_list;
	}
}

#linear time axes transformation
sub time_transform {
	my $timestamp = shift;
	my $x1 = shift;
	my $k = shift;
	my $x0 = shift;
	return ($timestamp - $x1) * $k + $x0;
}

#input is number of file: 1 or 2
sub find_next {
	my $file_num = shift; 
	#these three are coefficients for linear timestamp transform 
	#and are used to project one time gap to another. the math behind is:
	#	returned_timestamp = (timestamp - x1)*k + x0
	#	x1 is a start of current gap,
	#	k is a coefficient, k = (length of gap to transform to) / (length of current gap)
	#	x0 is a start of gap to transform to.
	my $x1 = shift;
	my $k = shift;
	my $x0 = shift;
	$x1 = 0 if not defined $x1;
	$k = 1 if not defined $k;
	$x0 = 0 if not defined $x0;
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
					$st_t_1 = time_transform($st_t_1, $x1, $k, $x0);
					my $end_t_1 = ($end_h_1 * 60 + $end_m_1) * 60 + $end_s_1;
					$end_t_1 = time_transform($end_t_1, $x1, $k, $x0);
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
					$st_t_1 = time_transform($st_t_1, $x1, $k, $x0);
					my $end_t_1 = ($end_h_1 * 60 + $end_m_1) * 60 + $end_s_1;
					$end_t_1 = time_transform($end_t_1, $x1, $k, $x0);
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
