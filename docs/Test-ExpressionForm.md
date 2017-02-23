---
external help file: Test-Expression-help.xml
online version: 
schema: 2.0.0
---

# Test-ExpressionForm

## SYNOPSIS
Display a graphical test form.
## SYNTAX

```
Test-ExpressionForm
```

## DESCRIPTION
This command will display a WPF-based form that you can use to enter in testing information. Testing intervals are in seconds. All of the values are then passed to the Test-Expression command. Results will be displayed in the form.

When you close the form, the last result object will be passed to the pipeline, including all metadata, the scriptblock and arguments.
## EXAMPLES

### Example 1
```
PS C:\> test-expressionform
```

Launch the form.
## PARAMETERS

## INPUTS

### None

## OUTPUTS

### System.Object

## NOTES
Learn more about PowerShell: http://jdhitsolutions.com/blog/essential-powershell-resources/

## RELATED LINKS
[Online Version:](https://github.com/jdhitsolutions/Test-Expression/blob/master/docs/Test-ExpressionForm.md)

[Test-Expression]()

