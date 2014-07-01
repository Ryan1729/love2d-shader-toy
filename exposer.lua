-- ver 0.0.5
-- Displays given variables and allows the user to adjust them directly.
-- Written for use with love2d

-- how to use:
-- add the line
-- 		local exposer = require "exposer"
--		to main.lua
-- store the variables you wish to expose in 'exposed' table below.
-- 		if you add a number then the number will be controlled by clicking and
--		dragging left and right
--		if you add a table the first two elements will be controlled by clicking
--  	and dragging left/right and up/down respectively 
--  	Buttons may optionally be added.
-- put this file in the same location as main.lua
-- call exposer.load from love.load
-- call exposer.draw from love.draw
-- call exposer.update from love.update
-- call exposer.mousepressed from love.mousepressed
-- call exposer.mousereleased from love.mousereleased
-- that's it.
-- optional: if you don't like your values being incremented/decremented
--		by one you can add a function to exposer.adjusters using the same key you 
--		used to add your variable to exposer.exposed. This function will be passed 
--		two values in order. If the user cicks and drags, the values will be the 
--		current value of the variable and the number of pixels the user has dragged 
--		the mouse, divided by exposer.dragResolution. If instead the the plus or minus
--		buttons are clicked, the second value passed will be 1 and -1 respectively 
--		Positive distance values indicate either rightward or upward movement, 
--		negative values the opposite. The function should then reutrn the next value 
--		for your variable to be assigned to. You can use defaultAdjuster below as a 
--		guide, defaultAdjuster will be called if there is no entry in 
--		exposer.adjusters with a matching key. If your variable is a table, place a 
--		table with two functions in it in exposer.adjusters. the first will modify 
--		the first value, the second will modify the second.
--optional: you can change any of the color variables in exposer below
-- 		to tables of the form {r,g,b,a} to adjust how exposed values look, 
-- 		before calling exposed.load. If you want to adjust how things look later
-- 		you'll have to call exposed.load again.
-- optional: exposer.dragResolution determines how many pixels (as returned by
--		love.mouse.getX() and love.mouse.getY() ) that the user has to drag to
--		change the value. You can change this value if you want to, no need to
--		run anything again you aren't already.
-- optional: other adjustable variables should be self explanatory

local exposer = {
					-- you can these adjust and they will be read, not written
					boxColor = { 0, 0, 255, 128},
					hotColor = { 0, 60, 240, 128}, 
					textColor = {255, 255, 255, 128},
					buttonColor = {0, 255, 0, 128},
					dragResolution = 2,
					buttonHeightToBoxHeightRatio = 1,
					wantDragging = true,
					wantButtons = true,
					adjusters = {},
					exposed = {},
					-- these will be overwritten and so shouldn't be changed
					x = 0,
					y = 0,
					drag = {},
					buttons = {},
					page = 1,
					maxPage = 1,
				}
				
--------------------------------------------
--local functions
--------------------------------------------
local function defaultAdjuster(currentValue, distance) 

	return currentValue + math.floor(distance)

end
--a modification of the pair of fuctions found here
--	http://lua-users.org/wiki/TableSerialization
--to output a single line string
local function table_print(tt, sep, done)
	done = done or {}
	sep = sep or ", "
	if type(tt) == "table" then
		local sb = {}
		for key, value in pairs (tt) do
			if type (value) == "table" and not done [value] then
				done [value] = true
				table.insert(sb, "{");
				table.insert(sb, to_string(value, sep))
				table.insert(sb, "}"..sep);
			elseif "number" == type(key) then
				table.insert(sb, string.format("%s"..sep, tostring(value)))
			else
				table.insert(sb, string.format(
				"%s = \"%s\""..sep, tostring (key), tostring(value)))
			end
		end
		return table.concat(sb)
	else
	return tt .. "\n"
	end
end

local function to_string( tbl, sep)
	if  "nil"       == type( tbl ) then
		return tostring(nil)
	elseif  "table" == type( tbl ) then
		sep = sep or ", "
		-- removing final sep, there might be a better way.
		return string.reverse(
					string.gsub (
								string.reverse(table_print(tbl, sep)),
								string.reverse(sep),
								"",
								1
								)
							 )
	elseif  "string" == type( tbl ) then
		return tbl
	else
		return tostring(tbl)
	end
end

---------------------------------
--http://lua-users.org/wiki/CopyTable
---------------------------------
local function deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[deepcopy(orig_key)] = deepcopy(orig_value)
		end
		setmetatable(copy, deepcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

---------------------------------
--http://lua-users.org/wiki/SortedIteration
---------------------------------
local function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex )
    return orderedIndex
end

local function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.

    --print("orderedNext: state = "..tostring(state) )
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex( t )
        key = t.__orderedIndex[1]
        return key, t[key]
    end
    -- fetch the next value
    key = nil
    for i = 1,table.getn(t.__orderedIndex) do
        if t.__orderedIndex[i] == state then
            key = t.__orderedIndex[i+1]
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

local function orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end

---------------------------------
--written for this library
---------------------------------
local function isPointInBox (pX, pY, bX, bY, bW, bH)

	return pX > bX and pX < bX+bW and pY > bY and pY < bY+bH
end

local function oneDDistanceFromRange (point, lowEdgeOfRange, widthOfRange)
	if point < lowEdgeOfRange then
		return point - lowEdgeOfRange
	elseif point > (lowEdgeOfRange + widthOfRange) then
		return point - (lowEdgeOfRange + widthOfRange)
	else 
		return 0
	end
end

local function adjust(value, i, step)
	if 	exposer.adjusters[i] then
		exposer.exposed[i] =
			exposer.adjusters[i](
								value,
								step
								)
	else							
		exposer.exposed[i] =
			defaultAdjuster(
							value,
							step
							)
	end
end

local function adjustTable (valueTable, i, xStep, yStep)
	if 	type(exposer.adjusters[i]) == "table" 
	and #exposer.adjusters[i] >=2 then
				
		exposer.exposed[i][1] = 
			exposer.adjusters[i][1](
									valueTable[1],--exposer.drag[i].oldValue[1], 
									xStep
									)
					

		exposer.exposed[i][2] = 
			exposer.adjusters[i][2](
									valueTable[2],--exposer.drag[i].oldValue[2],
									yStep
									)
	
	else
		exposer.exposed[i][1] = 
			defaultAdjuster(
							valueTable[1],--exposer.drag[i].oldValue[1], 
							xStep
							)
					

		exposer.exposed[i][2] = 
			defaultAdjuster(
							valueTable[2],--exposer.drag[i].oldValue[2],
							yStep
							)
	end
end


--------------------------------------------
--public functions
--------------------------------------------
function exposer.load(minX, minY, maxX, maxY)
	local defaultMinX = 0
	local defaultMinY = 0
	local defaultMaxX = love.graphics.getWidth()
	local defaultMaxY = love.graphics.getHeight()
	local buffer = 10
	local boxColorString = string.format("%d,%d,%d,%d", unpack(exposer.boxColor))
	local hotColorString = string.format("%d,%d,%d,%d", unpack(exposer.hotColor))
	local textColorString = string.format("%d,%d,%d,%d", unpack(exposer.textColor))
	local buttonColorString = string.format("%d,%d,%d,%d", unpack(exposer.buttonColor))
	local max = math.max
	local separator = ", "
	local font = love.graphics.getFont()
	local fontHeight = font:getHeight()
	local fontWidth = 0 
	local boxWidth = 0
	local boxHeight = 0
	local currentPage = 1
	local rightEdge = 0
	local bottomEdge = 0
	local wantButtons = exposer.wantButtons
	local buttonHeightToBoxHeightRatio = exposer.buttonHeightToBoxHeightRatio
	local buttonWidth = 0
	if wantButtons then
		buttonWidth = (2 * buffer) + max(font:getWidth("-"),font:getWidth("+"))
	end
	--this string is used to make a function created with loadstring in 
	--exposer.load a closure containing the functions to_string and table_print
	local to_stringString =
	[[local table_print, to_string
	
	table_print = function (tt, sep, done)
	  done = done or {}
	  sep = sep or ", "
	  if type(tt) == "table" then
		local sb = {}
		for key, value in pairs (tt) do
		  if type (value) == "table" and not done [value] then
			done [value] = true
			table.insert(sb, "{");
			table.insert(sb, to_string(value, sep))
			table.insert(sb, "}"..sep);
		  elseif "number" == type(key) then
			table.insert(sb, string.format("%s"..sep, tostring(value)))
		  else
			table.insert(sb, string.format(
				"%s = \"%s\""..sep, tostring (key), tostring(value)))
		   end
		end
		return table.concat(sb)
	  else
		return tt .. "\n"
	  end
	end

	to_string = function ( tbl, sep)
		if  "nil"       == type( tbl ) then
			return tostring(nil)
		elseif  "table" == type( tbl ) then
			sep = sep or ", "
			-- removing final sep, there might be a better way.
			return string.reverse(
						string.gsub (
									string.reverse(table_print(tbl, sep)),
									string.reverse(sep),
									"",
									1
									)
								 )
		elseif  "string" == type( tbl ) then
			return tbl
		else
			return tostring(tbl)
		end
	end]]
	
	minX = minX or defaultMinX -- set minX to defaultMinX if minX is nil
	minY = minY or defaultMinY -- set minY to defaultMinY if minY is nil
	maxX = maxX or defaultMaxX -- set maxX to defaultMaxX if maxX is nil
	maxY = maxY or defaultMaxY -- set maxY to defaultMaxY if maxY is nil


	
	exposer.x, exposer.y = minX + buffer, minY + buffer
	
	for i,v in orderedPairs(exposer.exposed) do

		
		fontWidth = max(font:getWidth(i),font:getWidth(to_string(v)))
		
		boxWidth = (2 * buffer) + fontWidth
		boxHeight = (3 * buffer) + (2*fontHeight)
		rightEdge = exposer.x + boxWidth
		if  wantButtons then
			buttonWidth = (2 * buffer) + max(font:getWidth("-"),font:getWidth("+"))
			rightEdge = rightEdge + (2 * buttonWidth) 
		end
		if rightEdge > maxX then

			exposer.x = minX + buffer
			exposer.y = exposer.y + boxHeight + buffer
			bottomEdge = exposer.y + boxHeight
			if bottomEdge > maxY then
				exposer.y = minY + buffer
				currentPage = currentPage + 1
			end
			
		end
		

		--the function this creates will be called by exposer.draw
		local s = 
		to_stringString ..
		[[
		local value ,isHot = ...;
		
		if isHot then
			love.graphics.setColor(]]..hotColorString..[[)
		else
			love.graphics.setColor(]]..boxColorString..[[)
		end 
		]] ..
		"love.graphics.rectangle(\"fill\", " .. exposer.x + buttonWidth .. ", " .. exposer.y .. ", " .. boxWidth .. ", " .. boxHeight .. ") "
		
		--draw buttons
		if wantButtons then 
		s = s ..
		"love.graphics.setColor(".. buttonColorString ..") " .. 
		"love.graphics.rectangle(\"fill\", " .. exposer.x .. ", " .. exposer.y .. ", " .. buttonWidth  .. ", " .. boxHeight*buttonHeightToBoxHeightRatio  .. ") " ..
		"love.graphics.rectangle(\"fill\", " .. exposer.x + buttonWidth + boxWidth .. ", " .. exposer.y .. ", " .. buttonWidth  .. ", " .. boxHeight*buttonHeightToBoxHeightRatio .. ")" 
		end
		s = s ..
		"love.graphics.setColor(".. textColorString ..") " .. 
		"love.graphics.printf(\"".. i .. "\", " .. exposer.x  + buttonWidth + buffer.. ", " ..exposer.y + buffer .. ", " ..fontWidth.. ", \"center\") " ..
		"love.graphics.printf(to_string(value), " .. exposer.x + buttonWidth + buffer.. ", " .. exposer.y + fontHeight + (2 * buffer) .. ", " ..fontWidth.. ", \"center\") "
		
		--draw button text
		if wantButtons then 
		s = s ..
		"love.graphics.printf(\"-\", " .. exposer.x .. ", " ..exposer.y + ((boxHeight - fontHeight)/2) .. ", " ..buttonWidth.. ", \"center\") " ..
		"love.graphics.printf(\"+\", " .. exposer.x + buttonWidth + boxWidth .. ", " ..exposer.y + ((boxHeight - fontHeight)/2) .. ", " ..buttonWidth.. ", \"center\") "
		end
		
		
		local drawFunction, errmsg = assert(loadstring(s))
		if not drawFunction then
			drawFunction = function() love.graphics.rectangle("fill", 50, 50, 50, 50 ) end
			print(errmsg)
		end
		
		if exposer.drag[i] then
			--these are done as assignments to keep any other values stored in 
			--the table
			exposer.drag[i].draw = drawFunction
			exposer.drag[i].x = exposer.x + buttonWidth
			exposer.drag[i].y = exposer.y
			exposer.drag[i].width = boxWidth
			exposer.drag[i].height = boxHeight
			exposer.drag[i].page = currentPage
		else
		--active indicates whether the value is being dragged, draw is explained above and the rest are necessary for checking if the value is being clicked
		exposer.drag[i] = {	
							active = false, 
							draw = drawFunction,
							x = exposer.x + buttonWidth, 
							y = exposer.y,
							width = boxWidth, 
							height = boxHeight,
							page = currentPage,
							oldValue = deepcopy(v)
						  }
		end
		
		if exposer.buttons[i] then
			exposer.buttons[i].leftx = exposer.x
			exposer.buttons[i].y = exposer.y
			exposer.buttons[i].rightx = exposer.x + buttonWidth + boxWidth
			exposer.buttons[i].width = buttonWidth
			exposer.buttons[i].height = boxHeight * buttonHeightToBoxHeightRatio
		else
			exposer.buttons[i] = {
									leftx = exposer.x,
									y = exposer.y,
									rightx = exposer.x + buttonWidth + boxWidth,
									width = buttonWidth,
									height = boxHeight * buttonHeightToBoxHeightRatio,
								 }
		end
		-- update/reset variable for next box
		exposer.x = exposer.x + boxWidth + (2* buttonWidth) + buffer
		
	end
	
	exposer.maxPage = currentPage
end

function exposer.update()
	local dragResolution = exposer.dragResolution
	local page = exposer.page
	for i,v in orderedPairs(exposer.exposed) do
		if exposer.drag[i].page == page
		and exposer.drag[i].active==true 
		and not isPointInBox(love.mouse.getX(), love.mouse.getY(), 
							 exposer.drag[i].x, exposer.drag[i].y,
							 exposer.drag[i].width, exposer.drag[i].height) then
			if 	type(exposer.exposed[i]) == "table" 
					and #exposer.exposed[i] >=2 then
					
				local xDistance = oneDDistanceFromRange(
														love.mouse.getX(),
														exposer.drag[i].x,
														exposer.drag[i].width
														)
							
				local yDistance = oneDDistanceFromRange(
														love.mouse.getY(),
														exposer.drag[i].y,
														exposer.drag[i].height
														)
														
				adjustTable (
							exposer.drag[i].oldValue, 
							i, 
							xDistance/dragResolution,
							yDistance/dragResolution
							)
			else
				
				local distance = oneDDistanceFromRange(
														love.mouse.getX(),
														exposer.drag[i].x,
														exposer.drag[i].width
													  )
				adjust(exposer.drag[i].oldValue, i, distance/dragResolution)
			end
		end
	end
end

function exposer.draw()
	local page = exposer.page
	
	for i,v in pairs(exposer.drag) do
		if v.page == page then
			v.draw(exposer.exposed[i],v.active)
		end
	end

end

function exposer.mousepressed (x, y, button)
	if button == "l" then
	local page = exposer.page
		if exposer.wantButtons then
		--checking if buttons were clicked on
			for i,v in pairs(exposer.buttons) do
				if exposer.drag[i].page == page then
					if isPointInBox (x, y, v.leftx, v.y, v.width, v.height) then
                        if 	type(exposer.exposed[i]) == "table" 
                        and #exposer.exposed[i] >=2 then
                            adjustTable (exposer.exposed[i], i, -1, -1)
                        else
                            adjust(exposer.exposed[i], i, -1)
                        end
					elseif isPointInBox (x, y, v.rightx, v.y, v.width, v.height) then
						if 	type(exposer.exposed[i]) == "table"
                        and #exposer.exposed[i] >=2 then
                            adjustTable (exposer.exposed[i], i, 1, 1)
                        else
                            adjust(exposer.exposed[i], i, 1)
                        end
					end
				end
			end
		end
		 
		if exposer.wantDragging then
			exposer.startDrag(x, y, button)
		end
	end
end

function exposer.startDrag(x, y, button)
	local deepcopy = deepcopy 
	local page = exposer.page
	--make the dragging happen
	for i,v in pairs(exposer.drag) do
		
	  if exposer.drag[i].page == page 
	  and isPointInBox (x, y, v.x, v.y, v.width, v.height) then
		v.active = true
		v.oldValue = deepcopy(exposer.exposed[i])
	  end
	  
	end
end

function exposer.mousereleased(x, y, button)
	if exposer.wantDragging then
		exposer.stopDrag(x, y, button)
	end
end

function exposer.stopDrag (x, y, button)
	--make the dragging stop happening
   if button == "l" then
		for i,v in pairs(exposer.drag) do
		
			v.active = false
			
		end

   end
   
end



return exposer 
