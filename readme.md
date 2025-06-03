# MATLAB dotenv.m
The `dotenv.m` function imports .env files from either bash or python-style .env syntax.

Currently under heavy development (including readme.md) as not all features of bash source or python dotenv are implemented. Currently, the parser is good enough for most common tasks that one would expect when using MATLAB.

## Features
- Parses a .env into a MATLAB structure array
- Can adjust key names to be MATLAB compatible (on your terms)
- Can parse raw key=value text
- Can parse .env files like bash's "source"
- Can parse .env files similar to the Python dotenv library

## Installation
Download the `dotenv.m` file to your MATLAB path.

## Inputs/Outputs

### Required Inputs
The following arguments are positional and required:
- `filename`: the name of the .env file (or path if not in current folder)

### Optional Inputs
The following arguments are name,value pairs and are all optional. However, setting the `Mode` is often good to make explicit.
- `Mode` (string, default = "python"): The rules to follow when parsing the .env file. Can be one of:
  - `"python"` Parses like the [Python dotenv library](https://pypi.org/project/python-dotenv/)
  - `"bash"` Parses like bash source
  - `"raw"` Parses raw text
- `CoerceTypes` (logical, default = true): If the output values should be cast to their appropriate type (double/nan, logical, string).
- `FixKeys` (string, default = "underscore"): If a key name is valid in the mode it is operating in, but cannot be supported in MATLAB, how should MATLAB fix the key name? Throws a warning when encountered.
- `FixKeysPrefix` (string, default = "x"): Only effective when FixKeys is not "none". MATLAB will append a string (defined by FixKeysPrefix) to fix a key name (like a key starting with a number).

### Output
- `struct`: a structure with fields for each variable name and values. The `CoerceTypes` argument determines if the values are strings or typed.

## Examples
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






