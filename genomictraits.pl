#!/usr/bin/perl 

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Data::Dumper;

use lib './modules/';
use Genomictraits;



# -------------------------------------------------- #
#
# Get the parameters
#
# -------------------------------------------------- #


# initialize some parameters
our ($indir, $outdir, $rdpbin, $clustalwbin, $help, $traitsdir, $alignmentdir, $fnndir, $analyzetraits, $jobname) = undef;
our $bootstrap = 0.8;
our $identity = 97;
our @traits;


# get the user options
GetOptions(
	'jobname|j=s'		=> \$jobname,			
    'indir|i=s'       	=> \$indir,			# jobname: defines the output directory name
    'outdir|o=s'      	=> \$outdir,  	        # input: the directory with the 16s sequence files
	'alignmentdir|a=s'	=> \$alignmentdir,	#
	'fnndir|f=s'		=> \$fnndir,
    'rdp|r=s'  			=> \$rdpbin,        	# alignment: directory with the underlying "genus packages"
    'clustalw|c=s'     	=> \$clustalwbin,     # directory where the traits are saved
	'analyzetraits|n=s'	=> \$analyzetraits,
	'traitsdir|t=s'		=> \$traitsdir,
	'traits|x=s'		=> \@traits,
	'bootstrap|b=s'		=> \$bootstrap,
	'identity|d=s'		=> \$identity,
    'Help|h|?'          => \$help,             # help: help page for this script

) or pod2usage(1) and exit;

# show help message
pod2usage(1) if $help;

print @traits;

#
unless($indir) {
	die("No input directory given");
}


# starting the pipeline for each inputfile form the inputdir

opendir(INDIR, "$indir") or die $!;
	while(my $next_file = readdir(INDIR)) {

		# check, if it is a directory or ./..
		if ($next_file !~ /^\./){

			# get the input data into the perl module
			my $prepare = Genomictraits->new(
				jobname => $jobname,
				infile => "$indir"."$next_file",	# path to extracted .frn from NCBI
				outdir => $outdir,					# path to extracted .rpt from NCBI
				alignmentdir => $alignmentdir,	#
				fnndir => $fnndir,					#
				rdpbin => $rdpbin,					# path to nodes.1.bin
				clustalwbin => $clustalwbin,		# path to ClustalW binary
				analyzetraits => $analyzetraits,	# 
				traitsdir => $traitsdir,			#
				traits => [@traits],					#
				rdp_bootstrap => $bootstrap, 		#
				distmat_identity => $identity,		#
			);

			my $mapping = $prepare->mapping();

		}
	}
closedir(INDIR) or die $!;






__END__


=head1 NAME

	genomictraits.pl


=head1 DESCRIPTION

	Perl extension to map 16S rRNA sequence samples to genomes.
	Outputs all nucleotide sequences found for each sample. 
	Optional compares genomic traits of the samples (pfam).


=head1 USAGE

	perl genomictraits.pl -j <name> -i <path> -o <path> -a <path> -f <path> -r <bin> -c <bin> [-n <#>] [-t <path>] [-x <pfam>] [-b <#>] [-d <#>]

	For more information, please see the README_GENOMICTRAITS.txt


=head1 SYNOPSIS

	--Help or -h		# show this help page

	MANDATORY PARAMETER:
	--jobname or -j		# defines the jobname for the output
	--indir or -i       	# defines path to directory with 16s input samples	
	--outdir or -o 		# defines output directory (must be a valid path)
	--alignmentdir or -a	# defines directory to genus packages (genus_aln, see Referencedata.pm)
	--fnndir or -f		# defines directory to .fnn files (Download from NCBI, extracted)
	--rdp or -r 		# defines path to RDP Classifier binary 
	--clustalw or -c	# defines path to ClustalW binary

	OPTIONAL PARAMETER:
	--analyzetraits or -n	# analyze the traits for the inputsamples (boolean, default 0)
	--traitsdir or -t	# define directory for the genomic traits (mandatory if analyzetraits = 1)
	--traits or -x		# define the traits to compare, comma separated (pfam,go) (MANDATORY if analyzetraits = 1) ONLY PFAM POSSIBLE AT THE MOMENT!
	--bootstrap or -b	# define the bootstrap cutoff for the RDP Classifier, between 0 and 1 (default 0.8)
	--identity or -d	# define the identity cutoff for the alignments, between 0 and 100 (defaul 97)

=cut
