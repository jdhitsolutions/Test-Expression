# Test-Expression
    
## SYNOPSIS
Test a PowerShell expression for performance
    
## SYNTAX
    Test-Expression [-Expression] <ScriptBlock> [-ArgumentList <Object[]>] [-Count <Int32>] [-Interval <Double>] [-IncludeScriptblock] [-AsJob] [<CommonParameters>]    
    Test-Expression [-Expression] <ScriptBlock> [-ArgumentList <Object[]>] [-Count <Int32>] [-IncludeExpression] [-AsJob] -RandomMinimum <Double> -RandomMaximum <Double> [<CommonParameters>]

## DESCRIPTION
This command will test a PowerShell expression or scriptblock for a specified number of times and calculate the average runtime, in milliseconds, over all the tests. 
The output will also show the median and trimmed values. The median is calculated by sorting the values in ascending order and selecting the value in the center of the array. If the array has an even number of elements then the median is the average of the two values in the center.
The trimmed value will toss out the lowest and highest values and average the remaining values. This may be the most accurate indication as it will eliminate any small values which might come from caching and any large values which may come a temporary shortage of resources. You will only get a value if you run more than 1 test.
    
## EXAMPLES
    
_-------------------------- EXAMPLE 1 --------------------------_

    PS C:\>$cred = Get-credential globomantics\administrator
    PS C:\> Test-Expression {param($cred) get-wmiobject win32_logicaldisk -computer chi-dc01 -credential $cred } -argumentList $cred
       
    Tests        : 1
    TestInterval : 0.5
    AverageMS    : 1990.6779
    MinimumMS    : 1990.6779
    MaximumMS    : 1990.6779
    MedianMS     : 1990.6779
    TrimmedMS    : 
    
Test a command once passing an argument to the scriptblock.
       
_-------------------------- EXAMPLE 2 --------------------------_
    
    PS C:\>$sb = {1..1000 | foreach {$_*2}}
    PS C:\> test-expression $sb -count 10 -interval 2
    
    Tests        : 10
    TestInterval : 2
    AverageMS    : 79.16527
    MinimumMS    : 26.1216
    MaximumMS    : 105.8981
    MedianMS     : 82.7215
    TrimmedMS    : 82.454125
    
    
    PS C:\> $sb2 = { foreach ($i in (1..1000)) {$_*2}}
    PS C:\> test-expression $sb2 -Count 10 -interval 2
    
    Tests        : 10
    TestInterval : 2
    AverageMS    : 5.55528
    MinimumMS    : 1.7893
    MaximumMS    : 24.7843
    MedianMS     : 1.959
    TrimmedMS    : 3.6224
    
These examples are testing two different approaches that yield the same results over a span of 10 test runs, pausing for 2 seconds between each test. The values for Average, Minimum and Maximum are in milliseconds.
    
_-------------------------- EXAMPLE 3 --------------------------_
    
    PS C:\>Test-expression {get-service bits,wuauserv,spooler} -count 5 -IncludeScriptblock
    
    
    Tests        : 5
    TestInterval : 0.5
    AverageMS    : 5.01026
    MinimumMS    : 3.0295
    MaximumMS    : 11.3456
    MedianMS     : 3.6397
    TrimmedMS    : 3.55873333333333
    Expression   : get-service bits,wuauserv,spooler
    
Include the tested expression in the output.
    

_Last Updated: September 7, 2016_