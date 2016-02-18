config = require 'lapis.config'.get!
tnt = if ngx then require 'resty.tarantool'

tnt_down = nil

connect_tnt = ->
  tnt_config = config.tarantool
  return nil, "tarantool not configured" unless tnt_config

  tar, err = tnt\new({
        host: tnt_config.host
        port: tnt_config.port,
        user: tnt_config.user,
        password: tnt_config.password,
        socket_timeout: tnt_config.socket_timeout
      })

  ok = tar\connect!

  if ok
    return tar, nil
  else
    tnt_down = ngx.time!
    return k, err

get_tnt = ->
  return nil, "missing tarantool library" unless tnt
  return nil, "tarantool down" if tnt_down and tnt_down + 60 > ngx.time!

  tar = ngx.ctx.tar
  unless tar
    import after_dispatch from require "lapis.nginx.context"

    tar, err = connect_tnt!
    return nil, err unless tar

    ngx.ctx.tar = tar
    after_dispatch ->
      tar\set_keepalive!
      ngx.ctx.tar = nil

  return tar

tnt_cache = (space) ->
  (req) ->
    tnt = get_tnt!

    {
      get: (key) =>
        return unless tnt
        out = tar\select(space, "primary", key)
        return nil if out == ngx.null or not out[1]
        out[1]

      set: (key, content, expire) =>
        return unless tar
        tar\insert(space, key, expire, content)

    }


{ :get_tnt, :tnt_cache }

