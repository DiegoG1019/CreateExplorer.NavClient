---@diagnostic disable: inject-field

local basalt, vector
local context
local TwoPi = math.pi * 2

local maxExpectedSpeed, maxExpectedAltitude = 100, 600

local function rotate(x, y, angleRad)
    local v = vector(x, y):rotate(-angleRad + math.pi)
    return math.floor(v.x), math.floor(v.y)
end

local function rotateDeg(x, y, angleDeg)
    return rotate(x, y, math.rad(angleDeg))
end

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
        ["current"] = 150,
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
            ["level"] = 454674,
            ["max"] = 800000
        },
        {
            ["level"] = 2845214,
            ["max"] = 3000000
        }
    }
}

local uiState = {
    Ship = TestData,
    Elements = {
        ["distance"] = {
            ["target"] = nil,
            ["travelled"] = nil
        },
        ["facingAngle"] = {
            ["currentDegFromNorth"] = nil,
            ["targetDegFromNorth"] = nil
        },
        ["propeller"] ={
            ["liftRpm"] = nil,
            ["pushRpm"] = nil,
            ["tailDeg"] = nil,
            ["liftLevel"] = nil,
            ["pushLevel"] = nil,
        },
        ["speed"] = {
            ["total"] = nil,
            ["components"] = nil
        },
        ["altitude"] = {
            ["target"] = nil,
            ["bar"] = nil,
            ["current"] = nil,
            ["pressure"] = nil
        },
        ["gimbal"] = {
            ["x"] = nil,
            ["z"] = nil,
            ["corrections"] = nil
        },
        ["fuel"] = {
            [1] = {
                ["progress"] = nil,
                ["current"] = nil,
                ["max"] = nil
            },
            [2] = {
                ["progress"] = nil,
                ["current"] = nil,
                ["max"] = nil
            }
        }
    }
}

local function SetUpView()
    local frame = basalt.getMainFrame()
    frame.background = basalt.rgb("FF091E54")
    basalt.use("charts")

    local base = frame:addRow()

    local leftPanel = base:addRow({
        width = 3
    })

    local rightPanel = base:addColumn({
        height = basalt.fill()
    })
    
    -- altitude

    local altitudeBar = leftPanel:addColumn({gap = 0, padding = 0, width = 1})

    altitudeBar:addLabel({
        text = "A",
        foreground = colors.lightBlue,
        width = 1
    })

    uiState.Elements["altitude"]["bar"] = altitudeBar:addProgressBar({
        direction = "up",
        barColor = colors.lightBlue,
        showPercentage = false,
        progress = 0,
        height = basalt.percent(1),
        width = 1
    })
    local altitudeSection = rightPanel:addRow()

    local altitudeTextSection = altitudeSection:addColumn()
    local heightTextSection = altitudeTextSection:addRow()

    heightTextSection:addLabel({
        foreground = colors.lightBlue,
        text = "Altitude: "
    })

    uiState.Elements["altitude"]["current"] = heightTextSection:addLabel({
        foreground = colors.blue,
        text = "0 blocks"
    })

    local pressureTextSection = altitudeTextSection:addRow()
    pressureTextSection:addLabel({
        foreground = colors.lightBlue,
        text = "Pressure: "
    })

    uiState.Elements["altitude"]["pressure"] = pressureTextSection:addLabel({
        foreground = colors.blue,
        text = "0"
    })

    -- distance
    --local distanceSection = rightPanel:addRow()
    
    -- propeller
    local propellerSection = rightPanel:addColumn()
    local propellerRpm = propellerSection:addRow()
    propellerRpm:addLabel({
        text = "Lift: ",
        foreground = colors.purple
    })

    uiState.Elements["propeller"]["liftRpm"] = propellerRpm:addLabel({ -- lift rpm
        text = "0 RPM",
        foreground = colors.magenta
    })

    propellerRpm:addLabel({
        text = " @ ",
        foreground = colors.purple
    })

    uiState.Elements["propeller"]["liftLevel"] = propellerRpm:addLabel({ -- lift level
        text = "0",
        foreground = colors.red
    })

    propellerRpm:addLabel({
        text = " | Push: ",
        foreground = colors.purple
    })

    uiState.Elements["propeller"]["pushRpm"] = propellerRpm:addLabel({ -- push rpm
        text = "0 RPM",
        foreground = colors.magenta
    })

    propellerRpm:addLabel({
        text = " @ ",
        foreground = colors.purple
    })

    uiState.Elements["propeller"]["pushLevel"] = propellerRpm:addLabel({ -- push level
        text = "0",
        foreground = colors.red
    })
    
    -- speed
    
    local speedBar = leftPanel:addColumn({gap = 0, padding = 0, width = 1})

    speedBar:addLabel({
        text = "S",
        foreground = colors.yellow
    })

    uiState.Elements["speed"]["bar"] = speedBar:addProgressBar({
        direction = "up",
        barColor = colors.yellow,
        showPercentage = false,
        progress = 0,
        height = basalt.percent(1),
        width = 1
    })

    local speedSection = rightPanel:addRow()

    speedSection:addLabel({
        foreground = colors.lightBlue,
        text = "Speed: "
    })

    uiState.Elements["speed"]["total"] = speedSection:addLabel({
        foreground = colors.yellow,
        text = "0 m/s"
    })

    uiState.Elements["speed"]["components"] = speedSection:addLabel({
        foreground = colors.orange,
        text = " (x:0, z:0) m/s"
    })

    -- gimbal

    local gimbalRow = rightPanel:addRow()
    gimbalRow:addLabel({text = "Gimbal: ", foreground = colors.lightBlue})
    gimbalRow:addLabel({text="x", foreground = basalt.rgb("FF254B97")})
    uiState.Elements["gimbal"]["x"] = gimbalRow:addLabel({
        foreground = colors.blue,
        text = "0"
    })

    gimbalRow:addLabel({text=" ; "})

    gimbalRow:addLabel({text="z", foreground = basalt.rgb("FF8F3535")})
    uiState.Elements["gimbal"]["z"] = gimbalRow:addLabel({
        foreground = colors.red,
        text = "0"
    })

    gimbalRow:addLabel({text=" -> "})

    uiState.Elements["gimbal"]["corrections"] = gimbalRow:addLabel({
        foreground = colors.green,
        text = "0"
    })

    -- Fuel

    local fuelSection = rightPanel:addRow()
    local fuelTank1 = fuelSection:addColumn()
    local fuelTank2 = fuelSection:addColumn()

    fuelTank1:addLabel({
        text = "Fuel 1",
        foreground = colors.orange
    })

    uiState.Elements["fuel"][1]["progress"] = fuelTank1:addProgressBar({
        direction = "right",
        barColor = basalt.rgb("FFC68C19"),
        showPercentage = true,
        progress = 0
    })

    local fuelTank1Text = fuelTank1:addRow()
    uiState.Elements["fuel"][1]["current"] = fuelTank1Text:addLabel({
        text = "0",
        foreground = colors.orange
    })

    fuelTank1Text:addLabel({
        text = " / ",
        foreground = colors.yellow
    })

    uiState.Elements["fuel"][1]["max"] = fuelTank1Text:addLabel({
        text = "0",
        foreground = colors.orange
    })

    fuelTank2:addLabel({
        text = "Fuel 2",
        foreground = colors.orange
    })

    uiState.Elements["fuel"][2]["progress"] = fuelTank2:addProgressBar({
        direction = "right",
        barColor = basalt.rgb("FFC68C19"),
        showPercentage = true,
        progress = 0
    })

    local fuelTank2Text = fuelTank2:addRow()
    uiState.Elements["fuel"][2]["current"] = fuelTank2Text:addLabel({
        text = "0",
        foreground = colors.orange
    })

    fuelTank2Text:addLabel({
        text = " / ",
        foreground = colors.yellow
    })

    uiState.Elements["fuel"][2]["max"] = fuelTank2Text:addLabel({
        text = "0",
        foreground = colors.orange
    })

    -- LARGE WIDGETS HERE
    local largeWidgetSection = rightPanel:addRow({
        width = basalt.fill(),
        height = basalt.fill()
    })

    -- facing angle
    local facingAngleSection = largeWidgetSection:addColumn({
        width = basalt.fill(),
        height = basalt.fill()
    })
    
    facingAngleSection:addLabel({
        text = "Facing Direction",
        foreground = colors.white,
        alignSelf = "center"
    })

    uiState.Elements["facingAngle"]["currentDegFromNorth"] = facingAngleSection:addLabel({
        text = "0 deg",
        foreground = colors.white,
        alignSelf = "center"
    })

    uiState.Elements["facingAngle"]["Widget"] = facingAngleSection:addCanvas({
        width = basalt.fill(),
        height = basalt.fill()
    })

    uiState.Elements["facingAngle"]["Widget"].draw = function(self, buffer)        
        local width, height = self.width, self.height - 1

        -- create a vector where the origin is at the bottom center of the screen
        local xoff, yoff = self.width / 2, self.height
        local x, y = 0, height

        local facing = uiState.Ship["facingAngle"]["currentDegFromNorth"]

        for i = 0, 360, 5 do

            local x2, y2 = rotateDeg(x, y, i)
            buffer:blit(xoff + x2, yoff + y2, ".", colors.black, colors.blue)
        end

        local fg, bg
        if (height >= 7 * 2) then
            fg, bg = colors.black, colors.red
        else
            if facing > 90 and facing < 270 then
                facing = facing - 180
                fg, bg = colors.red, colors.black
                buffer:blit(math.floor(width / 2), math.floor(height / 2), "v", fg, bg)
            else
                fg, bg = colors.black, colors.red
                buffer:blit(math.floor(width / 2), math.floor(height / 2), "^", fg, bg)
            end
        end
        
        local markerx, markery = rotateDeg(x, y, facing)
        buffer:blit(xoff + markerx, yoff + markery, "*", fg, bg)
    end

    local unused = largeWidgetSection:addColumn({
        width = basalt.fill(),
        height = basalt.fill()
    })
end

local lastUpdateCheck = -1
local ix = 0
local function Refresh()
    -- debug

    uiState.Ship["facingAngle"]["currentDegFromNorth"] = (uiState.Ship["facingAngle"]["currentDegFromNorth"] + 1) % 360

    -- end

    if context.System.UpdateChecks ~= lastUpdateCheck then
        lastUpdateCheck = context.System.UpdateChecks
        basalt.getMainFrame():markDirty()
    end

    uiState.Elements["fuel"][1]["progress"].progress = (uiState.Ship["fuel"][1]["level"] / uiState.Ship["fuel"][1]["max"]) * 100
    uiState.Elements["fuel"][2]["progress"].progress = (uiState.Ship["fuel"][2]["level"] / uiState.Ship["fuel"][2]["max"]) * 100

    uiState.Elements["fuel"][1]["current"].text = uiState.Ship["fuel"][1]["level"]
    uiState.Elements["fuel"][2]["current"].text = uiState.Ship["fuel"][2]["level"]

    uiState.Elements["fuel"][1]["max"].text = uiState.Ship["fuel"][1]["max"]
    uiState.Elements["fuel"][2]["max"].text = uiState.Ship["fuel"][2]["max"]

    uiState.Elements["gimbal"]["x"].text = tostring(uiState.Ship["gimbal"]["x"])
    uiState.Elements["gimbal"]["z"].text = tostring(uiState.Ship["gimbal"]["z"])
    uiState.Elements["gimbal"]["corrections"].text = "px:"..tostring(uiState.Ship["gimbal"]["correctionPX"])..", pz"..tostring(uiState.Ship["gimbal"]["correctionPZ"])..", nx"..tostring(uiState.Ship["gimbal"]["correctionNX"])..", nz"..tostring(uiState.Ship["gimbal"]["correctionNZ"])
    
    uiState.Elements["altitude"]["bar"].progress = (uiState.Ship["altitude"]["current"] / maxExpectedAltitude) * 100
    uiState.Elements["altitude"]["current"].text = tostring(uiState.Ship["altitude"]["current"]).." blocks"
    uiState.Elements["altitude"]["pressure"].text = tostring(uiState.Ship["altitude"]["pressure"])

    local spdx, spdz = uiState.Ship["speed"]["x"], uiState.Ship["speed"]["z"]
    local spd = math.sqrt((spdx * spdx + spdz * spdz))

    uiState.Elements["speed"]["components"].text = string.format(" (x:%.2f, z:%.2f)", spdx, spdz)
    uiState.Elements["speed"]["total"].text = string.format("%.2f m/s", spd)

    uiState.Elements["speed"]["bar"].progress = (spd / maxExpectedSpeed) * 100

    uiState.Elements["propeller"]["liftLevel"].text = uiState.Ship["propeller"]["liftLevel"]
    uiState.Elements["propeller"]["liftRpm"].text = uiState.Ship["propeller"]["liftRpm"] .. " RPM"
    uiState.Elements["propeller"]["pushLevel"].text = uiState.Ship["propeller"]["pushLevel"]
    uiState.Elements["propeller"]["pushRpm"].text = uiState.Ship["propeller"]["pushRpm"] .. "RPM"

    uiState.Elements["facingAngle"]["currentDegFromNorth"].text = string.format("%.2f deg", uiState.Ship["facingAngle"]["currentDegFromNorth"])

    uiState.Elements["facingAngle"]["Widget"]:markRenderDirty()
end

local function InstallRequire(lib, cmd)
    local success, b = pcall(require, lib)

    if not success then
        shell.run(cmd)
        b = require(lib)
    end

    return b
end

return {
    ["Init"] = function(ctx)
        context = ctx
        basalt = InstallRequire("basalt", "wget run https://basalt.madefor.cc/2.5/install.lua minified")
        vector = InstallRequire("vector", "wget https://raw.githubusercontent.com/automattf/vector.lua/refs/heads/master/vector.lua")

        SetUpView()
    end,

    ["Update"] = Refresh,

    ["Event"] = function (event, ...)
        basalt.update(event, ...)
    end
}