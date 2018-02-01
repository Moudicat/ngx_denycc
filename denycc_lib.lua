require 'config'

function getIP()
  local clientIP = ngx.req.get_headers()["X-Real-IP"]

  if clientIP == nil then
    clientIP = ngx.req.get_headers()["x-forwarded-for"]
    if clientIP == nil then
      clientIP = ngx.var.remote_addr
      if clientIP == nil then
        clientIP = "unknown"
      end
    end
  end

  return clientIP
end

function saveLog2File(logfile, data)
  local fd, err = io.open(logfile, "a")

  if fd == nil then
    --ngx.log(ngx.WARN, err)
    return false
  end

  fd:write(data)
  fd:flush()
  fd:close()
end

function log(key)
  if logger == "on" then
    local userAgent = ngx.var.http_user_agent
    local serverName = ngx.var.server_name
    local time = ngx.localtime()

    local filePath = logPath.."/"..serverName.."_"..ngx.today()..".log"
    local msg = "["..time.."] "..key.." "..userAgent.."\n"

    saveLog2File(filePath, msg)
  end
end

function denycc(limitCount, limitTime)
  if limitCount == nil then
    limitCount = defaultLimitCount
  end

  if limitTime == nil then
    limitTime = defaultLimitTime
  end

  local uri = ngx.var.uri
  local key = "("..getIP()..")"..uri
  local record = ngx.shared.record
  local value, err = record:get(key)
  if value then
    if value > limitCount then
      log(key)
      ngx.exit(503)
      return true
    else
      record:incr(key, 1)
    end
  else
    record:set(key, 1, limitTime)
  end

  return false
end
