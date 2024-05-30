function jsonify(t)
	local json = require("json")
	return json.encode(t)
end
