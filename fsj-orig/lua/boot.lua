-- Boot the original client scripts, then install the in-process fake servers. Claude.
package.path = "res://lua/ShellClientLua/?.lua;res://lua/ShellCommonLua/?.lua;res://lua/?.lua;" .. package.path
