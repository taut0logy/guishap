# Guishap Programming Language Documentation

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
11. [Best Practices](#best-practices)
12. [Examples](#examples)

## Introduction

Guishap is a statically-typed programming language designed with readability and explicit type declarations in mind. Its distinctive feature is the use of underscores and percentage signs in variable declarations, making type information immediately visible in the code.

## Language Features

### Key Characteristics

- Statically typed
- Explicit type declarations
- Collection-based custom types
- Multiple loop constructs
- Case-based pattern matching
- Clear variable/constant distinction
- Built-in array support
- Member access notation

## Syntax and Conventions

### Naming Conventions

- Variables start with single underscore: `_variableName`
- Constants start with double underscore: `__CONSTANT_NAME`
- Collections start with uppercase: `CollectionName`
- Functions use camelCase: `functionName`

### Type Declaration Syntax

```guishap
_variableName%type
__CONSTANT_NAME%type
_arrayName%type[]
```

## Data Types

### Basic Types

```guishap
int     # Integer values
float   # Floating-point numbers
bool    # Boolean values
char    # Single characters
string  # Text strings
```

### Array Types

```guishap
_numbers%int[]      # Integer array
_names%string[]    # String array
_values%float[]    # Float array
```

## Variables and Constants

### Variable Declaration

```guishap
_age%int:25;
_name%string:"John";
_grades%float[]:[85.5, 90.0, 88.5];
```

### Constant Declaration

```guishap
__PI%float:3.14159;
__MAX_STUDENTS%int:100;
__APP_NAME%string:"Guishap App";
```

### Variable Assignment

```guishap
counter:0;        # Assignment uses colon
total:sum/2;     # Can use expressions
```

## Collections

### Defining Collections

```guishap
col Student {
    _name%string,
    _age%int,
    _grades%float[]
};
```

### Using Collections

```guishap
_student%Student:{
    _name:"Alice",
    _age:20,
    _grades:[95.0, 88.5, 92.0]
};
```

### Member Access

```guishap
_studentName:student.name;
_studentGrades:student.grades;
```

## Control Flow

### If-Elif-Else Statements

```guishap
if [score >= 90] {
    grade:"A";
} elif [score >= 80] {
    grade:"B";
} else {
    grade:"C";
}
```

### Case Statements

```guishap
case [value] {
    [1]: result:"One";
    [2]: result:"Two";
    []: result:"Other";  # Default case
}
```

### Loops

#### Till Loop (Condition-based)

```guishap
loop till [_counter < 10] {
    sum:_sum + counter;
    counter:counter + 1;
}
```

#### For Loop (Range-based)

```guishap
loop _i%int for [0..5..1] {    # start..end..step
    total:total + array[i];
}
```

### Loop Control

```guishap
break;      # Exit loop
continue;   # Skip to next iteration
```

## Functions

### Function Declaration

```guishap
shap calculateAverage (_numbers%float[])>float {
    _sum%float:0.0;
    loop _i%int for [0.._length..1] {
        sum:sum + numbers[i];
    }
    ret sum/length;
}
```

### Function Return

```guishap
ret value;     # Return value
```

## Operators

### Arithmetic Operators

```guishap
+    # Addition
-    # Subtraction
*    # Multiplication
/    # Division
%    # Modulo
^    # Power
```

### Comparison Operators

```guishap
>    # Greater than
<    # Less than
>=   # Greater than or equal
<=   # Less than or equal
!=   # Not equal
==   # Equal
```

### Bitwise Operators

```guishap
&    # Bitwise AND
|    # Bitwise OR
~    # Bitwise NOT
```

### Range Operator

```guishap
..   # Range operator (used in loops)
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
