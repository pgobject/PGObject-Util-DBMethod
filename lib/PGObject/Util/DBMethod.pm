package PGObject::Util::DBMethod;

use 5.006;
use strict;
use warnings;
use Exporter 'import';

=head1 NAME

PGObject::Util::DBMethod - Declarative stored procedure <-> object mappings for
the PGObject Framework

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Without PGObject::Util::DBobject, you would:

    sub mymethod {
        my ($self) = @_;
        return $self->call_dbmethod(funcname => 'foo');
    }

With this you'd do this instead:

    dbmethod mymethod => (funcname => 'foo');

=head1 EXPORT

This exports only dbmethod, which it always exports.

=cut

our @EXPORT = qw(dbmethod);

=head1 SUBROUTINES/METHODS

=head2 dbmethod

use as dbmethod (name => (default_arghash))

For example:

  package MyObject;
  use PGObject::Utils::DBMethod;

  dbmethod save => (
                                 strict_args => 0,
                                    funcname => 'save_user', 
                                  funcschema => 'public',
                                        args => { admin => 0 },
  );
  $MyObject->save(args => {username => 'foo', password => 'bar'});

Special arguments are:

=over

=item strict_args

If true, args override args provided by user.

=item returns_objects

If true, bless returned hashrefs before returning them.

=back

=cut

sub dbmethod {
    my $name = shift;
    my %defaultargs = @_;
    my ($target) = caller;

    my $coderef = sub {
       my $self = shift @_;
       my %args = @_;
       for my $key (keys %{$defaultargs{args}}){
           $args{args}->{$key} = $defaultargs{args}->{$key} 
                  unless $args{args}->{$key} or $defaultargs{strict_args};
           $args{args}->{$key} = $defaultargs{args}->{$key} 
                 if $defaultargs{strict_args};
       }
       for my $key(keys %defaultargs){
           next if grep(/^$key$/, qw(strict_args args returns_objects));
           $args{$key} = $defaultargs{$key} if $defaultargs{$key};
       }
       my @results = $self->call_dbmethod(%args);
       if ($defaultargs{returns_objects}){
           for my $ref(@results){
               $ref = "$target"->new(%$ref);
           }
       }
       return shift @results unless wantarray;
       return @results;
    };
    no strict 'refs';
    *{"${target}::${name}"} = $coderef;
}

=head1 AUTHOR

Chris Travers, C<< <chris.travers at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject-util-dbmethod at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Util-DBMethod>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::Util::DBMethod


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Util-DBMethod>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PGObject-Util-DBMethod>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PGObject-Util-DBMethod>

=item * Search CPAN

L<http://search.cpan.org/dist/PGObject-Util-DBMethod/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Chris Travers.

This program is released under the following license: BSD


=cut

1; # End of PGObject::Util::DBMethod
