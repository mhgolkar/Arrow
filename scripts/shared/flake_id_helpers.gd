# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

## Distributed Unique ID helpers
# We use our custom distributed unique resource IDs
# inspired by Twitter's Snowflake, to make sure that
# multiple authors can work on the same project, at the same time,
# and never create resources with identical IDs, which means they can later
# merge their works (using VCS tools such as Git) with minimum effort.
# These IDs have the same structure as Snowflakes, but are constructed by:
# + 41 bits for timestamp (in millisecond,)
# + 6  bits for unique author (producer/machine) identifier and the rest of
# + 16 bits for an index (sequence-number) to make multiple IDs in the same millisecond.
# Each flake will use 63 bits which allows them to fit in `i64` (signed 64-bit integer.)
class_name Flake

## Maximum Number of Authors
# With 6 bits dedicated to unique author-id we can have maximum `2^6` authors (including `0`)
# working on the same project at the same time, which sounds reasonable.
const MAX_POSSIBLE_AUTHOR_ID = 64

## Sequense Size per Millisecond
# Using a sequence number we can produce multiple IDs in each millisecond.
# The size of sequence (so the higher index limit) is `2^16`.
const SEQUENCE_SIZE = 65_536

## Flake Generator
# This class helps generating unique distributed resource IDs,
# to make sure they never overlap even when multiple authors contribute to the same project.
class Generator:
	
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
		_UNIQUE_PRODUCER = producer % MAX_POSSIBLE_AUTHOR_ID
		_TIME_SPAN = _unsafe_unix_now_millisecond()
		_SEQUENCE_IDX = SEQUENCE_SIZE - 1 # (so the first `...next` call will reset timer) 
		print_debug("flake generator (re-)initialized with epoch: ", _EPOCH, " and producer: ", _UNIQUE_PRODUCER)
		pass
	
	func reset_producer(producer:int) -> void:
		_UNIQUE_PRODUCER = producer % MAX_POSSIBLE_AUTHOR_ID
		print_debug("flake generator updated with epoch: ", _EPOCH, " and producer: ", _UNIQUE_PRODUCER)
		pass
	
	## Current Unix Time (Unsafe)
	# It fetches current unix system time in *milliseconds*
	# but is **unsafe** because `get_unix_time` is not accurate and fast enough,
	# so when mixed with `get_ticks_usec` that gets wrapped faster, may produce time going backwards.
	static func _unsafe_unix_now_millisecond():
		return (
			(
				OS.get_unix_time() # seconds
				* 1_000_000 # as microseconds
				+ ( OS.get_ticks_usec() ) % 1_000_1000 # plus microticks
			) / 1000 # converted to milliseconds
			
		)
	
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
			(time << 22) # 🡠 22 bits left shift (= for 6 Author (Producer/Machine) ID + 16 Secquence)
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
			# where we shall reset sequnce,
			_SEQUENCE_IDX = 0
			# and update the internal state:
			_TIME_SPAN = now
		# or still in the same millisecond timestamp:
		else: # (now <= _TIME_SPAN)
			# where we should use the next index in the sequence:
			_SEQUENCE_IDX = (_SEQUENCE_IDX + 1) % SEQUENCE_SIZE
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
		_SEQUENCE_IDX = (_SEQUENCE_IDX + 1) % SEQUENCE_SIZE
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
	
