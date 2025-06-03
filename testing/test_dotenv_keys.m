classdef test_dotenv_keys < DotenvTestBase

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

        function testSimpleAssignment(testCase)
            % Simple unquoted assignment
            line = "MY_VAR=1234";
            expectedResults = {
                "python", "value", "MY_VAR", "1234";
                "bash", "value", "MY_VAR", "1234";
                "raw", "value", "MY_VAR", "1234";
                };
            testCase.verifyLine(line, expectedResults)
        end


        function testColonAssignment(testCase)
            % Tests the unique python mode for detecting : separator
            line = "MY_VAR: 1234";
            expectedResults = {
                "python", "value", "MY_VAR", "1234";
                "bash", "error", 'dotenv:bash:NoSeparator', [];
                "raw", "error", 'dotenv:raw:NoSeparator', [];
                };
            testCase.verifyLine(line, expectedResults)
        end


        function testInvalidKeyNumber(testCase)
            % Python and bash keys should not start with numbers, but in
            % raw mode will use MATLAB's variable name correction
            line = "1INVALID=foo";
            args = {"FixKeysPrefix", "x"};
            expectedResults = {
                "python", "error", "dotenv:python:KeySyntax", [];
                "bash",   "error", "dotenv:bash:KeySyntax", [];
                "raw",    "value", "x1INVALID", "foo";
                };
            testCase.verifyLine(line, expectedResults, args)
        end


        function testBashExport(testCase)
            % Tests interpreting the bash "export" directive. Parser
            % removes the directive unless in raw mode.
            % Assuming FixKey is not "none", space is deleted regardless of FixKey
            line = "export MY_VAR=5";
            optArgs = {"FixKeys", "underscore"};
            expectedResults = {
                "python", "value", "MY_VAR", "5";
                "bash",   "value", "MY_VAR", "5";
                "raw",    "value", "exportMY_VAR", "5";
                };
            testCase.verifyLine(line, expectedResults, optArgs)
        end


        function testMissingSeparator(testCase)
            % Parsor errors if no equal sign (and : if python)
            line = "MY_VAR 1234";
            expectedResults = {
                "python", "error", "dotenv:python:InvalidSeparator", [];
                "bash",   "error", "dotenv:bash:NoSeparator", [];
                "raw",    "error", "dotenv:raw:NoSeparator", [];
                };
            testCase.verifyLine(line, expectedResults)
        end


        function testKeyWithHyphen(testCase)
            % Hyphens are not permitted, but in raw mode will use MATLAB's
            % variable name correction.
            line = "MY-VAR=hello";
            optArgs = {"FixKeys", "underscore"};
            expectedResults = {
                "python", "error", "dotenv:python:KeySyntax", [];
                "bash",   "error", "dotenv:bash:KeySyntax", [];
                "raw",    "value", "MY_VAR", "hello";
                };
            testCase.verifyLine(line, expectedResults, optArgs)
        end


        function testMultipleEquals(testCase)
            % Only the first equal sign is used (same for :)
            line = "MY_VAR=value=more";
            expectedResults = {
                "python", "value", "MY_VAR", "value=more";
                "bash",   "value", "MY_VAR", "value=more";
                "raw",    "value", "MY_VAR", "value=more";
                };
            testCase.verifyLine(line, expectedResults)
        end


        function testSeparatorWhitespaceNoQuotes(testCase)
            % Python is forgiving with whitespace, bash is not, raw is
            % literal.
            line = "MY_VAR    =    spaced";
            expectedResults = {
                "python", "value", "MY_VAR", "spaced";
                "bash",   "error", "dotenv:bash:KeyWhiteSpace", [];
                "raw",    "value", "MY_VAR", "    spaced";
                };
            testCase.verifyLine(line, expectedResults)
        end


        function testDoubleQuotedKey(testCase)
            % Parser does not want quoted keys but will strip them if in
            % raw mode.
            line = """MY_VAR""=1234";
            expectedResults = {
                "python", "error", "dotenv:python:KeySyntax", [];
                "bash",   "error", "dotenv:bash:KeySyntax", [];
                "raw",    "value", "MY_VAR", "1234";
                };
            testCase.verifyLine(line, expectedResults)
        end


        function testSingleQuotedKey(testCase)
            % Parser does not want quoted keys but will strip them if in
            % raw mode.
            line = "'MY_VAR'=1234";
            expectedResults = {
                "python", "error", "dotenv:python:KeySyntax", [];
                "bash",   "error", "dotenv:bash:KeySyntax", [];
                "raw",    "value", "MY_VAR", "1234";
                };
            testCase.verifyLine(line, expectedResults)
        end


        function testColonInDoubleQuotes(testCase)
            line = "MY_VAR=""a:b:c""";
            expectedResults = {
                "python", "value", "MY_VAR", "a:b:c";
                "bash",   "value", "MY_VAR", "a:b:c";
                "raw",    "value", "MY_VAR", """a:b:c""";
                };
            testCase.verifyLine(line, expectedResults)
        end

    end

end