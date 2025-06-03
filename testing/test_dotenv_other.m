classdef test_dotenv_other < DotenvTestBase

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

        function testSimpleTrailingComment(testCase)
            line = 'MY_VAR=abc # this is a comment';
            expectedResults = {
                "python", "value", "MY_VAR", "abc";
                "bash",   "value", "MY_VAR", "abc";
                "raw",    "value", "MY_VAR", "abc # this is a comment";
                };
            testCase.verifyLine(line, expectedResults)
        end


        function testLineComment(testCase)
            line = "# Line Comment";
            expectedResults = {
                "python", "empty", [], [];
                "bash",   "empty", [], [];
                "raw",    "empty", [], [];
                };
            testCase.verifyLine(line, expectedResults)
        end


        function testEmptyLines(testCase)
            line = "";
            expectedResults = {
                "python", "empty", [], [];
                "bash",   "empty", [], [];
                "raw",    "empty", [], [];
                };
            testCase.verifyLine(line, expectedResults)
        end


        function testWhiteSpaceLines(testCase)
            line = "    ";
            expectedResults = {
                "python", "empty", [], [];
                "bash",   "empty", [], [];
                "raw",    "empty", [], [];
                };
            testCase.verifyLine(line, expectedResults)
        end


        function testEscapedDollarSignBash(testCase)
            line = "MY_VAR=\\$HOME";
            expectedResults = {
                "python", "value", "MY_VAR", "\\$HOME";
                "bash",   "value", "MY_VAR", "$HOME";
                "raw",    "value", "MY_VAR", "\\$HOME";
                };
            testCase.verifyLine(line, expectedResults)
        end


        function testEscapedNewlineBashStyle(testCase)
            line = "MY_VAR=hello\\nworld";
            expectedResults = {
                "python", "value", "MY_VAR", "hello\\nworld";
                "bash",   "value", "MY_VAR", "hello\\nworld";
                "raw",    "value", "MY_VAR", "hello\\nworld";
                };
            testCase.verifyLine(line, expectedResults)
        end


        function testNoValue(testCase)
            line = "MY_VAL=";
            expectedResults = {
                "python", "value", "MY_VAL", "";
                "bash",   "value", "MY_VAL", "";
                "raw",    "value", "MY_VAL", "";
                };
            testCase.verifyLine(line, expectedResults)
        end

        function testSubstitutionDollarBraceDoubleQuotes(testCase)
            line = ["VAL_1=123", "VAL_2=""${VAL_1}456"""];
            expectedResults = {
                "python", "value", "VAL_2", "123456";
                "bash",   "value", "VAL_2", "123456";
                "raw",    "value", "VAL_2", """${VAL_1}456""";
                };
            testCase.verifyLine(line, expectedResults)
        end


        function testSubstitutionDollarBraceSingleQuotes(testCase)
            line = ["VAL_1=123", "VAL_2='${VAL_1}456'"];
            expectedResults = {
                "python", "value", "VAL_2", "${VAL_1}456";
                "bash",   "value", "VAL_2", "${VAL_1}456";
                "raw",    "value", "VAL_2", "'${VAL_1}456'";
                };
            testCase.verifyLine(line, expectedResults)
        end


        function testSubstitutionDollarBraceNoQuotes(testCase)
            line = ["VAL_1=123", "VAL_2=${VAL_1}456"];
            expectedResults = {
                "python", "value", "VAL_2", "123456";
                "bash",   "value", "VAL_2", "123456";
                "raw",    "value", "VAL_2", "${VAL_1}456";
                };
            testCase.verifyLine(line, expectedResults)
        end

    end

end