local G = require(game.ReplicatedFirst:WaitForChild("GLOBALS"))

print(("%s - v%s"):format(G.GAMETITLE, G.VERSION))
print(("Debug is %s."):format((G.DEBUG and "enabled" or "disabled")))

--Setup the PRNG.
math.randomseed(tick()) -- Must be called only one time per program.
math.random() -- Flush the first couple results to fix a known C/Lua bug.
math.random()
math.random()


-- The only things that should be run from Main are modules that are not loaded anywhere else.
-- These modules run their own init when loaded with "require"
local CoreLogic = require(script:WaitForChild("CoreLogic"))