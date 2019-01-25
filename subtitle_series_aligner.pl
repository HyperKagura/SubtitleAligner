use strict;
use warnings;

my $dir_name = "";
if ($#ARGV >= 0) {
	$dir_name = $ARGV[0];
	open (MYFILE1, ">$dir_name.ab"); 
	close (MYFILE1);
	open (MYFILE2, ">$dir_name.ru"); 
	close (MYFILE2);
	open (MYLOGFILE, ">$dir_name.log"); 
	close (MYLOGFILE);
	my $season_num = 1;
	while (1) {
		open(INFILE1, "<$dir_name/season$season_num/ara/contentlist") or die ("Unable to open file $dir_name/season$season_num/ara/contentlist");
		open(INFILE2, "<$dir_name/season$season_num/ru/contentlist") or die ("Unable to open file $dir_name/season$season_num/ru/contentlist");
		while (<INFILE1>) {
			my $ru_file = <INFILE2>;
			last if not defined $ru_file;
			my $ara_file = $_;
			$ara_file =~ s/\r?\n//g;
			$ru_file =~ s/\r?\n//g;
			$ara_file =~ s/ +$//g;
			$ru_file =~ s/ +$//g;
			print "perl subtitle_aligner_with_pauses.pl \"$dir_name/season$season_num/ru/$ru_file\" \"$dir_name/season$season_num/ara/$ara_file\" $dir_name\n";
			my $output = `perl subtitle_aligner_with_pauses.pl \"$dir_name/season$season_num/ru/$ru_file\" \"$dir_name/season$season_num/ara/$ara_file\" $dir_name`;
			print $output;
			open (MYLOGFILE, ">>$dir_name.log"); 
			print MYLOGFILE $output;
			close (MYLOGFILE);
		}
		close(INFILE1);
		close(INFILE2);
		$season_num++;
	}
}