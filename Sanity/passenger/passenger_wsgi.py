def application(environ, start_response):
    start_response('200 OK', [('Content-Type', 'text/plain')])
    return [b"Hello, this is a web application running on port %%PORT%%. How are you?\n"]
