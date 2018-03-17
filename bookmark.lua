local mp = require 'mp'
local utils = require 'mp.utils'
local options = require 'mp.options'

local M = {}

local o = {
    save_period = 30
}
options.read_options(o)

local cwd_root = utils.getcwd()
print("CWD:"..cwd_root)

local play_root
local play_name
local play_path
local play_time

local mark_name = ".mpv.bookmark"
local mark_path

function M.show(msg, mllion) 
    mp.commandv("show-text", msg, mllion)
end

function M.load_mark()
    local file = io.open(mark_path, "r")
    if file == nil then
        print("read fail:"..mark_path)
        return false
    end
    play_name = file:read()
    if play_name == nil then
        file:close()
        return false
    else
        play_path = play_root.."/"..play_name
    end
    play_time = file:read('*n')
    if play_time == nil then
        file:close()
        return false
    end
    file:close()
    return true
end

function M.save_mark()
    local name = mp.get_property("filename")
    local time = mp.get_property("time-pos", 0)
    if not(name == nil or time == 0) then
        local file = io.open(mark_path, "w")
        file:write(name.."\n")
        file:write(time)
        print("save:"..name.." : "..time)
        file:close()
    end
end

function M.pause(name, paused)
    if paused then
        M.save_period_timer:stop()
        M.save_mark()
    else
        M.save_period_timer:resume()
    end
end

function M.hms(time_s)
    local ts = math.modf(time_s)
    local h = math.modf(ts/3600)
    ts = ts % 3600
    local m = math.modf(ts/60)
    s = ts % 60
    local time = ""..h..':'
    if m < 10 then
        time = time.."0"
    end
    time = time..m..':'
    if s < 10 then
        time = time.."0"
    end
    time = time..s
    return time
end

local timeout = 20
function M.jump()
    timeout = timeout - 1
    if(timeout < 1) then
         M.wait_jump:kill()
         M.unbind_key()
    end
    local msg = ''
    if timeout < 10 then
        msg = '0'
    end
    msg = play_name.."--"..M.hms(play_time).."--continue?"..msg..timeout.."[y/N]"
    mp.commandv("show-text",  msg, 1000)
end

function M.bind_key()
    mp.add_key_binding('y', 'resume_yes', function()
        M.wait_jump:kill()
        M.resume()
        M.unbind_key()
    end)
    mp.add_key_binding('n', 'resume_not', function()
        M.wait_jump:kill()
        M.unbind_key()
    end)
end

function M.unbind_key()
    mp.remove_key_binding('y')
    mp.remove_key_binding('n')
end

function M.resume()
    local c_file = mp.get_property("filename", "")
    local c_path = mp.get_property("path", "")
    if c_path ~= play_path then
        mp.commandv('loadfile', play_path)
        mp.add_timeout(0.5, function()
            mp.set_property("time-pos", play_time)
        end)
    else
        mp.set_property("time-pos", play_time)
    end
end

function M.exe()
    local c_file = mp.get_property("filename")
    local c_path = mp.get_property("path")
    if(c_file == nil) then
        M.show('no file is playing', 5000)
        return
    end
    play_root = c_path:match("(.+)/")
    mark_path = play_root.."/"..mark_name
    if(not M.load_mark()) then
        play_name = ""
        play_path = ""
        play_time = 0
    end
    if(c_path == play_path) then
        M.resume()
        mp.commandv('show-text', 'play is resumed', 2000)
        return
    end
    M.wait_jump = mp.add_periodic_timer(1, M.jump)
    M.bind_key()
end

mp.add_timeout(0.5, M.exe)

M.save_period_timer = mp.add_periodic_timer(o.save_period, M.save_mark)
mp.add_hook("on_unload", 50, M.save_mark)
mp.observe_property("pause", "bool", M.pause)
