package Media::HLS::Client;
our $VERSION = 0.1;
use 5.010;
use warnings;
use strict;
use Method::Signatures::Simple;
use Readonly;
use LWP::UserAgent;

Readonly our $Supports => 4;

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless {
		version => 1,
		status => 'ok',
		cache => 1,
		error => 'success',
		uri => $args{uri},
	}, $class;

	$self->__load();
	return $self;
}

method version {
	return $self->{version};
}

method cache {
	return $self->{cache};
}

method status {
	return $self->{status};
}

method error {
	return $self->{error};
}

method __error {
	$self->{error} = shift;
	$self->{status} = 'error';
}

method __fetch {
	my $ua = LWP::UserAgent->new();
	$ua->timeout(10);
	$ua->env_proxy;

	my $resp = $ua->get($self->{uri});

	if (! $resp->is_success) {
		$self->__error(
			sprintf 'Could not fetch url (%s)', $resp->status_line
		);
		return;
	}

	return $resp->decoded_content;
}

method __set_hls_version {
	my $line = shift;
	$self->{version} = $1 if $line =~ /^#EXT-X-VERSION:([0-9]+)$/;
}

method __set_hls_cache {
	my $line = shift;

	# Default is yes. Only way to disable is this exact string.
	$self->{cache} = 0 if $line eq '#EXT-X-CACHE:NO';
}

method __parse_m3ue {
	my %dispatch = (
		'EXT-X-VERSION' => method { $self->__set_hls_version(@_) },
		'EXT-X-CACHE' => method { $self->__set_hls_cache(@_) },
	);

	while (@_) {
		local $_ = shift;

		next if /^#(?!EXT)/; # ignore comments
		if (my ($directive) = /^#(EXT[^:]+)/) {
			$dispatch{$directive}->($self, $_, \@_)
				if exists $dispatch{$directive};

			# Spec defines that unknown directives
			# should be ignored.
		}
	}
}

method __load {
	my $playlist = $self->__fetch or return;

	my ($head, @m3u) = split /\n/, $playlist;
	if ($head ne '#EXTM3U') {
		$self->__err('URI is not an M3UE file (so not an HLS stream)');
		return;
	}

	$self->__parse_m3ue(@m3u);
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

=head2 version

Returns the HLS version used by the stream. Corresponds to the
EXT-X-VERSION field in HLS.

=head2 cache

Is this media allowed to be cached? Corresponds to the EXT-X-

=head2 status

Returns the status of the HLS parsing. It can be either of the strings
'ok' or 'error'. If the status is 'error', refer to the error method
for information what's actually wrong; the object is unusable, except
for the error method --- reliying on any information from the object
is undefined.

=head2 error

If status is 'ok', returns the error message. Otherwise, returns the
string 'success'.

=head1 REFERENCES

=over

=item 1. draft-pantos-http-live-streaming-08

This document can be found in doc/draft-pantos-http-live-streaming-08
in the repository.

=back

=cut

1;
