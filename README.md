# Redis module for V

This module aims to be a full-featured Redis client for [V](https://vlang.io/)

> The version of this module will remain in `0.x.x` unless the language API's are finalized and implemented.

## Docs

To be implemented. There will be some great docs, but only once I get most of the basic stuff sorted out. For the time being I suggest you to take a look at the test files. They'll provide you with enough to get started.

## Features already working
- GET
- GETSET
- TTL
- PTTL
- SET
- SETEX
- PSETEX
- SETNX
- INCR
- INCRBY
- INCRBYFLOAT
- DECR
- DECRBY
- EXPIRE
- PEXPIRE
- EXPIREAT
- PEXPIREAT
- DEL
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

Are being implemented with every feature (100% code coverage in mind)

## License

[MIT](LICENSE)

## Contributors

- [Patrick Pissurno](https://github.com/patrickpissurno) - creator and maintainer
