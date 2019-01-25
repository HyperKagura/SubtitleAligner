use strict;
use warnings;
use Hash::Ordered;

my $sliding_w_size = 50;

my $input_f1 = "";
my $input_f2 = "";
my $out_corp_name = "";
my $output_counter = 0;
if ($#ARGV >= 0) {
	$input_f1 = $ARGV[0];
	$input_f2 = $ARGV[1];
	$out_corp_name = $ARGV[2];
	print "Files are: $input_f1 and $input_f2\n";
	
	#open(INFILE1, "<$input_f1") or die ("Unable to open first file");
	#open(INFILE2, "<$input_f2") or die ("Unable to open second file");
	my $ru_hash;
	my $ara_hash;
	if ($input_f1 =~ /RUS_BT/) {
		$ru_hash = get_pairs($input_f1, "RUS");
		$ara_hash = get_pairs($input_f2, "ARA");
	}
	else {
		$ara_hash = get_pairs($input_f1, "ARA");
		$ru_hash = get_pairs($input_f2, "RUS");
	}
	
	my $prev_key = "";
	my $prev_val = "";
	my $key;
	my $value;
	my $ru_key;
	my $ru_value;
	my $window_next = $ru_hash->iterator;
	my $window_hash = Hash::Ordered->new;
	my $m_count = 0;
	#put first n lines in window
	while (($ru_key, $ru_value) = $window_next->()) {
		last if (! defined $ru_key);
		$window_hash->push($ru_key => $ru_value);
		$m_count++;
		last if ($m_count >= $sliding_w_size);
	}
	
	#my $window_start = $ru_hash->iterator;
	while (1) {
		($key, $value) = $ara_hash->shift;
		last if (! defined $key);
		#print "$key\n$value\n\n";
		if ($prev_key ne "") {
			#merge and check
			#print "merging $prev_key and $key\n";
			my $merged_key = $prev_key . " " . $key;
			$merged_key =~ s/  / /gs;
			my $merged_val = $prev_val . " " . $value;
			$merged_val =~ s/  / /gs;
			my $iter = $window_hash->iterator;
			my $counter = 0;
			while (($ru_key, $ru_value) = $iter->()) {
				#print "\tru_key: $ru_key\n";
				if ($ru_key eq $merged_key) {
					$output_counter++;
					open (MYFILE1, ">>$out_corp_name.ab"); 
					print MYFILE1 "$merged_val\n";
					close (MYFILE1);
					open (MYFILE2, ">>$out_corp_name.ru"); 
					print MYFILE2 "$ru_value\n";
					close (MYFILE2);
					#print "found ru: $ru_value\nara: $merged_val\n\n";
					$prev_key = "";
					$prev_val = "";
					#throw away all of the previous lines from the window
					#and append new lines from document
					while (my ($ru_k, $ru_v) = $window_hash->shift ) {
						my ($new_ru_k, $new_ru_v) = $window_next->();
						if (defined $new_ru_k) {
							$window_hash->push($new_ru_k => $new_ru_v);
						}
						last if ($ru_k eq $ru_key);
					}
					last;
				} else {
					$counter++;
					last if ($counter >= $sliding_w_size);
				}
			}
			next if ($counter < $sliding_w_size);
			#print "search didn't find anything\n\n";
			$prev_key = "";
			$prev_val = "";
			#$window_hash->shift;
			#($ru_key, $ru_value) = $window_next->();
			#last if (! defined $ru_key);
			#$window_hash->push($ru_key => $ru_value);
		}
		#check a window for a key val
		my $iter = $window_hash->iterator;
		my $counter = 0;
		#print "looking for $key\n";
		while (($ru_key, $ru_value) = $iter->()) {
			last if (! defined $ru_key);
			#print "\tru_key: $ru_key\n";
			if ($ru_key eq $key) {
				$output_counter++;
				open (MYFILE1, ">>$out_corp_name.ab"); 
				print MYFILE1 "$value\n";
				close (MYFILE1);
				open (MYFILE2, ">>$out_corp_name.ru"); 
				print MYFILE2 "$ru_value\n";
				close (MYFILE2);
				#print "found ru: $ru_value\nara: $value\n\n";
				#throw away all of the previous lines from the window
				#and append new lines from document
				while (my ($ru_k, $ru_v) = $window_hash->shift ) {
					my ($new_ru_k, $new_ru_v) = $window_next->();
					if (defined $new_ru_k) {
						$window_hash->push($new_ru_k => $new_ru_v);
					}
					last if ($ru_k eq $ru_key);
				}
				last;
			} else {
				$counter++;
				last if ($counter >= $sliding_w_size);
			}
		}
		if ($counter >= $sliding_w_size) {
			#sentence not found -> fill prev;
			#print "search didn't find anything\n\n";
			$prev_key = $key;
			$prev_val = $value;
			#no window move here -> try to merge before moving
		}
	}
	print "total: $output_counter lines evaluated\n";
}

sub get_pairs {
	my $file_name = shift;
	my $second_lang = shift; # "ARA" or "RUS"
	open (MYFILE1, ">$second_lang.txt"); 
	close (MYFILE1);
	open(INFILE1, "<$file_name") or die ("Unable to open file $file_name");
	my $m_text = "";
	my $eng_tr = Hash::Ordered->new;
	while (<INFILE1>) {
		$m_text .= $_;
	}
	$m_text =~ s/\r\n?\r\n/\r\n/gms;
	while ($m_text =~ m/<tr>(.*?)<\/tr>/gms) {
		my $in_tr = $1;
		$in_tr =~ s/\[~\]//g;
		$in_tr =~ s/\{[0-9]+\}//g; #get rid of paragraph sign
		#print $in_tr."\n\n\n\n";
		if ($in_tr =~ /<td.*?>(.*)<\/td>.*<td.*?>(.*)<\/td>/gms) {
			my $eng = $1;
			my $second = $2;
			#print "eng: $eng\n$second_lang: $second\n\n";
			if ($eng =~ / ?\[ENG\](.*)$/gms) {
				$eng = $1;
				#print "eng: $eng\n$second_lang: $second\n\n";
				$eng =~ s/\r?\n/ /g;
				$eng =~ s/\&nbsp\;/ /gs;
				#print "108 eng: $eng\n$second_lang: $second\n\n";
				$eng =~ s/  / /gs;
				$eng =~ s/<span.*?>(.*?)<\/span>/$1/gs;
				$eng =~ s/<a .*?>(.*?)<\/a>/$1/gs;
				$eng =~ s/^ +//g;
				$eng =~ s/ +$//g;
				if ($second =~ / ?\[$second_lang\](.*)$/gms) {
					$second = $1;
					$second =~ s/\r?\n/ /g;
					#print "115 eng: $eng\n$second_lang: $second\n\n";
					$second =~ s/\&nbsp\;/ /gs;
					$second =~ s/\&\#([\da-fA-F]+)\;/chr $1/ge;
					$second =~ s/<span.*?>(.*?)<\/span>/$1/gs;
					$second =~ s/<a .*?>(.*?)<\/a>/$1/gs;
					$second =~ s/^ +//g;
					$second =~ s/ +$//g;
					#print "eng: $eng\n$second_lang: $second\n\n";
					
					#print "english: $eng\n";
					#print "$second_lang: $second\n\n";	
					
					$eng_tr->push($eng => $second);
					#getstore($aud, "data/wav/$audio_name.mp3");
					#open (MYFILE2, ">>$second_lang.txt"); 
					#print MYFILE2 "$eng\n$second\n\n"; 
					#close (MYFILE2);
					#open (MYFILE2, ">>data/files.transcription"); 
					#print MYFILE2 "<s> $arab $arab </s> ($audio_name)\n"; 
					#close (MYFILE2);
				}
			}
		}
	}
	close(INFILE1);
	return $eng_tr; #return a hash reference
}

