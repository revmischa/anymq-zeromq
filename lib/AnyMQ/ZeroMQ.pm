package AnyMQ::ZeroMQ;

use 5.006;

use Any::Moose;

=head1 NAME

AnyMQ::ZeroMQ - AnyMQ adaptor to talk to ZeroMQ

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

  my $bus = AnyMQ->new_with_traits(
      traits  => ['ZeroMQ'],
      address => 'localhost:4000',
  );

=head1 AUTHOR

Mischa Spiegelmock, C<< <revmischa at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-anymq-zeromq at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AnyMQ-ZeroMQ>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AnyMQ::ZeroMQ


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AnyMQ-ZeroMQ>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AnyMQ-ZeroMQ>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AnyMQ-ZeroMQ>

=item * Search CPAN

L<http://search.cpan.org/dist/AnyMQ-ZeroMQ/>

=back


=head1 ACKNOWLEDGEMENTS

L<AnyMQ>, L<AnyEvent::ZeroMQ>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Mischa Spiegelmock.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of AnyMQ::ZeroMQ
