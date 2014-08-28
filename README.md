# Description

Adenosine is a tiny script wrapper for [curl](http://curl.haxx.se/). It
provides a simple, concise shell interface for interacting with
[REST](http://en.wikipedia.org/wiki/Representational_State_Transfer) services.
Since it is just a command you run in your shell and not in its own separate
command environment you have access to all the powerful shell tools, such
as perl, awk, grep, sed, etc. You can use adenosine in pipelines to process data
from REST services, and PUT or POST the data right back.  You can even pipe
the data in and then edit it interactively in your text editor prior to PUT
or POST.

Cookies are supported automatically and stored in a file locally. Most of
the arguments are remembered from one call to the next to save typing. It
has pretty good defaults for most purposes. Additionally, adenosine allows you
to easily provide your own options to be passed directly to curl, so even
the most complex requests can be accomplished with the minimum amount of
command line pain.

[Here is a nice screencast showing adenosine (n�e resty) in action](http://jpmens.net/2010/04/26/resty/)
(by Jan-Piet Mens).

# Quick Start

## From git

Grab the files from github:

      $ git clone http://github.com/frioux/app-adenosine-prefab

Source the exports before using it. (You can put this line in your `~/.bashrc`
file if you want.)

      $ . app-adenosine-prefab/adenosine-exports

## From CPAN

If you are a Perl user you can install adenosine from CPAN as follows:

      $ cpanm App::Adenosine

And then source the function wrappers as follows:

      $ eval $(adenosine exports)

Set the REST host to which you will be making your requests (you can do this
whenever you want to change hosts, anytime).

      $ adenosine http://127.0.0.1:8080/data
      http://127.0.0.1:8080/data*

Make some HTTP requests.

      $ GET /blogs.json
      [ {"id" : 1, "title" : "first post", "body" : "This is the first post"}, ... ]

      $ PUT /blogs/2.json '{"id" : 2, "title" : "updated post", "body" : "This is the new."}'
      {"id" : 2, "title" : "updated post", "body" : "This is the new."}

      $ DELETE /blogs/2

      $ POST /blogs.json '{"title" : "new post", "body" : "This is the new new."}'
      {"id" : 204, "title" : "new post", "body" : "This is the new new."}

# What's Next?

Check out some of the plugins available for adenosine!  Right now there's just
two, `Rainbow` and `Stopwatch`.  To use them, edit the `bin/adenosine` file and
uncomment the plugin lines.

# Hacking!

Want to add some features?  Fork the `frioux/app-adenosine` repository and send
pull requests!

# A Work In Progress

Adenosine was ported to Perl from [resty](https://github.com/micha/resty) due
to a number of [issues](https://github.com/micha/resty/issues).  Because
adenosine is not a simple shell function it does not use env vars as much, and
so is less "persistent" than resty when it comes to various settings.  I'm
completely willing to fix this by wrapping adenosine with a small shell
function that sets various environment variables, but I'd rather get it
released with a few exciting features resty does not have.  With that in mind,
patches are always welcome.  Please get in touch if you'd like one of the
currently unsupported resty features to be fixed and I'll certainly do what I
can to get it working.  Any part of the doc marked with `!!!` is a place to
look out for an imcompatibility.

# Usage

      source adenosine-exports [-W] [remote] # load functions into shell         !!!
      adenosine [-v]                         # prints current request URI base   !!!
      adenosine <remote> [OPTIONS]           # sets the base request URI         !!!

      HEAD [path] [OPTIONS]                   # HEAD request
      OPTIONS [path] [OPTIONS]                # OPTIONS request
      GET [path] [OPTIONS]                    # GET request
      DELETE [path] [OPTIONS]                 # DELETE request
      PUT [path] [data] [OPTIONS]             # PUT request
      POST [path] [data] [OPTIONS]            # POST request
      TRACE [path] [OPTIONS]                  # TRACE request
      PATCH [path] [OPTIONS]                  # PATCH request

      Options:

      -Q            Don't URL encode the path.
      -q <query>    Send query string with the path. A '?' is prepended to
                    <query> and concatenated onto the <path>.
      -W            Don't write to history file (only when sourcing script).    !!!
      -V            Edit the input data interactively in 'vi'. (PUT and POST
                    requests only, with data piped to stdin.)
      -v            Verbose output. When used with the adenosine command itself
                    this prints the saved curl options along with the current
                    URI base. Otherwise this is passed to curl for verbose
                    curl output.
      <curl opt>    Any curl options will be passed down to curl.

# Configuration, Data File Locations

Adenosine creates a few files in either your `${XDG_CONFIG_HOME}` and `${XDG_DATA_HOME}`
directory (if your system uses the XDG directory standard) or in the `~/.resty`
directory, otherwise.

## Using Existing, Pre-v2.1 Configuration Files With v2.1

If you had resty installed before version 2.1 and your system uses the XDG
config directory standard and you want to continue using your existing
configuration files, please make a backup of your `~/.resty` directory
and then do:

      $ mkdir -p "${XDG_CONFIG_HOME}/resty" "${XDG_DATA_HOME}/resty"
      $ mv ~/.resty/c "${XDG_DATA_HOME}/resty"
      $ mv ~/.resty/* "${XDG_CONFIG_HOME}/resty"

# Request URI Base

The request URI base is what the eventual URI to which the requests will be
made is based on. Specifically, it is a URI that may contain the `*` character
one or more times. The `*` will be replaced with the `path` parameter in the
`OPTIONS`, `HEAD`, `GET`, `POST`, `PUT`, `PATCH` or `DELETE` request as
described above.

For example:

      $ adenosine 'http://127.0.0.1:8080/data*.json'
      http://127.0.0.1:8080/data*.json

and then

      $ GET /5
      { "the_response" : true }

would result in a \`GET\` request to the URI `http://127.0.0.1:8080/data/5.json`.

If no `*` character is specified when setting the base URI, it's just added
onto the end for you automatically.

## HTTPS URIs

HTTPS URIs can be used, as well. For example:

      $ adenosine 'https://example.com/doit'
      https://example.com/doit*

## URI Base History

The URI base is saved to an rc file (`${XDG_CONFIG_HOME}/resty/host` or `~/.resty/host`)
each time it's set, and the last setting is saved in an environment variable `!!!`
(`$_resty_host`).  The URI base is read from the rc file when resty starts
up, but only if the `$_resty_host` environment variable is not set.
In this way you can make requests to different hosts using resty from
separate terminals, and have a different URI base for each terminal.

If you want to see what the current URI base is, just run `adenosine` with no
arguments. The URI base will be printed to stdout.

# The Optional Path Parameter

The HTTP verbs (`OPTIONS`, `HEAD`, `GET`, `POST`, `PUT`, `PATCH` and
`DELETE`) first argument is always
an optional URI path. This path must always start with a `/` character. If
the path parameter is not provided on the command line, adenosine will just use
the last path it was provided with. This "last path" is stored in an
environment variable (`$_resty_path`), so each terminal basically has its `!!!`
own "last path".

## URL Encoding Of Path Parameter

Adenosine will always
[URL encode](http://www.blooberry.com/indexdot/html/topics/urlencoding.htm) the
path, except for slashes. (Slashes in path elements need to be manually
encoded as `%2F`.) This means that the `?`, `=`, and `&` characters will
be encoded, as well as some other problematic characters. To disable this
behavior use the `-Q` option.

## Query Strings, POST Parameters, And Both At The Same Time

There are three ways to add a query string to the path. The first, mentioned
above, is to disable URL encoding with the `-Q` option, and include the
query string with the path parameter, like this:

      $ GET '/blogs/47?param=foo&otherparam=bar' -Q

To specify a query string without disabling URL encoding on the path the
`-q` option is used, like this:

      $ GET /blogs/47 -q 'param=foo&otherparam=bar'

Finally, you can use the curl `-d` and `-G` options, like this:

      $ GET /blogs/47 -d 'param=foo' -d 'otherparam=bar' -G

However, if you want to pass both GET parameters in the query string **and**
POST parameters in the request body, curl cannot support this by itself.
Using the `-q` or `-Q` adenosine options with the `-d` curl option will accomplish
this, like so:

      $ POST '/blogs/47?param=foo&otherparam=bar' -Q -d 'postparam=baz'

# POST/PUT Requests and Data

Normally you would probably want to provide the request body data right on
the command line like this:

      $ PUT /blogs/5.json '{"title" : "hello", "body" : "this is it"}'

But sometimes you will want to send the request body from a file instead. To
do that you pipe in the contents of the file:

      $ PUT /blogs/5.json < /tmp/t # !!!

Or you can pipe the data from another program, like this:

      $ myprog | PUT /blogs/5.json # !!!

Or, interestingly, as a filter pipeline with
`jsawk|http://github.com/micha/jsawk`:

      $ GET /blogs/5.json | jsawk 'this.author="Bob Smith";this.tags.push("news")' | PUT

Notice how the `path` argument is omitted from the `PUT` command.

## Edit PUT/POST Data In Vi

With the `-V` options you can pipe data into `PUT` or `POST`, edit it in vi,
save the data (using `:wq` in vi, as normal) and the resulting data is then
PUT or POSTed. This is similar to the way `visudo` works, for example.

      $ GET /blogs/2 | PUT -V

This fetches the data and lets you edit it, and then does a PUT on the
resource. If you don't like vi you can specify your preferred editor by
setting the `EDITOR` environment variable.

# Errors and Output

For successful 2xx responses, the response body is printed on stdout. You
can pipe the output to stuff, process it, and then pipe it back to adenosine,
if you want.

For responses other than 2xx the response body is dumped to stderr.

# Passing Command Line Options To Curl

Anything after the (optional) `path` and `data` arguments is passed on to
`curl`.

For example:

      $ GET /blogs.json -H "Range: items=1-10"

The `-H "Range: items=1-10"` argument will be passed to `curl` for you. This
makes it possible to do some more complex operations when necessary.

      $ POST -v -u user:test

In this example the `path` and `data` arguments were left off, but `-v` and
`-u user:test` will be passed through to `curl`, as you would expect.

Here are some useful options to try:

- `-v`

    verbose output, shows HTTP headers and status on stderr

- `-j`

    junk session cookies (refresh cookie-based session)

- <-u $username:$password>

    HTTP basic authentication

- <-H $header>

    add request header (this option can be added more than once)

## Setting The Default Curl Options

Sometimes you want to send some options to curl for every request. It
would be tedious to have to repeat these options constantly. To tell
adenosine to always add certain curl options you can specify those options
when you call adenosine to set the URI base. For example:

      $ adenosine example.com:8080 -H "Accept: application/json" -u user:pass

Every subsequent request will have the `-H "Accept:..."` and `-u user:...`
options automatically added. Each time adenosine is called this option list
is reset.

## Per-Host/Per-Method Curl Configuration Files

Adenosine supports a per-host/per-method configuration file to help you with
frequently used curl options. Each host (including the port) can have its
own configuration file in the `~/.resty` directory. The file format is

      $ GET [arg] [arg] ...
      $ PUT [arg] [arg] ...
      $ POST [arg] [arg] ...
      $ DELETE [arg] [arg] ...

Where the `arg`s are curl command line arguments. Each line can specify
arguments for that HTTP verb only, and all lines are optional.

So, suppose you find yourself using the same curl options over and over. You
can save them in a file and adenosine will pass them to curl for you. Say this
is a frequent pattern for you:

      $ adenosine localhost:8080
      $ GET /Blah -H "Accept: application/json"
      $ GET /Other -H "Accept: application/json"
      ...
      $ POST /Something -H "Content-Type: text/plain" -u user:pass
      $ POST /SomethingElse -H "Content-Type: text/plain" -u user:pass
      ...

It's annoying to add the `-H` and `-u` options to curl all the time. So
create a file `~/.resty/localhost:8080`, like this:

`~/.resty/localhost:8080`

      GET -H "Accept: application/json"
      POST -H "Content-Type: text/plain" -u user:pass

Then any GET or POST requests to localhost:8080 will have the specified
options prepended to the curl command line arguments, saving you from having
to type them out each time, like this:

      $ GET /Blah
      $ GET /Other
      ...
      $ POST /Something
      $ POST /SomethingElse
      ...

Sweet! Much better.

# Exit Status

Successful requests (HTTP respose with 2xx status) return zero.
Otherwise, the first digit of the response status is returned (i.e., 1 for
1xx, 3 for 3xx, 4 for 4xx, etc.) This is because the exit status is an 8 bit
integer---it can't be greater than 255. If you want the exact status code
you can always just pass the `-v` option to curl.

# Using Adenosine In Shell Scripts `!!!`

Since adenosine creates the REST verb functions in the shell, when
using it from a script you must `source` it before you use any of the
functions. However, it's likely that you don't want it to be overwriting the
adenosine host history file, and you will almost always want to set the URI
base explicitly.

      #!/usr/bin/env bash

      # Load adenosine, don't write to the history file, and set the URI base
      . /path/to/adenosine-exports -W 'https://myhost.com/data*.json'

      # GET the JSON list of users, set each of their 'disabled' properties
      # to 'false', and PUT the modified JSON back
      GET /users | jsawk 'this.disabled = false' | PUT

Here the `-W` option was used when loading the script to prevent writing
to the history file and an initial URI base was set at the same time. Then a
JSON file was fetched, edited using [jsawk](http://github.com/micha/jsawk),
and re-uploaded to the server.

# Application Configuration

Adenosine may be configured by placing a `YAML` document in
`~/.adenosinerc.yml`.  More parts of adenosine will be configurable as time
goes on, but right now the only real configuration is for plugins.

Adenosine's plugin architecture (documented at
["USING PLUGINS" in App::Adenosine](https://metacpan.org/pod/App::Adenosine#USING-PLUGINS) and ["CREATING PLUGINS" in App::Adenosine](https://metacpan.org/pod/App::Adenosine#CREATING-PLUGINS)) can be
used to color code headers, time the request, or more, if you choose to write
more plugins.  Enabling a plugin is simple with the `~/.adenosinerc.yml`
file.  Here is how you would enable both [App::Adenosine::Plugin::Stopwatch](https://metacpan.org/pod/App::Adenosine::Plugin::Stopwatch)
and [App::Adenosine::Plugin::Rainbow](https://metacpan.org/pod/App::Adenosine::Plugin::Rainbow), including a little bit of extra
(non-required) configuration to customize some colors for `::Rainbow`.

    plugins:
       - ::Stopwatch
       - ::Rainbow: {
             request_method_color: cyan
         }

The following would work if you didn't want to configure `::Rainbow`

    plugins:
       - ::Stopwatch
       - ::Rainbow

Another option allows the user to disable the XDG based directory structure
(typically `~/.config`).  Simply put the following in your
`~/.adenosinerc.yml`:

    enable_xdg: 0

# Working With JSON or XML Data

JSON REST web services require some special tools to make them accessible
and easily manipulated in the shell environment. The following are a few
scripts that make dealing with JSON data easier.

- [Jsawk](http://github.com/micha/jsawk) can be used to process and filter JSON
data from and to adenosine, in a shell pipeline. This takes care of parsing
the input JSON correctly, rather than using regexes and sed, awk, perl or
the like, and prints the resulting output in correct JSON format, as well.

        GET /blogs.json |jsawk -n 'out(this.title)' # prints all the blog titles

- The included `pp` script will pretty-print JSON for you.

        GET /blogs.json |pp # pretty-prints the JSON output from adenosine

- Another way to format JSON output:

          $ echo '{"json":"obj"}' | python -mjson.tool
          {
            "json": "obj"
          }

- The `tidy` tool can be used to format HTML/XML:

          $ ~$ echo "<test><deep>value</deep></test>" | tidy -xml -q -i
          <test>
            <deep>value</deep>
          </test>
