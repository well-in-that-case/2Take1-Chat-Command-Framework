---@diagnostic disable: undefined-global
-- Author: well in that case#0082 (700091773695033505)
-- Command Framework: A modular utility that'll do the heavy lifting for your chat commands.
--
-- Licensing:
--      - You're granted the four essential freedoms of free software (https://www.gnu.org/philosophy/free-sw.html#four-freedoms) under these conditions:
--          - You don't claim you've originally made this script.
--          - If you modify this script, you include a link to the original source on GitLab (found below) inside of your repository or source:
--              - https://gitlab.com/wellinthatcase/2take1-scripts-case/-/blob/main/command_framework/command_framework.lua
--
-- Other Credits:
--      - Rimuru♡#1337 (928076634404311090) -- nice user, good developer; also helped me understand the chatEvent.

local pkg = {
    cmds = {},
    enum = {
        ["activated"] = true,
        ["deactivated"] = false
    },
    kwargs = {},
    version = "0.1.0",
    __debug = false,
    prefixes = {},
}

local luaBoolValues = {
    ["nil"] = "nil",
    ["true"] = true,
    ["false"] = false
}

local function parseStringIntoLuaValue(val)
    local nVal = tonumber(val)
    local bVal = luaBoolValues[val]

    if nVal then
        return nVal
    elseif bVal ~= nil then
        if bVal == "nil" then
            return nil
        else
            return bVal
        end
    end

    return val
end

-- Debug only, was useful in 0.0.1 -- keeping it just in case.
-----------------------------------------------------------------------------
-- @func typeof                                                            --
-- @desc Monkey-patches _G["type"] to support basic type introspection.    --
--       This is effectively an alias to _G["type"] unless the metatable   --
--       of the object == pkg.__null, which means it's a null object.      --
--       If this happens, it returns "null" to introspect a nil object.    --
--                                                                         --
-- @param object | Any: The object to check.                               --
-- @return type  | Any: The type of the object, either native or "null"    --
-----------------------------------------------------------------------------
function pkg.typeof(object)
    local mt = getmetatable(object)
    if mt == pkg.__null then
        return "null"
    else
        return type(object)
    end
end

-----------------------------------------------------------------------------
-- @func to_str                                                            --
-- @desc Prevent dead-strings by not touching things that are already str. --
--                                                                         --
-- @param str | string: The non-string to convert, if needed.              --
-----------------------------------------------------------------------------
function pkg.to_str(str)
    if type(str) ~= "string" then
        return tostring(str)
    else
        return str
    end
end

-----------------------------------------------------------------------------
-- @func add_prefix                                                        --
-- @desc Append a prefix to the current prefix list.                       --
--                                                                         --
-- @param to_add  | string: The prefix(s) to append.                       --
-- @return result | boolean: Always true, this cannot fail.                --
-----------------------------------------------------------------------------
function pkg.add_prefix(to_add, ...)
    local function perform(p)
        p = p or to_add
        table.insert(pkg.prefixes, pkg.to_str(p))
    end

    local t = {...}

    if #t > 0 then
        for index, element in next, t do
            perform(element)
        end
    end
    perform()

    return true
end

-----------------------------------------------------------------------------
-- @func del_prefix                                                        --
-- @desc Deletes a prefix from the current prefix list.                    --
--                                                                         --
-- @param to_del   | string: The prefix to delete.                         --
-- @param more_del | Table: An unpacked table of more prefixes to del.     --
-- @return result  | Table: A list of prefixes that were deleted.          --
-----------------------------------------------------------------------------
function pkg.del_prefix(to_del, ...)
    local those_deleted = {}

    local function perform(p)
        p = p or to_del
        for index, prefix in next, pkg.prefixes do
            if pkg.to_str(prefix) == pkg.to_str(p) then
                pkg.prefixes[index] = nil
                table.insert(those_deleted, p)
            end
        end
    end

    local t = {...}

    if #t > 0 then
        for index, element in next, t do
            perform(element)
        end
    end
    perform()

    return those_deleted
end

-----------------------------------------------------------------------------
-- @func add_command                                                       --
-- @desc Add a chat command to your script.                                --
--                                                                         --
-- @param command_name  | string: The name of your chat command.           --
-- @param activated     | boolean: Is this command is activated or not?    --
-- @param callback      | function: Function to execute for this command.  --
-- @return result       | table: A reference to the command object.        --
-----------------------------------------------------------------------------
function pkg.add_command(command_name, activated, callback)
    assert(type(activated) == "boolean", "add_command 'activated' must be a boolean")
    assert(type(command_name) == "string", "add_command 'command_name' must be a string.")
    assert(type(callback) == "function", "add_command 'callback' must be a function.")

    local prototype = {
        callback = callback,
        activated = activated
    }

    pkg.cmds[command_name] = prototype
    return prototype
end

-----------------------------------------------------------------------------
-- @func get_command                                                       --
-- @desc Returns a command object.                                         --
--                                                                         --
-- @param command_name | string: The name of the command.                  --
-- @return command     | Table, nil: The command object, if any.           --
-----------------------------------------------------------------------------
function pkg.get_command(command_name)
    return pkg.cmds[pkg.to_str(command_name)]
end

-----------------------------------------------------------------------------
-- @func get_command                                                       --
-- @desc Executes a command by calling callback with rest args.            --
--                                                                         --
-- @param command_name | string: The name of the command.                  --
-- @param ...          | Any: The arguments to pass, passed as rest.       --
-- @return result      | Any: The result of the callback.                  --
-----------------------------------------------------------------------------
function pkg.run_command(command_name, ...)
    local cmd = pkg.get_command(command_name)

    if cmd then
        return cmd.callback(...)
    end
end

-----------------------------------------------------------------------------
-- @func del_command                                                       --
-- @desc Deletes a command. It returns false if the command doesn't exist. --
--                                                                         --
-- @param command_name | string: The name of the command.                  --
-- @return result      | boolean: True if deleted, false otherwise.        --
-----------------------------------------------------------------------------
function pkg.del_command(command_name)
    command_name = pkg.to_str(command_name)
    local exists = pkg.get_command(command_name)

    if exists then
        pkg.cmds[command_name] = nil
        return true
    end

    return false
end

-----------------------------------------------------------------------------
-- @func toggle_command                                                    --
-- @desc Toggles whether a command may run or not.                         --
--                                                                         --
-- @param command_name | string: The name of the command.                  --
-- @param strong_bool  | boolean: An explicit value to set the state as.   --
-- @return activated   | boolean: The new activation state of the command. --
-----------------------------------------------------------------------------
function pkg.toggle_command(command_name, strong_bool)
    command_name = pkg.to_str(command_name)
    local exists = pkg.get_command(command_name)

    if exists then
        if type(strong_bool) == "boolean" then
            pkg.cmds[command_name].activated = strong_bool
        else
            pkg.cmds[command_name].activated = not exists.activated
        end
    end

    return not exists.activated
end

-----------------------------------------------------------------------------
-- @func process_command                                                   --
-- @desc Parses this string and determines if it shall be processed.       --
--                                                                         --
-- @param chat_string | string: The string to parse, usually from chat.    --
-- @return processed  | boolean: The result of the callback, or false.     --
-----------------------------------------------------------------------------
function pkg.process_command(chat_string)
    assert(type(chat_string) == "string", "process_command 'chat_string' must be a string.")

    local this_prefix
    for _, prefix in next, pkg.prefixes do
        if chat_string:sub(1, #prefix) == prefix then
            this_prefix = prefix
            break
        end
    end

    if this_prefix then
        local generic_args = {}

        for arg in chat_string:gmatch "%S+" do
            table.insert(generic_args, arg)
        end

        local name = generic_args[1]
        if type(name) ~= "string" then
            return false
        end

        local command = pkg.get_command(name:sub(#this_prefix + 1, #name))

        if not command or command.activated == false then
            return false
        end

        local keywords = {}
        local positionals = {}

        for index, argument in next, generic_args do
            local kwarg = false

            if index ~= 1 then
                for key, value in argument:gmatch "%s*([^=]*)=([^=]*)%f[%s%z]" do
                    if key and value then
                        keywords[key] = parseStringIntoLuaValue(value)
                        kwarg = true
                    end
                end

                if not kwarg then
                    table.insert(positionals, #positionals + 1, parseStringIntoLuaValue(argument))
                end
            end
        end

        pkg.kwargs = keywords
        return command.callback(table.unpack(positionals))
    end

    return false
end

if pkg.__debug == true then
    local prefix = "!"
    pkg.add_prefix(prefix)

    pkg.add_command("hello", pkg.enum.activated, function ()
        local kwargs = pkg.kwargs
        if kwargs.color then
            print(kwargs.color)
        end

        if kwargs.state then
            print(kwargs.state)
        end
    end)

    pkg.add_command("world", pkg.enum.activated, function (...)
        local t = {...}

        if #t == 0 then
           print "No positional arguments have been passed."
        end

        for index, argument in next, t do
            print("Positional Index: "..tostring(index).." | Positional Value: "..tostring(argument))
        end

        for key, value in pairs(pkg.kwargs) do
            print("Key: "..key.."\nValue: "..tostring(value))
        end
    end)

    print "CMD Framework debug, testing positional command:"
    pkg.process_command("!world hello world how are you doing?")

    print "CMD Framework debug, testing keyword-only command:"
    pkg.process_command("!world key1=value1 key2=value2 key3=value3")

    print "CMD Framework debug, testing positional & keyword command:"
    pkg.process_command("!world pos1 key1=value1 pos2 pos3 key2=value2")

    do
        print "CMD Framework debug, testing prefix functions."
        pkg.add_prefix("prefix")
        print("Added prefix?: "..tostring(#pkg.prefixes > 1))
        print "Removing prefix."
        pkg.del_prefix("prefix", "!")
        print("Removed prefix?: "..tostring(#pkg.prefixes < 1))
        print "CMD Framework debug, finished testing prefix functions."
    end

    do
        print "CMD Framework debug, testing command activation states."
        pkg.add_command("null", true, function () end)
        print("Current state: "..tostring(pkg.get_command("null").activated))
        print "Toggling state."
        pkg.toggle_command("null")
        print("New state: "..tostring(pkg.get_command("null").activated))
        print "CMD Framework debug, finished testing command activation states."
    end

    do
        print "CMD Framework debug, testing command deletion."
        pkg.del_command("null")
        print("Deleted state: "..tostring(pkg.get_command("null") == nil))
        print "CMD Framework debug, finished testing command deletion."
    end

    do
        print "CMD Framework debug, testing remote callback calls."
        pkg.add_command("null", false, function ()
            return true
        end)
        print("Callback state: "..tostring(pkg.run_command("null")))
        print "CMD Framework debug, finished testing remote callback calls."
    end

    pkg.add_prefix(".")
    pkg.add_command("print", true, function (...)
        print(table.concat({...}, " "))
        for name, value in pairs(pkg.kwargs) do
            print("Kwarg Name: "..name.." | Kwarg Value: "..tostring(value))
        end
    end)

    event.add_event_listener("chat", function(event)
        pkg.process_command(event.body)
    end)
end

return pkg
