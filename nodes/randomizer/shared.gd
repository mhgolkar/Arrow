# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Randomizer Node Type Shared Class
# (shared functionalities and constants)
class_name RandomizerSharedClass

# randomizers are by definition, to dispatch one (single) input
# to one of many possible outputs,
# randomly chosen
# so there must be at least two outgoing slots for any randomizer
const RANDOMIZER_MINIMUM_ACCEPTABLE_OUT_SLOTS = 2
# and there can be a limit for the sake of tidiness
const RANDOMIZER_MAXIMUM_ACCEPTABLE_OUT_SLOTS = 10

# Note: the one incoming slot is always there in the `.tscn`
