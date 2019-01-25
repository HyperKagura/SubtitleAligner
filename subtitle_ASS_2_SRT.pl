use strict;
use warnings;
#ffmpeg -i Movie.mkv -map 0:s:0 subs.srt

my $input_f1 = "";
if ($#ARGV >= -1) {
	$input_f1 = $ARGV[0];
	#print "File is: $input_f1\n";
	
	open(INFILE1, "<$input_f1") or die ("Unable to open first file $input_f1");
	
	while(<INFILE1>) {
		my $ass_str = $_;
		#print "$ass_str";
		last if ( $ass_str =~ /^\[Events\]/g);
	}
	
	my $m_format = <INFILE1>;
	die('Events not found') if (! defined $m_format);
	my %field_num;
	my $format_len = 0;
	if ($m_format =~ /^Format: (.*)$/gs) { #?gs
		my @fields = split(',', $1);
		foreach my $field_name (@fields) {
			$field_name =~ s/[ \n\r]//g;
			$field_num{$field_name} = $format_len;
			#print "$field_name, ";
			$format_len++;
		}
		#print "\n";
		die("Start key not set") if (! defined $field_num{"Start"});
		die("End key not set") if (! defined $field_num{"End"});
		die("Text key not set") if (! defined $field_num{"Text"});
	}
	else {
		die("Error: cannot find format\n");
	}
	my $m_sub_num = 0;
	while(<INFILE1>) {
		my $ass_str = $_;
		last if ($ass_str eq "\r\n");
		$m_sub_num++;
		print "$m_sub_num\n";
		my @field_vals = split(',', $ass_str, $format_len);
		my $zero_line = "0";
		$field_vals[$field_num{'Start'}] =~ s/\.(\d\d)$/,$1$zero_line/g;
		$field_vals[$field_num{'Start'}] =~ s/^(\d):/0$1:/g;
		$field_vals[$field_num{'End'}] =~ s/\.(\d\d)$/,$1$zero_line/g;
		$field_vals[$field_num{'End'}] =~ s/^(\d):/0$1:/g;
		print "$field_vals[$field_num{'Start'}] --> $field_vals[$field_num{'End'}]\n";
		my $text_id = $field_num{'Text'};
		#print "text id is: $field_num{'Text'}, len is: $format_len\n";
		my $m_text = $field_vals[$field_num{'Text'}];
		#print "$m_text\n";
		$m_text =~ s/\\[nN]/\n/g;
		$m_text =~ s/\\t/\t/g;
		$m_text =~ s/\r?\n\r?\n/\n/gms;
		$m_text =~ s/\r?\n$//g;
		print "$m_text\n\n";
	}
}
