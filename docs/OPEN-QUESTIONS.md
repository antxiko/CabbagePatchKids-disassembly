# Open questions

What is settled, and what is not, kept apart. What is measured carries its
measurement; what is assumed says so and **has not been written into the
listing as if it were a fact**.

---

## MEASURED, and closed

- The whole cartridge: **16,384 bytes, 16,384 explained, zero unexplained**.
- The listing **reassembles byte for byte** with pasmo.
- **143 data ranges** declared, all crossed against the trace, and every one of
  them either walked with the format its own consumer uses —the run-length
  unpacker, the label engine, the tile lists— or pointed at by an instruction
  that reads it.
- Commented at **24.5%**, with **no routine below 10%** out of 562.
- The three leftover blocks from the other cartridge are identical **byte for
  byte** and have **no reference at all**: not an immediate, not a word inside
  any table.

---

## ASSUMED, and labelled as such

- **That the two bytes of the kid-picking screen choose its look.** What is
  measured is that `0xE05B` and `0xE05C` are a row and a column each, that
  `0x78C9` places five sprites from them, and that the screen offers exactly
  the four actions `0x79BA` produces. Which pieces of the kid change with each
  one has not been read off one by one.
- **The names of some obstacles.** The engine is Athletic Land's and its
  annotations came across with it, so a few of them are named for what they do
  there. The artwork here is different, and the names of the objects have been
  softened wherever the drawing was not checked.

---

## OPEN: what could not be settled

### 1. Whether the three leftover blocks were ever meant to be used

They are complete and well formed —the lists close on their own 0x00 exactly
where the ones that *are* used begin— but nothing reads them. Whether the
recompilation simply carried them along or something in an earlier build did
use them cannot be told from this binary.

### 2. What the demo does, and how it decides

The attract mode plays on its own from state 7, and the states around it (18
and 19) belong to it, but the routine that feeds it its moves has not been
picked apart.

### 3. The six streams of the table at 0x55F5

They are six run-length streams of 96 bytes of VRAM each, one chosen by the
high nibble of `0xE05B`, and they go into the **sprite pattern table**. That
much closes exactly. Which of them is which kid, and whether the choice on the
first screen is what selects them, has not been checked on screen.

### 4. The blind jump at 0x408B

It is the dispatcher's own `jp (hl)`, and its five tables are accounted for, so
nothing is missing from the trace. It is listed here because a blind jump is
always worth naming: if a sixth table existed, this is where it would come
from.
