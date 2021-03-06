package Rdp_parser;

use 5.012004;
use strict;
use warnings;

our @ISA = qw();

our $VERSION = '0.01';



=pod


=head1 NAME

RDP_parser.pm


=head1 DESCRIPTION 

Perl extension to parse output files of the RDP classifier.



=head1 SYNOPSIS

	use RDP_parser;
	my $rdp_parser = RDP_parser->new();
	$rdp_parder->next_rdp_result();

=cut


=pod


=head1 Constructor METHOD


=head2 new

Initialize a rdp_parser object. Takes parameters in key => value format. 
Parameters are:

	mandatory:

	_FILE => ''	# defines the input file for the parser. Need to be a RDP Classifier outut file (fixrank).


=cut



sub new {
	my $class = shift;
	
	# defaults for rdp
	my $self = {
        '_FILE' => undef,
        '_FH' => '',
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

    }

	return $self;

}


sub file {

    my $self =shift;

    if (@_) {

    	my $value = shift;

        # check, if file is empty
        if (! -z $value) {
            $self->{_FILE} = $value;
        } 
        else {
            die("The given queryfile is empty: $value");
        }

    }

	# open file in read/write mode
	if ($self->{_FILE}){
		my $fh;
		open ( $fh, "<", $self->{_FILE} ) || die $!;
		$self->{_FH} = $fh;
	}

    return $self->{_FILE};

}

##------------------------------------------------------------------------##

=head1 Accessor METHODS

=cut


=head2 parse_rdp

Parses the rdp-output in fixrank-format ONLY. Consists of 20 columns.
Example:

query   tab domain                  phylum                          class                           order                       family                          genus
H4-5-f		Bacteria	domain	1.0	"Proteobacteria"	phylum	1.0	Gammaproteobacteria	class	1.0	Pseudomonadales	order	1.0	Pseudomonadaceae	family	1.0	Pseudomonas	genus	0.71
H5-1-f		Bacteria	domain	1.0	"Proteobacteria"	phylum	1.0	Gammaproteobacteria	class	1.0	"Enterobacteriales"	order	1.0	Enterobacteriaceae	family	1.0	Tatumella	genus	0.54
H5-2-f		Bacteria	domain	1.0	"Proteobacteria"	phylum	1.0	Gammaproteobacteria	class	1.0	"Enterobacteriales"	order	1.0	Enterobacteriaceae	family	1.0	Tatumella	genus	0.52

Returns a hash reference:
        query->{'domain'} = domain_name;
        query->{'phylum'} = phylum_name;
        query->{'class'} = class_name;
        query->{'order'} = order_name;
        query->{'family'} = family_name;
        query->{'genus'} = genus_name;
        query->{'domain_score'} = domain_score;
        query->{'phylum_score'} = phylum_score;
        query->{'class_score'} = class_score;
        query->{'order_score'} = order_score;
        query->{'family_score'} = family_score;
        query->{'genus_score'} = genus_score;

=cut


###

sub next_rdp_result {

    my $self = shift;

    my $fh = $self->{_FH};
	local $/ = "\n";

	# return
	my $rdp = <$fh>;
	return unless defined $rdp;
	chomp($rdp);


    # split the line
    my ($header,$strand,
    $domain_name,$domain,$domain_score,
    $phylum_name,$phylum,$phylum_score,
    $class_name,$class,$class_score,
    $order_name,$order,$order_score,
    $family_name,$family,$family_score,
    $genus_name,$genus,$genus_score                        
    ) = split ("\t", $rdp);

    # header with leading ">"
    $header = ">"."$header";

    # if strandinformation is empty -> "+", else it is "-"
    if ($strand eq "") {
        $strand = "+";
    }

    #my %rdp_result;
    #$rdp_result{$header}->{'domain'} = $domain_name;
    #$rdp_result{$header}->{'phylum'} = $phylum_name;
    #$rdp_result{$header}->{'class'} = $class_name;
    #$rdp_result{$header}->{'order'} = $order_name;
    #$rdp_result{$header}->{'family'} = $family_name;
    #$rdp_result{$header}->{'genus'} = $genus_name;
    #$rdp_result{$header}->{'domain_score'} = $domain_score;
    #$rdp_result{$header}->{'phylum_score'} = $phylum_score;
    #$rdp_result{$header}->{'class_score'} = $class_score;
    #$rdp_result{$header}->{'order_score'} = $order_score;
    #$rdp_result{$header}->{'family_score'} = $family_score;
    #$rdp_result{$header}->{'genus_score'} = $genus_score;

    return ($header, $strand, $genus_name, $genus_score);

}



# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 SEE ALSO

	Referencedata.pm
	Reader.pm
	Unique.pm
	Genomictraits.pm
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
