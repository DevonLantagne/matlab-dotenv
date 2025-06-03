classdef (Abstract) DotenvTestBase < matlab.unittest.TestCase
    % Superclass for all test groups.
    %
    % Handles:
    %   Temp .env file creation and deletion before and after tests.
    %   Dynamically adds dotenv.m to the MATLAB path.
    %   Contains logic for validating a .env line.
    %   User defines property "defaultArgs" to set default dotenv args.

    properties
        TempFileName
    end

    properties (Abstract, Access = protected)
        defaultArgs
    end

    properties (Constant, Access = protected)
        % You can override this in subclasses if needed
        DotenvRelativePath = fullfile('..');  % relative path from test file
    end

    methods (TestClassSetup)
        % Shared setup for the entire test class

        function addDotenvToPath(testCase)
            % Get the path of the subclass test file
            testClassFile = which(class(testCase));
            testDir = fileparts(testClassFile);

            % Resolve the dotenv path
            dotenvDir = fullfile(testDir, testCase.DotenvRelativePath);

            if exist(fullfile(dotenvDir, 'dotenv.m'), 'file')
                addpath(dotenvDir);
            else
                error('DotenvTestBase:MissingDotenv', ...
                      'Could not find dotenv.m in expected location: %s', dotenvDir);
            end
        end
    end

    methods (TestMethodSetup)
        % Setup for each test

        % Temp filename
        function createTempFile(testCase)
            testCase.TempFileName = [tempname, '.env'];
        end
    end

    methods (TestMethodTeardown)
        function deleteTempFile(testCase)
            if isfile(testCase.TempFileName)
                delete(testCase.TempFileName);
            end
        end
    end

    methods(Test)
        % Common test methods

    end

    methods (Access = protected)
        function verifyLine(testCase, line, expectedResults, dotenvArgs)
            arguments
                testCase
                line (1,:) string
                expectedResults (:,4) cell
                dotenvArgs (1,:) cell = {}
            end

            fid = fopen(testCase.TempFileName, "w");
            fprintf(fid, "%s\n", line); % can also write an array of lines (new line)
            fclose(fid);

            for rowData = expectedResults'
                mode = rowData{1};
                resultType = rowData{2};

                diagnostic_lines = sprintf("Line: %s\n", line);
                diagnostic = sprintf("Mode: %s\n%s\n", mode, diagnostic_lines);

                tempDotenvArgs = [{"Mode", mode}, testCase.defaultArgs(:)', dotenvArgs(:)'];

                if resultType == "value"
                    expectedKey = rowData{3};
                    expectedValue = rowData{4};
                    diagnostic = sprintf("%sExpected Key: (%s)\nExpected Value: (%s)\n", ...
                        diagnostic, ...
                        expectedKey, ...
                        expectedValue);
                    % Run function to get results
                    parsedEnv = dotenv(testCase.TempFileName, tempDotenvArgs{:});
                    % Unit tests will only look for the expected key=value.
                    testCase.verifyTrue(isfield(parsedEnv, expectedKey), ...
                        sprintf("%s%s\n", diagnostic, "Expected key not found."))
                    testCase.verifyEqual(parsedEnv.(expectedKey), expectedValue, ...
                        sprintf("%s%s\n", diagnostic, "Parsed value does not match expected."))

                elseif resultType == "error"
                    expectedErrorCode = rowData{3};
                    testCase.verifyError( ...
                        @() dotenv(testCase.TempFileName, tempDotenvArgs{:}), ...
                        expectedErrorCode, ...
                        sprintf("%s%s\n", diagnostic, "Expected an error to be thrown by dotenv.m"))

                elseif resultType == "empty"
                    parsedEnv = dotenv(testCase.TempFileName, tempDotenvArgs{:});

                    testCase.verifyEmpty(parsedEnv, ...
                        sprintf("%s%s\n", diagnostic, "Expected no parsed text"))

                end
            end
        end
    end
end