#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile (
	NAME => 'Media::HLS::Client',
	AUTHOR => 'Olof Johansson <olof@cpan.org>',
	LICENSE => 'perl',
	ABSTRACT_FROM => 'lib/Media/HLS/Client.pm',
	VERSION_FROM => 'lib/Media/HLS/Client.pm',
	SIGN => 1,

	PREREQ_PM => {
		'LWP::UserAgent' => 0,
		'Moo' => 0,
		'Parse::M3U::Extended' => 0.1,
	},
);

