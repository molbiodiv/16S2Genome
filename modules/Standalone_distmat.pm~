package Standalone_distmat;

use 5.014002;
use strict;
use warnings;

use File::Temp;

use lib './';
use Reader;

our @ISA = qw();

our $VERSION = '0.01';



=head1 NAME

RDP_parser.pm


=head1 DESCRIPTION 

Perl extension to calculate an uncorrected distance between  nucleotide sequences (need to be aligned)
depending on the distmat algorithm.



=head1 SYNOPSIS

	use Standalone_distmat;
	my $distmat = Standalone_distmat->new();
	$distmat->do_distmat();

=cut


=pod


=head1 Constructor METHOD


=head2 new

Initialize a distmat object. Takes parameters in key => value format. 
Parameters are:

	mandatory:

	_QUERY => ''	# defines the query sequence
	_TARGET => ''	# defines the target sequence

=cut


sub new {

	my $class = shift;
	
	# defaults for needle
	my $self = {
        '_QUERY' => undef,
        '_QUERYFH' => '',
        '_TARGET' => undef,
        '_TARGETFH' => '',
        '_NUCMETHOD' => '0',
        '_PROTMETHOD' => undef,
        '_AMBIGUOUS' => '0',
        '_GAPWEIGHT' => '0',
        '_POSITION' => undef,
        '_CALCULATEA' => undef,
        '_PARAMETERA' => undef,
        '_SBEGIN' => undef,
        '_SEND' => undef,
        '_OUT' => 'stdout',
	};
	
	bless ($self, $class);

    # check if parameters exist
    if (@_)
    {
	    if (@_%2!=0) {
	        die("Something is wrong concerning the parameters given to new! The parameters are: @_");
	    }

	    my %parameter = @_;

        unless ($parameter{query}) {
            die("No query definded!");
        }

        unless ($parameter{target}) {
            die("No targetdefinded!");
        }


        if (defined $parameter{query}) {
            $self->query($parameter{query});
        }

	    if (defined $parameter{target}) {
	        $self->target($parameter{target});
    	}


    }

    # if no parameters are defined yet
    else {
        die("No parameters defined! (obligatory: query, target)");
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

sub query {

    my $self =shift;

    if (@_) {

    	my $value = shift;

        # check, if path is a file
        if ( $value) {
            $self->{_QUERY} = $value;

	        # open file in read/write mode
	        if ($self->{_QUERY}){
		        my $fh;
		        open ( $fh, '<', $self->{_QUERY} ) || open ( $fh, '<', \$self->{_QUERY} ) || die $!;
		        $self->{_QUERYFH} = $fh;
	        }
        } 
        else {
            die("The given queryfile is NOT existent: $value");
        }

    }

    return $self->{_QUERY};

}



=head2 targetfile

Define targetfile.

=cut


### check, if targetfile is existent

sub target {

    my $self =shift;

    if (@_) {

    	my $value = shift;

        # check, if path is a file
        if ( $value) {
            $self->{_TARGET} = $value;

	        # open file in read/write mode
	        if ($self->{_TARGET}){
		        my $fh;
		        open ( $fh, '<', $self->{_TARGET} ) || open ( $fh, '<', \$self->{_TARGET} ) || die $!;
		        $self->{_TARGETFH} = $fh;
	        }

        } 
        else {
            die("The given targetfile is NOT existent: $value");
        }

    }

    return $self->{_TARGET};

}



=head2 do_distmat



=cut


###

sub do_distmat {

    my $self = shift;

    my $match = 0;
    my $mismatch = 0;
    my $gap = 0;

    # new instance of fasta::reader
    my $query = Reader->new(file => $self->{_QUERY});
    my $target = Reader->new(file => $self->{_TARGET});


    my($id1, $seq1) = $query->next_seq();
    my @query_seq = split(//, $seq1);


    my ($id2,$seq2) = $target->next_seq();
    my @target_seq = split(//, $seq2); 

    if ($#target_seq != $#query_seq) {
        die "Sequences do not have the same length!\n";
    }


    for (my $i = 0; $i < @query_seq; $i++) {
        if ( ($query_seq[$i] eq "-") || ($target_seq[$i] eq "-") ) {
            $gap++;
        }
        elsif ($query_seq[$i] eq $target_seq[$i]) {
            $match++;
        }
        elsif ($query_seq[$i] ne $target_seq[$i]) {
            $mismatch++;
        }

    }

    my $distance;

    if ( ($match == 0) && ($mismatch == 0) ) {
        return( $id1,$id2,100 );
    }
    elsif($match == 0) {
        return( $id1,$id2,100 );
    }
    elsif($mismatch == 0) {
        $distance = 0;
        return( $id1,$id2,0 );
    }
    else {
        $distance = 100 - ( ($match / ($match+$mismatch) ) * 100 );
        return( $id1,$id2,sprintf("%.2f", $distance) );
    }

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
	Genomictraits.pm
	Zscore_erf.pm


=head1 AUTHOR

Hannes Horn, <lt>Hannes.Horn@uni-wuerzburg.de<>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Hannes Horn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
