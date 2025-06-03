classdef template_test_class < DotenvTestBase
    
    properties (Access = protected)
        % defaultArgs - Default name/value list of args for dotenv.m
        defaultArgs = {"CoerceTypes", false, "FixKeys", "underscore"}
    end
    
    methods (Test)
        % Test methods
        
        % epxectedResult is a cell array where each row is the data:
        % {mode, resultType, expectedKey/errorType, expectedValue/[]}
        % If resultType is "value", then expect a Key and Value.
        % If resultType is "error", then expect an error message in the
        %   expectedKey column. Ignore last column.
        % If resultType is "empty", then expect no key=value pair but a good parse

        
        
    end
    
end