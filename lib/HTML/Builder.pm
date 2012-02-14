#
# This file is part of HTML-Builder
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package HTML::Builder;
{
  $HTML::Builder::VERSION = '0.001';
}

# ABSTRACT: A declarative approach to HTML generation

use v5.10;

use strict;
use warnings;

use Capture::Tiny 0.15 'capture_stdout';
use CGI ();
use HTML::Tiny;
use Sub::Install;
use List::MoreUtils 'uniq';

# debugging...
#use Smart::Comments;

my @tags;


sub our_tags {
    state $tags = [ uniq sort
        #grep { ! /^(state)$/ }
        map { @{$_} }
        map { $CGI::EXPORT_TAGS{$_} // [] }
        qw{ :html2 :html3 :html4 }
    ];

    return @$tags;
}

BEGIN {

    sub _is_autoload_gen {
        my ($attr_href) = @_;

        return sub {
            shift;

            my $field = our $AUTOLOAD;
            $field =~ s/.*:://;

            # XXX
            $field =~ s/__/:/g;   # xml__lang  is 'foo' ====> xml:lang="foo"
            $field =~ s/_/-/g;    # http_equiv is 'bar' ====> http-equiv="bar"

            # Squash empty values, but not '0' values
            my $val = join ' ', grep { defined $_ && $_ ne '' } @_;

            #push @$attr_aref, $field => $val;
            $attr_href->{$field} = $val;

            return;
        };
    }

    my $h = HTML::Tiny->new;

    sub tag($&) {
        my ($tag, $inner_coderef) = @_;

        ### @_
        my %attrs = ();

        # This is almost completely stolen from Template::Declare::Tags, and
        # completely terrifying in that it confirms my dark suspicions on how
        # it was achieved over there.
        no warnings 'once', 'redefine';
        local *gets::AUTOLOAD = _is_autoload_gen(\%attrs);
        my $inner = q{};
        my $stdout = capture_stdout { $inner .= $inner_coderef->() || q{} };

        ### $stdout
        return $h->tag($tag, \%attrs, "$stdout$inner");
    }

    @tags = our_tags();

    for my $tag (@tags) {

        Sub::Install::install_sub({
            code => sub(&) { unshift @_, $tag; goto \&tag },
            as   => $tag,
        });
    }
}

use Sub::Exporter -setup => {

    exports => [ @tags ],
    groups  => {

        default    => ':moose_safe',
        moose_safe => [ grep { ! /^(meta|with)/ } @tags ],

        minimal => [ 'h1'..'h5', qw{
            div p img script br ul ol li style a
        } ],
    },
};

!!42;



=pod

=encoding utf-8

=head1 NAME

HTML::Builder - A declarative approach to HTML generation

=head1 VERSION

This document describes 0.001 of HTML::Builder - released February 14, 2012 as part of HTML-Builder.

=head1 SYNOPSIS

    use HTML::Builder ':minimal';

    # $html is: <div id="main"><p>Something, huh?</p></div>
    my $html = div { id gets 'main'; p { 'Something, huh?' } };

=head1 DESCRIPTION

A quick and dirty set of helper functions to make generating small bits of
HTML a little less tedious.

=head1 FUNCTIONS

=head2 our_tags

A unique, sorted list of the HTML tags we know about (and handle).

=head2 tag($tag_name, $code_ref)

The actual function responsible for handling the tagging.  All of the helper
functions pass off to tag() (e.g. C<div()> is C<sub div(&) { unshift 'div';
goto \&tag }>).

=head1 USAGE

Each supported HTML tag takes a coderef, executes it, and returns the output
the coderef writes to STDOUT with the return value appended.

That is:

    div { say h1 { 'Hi there! }; p { "Nice day, isn't it?" } }

Generates:

    <div><h1>Hi there!</h1><p>Nice day, isn't it?</p></div>

Element attributes are handled by specifying them with C<gets>.  e.g.:

    div { id gets 'main'; 'Hi!' }

Generates:

    <div id="main">Hi!</div>

L<gets> may be specified multiple times, for multiple attributes.

=head1 EXPORTED FUNCTIONS

Each tag we handle is capable of being exported, and called with a coderef.
This coderef is executed, and the return is wrapped in the tag.  Attributes on
the tag can be set from within the coderef by using L<gets>, a la C<id gets
'foo'>.

=head2 Export Groups

=head3 all

Everything.

Well, what C<@CGI::EXPORT_TAGS{qw{ :html2 :html3 :html4 }}> thinks is
everything, at any rate.

This isn't, perhaps, optimal, but I haven't run into any issues with it yet.
That being said, I'm open to changing our tags list, and where it's generated
from.

=head3 minimal

A basic set of the most commonly used tags:

    h1..h4 div p img script br ul ol li style a

=head3 moose_safe

Everything, except tags that would conflict with L<Moose> sugar (currently
C<meta>).

=head1 ACKNOWLEDGMENTS

This package was inspired by L<Template::Declare::Tags>... In particular, our
C<gets::AUTOLOAD> is pretty much a straight-up copy of Template::Declare::Tags'
C<is::AUTOLOAD>, with some modifications.  We also pass off to L<HTML::Tiny>,
and allow it to do the work of actually generating the output.  Thanks! :)

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<L<CGI> (in particular, C<%CGI::EXPORT_TAGS>)|L<CGI> (in particular, C<%CGI::EXPORT_TAGS>)>

=item *

L<HTML::Tiny>

=item *

L<Template::Declare::Tags>

=back

=head1 SOURCE

The development version is on github at L<http://github.com/RsrchBoy/html-builder>
and may be cloned from L<git://github.com/RsrchBoy/html-builder.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/html-builder/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut


__END__


