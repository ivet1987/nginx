package rhtshello;

use nginx;

sub handler {
    my $r = shift;

    $r->send_http_header("text/plain");
    return OK if $r->header_only;

    $r->print("Hello, nginx-perl-world\n");

    if (-f $r->filename or -d _) {
        $r->print($r->uri, " exists!\n");
    }

    return OK;
}

1;
__END__
