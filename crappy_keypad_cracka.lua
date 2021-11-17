local NextCheck = CurTime()

local DigitCheck = CurTime()
    
local TestCode = 1

local LastCode = TestCode

local CurEnt = nil

local Checking = false

local curdigit = 0

local StartTime = nil

local function EnterDigits(ent, code)
    if DigitCheck <= CurTime() then

        if curdigit == #tostring(code) then
            curdigit = 0
            return true
        end

        curdigit = curdigit + 1


        local digit = string.sub(tostring(code), curdigit, curdigit)

        net.Start("Keypad")
            net.WriteEntity(ent)
            net.WriteInt(0, 4)
            net.WriteUInt(digit, 8)
        net.SendToServer()


        DigitCheck = CurTime() + 0.05
    end
end

local function DecodingThink()
    if !IsValid(CurEnt) then
        TestCode = 1

        hook.Remove("Tick", "DecodingThink")
    end

    if CurEnt:GetStatus() == 0 and NextCheck <= CurTime() then
        if Checking then return end

        local thing = EnterDigits(CurEnt, TestCode)

        if thing == true then
            LocalPlayer():ChatPrint("Trying code \"" .. TestCode .. "\"")
            Checking = true

            net.Start("Keypad")
                net.WriteEntity(CurEnt)
                net.WriteInt(1, 4)
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
    elseif CurEnt:GetStatus() == 1 then
        LocalPlayer():ChatPrint("Found code: " .. LastCode)

        LocalPlayer():ChatPrint("It took " .. os.date("%H hours, %M minutes, %S seconds", 82800 + os.time() - StartTime) .. " to find the code!")

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
        if tr.Entity.CSCode then
            CurEnt = tr.Entity
            TestCode = tr.Entity.CSCode
            hook.Add("Tick", "StartDigitEnter", StartDigitEnter)
        else
            StartDecoding(tr.Entity)
        end
    end
end)