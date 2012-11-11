# Mock LWP::UA module
package LWP::UserAgent;

use warnings;
use strict;
use HTTP::Response;
use URI;

# LWP interface

sub new {
	my $class = shift;
	bless { @_ }, $class;
}

sub env_proxy {
	my $self = shift;
	$self->{_proxy_set} = 1;
}

sub get {
	my $self = shift;
	my $url = shift;
	return $self->_gen_resp($url);
}

sub timeout {
	1;
}

sub is_success {
	1;
}

# Mock helpers

sub _gen_resp {
	my $self = shift;
	my $url = shift;
	my $fname = _mock_content_fname($url);

	return _gen_404($url) unless -r $fname;
	return _gen_200($url);
}

sub _gen_404 {
	return HTTP::Response->new(404, 'Not found');
}

sub _gen_200 {
	my $url = shift;
	my $data = _read_file(_mock_content_fname($url));

	return HTTP::Response->new(500, 'Internal server error')
		unless $data;

	return HTTP::Response->new(200, 'OK', [
		Server => 'Play! Framework;1.2.4;prod',
		'Content-Type' => 'text/html; charset=utf-8',
		'Cache-Control' => 'max-age=45',
		Date => 'Mon, 16 Jul 2012 22:08:20 GMT',
		'Content-Length' => '8479',
		Connection => 'keep-alive',
	], $data);
}

sub _read_file {
	my $fname = shift;
	open my $fh, '<', $fname
		or die("Could not open test data file $fname: $!");
	my $data = join '', <$fh>;
	close $fh;
	return $data;
}

sub _mock_headers_fname {
	my $uri = URI->new(shift);

	return sprintf 't/data/lwp/headers/%s/%s',
		$uri->host,
		$uri->path_query;
}

sub _mock_content_fname {
	my $uri = URI->new(shift);

	return sprintf 't/data/lwp/content/%s/%s',
		$uri->host,
		$uri->path_query;
}

1;
