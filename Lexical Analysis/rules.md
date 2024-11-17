# Guishap Language Lexical Rules Documentation

## Table of Contents

1. [Keywords and Types](#keywords-and-types)
2. [Collections](#collections)
3. [Variables and Constants](#variables-and-constants)
4. [Loops](#loops)
5. [Functions](#functions)
6. [Conditions](#conditions)
7. [Comments](#comments)
8. [Operators](#operators)
9. [Separators](#separators)
10. [Literals](#literals)
11. [Member Access](#member-access)
12. [Identifiers](#identifiers)

## Keywords and Types

```flex
"int"|"float"|"bool"|"char"|"string"
```
### Description

- Basic data types in Guishap
- Matched as keywords and counted in keyword counter
- Must be lowercase
- No whitespace allowed within type names

## Collections

```flex
"col"[ \t]+[A-Z][a-zA-Z0-9_]*[ \t]*[{]
```
### Description
- Defines a custom data structure
- Must start with keyword "col"
- Requires at least one whitespace after "col"
- Collection name must:
  - Start with uppercase letter
  - Can contain letters, numbers, and underscores
  - Cannot start with numbers or underscores
- Can have optional whitespace before opening brace
- Example: `col Student {`

## Variables and Constants
### Constants
```flex
"__"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+
```
#### Description
- Must start with double underscore "__"
- Followed by:
  - Letter as first character
  - Any number of letters, numbers, or underscores
- Type declaration with "%" followed by type name
- Example: `__MAX_VALUE%int`

### Variables
```flex
"_"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+
```
#### Description
- Must start with single underscore "_"
- Followed by:
  - Letter as first character
  - Any number of letters, numbers, or underscores
- Type declaration with "%" followed by type name
- Example: `_counter%int`

### Array Variables
```flex
"_"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+"\[\]"
```
#### Description
- Same as regular variables
- Ends with "[]" to indicate array type
- Example: `_scores%float[]`

## Loops
### Till Loop
```flex
"loop"[ \t]+"till"
```
#### Description
- Keyword "loop" followed by whitespace
- Keyword "till" indicates condition-based loop
- Must include condition in square brackets
- Example: `loop till [i < 10]`

### For Loop
```flex
"loop"[ \t]+"for"
```
#### Description
- Keyword "loop" followed by whitespace
- Keyword "for" indicates range-based loop
- Must include range in square brackets
- Example: `loop for [0..10..1]`

### Loop Control
```flex
"break"|"continue"
```
#### Description
- `break`: Exits the current loop
- `continue`: Skips to next iteration
- No arguments or conditions needed

## Functions
```flex
"shap"[ \t]+[a-zA-Z][a-zA-Z0-9_]*
```
### Description
- Keyword "shap" defines a function
- Function name must:
  - Start with letter
  - Can contain letters, numbers, underscores
- Return type specified after ">"
- Example: `shap calculateAverage (_nums%float[])>float`

### Return Statement
```flex
"ret"
```
#### Description
- Keyword "ret" returns value from function
- Must be followed by value or expression
- Example: `ret result;`

## Conditions
### If Statement
```flex
"if"[ \t]*"["
```
#### Description
- Keyword "if" followed by condition in brackets
- Can have optional whitespace before bracket
- Example: `if [x > 0]`

### Elif Statement
```flex
"elif"[ \t]*"["
```
#### Description
- Alternative condition after if
- Must include condition in brackets
- Example: `elif [x < 0]`

### Else Statement
```flex
"else"
```
#### Description
- Final alternative in conditional chain
- No condition required
- Example: `else {`

### Case Statement
```flex
"case"[ \t]*"["
```
#### Description
- Multiple condition matcher
- Value to match in brackets
- Cases defined with square brackets and colon
- Example:
```guishap
case [value] {
    [1]: action1;
    [2]: action2;
    []: defaultAction;
}
```

## Comments
### Block Comments
```flex
"##"[^#]*"##"
```
#### Description
- Starts with double hash "##"
- Can span multiple lines
- Ends with double hash "##"
- Cannot nest block comments
- Example:
```guishap
##
This is a block comment
It can span multiple lines
##
```

### Line Comments
```flex
"#"[^\n]*
```
#### Description
- Starts with single hash "#"
- Continues until end of line
- Cannot span multiple lines
- Example: `# This is a line comment`

## Operators
### Arithmetic Operators
```flex
"+"|"-"|"*"|"/"|"%"|"^"
```
#### Description
- `+`: Addition
- `-`: Subtraction
- `*`: Multiplication
- `/`: Division
- `%`: Modulo
- `^`: Power

### Comparison Operators
```flex
">="|"<="|"!="|"=="|">"|"<"
```
#### Description
- `>=`: Greater than or equal
- `<=`: Less than or equal
- `!=`: Not equal
- `==`: Equal
- `>`: Greater than
- `<`: Less than

### Bitwise Operators
```flex
"&"|"|"|"~"
```
#### Description
- `&`: Bitwise AND
- `|`: Bitwise OR
- `~`: Bitwise NOT

### Assignment Operator
```flex
":"
```
#### Description
- Used for value assignment
- Example: `_x:5`

### Range Operator
```flex
".."
```
#### Description
- Used in loops to define ranges
- Example: `0..10..1` (start..end..step)

## Separators
```flex
[{}(),\[\]]
```
### Description
- `{` and `}`: Block delimiters
- `(` and `)`: Function parameter groups
- `,`: List separator
- `[` and `]`: Array indexing, conditions

## Literals
### String Literals
```flex
\"[^\"]*\"
```
#### Description
- Text enclosed in double quotes
- Cannot contain unescaped quotes
- Example: `"Hello, World!"`

### Number Literals
```flex
[0-9]+(\.[0-9]+)?
```
#### Description
- Integer or floating-point numbers
- Optional decimal part
- Examples: `42`, `3.14`

## Member Access
```flex
"."[a-zA-Z][a-zA-Z0-9_]*
```
### Description
- Dot operator followed by member name
- Used to access collection members
- Example: `_student.name`

## Identifiers
```flex
[a-zA-Z][a-zA-Z0-9_]*
```
### Description
- Names for variables, functions, etc.
- Must start with letter
- Can contain letters, numbers, underscores
- Case-sensitive
- Cannot be keywords

## Whitespace
```flex
[ \t\n]+
```
### Description
- Spaces, tabs, and newlines
- Ignored by lexer except where required
- Used for readability

## Error Handling
```flex
.
```
### Description
- Catches any unmatched characters
- Helps identify lexical errors
- Reports unknown tokens for debugging