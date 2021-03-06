package Media::HLS::Client;
our $VERSION = 0.1;
use 5.010;
use warnings;
use strict;
use Moo;
use LWP::UserAgent;
use Parse::M3U::Extended qw(m3u_parser);

sub supports { return 4 }

has version => (
	is => 'rwp',
	default => sub { 1 },
);

has cache => (
	is => 'rwp',
	default => sub { 1 },
);

has uri => (
	is => 'ro',
);

has variants => (
	is => 'lazy',
);

has status => (
	is => 'rwp',
	default => sub { 'ok' },
);

has error => (
	is => 'rwp',
	trigger => sub { my $s = shift; $s->_set_status('error') },
);


sub BUILD {
	my $self = shift;

	$self->{__variants} = [];

	my $m3u = $self->__fetch();
	my $hls = $self->__load($m3u);
}

sub __fetch {
	my $self = shift;
	my $ua = LWP::UserAgent->new();
	$ua->timeout(10);
	$ua->env_proxy;

	my $resp = $ua->get($self->uri);

	if (! $resp->is_success) {
		$self->_set_error(
			sprintf 'Could not fetch url (%s)', $resp->status_line
		);
		return;
	}

	return $resp->decoded_content;
}

sub _build_variants {
	my $self = shift;
	return @{$self->{__variants}};
}

sub __handle_variant {
	my $self = shift;
	my $line = shift;
	my $v_tok = shift;
	push @{$self->{__variants}}, Media::HLS::Client->new(
		uri => $v_tok->{value},
	);
}

sub __set_cache {
	my $self = shift;
	my $line = shift;
	$self->_set_cache(not $line->{value} eq 'NO');
}

sub __set_version {
	my $self = shift;
	my $line = shift;
	$self->_set_version($line->{value});
}

sub __analyze_m3ue {
	my $self = shift;

	my %tagcb = (
		'EXT-X-STREAM-INF' => sub { $self->__handle_variant(@_) },
		'EXT-X-ALLOW-CACHE' => sub { $self->__set_cache(@_) },
		'EXT-X-VERSION' => sub { $self->__set_version(@_) },
	);

	while (my $line = shift) {
		my $type = $line->{type};
		next if $type eq 'comment';

		if ($type eq 'directive') {
			my $tag = $line->{tag};
			$tagcb{$tag}->($line, @_) if exists $tagcb{$tag};
		}
	}
}

sub __load {
	my $self = shift;
	my $m3u = shift;
	$self->__analyze_m3ue(m3u_parser($m3u));
}

=head1 NAME

Media::HLS::Client - a HLS client implementation

=head1 DESCRIPTION

Media::HLS::Client implements parsing of the Extended M3U file format,
according to the HLS specification (version 4), as defined in [1].

=head1 CONSTRUCTOR

 Media::HLS->new(
     uri => $uri,
 );

=head1 METHODS

=head2 uri

Returns the URI (as supplied in the constructor).

=head2 version

Returns the HLS version used by the stream. Corresponds to the
EXT-X-VERSION field in HLS.

=head2 cache

Is this media allowed to be cached? Corresponds to the EXT-X-

=head2 variants

Returns the variants as Media::HLS::Client objects, if any.

=head2 status

Returns the status of the HLS parsing. It can be either of the strings
'ok' or 'error'. If the status is 'error', refer to the error method
for information what's actually wrong; the object is unusable, except
for the error method --- reliying on any information from the object
is undefined.

=head2 error

If status is 'ok', returns the error message. Otherwise, returns the
string 'success'.

=head1 FUNCTIONS

=head2 supports

Returns the highest HLS version supported by the module. (Currently
4). Can be called as a method or as a function.

=head1 REFERENCES

=over

=item 1. draft-pantos-http-live-streaming-08

This document can be found in doc/draft-pantos-http-live-streaming-08
in the repository.

=back

=cut

1;
