use strict;
use warnings;

my $dir_name = "";
if ($#ARGV >= 0) {
	my $lang = $ARGV[0];
	$dir_name = $ARGV[1];
	open (MYFILE1, ">$dir_name.ab"); 
	close (MYFILE1);
	open (MYFILE2, ">$dir_name.ru"); 
	close (MYFILE2);
	open (MYLOGFILE, ">$dir_name.log"); 
	close (MYLOGFILE);
	my $season_num = 1;
	while (1) {
		open(INFILE1, "<$dir_name/season$season_num/$lang/contentlist") or die ("Unable to open file $dir_name/season$season_num/$lang/contentlist");
		open(OUTPUTFILE, ">$dir_name.$lang.txt");
		close(OUTPUTFILE);
		while (<INFILE1>) {
			my $srt_file = $_;
			$srt_file =~ s/\r?\n//g;
			$srt_file =~ s/ +$//g;
			print "perl SRT_text_extractor.pl \"$dir_name/season$season_num/$lang/$srt_file\" >>$dir_name.$lang.txt\n";
			my $output = `perl SRT_text_extractor.pl \"$dir_name/season$season_num/$lang/$srt_file\" >>$dir_name.$lang.txt`;
			print $output;
		}
		close(INFILE1);
		close(INFILE2);
		$season_num++;
	}
}
else {
	print STDERR "Usage:\nperl SRT_one_lang_extractor.pl <language_prefix> <series_dir>\n";
	print STDERR "Example:\nperl SRT_one_lang_extractor.pl ru friends\n";
	print STDERR "This script will go through all avaiable \"season\" subdirectories\n of <series_dir> and collect all subtitle texts";
}