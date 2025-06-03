classdef test_dotenv_quotes < DotenvTestBase

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

        function testDoubleQuoted(testCase)
            line = "MY_VAR=""hello""";
            expectedResults = {
                "python", "value", "MY_VAR", "hello";
                "bash",   "value", "MY_VAR", "hello";
                "raw",    "value", "MY_VAR", """hello""";
                };
            testCase.verifyLine(line, expectedResults)
        end
        function testSingleQuoted(testCase)
            line = "MY_VAR='hello'";
            expectedResults = {
                "python", "value", "MY_VAR", "hello";
                "bash",   "value", "MY_VAR", "hello";
                "raw",    "value", "MY_VAR", "'hello'";
                };
            testCase.verifyLine(line, expectedResults)
        end

        function testDoubleQuotedWithSpaces(testCase)
            line = "MY_VAR=""hello world""";
            expectedResults = {
                "python", "value", "MY_VAR", "hello world";
                "bash",   "value", "MY_VAR", "hello world";
                "raw",    "value", "MY_VAR", """hello world""";
                };
            testCase.verifyLine(line, expectedResults)
        end
        function testSingleQuotedWithSpaces(testCase)
            line = "MY_VAR='hello world'";
            expectedResults = {
                "python", "value", "MY_VAR", "hello world";
                "bash",   "value", "MY_VAR", "hello world";
                "raw",    "value", "MY_VAR", "'hello world'";
                };
            testCase.verifyLine(line, expectedResults)
        end


        % Tests the parser ignores # in quotes but not outside. Raw
        % takes everything.
        function testHashInDoubleQuote(testCase)
            line = "PASSWORD=""MyPass3#Word"" # password comment";
            expectedResults = {
                "python", "value", "PASSWORD", "MyPass3#Word";
                "bash",   "value", "PASSWORD", "MyPass3#Word";
                "raw",    "value", "PASSWORD", """MyPass3#Word"" # password comment";
                };
            testCase.verifyLine(line, expectedResults)
        end


        function testEscapedDoubleQuotesInsideDoubleQuotes(testCase)
            line = "MY_VAR=""This is a \""quoted\"" word""";
            expectedResults = {
                "python", "value", "MY_VAR", "This is a ""quoted"" word";
                "bash",   "value", "MY_VAR", "This is a ""quoted"" word";
                "raw",    "value", "MY_VAR", """This is a \""quoted\"" word""";
                };
            testCase.verifyLine(line, expectedResults)
        end
        function testEscapedDoubleQuotesInsideSingleQuotes(testCase)
            % Won't escape double quotes with literal single quotes
            line = "MY_VAR='This is a \""quoted\"" word'";
            expectedResults = {
                "python", "value", "MY_VAR", "This is a \""quoted\"" word";
                "bash",   "value", "MY_VAR", "This is a \""quoted\"" word";
                "raw",    "value", "MY_VAR", "'This is a \""quoted\"" word'";
                };
            testCase.verifyLine(line, expectedResults)
        end

        function testEscapedSingleQuotesInsideDoubleQuotes(testCase)
            line = "MY_VAR=""This is a \'quoted\' word""";
            expectedResults = {
                "python", "value", "MY_VAR", "This is a 'quoted' word";
                "bash",   "value", "MY_VAR", "This is a 'quoted' word";
                "raw",    "value", "MY_VAR", """This is a \'quoted\' word""";
                };
            testCase.verifyLine(line, expectedResults)
        end
        function testEscapedSingleQuotesInsideSingleQuotes(testCase)
            % Python escapes single quotes and backslashes but bash takes
            % everything literally. Nested single quotes in bash error.
            line = "MY_VAR='This is a \'quoted\' word'";
            expectedResults = {
                "python", "value", "MY_VAR", "This is a 'quoted' word";
                "bash",   "error", "dotenv:helper:OddQuotes", [];
                "raw",    "value", "MY_VAR", "'This is a \'quoted\' word'";
                };
            testCase.verifyLine(line, expectedResults)
        end

        function testUnterminatedDoubleQuote(testCase)
            line = "MY_VAR=""unclosed";
            expectedResults = {
                "python", "error", "dotenv:helper:UnclosedQuotes", [];
                "bash",   "error", "dotenv:helper:UnclosedQuotes", [];
                "raw",    "value", "MY_VAR", """unclosed";
                };
            testCase.verifyLine(line, expectedResults)
        end
        function testUnterminatedSingleQuote(testCase)
            line = "MY_VAR='unclosed";
            expectedResults = {
                "python", "error", "dotenv:helper:UnclosedQuotes", [];
                "bash",   "error", "dotenv:helper:UnclosedQuotes", [];
                "raw",    "value", "MY_VAR", "'unclosed";
                };
            testCase.verifyLine(line, expectedResults)
        end


        function testWindowsPathDoubleQuotes(testCase)
            line = "MY_DIR=""C:\\Users\\user\\Code Projects\\matlab-dotenv""";
            expectedResults = {
                "python", "value", "MY_DIR", "C:\Users\user\Code Projects\matlab-dotenv";
                "bash",   "value", "MY_DIR", "C:\Users\user\Code Projects\matlab-dotenv";
                "raw",    "value", "MY_DIR", """C:\\Users\\user\\Code Projects\\matlab-dotenv""";
                };
            testCase.verifyLine(line, expectedResults)
        end
        function testWindowsPathSingleQuotes(testCase)
            line = "MY_DIR='C:\\Users\\user\\Code Projects\\matlab-dotenv'";
            expectedResults = {
                "python", "value", "MY_DIR", "C:\Users\user\Code Projects\matlab-dotenv";
                "bash",   "value", "MY_DIR", "C:\\Users\\user\\Code Projects\\matlab-dotenv";
                "raw",    "value", "MY_DIR", "'C:\\Users\\user\\Code Projects\\matlab-dotenv'";
                };
            testCase.verifyLine(line, expectedResults)
        end
        function testWindowsPathNoQuotes(testCase)
            line = "MY_DIR=C:\Users\user\Code Projects\matlab-dotenv";
            expectedResults = {
                "python", "value", "MY_DIR", "C:\Users\user\Code Projects\matlab-dotenv";
                "bash",   "error", "dotenv:bash:UnquotedSpace", [];
                "raw",    "value", "MY_DIR", "C:\Users\user\Code Projects\matlab-dotenv";
                };
            testCase.verifyLine(line, expectedResults)
        end


        function testUnixPathDoubleQuotes(testCase)
            line = "MY_DIR=""/Users/user/Code Projects/matlab-dotenv""";
            expectedResults = {
                "python", "value", "MY_DIR", "/Users/user/Code Projects/matlab-dotenv";
                "bash",   "value", "MY_DIR", "/Users/user/Code Projects/matlab-dotenv";
                "raw",    "value", "MY_DIR", """/Users/user/Code Projects/matlab-dotenv""";
                };
            testCase.verifyLine(line, expectedResults)
        end
        function testUnixPathSingleQuotes(testCase)
            line = "MY_DIR='/Users/user/Code Projects/matlab-dotenv'";
            expectedResults = {
                "python", "value", "MY_DIR", "/Users/user/Code Projects/matlab-dotenv";
                "bash",   "value", "MY_DIR", "/Users/user/Code Projects/matlab-dotenv";
                "raw",    "value", "MY_DIR", "'/Users/user/Code Projects/matlab-dotenv'";
                };
            testCase.verifyLine(line, expectedResults)
        end
        function testUnixPathNoQuotes(testCase)
            line = "MY_DIR=/Users/user/Code Projects/matlab-dotenv";
            expectedResults = {
                "python", "value", "MY_DIR", "/Users/user/Code Projects/matlab-dotenv";
                "bash",   "error", "dotenv:bash:UnquotedSpace", [];
                "raw",    "value", "MY_DIR", "/Users/user/Code Projects/matlab-dotenv";
                };
            testCase.verifyLine(line, expectedResults)
        end
    end

end