local SkuVoice_MAJOR, SkuVoice_MINOR = "SkuVoice-1.0", 15
local SkuVoice, oldminor = LibStub:NewLibrary(SkuVoice_MAJOR, SkuVoice_MINOR)

if not SkuVoice then return end -- No upgrade needed

local mSkuVoiceQueue = {}

function SkuVoice:Create()
	local f = CreateFrame("Frame", "SkuVoiceMainFrame", UIParent)
	local fTime = 0
	f:SetScript("OnUpdate", function(self, time)
		fTime = fTime + time
		if fTime > 0.1 then
			fTime = 0

			local tPlayNext = true
			local tTombstone
			for i = 1, table.getn(mSkuVoiceQueue) do
				if mSkuVoiceQueue[i] then
					if mSkuVoiceQueue[i].soundHandle then
						if mSkuVoiceQueue[i].wait == true then
							if (GetTime() - mSkuVoiceQueue[i].endTimestamp) < 0 then
								tPlayNext = false
							else
								tTombstone = i
							end
						else
							tTombstone = i
						end
					end

					if tPlayNext == true then
						local willPlay, soundHandle = PlaySoundFile(mSkuVoiceQueue[i].file, mSkuVoiceQueue[i].soundChannel)
						if willPlay then
							mSkuVoiceQueue[i].soundHandle = soundHandle
							mSkuVoiceQueue[i].endTimestamp = GetTime() + mSkuVoiceQueue[i].length
							tPlayNext = false
						else
							tTombstone = i
						end
					end
				end
			end

			if tTombstone then
				if mSkuVoiceQueue[tTombstone].soundHandle then
					StopSound(mSkuVoiceQueue[tTombstone].soundHandle, 0)
				end
				table.remove(mSkuVoiceQueue, tTombstone)
			end
		end
	end)

	return SkuVoice
end

---------------------------------------------------------------------------------------------------------
function SkuVoice:UtilRound(aNumber, aInterval)
	return (aInterval * math.floor( 10 * aNumber / aInterval ) / 10)
end

---------------------------------------------------------------------------------------------------------------------------------------
local function SplitString(aString)
	--dprint("split:", aString, SkuAudioFileIndex[aString])
	if SkuAudioFileIndex[aString] then
		return aString
	end
	if aString == nil then
		return ""
	end

	if aString == "" then
		return aString
	end
	aString = string.gsub(aString, "\"", ";"..L["backslash"]..";")
	aString = string.gsub(aString, "'", ";")
	aString = string.gsub(aString, "%.", ";"..L["period"]..";")
	aString = string.gsub(aString, ",", ";")
	aString = string.gsub(aString, "%?", ";"..L["question;mark"]..";")
	aString = string.gsub(aString, "!", ";"..L["exclamation;point"]..";")
	aString = string.gsub(aString, "|", ";")
	aString = string.gsub(aString, "%[", ";")
	aString = string.gsub(aString, "%]", ";")
	aString = string.gsub(aString, "%+", ";")
	aString = string.gsub(aString, "%*", ";")
	aString = string.gsub(aString, "#", ";")
	aString = string.gsub(aString, "%-", ";")
	aString = string.gsub(aString, ":", ";"..L["colon"]..";")
	aString = string.gsub(aString, "&", ";"..L["and"]..";")
	aString = string.gsub(aString, "%%", ";%;")
	aString = string.gsub(aString, "/", ";slash;")
	aString = string.gsub(aString, "\\", ";\\;")
	aString = string.gsub(aString, "%(", ";(;")
	aString = string.gsub(aString, "%)", ";);")
	aString = string.gsub(aString, "=", ";=;")
	aString = string.gsub(aString, "<", ";<;")
	aString = string.gsub(aString, ">", ";>;")
	aString = string.gsub(aString, "	", ";")
	aString = string.gsub(aString, "  ", " ")
	aString = string.gsub(aString, " ", ";")
	aString = string.gsub(aString, ";;", ";")
	aString = string.lower(aString)

	if string.sub(aString, string.len(aString)) == ";" then
		aString = string.sub(aString, 1, string.len(aString)-1)
	end
	return aString
end

---------------------------------------------------------------------------------------------------------------------------------------
local function Unescape(aString)
	local tResult = tostring(aString)
	tResult = gsub(tResult, "|c........", "") -- Remove color start.
	tResult = gsub(tResult, "|r", "") -- Remove color end.
	tResult = gsub(tResult, "|H.-|h(.-)|h", "%1") -- Remove links.
	tResult = gsub(tResult, "|T.-|t", "") -- Remove textures.
	tResult = gsub(tResult, "{.-}", "") -- Remove raid target icons.
	return tResult
end

---------------------------------------------------------------------------------------------------------
function SkuVoice:StopAllOutputs()
	for i = 1, table.getn(mSkuVoiceQueue) do
		if mSkuVoiceQueue[i] then
			if mSkuVoiceQueue[i].soundHandle then
				StopSound(mSkuVoiceQueue[i].soundHandle, 0)
			end
		end
	end
	mSkuVoiceQueue = {}
end

---------------------------------------------------------------------------------------------------------
function SkuVoice:OutputString(aString, aOverwrite, aWait, aLength, aDoNotOverwrite, aIsMulti, aSoundChannel) -- for strings with lookup in string index
	aSoundChannel = aSoundChannel or SkuOptions.db.profile["SkuOptions"].soundChannels.SkuChannel or "Talking Head"

	aIsMulti = aIsMulti or false
	if string.find(aString, ";") then
		aIsMulti = true
	end

	if not aString or not SkuAudioDataLenIndex or not SkuAudioFileIndex then
		return
	end
	if aString == "" then
		return
	end

	if aOverwrite == true then
		for i = 1, table.getn(mSkuVoiceQueue) do
			if mSkuVoiceQueue[i] then
				if mSkuVoiceQueue[i].doNotOverwrite ~= true then
					if mSkuVoiceQueue[i].soundHandle then
						StopSound(mSkuVoiceQueue[i].soundHandle)
					end
					mSkuVoiceQueue[i] = nil
				end
			end
		end
		--SkuVoiceQueue = {}
	end
	aString = Unescape(aString)
	aString = aString:gsub("\"", "")

	local tNumber = tonumber(aString)
	if tNumber then
		if tNumber - math.floor(tonumber(aString)) > 0 then
			aString = ""
			return
		end
	end

	local tStrings = {}
	if (string.find(aString, "sound-") or string.find(aString, "male%-")) then
		table.insert(tStrings, aString)
	else
		aString = string.lower(aString)
		aString = SplitString(aString)

		local sep, tSplittedString = ";", {}
		if type(aString) == "string" then
			local pattern = string.format("([^%s]+)", sep)
			aString:gsub(pattern, function(c) tSplittedString[#tSplittedString+1] = c end)
		else
			tSplittedString = {aString}
		end

		for x = 1, #tSplittedString do
			if tonumber(tSplittedString[x]) then
				local tFloatNumber = string.format("%.1f", tonumber(tSplittedString[x]))
				if tonumber(tFloatNumber) < 1000000 then
					if (tFloatNumber - string.format("%d", tFloatNumber)) > 0 then
						--float
						local tIVal = string.format("%d", tFloatNumber)
						local tFVal = string.format("%d", string.format("%.1f", (tFloatNumber - tIVal) * 10))
						table.insert(tStrings, tIVal)
						table.insert(tStrings, L["comma"])
						table.insert(tStrings, tFVal)
					else
						--int
						local tNumber = math.floor(tonumber(tSplittedString[x]))
						if tNumber == 0 then
							table.insert(tStrings, 0)
						else
							local tRemaining = tNumber
							if tNumber > 13000 then
								--no audio available
							end
							if tNumber > 999 then
								local tRound = SkuVoice:UtilRound(tRemaining, 10000)
								table.insert(tStrings, tRound)
								tRemaining = tRemaining - tRound
							end
							if tRemaining > 99 then
								local tRound = SkuVoice:UtilRound(tRemaining, 1000)
								table.insert(tStrings, tRound)
								tRemaining = tRemaining - tRound
							end
							if tRemaining > 0 then
								table.insert(tStrings, tRemaining)
							end
						end
					end
				end
			else
				table.insert(tStrings, tSplittedString[x])
			end
		end
	end


	for x = 1, #tStrings do
		local tFile = SkuAudioFileIndex[tostring(tStrings[x])]

		if tFile == nil then
			local tModString = string.lower(tostring(tStrings[x]))
			tFile = SkuAudioFileIndex[tModString]
		end
		if tFile == nil then
			local tModString = string.upper(string.sub(tostring(tStrings[x]),1,1))..string.sub(tostring(tStrings[x]),2)
			tFile = SkuAudioFileIndex[tModString]
		end
		if tFile == nil then
			--SkuCore:Debug(tStrings[x])
			--file = SkuAudioFileIndex["Keine Audiodatei"]
			tFile = SkuAudioFileIndex["sound-audiofehltbeep"]
			if SkuOptions.db then
				if SkuOptions.db.profile.missingAudio == nil then
					SkuOptions.db.profile.missingAudio = {}
				end

				--if not SkuOptions.db.profile.missingAudio[tStrings[x]] then
--					--table.insert(SkuOptions.db.profile.missingAudio, tStrings[x])
					--SkuOptions.db.profile.missingAudio[tStrings[x]] = 1
				--else
--					SkuOptions.db.profile.missingAudio[tStrings[x]] = SkuOptions.db.profile.missingAudio[tStrings[x]] + 1
				--end

				if SkuOptions.db.realm.missingAudio == nil then
					SkuOptions.db.realm.missingAudio = {}
				end
				if not SkuOptions.db.realm.missingAudio[tStrings[x]] then
					--table.insert(SkuOptions.db.profile.missingAudio, tStrings[x])
					SkuOptions.db.realm.missingAudio[tStrings[x]] = 1
				else
					SkuOptions.db.realm.missingAudio[tStrings[x]] = SkuOptions.db.realm.missingAudio[tStrings[x]] + 1
				end

			end
		end

		if tFile then
			if tFile ~= "" then
				local tLength = SkuAudioDataLenIndex[tFile] or aLength

				--if isMulti == true then
					tLength = tLength - ((100 - tonumber(SkuOptions.db.profile["SkuOptions"].TTSSepPause)) / 100) -- - 0.15
				--end


				tFile = "Interface\\AddOns\\SkuAudioData\\assets\\audio\\"..tFile
				aOverwrite = aOverwrite or false
				aWait = aWait or false
				tLength = tLength or 0
				if x == 1 then
					--[[if overwrite == true then
						for i = 1, table.getn(SkuVoiceQueue) do
							if SkuVoiceQueue[i].soundHandle then
								StopSound(SkuVoiceQueue[i].soundHandle)
							end
						end
						SkuVoiceQueue = {}
					end]]
				end
				table.insert(mSkuVoiceQueue, {
					["file"] = tFile,
					["wait"] = aWait,
					["length"] = tLength,
					["endTimestamp"] = 0,
					["soundHandle"] = nil,
					["doNotOverwrite"] = aDoNotOverwrite or false,
					["soundChannel"] = aSoundChannel,
				})

			end
		end
	end

end

---------------------------------------------------------------------------------------------------------
function SkuVoice:StopOutputEmptyQueue()
	-- fade all in SkuVoiceQueue
	for i = 1, table.getn(mSkuVoiceQueue) do
		if mSkuVoiceQueue[i] then
			if mSkuVoiceQueue[i].soundHandle then
				StopSound(mSkuVoiceQueue[i].soundHandle)
			end
		end
	end
	mSkuVoiceQueue = {}
end

---------------------------------------------------------------------------------------------------------
--[[
function SkuVoice:Output(file, overwrite, wait, length, doNotOverwrite, isMulti, soundChannel) -- for audio file names
	--dprint("SV OUTPUT")
	soundChannel = soundChannel or SkuOptions.db.profiles["SkuOptions"].soundChannels.SkuChannel or "Talking Head"
	
	isMulti = isMulti or false

	if not file or not SkuAudioDataLenIndex then
		return
	end

	if not SkuAudioDataLenIndex[file] then --element is in string index
		if SkuCore and file then
			--SkuCore:Debug("SkuVoice:Output - missing audio file: "..file)
		end
	end

	local length = SkuAudioDataLenIndex[file] or length

	file = "Interface\\AddOns\\SkuAudioData\\assets\\audio\\"..file

	overwrite = overwrite or false
	wait = wait or false
	length = length or 0

	if overwrite == true then
		-- fade all in SkuVoiceQueue
		for i = 1, table.getn(mSkuVoiceQueue) do
			if mSkuVoiceQueue[i] then
				if mSkuVoiceQueue[i].soundHandle then
					StopSound(mSkuVoiceQueue[i].soundHandle)
				end
			end
		end
		mSkuVoiceQueue = {}
	end

	table.insert(mSkuVoiceQueue, {
		["file"] = file,
		["wait"] = wait,
		["length"] = length,
		["endTimestamp"] = 0,
		["soundHandle"] = nil,
		["doNotOverwrite"] = doNotOverwrite or false,
		["soundChannel"] = soundChannel,
})
end
]]
function SkuVoice:Release()

end