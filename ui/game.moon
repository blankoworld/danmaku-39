
{
	:Danmaku,
	:Entity,
	:Enemy,
	:Bullet,
	:Player,
	:Stage
} = require "danmaku"

utf8 = require "utf8"

-- Needed for configuration thingies.
data = require "data"
highscores = require "highscores"
vscreen = require "vscreen"
fonts = require "fonts"

Menu = require "ui.tools.menu"
Grid = require "ui.tools.grid"

state = {
}

tryAgainItem = ->
	{
		label: "Restart"
		onSelection: {
			{
				label: "Are you sure?"
			}
			{
				label: "No"
				onSelection: =>
					@\setItemsList @items.parent
			}
			{
				label: "Yes"
				onSelection: =>
					state\enter state.options, state.playerOptions
			}
		}
	}

mainMenuItem = ->
	{
		label: "Main menu"
		onSelection: {
			{
				label: "Are you sure?"
			}
			{
				label: "No"
				onSelection: =>
					@\setItemsList @items.parent
			}
			{
				label: "Yes"
				onSelection: =>
					state.manager\setState require "ui.menu"
			}
		}
	}

gameOverMenu = ->
	Menu {
		font: state.menu.font
		{
			label: "Game over…"
		}
		tryAgainItem!
		mainMenuItem!
	}

victoryMenu = ->
	Menu {
		font: state.menu.font
		{
			label: "Victory!"
		}
		tryAgainItem!
		mainMenuItem!
	}

state.enter = (options, players) =>
	@players = {}
	@paused = false
	@awaitingPlayerName = false
	@resuming = false

	@playerName = data.config.lastUsedName

	@font = fonts.get nil, 24

	options or= {}
	{
		:noBombs, :pacific, :training, :difficulty
		:stage
	} = options

	@options = options
	@playerOptions = players

	@stage = stage

	@menu = Menu {
		font: love.graphics.newFont "data/fonts/miamanueva.otf", 32
		{
			label: "Pause"
		}
		{
			label: "Resume"
			onImmediateSelection: =>
				state.resuming = @drawTime
			onSelection: =>
				state.resuming = false
				state.paused = false
		}
		tryAgainItem!
		mainMenuItem!
	}
	@nameGrid = Grid {
		columns: 20
		rows: 8
		cells: {
			"a", "b", "c", "d", "e", "f", "g", "h", "i", "j",
			"k", "l", "m", "n", "o", "p", "q", "r", "s", "t",

			"u", "v", "w", "x", "y", "z", " ", " ", " ", " ",
			" ", " ", " ", " ", " ", " ", " ", " ", " ", " ",

			"A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
			"K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",

			"U", "V", "W", "X", "Y", "Z", " ", " ", " ", " ",
			".", ",", "’", ":", ";", "@", "#", "(", ")", "[",

			" ", " ", " ", " ", " ", " ", " ", " ", " ", " ",

			" ", " ", " ", " ", " ", " ", " ", " ", " ", " ",

			" ", " ", " ", " ", " ", " ", " ", " ", " ", " ",
			" ", " ", " ", " ", " ", " ", " ", " ", " ", "END",
		}
		cursors: {
			{
				color: {0, 0, 0}
			}
		}
		onSelection: (cursor) =>
			char = @cells[cursor.index]

			if char == "END"
				self = state

				highscores.save @stage, @players, @options, @danmaku.score, @playerName
				data.config.lastUsedName = @playerName
				data.saveConfig!

				@awaitingPlayerName = false
				@paused = 0
			else
				state.playerName ..= char
		onEscape: =>
			name = state.playerName
			offset = utf8.offset(name, -1)

			if offset
				state.playerName = string.sub(name, 1, offset - 1)
		drawCursor: =>
		drawCell: (r, grid) =>
			unless self
				self = " "

			if grid.cells[grid.cursors[1].index] == self
				love.graphics.setColor 255, 127, 127
			else
				love.graphics.setColor 255, 255, 255

			love.graphics.print (self or " "), r.x, r.y - 14
	}

	width, height = switch stage.screenRatio
		when "wide"
			974, 585
		when "narrow"
			375, 750
		else
			600, 750

	@danmaku = Danmaku
		x: 25
		y: 25
		stage: Stage stage
		:width, :height
		:noBombs, :pacific, :training, :difficulty


	-- FIXME: update their positions, based on players count
	for player in *players
		player.x = @danmaku.width / 2
		player.y = @danmaku.height * 5 / 6

		table.insert @players, @danmaku\addEntity Player player

	print stage.name, players[1].name, players[1].secondaryAttackName, options
	@highscore = do
		if #players == 1
			highscores.get stage, players[1], options

	-- Mostly serves to print entity hitboxes.
	@danmaku.debug = false

state.drawWideUI = (x, y) =>
	sizemod = vscreen.rectangle.sizeModifier
	h = @danmaku.drawHeight + (@danmaku.y - y) * 2
	totalWidth = @danmaku.drawWidth - 25 * sizemod * (#@players - 1)

	love.graphics.setFont @font

	for i = 1, #@players
		player = @players[i]

		r = with {
			w: (totalWidth) / #@players
			h: vscreen.height * sizemod - h - 25 * sizemod
			x: x
			y: y + h
		}
			.x += .w * (i - 1) + 25 * sizemod * i

		love.graphics.setColor 255, 255, 255
		love.graphics.rectangle "line", r.x, r.y, r.w, r.h

		love.graphics.print "B: #{player.bombs}", r.x + 10 * sizemod, r.y + 10 * sizemod
		love.graphics.print "L: #{player.lives}", r.x + 10 * sizemod, r.y + 50 * sizemod
		love.graphics.print "S: #{player.score}", r.x + 10 * sizemod, r.y + 90 * sizemod

livesBox =
	height: 35
	draw: (player, x, y, sizemod) =>
		love.graphics.setColor 255, 125, 1955
		for i = 0, 9
			if (i + 1) <= player.lives
				love.graphics.rectangle "line",
					x + 40 * sizemod * i, y,
					35 * sizemod, 35 * sizemod

bombsBox =
	height: 35
	draw: (player, x, y, sizemod) =>
		love.graphics.setColor 127, 255, 127
		for i = 0, 9
			if (i + 1) <= player.bombs
				love.graphics.rectangle "line",
					x + 40 * sizemod * i, y,
					35 * sizemod, 35 * sizemod

normalPlayerBox =
	resize: (sizemod) =>
		x = vscreen.rectangle.x

		@height = 260 * sizemod
		@width = love.graphics.getWidth! -
			state.danmaku.drawWidth -
			(state.danmaku.x - x) * 3
	draw: (player, x, y, sizemod) =>
		love.graphics.rectangle "line",
			x, y,
			@width, @height

		love.graphics.print "#{player.name}",
			x + 5 * sizemod, y + 5 * sizemod

		love.graphics.print "Score",
			x + 5 * sizemod, y + 45 * sizemod
		love.graphics.print "#{player.score}",
			x + 250 * sizemod, y + 45 * sizemod

		love.graphics.print "Points",
			x + 5 * sizemod, y + 75 * sizemod
		love.graphics.print "#{player.customData.points or 0}",
			x + 250 * sizemod, y + 75 * sizemod

		love.graphics.print "Graze",
			x + 5 * sizemod, y + 105 * sizemod
		love.graphics.print "#{player.graze}",
			x + 250 * sizemod, y + 105 * sizemod

		livesBox\draw player,
			x + 5 * sizemod, y + 140 * sizemod,
			sizemod
		bombsBox\draw player,
			x + 5 * sizemod, y + 180 * sizemod,
			sizemod

		love.graphics.setColor 255, 63, 63
		love.graphics.rectangle "line",
			5 * sizemod + x, 220 * sizemod + y,
			(@width - 5 * 2) * sizemod * (player.power / player.maxPower), 35 * sizemod
		love.graphics.print "#{player.power}/#{player.maxPower}",
			5 * sizemod + x, 225 * sizemod + y

		love.graphics.setColor 255, 255, 255

smallPlayerBox =
	resize: (sizemod) =>
		@height = 160
		@width = 405
	draw: (player, x, y, sizemod) =>
		love.graphics.rectangle "line", x, y, @width, @height

		love.graphics.print "#{player.name}", x + 5, y + 5
		love.graphics.print "#{player.score}", x + 250, y + 5

		livesBox\draw player, x + 5, y + 40, sizemod
		bombsBox\draw player, x + 5, y + 80, sizemod

		love.graphics.setColor 255, 63, 63
		love.graphics.rectangle "line",
			5 + x, 120 + y,
			245 * (player.power / player.maxPower), 35
		love.graphics.print "#{player.power}/#{player.maxPower}", 5 + x, 125 + y

		love.graphics.setColor 255, 255, 255
		love.graphics.print "#{player.graze}",
			250 + x, 125 + y

		love.graphics.setColor 255, 255, 255

state.drawNormalUI = (x, y) =>
	w = @danmaku.drawWidth + (@danmaku.x - x) * 2
	sizemod = vscreen.rectangle.sizeModifier

	love.graphics.setFont @font

	love.graphics.setColor 255, 255, 255
	love.graphics.print "#{love.timer.getFPS!} FPS",
		x + w + 10 * sizemod, y + 705 * sizemod
	love.graphics.print "#{#@danmaku.entities} entities",
		x + w + 10 * sizemod, y + 770 * sizemod

	love.graphics.print "Score",
		x + w + 10 * sizemod, y + 10 * sizemod
	love.graphics.print "#{@danmaku.score}",
		x + w + 255 * sizemod, y + 10 * sizemod

	love.graphics.print "Highscore",
		x + w + 10 * sizemod, y + 40 * sizemod
	love.graphics.print "#{math.max @highscore, @danmaku.score}",
		x + w + 255 * sizemod, y + 40 * sizemod

	box = if #@players > 2
		smallPlayerBox
	else
		normalPlayerBox

	for i, player in ipairs @players
		box\resize sizemod
		box\draw player,
			x + w + 5 * sizemod,
			y + 80 * sizemod + (i - 1) * (box.height + 5 * sizemod),
			sizemod

state.draw = =>
	{:x, :y, :w, :h, sizeModifier: sizemod} = vscreen\update!
	danmakuSizemod = state.danmaku.drawWidth / state.danmaku.width

	@danmaku.drawWidth = @danmaku.width * math.floor sizemod
	@danmaku.drawHeight = @danmaku.height * math.floor sizemod

	@danmaku.x = x + 25 * sizemod
	@danmaku.y = y + 25 * sizemod

	-- XXX: Temporary markers.
	for item in *@danmaku.items
		if item.important
			love.graphics.setColor 255, 0, 0
			love.graphics.circle "fill",
				@danmaku.x + item.x * danmakuSizemod,
				@danmaku.y + @danmaku.drawHeight,
				32 * danmakuSizemod

	-- XXX: Temporary markers.
	if @danmaku.boss
		boss = @danmaku.boss

		love.graphics.setColor 255, 0, 0
		love.graphics.circle "fill",
			@danmaku.x + boss.x * danmakuSizemod,
			@danmaku.y + @danmaku.drawHeight,
			32 * danmakuSizemod

	if @paused or @awaitingPlayerName
		c = if @resuming
			c = 127 + 127 * math.min 1, @menu.drawTime - @resuming
		else
			c = 255 - 127 * math.min 1, @paused or 0
		love.graphics.setColor c, c, c
	else
		love.graphics.setColor 255, 255, 255

	@danmaku\draw!

	if @danmaku.width >= 700
		@\drawWideUI x, y
	else
		@\drawNormalUI x, y

	if state.awaitingPlayerName
		love.graphics.print @playerName .. "_", @nameGrid.x, @nameGrid.y - 50

		@nameGrid\draw!
	if state.paused
		@menu\draw!

state.update = (dt) =>
	{:x, :y, :w, :h, sizeModifier: sizemod} = vscreen\update!
	danmakuSizemod = state.danmaku.drawWidth / state.danmaku.width

	@font = fonts.get nil, 24 * sizemod

	if state.awaitingPlayerName
		@nameGrid.width = 520 * danmakuSizemod
		@nameGrid.height = 300 * danmakuSizemod
		@nameGrid.x = x + 25 * sizemod
		@nameGrid.y = y + vscreen.height - @nameGrid.height - 25 * danmakuSizemod

		return
	elseif state.paused
		state.paused += dt
		print danmakuSizemod

		@menu.width = 400 * danmakuSizemod
		@menu.itemHeight = 64 * danmakuSizemod
		@menu.font = fonts.get "miamanueva", 32 * danmakuSizemod
		@menu.x = x + 25 * sizemod + 25 * danmakuSizemod
		@menu.y = y + 25 * sizemod + 325 * danmakuSizemod
		@menu\update dt

		return

	if @danmaku.endReached
		state.awaitingPlayerName = true
		print "We reached the end."
		state.paused = 0

		@menu = victoryMenu!

		return

	allJoysticks = love.joystick.getJoysticks!
	for i = 1, #@players
		inputs = data.config.inputs[i]
		padInputs = data.config.gamepadInputs[i]
		keyboard = (key) ->
			love.keyboard.isScancodeDown inputs[key]
		gamepad = (button) ->
			for joystick in *allJoysticks
				if joystick\getID! == padInputs.gamepad
					return joystick\isGamepadDown padInputs[button]

				return false

		-- Gamepad joysticks get priority, here.
		joystick = do
			joystick = nil
			for j in *allJoysticks
				if padInputs.gamepad == j\getID!
					joystick = j
					break
			joystick

		@players[i].movement.left = false
		@players[i].movement.right = false
		@players[i].movement.up = false
		@players[i].movement.down = false

		if joystick and joystick\getAxisCount! >= 1
			dx, dy = joystick\getAxes!

			if dx > 0
				@players[i].movement.right = dx
			elseif dx < 0
				@players[i].movement.left = -dx

			if dy > 0
				@players[i].movement.down = dy
			elseif dy < 0
				@players[i].movement.up = -dy

		for key in *{"left", "right", "up", "down"}
			@players[i].movement[key] or= (keyboard(key) or gamepad(key)) and 1

		for key in *{"bombing", "firing", "focusing"}
			@players[i][key] = keyboard(key) or gamepad(key)

	playersLeft = false
	for i, player in ipairs @players
		if not player.readyForRemoval
			playersLeft = true
			break

	unless playersLeft
		state.paused = 0

		@menu = gameOverMenu!

	@danmaku\update dt

state.keypressed = (key, ...) =>
	if state.awaitingPlayerName
		@nameGrid\keypressed key, ...
	elseif state.paused
		-- Holy shit, this is the project’s hackiest hack. I think.
		-- FIXME: I DON’T EVEN KNOW WHAT THIS DOES ANYMORE HALP
		if key == "escape" and @menu.items.selection == 1 and @menu.items[1].label == "Resume"
			@menu\back!
		else
			@menu\keypressed key, ...
	elseif key == "escape"
		@menu.drawTime = 0

		unless state.paused
			state.paused = 0

state.gamepadpressed = (joystick, button) =>
	if state.awaitingPlayerName
		@nameGrid\gamepadpressed joystick, button
	elseif state.paused
		if button == "start"
			if state.danmaku.endReached
				return

			@menu.selectionTime = 0
			@menu.selectedItem = {
				onSelection: =>
					state.paused = false
			}
		else
			@menu\gamepadpressed joystick, button
	elseif button == "start"
		@menu.drawTime = 0

		unless state.paused
			state.paused = 0

state

