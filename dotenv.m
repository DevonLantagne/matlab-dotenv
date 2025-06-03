function env = dotenv(filenames, opts)
% Reads a .env file similar to POSIX shells (bash) and Python dotenv and returns a MATLAB structure.
% Use optional flags to control parsing style.
%
% Differences between this dotenv.m and other parsers:
%   - Does not support single quote keys, all keys must be valid MATLAB
%     variable names.
%   - Does not support line's starting with the "export" directive
%
% Input:
%   filename (required)
%       The filename(s) of the .env file you want to load. If you want to
%       load multiple files, filename should be a string vector.
%   Mode (optional, name/value, default="python")
%       The .env standard you want to parse.
%       - "python" is the most widely adopted and most forgiving. If you
%         are only using your .env for MATLAB, use "python" mode. Visit
%         https://pypi.org/project/python-dotenv/. Note, there are
%         limitations with this implementation.
%       - "bash" is used in operating system environments
%       - "raw" will not perform any unique parsing or handling of escape
%         characters. Assumes '=' separator.
%   CoerceTypes (optional, name/value, default=true)
%       Will attempt to cast all values out of strings into double/NaN,
%       boolean, or keep as strings.
%   FixKeys (optional, name/value, defalut="underscore")
%       If a key name is valid in the mode it is operating in, but cannot
%       be supported in MATLAB, how should MATLAB fix the key name? Throws
%       a warning when encountered.
%   FixKeysPrefix (optional, name/value, default="x")
%       Only effective when FixKeys is not "none". MATLAB will append a
%       string (defined by FixKeysPrefix) to fix a key name (like a key 
%       starting with a number).
%
%
% Output:
%   env - a structure with fields for each variable name and values. By
%   default, all values are strings. It is up to the application to recast
%   variables into their expected types.
%
% Examples:
%
%   env = dotenv(".env"); % loads the .env file with all values being
%                         % strings.
%
% By Devon Lantagne
%
% TODO:
%   Python Parser:
%       - Support multiline values without \n

arguments
    filenames (1,:) string
    opts.Mode (1,1) string {mustBeMember(opts.Mode, ["python","bash","raw"])} = "python"
    opts.CoerceTypes (1,1) logical = true
    opts.FixKeys (1,1) string {mustBeMember(opts.FixKeys, ["none", "underscore", "hex", "delete"])} = "underscore"
    opts.FixKeysPrefix (1,1) string {mustBeValidVariableName} = "x"
end

env = []; % init var (returns empty if no variables in file)

% For each filename provided
for filename = filenames

    % Guard for bad files
    if ~isfile(filename)
        error('dotenv:FileNotFound', ...
            '.env file not found: %s', filename);
    end

    % Read all data in the file
    % Maintain empty lines for error reporting
    filetext = readlines(filename);

    % Separator - Python can use = or : as the separator; but only the
    % first separator will be used for the whole config file. Default to =
    % for all Modes
    if opts.Mode == "python"
        separator = '';
    end

    % For each line:
    for LineNum = 1:length(filetext)

        % Processes regardless of Mode
        ThisLine = filetext(LineNum); % read lines as string array
        % If empty or a comment line
        if (strlength(strtrim(ThisLine))==0) || startsWith(ThisLine, "#")
            continue
        end

        % Parse depending on the Mode
        try
            switch opts.Mode
                case "bash"
                    [key, remainder] = BashKeyValExtract(ThisLine);
                    value = ParseBash(remainder, env);
                case "python"
                    [key, remainder, separator] = PythonKeyValExtract(ThisLine, separator);
                    value = PythonParse(remainder, env);
                case "raw"
                    % Do nothing, let the app figure it out.
                    % Will trim whitespace on key
                    key = strtrim(extractBefore(ThisLine, "="));
                    if ismissing(key)
                        % Throwing warnings for \U escape in sprintf ????
                        % This needs a major fix since MATLAB is escaping
                        % our test sequences, so we need to escape the
                        % escapes.
                        % TODO
                        error('dotenv:raw:NoSeparator', ...
                            filename + ": Line " + LineNum + ": " + ThisLine + newline + ...
                            "Could not find '=' separator.");
                    end
                    % Be nice and strip quotes around the key (if any)
                    if startsWith(key, """") || startsWith(key, "'")
                        key = extractBetweenQuotes(key, false);
                    end
                    value = extractAfter(ThisLine, "=");
                    
            end
        catch ME
            causeException = MException('dotenv:ParseError', ...
                filename + ": Line " + LineNum + ": " + ThisLine);
                %sprintf("%s: Line %d: %s", filename, LineNum, ThisLine));
            ME = addCause(ME, causeException);
            rethrow(ME)
        end

        % Validate field name (must be valid matlab syntax)
        if ~isvarname(key)
            if opts.FixKeys == "none"
                error('dotenv:InvalidKeyName', ...
                    "%s: Line %d: %s\n%s", filename, LineNum, ThisLine, ...
                    "Invalid variable name");
            end
            % Otherwise we have permission to fix the key name
            OldKey = key;
            key = matlab.lang.makeValidName(OldKey, ...
                "ReplacementStyle", opts.FixKeys, ...
                "Prefix", opts.FixKeysPrefix);
            warning("dotenv:FixedKey", "Replaced old key (%s) with new key (%s)", OldKey, key)
        end

        env.(key) = value; % Store KEY=VALUE in struct
    end
end

% Handle type coercsion at the end (makes var sub easier as strings)
if opts.CoerceTypes
    env = CoerceTypes(env);
end

end


%% Python 

% Key/Value Extractor
function [key, remainder, separator] = PythonKeyValExtract(ThisLine, separator)
% Python can use = or : for assignment, but only the first one is
% used and must be used for all variables. If separator is empty,
% we must determine the standard for this file.
%
% Python dotenv never allows quoted Keys, does not allow hyphens

if isempty(separator)
    equalIdx = strfind(ThisLine, "=");
    if isempty(equalIdx); equalIdx = inf; end

    colonIdx = strfind(ThisLine, ":");
    if isempty(colonIdx); colonIdx = inf; end

    FirstSepIndex = min(equalIdx(1), colonIdx(1));
    if FirstSepIndex == inf
        error('dotenv:python:InvalidSeparator', ...
            'Line %d malformed: no "=" or ":" found. Line was:\n%s', ...
            0, ThisLine);
    end

    separator = extract(ThisLine, FirstSepIndex);
end

% Find the first separator char and split (key=value)
splitIdx = strfind(ThisLine, separator);
if isempty(splitIdx)
    error('dotenv:python:NoSeparator', ...
        'Line %d malformed: no %c found. Line was:\n%s', ...
        0, separator, ThisLine);
end
splitIdx = splitIdx(1); % only consider the first separator char

% Check if we don't have a key name
if splitIdx == 1
    error('dotenv:python:EmptyKey', ...
        'Line %d malformed: empty variable name. Line was:\n%s', ...
        0, ThisLine);
end

% Extract the key as the text before the separator
key = extractBefore(ThisLine, separator);
key = strtrim(key);

% even if bash's export directive is present, strip it
if startsWith(key, "export "); key = strtrim(extractAfter(key, "export ")); end

% Validate the key is compatible with python (use regexp)
isNotValidPythonKey = isempty(regexp(key, '^[A-Za-z_][A-Za-z0-9_]*$', 'once'));
if isNotValidPythonKey
    error('dotenv:python:KeySyntax', ...
        "Invalid key syntax, illegal character(s).\nLine was:\n%s\nKey was:\n%s", ...
        ThisLine, key);
end

% Extract the value "remainder" as all the text after the =
remainder = strtrim( extractAfter(ThisLine, splitIdx) );
end


% Parse Python Values
function val = PythonParse(remainder, env)
% "remainder" is string scalar (stripped) after the separator
% "env" is a struct of previously parsed key=values

% First check if this is an empty var
if strlength(remainder)==0
    val = "";
    return
end

% Handle behavior based on first char (quote or non-quote)
switch extract(remainder, 1)
    case '"' % Double quote (allows escaping)
        
        % Extract text between double quotes (can escape quotes)
        val = extractBetweenQuotes(remainder, true);

        % Unescape characters
        val = strrep(val, '\n', newline);
        val = strrep(val, '\r', char(13));
        val = strrep(val, '\t', char(9));
        val = strrep(val, '\b', char(8));
        val = strrep(val, '\f', char(12));
        val = strrep(val, '\v', char(11));
        val = strrep(val, '\a', char(7));
        val = strrep(val, '\0', char(0));
        val = strrep(val, '\"', '"');
        val = strrep(val, '\''','''');
        val = strrep(val, '\\', '\'); % always do last

        % Perform variable substitution: ${VAR}
        val = VarExpansion(val, env);


    case '''' % Single quote (literal)

        % Extract text between single quotes. User can escape a single
        % quote
        val = extractBetweenQuotes(remainder, true);

        % Unescape characters
        % Can only escape single quote and backslash
        val = strrep(val, '\''', "'");
        val = strrep(val, '\\', '\'); % always do last

        % No variable expansion


    otherwise % Unquoted Raw value
        % Remove comment test if any.
        % Needs whitespace before comment, otherwise literal
        if contains(remainder, ' #')
            val = extractBefore(remainder, ' #');
        else
            val = remainder;
        end
        
        % Perform variable substitution: ${VAR}
        val = VarExpansion(val, env);


end % end switch

end % end function ParsePython


%% Bash 

% Key/Value Extractor
function [key, remainder] = BashKeyValExtract(ThisLine)
% Bash only uses the '=' separator. Cannot have any spaces around the key.
% Whitespace after = is preserved.

% Find the first separator char and split (key=value)
splitIdx = strfind(ThisLine, '=');
if isempty(splitIdx)
    error('dotenv:bash:NoSeparator', ...
        "Line %d malformed: no '=' found. Line was:\n%s", ...
        0, ThisLine);
end
splitIdx = splitIdx(1); % only consider the first separator char

% Check if we don't have a key name
if splitIdx == 1
    error('dotenv:bash:EmptyKey', ...
        'Line %d malformed: empty variable name. Line was:\n%s', ...
        0, ThisLine);
end


% Extract the key as the text before the separator
key = extractBefore(ThisLine, '=');

% bash allows the "export" directive before a key=value pair, strip it
% always
if startsWith(key, "export "); key = extractAfter(key, "export "); end

% Cannot have whitespaces around key
if contains(key," ")
    error('dotenv:bash:KeyWhiteSpace', ...
        "Line %d malformed: Cannot have whitespace around key. Line was:\n%s", ...
        0, ThisLine);
end
% Validate the key is compatible with bash (use regexp)
isNotValidBashKey = isempty(regexp(key, '^[a-zA-Z_][a-zA-Z0-9_]*$', 'once'));
if isNotValidBashKey
    error('dotenv:bash:KeySyntax', ...
        "Invalid key syntax, illegal character(s). Line was:\n%s Key was:\n%s", ...
        ThisLine, key);
end

% Extract the value "remainder" as all the text after the =
remainder = extractAfter(ThisLine, splitIdx);

end


% Parse Bash Values
function val = ParseBash(remainder, env)
% Bash does not allow spaces around the KEY.
% Leading whitespace in the value is literal

% First check if this is an empty var
if strlength(remainder)==0
    val = "";
    return
end

% Handle behavior based on first char (quote or non-quote)
switch extract(remainder, 1)
    case '"' % Double quote (allows escaping)

        % Extract text between double quotes (can escape quotes)
        val = extractBetweenQuotes(remainder, true);

        % Unescape characters
        val = strrep(val, '\n', newline);
        val = strrep(val, '\r', char(13));
        val = strrep(val, '\t', char(9));
        val = strrep(val, '\b', char(8));
        val = strrep(val, '\f', char(12));
        val = strrep(val, '\v', char(11));
        val = strrep(val, '\a', char(7));
        val = strrep(val, '\0', char(0));
        val = strrep(val, '\"', '"');
        val = strrep(val, '\''','''');
        val = strrep(val, '\\', '\'); % always do last

        % Perform variable substitution: ${VAR}
        val = VarExpansion(val, env);


    case '''' % Single quote (strict literal)
        % Only get the first two single quotes and get the text between as
        % is.
        val = extractBetweenQuotes(remainder, false);

        % No escape characters

        % No variable expansion

    otherwise
        % Literal (including leading whitespace)
        if contains(remainder, ' #')
            val = extractBefore(remainder, ' #');
        else
            val = remainder;
        end

        if contains(val, " ")
            error("dotenv:bash:UnquotedSpace",...
                "Cannot have spaces in an unquoted value. Raw value was:\n%s", val)
        end

        % Perform variable substitution: ${VAR}
        val = VarExpansion(val, env);

end
end


%% Variable Expansion
function val = VarExpansion(val, env)
% Perform variable substitution, ${VAR}, in the string.
% Can have multiple matches
matches = regexp(val, '\$\{([^}]+)\}', 'tokens');
for k = 1:numel(matches)
    varname = matches{k}{1};
    if isfield(env, varname)
        val = strrep(val, ['${' varname '}'], env.(varname));
    else
        error('dotenv:helper:UndefinedKey', ...
            'Undefined variable, %s, for substitution.', ...
            varname);
    end
end
end


%% FindQuotes Helper Function
function val = extractBetweenQuotes(val, AllowEscaping)
    % Extracts text between quotes (ignores # outside after).
    % Assumes there is no leading whitespace.
    % val is a string scalar of quoted text that might have a # comment at the end.
    % AllowEscaping is boolean that allows escaping chars after \

    % Determine quote type
    quoteType = extract(val, 1);
    % Temp replace all escaped quotes with spaces
    if AllowEscaping
        RealQuoteVal = replace(val, "\" + quoteType, "  ");
    else
        RealQuoteVal = val;
    end

    % Find all the unescaped quotes; the first two are the valid
    % quotes. If there are more, they should be after a comment.
    quoteIdx = strfind(RealQuoteVal, quoteType);

    % Remove any candidates after a comment (if any)
    commentIdx = strfind(RealQuoteVal, "#");
    if isempty(commentIdx); commentIdx = inf; end

    % delete quotes after a #
    quoteIdx(quoteIdx > commentIdx) = []; 

    % Must have at least two quotes now
    if length(quoteIdx) < 2
        error('dotenv:helper:UnclosedQuotes', ...
            "Unclosed quotes")
    end
    if length(quoteIdx) > 2
        error('dotenv:helper:OddQuotes', ...
            "Malformed line, odd number of unescaped quotes.")
    end

    % Good indeces, extract
    val = extractBetween(val, quoteIdx(1)+1, quoteIdx(2)-1);
end


%% CoerceTypes Helper Function
function env = CoerceTypes(env)
for thisField = string(fields(env))'
    val = env.(thisField);

    valLower = lower(val);
    if valLower == "true" || valLower == "yes"
        val = true;
    elseif valLower == "false" || valLower == "no"
        val = false;
    elseif valLower == "null" || valLower == "none"
        val = [];
    elseif valLower == "nan"
        val = NaN;
    elseif ~isnan(str2double(val)) && ~isempty(val)
        val = str2double(val);
    end

    env.(thisField) = val;
end

end