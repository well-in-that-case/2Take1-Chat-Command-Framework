
# Case's Command Framework
A modular utility that'll do the heavy lifting for your chat commands.

## Features:
- Pretty readable interface.
- Multiple, simultaneous prefixes of any length. 
- Pythonic positional & keyword argument support.
- Command activation and deactivation, respectively.
- Automatic type conversion of positional & keyword arguments.

###### Warning:
This is a sensitive utility. Since spaces are the delimiter, it relies that the user can type commands coherently. You may need to instruct them how. A space between the "=" when it comes to keyword arguments will incorrectly render it as a positional argument, and someone using commas between positionals as a way to inappropriately delimit their arguments will have a comma appending each argument. So, just be aware.

#### Into Argument Parsing & Types
This framework parses arguments by a space. So, "a b c d" are all different arguments respectively, and they are also all positional arguments, which speaks to their format and how they're handled.

Positional arguments are passed directly to your callback in the order they're read.
So, "a b c d", will be read to `function(a, b, c, d)` appropriately.

Keyword arguments look slightly different, in a key-value format.
```ini
key1=val1
key2=val2
```
Suppose that we call `process_command` with this string:
```
!print hello world randomkwarg=randomvalue how are you?
```
Inferring the function name, the output would appear as if there is no random kwarg within the string of positionals. This is because keyword arguments are extracted and assigned to the `kwargs` property of the package, or as seen below, `commands.kwargs`.

If you wish to access the kwargs for your command within your callback, you only need to read `commands.kwargs` (which is a table) and they'll all be assigned there within the same key-value format.

# Examples
```lua
local commands = require "./command_framework"

-- There is no default prefix.
commands.add_prefix("!")

-- Prints what the message was, minus the command name & prefix.
commands.add_command("repeat", commands.enum.activated, function (...)
    print(table.concat(table.pack(...), " "))
end)

-- This is semantically equal:
commands.add_command("repeat", true, function (...)
    print(table.concat(table.pack(...), " "))
end)

-- Listen for commands. 
-- You can use event.player to gatekeep who uses your commands.
event.add_event_listener("chat", function(event)
    commands.process_command(event.body)
end)
```

## Module Documentation:
### add_command
Adds a command to be processed by the framework.
##### Parameters:
- command_name
    - The name of your upcoming command.
- activated
    - Whether to activate this command at creation. 
- callback
    - The callback to run once this command is invoked. Any positional arguments are passed directly.

##### Returns:
A table which is a reference to the command object assigned. Structure is as follows:
```lua
{
    callback = callback,
    activated = activated
}
```

### get_command
Returns the command object for this command, if any.
##### Parameters:
- command_name
    - The name of the command to try and fetch.

##### Returns:
The command object, if any. The structure is as follows:
```lua
{
	callback = ...,
	activated = ...
}
```

### run_command
Run this command. Any parameters besides the first one are passed to  your command.
##### Parameters:
- command_name
    - The name of the command.

##### Returns
The response from your callback.

### del_command
Delete this command.
##### Parameters:
- command_name
    - The name of this command.

##### Returns:
A boolean indicating if the command was deleted.

### toggle_command
Toggle the activation state of this command.
##### Parameters:
- command_name
    - The name of this command.
- strong_bool
    - A boolean indicating the next state. By default, it reverses the current state.

##### Returns:
The new activation state of the command.

### add_prefix
Appends a prefix to the prefix pool.
##### Parameters:
- prefix
    - The prefix(s) to append.

### del_prefix
Deletes a prefix from the prefix pool.
##### Parameters:
- prefix
    - The prefix(s) to delete. Add more arguments to delete more.

##### Returns:
A table of all the prefixes which were deleted.

### process_command
Process this string as a potential command.
##### Parameters:
- chat_string
    - The string to parse & process.

# Mock Examples (Untested)
Basic usage:
```lua
local commands = require "./command_framework.lua"

commands.add_prefix("!")
commands.add_command("kick", true, function(rid)
    if network.network_is_host() then
        network.network_session_kick_player(rid)
    end
end)

event.add_event_handler("chat", function(event)
    commands.process_command(event.body)
end)
```
```lua
local commands = require "./command_framework.lua"

-- Clear our prefixes. (It's clear by default)
commands.prefixes = {}

-- Add our own prefix:
commands.add_prefix "!"

-- Nevermind, I don't like that prefix. This is better:
commands.del_prefix "!"
commands.add_prefix ";;"

-- For our first command:
commands.add_command("mock", true, function(...)
    local rest_as_str = table.concat({...}, " ")
    local new = 'A dumb person once said: "'..rest_as_str..'"'
    
    network.send_chat_message(new, false)
end)

-- To disable the command:
commands.toggle_command("mock", false)

-- Or enable it, obviously:
commands.toggle_command("mock", true)

-- Maybe we want to run it remotely:
local args = {
    "Argument 1",
    "Argument 2",
    "Argument 3"
}
commands.run_command("mock", table.unpack(args)) -- A dumb user once said: ...

-- And now to actually make it work:
event.add_event_handler("chat", function(event)
    commands.process_command(event.body)
end)

-- What about keyword arguments?
commands.add_command("print_kwargs", true, function()
    for name, value in pairs(commands.kwargs) do 
        print("Kwarg Name: "..name.." | Kwarg Value: "..tostring(value))
    end
end)
-- Kwargs are parsed independently and given to commands.kwargs.
-- Every time a command is ran, they are assigned by that command.
-- That allows every positional to be heard by your callback.
commands.process_command("!print_kwargs key1=val1 key2=val2")
-- Mixing kwargs with positionals works flawlessly.
```
