 local expr = require "exposer"

-- this is a kind of silly workaround to get two distinct copies of exposer
package.loaded["exposer"] = false

local expr2 = require "exposer"
 
function love.load()
    -- load settings file
    settingsPath  = "settings.lua"
    if love.filesystem.exists(settingsPath) then
        print("settings file found")
        local contents = love.filesystem.read(settingsPath)
        --contents = string.gsub(contents, "}", "") -- sanitize
        
        expr2.exposed = assert(loadstring("return {" .. contents .. "}"))()
        print("settings file loaded")
    else
        print("settings file not found")
    end
    
    
    expr2.exposed.fontSize = expr2.exposed.fontSize or 14

    if expr2.exposed.topLeft then
        expr2.exposed.topLeft[1] = expr2.exposed.topLeft[1] or 128
        expr2.exposed.topLeft[2] = expr2.exposed.topLeft[2] or 128
    else
        expr2.exposed.topLeft = {128, 128}
    end
    
    if expr2.exposed.bottomRight then
        expr2.exposed.bottomRight[3] = expr2.exposed.bottomRight[3] or 640
        expr2.exposed.bottomRight[4] = expr2.exposed.bottomRight[4] or 384
    else
        expr2.exposed.bottomRight = {640, 384}
    end

    expr2.exposed.textX = expr2.exposed.textX or 10
    expr2.exposed.textY = expr2.exposed.textY or 38

    expr2.exposed.menuWidth = expr2.exposed.menuWidth or 64
    expr2.exposed.menuHeight = expr2.exposed.menuHeight or 64

	-- Initialize font, and set it.
	font = love.graphics.newFont("assets/press-start-2p/PressStart2P.ttf",expr2.exposed.fontSize)
	love.graphics.setFont(font)
	love.window.setTitle("pictures as arrays")
    
    -- load gear picture
    gear = love.graphics.newImage( "assets/whitegear.png")
    gear:setFilter("nearest", "nearest")
    
	-- initial state
	showHUD = true
    showSettings = false
    expr.exposed.redIndex = 1
    expr.exposed.greenIndex = 1
    expr.exposed.blueIndex = 1
    
    -- the number of options in op_apply
    redIndexMax = 7
    greenIndexMax = redIndexMax
    blueIndexMax = redIndexMax

    expr.exposed.redTrans = 1
    expr.exposed.greenTrans = 1
    expr.exposed.blueTrans = 1
    
    --the number of options in op_arg_calc
    redTransMax = 4
    greenTransMax = redTransMax
    blueTransMax = redTransMax
	
	expr.exposed.scale = 1
	expr.exposed.translation = {}
	expr.exposed.translation[1] = 0 
	expr.exposed.translation[2] = 0
	
	
	love.window.setMode(768,512,{borderless = true})
	winW = love.graphics.getWidth()
	winH = love.graphics.getHeight()
	imageData = love.image.newImageData(winW, winH)

	setShaderSetup()
    

    
	image = love.graphics.newImage( imageData )
	
	
	expr.load(
                expr2.exposed.topLeft[1],
                expr2.exposed.topLeft[2], 
                expr2.exposed.bottomRight[1],
                expr2.exposed.bottomRight[2]
             )
    expr2.load(
                expr2.exposed.topLeft[1],
                expr2.exposed.topLeft[2], 
                expr2.exposed.bottomRight[1],
                expr2.exposed.bottomRight[2]
              )
    
    local minMaxAdjusterMaker = 
    function (minValue, maxValue)
		return function (currentValue, distance) 
			local result = math.floor(currentValue + distance)
			if result > maxValue then
				return maxValue
			elseif result < minValue then
				return 1
			else
				return result
			end
		end
	end
	expr.adjusters.redIndex = minMaxAdjusterMaker(1, redIndexMax)
	expr.adjusters.greenIndex = minMaxAdjusterMaker(1, greenIndexMax)
	expr.adjusters.blueIndex = minMaxAdjusterMaker(1, blueIndexMax)
    expr.adjusters.redTrans = minMaxAdjusterMaker(1, redTransMax)
    expr.adjusters.greenTrans = minMaxAdjusterMaker(1, greenTransMax)
    expr.adjusters.blueTrans = minMaxAdjusterMaker(1, blueTransMax)
    
    
    
    expr.adjusters.scale = 
    (function ()
        local f = function (n)
            if n >= 1 then
                return n
            else
                return 2^(n-1)
            end
        end
        
        local fInv = function (n)
            if n >= 1 then
                return n
            else
                local log = math.log
                return log(n)/log(2) + 1
            end
        end

        return function(currentValue, distance)
            return f( fInv(currentValue) + math.floor(distance))
        end
    end)()
	expr.adjusters.translation = {}
	expr.adjusters.translation[1] = 
	function(currentValue, distance) 
		return currentValue - math.floor(distance)
	end
	
	expr.adjusters.translation[2] = expr.adjusters.translation[1]

    
	
    HUDbox =      {expr2.exposed.menuWidth * 0, love.graphics.getHeight() - expr2.exposed.menuHeight, expr2.exposed.menuWidth, expr2.exposed.menuHeight}
    -- using a separate variable in case we want to decouple these later
    resetbox = HUDbox
    leftbox =     {expr2.exposed.menuWidth * 2, love.graphics.getHeight() - expr2.exposed.menuHeight, expr2.exposed.menuWidth, expr2.exposed.menuHeight}
	rightbox =    {expr2.exposed.menuWidth * 4, love.graphics.getHeight() - expr2.exposed.menuHeight, expr2.exposed.menuWidth, expr2.exposed.menuHeight}
    settingsbox = {expr2.exposed.menuWidth * 6, love.graphics.getHeight() - expr2.exposed.menuHeight, expr2.exposed.menuWidth, expr2.exposed.menuHeight}
    applybox =    {expr2.exposed.menuWidth * 8, love.graphics.getHeight() - expr2.exposed.menuHeight, expr2.exposed.menuWidth, expr2.exposed.menuHeight}

	print("loaded")
end

function love.update(dt)
	
	if showHUD then
        if showSettings then
        expr2.update()
        else
        expr.update()
        end
    end

end

function love.draw()

	love.graphics.setShader(shader)
    sendExterns()

	love.graphics.setColor(255,255,255,128)
	love.graphics.draw(image)
	
    love.graphics.setShader(empty_shader)

	if(showHUD) then
		love.graphics.setColor(255,255,255,128)
        if showSettings then
            love.graphics.printf(
                                "Reset to the default settings by deleting the file at \n".. love.filesystem.getSaveDirectory( ) .. "/" ..settingsPath,
                                expr2.exposed.textX,expr2.exposed.textY,winW,"left"
                                )
        else
            love.graphics.printf(
                                "Tap the green + and - buttons or press and drag on the blue parts to adjust values. Tap the blue arrows to display more values",
                                expr2.exposed.textX,expr2.exposed.textY,winW,"left"
                                )
        end

        
        
        if showSettings then
            expr2.draw()
        else
            expr.draw()
        end
		love.graphics.setColor(255,0,0,255)
		love.graphics.rectangle("line",expr2.exposed.topLeft[1],expr2.exposed.topLeft[2],expr2.exposed.bottomRight[1]-expr2.exposed.topLeft[1],expr2.exposed.bottomRight[2]-expr2.exposed.topLeft[2])
						
		love.graphics.rectangle("fill", unpack(settingsbox))
		
		love.graphics.rectangle("fill", unpack(leftbox))
		love.graphics.rectangle("fill", unpack(rightbox))
        
        if not showSettings then
            love.graphics.rectangle("fill", unpack(HUDbox))
		else
            love.graphics.setColor(0,255,0,255)
            love.graphics.rectangle("fill", unpack(applybox))
            love.graphics.rectangle("fill", unpack(resetbox))
        end
		love.graphics.setColor(0,0,255,255)

        love.graphics.draw(gear, settingsbox[1], settingsbox[2], 0, settingsbox[3]/(gear:getWidth()), settingsbox[4]/(gear:getHeight()))
        
        
		love.graphics.polygon(
								"fill", leftbox[1], leftbox[2] + (leftbox[4] / 2),
								leftbox[1] + leftbox[3], leftbox[2],
								leftbox[1] + leftbox[3], leftbox[2] + leftbox[4]
							 ) 
                             
		love.graphics.polygon(
								"fill", rightbox[1] + rightbox[3],
								rightbox[2] + (rightbox[4] / 2),
								rightbox[1], rightbox[2],
								rightbox[1], rightbox[2] + rightbox[4]
							 )
		
        if not showSettings then
		love.graphics.printf( 
								"hide", HUDbox[1],
								HUDbox[2] + ((HUDbox[4] - font:getHeight())/2),
								HUDbox[3],
								"center" 
							)
        else
		love.graphics.printf( 
								"save", applybox[1],
								applybox[2] + ((applybox[4] - font:getHeight())/2),
								applybox[3],
								"center" 
							)
		love.graphics.printf( 
								"reset", resetbox[1],
								resetbox[2] + ((resetbox[4] - font:getHeight())/2),
								resetbox[3],
								"center" 
							)
        end

	end
    
end

function love.keypressed(key)
	
    if  key == "q" or key == "escape" then
		love.event.push('quit')
	end	
	
end

local function isPointInBox (pX, pY, bX, bY, bW, bH)

	return pX > bX and pX < bX+bW and pY > bY and pY < bY+bH
end

function love.mousepressed(x, y, button)

    if (showHUD and isPointInBox(x, y, unpack(settingsbox))) then
		showSettings = not showSettings
    elseif showHUD and showSettings and isPointInBox(x, y, unpack(applybox)) then
        --save settings file
        love.filesystem.write( settingsPath, table_print(expr2.exposed))
        --apply the changes
        love.load()
    elseif showHUD and showSettings and isPointInBox(x, y, unpack(resetbox)) then
        --delete settings file
        love.filesystem.remove( settingsPath)
        --remove old values
        expr2.exposed = {}
        --apply the changes
        love.load()
    elseif (showHUD and isPointInBox(x, y, unpack(HUDbox)))
		or not showHUD then
		showHUD = not showHUD
	elseif showSettings and isPointInBox(x, y, unpack(leftbox)) then
		expr2.page = decAndWrap(expr2.page, 1, expr2.maxPage)
	elseif showSettings and isPointInBox(x, y, unpack(rightbox)) then
		expr2.page = incAndWrap(expr2.page, 1, expr2.maxPage)
	elseif isPointInBox(x, y, unpack(leftbox)) then
		expr.page = decAndWrap(expr.page, 1, expr.maxPage)
	elseif isPointInBox(x, y, unpack(rightbox)) then
		expr.page = incAndWrap(expr.page, 1, expr.maxPage)
	elseif showSettings then
        expr2.mousepressed(x, y, button)
    else
		expr.mousepressed(x, y, button)
	end
end

function love.mousereleased(x, y, button)
	expr.mousereleased(x, y, button)
	expr2.mousereleased(x, y, button)
end

function decAndWrap (variable, lowEnd, highEnd)
	variable = variable - 1
	if variable < lowEnd then
		variable = highEnd
	end	
	return variable
end

function incAndWrap(variable, lowEnd, highEnd)
	variable = variable + 1
	if variable > highEnd then
		variable = lowEnd
	end	
	return variable
end


function setShaderSetup ()

    shader = love.graphics.newShader("assets/shaders.glsl")
    local code = [[

#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
    return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{
    vec4 texcolor = Texel(texture, texture_coords);
    return texcolor * color;
}
#endif]]
    empty_shader = love.graphics.newShader(code,code)

end 

function sendExterns() -- sends externs to shader

    shader:send("translations", expr.exposed.translation)
    
    shader:send("scale", expr.exposed.scale)
    
    shader:send("red_op_number", expr.exposed.redIndex)
    
    shader:send("green_op_number", expr.exposed.greenIndex)
    
    shader:send("blue_op_number", expr.exposed.blueIndex)
    
    shader:send("red_op_args_number", expr.exposed.redTrans)
    
    shader:send("green_op_args_number", expr.exposed.greenTrans)
    
    shader:send("blue_op_args_number", expr.exposed.blueTrans)

end

--a heavy modification of the pair of fuctions found here
--	http://lua-users.org/wiki/TableSerialization
--to output a single line string
function table_print (tt, sep)
    sep = sep or ", "
    if type(tt) == "table" then
        local sb = {}
        local newValue = ""
        for key, value in pairs (tt) do
            if type(value) == "string" then
                newValue = '"' .. value .. '"'
            else
                newValue = to_string(value)
            end
            if type(key) == "number" then
                table.insert(sb, string.format("%s"..sep, newValue))
            elseif type (key) == "string" then
                table.insert(sb, string.format("%s = %s"..sep, key, newValue))
            else
                table.insert(sb, string.format(
                "%s = %s"..sep, tostring (key), newValue))
            end
        end
        return table.concat(sb)
    else
    return tt .. "\n"
    end
end

function to_string ( tbl, sep)
    if  type( tbl ) == "table" then
        sep = sep or ", "
        -- removing final sep, there might be a better way.
        local tblStr = string.reverse(
                            string.gsub (
                                        string.reverse(table_print(tbl, sep)),
                                        string.reverse(sep),
                                        "",
                                        1
                                        )
                                     )
        return "{" .. tblStr .. "}"
    elseif type( tbl ) == "string" then
        return tbl
    else
        return tostring(tbl)
    end
end
