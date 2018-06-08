# dungeon-escape-vhdl-game
An old-style Dungeon Escape game that runs on an FPGA, implemented in VHDL

Note: All the work on this project has been done collaboratively by "sefak" and "akgokce" - Commit history does not reflect the actual workflow, pushings were done after everything was set.

[![A photo from this project](https://i.imgur.com/OzcGAqS.png)](https://vimeo.com/273938913 "A video of this project")

Brief Game Design:
The game has 4 states: Start, Gameplay, Win, and Gameover.
The objective is to reach the exit door without hitting any obstacle or monster within 180 seconds. To do that, the player has to pick up the key and open the exit door.

Notes on Generating Bit File:
This project does not generate programming file on Windows 10 machine using Xilinx ISE Design Suite 14.7. Instead, use Xilinx on Windows 7 or Linux based operating system.
The game is designed for Nexys 3 board based on Spartan 6 architecture and it uses 98% device's resources.

Disclaimer:
The purpose of putting the code on GitHub is to give an intuition and guidance to those who want to implement a similar VHDL game. Use it with your own caution. No responsibilities regarding violation of an ethics codes of a course are accepted.
