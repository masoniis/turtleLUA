local M = {}

function M.jsonify(t)
	local jsonString = "{"
	for k, v in pairs(t) do
		if type(v) == "string" then
			jsonString = jsonString .. "\"" .. k .. "\":\"" .. v .. "\","
		elseif type(v) == "number" then
			jsonString = jsonString .. "\"" .. k .. "\":" .. v .. ","
		elseif type(v) == "table" then
			jsonString = jsonString .. "\"" .. k .. "\":" .. jsonify(v) .. ","
		end
	end
	jsonString = jsonString:sub(1, jsonString:len() - 1) .. "}"
	return jsonString
end

return M
