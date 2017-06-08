if not core.settings:get_bool("disable_spam_protection") then
	local max_masages_per_time = tonumber(core.settings:get("max_masages_per_time")) or 5
	local time_for_max_masages = tonumber(core.settings:get("time_for_max_masages")) or 30
	local max_repeat_massages = tonumber(core.settings:get("max_repeat_massages")) or 3
	local mute_time = tonumber(core.settings:get("mute_time")) or 120
	local mute_warnings = tonumber(core.settings:get("mute_warnings")) or 2

	core.register_on_joinplayer(function(player)
		player:set_attribute("spam_protection_last_massage", "")
		player:set_attribute("spam_protection_last_massages_time", core.get_gametime())
		player:set_attribute("spam_protection_last_massage_count", 0)
		player:set_attribute("spam_protection_repeat_massage_count", 0)
		player:set_attribute("spam_protection_mute_time", 0)
		player:set_attribute("spam_protection_violations", 0)
	end)

	local function punish_player(name)
		local player = core.get_player_by_name(name)
		local violations = player:get_attribute("spam_protection_violations") + 1
		player:set_attribute("spam_protection_violations", violations)
		
		if violations <= mute_warnings then
			if mute_warnings - violations == 1 then
				minetest.chat_send_player(name, "You have been warned!")
			else
				minetest.chat_send_player(name, "LAST WARNING!")
			end
		else
			player:set_attribute("spam_protection_mute_time", core.get_gametime() + mute_time)
			player:set_attribute("spam_protection_violations", 0)
			minetest.chat_send_all(name.." has been muted for then next "..mute_time.." seconds.")
		end
	end
	
	core.register_on_chat_message(function(name, message)
		local player = core.get_player_by_name(name)
		local gametime = core.get_gametime()
		local last_massage = player:get_attribute("spam_protection_last_massage")
		local last_massages_time = player:get_attribute("spam_protection_last_massages_time")
		local last_massage_count = player:get_attribute("spam_protection_last_massage_count") + 1
		local repeat_massage_count = player:get_attribute("spam_protection_repeat_massage_count")
		local current_mute_time = player:get_attribute("spam_protection_mute_time") - gametime
		
		if current_mute_time > 0 then
			minetest.chat_send_player(
				name,
				"You can't use the chat for the next "..current_mute_time.." seconds."
			)
			return true
		end
		
		player:set_attribute("spam_protection_last_massage", message)
		
		if last_massage_count > max_masages_per_time then
			last_massage_count = 0
			player:set_attribute("spam_protection_last_massages_time", gametime)
		end
		player:set_attribute("spam_protection_last_massage_count", last_massage_count)
		
		
		if last_massage == message then
			repeat_massage_count = repeat_massage_count + 1
			player:set_attribute(
				"spam_protection_repeat_massage_count", 
				repeat_massage_count
			)
			if repeat_massage_count > max_repeat_massages then
				player:set_attribute("spam_protection_repeat_massage_count", 0)
				minetest.chat_send_player(name, "Stop repeating yourself!")
				punish_player(name)
				return true
			end
		end
		
		if last_massage_count == 0 and gametime - last_massages_time < time_for_max_masages then
			minetest.chat_send_player(name, "Stop spamming!")
			punish_player(name)
			return true
		end
	end)
end
