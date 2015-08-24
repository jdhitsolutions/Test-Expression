#requires -version 4.0

Function Test-Expression {

<#
.SYNOPSIS
Test a PowerShell expression.
.DESCRIPTION
This command will test a PowerShell expression or scriptblock for a specified number of times and calculate the average runtime, in milliseconds, over all the tests. 
The output will also show the median and trimmed values. The median is calculated by sorting the values in ascending order and selecting the value in the center of the array. If the array has an even number of elements then the median is the average of the two values in the center.
The trimmed value will toss out the lowest and highest values and average the remaining values. This may be the most accurate indication as it will eliminate any small values which might come from caching and any large values which may come a temporary shortage of resources. You will only get a value if you run more than 1 test.
.PARAMETER Expression
The scriptblock you want to test. This parameter has an alias of sb.
.PARAMETER ArgumentList
An array of parameters to pass to the scriptblock. Arguments are positional.
.PARAMETER Count
The number of times to test the scriptblock.
.PARAMETER Interval
How much time to sleep in seconds between each test. Maximum is 60. You may want to use a sleep interval to mitigate possible caching effects.
.PARAMETER IncludeExpression
Include the test scriptblock in the output.
.PARAMETER AsJob
Run the tests as a background job.
.EXAMPLE
PS C:\> $cred = Get-credential globomantics\administrator
PS C:\> $c = "chi-dc01","chi-dc04"
PS C:\> Test-Expression {param($computer,$cred) get-wmiobject win32_logicaldisk -computer $computer -credential $cred } -argumentList $c,$cred


Tests        : 1
TestInterval : 0.5
AverageMS    : 1990.6779
MinimumMS    : 1990.6779
MaximumMS    : 1990.6779
MedianMS     : 1990.6779
TrimmedMS    : 

Test a command once passing an argument to the scriptblock. There is no TrimmedMS value because there was only one test.

.EXAMPLE
PS C:\> $sb = {1..1000 | foreach {$_*2}}
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
.Example
PS C:\>  Test-expression {get-service bits,wuauserv,spooler} -count 5 -IncludeScriptblock 


Tests        : 5
TestInterval : 0.5
AverageMS    : 5.01026
MinimumMS    : 3.0295
MaximumMS    : 11.3456
MedianMS     : 3.6397
TrimmedMS    : 3.55873333333333
Expression   : get-service bits,wuauserv,spooler

Include the tested expression in the output.
.NOTES
NAME        :  Test-Expression
VERSION     :  2.0   
LAST UPDATED:  August 24, 2015
AUTHOR      :  Jeff Hicks (@JeffHicks)

Learn more about PowerShell:
http://jdhitsolutions.com/blog/essential-powershell-resources/

  ****************************************************************
  * DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED *
  * THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF   *
  * YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, *
  * DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING.             *
  ****************************************************************
.LINK
Measure-Command
Measure-Object
.INPUTS
None
.OUTPUTS
Custom measurement object
#>

[cmdletbinding()]
Param(
[Parameter(Position=0,Mandatory,HelpMessage="Enter a scriptblock to test")]
[Alias("sb")]
[scriptblock]$Expression,
[object[]]$ArgumentList,
[ValidateScript({$_ -ge 1})]
[int]$Count = 1,
[ValidateRange(0,60)]
[double]$Interval = .5,
[switch]$IncludeScriptblock,
[switch]$AsJob
)

Write-Verbose "Measuring expression:"
Write-Verbose ($Expression | Out-String)
write-Verbose "$Count time(s) with a sleep interval of $($interval*1000) milliseconds"
<#
define an internal scriptblock that can be used 
directly or used to create a background job
#>

$myScriptBlock = {
  
    $TestData = 1..$using:count | foreach -begin {
     <#
      PowerShell doesn't seem to like passing a scriptblock as an
      argument when using Invoke-Command. It appears to pass it as
      a string so I'm recreating it as a scriptblock here.
     #>
     $script:testblock = [scriptblock]::Create($using:Expression)
     
     } -process {
         #invoke the scriptblock with any arguments and measure
         Measure-Command -Expression { 
         Invoke-Command -ScriptBlock $script:testblock -ArgumentList @($using:ArgumentList)
     } -outvariable +out
     #pause to mitigate any caching effects
     Start-Sleep -Milliseconds ($using:Interval*1000)
    } 
   
    $TestResults = $TestData | 
    Measure-Object -Property TotalMilliseconds -Average -Maximum -Minimum |
    Select-Object -Property @{Name = "Tests";Expression={$_.Count}},
    @{Name = "TestInterval";Expression={$using:Interval}},
    @{Name = "AverageMS";Expression = {$_.Average}},
    @{Name = "MinimumMS";Expression = {$_.Minimum}},
    @{Name = "MaximumMS";Expression = {$_.Maximum}},
    @{Name = "MedianMS";Expression = {

    #sort the values to calculate the median and trimmed values
    $sort = $out.totalmilliseconds | sort

    #test if there are an even or odd number of elements
    if ( ($sort.count) %2) {
        #odd number
        #subtract 1 because arrays start counting at 0
        $sort[(($sort.count-1)/2) -as [int]]
    }
    else {
        #even number
        #get middle two numbers and their average
        ($sort[($sort.count/2)] + $sort[$sort.count/2+1])/2
    }        
    }},
    @{Name="TrimmedMS";Expression={
        #values must be sorted in ascending order
        $data = $out.totalmilliseconds | Sort
        #select elements from the second to next to last
        ($data[1..($data.count-2)] | Measure-Object -Average).Average
  
    }}     

    if ($using:IncludeScriptblock) {
        $TestResults | Add-Member -MemberType Noteproperty -Name Expression -Value $using:Expression -PassThru
    }
    else {
        $TestResults
    }

} #myScriptBlock 

#parameter hashtable to splat against Invoke-Command
$paramHash = @{
 ScriptBlock = $myScriptBlock ComputerName = $env:computername HideComputerName = $True}

If ($AsJob) {
    Write-Verbose "Running as a background job"
    $paramHash.Add("AsJob",$True)
    Invoke-Command @paramHash 
}
else {
    #exclude RunspaceID where possible
    Invoke-Command @paramHash | Select-Object -property * -ExcludeProperty RunspaceID
}

} #end function

Set-Alias -Name tex -Value Test-Expression