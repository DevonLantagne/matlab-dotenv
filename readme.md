# MATLAB dotenv.m
The `dotenv.m` function imports .env files from either bash or python-style .env syntax.

Currently under heavy development (including readme.md) as not all features of bash source or python dotenv are implemented. Currently, the parser is good enough for most common tasks that one would expect when using MATLAB.

## Features
- Parses a .env into a MATLAB structure array
- Can adjust key names to be MATLAB compatible (on your terms)
- Can parse raw key=value text
- Can parse .env files like bash's "source"
- Can parse .env files similar to the Python dotenv library
- Supports single-pass variable expansion (currently only ${} syntax)

## Installation

### Manual from GitHub via browser
Download the `dotenv.m` file to your MATLAB path. Consider downloading the `readme.md` as well.

### Download Script
Download the `download_dotenv.m` script and place it where you want to download the `dotenv` repo. The script creates a folder `dotenv` in the current working directory and downloads `dotenv.m` and `readme.md` from this repo.

## Inputs/Outputs

### Required Inputs
The following arguments are positional and required:
- `filename`: the name of the .env file (or path if not in current folder). Can be a string array - will merge all variables together into one structure and only the most recent key will be used if duplicates exist.

### Optional Inputs
The following arguments are name,value pairs and are all optional. However, setting the `Mode` is often good to make explicit.
- `Mode` (string, default = "python"): The rules to follow when parsing the .env file. Can be one of:
  - `"python"` Parses like the [Python dotenv library](https://pypi.org/project/python-dotenv/)
  - `"bash"` Parses like bash source
  - `"raw"` Parses raw text
- `CoerceTypes` (logical, default = true): If the output values should be cast to their appropriate type (double/nan, logical, string).
- `FixKeys` (string, default = "underscore"): If a key name is valid in the mode it is operating in, but cannot be supported in MATLAB, how should MATLAB fix the key name? Throws a warning when encountered. Can be one of:
  - `"none"` A key name that is valid in Python or bash that isn't valid in MATLAB will throw an error.
  - `"underscore"` Replcaces invalid MATLAB variable name characters with _
  - `"hex"` Replcaces invalid MATLAB variable name characters with their hex codes
  - `"delete"` Deletes invalid MATLAB variable name characters
- `FixKeysPrefix` (string, default = "x"): Only effective when FixKeys is not "none". MATLAB will append a string (defined by FixKeysPrefix) to fix a key name (like a key starting with a number). This would happen if you tried to set a key name starting with a number or underscore

### Output
- `struct`: a structure with fields for each variable name and values. The `CoerceTypes` argument determines if the values are strings or typed.

### Example Usage
`"Mode", "python"` Parse similar to Python dotenv.\
`"CoerceTypes", true` Detect variable types and cast them to MATLAB datatypes.\
`"FixKeys", "underscore"` If output struct fieldnames are not standard MATLAB variable names, try to fix them with an underscore.
```matlab
env = dotenv(".env", "Mode", "python", "CoerceTypes", true, "FixKeys", "underscore");
```

## Example .env Syntax
Below are valid and invalid syntax for the respective operating modes. 

### Valid Python

Assignment can be done with = or : but must be consistent within the .env file.
```env
MYVAR: 123
```
```env
MYVAR = 123
```

Very forgiving with spaces around keys, separators, and values.
```env
VAR_1 = 123
VAR_2=123
VAR_3:123
VAR_4: 123
VAR_5 : 123
```

Can add `#` for comments, both as its own line and after an assignment. Inline comments need a space before the #
```env
MY_VAR = 1234 # a comment
```



