package Rdp;

use 5.012004;
use strict;
use warnings;

use File::Basename;
our @ISA = qw();

our $VERSION = '0.01';


=pod


=head1 NAME

RDP.pm


=head1 DESCRIPTION 

Perl wrapper for the RDP Classifier to use in Perl scripts.


=head1 SYNOPSIS

	use RDP;
	my $rdp = RDP->new();
	$rdp->do_rdp()

=cut


=pod


=head1 Constructor METHOD


=head2 new

Initialize a rdp object. Takes parameters in key => value format. 
Parameters are:

	mandatory:

        '_FILE' => undef,
        '_OUT' => './test',
        '_GENE' => '16srrna',
        '_RDPFORMAT' => 'fixrank',
        '_RDP' => undef,
        '_FILENAME' => undef,


=cut



sub new {
	my $class = shift;
	
	# defaults for rdp
	my $self = {
        '_FILE' => undef,
        '_OUT' => './test',
        '_GENE' => '16srrna',
        '_RDPFORMAT' => 'fixrank',
        '_RDP' => undef,
        '_FILENAME' => undef,
	};
	

	bless ($self, $class);

    # check if parameters exist
    if (@_)
    {
	    if (@_%2!=0) {
	        die("Something is wrong concerning the parameters given to new! The parameters are: @_");
	    }

	    my %parameter = @_;

        unless ($parameter{file}) {
            die("No queryfile definded!");
        }

        if (defined $parameter{file}) {
            $self->file($parameter{file});
        }

	    if (defined $parameter{out}) {
	        $self->out($parameter{out});
    	}

	    if (defined $parameter{gene}) {
	        $self->gene($parameter{gene});
    	}

	    if (defined $parameter{rdpformat}) {
	        $self->rdpformat($parameter{rdpformat});
    	}

	    if (defined $parameter{rdp}) {
	        $self->rdp($parameter{rdp});
    	}

    }

    # if no parameters are defined yet
    else {
        die("No parameters defined! (obligatory: file)");
    }

	return $self;

}



##------------------------------------------------------------------------##

=head1 Accessor METHODS

=cut



=head2 queryfile

Define queryfile.

=cut


### check, if queryfile is existent

sub file {

    my $self =shift;

    if (@_) {

    	my $value = shift;

        # check, if path is a file
        if (-f $value) {
            $self->{_FILE} = $value;

			# extract the filename from path
			my $filename = basename( $self->{_FILE} );
			$self->{_FILENAME} = $filename;
        } 
        else {
            die("The given queryfile is NOT existent: $value");
        }

    }

    return $self->{_FILE};

}



=head2 outfile

Define outfile (name).

=cut


### check, if outfile is existent

sub out {

    my $self =shift;

    if (@_) {

    	my $value = shift;

		# check if output already existent
		if ($value) {
			$self->{_OUT} = "$value";
		}
        else {
            die("The given output path is NOT existent: $value");
        }
    }

    return $self->{_OUT};

}



=head2 rdp

Define path to rdp. If path is not valid, it will be guessed.

=cut


### check, if RDP is executable

sub rdp {

    my $self =shift;

    if (@_) {

    	my $value = shift;

        # check, if rdp is executable
        if (-x $value ) {
            $self->{_RDP} = $value;
        } 

        # else guess the path
        else {
            my $rdp_classifier = qx(which rdp_classifier);
            $rdp_classifier =~ s/\R//g; # remove newlines

            if (-x $rdp_classifier) {
                $self->{_RDP} = $rdp_classifier;
            }
            else {
                die("RDP Classifier is NOT existent or NOT executable: $value");
            }
        }

    }

    return $self->{_RDP};

}



sub gene {

    my $self =shift;

    if (@_) {

    	my $value = shift;

        # check, if evalue is defined
        if ($value eq "16srrna") {
            $self->{_GENE} = $value;
        } 
        elsif ($value eq "fungallsu") {
            $self->{_GENE} = $value;
        }
        else {
            die("The given value is not allowed: $value");
        }

    }

    return $self->{_GENE};

}


sub rdpformat {

    my $self =shift;

    if (@_) {

    	my $value = shift;

        # check, if evalue is defined
        if ($value eq "fixrank") {
            $self->{_RDPFORMAT} = $value;
        } 
        elsif ($value eq "allrank") {
            $self->{_RDPFORMAT} = $value;
        } 
        elsif ($value eq "db") {
            $self->{_RDPFORMAT} = $value;
        } 
        else {
            die("The given value is not allowed: $value");
        }

    }

    return $self->{_RDPFORMAT};

}



=head2 do_rdp

Start rdp with the given parameters.
Generates one outputfile for each inputfile. 
Returns a scalar with the path of the file.

=cut


###

sub do_rdp {

    my $self = shift;


	# check, if output already exists. If yes, exit and return path.
	if (-f "$self->{_OUT}") {
	    print "Skipping: Rdp Classifier. "."$self->{_OUT}"." already existent."."\n";
	    return ($self->{_OUT});
	}

    # prepare the statement
    my $statement = undef;

    # check for given parameters

    # does rdp exist
    if (defined $self->{'_RDP'}) {
        $statement = "java -jar $self->{'_RDP'}";
    }

    # is the query a file
    if (defined $self->{'_FILE'}) {
        $statement .= " -queryFile $self->{'_FILE'}";
    }


    # is the output path defined
    if ( defined $self->{'_OUT'} ) {
        $statement .= " --outputFile "."$self->{_OUT}";
    }


    # is gene defined (16s or fungi)
    if (defined $self->{'_GENE'}) {
        $statement .= " --gene $self->{'_GENE'}";
    }


    # if format is defined
    if (defined $self->{'_RDPFORMAT'}) {
        $statement .= " --format $self->{'_RDPFORMAT'}";
    }

    # execute statement
    qx($statement);

	# return
    return( $self->{_OUT} );

}




# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 SEE ALSO

	Referencedata.pm
	Reader.pm
	Unique.pm
	Rdp_parser.pm
	Genomictraits.pm
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
