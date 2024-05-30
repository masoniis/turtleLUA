local request = http.get("https://api.waifu.pics/sfw/waifu")
if request then
	local response = request.readAll()
	request.close()
	print(response)
else
	print("Failed to perform API request.")
end

local wsURL = "ws://73.229.134.181:80"
local ws = http.websocket(wsURL)
if ws then
	print("WebSocket connection established.")
	local message = { client = "turtle", data = "Hello, world! I am the turtleaa!" }

	local jsonString = "{\"action\":\"" .. message.client .. "\",\"data\":\"" .. message.data .. "\"}"
	print("Sending " .. jsonString)

	ws.send(jsonString)

	local response, err = ws.receive()
	if response then
		print("Received from server: " .. response)
	else
		print("Failed to receive message: " .. err)
	end

	print("Closing WebSocket connection.")
	ws.close()
else
	print("Failed to establish WebSocket connection.")
end
