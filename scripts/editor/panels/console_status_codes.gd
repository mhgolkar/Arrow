# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Console Status Codes
# (sent by nodes being played, interpreted by the console)
class_name CONSOLE_STATUS_CODE

# the outgoing played slot is connected to no other node
const EXIT_END = 0
const EXIT_END_MESSAGE = "CONSOLE_STATUS_EXIT_END_MESSAGE" # Translated ~ "◆ EOL: {name} ({uid})"

# the outgoing played slot is connected to no other node
const END_EDGE = 1
const END_EDGE_MESSAGE = "CONSOLE_STATUS_END_EDGE_MESSAGE" # Translated ~ "◆ EOL: {name} ({uid})"

# no default action is taken by the node (e.g. due to being skipped)
const NO_DEFAULT = 2
const NO_DEFAULT_MESSAGE = "CONSOLE_STATUS_NO_DEFAULT_MESSAGE" # Translated ~ "⚠ No DEFAULT: {name} ({uid})"
