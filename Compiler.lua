
local Compiler = {};
Bytecode = require('BytecodeEditor.lua');

Compiler.Compile = function(self, src)
    local bytes = Bytecode.Editor:StringToBytecodeArray(src);
    local AllChunksLoaded = false;
    local CompiledChunks = {};
    local chunkLevel = 0;
    repeat --compiler has to run things in order also
        local byteChunk = Bytecode.Editor:ReplicateArray(bytes);
        local ActionData = Bytecode.Editor:StripActionPhase(byteChunk);
        --[[
            have to recursive through these things:
            action statements
            function chains
            loop and if statements
            transfer and break statements
        ]]
        if (ActionData ~= nil) then --Means it involves defining, easier to seperate phases
            local byteChunkCopy = Bytecode.Editor:ReplicateArray(byteChunk);
            Bytecode.Editor:RemoveIndexChunk(byteChunk, ActionData.Initial, #ActionData, false);
            Bytecode.Editor:RemoveIndexChunk(byteChunkCopy, 1, ActionData.Final, false); --for value phase
            local VariableData = Bytecode.Editor:StripVariablePhase(byteChunk);
            local ValueData = Bytecode.Editor:StripValuePhase(byteChunkCopy); --this is going to be tricky
            chunkLevel = chunkLevel + 1;
            CompiledChunks[chunkLevel] = {
                Variable = VariableData;
                Action = ActionData;
                Value = ValueData;
            };
        elseif (ActionData == nil) then --it might just be simple function chaining, but actiondata only searches for |
            
        end;
    until
        AllChunksLoaded == true;
    
    return CompiledChunks;
end;

return Compiler;