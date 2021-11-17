-- cringe
local NextCheck = CurTime()

local DigitCheck = CurTime()
    
local TestCode = 1

local LastCode = TestCode

local CurEnt = nil

local Checking = false

local curdigit = 0

local StartTime = nil

-- we cant enter a 4 digit pin code at once so we send all the digits separately to the keypad
-- the code is prolly pretty shit, i went a little crazy over trying to make this
local function EnterDigits(ent, code)
    if DigitCheck <= CurTime() then

        if curdigit == #tostring(code) then
            curdigit = 0
            return true
        end

        curdigit = curdigit + 1


        local digit = string.sub(tostring(code), curdigit, curdigit)

        net.Start("Keypad")
            net.WriteEntity(ent)-- this keypad
            net.WriteInt(0, 4)-- mode: enter combo
            net.WriteUInt(digit, 8)-- send digit
        net.SendToServer()


        DigitCheck = CurTime() + 0.05 -- 0.05 is the delay between commands server side for the keypad
    end
end

local function DecodingThink()
    if !IsValid(CurEnt) then
        TestCode = 1

        hook.Remove("Tick", "DecodingThink")
    end

    if CurEnt:GetStatus() == 0 and NextCheck <= CurTime() then -- if keypad doin nothing do our combo guessing game
        if Checking then return end

        local thing = EnterDigits(CurEnt, TestCode)

        if thing == true then -- wait for a result from the digits department before moving on
            LocalPlayer():ChatPrint("Trying code \"" .. TestCode .. "\"")
            Checking = true

            net.Start("Keypad")
                net.WriteEntity(CurEnt)
                net.WriteInt(1, 4) -- accepted input code and wait for result
            net.SendToServer()

            LastCode = TestCode

            TestCode = TestCode + 1

            if string.find(tostring(TestCode), "0") then
                TestCode = tonumber(string.Replace(tostring(TestCode), "0", "1"))
            end

            NextCheck = CurTime() + 0.05

            Checking = false
        else
            return
        end
    elseif CurEnt:GetStatus() == 1 then -- status 1 == access granted
        LocalPlayer():ChatPrint("Found code: " .. LastCode)

        LocalPlayer():ChatPrint("It took " .. os.date("%H hours, %M minutes, %S seconds", 82800 + os.time() - StartTime) .. " to find the code!") -- if ur a mad man wait the entire time for a 4 digit code to be guessed

        CurEnt.CSCode = LastCode

        TestCode = 1

        hook.Remove("Tick", "DecodingThink")
        return
    end
end

local function StartDecoding(ent)
    LocalPlayer():ChatPrint("Started decoding...")

    StartTime = os.time()

    CurEnt = ent

    hook.Add("Tick", "DecodingThink", DecodingThink)
end

local function StartDigitEnter()
    local result = EnterDigits(CurEnt, TestCode)

    if result == true then
        net.Start("Keypad")
            net.WriteEntity(CurEnt)
            net.WriteInt(1, 4)
        net.SendToServer()

        hook.Remove("Tick", "StartDigitEnter")
    end
end

concommand.Add("CrackMeh", function()
    local tr = LocalPlayer():GetEyeTrace()

    if tr.Entity and tr.Entity:GetClass() == "Keypad" then
        if tr.Entity.CSCode then -- when a code is guessed it gets saved onto the keypad clientside for later entering
            CurEnt = tr.Entity
            TestCode = tr.Entity.CSCode
            hook.Add("Tick", "StartDigitEnter", StartDigitEnter)
        else
            StartDecoding(tr.Entity) -- start decoding if there is no code saved
        end
    end
end)
