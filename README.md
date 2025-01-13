# Guishap Programming Language Documentation

## Developed by

**Raufun Ahsan**

*Khulna University of Engineering & Technology*

Roll: 2007030

Session: 2020-2021

## Table of Contents

1. [Introduction](#introduction)
2. [Language Features](#language-features)
3. [Syntax and Conventions](#syntax-and-conventions)
4. [Data Types](#data-types)
5. [Variables and Constants](#variables-and-constants)
6. [Collections](#collections)
7. [Control Flow](#control-flow)
8. [Functions](#functions)
9. [Operators](#operators)
10. [Comments](#comments)

## Introduction

Guishap is a statically-typed programming language designed with readability and explicit type declarations in mind. Its distinctive feature is the use of underscores and percentage signs in variable declarations, making type information immediately visible in the code.

## Language Features

### Key Characteristics

- Statically typed with explicit type declarations
- Collection-based custom types
- Multiple loop constructs (till and for)
- Case-based pattern matching
- Clear variable/constant distinction
- Built-in array support
- Member access notation
- Function parameters with default values

## Syntax and Conventions

### Naming Conventions

- Variables start with single underscore: `_variableName`
- Constants start with double underscore: `__CONSTANT_NAME`
- Collections start with uppercase: `CollectionName`

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

# Parameter with default value
shap greet (_name%string:"Guest")>void {
    # Function body
}
```

### Function Return

```guishap
ret value;     # Return a value
ret;          # Return from void function
```

## Operators

### Arithmetic Operators

```guishap
+    # Addition
-    # Subtraction
*    # Multiplication
/    # Division
%    # Modulo
```

### Comparison Operators

```guishap
>    # Greater than
<    # Less than
>=   # Greater than or equal
<=   # Less than or equal
==   # Equal
```

### Logical Operators

```guishap
&&   # Logical AND
||   # Logical OR
!    # Logical NOT
```

### Bitwise Operators

```guishap
&    # Bitwise AND
|    # Bitwise OR
^    # Bitwise XOR
~    # Bitwise NOT
```

### Range Operator

```guishap
..   # Range operator (used in for loops)
```

## Comments

### Line Comments

```guishap
# This is a single-line comment
```

### Block Comments

```guishap
##
This is a multi-line comment
It can span multiple lines
##
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
