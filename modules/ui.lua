local basalt

local TestData = {
    --["manualcontrols"] = false,
    ["distance"] = {
        ["targetSqr"] = nil,
        ["travelledSqr"] = 0
    },
    ["facingAngle"] = {
        ["currentDegFromNorth"] = 180,
        ["targetDegFromNorth"] = nil
    },
    ["propeller"] ={
        ["liftRpm"] = 10,-- line 1
        ["pushRpm"] = 20,-- line 2
        ["tailDeg"] = 30,-- line 3
        ["tailDegRef"] = 40,-- line 4 -- 90 deg offset from tailDeg sensor, to tell angle direction
        ["tailDegAngle"] = 50,
        ["liftRL1"] = 12,
        ["liftRL2"] = 10,
        ["pushRL1"] = 9,
        ["pushRL2"] = 6,
        ["liftLevel"] = 5,
        ["pushLevel"] = 4
    },
    ["speed"] = {
        ["x"] = 10,
        ["y"] = 20,
        ["z"] = 30
    },
    ["altitude"] = {
        ["target"] = nil,
        ["current"] = 100,
        ["pressure"] = .05
    },
    ["gimbal"] = {
        ["x"] = -1,
        ["z"] = 2,
        ["correctionPX"] = 12,
        ["correctionNX"] = 3,
        ["correctionPZ"] = 6,
        ["correctionNZ"] = 30
    },
    ["fuel"] = {
        {
            ["level"] = 0,
            ["max"] = 800000,
            ["perc"] = 0
        },
        {
            ["level"] = 0,
            ["max"] = 3000000,
            ["perc"] = 0
        }
    }
}

return {
    ["Init"] = function()
        local success, b = pcall(require, "basalt")

        if not success then
            os.execute("wget run https://basalt.madefor.cc/2.5/install.lua minified")
            b = require("basalt")
        end

        basalt = b
    end
}