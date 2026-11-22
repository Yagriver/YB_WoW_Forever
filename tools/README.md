# Tools

Development helpers, not installed anywhere.

- `t5.py`, `t51.py`: addon tests in a simulated WoW API (Lua 5.4 and real Lua 5.1 through `lupa`).
- `run.py`, `ui.py`, `dev_block.py`, `pad_block.py`: simulator stubs and screen renders.
- `gen_vdf.py`: builds the Steam Input layout; `vdf.py`, `vdf_check.py`: parse and check it.

Requires `pip install lupa pillow`. Some scripts still expect to run from a working copy of the project;
paths are cleaned up as the tools move to the shared engine in phase 2.
