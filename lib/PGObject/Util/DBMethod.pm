package PGObject::Util::DBMethod;

use 5.008;
use strict;
use warnings;
use Exporter 'import';

=head1 NAME

PGObject::Util::DBMethod - Declarative stored procedure <-> object mappings for
the PGObject Framework

=head1 VERSION

Version 1.1.0

=cut

our $VERSION = '1.1.0';


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

=item args

It set must point to a hashref.  Used to allow mapping of function arguments
to arg hash elements.  If this is set then funcname, funcschema, etc, cannot be
overwritten on the call.

=item strict_args

If true, args override args provided by user.

=item returns_objects

If true, bless returned hashrefs before returning them.

=item merge_back

If true, merges the first record back to the $self at the end before returning,
and returns $self.  Note this is a copy only one layer deep which is fine for 
the use case of merging return values from the database into the current 
object.

=back

=cut

my %code = (
     intro => '
           sub {
               my ($self, @args) = @_;
               my %dbargs = @args unless $default_args{arg_list};
               for (keys %default_args ){
                    $dbargs{$_} = $default_args{$_} unless defined $dbargs{$_};
               }
               for (keys %{$default_args{args}}){
                    $dbargs{args}->{$_} = $default_args{args}->{$_}
                        unless defined $dbargs{args}->{$_};
               }',
     args => {
         args => '',
         arg_list => '
               my @arglist = @args;
               my @argnames =  @{$default_args{arg_list}};
               $dbargs{args} = { map { ($_,  shift @arglist) } 
                              @argnames };',
         default => '
               my $dbargs = {@args};', # copy
     },
     arg_precedence => {
         strict => '
               $dbargs{$_} = $default_args{$_} 
                   for grep {$_ ne "args"} keys %default_args;
               $dbargs{args}->{$_} = $default_args{args}->{$_}
                   for keys %{$default_args{args}};',
         default => '',
     },
     run => '
               my @results = $self->call_dbmethod(%dbargs);',
     returns => { 
          objects => '
               @results =  map { $self->new($_) } @results;',
          merged_back => '
               _merge($self, $results[0]);
               @results = ($results[0]);',
          default => '',
     },
     final => '
               return wantarray ? @results : shift @results;
           }',
);

sub dbmethod {
    my $name = shift;
    my %default_args = @_;
    my ($target) = caller;
    my $returns;
    my @arg_opts = qw(args arg_list);
    my ($args) = grep { $default_args{$_} } @arg_opts;
    $args ||= 'default';
    if ($default_args{returns_objects}){
       $returns = 'objects';
    } elsif ($default_args{merge_back}) {
       $returns = 'merged_back';
    } else {
       $returns = 'default';
    }
    my $arg_prec = $default_args{strict_args} ? 'strict' : 'default';
    my $codestr = join '',
                  $code{intro}, $code{args}->{$args}, 
                  $code{arg_precedence}->{$arg_prec}, $code{run},
                  $code{returns}->{$returns}, $code{final};
    warn $codestr if $ENV{PGOBJECT_DEBUG};
    local $@ = undef;
    my $coderef = eval $codestr || die $@;
    no strict 'refs';
    *{"${target}::${name}"} = $coderef;
}

# private function _merge($dest, $src)
# used to merge incoming db rows to a hash ref.
# hash table entries in $src overwrite those in $dest.
# Since this is an incoming row, we can generally assume we are not having to 
# do a deep copy.

sub _merge {
    my ($dest, $src) = @_;
    if (eval {$dest->can('has') and $dest->can('extends')}){
       # Moo or Moose.  Use accessors, though better would be to just return
       # objects in this case.
       for my $att (keys %$src){
           $dest->can($att)->($dest, $src->{$att}) if $dest->can($att);
       }
    } else {
        $dest->{$_} = $src->{$_} for (keys %$src);
    }
}

# private method _process_args.
# first arg $arrayref of argnames
# after that we just pass in @_ from the function call
# then we return a hash with the args as specified.

sub _process_args {
    my $arglist = shift @_;
    my @args = @_;

    my $arghref = {};

    my $maxlen = scalar @_;
    my $it = 1;
    for my $argname (@$arglist){
        last if $it > $maxlen;
        $arghref->{$argname} = shift @args;
        ++$it;
    }
    return $arghref;
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
