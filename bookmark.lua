local mp = require 'mp'
local utils = require 'mp.utils'
local options = require 'mp.options'

local M = {}

local o = {
    save_period = 30,
    list_next = "end",
    list_prev = "home"
}
options.read_options(o)

local cwd_root = utils.getcwd()

local play_root
local play_name
local play_path
local play_percent
local play_index
local play_list = {}

local load_index = 1
local c_index = 1

local mark_name = ".mpv.bookmark."
local mark_path

local wait_msg

function M.show(msg, mllion)
    mp.commandv("show-text", msg, mllion)
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

function M.compare(s1, s2)
    local l1 = #s1
    local l2 = #s2
    local len = l2
    if l1 < l2 then
        local len = l1
    end
    for i = 1, len do
        if s1:sub(i,i) < s2:sub(i,i) then
            return -1, i-1
        elseif s1:sub(i,i) > s2:sub(i,i) then
            return 1, i-1
        end
    end
    return 0, len
end

function M.load_mark()
    local file = io.open(mark_path, "r")
    if file == nil then
        print("can not open bookmark file")
        return false
    end
    play_name = file:read()
    if play_name == nil then
        print("can not get file's name of last play")
        file:close()
        return false
    else
        play_path = play_root.."/"..play_name
    end
    play_percent = file:read("*n")
    if play_percent == nil then
        print("can not get play percent of last play")
        file:close()
        return false
    end
    if(play_percent >= 100) then
        play_percent = 99
    end
    print("last paly:\n", play_name, "\n", play_percent, "%")
    file:close()
    return true
end

function M.save_mark()
    local name = mp.get_property("filename")
    local percent = mp.get_property("percent-pos", 0)
    if not(name == nil or percent == 0) then
        local file = io.open(mark_path, "w")
        file:write(name.."\n")
        file:write(percent)
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

local timeout = 20
function M.wait_jump()
    timeout = timeout - 1
    if(timeout < 1) then
        play_percent = mp.get_property("percent-pos", 0)
        M.key_jump()
    end
    local msg = ""
    if timeout < 10 then
        msg = "0"
    end
    msg = wait_msg.."--"..(math.modf(play_percent*10)/10).."%--continue?"..msg..timeout.."[y/N]"
    M.show(msg, 1000)
end

function M.bind_key()
    mp.add_key_binding('y', 'resume_yes', function()
        load_index = play_index
        M.key_jump()
    end)
    mp.add_key_binding('n', 'resume_not', function()
        play_percent = mp.get_property("percent-pos", 0)
        M.key_jump()
    end)
end

function M.unbind_key()
    mp.remove_key_binding('y')
    mp.remove_key_binding('n')
end

function M.key_jump()
    M.unbind_key()
    M.wait_jump_timer:kill()
    mp.register_event("file-loaded", M.jump_resume)
    mp.set_property("playlist-pos", load_index)
end

function M.jump_resume()
    mp.unregister_event(M.jump_resume)
    mp.set_property("percent-pos", play_percent)
    if(load_index == play_index) then
        M.show("resume ok", 1500)
    else
        M.show("resume no", 1500)
    end
    mp.commandv("playlist-remove", 0)
end

function M.list_next()
    mp.command("playlist-next", "weak")
end

function M.list_prev()
    mp.command("playlist-prev", "weak")
end

function M.exe()
    mp.unregister_event(M.exe)
    local c_file = mp.get_property("filename")
    local c_path = mp.get_property("path")
    if(c_file == nil) then
        M.show('no file is playing', 1500)
        mp.unregister_event(M.exe)
        return
    end
    play_root = c_path:match("(.+)/")
    mark_path = play_root.."/"..mark_name
    if(not M.load_mark()) then
        play_name = ""
        play_path = ""
        play_percent = 0
    end
    local c_type = c_file:match("%.([^.]+)$")
    print("palying type:", c_type)
    local play_exist = false
    if c_type ~= nil then
        local temp_list = utils.readdir(play_root.."/", "files")
        table.sort(temp_list)
        for i = 1, #temp_list do
            local name = temp_list[i]
            if name:match("%."..c_type.."$") ~= nil then
                table.insert(play_list, name)
                local path = play_root.."/"..name
                mp.commandv("loadfile", path, "append")
                if(play_name == name) then
                    play_exist = true
                    play_index = #play_list
                end
                if(c_file == name) then
                    c_index = #play_list
                end
            end
        end
    end
    if(not play_exist) then
        play_path = c_path
        play_name = c_file
        play_index = c_index
    end
    load_index = c_index
    
    local list_count = mp.get_property("playlist-count")
    local list_pos = mp.get_property("playlist-pos")
    --[[
    print(list_pos,":",list_count)
    for i = 0, list_count-1 do
        print(mp.get_property("playlist/"..i.."/filename"))
    end
    --]]
    
    if(c_index == play_index) then
        if(load_index == 1) then
            mp.set_property("percent-pos", play_percent)
            M.show("resume ok", 1500)
        else
            mp.register_event("file-loaded", M.jump_resume)
            mp.set_property("playlist-pos", play_index)
        end
    else
        if(#play_name <= 16) then
            wait_msg = play_name
        else
            local _, k = M.compare(play_name, c_file)
            if k < 8 then
                wait_msg = play_name:sub(1, 16)
            elseif k+8 >= #play_name then
                wait_msg = play_name:sub(-16, -1)
            else
                wait_msg = play_name:sub(k-7, k+8)
            end
        end
        M.wait_jump_timer = mp.add_periodic_timer(1, M.wait_jump)
        M.bind_key()
    end
    M.save_period_timer = mp.add_periodic_timer(o.save_period, M.save_mark)
    mp.add_hook("on_unload", 50, M.save_mark)
    mp.observe_property("pause", "bool", M.pause)
    mp.add_key_binding(o.list_next, 'list-next', M.list_next)
    mp.add_key_binding(o.list_prev, 'list-prev', M.list_prev)
end
mp.register_event("file-loaded", M.exe)
