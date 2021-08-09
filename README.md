# Redis module for V
[![build status](https://github.com/patrickpissurno/vredis/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/patrickpissurno/vredis/actions/workflows/build-and-test.yml)
[![license](https://img.shields.io/github/license/patrickpissurno/vredis.svg?maxAge=1800)](https://github.com/patrickpissurno/vredis/blob/master/LICENSE)

This module aims to be a full-featured Redis client for [V](https://vlang.io/)

> The version of this module will remain in `0.x.x` unless the language API's are finalized and implemented.

**Project is now compatible with the latest V version thanks to our new contributors**

#### Disclaimer
This project **is alive**, and I'm reviewing and merging pull requests as quickly as possible. Feel free to open PRs with improvements: as long as it keeps the code structure similar and passes the tests, it'll get merged. All features should have their own tests. Thanks!

## Docs

To be implemented. There will be some great docs, but only once I get most of the basic stuff sorted out. For the time being I suggest you to take a look at the test files. They'll provide you with enough to get started.

## Features already working
- GET
- GETSET
- GETRANGE
- RANDOMKEY
- EXISTS
- TYPE
- STRLEN
- TTL
- PTTL
- LPOP
- RPOP
- LLEN
- SET
- SETEX
- PSETEX
- SETNX
- INCR
- INCRBY
- INCRBYFLOAT
- APPEND
- SETRANGE
- DECR
- DECRBY
- LPUSH
- RPUSH
- EXPIRE
- PEXPIRE
- EXPIREAT
- PEXPIREAT
- PERSIST
- DEL
- RENAME
- RENAMENX
- FLUSHALL

## Installation

```
v up
v install patrickpissurno.redis
```

Or if you prefer using `vpkg`:

```
vpkg get redis
```

## Testing
Tests are being implemented alongside every feature. This module is being developed with a 100% coverage goal.

Every commit triggers GitHub Actions to build and test this module.

If you want to run tests manually, be sure to have a Redis server running locally at 127.0.0.1:6379. Then clone this repo and run:

```
v test .
```

## Contributors

- [Patrick Pissurno](https://github.com/patrickpissurno) - creator and maintainer
- [JalonSolov](https://github.com/JalonSolov) - ported to the latest V version
- [Delyan Angelov](https://github.com/spytheman) - fixed the new CI

## License

MIT License

Copyright (c) 2020-2021 Patrick Pissurno

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
