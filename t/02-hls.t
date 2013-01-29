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

	note "Testing $uri";
	my $hls = new_ok('Media::HLS::Client' => [ uri => $uri ]);

	is($hls->status, $ref->{status} // 'ok', 'Successful HLS request');
	is($hls->uri, $uri, 'URI attribute');

	SKIP: {
		skip 'HLS failed: ' . $hls->error, 2 if $hls->status eq 'error';
		test_valid_hls($hls, $ref);
	}
}

sub test_valid_hls {
	my $hls = shift;
	my $ref = shift;

	is(
		$hls->version, $ref->{version},
		"Stream is version $ref->{version}"
	);

	is(
		$hls->cache, $ref->{cache}, ($ref->{cache} ?
			'Stream is allowed to be cached'   :
			'Stream is NOT allowed to be cached'
	));

	my $has_variants = $ref->{variants} && @{$ref->{variants}};
	is($hls->variants ? 1 : 0, $has_variants ? 1 : 0, $has_variants ?
		'Playlist has variants' : 'Playlist does not have variants'
	);

	SKIP: {
		skip 'Not a variant playlist', 1 unless $has_variants;

		is(
			int $hls->variants,
			int @{$ref->{variants}},
			'Number of variants'
		);
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

		variants => [
			{
				'http://example.com/test_0.m3u8' => {
					version => 2,
					cache => 1,
				},
			},
			{
				'http://example.com/test_1.m3u8' => {
					version => 2,
					cache => 1,
				},
			},
			{
				'http://example.com/test_2.m3u8' => {
					version => 2,
					cache => 1,
				},
			},
			{
				'http://example.com/test_3.m3u8' => {
					version => 2,
					cache => 1,
				},
			},
			{
				'http://example.com/test_4.m3u8' => {
					version => 2,
					cache => 1,
				},
			},
			{
				'http://example.com/test_5.m3u8' => {
					version => 2,
					cache => 1,
				},
			},
		],
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
