# Refactoring
* Make more type definitions
* Make UI use addChild/removeChild instead
* Allow default data outside of events
* Add ability to disable elements receiving input
	* tllayerlabel.lua does a hacky method
* Figure out when to disconnect Luvent signals in Property objects
* Add content width/height
* Canvas ignores SpriteTool drawing when switching while drawing


# Functionality
* Add docking
* Add multiple views in one tab


# Enhancements
* Make unsaved indicator
* Make sure magic number is always detected as binary


# Bugs
* Some places expect a palette to exist and have 2 colors
* Having a large palette sidebar can make buttons on the inspector unclickable
* Exporting data doesn't take into account scale
