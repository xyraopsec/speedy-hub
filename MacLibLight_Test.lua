--[[ MacLib LIGHT | TEST — loads MacLibLight.lua from the `test` branch.
   Test version only. Production files on master are untouched. ]]
local MacLib = loadstring(game:HttpGet(
  "https://raw.githubusercontent.com/xyraopsec/speedy-hub/test/MacLibLight.lua?v=1.0"
))()
MacLib:Demo()
