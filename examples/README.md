# Example Projects

This directory contains example Arrow projects that demonstrate various features
of the narrative design tool.

## The Last Signal

**File:** `the_last_signal.arrow`

A sci-fi mystery narrative where you play as Commander Elara Voss, the sole
remaining crew member aboard the deep-space research station Helios-7. A
mysterious signal leads you to uncover a secret that changes everything.

### Features Demonstrated

- **Characters** — Named characters with color coding (ARIA the AI, Commander Voss)
- **Variables** — Four variables of different types (`num`, `bool`, `str`) tracking
  trust level, inventory, story flags, and crew status
- **Branching Dialogue** — Dialog nodes with character portraits driving the story
- **Player Choices** — Interaction nodes offering meaningful decisions that affect
  the narrative path
- **Conditions** — Condition nodes that check variable state to alter story flow
  (e.g. whether the signal was decoded, trust level with ARIA)
- **Variable Updates** — Nodes that modify variables based on player choices
- **Multiple Scenes** — Three scenes (Bridge/Comms, Cargo Hold, Discovery) organized
  as chapters
- **Jump Nodes** — Cross-scene navigation connecting the story across scenes
- **Multiple Endings** — Two distinct endings based on the player's final choice

### How to Use

1. Open Arrow
2. Go to **File > Open** and select `the_last_signal.arrow`
3. Explore the node graph to see the branching structure
4. Use **File > Export Playable HTML** to generate a playable version
