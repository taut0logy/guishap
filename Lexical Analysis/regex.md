# Guishap Language Regex Pattern Analysis

## Table of Contents
1. [Basic Pattern Elements](#basic-pattern-elements)
2. [Pattern Categories](#pattern-categories)
3. [Detailed Pattern Analysis](#detailed-pattern-analysis)

## Basic Pattern Elements

Before diving into specific patterns, let's understand the regex elements used:

| Symbol | Meaning |
|--------|----------|
| `[ ]` | Character class - matches any single character inside brackets |
| `[^ ]` | Negated character class - matches any character NOT inside brackets |
| `+` | One or more occurrences |
| `*` | Zero or more occurrences |
| `\t` | Tab character |
| `\n` | Newline character |
| `\[` | Literal left square bracket |
| `\]` | Literal right square bracket |
| `\"` | Literal double quote |

## Pattern Categories

### 1. Basic Patterns
```regex
[a-zA-Z]     # Matches any single letter (upper or lowercase)
[0-9]        # Matches any single digit
[_]          # Matches underscore
```

### 2. Combined Pattern Groups
```regex
[a-zA-Z0-9_] # Matches any letter, digit, or underscore
[ \t\n]      # Matches any whitespace character
```

## Detailed Pattern Analysis

### 1. Whitespace Pattern
```regex
[ \t\n]+
```
**Breakdown:**
- `[ \t\n]` - Character class containing:
  - Space character (` `)
  - Tab character (`\t`)
  - Newline character (`\n`)
- `+` - Matches one or more occurrences
**Matches:** Any sequence of spaces, tabs, or newlines
**Example matches:**
- "   " (three spaces)
- "\t\t" (two tabs)
- "\n  \t" (newline, two spaces, tab)

### 2. Identifier Pattern
```regex
[a-zA-Z][a-zA-Z0-9_]*
```
**Breakdown:**
- `[a-zA-Z]` - First character must be a letter
- `[a-zA-Z0-9_]*` - Followed by zero or more letters, digits, or underscores
**Matches:** Valid variable/function names without special prefixes
**Example matches:**
- "variable"
- "myVar123"
- "calculateSum"

### 3. Variable Declaration Pattern
```regex
"_"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+
```
**Breakdown:**
- `"_"` - Starts with single underscore
- `[a-zA-Z]` - Followed by a letter
- `[a-zA-Z0-9_]*` - Followed by zero or more letters, digits, or underscores
- `"%"` - Type separator
- `[a-zA-Z]+` - One or more letters for type name
**Example matches:**
- "_counter%int"
- "_name%string"
- "_value123%float"

### 4. Constant Declaration Pattern
```regex
"__"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+
```
**Breakdown:**
- `"__"` - Starts with double underscore
- Rest same as variable pattern
**Example matches:**
- "__MAX_VALUE%int"
- "__PI%float"
- "__NAME%string"

### 5. Array Declaration Pattern
```regex
"_"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+"\[\]"
```
**Breakdown:**
- Same as variable pattern
- `"\[\]"` - Ends with literal brackets
**Example matches:**
- "_numbers%int[]"
- "_names%string[]"
- "_values%float[]"

### 6. Collection Definition Pattern
```regex
"col"[ \t]+[A-Z][a-zA-Z0-9_]*[ \t]*[{]
```
**Breakdown:**
- `"col"` - Literal "col" keyword
- `[ \t]+` - One or more whitespace characters
- `[A-Z]` - Must start with uppercase letter
- `[a-zA-Z0-9_]*` - Followed by zero or more letters, digits, or underscores
- `[ \t]*` - Zero or more whitespace characters
- `[{]` - Opening brace
**Example matches:**
- "col Student {"
- "col UserData   {"
- "col BankAccount{"

### 7. Number Pattern
```regex
[0-9]+(\.[0-9]+)?
```
**Breakdown:**
- `[0-9]+` - One or more digits
- `(\.[0-9]+)?` - Optional decimal part:
  - `\.` - Literal decimal point
  - `[0-9]+` - One or more digits
  - `?` - Makes the entire decimal part optional
**Example matches:**
- "42"
- "3.14"
- "0.123"

### 8. String Literal Pattern
```regex
\"[^\"]*\"
```
**Breakdown:**
- `\"` - Opening quote
- `[^\"]*` - Zero or more non-quote characters
- `\"` - Closing quote
**Example matches:**
- `"Hello, World!"`
- `"123"`
- `""`

### 9. Block Comment Pattern
```regex
"##"[^#]*"##"
```
**Breakdown:**
- `"##"` - Opening double hash
- `[^#]*` - Zero or more non-hash characters
- `"##"` - Closing double hash
**Example matches:**
```
## This is a comment ##
## Multiple
   lines
   allowed ##
```

### 10. Line Comment Pattern
```regex
"#"[^\n]*
```
**Breakdown:**
- `"#"` - Opening hash
- `[^\n]*` - Zero or more non-newline characters
**Example matches:**
- "# This is a comment"
- "# Another comment"

### 11. Member Access Pattern
```regex
"."[a-zA-Z][a-zA-Z0-9_]*
```
**Breakdown:**
- `"."` - Literal dot
- `[a-zA-Z]` - Letter
- `[a-zA-Z0-9_]*` - Zero or more letters, digits, or underscores
**Example matches:**
- ".name"
- ".age"
- ".getValue"

### 12. Function Declaration Pattern
```regex
"shap"[ \t]+[a-zA-Z][a-zA-Z0-9_]*
```
**Breakdown:**
- `"shap"` - Function keyword
- `[ \t]+` - One or more whitespace characters
- `[a-zA-Z]` - First letter of function name
- `[a-zA-Z0-9_]*` - Rest of function name
**Example matches:**
- "shap calculate"
- "shap process123"
- "shap getValue"

### 13. Loop Patterns
```regex
"loop"[ \t]+"till"
"loop"[ \t]+"for"
```
**Breakdown:**
- `"loop"` - Loop keyword
- `[ \t]+` - One or more whitespace characters
- `"till"|"for"` - Loop type keyword
**Example matches:**
- "loop till"
- "loop for"

### Usage Notes

1. **Order Matters**: In the flex file, patterns are matched in order of appearance. More specific patterns should come before general ones.

2. **Whitespace Handling**: Most patterns explicitly handle whitespace where required, making the syntax somewhat rigid but unambiguous.

3. **Case Sensitivity**: The language is case-sensitive, with specific rules for when uppercase/lowercase should be used.

4. **Special Characters**: Most special characters ([], {}, ., ") are either escaped or handled in character classes to avoid regex interpretation.

Would you like me to expand on any of these patterns or provide more examples?