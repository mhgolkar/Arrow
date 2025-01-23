# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

class_name Flake

## Native distributed incremental (default) UID helpers
# Arrow's native flake generator guarantees uniqueness of resource IDs
# while multiple authors can work simultaneously on the same project
# by assigning each author a unique ID and an incremental seed bucket.
# These values will be mixed together with a chapter ID
# which can be unique to each document for projects divided into multiple ones,
# and shape a 53-bit UID for each resource. In other words:
# + 10 bit chapter ID (0 - 1024; Optional, default `0`)
# +  6 bit author ID (0 - 64; At least one author with `0` ID)
# + 37 bit for more than 137 billion resources per author per chapter.
# These UIDs are fast, minimal (specially for single author projects,)
# and fit into a double-precision floating-point representation
# (allowing easier use of Arrow projects in many languages such as JS.)
#
# Note:
# You can change the bit sizes from Settings, but it is highly recommended to
# **keep the defaults** for most of workflows.
#
class Native:

	const BIT_SIZE = Settings.NATIVE_DISTRIBUTED_UID_BIT_SIZES

	## Maximum Chapter ID
	# By default with 10 bits dedicated to unique chapter-id we can have maximum `2^10 = 1024` sub-projects (including `0`.)
	const CHAPTER_ID_EXCLUSIVE_LIMIT = int( pow( 2, BIT_SIZE[0] ) )
	
	## Maximum Number of Authors
	# With 6 bits dedicated to unique author-id we can have maximum `2^6 = 64` authors (including `0`)
	# which sounds reasonable for number of authors working on the same project at the same time.
	const AUTHOR_ID_EXCLUSIVE_LIMIT = int( pow( 2, BIT_SIZE[1] ) )

	## Maximum number of resource IDs per author per chapter (by default `2^37 = 137_438_953_472` including `0`)
	const RESOURCE_SEED_EXCLUSIVE_LIMIT = int( pow( 2, BIT_SIZE[2] ) )

	# Shifts for each segment
	const CHAPTER_SHIFT = BIT_SIZE[1] + BIT_SIZE[2] # (by default 43 bits left shift to open space for 6-bit Author ID and 37-bit resource Seed)
	const AUTHOR_SHIFT = BIT_SIZE[2] #  # (by default 37 bits left shift to open way for resource Seed)
	const SEED_SHIFT = 0 # (seed fills up the rest of open space provided by other shifts and is the last segment)

	# A reference to the active project meta data to directly manage incremental seeds per authors
	var _PROJECT_META: Dictionary

	# ID of the author currently producing the UIDs
	var _ACTIVE_AUTHOR_ID: int

	func _init(project_meta: Dictionary, active_author: int) -> void:
		_ACTIVE_AUTHOR_ID = active_author
		_PROJECT_META = project_meta
		print_debug(
			"native flake generator (re-)initialized with authors: ",
			_PROJECT_META.authors, "; active: ", _ACTIVE_AUTHOR_ID
		)
		pass
	
	func reset_active_author(id: int) -> void:
		_ACTIVE_AUTHOR_ID = id
		print_debug("native flake generator active author changed: ", _ACTIVE_AUTHOR_ID)
		pass
	
	static func _calculate_unchecked(chapter: int, author: int, next_seed: int) -> int:
		return (
			# > Godot `int` is i64 so we can directly shift them (not using first few bits.)
			(chapter << CHAPTER_SHIFT) 
			| (author << AUTHOR_SHIFT)
			| (next_seed << SEED_SHIFT)
		)
	
	## Next Flake
	# Simply generates an integer flake from tracked values.
	# returns null if any of the values is out of bound.
	func next() -> int:
		var chapter: int = _PROJECT_META.chapter
		var active_author: int = _ACTIVE_AUTHOR_ID
		var their_next_seed: int = _PROJECT_META.authors[active_author][1]
		if (
			chapter < CHAPTER_ID_EXCLUSIVE_LIMIT &&
			active_author < AUTHOR_ID_EXCLUSIVE_LIMIT &&
			their_next_seed < RESOURCE_SEED_EXCLUSIVE_LIMIT
		):
			var next_uid = _calculate_unchecked(chapter, active_author, their_next_seed)
			_PROJECT_META.authors[active_author][1] = (their_next_seed + 1)
			return next_uid
		else:
			printerr(
				"Native flake generator internal state failed: ",
				_PROJECT_META.authors, " active: ", active_author, " chapter: ", chapter
			)
			return -999


## Time-based Distributed Unique ID helpers
# We use our custom distributed unique resource IDs
# inspired by Twitter's *Snowflake*, to make sure that
# multiple authors can work on the same project, at the same time,
# and never create resources with identical IDs, which means they can later
# merge their works (using VCS tools such as Git) with minimum effort.
# These IDs have the same structure as Snowflakes, but are constructed by:
# + 41 bits for timestamp (in millisecond,)
# + 6  bits for unique author (producer/machine) identifier and the rest of
# + 16 bits for an index (sequence-number) to make multiple IDs in the same millisecond.
# Each flake will use 63 bits which allows them to fit in `i64` (signed 64-bit integer.)
class Snow:
	
	## Maximum Number of Authors
	# With 6 bits dedicated to unique author-id we can have maximum `2^6` authors (including `0`)
	# working on the same project at the same time, which sounds reasonable.
	const AUTHOR_ID_EXCLUSIVE_LIMIT = 64

	## Sequence Size per Millisecond
	# Using a sequence number we can produce multiple IDs in each millisecond.
	# The size of sequence (so the higher index limit) is `2^16`.
	const SEQUENCE_SIZE_EXCLUSIVE_LIMIT = 65_536

	# Epoch since which we calculate the 41 time-stamp bits of the flake
	var _EPOCH: int

	# Machine/Author Unique ID constructing 6 bits of the flake, preventing clashes
	var _UNIQUE_PRODUCER: int

	# Sequence index/number (16 more bits) allowing us to generate more IDs within the same millisecond
	var _SEQUENCE_IDX: int
	
	# Last time an ID is generated (in milliseconds)
	var _TIME_SPAN: int

	func _init(epoch:int, producer:int) -> void:
		_EPOCH = epoch
		_UNIQUE_PRODUCER = producer % AUTHOR_ID_EXCLUSIVE_LIMIT
		_TIME_SPAN = _unsafe_unix_now_millisecond()
		_SEQUENCE_IDX = SEQUENCE_SIZE_EXCLUSIVE_LIMIT - 1 # (so the first `...next` call will reset timer) 
		print_debug("snowflake generator (re-)initialized with epoch: ", _EPOCH, " and producer: ", _UNIQUE_PRODUCER)
		pass
	
	func reset_producer(producer:int) -> void:
		_UNIQUE_PRODUCER = producer % AUTHOR_ID_EXCLUSIVE_LIMIT
		print_debug("flake generator updated with epoch: ", _EPOCH, " and producer: ", _UNIQUE_PRODUCER)
		pass
	
	## Current Unix Time (Unsafe)
	# It fetches current unix system time in *milliseconds*
	static func _unsafe_unix_now_millisecond():
		# We don't need this hacky timer ...
		# (Which is very **unsafe** because `OS.get_unix_time` is not accurate and fast enough,
		# so when mixed with `OS.get_ticks_usec` that gets wrapped faster, may produce time going backwards)
		# return (
		# 	(
		# 		OS.get_unix_time() # seconds
		# 		* 1_000_000 # as microseconds
		# 		+ ( OS.get_ticks_usec() ) % 1_000_1000 # plus micro-ticks
		# 	) / 1000 # converted to milliseconds
		# )
		# ... thanks to new `Time` singleton
		return int( Time.get_unix_time_from_system() * 1000 )
	
	func _await_next_millisecond(previous:int) -> int:
		var next = 0
		while next <= previous:
			next = _unsafe_unix_now_millisecond()
		return next
	
	func _since_epoch(time:int) -> int:
		var since = time - _EPOCH
		if since < 0 :
			printerr("generating flakes with prehistoric timestamp! epoch: ", _EPOCH, " time: ", time)
		return since
	
	func _calculate_unchecked(time:int, producer:int, index:int) -> int:
		return (
			# > Godot `int` is i64 so we can directly shift them:
			(time << 22) # 🡠 22 bits left shift (= for 6 Author (Producer/Machine) ID + 16 Sequence)
			| (producer << 16) # 🡠 16 bits left shift (for Sequence)
			| index # fills up the rest of (16) bits
		)
	
	## Next Flake (Real-time)
	# Returns next distributed unique identifier.
	# It generates realtime IDs (i.e. timestamp is always equal to call time.)
	func realtime_next() -> int:
		# First get real-time stamp:
		var now = _unsafe_unix_now_millisecond()
		# and make sure we never make backward flakes:
		if now < _TIME_SPAN:
			print_debug("System clock went backward! last: ", _TIME_SPAN, " now: ", now, "; going with the last.")
			now = _TIME_SPAN
		# ...
		# Now we are either in the new generation (later timestamp:)
		if now > _TIME_SPAN:
			# where we shall reset sequence,
			_SEQUENCE_IDX = 0
			# and update the internal state:
			_TIME_SPAN = now
		# or still in the same millisecond timestamp:
		else: # (now <= _TIME_SPAN)
			# where we should use the next index in the sequence:
			_SEQUENCE_IDX = (_SEQUENCE_IDX + 1) % SEQUENCE_SIZE_EXCLUSIVE_LIMIT
			# But if we have already used all the indices,
			if _SEQUENCE_IDX == 0:
				# it's necessary to wait for the next timestamp and update internals
				# (otherwise we can't guarantee uniqueness.)
				_TIME_SPAN = _await_next_millisecond(now)
		# Now, we can generate the ID with a timestamp relative to our custom `_EPOCH`:
		var relative_timestamp = _since_epoch(_TIME_SPAN)
		return _calculate_unchecked(relative_timestamp, _UNIQUE_PRODUCER, _SEQUENCE_IDX)
	
	## Next Flake (Quick/Full-Sequence)
	# Returns next identifier. Compared to `realtime_next` method,
	# this one uses all indices in the sequence before trying new time-stamp.
	# This method is faster, but not real-time.
	func lazy_next() -> int:
		# We try the next index for the sequence number
		_SEQUENCE_IDX = (_SEQUENCE_IDX + 1) % SEQUENCE_SIZE_EXCLUSIVE_LIMIT
		# If it's zero, we have produced all the possible IDs in the millisecond,
		if _SEQUENCE_IDX == 0:
			# so we should update the production time span:
			var now = _unsafe_unix_now_millisecond()
			if now <= _TIME_SPAN:
				# (if we are still in the same millisecond, or time is going backwards,
				# we have to wait for the next millisecond)
				now = _await_next_millisecond(now)
			# Keep this new millisecond (time span) for the next generations:
			_TIME_SPAN = now
		# Finally, we can generate the ID with a timestamp relative to our custom `_EPOCH`:
		var relative_timestamp = _since_epoch(_TIME_SPAN)
		return _calculate_unchecked(relative_timestamp, _UNIQUE_PRODUCER, _SEQUENCE_IDX)
	
