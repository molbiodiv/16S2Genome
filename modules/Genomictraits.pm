package Genomictraits;

use 5.014002;
use strict;
use warnings;

use Log::Log4perl qw(:no_extra_logdie_message :nowarn);

use lib './modules/';
use Unique;
use Rdp;
use Rdp_parser;
use Reader;
use Standalone_distmat;
use File::Basename;
use Zscore_erf;

our @ISA = qw();
our $VERSION = '0.01';


### initialize & configure log4perl

my $log_conf = q(
    log4perl.rootLogger                                 = DEBUG, LOG1, SCREEN
    log4perl.appender.SCREEN                            = Log::Log4perl::Appender::Screen
    log4perl.appender.SCREEN.stderr                     = 0
    log4perl.appender.SCREEN.layout                     = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.SCREEN.layout.ConversionPattern   = %m %n
    log4perl.appender.LOG1                              = Log::Log4perl::Appender::File
    log4perl.appender.LOG1.filename                     = ./genomictraits.log
    log4perl.appender.LOG1.mode                         = append
    log4perl.appender.LOG1.layout                       = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.LOG1.layout.ConversionPattern     = %d %p %m %n
);
Log::Log4perl::init(\$log_conf);
my $log = Log::Log4perl->get_logger();


=pod


=head1 NAME

Genomictraits.pm


=head1 DESCRIPTION 

Perl extension to map 16S rRNA sequence samples to genomes.
Outputs all nucleotide sequences found for each sample. 
Optional compares genomic traits of the samples (pfam, go).


Files which are used - .ffn files from NCBI:
L<ftp://ftp.ncbi.nlm.nih.gov/genomes/Bacteria/all.ffn.tar.gz>
Other:
genus_aln, create by Referencedata.pm / referencedata.pl


=head1 SYNOPSIS

	use Genomictraits;
	my $traits = Genomictraits->new();
	$traits -> mapping();
	$traits -> compare_traits();	


=cut


=pod


=head1 Constructor METHOD


=head2 new

Initialize a genomictraits object. Takes parameters in key => value format. 
Parameters are:

	mandatory:

	jobname => '',	# defines the jobname for the output
	infile => '',	# defines the file to be processed
	outdir => '',	# defines output directory (must be a valid path)
	ffndir => '',	# defines directory to .fnn files (Download from NCBI, extracted)
	alignmentdir => '',	# defines directory to genus packages (genus_aln, see Referencedata.pm)
	rdpbin => '',	# defines path to RDP Classifier binary 
	clustalwbin => '',	# defines path to ClustalW binary

	optional:

	rdp_bootstrap => 0.8,	# define the bootstrap cutoff for the RDP Classifier, between 0 and 1 (default 0.8)
	distmat_identity => 97,	# define the identity cutoff for the alignments, between 0 and 100 (defaul 97)
	analyzetraits => 0,	# analyze the traits for the inputsamples (boolean, default 0)
	traitsdir => '',	# define directory for the genomic traits (mandatory if analyzetraits = 1) 
	traits => [],	# define the traits to compare, comma separated (e.g. pfam,go) (mandatory if analyzetraits = 1)


=cut



sub new {		

    my $class = shift;
	my $self = {
		_JOBNAME => '',
		_INFILE => '',
		_INFILE_NAME => '',
		_OUTDIR => '',
		_FFNDIR => '',
		_RDPBIN => '',
		_ALIGNMENTDIR => '',
		_TRAITSDIR => '', 
		_TRAITS => [],
		_CLUSTALWBIN => '', 
		_RDP_BOOTSTRAP => 0.8,
		_DISTMAT_IDENTITY => 97,
		_UNIQUEOUT => '/unique',
		_RDPOUT => '/rdp',
		_METAGENOMEOUT => '/metagenome',
		_TRAITSOUT => '/traits',
		_ALIGNMENTOUT => '/alignment',
		_LOGOUT => '/log',
		_ANALYZETRAITS => 0,
		_METAGENOME_SEQ_NUM => 0,
		_SINGLE_GENOME => 0,
		_MULTIPLE_GENOME => 0,
		_BOOTSTRAP_POSITIVE => 0,
		_IDENTITY_POSITIVE => 0,
		_TAXONOMY => {},
		_OUTCOMPARETRAIT => '/compare_traits',
	};

    bless($self, $class);

# ----------------------------------------------------------------- #

    print STDOUT "\n";
    print STDOUT "\-"x25,"\n";
    print STDOUT "USED PARAMETER AND PATHS\n";
    print STDOUT "\-"x25,"\n";  

# ----------------------------------------------------------------- #

    # check if still parameters exist
    if (@_)
    {
	    if (@_%2!=0) {
	        $log->error("Something is wrong concerning the parameters! Odd number of elements!");
	    }

	    my %parameter = @_;

		print Dumper(\%parameter);

        if (defined $parameter{infile}) {
            $self->infile($parameter{infile});
        }
		else {
			$log->logdie("No input directory defined")
		}

        if (defined $parameter{outdir}) {
            $self->outdir($parameter{outdir});
        }
		else {
			$log->logdie("No output directory defined")
		}	

        if (defined $parameter{jobname}) {
            $self->jobname($parameter{jobname});
        }
		else {
			$log->logdie("No jobname defined")
		}

        if (defined $parameter{alignmentdir}) {
            $self->alignmentdir($parameter{alignmentdir});
        }	
		else {
			$log->logdie("No genus packages (genus_aln) directory defined")
		}

        if (defined $parameter{fnndir}) {
            $self->fnndir($parameter{fnndir});
        }	
		else {
			$log->logdie("No .fnn directory defined")
		}

        if (defined $parameter{analyzetraits}) {
            $self->analyzetraits($parameter{analyzetraits});
        }	
		else {
			$log->info("Comparing traits: disabled")
		}

		if ($self->{_ANALYZETRAITS} == 1) {

		    if (defined $parameter{traitsdir}) {
		        $self->traitsdir($parameter{traitsdir});
		    }	
			else {
				$log->logdie("No traits directory defined")
			}

		    if (defined $parameter{traits}) {
		        $self->traits($parameter{traits});
		    }	
			else {
				$log->logdie("No traits defined")
			}		

		}

        if (defined $parameter{clustalwbin}) {
            $self->clustalwbin($parameter{clustalwbin});
        }
		else {
			$log->logdie("No ClustalW binary defined")
		}

        if (defined $parameter{rdpbin}) {
            $self->rdpbin($parameter{rdpbin});
        }
		else {
			$log->logdie("No RDP classifier binary defined")
		}

        if (defined $parameter{rdp_bootstrap}) {
            $self->rdp_bootstrap($parameter{rdp_bootstrap});
        }
		else {
			$log->info("Using RDP bootstrap $self->{_RDP_BOOTSTRAP}")
		}

        if (defined $parameter{distmat_identity}) {
            $self->distmat_identity($parameter{distmat_identity});
        }
		else {
			$log->info("Using identity $self->{_DISTMAT_IDENTITY}")
		}

    }

	# return
	return $self;

}


# check input directory

sub infile {

    my $self = shift;

    if (@_) {

    	my $value = shift;

        # check, if path is a directory
        if (-f $value && -r $value) {
            $self->{_INFILE} = $value;
			$log->info("Using input file: $value");

			# extract the filename from path
			my $filename = basename( $self->{_INFILE} );
			$self->{_INFILE_NAME} = $filename;

        } 
        else {
            $log->logdie("The given input file is NOT existent or NOT a file: $value");
        }

    }
	
	# return
    return $self->{_INFILE};

}


# check output directory

sub outdir {

    my $self = shift;

    if (@_) {

    	my $value = shift;

        # check, if path is a directory
        if (-d $value && -w $value) {
            $self->{_OUTDIR} = $value;
			$log->info("Using output directory: $value")

        } 
        else {
            $log->logdie("The given output path is NOT existent or NOT a directory: $value");
        }

    }
	
	# return
    return $self->{_OUTDIR};

}


# check jobname

sub jobname {

    my $self = shift;

    if (@_) {

    	my $value = shift;
		$self->{_JOBNAME} = $value;

		mkdir("$self->{_OUTDIR}/$self->{_JOBNAME}", 0777);

    }
	
	# return
    return $self->{_JOBNAME};

}


# check genus package directory

sub alignmentdir {

    my $self = shift;

    if (@_) {

    	my $value = shift;

        # check, if path is a directory
        if (-d $value && -r $value) {
            $self->{_ALIGNMENTDIR} = $value;
			$log->info("Using genus package directory: $value")

        } 
        else {
            $log->logdie("The given genus package path is NOT existent or NOT a directory: $value");
        }

    }
	
	# return
    return $self->{_ALIGNMENTDIR};

}


# check amino acid sequences directory (genomes)

sub fnndir {

    my $self = shift;

    if (@_) {

    	my $value = shift;

        # check, if path is a directory
        if (-d $value && -r $value) {
            $self->{_FFNDIR} = $value;
			$log->info("Using .fnn directory: $value")

        } 
        else {
            $log->logdie("The given .fnn path is NOT existent or NOT a directory: $value");
        }

    }
	
	# return
    return $self->{_FFNDIR};

}


# check if traits should be compared

sub analyzetraits {

	my $self = shift;

	if (@_) {

		my $value = shift;

		# check, if value is boolean (0,1)
		if ( ($value == 1) || ($value == 0) ) {
			$self->{_ANALYZETRAITS} = $value;
			if ($value == 1) {
				$log->info("Comparing traits enabled")
			}
			elsif($value == 0) {
				$log->info("Comparing traits disabled");
			}

		}
		else {
			$log->logdie("The given value analyzetraits is neither 0 nor 1");
		}
	}

	# return
	return $self->{_ANALYZETRAITS};

}


# check traits directory

sub traitsdir {

    my $self = shift;

    if (@_) {

    	my $value = shift;

        # check, if path is a directory
        if (-d $value && -r $value) {
            $self->{_TRAITSDIR} = $value;
			$log->info("Using traits directory: $value")

        } 
        else {
            $log->logdie("The given traits path is NOT existent or NOT a directory: $value");
        }

    }

	# return
    return $self->{_TRAITSDIR};

}


# check for the traits, which should be compared

sub traits {

	my $self = shift;

	if (@_) {

		my ($values) = @_;

        # split the traits by commata
        my @values = split(/,/,join(',',@$values));
		foreach (@values) {

			# check if trait directory does exist 
			if (-d "$self->{_TRAITSDIR}"."$_") {
				push(@{$self->{_TRAITS}}, $_);
				$log->info("\tCompare trait: $_")
			}		
			else {
				$log->logdie("Trait $_ does not exist in $self->{_TRAITSDIR}");
			}

		}
	}

	# return
	return $self->{_TRAITS};

}



# check for ClustalW binary

sub clustalwbin {

    my $self =shift;

    if (@_) {

    	my $value = shift;

        # check, if clustalw is executable
        if (-f $value && -x $value) {
            $self->{_CLUSTALWBIN} = $value;
        } 

        # else guess the path
        else {
            my $clustalwbin = qx(which clustalw);
            $clustalwbin =~ s/\R//g; # remove newlines

            if (-f $clustalwbin && -x $clustalwbin) {
                $self->{_CLUSTALWBIN} = $clustalwbin;
				$log->info("Using ClustalW binary: $clustalwbin");
            }
            else {
                $log->logdie("ClustalW is NOT existent or NOT executable: $value");
            }
        }

    }

    return $self->{_CLUSTALWBIN};

}


# check for RDP classifier binary

sub rdpbin {

    my $self =shift;

    if (@_) {

    	my $value = shift;

        # check, if clustalw is executable
        if (-f $value && -x $value) {
            $self->{_RDPBIN} = $value;
        } 

        # else guess the path
        else {
            my $rdpbin = qx(which rdpclassifer);
            $rdpbin =~ s/\R//g; # remove newlines

            if (-f $rdpbin && -x $rdpbin) {
                $self->{_RDPBIN} = $rdpbin;
				$log->info("Using RDP Classifier binary: $rdpbin");
            }
            else {
                $log->logdie("RDP classifier is NOT existent or NOT executable: $value");
            }
        }

    }

    return $self->{_RDPBIN};

}


# check the user distmat identity

sub distmat_identity {

	my $self = shift;

	if (@_) {

		my $value = shift;

		# check if value is numeric
		if ( ($value =~ /^\s*\d+\.*\d*\s*$/) && ($value >= 0) && ($value <= 100) ) {
			$self->{_DISTMAT_IDENTITY} = $value;
			$log->info("Using identity: $value");
		}
		else {
			$log->logdie("Identity is not numeric or not between 0 - 100");
		}
	}

	# return
	return $self->{_DISTMAT_IDENTITY};

}


# check the user distmat identity

sub rdp_bootstrap {

	my $self = shift;

	if (@_) {

		my $value = shift;

		# check if value is numeric
		if ( ($value =~ /^\s*\d+\.*\d*\s*$/) && ($value >= 0) && ($value <= 1) ) {
			$self->{_RDP_BOOTSTRAP} = $value;
			$log->info("Using RDP bootstrap value: $value");
		}
		else {
			$log->logdie("RDP classifier bootstrap is not numeric or not between 0 - 1");
		}
	}

	# return
	return $self->{_RDP_BOOTSTRAP};

}



=pod


=head1 Object METHOD


=head2 mapping

Mapping the 16s sequence input files to genomes 
Parameters:
	
	no parameters

Output:

	in the chosen output directory/jobname/:
	/log/logfile:	file with statistics to the inputfile through the stages of the pipeline
	/unique/file:	unique sequences of the inputfile
	/rdp/file:	RDP Classifier output of the unique sequences
	/alignment/files:	alignment files: input 16s sequences vs. genus packages
	/metagenome/file:	nucleotide sequences from genomes which were hit by 16s sequences = pseudo-metagenome file
	/traits/file:	traits for one pseudo-metagenome (traits can occur more than once in this file!)
	/compare_traits/files:	traits compared between different input samples

=cut


# ----------------------------------------------------------------- #
#
# mapping
# 
#
# ----------------------------------------------------------------- #


sub mapping {

	my $self = shift;

	# create dir for logfile and open filehandle
	mkdir("$self->{_OUTDIR}//$self->{_JOBNAME}/$self->{_LOGOUT}", 0777);

	my $fh_logfile;
	open($fh_logfile, ">$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_LOGOUT}/$self->{_INFILE_NAME}.log");

	print $fh_logfile "\# logfile for: $self->{_INFILE_NAME}\n";
	print $fh_logfile "\# path\t$self->{_INFILE}\n";

# ----------------------------------------------------------------- #

    print STDOUT "\n";
    print STDOUT "\-"x25,"\n";
    print STDOUT "UNIQUE PROCESS\n";
    print STDOUT "\-"x25,"\n";  

# ----------------------------------------------------------------- #


	# make the input file unique by sequences
	mkdir("$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_UNIQUEOUT}", 0777);

        # instance of the module Unique
        my $unique = Unique->new(
            'file' => $self->{_INFILE}, 
            'out' => "$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_UNIQUEOUT}/$self->{_INFILE_NAME}".".unique",
        );
		print STDOUT "infile\t$self->{_INFILE}\n";
		print STDOUT "outfile\t$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_UNIQUEOUT}/$self->{_INFILE_NAME}".".unique\n";
		print $fh_logfile "\# path unique\t$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_UNIQUEOUT}/$self->{_INFILE_NAME}".".unique\n";

		# returns: path to output, number of seen sequences, number of unique sequences
        my ($unique_out, $num_sequences, $num_sequences_unique) = $unique->make_unique();
		print $fh_logfile "\# sequences\t$num_sequences\n";
		print $fh_logfile "\# sequences unique\t$num_sequences_unique\n";


# ----------------------------------------------------------------- #

    print STDOUT "\n";
    print STDOUT "\-"x25,"\n";
    print STDOUT "RDP PROCESS\n";
    print STDOUT "\-"x25,"\n";  

# ----------------------------------------------------------------- #


	# classifiy the unique sequences with RDP classifier
	mkdir("$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_RDPOUT}", 0777);

        # instance of the module Rdp
        my $rdp = Rdp->new(
            'file' => $unique_out,
            'out' => "$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_RDPOUT}/$self->{_INFILE_NAME}".".rdp",
            'rdp' => $self->{_RDPBIN},
        );
		print STDOUT "infile\t$unique_out\n";
		print STDOUT "outfile\t$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_RDPOUT}/$self->{_INFILE_NAME}".".rdp\n";
		print $fh_logfile "\# path rdp\t$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_RDPOUT}/$self->{_INFILE_NAME}".".rdp\n";

		#returns: path to output
        my $rdp_out = $rdp->do_rdp();


	# ----------------------------------------------------------------- #

    print STDOUT "\n";
    print STDOUT "\-"x25,"\n";
    print STDOUT "PARSING PROCESS\n";
    print STDOUT "\-"x25,"\n";  

	# ----------------------------------------------------------------- #


	# parse the RDP classifier output

		# instance of Rdp_parser
		my $rdp_parser = Rdp_parser->new(
		    'file' => $rdp_out
		);

		while (my ($header, $strand, $genus, $genus_score) = $rdp_parser->next_rdp_result()) {

		    # if bootstrap score is above given (default 0.8) 
		    if ($genus_score >= 0.8) {

				$self->{'_BOOTSTRAP_POSITIVE'}++;
				
				# check if an genus package exists for the given genus
	            if (-f "$self->{_ALIGNMENTDIR}/"."$genus".".aln") {

					$self->{'_GENUS_POSITIVE'}++;
					
					# ----------------------------------------------------------------- #

					# instance of module Reader.pm: get the sequence to align against genus package
					my $reader = Reader->new(file => $unique_out);

					# return header and sequence 
					my ($id,$seq) = $reader->get_seq($header);

					# ----------------------------------------------------------------- #

		            # if needed, reverse complement the sequence
		            if ($strand eq "-") {
		                $seq = &revcomp($seq);
		            }

					# ----------------------------------------------------------------- #

					# align the sequence against genus package -> return path to alignment file
					my $alignment_out = $self->alignment($header, $seq, $genus);

					# ----------------------------------------------------------------- #

					# parse the alignment and get the genome names
					my $genomes = $self->alignment_parser($alignment_out, $header);

					# ----------------------------------------------------------------- #

					# save the metagenome for the found genomes
					$self->metagenome_nuc($genomes);

					# ----------------------------------------------------------------- #

					# get the traits for the found genomes
					$self->get_traits($genomes) if ($self->{_ANALYZETRAITS} == 1);

					# ----------------------------------------------------------------- #

				}

				# if no genus package is existing for the genus
				else {
					# here maybe some blast for later versions... ?
				}
			}

			# if bootstrap is smaller than the given (default 0.8)
			else {

			}
		}

		# print some stats to logfile
		print $fh_logfile "\# bootstrap >= $self->{_RDP_BOOTSTRAP}\t$self->{'_BOOTSTRAP_POSITIVE'}\n";
		print $fh_logfile "\# genus hit\t$self->{'_GENUS_POSITIVE'}\n";
		print $fh_logfile "\# identity >= $self->{_DISTMAT_IDENTITY}\t$self->{'_IDENTITY_POSITIVE'}\n";
		print $fh_logfile "\# single genomes\t$self->{'_SINGLE_GENOME'}\n";
		print $fh_logfile "\# multiple genomes\t$self->{'_MULTIPLE_GENOME'}\n";
		foreach (keys %{$self->{_TAXONOMY}}) {
			print $fh_logfile "$_\t$self->{_TAXONOMY}->{$_}\n"
		}		

		# ----------------------------------------------------------------- #

		# compare the traits 
		$self->compare_traits() if ($self->{_ANALYZETRAITS} == 1);

}



# reverse complement a nucleotide sequences

sub revcomp {
       
    my ($sequence) = @_;
    
    # reverse the DNA sequence
    $sequence = reverse($sequence);

    # complement the reversed DNA sequence
    $sequence =~ tr/ABCDGHMNRSTUVWXYabcdghmnrstuvwxy/TVGHCDKNYSAABWXRtvghcdknysaabwxr/;

	# return the sequence reverse complement
    return($sequence);

}


# calculate alignment between target (16s) and query (genus packages)

sub alignment {

	my $self = shift;

    my ($header,$sequence,$genus) = @_;
    $header =~ tr/\>//d;

    # create dir for tempfile for the alignment
    mkdir("$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_ALIGNMENTOUT}", 0777);

    # write tempfile for alignment: query-header + query-sequence
	open(TMP, ">$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_ALIGNMENTOUT}/$header.tmp") or die $!;
    print TMP ">$header\n$sequence\n";
	close (TMP) or die $!;


    # do clustal alignment (if it doesnt exist yet)
    qx(clustalw -sequences -noweights -quiet -profile1="$self->{_ALIGNMENTDIR}/$genus.aln" -profile2=$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_ALIGNMENTOUT}/$header.tmp -output=fasta -outfile=$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_ALIGNMENTOUT}/$header.aln) unless (-f "$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_ALIGNMENTOUT}/$header.aln");

	# ----------------------------------------------------------------- #

    # delete tempfile after usage
    unlink("$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_ALIGNMENTOUT}/$header.tmp");
    unlink("$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_ALIGNMENTOUT}/$header.dnd");

	# return the path to the alignment file
	return("$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_ALIGNMENTOUT}/$header.aln");

}


# parse the alignment betwwen 16s and genus package to calculate the distances
# --> save the genomes with the best identites (can be single or multiple hits!)

sub alignment_parser {

	my $self = shift;

    my ($file, $header) = @_;

	print "$self->{_INFILE_NAME}\tParsing alignments, identities, create metagenomes - $header\n";


    my %results = ();
    my $best_identity = 0;
	my $identity = -1;

	# get the sequences from the alignment
    my $aln_reader = Reader->new(file => $file);
    my ($query_id, $query_seq) = $aln_reader->get_seq("$header");

    # for each target sequence from alignment: calculate distance query vs each target in alignment
    while ( my ($target_id, $target_seq) = $aln_reader->next_seq() ) {

		# ...for all sequences except the input sequence
		if ($target_id ne $header) {

			# ----------------------------------------------------------------- #

			my $distmat = Standalone_distmat->new(
				    'query' => "$query_id\n$query_seq\n",
				    'target' => "$target_id\n$target_seq\n",
			);
			my ($query,$target,$dist) = $distmat->do_distmat();

			# from the distance, calculate the identity
			my $identity = 100 - $dist;

			# ----------------------------------------------------------------- #

            # only consider results >= the user set identity
            if ($identity >= $self->{_DISTMAT_IDENTITY}) {


				# delete ">_#" from the found sequences (as this is the beginning of the name in the genus packages)
                my ($cut, $genome_name) = $target_id =~ /(\>\d+\_)(.*)/;

			    # save the best results to %results
                if ($identity > $best_identity) {
                    %results = ();
                    $results{$genome_name}++;
                    $best_identity = $identity;
                }

                # if there are multiple best hits
                elsif ($identity == $best_identity) {
                    $results{$genome_name}++;
                }
            }
		}
	}

	# collect some stats
	if (keys %results == 1) {		
		$self->{'_SINGLE_GENOME'}++;
		$self->{'_IDENTITY_POSITIVE'}++;
		foreach (keys %results) {
			$self->{_TAXONOMY}->{$_}++;
		}
	}
	elsif (keys %results > 1) {		
		$self->{'_MULTIPLE_GENOME'}++;
		$self->{'_IDENTITY_POSITIVE'}++;
		foreach (keys %results) {
			$self->{_TAXONOMY}->{$_} += 1/keys %results;
		}
	}

	# return
	return(\%results);
}


# calculate the metagenomes: for multiple hits, get the intersection of the sequences
# for single hit: just grab these sequences ;-)

sub metagenome_nuc {

	my $self = shift;

	my $genomes = shift;

	# create output directory
	mkdir("$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_METAGENOMEOUT}", 0777);

	# detect the number of found genomes
	my $number_of_genomes = keys %{$genomes};

	# ----------------------------------------------------------------- #

	# open filehandle to write/create a metagenome
	my $fh_metagenome;
	open($fh_metagenome, ">>$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_METAGENOMEOUT}/$self->{_INFILE_NAME}".".meta") or die $!;

	# ----------------------------------------------------------------- #

	# if it is only one genome, get the sequences :)
	if ($number_of_genomes == 1) {
		foreach (keys %{$genomes}) {

			opendir(FNN, "$self->{_FFNDIR}/$_") or die $!; 
				while(my $dir = readdir(FNN)) {

	        		# check, if it is a directory or ./..
    				if ( ($dir !~ /^\./) && ($dir =~ /^.*\.ffn$/) ) {

						my $reader = Reader->new(file => "$self->{_FFNDIR}/$_"."/$dir");
					
						while ( my ($id, $seq) = $reader->next_seq()) {	
							$self->{_METAGENOME_SEQ_NUM}++;
							print $fh_metagenome "\>$self->{_METAGENOME_SEQ_NUM}\_metagenome\_$self->{_INFILE_NAME}\n$seq\n";
						}
					}

				}

		}
	}

	# ----------------------------------------------------------------- #

	my %intersection;


	# if there are more than one --> intersection of the sequences :(
	if ($number_of_genomes > 1) {

		# get one key from the hash to compare the others against this one
		my @key =  (keys %{$genomes});
		my $first_key = shift @key;
		delete $genomes->{$first_key};

		# get the sequences for the first key
		opendir(FNN, "$self->{_FFNDIR}/$first_key") or die "$first_key $!"; 
			while(my $dir = readdir(FNN)) {

        		# check, if it is a directory or ./..
				if ( ($dir !~ /^\./) && ($dir =~ /^.*\.ffn$/) ) {

					my $reader = Reader->new(file => "$self->{_FFNDIR}/$first_key"."/$dir");
				
					while ( my ($id, $seq) = $reader->next_seq()) {	
						$intersection{$seq}++;
					}
				}

			}


		# the comparison to the sequences
		foreach my $compare_genome (keys %{$genomes}) {

			opendir(FNN, "$self->{_FFNDIR}/$compare_genome") or die $!; 
				while(my $dir = readdir(FNN)) {

					# save the sequences to compare
					my %compare;

		    		# check, if it is a directory or ./..
					if ( ($dir !~ /^\./) && ($dir =~ /^.*\.ffn$/) ) {

						my $reader = Reader->new(file => "$self->{_FFNDIR}/$compare_genome"."/$dir");
				
						while ( my ($id, $seq) = $reader->next_seq()) {	
							$compare{$seq}++;
						}
					}
					
					# the comparison
					foreach (keys %intersection) {

						# if the same sequence is also in the compare set, keep it..
						if (exists ($compare{$_})) {

							# ..but keep only the smaller number of this sequence
							if ($compare{$_} < $intersection{$_}) {
								$intersection{$_} = $compare{$_};
							}
						}

						# if the sequence is not in one of the compare sets --> delete it
						else {
							delete $intersection{$_};
						}
					}						
				}
		}

		# ----------------------------------------------------------------- #

		# writing the intersction to metagenome file output
		foreach (keys %intersection) {

			for (my $i = 0; $i < $intersection{$_}; $i++) {
				$self->{_METAGENOME_SEQ_NUM}++;
				print $fh_metagenome "\>$self->{_METAGENOME_SEQ_NUM}\_metagenome\_$self->{_INFILE_NAME}\n$_\n";
			}
		}


	}


	# ----------------------------------------------------------------- #

}


# get the traits (here pfam and go)

sub get_traits {

	my $self = shift;

	my $genomes = shift;

	# create output directory
	mkdir("$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_TRAITSOUT}", 0777);

	# detect the number of found genomes
	my $number_of_genomes = keys %{$genomes};

	# ----------------------------------------------------------------- #



	foreach my $search_trait ( @{$self->{_TRAITS}}) {

		# create output directory
		mkdir("$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_TRAITSOUT}/$search_trait/", 0777);

		# open filehandle to write/create a metagenome
		my $fh_traits;
		open($fh_traits, ">>$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_TRAITSOUT}/$search_trait/$self->{_INFILE_NAME}".".$search_trait") or die $!;


		# single genomes
		if ($number_of_genomes == 1) {

			# get one key from the hash to compare the others against this one
			foreach my $first_key (keys %{$genomes}) {

				# check if trait file exists for the genome
				if (-f "$self->{_TRAITSDIR}/$search_trait/$first_key.$search_trait") {
					open(TRAITS, "$self->{_TRAITSDIR}/$search_trait/$first_key.$search_trait") or die $!;
						while (my $trait = <TRAITS>) {
							chomp($trait);
							print $fh_traits "$trait\n";
						}

					close (TRAITS) or die $!;
				}
			}
		}

		# ----------------------------------------------------------------- #

		my %intersection;
		my %description;

		# multiple genomes -> intersection
		if (keys %{$genomes} > 1) {

			# get one key from the hash to compare the others against this one
			my @key =  (keys %{$genomes});
			my $first_key = shift @key;

			# check if trait file exists for the genome -> save for the first genome the traits
			if (-f "$self->{_TRAITSDIR}/$search_trait/$first_key.$search_trait") {
				open(TRAITS, "$self->{_TRAITSDIR}/$search_trait/$first_key.$search_trait") or die $!;
					while (my $trait = <TRAITS>) {
						chomp($trait);
						my($name,$abundance,$descr) = split(/\t/,$trait);
						$intersection{$name} = $abundance;
						$description{$name} = $descr;
					}
				close (TRAITS) or die $!;
			}

			foreach my $compare_genome (keys %{$genomes}) {

				if ($compare_genome ne $first_key) {

				my %compare;

				# check if trait file exists for the genome -> save for the first genome the traits
				if (-f "$self->{_TRAITSDIR}/$search_trait/$compare_genome.$search_trait") {
					open(TRAITS, "$self->{_TRAITSDIR}/$search_trait/$compare_genome.$search_trait") or die $!;
						while (my $trait = <TRAITS>) {
							chomp($trait);
							my($name,$abundance,$descr) = split(/\t/,$trait);
							$compare{$name} = $abundance;
						}
				}

				# the comparison
				foreach (keys %intersection) {

					# if the same sequence is also in the compare set, keep it..
					if (exists ($compare{$_})) {

						# ..but keep only the smaller number of this sequence
						if ($compare{$_} < $intersection{$_}) {
							$intersection{$_} = $compare{$_};
						}
					}

					# if the sequence is not in one of the compare sets --> delete it
					else {
						delete $intersection{$_};
					}
				}					

			}

			# ----------------------------------------------------------------- #	
			}	

		}

		# writing the intersction to metagenome file output
		foreach (keys %intersection) {
			print $fh_traits "$_\t$intersection{$_}\t$description{$_}\n";
		}

	}
}


sub compare_traits {

	my $self = shift;

	# create directory for compared traits
	mkdir("$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_OUTCOMPARETRAIT}/", 0777);

	# go through the traits
	foreach my $search_trait ( @{$self->{_TRAITS}}) {

	# create directory for specific traits
	mkdir("$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_OUTCOMPARETRAIT}/$search_trait/", 0777);

	# for description of traits
	my %description;


		# save the traits for this one		
		my $number_of_traits = 0;
		my %intersection;

		# read in the momentanous file
		open(TRAITFILE, "$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_TRAITSOUT}/$search_trait/$self->{_INFILE_NAME}.$search_trait") or die $!;
			while (my $line = <TRAITFILE>) {
				chomp($line);
				my($trait, $abundance, $description) = split(/\t/, $line);
				$intersection{$trait} += $abundance;
				$number_of_traits += $abundance;
				$description{$trait} = $description;
			}
		close (TRAITFILE) or die $!;

		# read in files from the trait directory to compare them to the momentanous file 

		opendir(TRAITDIR, "$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_TRAITSOUT}/$search_trait") or die $!; 
			while (my $file = readdir(TRAITDIR)) {
				if ( ($file ne "$self->{_INFILE_NAME}.$search_trait") && ($file !~ /^\./) && ($file =~ /.*\.$search_trait/)  ) {

					# open filehandle to print out the comparison
					my $fh_traits;
					open($fh_traits, ">$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_OUTCOMPARETRAIT}/$search_trait/$self->{_INFILE_NAME}"."\_$file") or die $!;
					print $fh_traits "\# trait\tfrequency1\tall traits1\tfrequency2\tall traits2\tp-value\tdescription\n";

					my %compare;
					my $compare_number_of_traits;

					open(COMPAREFILE, "$self->{_OUTDIR}/$self->{_JOBNAME}/$self->{_TRAITSOUT}/$search_trait/$file") or die $!;
						while (my $compare_line = <COMPAREFILE>) {
							chomp($compare_line);
								my($compare_trait, $compare_abundance, $compare_description) = split(/\t/, $compare_line);
								$compare{$compare_trait} += $compare_abundance;
								$compare_number_of_traits += $compare_abundance;
								$description{$compare_trait} = $compare_description;
						}
					close(COMPAREFILE) or die $!;

					# compare from first file to second file
					foreach my $inter (keys %intersection) {
						my $c_2 = 0;
						if (exists $compare{$inter}) {
							$c_2 = $compare{$inter};
							my ($pvalue, $f_1, $f_2) = &calculate_stats($intersection{$inter}, $c_2, $number_of_traits, $compare_number_of_traits);
							print $fh_traits "$inter\t$f_1\t$number_of_traits\t$f_2\t$compare_number_of_traits\t$pvalue\t$description{$inter}\n" if ($pvalue <= 0.01);
						}
					}

					# compare second file against first file (important, because it may have other traits to be compared)
					foreach my $comp (keys %compare) {
						my $c_1 = 0;
						if (! exists $intersection{$comp}) {
							my ($pvalue, $f_1, $f_2) = &calculate_stats($c_1, $compare{$comp}, $number_of_traits, $compare_number_of_traits);
							print $fh_traits "$comp\t$f_1\t$number_of_traits\t$f_2\t$compare_number_of_traits\t$pvalue\t$description{$comp}\n" if ($pvalue <= 0.01);
						}
					} 

				}
			}

	}

}

# calculate the pValue between for a trait from two sets

sub calculate_stats {

	my ($c_1,$c_2,$C_1,$C_2) = @_;

	# instance for Zscore_erf -> calculate p-Value for traits from different samples
	my $stats = Zscore_erf->new(
		'c_1' => $c_1,
		'c_2' => $c_2,
		'C_1' => $C_1,
		'C_2' => $C_2,
	);
	
	# calculate the p-Value
	my($pvalue,$f1,$f2) = $stats->calculate_pvalue(); 
 
	# return the p-Value, the frequency for the trait from sample1 and the frequency for sample 2
	return($pvalue,$f1,$f2);

}

# Preloaded methods go here.

1;
__END__


=head1 SEE ALSO

	Referencedata.pm
	Reader.pm
	Unique.pm
	Rdp_parser.pm
	Rdp.pm
	Standalone_distmat.pm
	Zscore_erf.pm


=head1 AUTHOR

Hannes Horn, <lt>Hannes.Horn@uni-wuerzburg.de<>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Hannes Horn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
