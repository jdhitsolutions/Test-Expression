# Test-Expression

THIS COMMANDS IN THIS MODULE HAVE BEEN INTEGRATED INTO THE [PSSCRIPTTOOLS](https://github.com/jdhitsolutions/PSScriptTools) MODULE.

This PowerShell module includes a primary command that will test a PowerShell expression or scriptblock for a specified number of times and calculate the average runtime, in milliseconds, over all the tests. 

## Why?
When you run a single test with `Measure-Command` the result might be affected by any number of factors. Likewise, running multiple tests may also be influenced by things such as caching. The goal in this module is to provide a test framework where you can run a test repeatedly with either a static or random interval between each test. The results are aggregated and analyzed. Hopefully, this will provide a more meaningful or realistic result.


    
## Examples
The output will also show the median and trimmed values as well as some metadata about the current PowerShell session.

```
PS C:\> $cred = Get-credential globomantics\administrator
PS C:\> Test-Expression {param($cred) get-wmiobject win32_logicaldisk -computer chi-dc01 -credential $cred } -argumentList $cred
   
Tests        : 1
TestInterval : 0.5
AverageMS    : 1990.6779
MinimumMS    : 1990.6779
MaximumMS    : 1990.6779
MedianMS     : 1990.6779
TrimmedMS    : 
PSVersion    : 5.1.14409.1005
OS           : Microsoft Windows 8.1 Enterprise
``` 
You can also run multiple tests with random time intervals.

```
PS C:\>Test-expression {param([string[]]$Names) get-service $names} -count 5 -IncludeExpression -argumentlist @('bits','wuauserv','winrm') -RandomMinimum .5 -RandomMaximum 5.5

Tests        : 5
TestInterval : Random
AverageMS    : 1.91406
MinimumMS    : 0.4657
MaximumMS    : 7.5746
MedianMS     : 0.4806
TrimmedMS    : 0.51
PSVersion    : 5.1.14409.1005
OS           : Microsoft Windows 8.1 Enterprise
Expression   : param([string[]]$Names) get-service $names
Arguments    : {bits, wuauserv, winrm}
```

For very long running tests, you can run them as a background job.

## Graphical Testing
The module also includes a graphical command called `Test-ExpressionForm`. This is intended to serve as both an entry and results form.

![Test Expression](images/testexpressionform.png)

When you quit the form the last result will be written to the pipeline including all metadata, the scriptblock and any arguments.

## Known Issues
There are no known issues at this time. Please use the Issues section of this repository to report any problems and enhancement requests.

_Last Updated: 25 September 2018_