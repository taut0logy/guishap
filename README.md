# Guishap Programming Language Documentation

## Developed by

**Raufun Ahsan**

*Khulna University of Engineering & Technology*

Roll: 2007030

Session: 2020-2021

## Table of Contents

1. [Introduction](#introduction)
2. [Language Features](#language-features)
3. [Parser Features](#parser-features)
4. [Syntax and Conventions](#syntax-and-conventions)
5. [Data Types](#data-types)
6. [Variables and Constants](#variables-and-constants)
7. [Collections](#collections)
8. [Control Flow](#control-flow)
9. [Functions](#functions)
10. [Operators](#operators)
11. [Best Practices](#best-practices)
12. [Examples](#examples)

## Introduction

Guishap is a statically-typed programming language designed with readability and explicit type declarations in mind. Its distinctive feature is the use of underscores and percentage signs in variable declarations, making type information immediately visible in the code.

## Language Features

### Key Characteristics

- Statically typed with explicit type declarations
- Strong type checking with limited type conversion (only between int and float)
- Collection-based custom types
- Multiple loop constructs (till and for)
- Case-based pattern matching
- Clear variable/constant distinction
- Built-in array support with type checking
- Member access notation
- Function parameters with type validation
- Mandatory main function with int return type
- Scope-based symbol management
- Comprehensive error reporting

## Parser Features

### Lexical Analysis

- Recognition of all language keywords and operators
- Support for numeric literals (integers and floats)
- String literal handling with proper escaping
- Identifier validation according to naming conventions
- Line number tracking for error reporting
- Comment handling and removal

### Syntax Analysis

- Complete grammar validation
- Type checking and validation
  - Basic type compatibility
  - Array type checking
  - Collection member type checking
  - Function parameter type checking
  - Return type validation
- Scope management
  - Symbol table maintenance
  - Scope-based symbol visibility
  - Temporary symbol cleanup
- Error Detection and Reporting
  - Syntax errors
  - Type mismatch errors
  - Undefined symbol errors
  - Duplicate symbol errors
  - Invalid array access errors
  - Function call errors
  - Return type mismatch errors

### Symbol Management

- Symbol table for variables and constants
- Function table for tracking function definitions
- Collection table for user-defined types
- Scope-based symbol visibility
- Support for temporary symbols (function parameters)

### Type System

- Basic type validation
- Array type checking
- Collection type checking
- Type compatibility checking
- Type conversion rules enforcement

### Error Handling

- Detailed error messages with line numbers
- Context-aware error reporting
- Type mismatch detection
- Symbol redefinition detection
- Invalid operation detection
- Array bounds checking
- Function parameter validation

### Output Generation

- Structured output to file (output.txt)
- Detailed logging of:
  - Declarations
  - Assignments
  - Operations
  - Function calls
  - Control flow
  - Scope changes
  - Collection access
  - Array access
- Compilation statistics

## Syntax and Conventions

### Naming Conventions

- Variables start with single underscore: `_variableName`
- Constants start with double underscore: `__CONSTANT_NAME`
- Collections start with uppercase: `CollectionName`
- Function names use camelCase: `functionName`

### Type Declaration Syntax

```guishap
_variableName%type              # Variable declaration
__CONSTANT_NAME%type           # Constant declaration
_arrayName%type[]             # Array declaration
```

## Data Types

### Basic Types

```guishap
int     # Integer values
float   # Floating-point numbers
string  # Text strings
bool    # Boolean values
void    # Used for functions with no return value
```

### Array Types

```guishap
_numbers%int[]      # Integer array
_names%string[]    # String array
_values%float[]    # Float array
```

### Type Compatibility

- Implicit conversion allowed between int and float
- No other implicit type conversions
- Array types must match exactly
- Collection types must match by name

## Variables and Constants

### Variable Declaration and Initialization

```guishap
# Declaration only
_age%int;
_name%string;

# Declaration with initialization
_age%int:25;
_name%string:"John";

# Array declaration with initialization
_grades%float[]:[85.5, 90.0, 88.5];
```

### Constant Declaration

Constants must be initialized at declaration:

```guishap
__PI%float:3.14159;
__MAX_STUDENTS%int:100;
__APP_NAME%string:"Guishap App";
```

### Assignment

```guishap
_counter:0;        # Assignment uses colon
_total:_sum/2;     # Can use expressions
_grades[0]:95.5;   # Array element assignment
```

## Collections

### Defining Collections

Collections are user-defined types that group related data:

```guishap
col Student {
    _name%string,
    _age%int,
    _grades%float[]
};
```

### Using Collections

```guishap
# Declare a collection variable
_student%Student;

# Assign values to members
_student._name:"John Doe";
_student._age:20;
_student._grades:[85.5, 90.0, 88.5];
```

### Member Access

```guishap
_name:_student._name;        # Access a member
_grade:_student._grades[0];  # Access array member
```

## Control Flow

### If-Elif-Else Statements

Conditions must be enclosed in square brackets:

```guishap
if [_score >= 90.0] {
    _grade:"A";
} elif [_score >= 80.0] {
    _grade:"B";
} else {
    _grade:"C";
}
```

### Case Statements

```guishap
case [_score] {
    [90.0] {
        ret "A";
    }
    [80.0] {
        ret "B";
    }
    [] {                # Default case
        ret "F";
    }
}
```

### Loops

#### Till Loop (While-style)

```guishap
_i%int:0;
loop till [_i < 5] {
    _sum:_sum + _scores[_i];
    _i:_i + 1;
}
```

#### For Loop (Range-based)

```guishap
loop _i%int for [0..5..1] {    # [start..end..step]
    _sum:_sum + _scores[_i];
}
```

### Loop Control

```guishap
break;      # Exit loop
continue;   # Skip to next iteration
```

## Functions

### Function Declaration

Functions are declared using the `shap` keyword:

```guishap
shap functionName (parameters)>returnType {
    # Function body
}
```

### Function Parameters

```guishap
# Regular parameter
shap print (_message%string)>void {
    # Function body
}

# Array parameter
shap calcAvg (_grades%float[])>float {
    # Function body
}

# Multiple parameters
shap addStudent (_name%string, _age%int, _grades%float[])>void {
    # Function body
}
```

### Function Return

```guishap
ret value;     # Return a value
ret;          # Return from void function
```

### Main Function

```guishap
shap main ()>int {
    # Program entry point
    ret 0;
}
```

## Operators

### Arithmetic Operators

```guishap
+    # Addition
-    # Subtraction
*    # Multiplication
/    # Division
%    # Modulo (integers only)
```

### Comparison Operators

```guishap
==   # Equal to
!=   # Not equal to
<    # Less than
>    # Greater than
<=   # Less than or equal to
>=   # Greater than or equal to
```

### Logical Operators

```guishap
&&   # Logical AND
||   # Logical OR
!    # Logical NOT
```

### Bitwise Operators

```guishap
&    # Bitwise AND (integers only)
|    # Bitwise OR (integers only)
^    # Bitwise XOR (integers only)
~    # Bitwise NOT (integers only)
```

## Best Practices

1. **Naming Conventions**
   - Use descriptive variable names
   - Keep consistent with underscore prefixes
   - Use uppercase for collections

2. **Type Safety**
   - Always declare types explicitly
   - Use appropriate data types
   - Consider using collections for complex data

3. **Code Organization**
   - Group related functions together
   - Define collections at the top of the file
   - Keep functions focused and single-purpose

4. **Comments**
   - Document complex logic
   - Explain non-obvious decisions
   - Use block comments for function documentation

## Examples

### Basic Calculator

```guishap
shap add (_a%float, _b%float)>float {
    ret a + b;
}

shap subtract (_a%float, _b%float)>float {
    ret a - b;
}

shap multiply (_a%float, _b%float)>float {
    ret a * b;
}

shap divide (_a%float, _b%float)>float {
    if [b == 0] {
        ret 0.0;  # Error case
    }
    ret a / b;
}
```

### Student Grade Management

```guishap
col Student {
    _name%string,
    _grades%float[],
    _average%float
};

shap calculateGrade (_grades%float[])>string {
    _avg%float:0.0;
    loop _i%int for [0..len(grades)..1] {
        avg:avg + grades[i];
    }
    avg:avg / len(grades);
    
    case [avg] {
        [90.0]: ret "A";
        [80.0]: ret "B";
        [70.0]: ret "C";
        [60.0]: ret "D";
        []: ret "F";
    }
}
```

### Array Processing

```guishap
shap findMax (_numbers%int[])>int {
    _max%int:numbers[0];
    loop _i%int for [1..len(numbers)..1] {
        if [numbers[i] > _max] {
            max:numbers[i];
        }
    }
    ret max;
}
```
