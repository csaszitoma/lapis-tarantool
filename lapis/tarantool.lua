local config = require(('lapis.config').get())
local tnt
if ngx then
  tnt = require('resty.tarantool')
end
local tnt_down = nil
local connect_tnt
connect_tnt = function()
  local tnt_config = config.tarantool
  if not (tnt_config) then
    return nil, "tarantool not configured"
  end
  local tar, err = tnt:new({
    host = tnt_config.host,
    port = tnt_config.port,
    user = tnt_config.user,
    password = tnt_config.password,
    socket_timeout = tnt_config.socket_timeout
  })
  local ok = tar:connect()
  if ok then
    return tar, nil
  else
    tnt_down = ngx.time()
    return k, err
  end
end
local get_tnt
get_tnt = function()
  if not (tnt) then
    return nil, "missing tarantool library"
  end
  if tnt_down and tnt_down + 60 > ngx.time() then
    return nil, "tarantool down"
  end
  local tar = ngx.ctx.tar
  if not (tar) then
    local after_dispatch
    after_dispatch = require("lapis.nginx.context").after_dispatch
    local err
    tar, err = connect_tnt()
    if not (tar) then
      return nil, err
    end
    ngx.ctx.tar = tar
    after_dispatch(function()
      tar:set_keepalive()
      ngx.ctx.tar = nil
    end)
  end
  return tar
end
local tnt_cache
tnt_cache = function(space)
  return function(req)
    tnt = get_tnt()
    return {
      get = function(self, key)
        if not (tnt) then
          return 
        end
        local out = tar:select(space, "primary", key)
        if out == ngx.null or not out[1] then
          return nil
        end
        return out[1]
      end,
      set = function(self, key, content, expire)
        if not (tar) then
          return 
        end
        return tar:insert(space, key, expire, content)
      end
    }
  end
end
return {
  get_tnt = get_tnt,
  tnt_cache = tnt_cache
}
