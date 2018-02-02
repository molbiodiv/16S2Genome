package Reader;


use warnings;
use strict;

our $VERSION = '0.01';

##------------------------------------------------------------------------##

=head1 NAME 

Fasta::Reader.pm

=head1 DESCRIPTION

Reader module for Fasta format files.

=head1 SYNOPSIS



##------------------------------------------------------------------------##

=head1 Constructor METHOD

=head2 new

Initialize a fasta parser object. Takes parameters in key => value format. 
 Parameters are:

  file => undef,
  mode => '<',   # read, 
                 # '+>': read+write (clobber file first)
                 # '+<': read+write (append)
                 # '>' : write (clobber file first)
                 # '>>': write (append)

=cut

sub new{

    my $class = shift;
	
	# defaults=
	my $self = {
		file => undef,
		mode => '<',
        fh => undef,
		@_	# overwrite defaults
	};

	# open file in read/write mode
	if ($self->{file}){
		my $fh;
		open ( $fh, $self->{mode}, $self->{file} ) || open ( $fh, $self->{mode}, \$self->{file} ) || die $!;
		$self->{fh} = $fh;
	}


	bless $self, $class;

	return $self;

}



##------------------------------------------------------------------------##

=head1 Object METHODS

=cut

=head2 next_seq

Loop through fasta file and return next 'Fasta::Seq' object.

=cut


sub next_seq {

	my $self = shift;
	
	my $fh = $self->{fh};
	local $/ = "\n>";

	# return fasta seq object
	my $fa = <$fh>;
	return unless defined $fa;
	chomp($fa);

    # split id, description an sequence
	my($id, $desc, $seq) = $fa =~ m/
		(?:>?(\S+))			# id, >? for records
		(?:\s([^\n]+))?\n	# desc, optional
		(.+)				# seq
		/xs;					# '.' includes \n

    # check if id has leading '>'
    if ($id !~ m/^>/) {
        $id = "\>"."$id";
    }

    # remove '\n' from sequence
    $seq =~ tr/\n//d;

	return ($id,$seq,$desc);

}


sub get_seq {

    my $self = shift;
    my $given_id = shift;

	# open file in read mode -> 2nd filehandle
	# for not changing the linecounter in 'next_seq'
	if ($self->{file}){
		my $fh;
		open ( $fh, $self->{mode}, $self->{file} ) || open ( $fh, $self->{mode}, \$self->{file} ) || die $!;
		$self->{fh2} = $fh;
	}

    my $fh = $self->{fh2};
	local $/ = "\n>";

    while (my $fa = <$fh>) {
        chomp($fa);

        # split id, description an sequence
	    my($id, $desc, $seq) = $fa =~ m/
		(?:>?(\S+))			# id, >? for records
		(?:\s([^\n]+))?\n	# desc, optional
		(.+)				# seq
		/xs;					# '.' includes \n

        # check if id has leading '>'
        if ($id !~ m/^>/) {
            $id = "\>"."$id";
        }

        # remove '\n' from sequence
        $seq =~ tr/\n//d;

		if ($id eq $given_id) {
	    	return ($id,$seq,$desc);
		}
    }
	die "Sequence with id '$given_id' not found!\n";
    
}


1;


=head1 SEE ALSO

	Referencedata.pm
	Genomcitraits.pm
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
