# Oso

Audiosocket's minimal URL shortener. It's named "oso" because those
three letters look a bit like our logo.

## Configuring

Oso probably expects Ruby 1.9.2, since that's what we deploy. YMMV.

If you install the deps in the `Isolate` file you can run `rackup` by
itself. If you'd like to use Isolate to manage deps, `gem install
isolate` and run `rake` instead (it'll call `rackup` from inside the
isolated environment).

Oso needs Redis. Set the `OSO_REDIS_URL` environment variable, which
defaults to `redis://localhost:6379`. All keys are namespaced under
`oso:`.

## Deploying

Oso is prepped for Heroku. It has an up-to-date `.gems` manifest, and
it'll use the `REDISTOGO_URL` env var if it exists. You're on your own
in any other environment, but it's going to be easy.

## License

Copyright 2011 Leopona Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
‘Software’), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
