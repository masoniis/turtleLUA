local wsURL = "ws://73.229.134.181:80"

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

local function sendStats(ws, turtleid)
	local stats = turtleStats()
	ws.send(jsonify({
		action = "turtleStats",
		id = turtleid,
		client = "turtle",
		data = {
			fuelLevel = stats.fuelLevel,
			inspect = stats.inspect,
			inspectInfo = stats.inspectInfo,
			inventory = stats.inventory,
		}
	}))
end

local ws = http.websocket(wsURL)

local function main()
	local turtleid = ""

	if ws then
		print("Websocket connected!")

		while turtleid == "" do
			ws.send(jsonify({ action = "setClientTag", data = "turtle" }))
			local response, err = ws.receive()
			if response then
				local responseT = luaify(response)
				if (responseT.action == "responseId") then
					turtleid = responseT.id
				else
					print("Received non-ID message: " .. response)
				end
			else
				print("Failed to receive initial ID: " .. err)
				break
			end
		end

		print("Turtle ID: " .. turtleid)
		ws.send(jsonify({ action = "newTurtle", id = turtleid, client = "turtle", data = "Hello world, I am a turtle!" }))
		-- sendStats(ws, turtleid)

		while true do
			local response, err = ws.receive(3)
			if response then
				local responeTable = luaify(response)
				if responeTable.action == "requestTurtleStats" then
					sendStats(ws, turtleid)
				else
					local luacode = load(responeTable.data)
					if luacode then
						print("Executing code: " .. responeTable.data)
						local success, fail = pcall(luacode)
						if not success then
							print("An error occurred in code execution: " .. fail)
						else
							print("Code executed successfully.")
						end
					else
						print("Received non-code message: " .. responeTable.data)
					end
				end
			else
				-- sendStats(ws, turtleid)
				if err then
					print("An error occurred: " .. err)
				end
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
