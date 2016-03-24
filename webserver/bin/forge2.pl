#!/usr/bin/perl

=head1 NAME

forge2.pl - Functional element Overlap analysis of the Results of Genome Wide Association Study (GWAS) Experiments 2.

=head1 SYNOPSIS

forge2.pl options (-f file) (-snp snplist)

=head1 DESCRIPTION

Analyse a set of SNPs for their overlap with DNase 1 Hypersensitive Site (DHS) hotspots and Histone marks compared to matched background SNPs. 
Identifies enrichment in DHS/Histone marks by tissue and plots graphs and table to display. Arbitrarily a minumum of 5+ SNPs is required.  
Note that if no SNPs are given the script will run on A DEFAULT GWAS* as an example output.

Several outputs are made.

A straight base R graphics pdf chart of the data.

A polychart (https://github.com/Polychart/polychart2) interactive javascript graphic using rCharts (http://ramnathv.github.io/rCharts/).

A dimple (http://dimplejs.org) d3 interactive graphic using rCharts.

A table using the Datatables (https://datatables.net) plug-in for the jQuery Javascript library, again accessed through rCharts.

In each of the graphics the colouring should be consistent. Blue (p value > 0.05), light red or pink (0.05 => p value > 0.01), red or dark red (p value <= 0.01 ) for the 95% and 99% cIs. 
Or whatever other thresholds are specified. 

Forge2 functions, plotting options and stats are provided by Forge2::Forge2, Forge2::Plot and Forge2::Stats modules.

=head1 OPTIONS

=over

=item B<data>

Dataset to analyse. 2015 Roadmap Epigenome histone mark data to choose from (h3k4me1, h3k4me3, h3k9me3, h3k36me3 or h3k27me3). h3k4me1 by default.

=item B<peaks>

Use peaks instead of hotspots. Peaks are more stringent DNase1 peaks calls representing DNase hypersensitive sites, 
rather than hotspots which are regions of generalised DNase1 sensitivity or open chromatin. Default is to use hotspots.

=item B<bkgd>

Specify whether the background matches should be picked from general set of arrays used in GWAS ('gwas') or from the Illumina_HumanOmni2.5 ('omni'). General GWAS arrays include

Affy_GeneChip_100K_Array

Affy_GeneChip_500K_Array

Affy_SNP6

HumanCNV370-Quadv3

HumanHap300v2

HumanHap550v3.0

Illumina_Cardio_Metabo

Illumina_Human1M-duoV3

Illumina_Human660W-quad

Defaults to 'gwas'. In both cases SNPs have to be on the arrays AND in the 1000 genomes phase 1 integrated call data set at phase1/analysis_results/integrated_call_sets.

=item B<label>

Supply a label that you want to use for the plotting titles, and filenames.

=item B<f>

Supply the name of a file containing a list of SNPs. 

Format must be given by the -format flag. 

If not supplied the analysis is performed either on snps provided as rsids in a comma separated list through the snps option 
or on a set of data from a default GWAS* study. Note that 5* SNPs are required at a minimum.

=item B<snps>

Can provide the snps as rsids in a comma separated list.

=item B<min_snps>

Specify the minimum number of SNPs to be allowed. Default is 5 now we are using binomial test.

=item B<thresh>

Alter the default binomial p value thresholds. Give a comma separate list of two e.g. 0.05,0.01 for the defaults

=item B<format>

If f is specified, specify the file format as follow:

rsid = list of snps as rsids each on a separate line. Optionally can add other fields after the rsid which are ignored, 

unless the pvalue filter is specified, in which case Forge2 assumes that the second field is the minus log10 pvalue

bed  = File given is a bed file of locations (chr\tbeg\tend).  bed format should be 0 based and the chromosome should be given as chrN. 

However we will also accept chomosomes as just N (ensembl) and 1-based format where beg and end are the same*.

tabix = File contains SNPs in tabix format.

ian = 1-based chr\tbeg\tend\trsid\tpval\tminuslog10pval

=item B<filter>

Set a filter on the SNPs based on the -log10 pvalue.  This works for files in the 'ian' or 'rsid' format. 
Give a value as the lower threshold and only SNPs with -log10 pvalues >= to the threshold will be analysed. Default is no filtering.

=item B<bkgrd>

Output background stats for investigation.

=item B<reps>

The number of background matching sets to pick and analyse. Default 1000*.

=item B<ld>

Apply filter for SNPs in LD at either r2 >= 0.8 ("high LD"), or r2 >= 0.1 ("independent SNPs"). Specify ld 0.8, or ld 0.1. Default is to filter at r2 >= 0.8.  With ld filter specified, forge2 will report SNPs removed due to LD with another SNP in the list and will randomly pick one for each LD block.
To turn off LD filtering specify -nold

=item B<nold>

Turn off LD filtering.

=item B<depletion>

Analyse for DHS/Histone mark depletion pattern instead of the default DHS/Histone mark enrichment analysis. Use when dealing with datasets suspected not to overlap with DHS. Specifying depletion will be indicated on the label (the text "Depletion Analysis" will be added to the file label).

=item B<noplot>

Just make the data file, don't plot.

=item B<help|h|?>

Print a brief help message and exits.

=item B<man|m>

Print this perldoc and exit.

=back

=head1 LICENCE

forge2.pl Functional analysis of GWAS SNPs

Copyright (C) 2015  EMBL - European Bioinformatics Institute and University College London
This program is free software: you can redistribute it and/or modify it under the terms of
the GNU General Public License as published by the Free Software Foundation, either version 3
of the License, or (at your option) any later version. This program is distributed in the hope
that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details. Neither
the institution name nor the name forge2.pl can be used to endorse or promote products derived from
this software without prior written permission. For written permission, please contact
c.breeze@ucl.ac.uk. Products derived from this software may not be called forge2.pl nor may forge2.pl
appear in their names without prior written permission of the developers. You should have received
a copy of the GNU General Public License along with this program.  If not, see http://www.gnu.org/licenses/.

=head1 AUTHOR

Charles Breeze, UCL and EBI

=head1 CONTACT

Charles Breeze <c.breeze@ucl.ac.uk>

=cut

use strict;
use 5.010;
use warnings;
use DBI; #database link to sqlite database
use Sort::Naturally;
use Cwd;
use Getopt::Long; #check this module
use File::Basename;
use Config::IniFiles;
use Pod::Usage;
use Scalar::Util qw(looks_like_number);
use Forge2::Stats2;
use Forge2::Plot2;
use Forge2::Forge2;
use Data::UUID;
use Statistics::Multtest qw(BY);
#use Data::Dump 'dump';

my $cwd = getcwd;

my $dbname = "forge2.db";

my $bkgd_label = {
    'gwas' => 'general set of arrays used in GWAS',
    'omni' => 'Illumina_HumanOmni2.5 array',
    };

my $bkgd = 'gwas'; # Default value
my ($data, $peaks, $label, $file, $format, $min_snps, $bkgrdstat, $noplot, $reps,
    $help, $man, $thresh, $ld, $nold, $depletion, $filter, $out_dir, @snplist,
    $web, $autoopen);

GetOptions (
    'data=s'     => \$data,
    'peaks'      => \$peaks,
    'bkgrd'      => \$bkgrdstat,
    'bkgd=s'     => \$bkgd,
    'label=s'    => \$label,
    'f=s'        => \$file,
    'format=s'   => \$format,
    'snps=s'     => \@snplist,
    'min_snps=i' => \$min_snps,
    'noplot'     => \$noplot,
    'reps=i'     => \$reps,
    'thresh=s'   => \$thresh,
    'ld=f'       => \$ld,
    'nold'       => \$nold,
    'depletion'  => \$depletion,
    'filter=f'   => \$filter,
    'out_dir=s'  => \$out_dir,
    'web=s'        => \$web,
    'autoopen'   => \$autoopen,
    'help|h|?'   => \$help,
    'man|m'      => \$man,

);


pod2usage(1) if ($help);
pod2usage(-verbose => 2) if ($man);

if (!$out_dir) {
    my $ug = new Data::UUID;
    $out_dir = $ug->to_hexstring($ug->create());
}

# the minimum number of snps allowed for test. Set to 5 as we have binomial p
unless (defined $min_snps) {
    $min_snps = 5;
}

# define which data we are dealing with for the bitstrings (h3k4me1, h3k4me3, h3k9me3, h3k36me3 or h3k27me3)
unless (defined $data ) {
    $data = "h3k4me1";
}

# Label for plots
unless (defined $label) {
    $label = "No label given";
}
  
if (!grep {$bkgd =~ /^$_/i and $bkgd = $_} keys %$bkgd_label) {
    die "Background (--bkgd) must be one of: ".join(", ", keys %$bkgd_label)."\n";
}

if (defined $depletion) {
    $label = "$label.depletion";
}

#regexp puts underscores where labels before
(my $lab = $label) =~ s/\s/_/g;
$lab = "$lab.$bkgd.$data";
#format for reading from file
unless (defined $format) {
    $format = 'rsid';
}


# Read the config file, forge2.ini
my $dirname = dirname(__FILE__);
my $cfg = Config::IniFiles->new( -file => "$dirname/forge2.ini" );
my $datadir = $cfg->val('Files', 'datadir');



# percentile bins for the bkgrd calculations. 
#This is hard coded so there are enough probes to choose from, but could later be altered.
#Forge2, like Forge, uses percentile bins
my $per = 10;


# number of sets to analyse for bkgrd.
unless (defined $reps) {
    $reps = 1000;
}


# Define the thresholds to use.
my ($t1, $t2);
if (defined $thresh) {
    ($t1, $t2) = split(",", $thresh);
    unless (looks_like_number($t1) && looks_like_number($t2)){
        die "You must specify numerical p value thresholds in a comma separated list";
    }
} else {
    $t1 = 0.05; # set binomial p values, BY is applied later based on number of samples (cells)
    $t2 = 0.01;
}

# Set r2 LD thresholds
my $r2;
unless (defined $nold){
    unless (defined $ld){
        $ld = 0.8;
    }
    unless ($ld == 0.1 || $ld == 0.8){
        die "You have specified LD filtering, but given an invalid value $ld. the format is ld 0.8, or ld 0.1";
    }
    ($r2 = $ld) =~ s /\.//;
    $r2 = "r".$r2;
}


unless (-s "$datadir/$dbname") {
    die "Database $dbname not found or empty";
}
my $dsn = "dbi:SQLite:dbname=$datadir/$dbname";
my $dbh = DBI->connect($dsn, "", "") or die $DBI::errstr;

# snps need to come either from a file or a list
my @snps;


# A series of data file formats to accept.

warn "[".scalar(localtime())."] Processing input...\n";

if (defined $file) {
    if (defined $filter) {
        unless ($format eq "ian" or $format eq "rsid") {
            warn "You have specified p value filtering, but this isn't implemented for files of format $format. No filtering will happen."
	}
    }
    my $sth = $dbh->prepare("SELECT rsid FROM bits WHERE location = ?");
    open my $fh, "<", $file or die "cannot open file $file : $!";
    @snps = process_file($fh, $format, $sth, $filter);

} elsif (@snplist) {
    @snps = split(/,/,join(',',@snplist));

} else{
    # Test SNPs from gwascatalog_21_03_2012  Pulmonary_function.snps.bed
    # If no options are given it will run on the default set of SNPs
    warn "No SNPs given, so running for example on PR interval set from the GWAS catalogue.";
    @snps = qw(rs11773845   rs17744182  rs17026156  rs7433306   rs7135659   rs3733017   rs1524976   rs3103778   rs1994318   rs16926523  rs10447419  rs7604827   rs12595668  rs746265    rs11732231  rs11773845  rs267567    rs3891585   rs6801957   rs3922844   rs6763048   rs1895585   rs10865355  rs6798015   rs3922844   rs6599222   rs7312625   rs7692808   rs3807989   rs11897119  rs6800541   rs11708996  rs4944092   rs11047543  rs251253    rs1896312);
}


# Remove redundancy in the input

my %nonredundant;
foreach my $snp (@snps) {
    $nonredundant{$snp}++;
}


foreach my $snp (keys %nonredundant) {
    if ($nonredundant{$snp} > 1) {
        say "$snp is present " . $nonredundant{$snp} . " times in the input. Analysing only once."
    }
}

@snps = keys %nonredundant;
my @origsnps = @snps;


#######!!!!!### LD filtering starts below:

my ($ld_excluded, $output, $input);
unless(defined $nold) {
    $input = scalar @snps;
    ($ld_excluded, @snps) = ld_filter(\@snps, $r2, $dbh);
    $output = scalar @snps;
}

# Check we have enough SNPs
if (scalar @snps < $min_snps) {
    die "Fewer than $min_snps SNPs. Analysis not run\n";
}


# get the cell list array and the hash that connects the cells and tissues
my ($cells, $tissues) = get_cells($data, $dbh);

# get the bit strings for the test snps from the database file
my $rows = get_bits(\@snps, $dbh);
#dump %$rows;
# unpack the bitstrings and store the overlaps by cell.
my $test = process_bits($rows, $cells, $data);

# generate stats on the background selection
if (defined $bkgrdstat) {
    bkgrdstat($test, $lab, "test");
}



# Identify SNPs that weren't found and warn about them.


my @missing;
foreach my $rsid (@origsnps) {
    if (defined $ld) {
        next if exists $$ld_excluded{$rsid};
    }
    unless (exists $$test{'SNPS'}{$rsid}) {
        push @missing, $rsid;
    }
}

if (scalar @missing > 0) {
    warn "The following " . scalar @missing . " SNPs have not been analysed because they were not found on the ".$bkgd_label->{$bkgd}."\n";
    warn join("\n", @missing) . "\n";
}
if (defined $ld) {
    if ($output < $input) {
        warn "For $label, $input SNPs provided, " . scalar @snps . " retained, " . scalar @missing . " not analysed, "  . scalar(keys %$ld_excluded) . " excluded for LD at >= R2 0.8 with another SNP from input\n";
    }
}

# only pick background snps matching snps that had bitstrings originally.

my @foundsnps = keys %{$$test{'SNPS'}};
my $snpcount = scalar @foundsnps;


# identify the gc, maf and tss, and then make bkgrd picks
warn "[".scalar(localtime())."] Loading the $bkgd background...\n";
my $picks = match(\%$test, $bkgd, $datadir, $per, $reps);

 
# for bkgrd set need to get distribution of counts instead
# make a hash of data -> cell -> bkgrd-Set -> overlap counts
my %bkgrd; #this hash is going to store the bkgrd overlaps

# Get the bits for the background sets and process
my $backsnps;

warn "[".scalar(localtime())."] Running the analysis with $snpcount SNPs...\n";
my $num = 0;
foreach my $bkgrd (keys %{$picks}) {
    warn "[".scalar(localtime())."] Repetition $num out of ".$reps."\n" if (++$num%100 == 0);
    #$rows = get_bits(\@{$$picks{$bkgrd}}, $sth);
    $rows = get_bits(\@{$$picks{$bkgrd}}, $dbh);
    #dump @$rows;
    $backsnps += scalar @$rows; #$backsnps is the total number of background probes analysed
    unless (scalar @$rows == scalar @foundsnps) {
        warn "Background " . $bkgrd . " only " . scalar @$rows . " SNPs out of " . scalar @foundsnps . "\n";
    }
    my $result = process_bits($rows, $cells, $data);
    foreach my $cell (keys %{$$result{'CELLS'}}) {
        push @{$bkgrd{$cell}}, $$result{'CELLS'}{$cell}{'COUNT'}; # accumulate the overlap counts by cell
    }
    if (defined $bkgrdstat) {
        bkgrdstat($result, $lab, $bkgrd);
    }
}

$dbh->disconnect();
warn "[".scalar(localtime())."] All repetitions done.\n";

warn "[".scalar(localtime())."] Calculating p-values...\n";
#Having got the test overlaps and the bkgd overlaps now calculate p values and output 
#the table to be read into R for plotting.


mkdir $out_dir;

open my $bfh, ">", "$out_dir/background.tsv" or die "Cannot open background.tsv";



my @results;
my @pvalues;
###ncmp is a function from Sort::Naturally
foreach my $cell (sort {ncmp($$tissues{$a}{'tissue'},$$tissues{$b}{'tissue'}) || ncmp($a,$b)} @$cells){
    # above line sorts by the tissues alphabetically (from $tissues hash values)

    # ultimately want a data frame of names(results)<-c("Zscore", "Cell", "Tissue", "File", "SNPs")
    say $bfh join("\t", @{$bkgrd{$cell}});
    my $teststat = ($$test{'CELLS'}{$cell}{'COUNT'} or 0); #number of overlaps for the test SNPs

    # binomial pvalue, probability of success is derived from the background overlaps over the tests for this cell
    # $backsnps is the total number of background snps analysed
    # $tests is the number of overlaps found over all the background tests
    my $tests;
    foreach (@{$bkgrd{$cell}}) {
        $tests += $_;
    }
    my $p = sprintf("%.6f", $tests/$backsnps);

    # binomial probability for $teststat or more hits out of $snpcount snps
    # sum the binomial for each k out of n above $teststat
    my $pbinom;
    if (defined $depletion) {
        foreach my $k (0 .. $teststat) {
            $pbinom += binomial($k, $snpcount, $p);
        }
    } else {
        foreach my $k ($teststat .. $snpcount) {
            $pbinom += binomial($k, $snpcount, $p);
        }
    }
    if ($pbinom >1) {
        $pbinom=1;
    }
    # Store the p-values in natural scale (i.e. before log transformation) for FDR correction
    push(@pvalues, $pbinom);
    $pbinom = sprintf("%.2e", $pbinom);

    # Z score calculation (note: this is here only for legacy reasons. Z-scores assume normal distribution)
    my $zscore = zscore($teststat, $bkgrd{$cell});

    my $snp_string = "";
    $snp_string = join(",", @{$$test{'CELLS'}{$cell}{'SNPS'}}) if defined $$test{'CELLS'}{$cell}{'SNPS'};
    # This gives the list of overlapping SNPs for use in the tooltips. If there are a lot of them this can be a little useless
    my ($shortcell, undef) = split('\|', $cell); # undo the concatenation from earlier to deal with identical cell names.

    push(@results, [$zscore, $pbinom, $shortcell, $$tissues{$cell}{'tissue'}, $$tissues{$cell}{'file'}, $snp_string, $$tissues{$cell}{'acc'}]);
}
close($bfh);

# Correct the p-values for multiple testing using the Benjamini-Yekutieli FDR control method
my $qvalues = BY(\@pvalues);
$qvalues = [map {sprintf("%.2e", $_)} @$qvalues];

# Write the results to a tab-separated file
my $filename = "$lab.chart.tsv";
open my $ofh, ">", "$out_dir/$filename" or die "Cannot open $out_dir/$filename: $!";
print $ofh join("\t", "Zscore", "Pvalue", "Cell", "Tissue", "File", "SNP", "Accession", "Qvalue"), "\n";
for (my $i = 0; $i < @results; $i++) {
    print $ofh join("\t", @{$results[$i]}, $qvalues->[$i]), "\n";
}
close($ofh);


warn "[".scalar(localtime())."] Generating plots...\n";
unless (defined $noplot){
    #Plotting and table routines
    Chart($filename, $lab, $out_dir, $tissues, $cells, $label, $t1, $t2, $data); # basic pdf plot
    dChart($filename, $lab, $out_dir, $data, $label, $t1, $t2, $web); # rCharts Dimple chart
    table($filename, $lab, $out_dir, $web); # Datatables chart
}

warn "[".scalar(localtime())."] Done.\n";

if ($autoopen) {
    system("open $out_dir/$lab.table.html");
    system("open $out_dir/$lab.dchart.html");
    system("open $out_dir/$lab.chart.pdf");
}
