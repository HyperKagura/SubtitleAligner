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
	open(INFILE1, "<$dir_name/contentlist") or die ("Unable to open file $dir_name/contentlist");
	while (<INFILE1>) {
		my $first_file = $_;
		$first_file =~ s/\r?\n//g;
		my $second_file = <INFILE1>;
		last if ! defined $second_file;
		$second_file =~ s/\r?\n//g;
		print "perl UN_extract_RU_ARA_one_pair.pl $dir_name/$first_file $dir_name/$second_file $dir_name\n";
		my $output = `perl UN_extract_RU_ARA_one_pair.pl $dir_name/$first_file $dir_name/$second_file $dir_name`;
		print $output;
		open (MYLOGFILE, ">>$dir_name.log"); 
		print MYLOGFILE $output;
		close (MYLOGFILE);
	}
	close(INFILE1);
}