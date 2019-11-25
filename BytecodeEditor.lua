
--[[
    \ are basically parenthesis
]]
local Service = {};
Service.Converter = {};
Service.Editor = {};
local warn = warn or print;

--[[
	NetworkQueue is essentially how data is represented in order
	Two types of network queues, Set and Command

	<A>["Lmao"]<B>|"Testing"
	<b><A>|"Lmaooo"
	<A><("Lol")>|"Lmaoo"
	<B><(<B>)>|"LmAA"
	<C><(<(true or false)>)>|"AAAAAA"
	Set = {
		VariableChain = {
			{
				ReferenceName = 'A';
				EndPoints = {'<', '>'};
			};
			{
				ReferenceName = 'Lmao';
				EndPoints = {'[', ']'};
			};
			{
				ReferenceName = 'B';
				EndPoints = {'<', '>'};
			};
		}; or
		VariableChain = {
			{
				ReferenceName = 'A';
				EndPoints = {'<', '>'};
			};
			{
				ReferenceName = 'Lmao';
				EndPoints = {'(', ')'}; ok this is really fucking weird
			};
			{
				ReferenceName = 'B';
				EndPoints = {'<', '>'};
			};
		}; or
		Action = 'Defining';
		ValueChain = {

		};
	};
]]
Service.Bytes = function(self, str)
    local byte = newproxy(true);
    local meta = getmetatable(byte);
    local bytearray = {};
	local bytestack = {};
	
	local NetworkQueue = {};
    for i = 1, str:len() do
        local byte = string.byte(str:sub(i, i));
        if (bytestack[byte] == nil) then
            bytestack[byte] = {};
        end;
        bytestack[byte][#bytestack[byte] + 1] = i;
        bytearray[#bytearray + 1] = byte;
    end;
    local FindFirstByte = function(char)
        local byte = string.byte(char);
        if (bytestack[byte] ~= nil) then
            return bytestack[byte][1];
        end;
	end;
	local GetAllOfBytes = function(char)
		local byte = string.byte(char);
        if (bytestack[byte] ~= nil) then
            return bytestack[byte];
        end;
	end;
	local FindAllNonchainingSequencesByEndpoints = function(e1, e2)
		local FirstEndpointOccurences = GetAllOfBytes(e1);
		local SecondEndpointOccurences = GetAllOfBytes(e2);
		local Sequences = {};
		if (FirstEndpointOccurences == SecondEndpointOccurences) then
			return FirstEndpointOccurences[1];
		end;
		for i = 1, #FirstEndpointOccurences do
			local Pos = FirstEndpointOccurences[i];
			for i2 = 1, #SecondEndpointOccurences  do
				local SecondPos = SecondEndpointOccurences[i2];
				if (Pos <= SecondPos) then
					for i = Pos, SecondPos do
						local byte = bytearray[i];
						if (byte ~= string.byte('<') and byte ~= string.byte('>') and byte ~= string.byte('(') and byte ~= string.byte('(') and i ~= Pos and i ~= SecondPos) then
							--here we're looking at the inner content and
						elseif (byte == string.byte('<') or byte == string.byte('>') or byte == string.byte('(') or byte == string.byte(')')) then
							if (i ~= Pos and i ~= SecondPos) then
								break;
							end;
						end;
						if (i == SecondPos) then --at the end here
							--we have to check that this isnt in a multiline string tho
							--wow we actually made it to the end without references
							Sequences[#Sequences + 1] = {Pos, SecondPos};
						end;
					end;
				--[[else
					break;]]
				end;
			end;
		end;
		return Sequences;
	end;

	local FindNonchainingSequenceByEndpoints = function(e1, e2)
		--meaning only true values will be evaluated in here
		--what if <"<a>">
		local FirstEndpointOccurences = GetAllOfBytes(e1);
		local SecondEndpointOccurences = GetAllOfBytes(e2);
		if (FirstEndpointOccurences == SecondEndpointOccurences) then
			return FirstEndpointOccurences[1];
		end;
		for i = 1, #FirstEndpointOccurences do
			local Pos = FirstEndpointOccurences[i];
			for i2 = 1, #SecondEndpointOccurences  do
				local SecondPos = SecondEndpointOccurences[i2];
				if (Pos <= SecondPos) then
					for i = Pos, SecondPos do
						local byte = bytearray[i];
						if (byte ~= string.byte('<') and byte ~= string.byte('>') and byte ~= string.byte('(') and byte ~= string.byte('(') and i ~= Pos and i ~= SecondPos) then
							--here we're looking at the inner content and
						elseif (byte == string.byte('<') or byte == string.byte('>') or byte == string.byte('(') or byte == string.byte(')')) then
							if (i ~= Pos and i ~= SecondPos) then
								break;
							end;
						end;
						if (i == SecondPos) then --at the end here
							--we have to check that this isnt in a multiline string tho
							--wow we actually made it to the end without references
							
							return Pos, SecondPos;
						end;
					end;
				--[[else
					break;]]
				end;
			end;
		end;
	end;

	local FindSequenceBeyondEndpoints = function(pos1, pos2, e1, e2)
		local firstExterior = (function()
			for i = 1, pos1 do
				local currentChar = bytearray[pos1 - (i - 1)];
				--print("A", pos1 - (i - 1));
				if (currentChar == string.byte(e1) and i ~= 1) then
					return pos1 - (i - 1);
				end;
			end;
		end)();
		local secondExterior = (function()
			--print(pos2);
			for i = pos2, #bytearray do
				local currentChar = bytearray[pos2 + (i - pos2)];
				--print("B", pos2 + (i - pos2));  --+ (i - 1));
				if (currentChar == string.byte(e2) and i ~= 1) then
					return pos2 + (i - pos2);
				end;
			end;
		end)();
		return firstExterior, secondExterior;
	end;

	local FindEntireSequence = function(seq)
		local firstChar = seq:sub(1, 1);
		local ByteOccurences = GetAllOfBytes(firstChar);
		if (ByteOccurences ~= nil) then
			for i = 1, #ByteOccurences do
				local Index = ByteOccurences[i]; --string position
				if (Index <= #bytearray) then --max string pos
					for i = 1, seq:len() do
						local currentCharInString = seq:sub(i, i);
						if (bytearray[Index + (i - 1)] == string.byte(currentCharInString)) then
							if (i == seq:len()) then
								return Index, Index + (i - 1);
							end;
						end;
					end;
				end;
			end;
		end;
	end;
    local GetAllBytes = function()
        return bytearray;
    end;
    meta.__index = function(self, index)
        if (index == 'FindFirstByte') then
            return FindFirstByte;
        elseif (index == 'GetAllBytes') then
			return GetAllBytes;
		elseif (index == 'FindEntireSequence') then
			return FindEntireSequence;
		elseif (index == 'FindNonchainingSequenceByEndpoints') then
			return FindNonchainingSequenceByEndpoints;
		elseif (index == 'FindAllNonchainingSequencesByEndpoints') then
			return FindAllNonchainingSequencesByEndpoints;
		elseif (index == 'FindSequenceBeyondEndpoints') then
			return FindSequenceBeyondEndpoints;
        end;
    end;
    meta.__newindex = function(self, index, value)
        return nil;
    end;
    meta.__tostring = function(self)
        local str = {};
        for i = 1, #bytearray do
            str[#str + 1] = string.char(bytearray[i]);
        end;
        return table.concat(str, '');
    end;
    meta.__metatable = 'Byte';
    return byte;
end;

Service.Converter.StringToBytecodeArray = function(self, str)
    local BytecodeArray = {};
    for i = 1, str:len() do
        local character = str:sub(i, i);
        BytecodeArray[i] = string.byte(character);
    end;
    return BytecodeArray;
end;

Service.Converter.BytecodeArrayToString = function(self, arr)
    local String = {};
    for i = 1, #arr do
        String[i] = string.char(arr[i]);
    end;
    return table.concat(String, '');
end;

Service.Editor.ReplicateArray = function(self, arr)
    local n_arr = {};
    for i, v in next, arr do
        n_arr[i] = v;
    end;
    return n_arr;
end;

Service.Editor.FindNext = function(self, arr, keyletter, initial, includeInitial)
    local index;
    for i = (function() 
        if (initial ~= nil and includeInitial == false) then
            return initial + 1;
        elseif (initial ~= nil and includeInitial == nil) then
            return initial + 1;
        end;
        return initial;
    end)() or 1, #arr do
        if (arr[i] == string.byte(keyletter)) then
            index = i;
            break;
        end;
    end;
    return index;
end;

Service.Editor.IdentifyChunkType = function(self, x, y)
    local isReference = x == '<' and y == '>';
    local isExecution = x == '[' and y == ']';
    local isContainer = x == '{' and y == '}';
    local isDefining = x == '|' and y == '|';
    local isSeperator = x == '\\' and y == '\\';
    local chunkData = {
        Type = 'N/A';
    };
    if (isReference == true) then
        chunkData.Type = 'Reference';
    elseif (isExecution == true) then
        chunkData.Type = 'Execution';
    elseif (isContainer == true) then
        chunkData.Type = 'Container';
    elseif (isDefining == true) then
        chunkData.Type = 'Definer';
    elseif (isSeperator == true) then
        chunkData.Type = 'Seperator';
    end;
    return chunkData.Type;
end;

Service.Editor.FindChunk = function(self, arr, x, y, includeContainers)
    local FirstIndex = Service.Editor:FindNext(arr, x);
    local SecondIndex = Service.Editor:FindNext(arr, y, FirstIndex, false);
    local VariableName = '';
    if (FirstIndex == nil or SecondIndex == nil) then
        return nil;
    end;
    for i = FirstIndex, SecondIndex do
        if (includeContainers == false or includeContainers == nil) then
            VariableName = VariableName..string.char(arr[i]);
        elseif (includeContainers == true) then
            if (i ~= FirstIndex and i ~= SecondIndex) then
                VariableName = VariableName..string.char(arr[i]);
            end;
        end;
    end;
    return {
        Name = VariableName;
        Initial = FirstIndex;
        Final = SecondIndex;
        Type = Service.Editor:IdentifyChunkType(x, y);
        x = x;
        y = y;
    };
end;

Service.Editor.FindWholeChunk = function(self, arr, word) --untested
    if (word:len() == 1) then
        for i = 1, #arr do
            if (arr[i] == string.byte(word)) then
                return {
                    Name = word;
                    Initial = i;
                    Final = i;
                    Type = Service.Editor:IdentifyChunkType(word, word);
                    x = '';
                    y = '';
                };
            end;
        end;
    end;
    return Service.Editor:FindChunk(arr, word:sub(1, 1), word:sub(word:len(), word:len()), true);
end;
--[[
    SEQ1 transfer +A
    REAL transfer <b>
    MACH 222222222
]]
Service.Editor.ChunkMatch = function(self, arr, seq, id)
    local sindex = 1;
    local seqbytes = Service.Converter:StringToBytecodeArray(seq);
    local Initial = nil;
    local Final = 1;
    local continuingChunk = false;
    local idChunks = {};
    local currentId = 0;
    local trueName = '';

    local acceptableForChunk = function(seqb, byte)
        print(tonumber(string.char(byte)))
        if (seqb == 0) then
            if (tostring(string.char(byte)) ~= nil) then
                return true;
            end;
        elseif (seqb == 1) then
            if (tonumber(string.char(byte)) ~= nil) then
                return true;
            end;
        elseif (seqb == -999) then
            if (byte == string.byte(';') or byte == string.byte(' ') or byte == string.byte('\n')) then
                return true;
            end;
        end;
        return false;
    end;

    for i = 1, #arr do
        print(sindex, #seqbytes, #arr);
        --[[if (sindex == #seqbytes) then --correct words
            Final = i;
            break;]]
            pcall(function()
       print("COMPARE", string.char(arr[i]), string.char(seqbytes[sindex]));end);
        warn('TRUE', trueName);
        if (arr[i] == seqbytes[sindex] and continuingChunk == false) then
            if (arr[i] == string.byte((id[currentId] or {id = '\\'}).id:sub(1, 1))) then
                print'outdated id?';
            end;
            warn("THIS GOD PASSED")
            if (Initial == nil) then
                Initial = i;
            end;
            if (#id == #idChunks) then
                Final = i;
            end;
            trueName = trueName..string.char(arr[i]);
            sindex = sindex + 1;
        else
            warn('id', currentId + 1, arr[i], continuingChunk)
            if (seqbytes[sindex] == string.byte('+') and acceptableForChunk(id[currentId + 1].acceptables, arr[i]) == true) then
                warn('lmao')
                sindex = sindex + 1;
                currentId = currentId + 1;
                trueName = trueName..string.char(arr[i]);
                idChunks[currentId] = {arr[i];};
                continuingChunk = true;
                print(id[currentId].acceptables)
                if (id[currentId].acceptables == -999) then --additonal spacials after this are just
                    if (arr[i] == string.byte(';') or arr[i] == string.byte(' ') or arr[i] == string.byte('\n') or arr[i + 1] == nil) then
                        warn('TRACKED HERE')
                        --trueName = trueName..string.char(arr[i]);
                        --idChunks[currentId][#idChunks[#idChunks] + 1] = arr[i];
                        continuingChunk = false;
                        Final = i;
                        sindex = sindex - 1;
                    end;
                end;
            elseif (continuingChunk == true) then
                if (id[currentId].acceptables == 0) then
                    if (id[currentId].utilizeEndpoints == true) then
                        if (arr[i] == string.byte(';') or arr[i] == string.byte(' ') or arr[i] == string.byte('\n') or arr[i + 1] == nil) then
                            idChunks[currentId][#idChunks[#idChunks] + 1] = arr[i];
                            continuingChunk = false;
                            Final = i;
                            trueName = trueName..string.char(arr[i]);
                            sindex = sindex + 1;
                        else
                            --warn("WE WERE LAST HERE", string.char(arr[i]), string.char(seqbytes[sindex]), string.char(seqbytes[sindex + 1]), #seqbytes, sindex + 1);
                            trueName = trueName..string.char(arr[i]);
                            idChunks[currentId][#idChunks[#idChunks] + 1] = arr[i];
                            if (arr[i + 1] == seqbytes[sindex + 1]) then
                                sindex = sindex + 1;
                            end;
                        end;
                    else
                        trueName = trueName..string.char(arr[i]);
                        idChunks[currentId][#idChunks[#idChunks] + 1] = arr[i];
                    end;
                elseif (id[currentId].acceptables == 1) then
                    if (id[currentId].utilizeEndpoints == true) then
                        if (arr[i] == string.byte(';') or arr[i] == string.byte(' ') or arr[i] == string.byte('\n') or arr[i + 1] == nil) then
                            idChunks[currentId][#idChunks[#idChunks] + 1] = arr[i];
                            continuingChunk = false;
                            Final = i;
                            trueName = trueName..string.char(arr[i]);
                            sindex = sindex + 1;
                        else
                            if (tonumber(string.char(arr[i])) ~= nil) then
                                trueName = trueName..string.char(arr[i]);
                                idChunks[currentId][#idChunks[#idChunks] + 1] = arr[i];
                            end;
                        end;
                    else
                        if (tonumber(string.char(arr[i])) ~= nil) then
                            trueName = trueName..string.char(arr[i]);
                            idChunks[currentId][#idChunks[#idChunks] + 1] = arr[i];
                        end;
                    end;
                end;
            else
                --sindex = 1;
            end;
        end;
    end;
    for i, v in next, idChunks do
        print'_____________________________';
        local a = {};
        for i = 1, #v do
            table.insert(a, string.char(v[i]));
        end;
        print(table.concat(a, ''));
        print'_____________________________';
    end;
    --table.foreach(idChunks[3], print);
    return {
        Name = trueName;
        GlobalInitial;
        GlobalFinal;
        LocalInitial = Initial;
        LocalFinal = Final;
        Type = 'N/A Match';
        x = string.char(arr[Initial]);
        y = string.char(arr[Final]);
    }
end;

Service.Editor.RemoveIndexChunk = function(self, arr, x, y, betweenOnly)
    for i = x, y do
        if (betweenOnly == false or betweenOnly == nil) then
            table.remove(arr, x);
        elseif (betweenOnly == true) then
            if (i ~= x and i ~= y) then
                table.remove(arr, x);
            end;
        end;
    end;
end;

Service.Editor.RemoveChunk = function(self, arr, x, y, betweenOnly)
    local FirstIndex = Service.Editor:FindNext(arr, x);
    local SecondIndex = Service.Editor:FindNext(arr, y, FirstIndex, false);
    if (FirstIndex == nil or SecondIndex == nil) then
        return nil;
    end;
    for i = FirstIndex, SecondIndex do
        if (betweenOnly == false or betweenOnly == nil) then
            table.remove(arr, FirstIndex);
        elseif (betweenOnly == true) then
            if (i ~= FirstIndex and i ~= SecondIndex) then
                table.remove(arr, FirstIndex);
            end;
        end;
    end;
end;

Service.Editor.StripVariablePhase = function(self, arr) --awesome it works, now the only issue is that it goes beyond the action phase which shouldn't happen
    --I think we should identify comments here lmao and ignore comments here
    local SafeCopy = Service.Editor:ReplicateArray(arr);

    --Index chaining, <a><b>, <a>["b"], \+transfer 3+\[]
    local FinishedSearching = false;
    local ReceivedChunks = {};
    local queryTimes = 0;
    local acceptedTimes = 0; --we need this to go in order to indexations.

    local FindFirstChunk = function()
        local IndexData = Service.Editor:FindChunk(SafeCopy, '<', '>', true);
        local ExecutionData = Service.Editor:FindChunk(SafeCopy, '[', ']', true);
        local SeperatorData = Service.Editor:FindChunk(SafeCopy, '\\', '\\', true);
        local ds = {0, 0, 0};
        if (SeperatorData ~= nil and queryTimes == 1) then
            ds[1] = 1;
        end;
        if (IndexData ~= nil) then
            ds[2] = 1;
        end;
        if (ExecutionData ~= nil) then
            ds[3] = 1;
        end;
        local priorityChunk = 0;
        local lowestInitial = math.huge;
        for i = 1, #ds do
            local status = ds[i];
            if (status == 1) then
                if (i == 1) then
                    if (SeperatorData ~= nil) then
                        if (SeperatorData.Initial < lowestInitial) then
                            lowestInitial = SeperatorData.Initial;
                            priorityChunk = 1;
                        end;
                    end;
                elseif (i == 2) then
                    if (IndexData ~= nil) then
                        if (IndexData.Initial < lowestInitial) then
                            lowestInitial = IndexData.Initial;
                            priorityChunk = 2;
                        end;
                    end;
                elseif (i == 3) then
                    if (ExecutionData ~= nil) then
                        if (ExecutionData.Initial < lowestInitial) then
                            lowestInitial = ExecutionData.Initial;
                            priorityChunk = 3;
                        end;
                    end;
                end;
            end;
        end;
        if (priorityChunk == 1) then
            Service.Editor:RemoveIndexChunk(SafeCopy, SeperatorData.Initial, SeperatorData.Final, false);
            return SeperatorData;
        elseif (priorityChunk == 2) then
            Service.Editor:RemoveIndexChunk(SafeCopy, IndexData.Initial, IndexData.Final, false);
            return IndexData;
        elseif (priorityChunk == 3) then
            Service.Editor:RemoveIndexChunk(SafeCopy, ExecutionData.Initial, ExecutionData.Final, false);
            return ExecutionData;
        end;
    end;

    repeat
        queryTimes = queryTimes + 1;
        local ChunkData = FindFirstChunk();
        if (ChunkData ~= nil) then
            acceptedTimes = acceptedTimes + 1;
            ReceivedChunks[acceptedTimes] = ChunkData;
        elseif (ChunkData == nil) then
            FinishedSearching = true;
            break;
        end;
    until
        FinishedSearching == true;
    for i, v in next, ReceivedChunks do
        print(i, v.x..v.Name..v.y);
    end;
    return ReceivedChunks;
end;

Service.Editor.StripActionPhase = function(self, arr)
     return Service.Editor:FindWholeChunk(arr, '|');
end;

Service.Editor.StripValuePhase = function(self, arr)

end;

Service.Editor.StripGeneralStatements = function(self, arr)
    local transferData = Service.Editor:ChunkMatch(arr, 'transfer +A', {
        {id = 'A', acceptables = 0, utilizeEndpoints = true};        
    });
    local breakData = Service.Editor:ChunkMatch(arr, 'break+A', {
        {id = 'A', acceptables = -999, utilizeEndpoints = false}
    });
    local ds = {0, 0};
    if (transferData ~= nil and transferData.Initial ~= nil) then
        ds[1] = 1;
    elseif (breakData ~= nil and transferData.Final ~= nil) then
        ds[2] = 1;
    end;
    local lowestInitial = math.huge;
    local priorityChunk = 0;
    for i = 1, #ds do
        if (ds[i] == 1) then
            if (i == 1) then
                if (transferData.Initial < lowestInitial) then
                    lowestInitial = transferData.Initial;
                    priorityChunk = 1;
                end;
            elseif (i == 2) then
                if (breakData.Initial < lowestInitial) then
                    lowestInitial = breakData.Initial;
                    priorityChunk = 2;
                end;
            end;
        end;
    end;
    if (priorityChunk == 1) then
        return transferData;
    elseif (priorityChunk == 2) then
        return breakData;
    end;
end;

Service.Editor.StripSpecificStatements = function(self, arr)

end;

--not super omega advanced lmao, big sad.

--[[fuck we need seperators
like [shit] so we can just stick variables in there

lmao[beeet] = 'lmao'
lmao.beeet = 'lmao'
we need to add seperators

How-to-code in Glutinity

> Variables
    (VariablePhase)(ActionPhase)(ValuePhase)
    All instances of setting variables work like this above
    Variables are referenced always using <(VariableName)> where (VariableName) is the name of the
        variable you want to reference.
        You're able to also apply indexation and chaining to the variable IF it's a table.
        Indexation: <Variable><Index>(Action)(Value)
        Chaining: <Variable>["Test"]<A>(Action)(Value)
        You cannot chain by itself, but you can apply chaining then indexation.

        --Seperators are not supported at all yet
        You can preset values using (Seperators), the only seperators that exist are parenthesis ().
        Indexation: <Variable><(<AnotherVariable>)>(Action)(Value)
        Chaining: <Variable>[(<AnotherVariable)]<A>(Action)(Value)
        where <AnotherVariable> is any value
    
        Lua version
        A.B = 'lol';
        A['lmao'].B = 'lol';
    You can choose what you want to do with the variable but you have to state what do you want to do.
        Currently (ActionPhase) describes this and the only phase it can be is <|>.
    
    The kinds of values you can set, there are A LOT.
    
    Value types:
        Strings - "(Content)", '(Content)'
        Multi-line Strings - *(Content)*
        Function statements - +(Content)+
        Containers - {(Content)}
        Numbers/Integers (Content)
        Booleans (Content)
    
    Operations:
        Addition - (Content) + (Content)
        Subtraction - (Content) - (Content)
        Multiplication - (Content) * (Content)
        Division - (Content) / (Content)
        Power - (Content) ^ (Content)
        Modulus - (Content) % (Content)

        Equalizing - (Content) || (Content)
        Inequalizing - (Content) !! (Content)
        Concatenation - (Content) . (Content)
        And -  (Content) and (Content)
        Or - (Content) or (Content)
        Is not - !(Content)
    
    Seperators:
        Infinity Seperator - ((Content))
    
    
> Sequencing and Transfering
    (SequencePhase)(Conditional)(SequencePhaseEnd)+(Function)+

    SequencePhase and SequencePhaseEnd should be the same.

    Sequence Phases:
        If statements - &(Conditional)&+(Function)+
        Else If statements - &(Conditional)&+(Function)+:&(Conditional)&+(Function)+
        Else statements - &(Conditional)&+(Function)+:-+(Function)+
        Number loops - %(Variable)(Action)(Value),(Conditional),(Function)%+(ToDoFunction)+
        Container loops - %(Variable),(Variable),(Container),(Filter)%+(Function)+
    
    Sequences above are considered to be "general" statements, because they are flexible.

    Transfer Phases:
        Return Variable - transfer (Variable)
        Break loop - break
    
    Transfers above are considered to be "strict" statements, they're not very flexible.
]]
local Source = [=[
	<A>["Lmao"]<B>|"Testing"
	<b><(A)><b>|"Lmaooo"
]=];
local ByteObj = Service:Bytes(Source);
local ReferenceA = ByteObj.FindFirstByte('<');
local BaseSeperators = ByteObj.FindAllNonchainingSequencesByEndpoints('(', ')');
local BaseReferences = ByteObj.FindAllNonchainingSequencesByEndpoints('<', '>');

local SeperatorData = BaseSeperators[1];
print(SeperatorData[1], SeperatorData[2])
local PureData = {ByteObj.FindSequenceBeyondEndpoints(SeperatorData[1], SeperatorData[2], '<', '>')};
table.foreach(PureData, print);
--[[
local Bytes = Service.Converter:StringToBytecodeArray(Source);
local ByteChunk = Service.Editor:ReplicateArray(Bytes);
local VariableData = Service.Editor:StripVariablePhase(ByteChunk); --variable phase has "chunks"
--the variable phase supports "chaining" lit. oh shit what about indexing
local ActionData = Service.Editor:StripActionPhase(ByteChunk); --no chunks, can only be a variable or so]]
--[[
table.foreach(ActionData, print);
print'______________________________';
table.foreach(VariableData[3], print);]]
--return Service;












