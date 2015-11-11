#requires -version 4.0

<#
   TODO: 
   ADD A RANDOM INTERVAL OPTION WITH PARAMETERS FOR MIN AND MAX
   need to build a scriptblock with all the parameters to avoid the overhead of using Invoke-Command
   Create custom type and format
   convert to a module
    

#>

<#
Change History
v2.2  Added ie alias to IncludeExpression
      Modified Measure-Command to invoke the scriptblock without needing to use Invoke-Command which added overhead
      Modified examples
v2.2.1 Added MIT license

#>
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
Include the test scriptblock in the output. This parameter has an alias of ie.
.PARAMETER AsJob
Run the tests as a background job.
.EXAMPLE
PS C:\> $cred = Get-credential globomantics\administrator
PS C:\> $c = "chi-dc01","chi-dc04"
PS C:\> Test-Expression {param([string[]]$computer,$cred) get-wmiobject -class win32_logicaldisk -computername $computer -credential $cred } -argumentList $c,$cred


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
AverageMS    : 72.78199
MinimumMS    : 29.4449
MaximumMS    : 110.6553
MedianMS     : 90.3509
TrimmedMS    : 73.4649625


PS C:\> $sb2 = { foreach ($i in (1..1000)) {$_*2}}
PS C:\> test-expression $sb2 -Count 10 -interval 2

Tests        : 10
TestInterval : 2
AverageMS    : 6.40283
MinimumMS    : 0.7466
MaximumMS    : 22.968
MedianMS     : 2.781
TrimmedMS    : 5.0392125

These examples are testing two different approaches that yield the same results over a span of 10 test runs, pausing for 2 seconds between each test. The values for Average, Minimum and Maximum are in milliseconds.
.Example
PS C:\>  Test-expression {get-service bits,wuauserv,spooler} -count 5 -IncludeScriptblock 


Tests        : 5
TestInterval : 0.5
AverageMS    : 4.9711
MinimumMS    : 2.7682
MaximumMS    : 11.7352
MedianMS     : 3.5341
TrimmedMS    : 3.4507
Expression   : get-service bits,wuauserv,spooler

Include the tested expression in the output.
.EXAMPLE
PS C:\> Test-Expression { get-eventlog -list } -count 10 -Interval 5 -asjob

Id     Name            PSJobTypeName   State         HasMoreData     Location             Command                  
--     ----            -------------   -----         -----------     --------             -------                  
184    Job184          RemoteJob       Running       True            WIN81-ENT-01         ...  

Run the test as a background job. When the job is complete, get the results.

PS C:\> receive-job 184 -keep


Tests        : 10
TestInterval : 5
AverageMS    : 2.80256
MinimumMS    : 0.7967
MaximumMS    : 14.911
MedianMS     : 1.4469
TrimmedMS    : 1.5397375
RunspaceId   : f30eb879-fe8f-4ad0-8d70-d4c8b6b4eccc

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
[Alias("ie")]
[switch]$IncludeScriptblock,
[switch]$AsJob
)

Write-Verbose "Measuring expression:"
Write-Verbose ($Expression | Out-String)
if ($ArgumentList) {
    Write-Verbose "Arguments: $($ArgumentList -join ",")"
}
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
       ##  write-host $using:expression -ForegroundColor yellow
        
        Measure-Command -Expression {$($script:testblock).Invoke(@($using:argumentlist)) } -OutVariable +out
         <#
         Measure-Command -Expression { 
         #Invoke-Command -ScriptBlock $script:testblock -ArgumentList @($using:ArgumentList)
        $sb = [scriptblock]::Create($using:expression)
        $sb.Invoke($using:argumentlist)
        #>

     #} -outvariable +out
     #pause to mitigate any caching effects
     
     Start-Sleep -Milliseconds ($using:Interval*1000)
    } 
    
    $TestResults = $TestData | 
    Measure-Object -Property TotalMilliseconds -Average -Maximum -Minimum |
    Select-Object -Property @{Name = "Tests";Expression={$_.Count}},
    @{Name = "TestInterval";Expression = {$using:Interval}},
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

#define an optional alias
Set-Alias -Name tex -Value Test-Expression