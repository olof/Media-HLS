#!/usr/bin/perl
use 5.012;
use lib 't/lib';
#use Test::More tests => 3;
use Test::More;

BEGIN { use_ok 'Media::HLS::Client' }

is(Media::HLS::Client::supports, 4, 'Implements HLS version 4');

sub test_uri {
	my $uri = shift;
	my $ref = shift;

	my $hls = new_ok('Media::HLS::Client' => [ uri => $uri ]);

	is($hls->status, 'ok', 'Successful HLS request');

	SKIP: {
		skip 'HLS failed: ' . $hls->error, 2 if $hls->status eq 'error';
		is(
			$hls->version, $ref->{version},
			"Stream is version $ref->{version}"
		);

		is(
			$hls->cache, $ref->{cache}, ($ref->{cache} ?
				'Stream is allowed to be cached'   :
				'Stream is NOT allowed to be cached'
		));
	}
}

# Each element in this URI is a "sub playlist" (EXT-X-STREAM-INF).
# It contains no other M3UE fields than EXTM3U and EXT-X-STREAM-INF.
test_uri(
	'http://example.com/test.m3u8' => {
		# If no EXT-X-VERSION is in the playlist, 1 must be assumed
		version => 1,

		# Cache=YES is implicit
		cache => 1,
	}
);

# This is actually one of the sub playlists of the previos test case.
# Its entries are actually the chunks of the video stream.
test_uri(
	'http://example.com/test_0.m3u8' => {
		version => 2,
		cache => 1,
	}
);

done_testing();
