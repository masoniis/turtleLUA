-- Turn a flat table into a JSON string
local function jsonify(flattable)
	local function tableToJson(tbl)
		local jsonString = "{"
		for k, v in pairs(tbl) do
			jsonString = jsonString .. "\"" .. k .. "\":"
			if type(v) == "table" then
				jsonString = jsonString .. tableToJson(v) .. ","
			else
				jsonString = jsonString .. "\"" .. tostring(v) .. "\"" .. ","
			end
		end
		jsonString = jsonString:sub(1, -2) .. "}"
		return jsonString
	end

	return tableToJson(flattable)
end

local function luaify(jsonString)
	local t = {}
	jsonString = jsonString:sub(2, jsonString:len() - 1)
	for key, value in string.gmatch(jsonString, "(%b\"\"):(%b\"\")") do
		key = key:sub(2, key:len() - 1)
		value = value:sub(2, value:len() - 1)
		t[key] = value
	end
	return t
end

local function turtleStats()
	local fuelLevel = turtle.getFuelLevel()
	local blockedForward, info = turtle.inspect()
	local inventory = {}
	for i = 1, 16 do
		inventory[i] = turtle.getItemDetail(i)
		if inventory[i] == nil then
			inventory[i] = "empty"
		end
	end
	local stats = {
		fuelLevel = tostring(fuelLevel),
		inspect = tostring(blockedForward),
		inspectInfo = tostring(info),
		inventory = inventory,
	}
	return stats
end

local wsURL = "ws://73.229.134.181:80"
local ws = http.websocket(wsURL)

local function main()
	-- Turtle identifier set on websocket connection
	local turtleid = ""

	if ws then
		print("Websocket success!")
		ws.send("turtle") -- Send the client tag to the server

		while turtleid == "" do
			local response, err = ws.receive()
			if response then
				local responseT = luaify(response)
				if responseT.id then
					turtleid = responseT.id
				end
			else
				print("Failed to receive initial ID: " .. err)
				break
			end
		end

		print("Turtle ID: " .. turtleid)
		local message = { action = "newTurtle", id = turtleid, client = "turtle", data = "Hello world, I am a turtle!" }
		-- print("Sending message: " .. jsonify(message))
		ws.send(jsonify(message))

		while true do
			local response, err = ws.receive()
			if response then
				local responeTable = luaify(response)
				if responeTable.action == "requestTurtleStats" then
					local stats = turtleStats()

					ws.send(jsonify({
						action = "turtleStats",
						id = turtleid,
						client = "turtle",
						fuelLevel = stats.fuelLevel,
						inspect = stats.inspect,
						inspectInfo = stats.inspectInfo,
						inventory = stats.inventory,
					}))
				else
					local luacode = load(responeTable.data)
					if luacode then
						print("Executing code: " .. responeTable.data)
						luacode()
					else
						print("Received non-code message: " .. responeTable.data)
					end
				end
			else
				print("Failed to receive message: " .. err)
				break
			end
		end

		print("Closing WebSocket connection.")
		ws.close()
	else
		print("Failed to establish WebSocket connection.")
	end
end

-- Run the main function in a protected environment that ensures websocket closure
local ok, errorMessage = pcall(main)
pcall(ws and ws.close or function() end)
if not ok then
	printError(errorMessage) -- Print the error message
end
