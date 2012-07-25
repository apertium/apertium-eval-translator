#!/usr/bin/perl -w 

# (c) 2007-2011 Felipe Sánchez Martínez
# (c) 2007-2011 Universitat d'Alacant
#
# This software is licensed under the GPL license version 3, or at
# your option any later version 
#

use strict; 
use warnings;

# Getting command line arguments:
use Getopt::Long;
# Documentation:
use Pod::Usage;
# I/O Handler
use IO::Handle;

use Math::Random::OO::Bootstrap;

#use locale;
#use POSIX qw(locale_h);
#setlocale(LC_ALL,"");

my($source, $test, $testb, $ref, $help, $times, $evalscript, $better);

$better="+"; # By default system A is better than system B if A gets higher scores

# Command line arguments
GetOptions( 'source|s=s'         => \$source,
            'test|t=s'           => \$test,
            'testb|b=s'          => \$testb,
            'better|c=s'         => \$better,
            'ref|r=s'            => \$ref,
            'times|n=n'          => \$times,
            'eval|e=s'           => \$evalscript,
            'help|h'             => \$help,
          ) || pod2usage(2);

pod2usage(2) if $help;
pod2usage(2) unless ($source);
pod2usage(2) unless ($test);
pod2usage(2) unless ($ref);
pod2usage(2) unless ($times);
pod2usage(2) unless ($evalscript);

open(SRC, "<$source") or die "Error: Cannot open source file \'$source\': $!\n";
open(TEST, "<$test") or die "Error: Cannot open test file \'$test\': $!\n";
open(REF, "<$ref") or die "Error: Cannot open reference file \'$ref\': $!\n";

if ($testb) {
  open(TESTB, "<$testb") or die "Error: Cannot open second test file \'$testb\': $!\n";
}

print "Source file: '$source'\n";
print "Test file: '$test'\n";
print "Second test file: '$testb'\n" if ($testb);
print "\tIn addition to the computation of confidence intervals, pair bootstrap resampling will be performed\n" if ($testb);
print "Reference file '$ref'\n";
print "Eval script '$evalscript'\n";
print "Better: '$better'\n";
print "Number of times '$times'\n\n";

my(@src_corpus, @test_corpus, @testb_corpus, @ref_corpus);

while(<TEST>) {
  &preprocess;
  push @test_corpus, $_;

  if ($testb) {
    $_=<TESTB>;
    &preprocess;
    push @testb_corpus, $_;
  }

  $_=<REF>;
  &preprocess;
  push @ref_corpus, $_;

  $_=<SRC>;
  &preprocess;
  push @src_corpus, $_;

}
close(SRC);
close(TEST);
close(REF);
close(TESTB) if ($testb);

if ($#test_corpus != $#ref_corpus) {
  print STDERR "Error: Test file has ", $#test_corpus+1, " sentences while reference file has ", $#ref_corpus+1, "\n";
  exit(1);
}

if ($#test_corpus != $#src_corpus) {
  print STDERR "Error: Test file has ", $#test_corpus+1, " sentences while source file has ", $#src_corpus+1, "\n";
  exit(1);
}

if ($testb) {
  if ($#test_corpus != $#testb_corpus) {
    print STDERR "Error: Second test file has ", $#testb_corpus+1, " sentences while the first one has ", $#test_corpus+1, "\n";
    exit(1);
  }
}

print "Number of samples (sentences): ",  $#test_corpus+1, "\n";

#Initialize the bootstrap resampling with replacement random numbers generator
my @sample=(0..$#test_corpus);
my $boots = Math::Random::OO::Bootstrap->new(@sample);
$boots->seed(0.42);

my @scores;
my @scoresb;
print "Perfoming bootstrap resampling ";
foreach (1..$times) {
  print ".";
  my @sampleset=&next_sample_set;  
  push @scores, &eval_sample_set(0, @sampleset);
  push @scoresb, &eval_sample_set(1, @sampleset) if ($testb);
}
print " done.\n\n";

my (@sorted_scores, @sorted_scoresb);
@sorted_scores = sort { $a <=> $b } @scores;
@sorted_scoresb = sort { $a <=> $b } @scoresb if ($testb);

print "Confidence intervals for system A ('$test')\n";
print "---------------------------------\n";
&confidence(0.95, @sorted_scores);
&confidence(0.85, @sorted_scores);
&confidence(0.75, @sorted_scores);
#&confidence(0.65, @sorted_scores);
#&confidence(0.50, @sorted_scores);

if ($testb) {
  print "\nConfidence intervals for system B ('$testb')\n";
  print "---------------------------------\n";
  &confidence(0.95, @sorted_scoresb);
  &confidence(0.85, @sorted_scoresb);
  &confidence(0.75, @sorted_scoresb);
  #&confidence(0.65, @sorted_scoresb);
  #&confidence(0.50, @sorted_scoresb);

  # pairwise comparison
  my @diffs;

  my $AbetterB = 0;
  my $equal = 0;
  for(my $i=0; $i<$times; $i++) {
    my $d;

    if ($better eq "+") {
     $d = $scores[$i]-$scoresb[$i];
    } else {
     $d = $scoresb[$i]-$scores[$i];
    }

    push @diffs, $d;

    $AbetterB++ if ($d>=0);

    $equal++ if ($d == 0);
  }

  my @sorted_diffs = sort { $a <=> $b } @diffs;

  print "\nComparison between systems A and B\n";
  print "----------------------------------\n";
  print "System A performs better (or equal) than system B $AbetterB times out of $times: ", sprintf("%.2f", ($AbetterB/$times)*100), "%\n";
  print "System A performs equal than system B $equal times out of $times: ", sprintf("%.2f", ($equal/$times)*100), "%\n";
  print "\nConfidence intervals for the discrepancy between the two systems\n";
  print "------------------------------------------------------------------\n";
  &confidence(0.95, @sorted_diffs);
  &confidence(0.85, @sorted_diffs);
  &confidence(0.75, @sorted_diffs);
  #&confidence(0.65, @sorted_diffs);
  #&confidence(0.50, @sorted_diffs); 
}

##########################################################################

sub confidence {
  my ($conf, @scores)=@_;

  my $drop=&round((1.0-$conf)/2.0*$times);

  print "--- Confidence: $conf    ";
  #print "Removing the top $drop and bottom $drop scores ... ";
  foreach (1..$drop) {
    shift @scores;
  }

  foreach (1..$drop) {
    pop @scores;
  }
  #print " done.\n";

  my($min,$max);
  $min=$scores[0];
  $max=$scores[$#scores];

  print sprintf("%.4f", &mean(@scores)), " in [ ", sprintf("%.4f", $min), " , ",  sprintf("%.4f", $max), " ]   ";

  print "Score: ", sprintf("%.4f",($min+(($max-$min)/2.0))), " +/- ", sprintf("%.4f",(($max-$min)/2.0)), "\n";
}

sub next_sample_set {
  my @sampleset;

  foreach (0..$#sample) {
    push @sampleset, $boots->next();
  }
  return @sampleset;
}

sub eval_sample_set {
  my ($usetestb, @sampleset)=@_;

  #Prepare source file
  open(TMP, ">/tmp/source_file-$usetestb-$$") or die "Error: Cannot open file \'/tmp/source_file-$usetestb-$$\': $!\n";  
  foreach (@sampleset) {
    print TMP $src_corpus[$_], "\n";
  }
  close(TMP);

  #Prepare test file
  open(TMP, ">/tmp/test_file-$usetestb-$$") or die "Error: Cannot open file \'/tmp/test_file-$usetestb-$$\': $!\n";  
  foreach (@sampleset) {
    if ($usetestb) {
      print TMP $testb_corpus[$_], "\n";
    } else {
      print TMP $test_corpus[$_], "\n";
    }
  }
  close(TMP);

  #Prepare reference file
  open(TMP, ">/tmp/reference_file-$usetestb-$$") or die "Error: Cannot open file \'/tmp/reference_file-$usetestb-$$\': $!\n";  
  foreach (@sampleset) {
    print TMP $ref_corpus[$_], "\n";
  }
  close(TMP);

  #Execution of the evaluation script
  my $output=`$evalscript /tmp/source_file-$usetestb-$$ /tmp/reference_file-$usetestb-$$ /tmp/test_file-$usetestb-$$`;
  chomp $output;

  $output =~ tr/,/./;

  `rm /tmp/source_file-$usetestb-$$ /tmp/reference_file-$usetestb-$$ /tmp/test_file-$usetestb-$$`;
  
  return $output;
}

sub round {
  my($number) = @_;
  return int($number + 0.5 * ($number <=> 0));
}

sub mean {
  my(@v) = @_;
  my $sum=0.0;

  foreach (@v) {
    $sum+=$_;
  }

  return $sum/($#v+1);
}


sub preprocess {
  chomp;
  #Insert spaces before and after punctuation marks 
  #s/([.,;:%¿?¡!()\[\]{}<>])/ $1 /g;
}

# References
#
# Ying Zhang, Stephan Vogel, Alex Waibel, (2004). Interpreting Bleu/NIST scores: How much improvement do we need to have a better system?, LREC 2004
# Philipp Koehn (2004). Statistical Significance Tests for Machine Translation Evaluation, EMNLP 2004

__END__

=head1 NAME

=head1 SYNOPSIS

mteval_by_bootstrap_resampling.pl -source srcfile -test testfile  [-testb tesfileb] [-better +|-] -ref reffile -times <n> -eval /path/to/eval/script

Options:

  -source|-s   Specify the source file
  -test|-t     Specify the translations to evaluate 
  -testb|-b    Specify a second set of translations to evaluate (optional)
  -better|-c   '+' means system A is better than system B if its 
               get higher scores, '-' means the opposite (optional, 
               by default='+')
  -ref|-r      Specify the reference translations
  -times|-n    Specify how many times the resampling should be done
  -eval|-e     Specify the full path to the MT evaluation script
  -help|-h     Show this help message

If a second translation is provided (see -testb) pair bootstrap resampling
will also be performed

(c) 2007-2011 Felipe Sánchez Martínez
(c) 2007-2011 Universitat d'Alacant

This software is licensed under the GNU GENERAL PUBLIC LICENSE version
3, or at your option any latter version. See
http://www.gnu.org/copyleft/gpl.html for a complete version of the
license.
