
Entity = require "danmaku.entity"
Enemy = require "danmaku.enemy"

class extends Enemy
	new: (arg) =>
		arg or= {}

		Enemy.__init self, arg

		@disableTimeoutRemoval = true

		@name = arg.name or "???"
		@touchable = arg.touchable or false

		@onEndOfSpell = arg.endOfSpell or ->

		-- Number of frames the boss should wait between two spellcards.
		@interSpellDelay = arg.interSpellDelay or 180

		@spellcards = {}
		for i = 1, #arg
			spell = arg[i]

			if type(spell) == "table"
				table.insert @spellcards, spell

		@spellSuccess = true

		@currentSpell = false
		@currentSpellIndex = 0
		@spellStartFrame = 0
		@spellEndFrame = 0
		@spellEndHealth = 0

	update: =>
		@\doUpdate =>
			if @frame == 0
				-- Recalculating lives and trimming incompatible spellcards.
				@lives = 0
				newSpellcards = {}
				for spell in *@spellcards
					unless spell\playableAtDifficulty @game.difficulty
						print "Skipping #{spell} due to difficulty."
						continue

					if spell.endOfLife or spell == @spellcards[#@spellcards]
						@lives += 1

					table.insert newSpellcards, spell

				@spellcards = newSpellcards

			currentSpell = @spellcards[@currentSpellIndex]

			if currentSpell
				if @health <= @spellEndHealth
					@\switchToNextSpell!
				elseif @frame == @spellStartFrame
					@damageable = true
					currentSpell.update self
					@speed = 0

					if currentSpell.position
						-- Fixes rounding errors.
						{:x, :y} = currentSpell.position self
						@x, @y = x, y
				elseif @frame == @spellEndFrame
					@spellSuccess = false

					@\switchToNextSpell!
				elseif @frame >= @spellStartFrame
					currentSpell.update self
			else
				if @currentSpellIndex == 0
					-- Before first spell…
					-- FIXME: hardcoded value.
					if @frame == 60
						@game\setBoss self

						@\switchToNextSpell!

					true
				else
					-- After last spell…
					print "last spell done"

				-- Used only when not dealing with spellcards.
				if @onUpdate
					@\onUpdate!

	switchToNextSpell: =>
		if @currentSpell
			if @onEndOfSpell
				@\onEndOfSpell @currentSpell

		@game\clearScreen!

		if @currentSpellIndex > 0
			difference = @spellEndFrame - @frame

			-- Jumping into the future~
			@frame += difference
			@game.frame += difference

		oldSpell = @spellcards[@currentSpellIndex]


		@currentSpellIndex += 1
		@touchable = true

		-- FIXME: WHY DOES IT HAVE TO TAKE TWO LINES? I hate you.
		while @spellcards[@currentSpellIndex] and not @spellcards[@currentSpellIndex]\playableAtDifficulty @game.difficulty
			print "Skipping #{@spellcards[@currentSpellIndex]}"
			@currentSpellIndex += 1

		spell = @spellcards[@currentSpellIndex]

		if spell
			if oldSpell and oldSpell.endOfLife
				@lives -= 1

			-- We're resetting the health after any kind of attack in
			-- case there was a slight damage overflow.
			health = 0

			index = @currentSpellIndex
			while @spellcards[index] and not @spellcards[index].endOfLife
				health += @spellcards[index].health
				index += 1

			@health = health
			@spellEndHealth = health - spell.health

			if not oldSpell or oldSpell.endOfLife
				@maxHealth = health

			@spellStartFrame = @frame + @interSpellDelay
			@spellEndFrame = @frame + spell.timeout + @interSpellDelay

			if spell.position
				position = spell.position self

				distance = Entity.distance self, position
				angle = math.atan2 position.y - @y,
					position.x - @x

				@speed = distance / @interSpellDelay
				@angle = angle

			@damageable = false
		else -- end of spellcards list
			@health = 1

		@spellSuccess = true
		@currentSpell = spell

	die: =>
		if @spellcards[@currentSpellIndex]
			@\switchToNextSpell!
		else
			@game\setBoss nil
			super\die!

