--[[
  Utility to generate a stream of programs from the same distribution
  produced by this codebase, and referenced in the learning to execute
  paper.
]]--

require 'torch'
include 'data.lua'

local cmd = torch.CmdLine()
cmd:option('-length_min', 1, 'min length of numbers in generated programs')
cmd:option('-length_max', 1, 'max length of numbers in generated programs')
cmd:option('-nesting_min', 1, 'min nesting depth of generated programs')
cmd:option('-nesting_max', 1, 'max nesting depth of generated programs')
cmd:option('-n', 10, 'number of programs to generate (0 for infinite)')
cmd:option('-prog_sep', '\n\n', 'separator to put between programs')
cmd:option('-out_sep', '@', 'separator to put between program and output value')
cmd:option('-seed', 0, 'manual seed (0 for random seed)')
local opt = cmd:parse(arg)

local length_min = opt.length_min
local length_max = opt.length_max
assert(1 <= length_min and length_min <= length_max)
local nesting_min = opt.nesting_min
local nesting_max = opt.nesting_max
assert(1 <= nesting_min and nesting_min <= nesting_max)

local gen = torch.Generator()
if opt.seed ~= 0 then
  torch.manualSeed(gen, opt.seed)
else
  torch.seed(gen)
end

function hardness_fun()
  return torch.random(gen, length_min, length_max), torch.random(gen, nesting_min, nesting_max)
end

local retries_max = 100

function write_programs(n, prog_sep, out_sep)
  local i = 1
  while n == 0 or i <= n do 
    local retries = 0
    local code, var, output
    
    -- Naive rejection method; generating longer programs often fails.
    -- This slightly messes up the distribution (we favor short programs
    -- since we just reject the really long ones) but makes the script
    -- much less likely to crash. For shorter programs (nesting < 20)
    -- this shouldn't make much of a difference.
    while true do
      if pcall(function() code, var, output = compose(hardness_fun) end) then
	output = string.format("%d", output)
    
	local input = ""
	for i = 1, #code do
	  input = string.format("%s%s\n", input, code[i])
	end
	input = string.format("%sprint(%s)", input, var)
    
	io.write(input)
	io.write(out_sep)
	io.write(output)
	io.write(prog_sep)

	break
      else
	if retries > retries_max then error('failed to generate program') end
	retries = retries + 1
      end
    end
    
    i = i + 1
  end
end

write_programs(opt.n, opt.prog_sep, opt.out_sep)
