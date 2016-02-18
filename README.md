
# `lapis-tarantool`

This module is used for integrating [Tarantool](http://tarantool.org) with
[Lapis](http://leafo.net/lapis). It uses the
[`lua-resty-tarantool`](https://github.com/openresty/lua-resty-tarantool) module.

## Installing

```bash
$ luarocks install lapis-tarantool
```

## Configuring

```moonscript
-- config.moon

config "development", ->
  tarantool {
    host: '127.0.0.1',
    port: 6379,
    user: 'lapisuser',
    password: 'mypasword'
  }

```

## Connecting

The function `get_tnt` can be used to get the current request's Tarantool
connection. If there's not connection established for the request a new one
will be opened. After the request completes the Tarantool connection will
automatically be recycled for future requests.

The return value of `get_tnt` is a connected
[`lua-resty-tarantool`](https://github.com/openresty/lua-resty-tarantool#methods)
object.

```moon
import get_tnt from require "lapis.tarantool"

class App extends lapis.Application
  "/": =>
    tnt = get_tnt!
    tnt\select "users", "3453489"

```


## Tarantool cache

You can use Tarantool as a cache using the [Lapis caching
API](http://leafo.net/lapis/reference/utilities.html#caching-cachedfn_or_tbl).

```moon
import cached from require "lapis.cache"
import tnt_cache from require "lapis.tarantool"

class App extends lapis.Application
  "/hello": cached {
    dict: tnt_cache "cache-prefix"
    =>
      @html ->
        div "hello"
  }
```

