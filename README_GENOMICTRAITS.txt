Genomictraits README file
Last readme update: 02/08/2014
Last data update: 03/25/2013


DOCUMENT CONTENT
================

	0. CONTACT INFORMATION
	1. INTRODUCTION
	2. REQUIREMENTS
	3. USAGE AND OUTPUT
	4. DATA STRUCTURE
	5. TROUBLESHOOTING
	6. HOW TO CITE



0. CONTACT INFORMATION
======================

Authors: Hannes Horn at Hannes.Horn@uni-wuerzburg.de
	 Alexander Keller at Alexander.Keller@uni-wuerzburg.de



1. INTRODUCTION
===============

The Genomictraits pipeline was developed to map 16S rRNA data to already sequenced genomes and create so-called
pseudo-metagenomes by sing their nucleotide sequences. Besides, genomic traits (here PFAM domains) can be compared
between different samples provided by the user.

 

2. REQUIREMENTS
===============

There my be some data, which has to be provided and installed by the user:

	Perl modules:
	The easiest way may be using CPAN.

	- Log::Log4perl
	- File::Temp
	- Digest::MD5
	- File::Basename


	Binaries:
	The binaries can be placed in the /bin directory or wherever you like. Path to these can be specified in the pipeline.

	- RDP Classifier 2.5: http://sourceforge.net/projects/rdp-classifier/files/rdp-classifier/rdp_classifier_2.5.zip/download
	- ClustalW 2.1: http://www.clustal.org/download/current/
	

	Data:
	
	- NCBI .fnn files: ftp://ftp.ncbi.nlm.nih.gov/genomes/Bacteria/all.ffn.tar.gz
	This data has to be extracted/unpacked. It can be placed in ./data/fnn/ or wherever you like. Path to data can be defined in the pipeline.
	


3. USAGE AND OUTPUT
===================

Usage:

	perl genomictraits.pl -j <name> -i <path> -o <path> -a <path> -f <path> -r <bin> -c <bin> [-n <#>] [-t <path>] [-x <pfam>] [-b <#>] [-d <#>]


Example:

	perl. genomictraits.pl -j "project_1" -i ./16s_data/ -o ./ -a ./data/genus_aln/ -f ./data/fnn/ -r /usr/bin/rdp_classifier.jar -c /usr/bin/clustalw -n 1 -t ./data/traits/ -x pfam
 

Example Output:

	Created directories and files:

	- dir: ./project_1/			Folder with all results for the input data.

	- dir: ./project_1/log/			contains a log file for each input file.
	- file ./project_1/log/<input>.log	Information about the path for produced files as well as used parameter and mapped genomes.

	- dir: ./project_1/unique/		contains unique sequences of the input file(s). Used for all downstream analysis.
	- dir: ./project_1/rdp/			contains the file produced by RDP Classifier for each input file.
	- dir: ./project_1/alignment/		contains all alignments with the classified input sequences against the complementary "genus package".
	- dir: ./project_1/metagenome/		contains the metagenomes for each input file
	- dir: ./project_1/traits/		contains the traits (PFAM) for the input file (Only if traits option was set to 1)
	- dir: ./project_1/compare_traits/	contains the comparison of different files for the genomic traits.
						(Only if traits option was set to 1 and if multiple input files were provided).


4. DATA STRUCTURE
=================

	DIR
	- genomictraits.pl
	- README_GENOMICTRAITS.txt	
	- bin
		rdp_classifier and clustalw binaries can be extracted to this directory.
	- modules
		Genomictraits.pm
		Rdp.pm
		Rdp_parser.pm
		Reader.pm
		Referencedata.pm
		Standalone_distmat.pm
		Unique.pm
		Zscore_erf.pm
	- data
		genus_aln (contains genus packages)
		traits (contains pre-calculated PFAM domain informations)
		fnn (NCBI .fnn files can be extracted here)



5. TROUBLESHOOTING
==================

	You may get a warning message like:
	"Use of assignment to $[ is deprecated at modules//Zscore_erf.pm line 199."
	This will NOT cause the pipeline to crash.

	
	If you encounter any problems, don't hesitate to ask (see CONTACT INFORMATIONS).
	



6. HOW TO CITE
==============

If you use this tool, please cite:

	Keller, A, Horn, H, Förster, F and Schultz, J. 2014. Computational integration of genomic traits into 16S rDNA microbiota sequencing studies. Gene. 

