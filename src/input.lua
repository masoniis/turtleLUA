-- Turn a flat table into a JSON string
local function jsonify(flattable)
	local jsonString = "{"
	for k, v in pairs(flattable) do
		jsonString = jsonString .. "\"" .. k .. "\":" .. "\"" .. v .. "\"" .. ","
	end
	jsonString = jsonString:sub(1, jsonString:len() - 1) .. "}"
	return jsonString
end

local function luaify(jsonString)
	local t = {}
	print("input:" .. jsonString)
	jsonString = jsonString:sub(2, jsonString:len() - 1)
	for pair in string.gmatch(jsonString, "%b\"\":%b\"\"") do
		print("Pair: " .. pair)
	end
	-- for str in string.gmatch(jsonString, "([^" .. "," .. "]+)") do
	-- 		local key, value = str:match("([^=]+)=(.*)")
	-- 		print("key: " .. key .. " value: " .. value)
	--        table.insert(t, { [key] = value })
	--  end

	print("Stage 2: ")
	for k, v in pairs(t) do
		print(k, v)
	end
	-- local table = {}
	-- for k, v in pairs(jsonString) do
	-- 	table[k] = v
	-- end
	print("END")
	return t
end

local wsURL = "ws://73.229.134.181:80"
local ws = http.websocket(wsURL)

local function main()
	-- Turtle identifier set on websocket connection
	local turtleid = ""

	if ws then
		ws.send("turtle") -- Send the client tag to the server

		print("WebSocket connection established.")
		local message = { action = "message", client = "turtle", data = "Hello, world! I am the turtleaa!" }

		local jsonString = "{\"action\":\"" .. message.client .. "\",\"data\":\"" .. message.data .. "\"}"
		print("Jsoned: " .. jsonify(message))
		print("Sending " .. jsonString)

		ws.send(jsonify(message))

		while true do
			local response, err = ws.receive()
			if response then
				print("Received from server: " .. response)
				print("Luaified: " .. tostring(luaify(response)))
				local luacode = load(response)
				if luacode then
					luacode()
				end
			else
				print("Failed to receive message: " .. err)
				break -- Break the loop if there's an error
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
