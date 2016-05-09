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
An array of parameters to pass to the test scriptblock. Arguments are positional.
.PARAMETER Count
The number of times to test the scriptblock.
.PARAMETER Interval
How much time to sleep in seconds between each test. Maximum is 60. You may want to use a sleep interval to mitigate possible caching effects.
.PARAMETER RandomMinimum
You can also specify a random interval by providing a random minimum and maximum values in seconds.
.PARAMETER RandomMaximum
You can also specify a random interval by providing a random minimum and maximum values in seconds.
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
PS C:\>  Test-expression {get-service bits,wuauserv,spooler} -count 5 -IncludeExpression 


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
VERSION     :  2.3  
LAST UPDATED:  April 1, 2016
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

[cmdletbinding(DefaultParameterSetName="Interval")]
Param(
[Parameter(Position=0,Mandatory,HelpMessage="Enter a scriptblock to test")]
[Alias("sb")]
[scriptblock]$Expression,
[object[]]$ArgumentList,
[ValidateScript({$_ -ge 1})]
[int]$Count = 1,
[Parameter(ParameterSetName = "Interval")]
[ValidateRange(0,60)]
[double]$Interval = .5,
[Alias("ie")]
[switch]$IncludeExpression,
[switch]$AsJob,
[Parameter(ParameterSetName = "Random",Mandatory)]
[Alias("min")]
[double]$RandomMinimum,
[Parameter(ParameterSetName = "Random",Mandatory)]
[Alias("max")]
[double]$RandomMaximum
)

Write-Verbose "Starting: $($MyInvocation.Mycommand)"
Write-Verbose ($PSBoundParameters | Out-string)
Write-Verbose "Measuring expression:"
Write-Verbose ($Expression | Out-String)
if ($ArgumentList) {
    Write-Verbose "Arguments: $($ArgumentList -join ",")"
}

if ($PSCmdlet.ParameterSetName -eq 'Interval') {
    write-Verbose "$Count time(s) with a sleep interval of $interval seconds."
}
else {
    write-Verbose "$Count time(s) with a random sleep interval between $RandomMinimum seconds and $RandomMaximum seconds."
}

#an internal function for the actual testing
Function _TestMe {
[cmdletbinding(DefaultParameterSetName="Interval")]
Param(
[scriptblock]$Expression,
[object[]]$ArgumentList,
[ValidateScript({$_ -ge 1})]
[int]$Count = 1,
[Parameter(ParameterSetName = "Interval")]
[ValidateRange(0,60)]
[double]$Interval=.5,
[Parameter(ParameterSetName = "Random",Mandatory)]
[Alias("min")]
[double]$RandomMinimum,
[Parameter(ParameterSetName = "Random",Mandatory)]
[Alias("max")]
[double]$RandomMaximum,
[switch]$IncludeExpression
)

 $TestData = 1..$count | foreach -begin {
     <#
      PowerShell doesn't seem to like passing a scriptblock as an
      argument when using Invoke-Command. It appears to pass it as
      a string so I'm recreating it as a scriptblock here.
     #>
     $script:testblock = [scriptblock]::Create($Expression)
     
     } -process {
         #invoke the scriptblock with any arguments and measure       
        Measure-Command -Expression {$($script:testblock).Invoke(@($argumentlist)) } -OutVariable +out
        
     #} -outvariable +out
     #pause to mitigate any caching effects
     if ($RandomMinimum -AND $RandomMaximum) {
        $sleep = Get-Random -Minimum ($RandomMinimum*1000) -Maximum ($RandomMaximum*1000)
        $TestInterval = "Random"
     }   
     else {
        $Sleep = ($Interval*1000)
        $TestInterval = $Sleep
     } 
     
     Start-Sleep -Milliseconds $sleep
    } 
    
    $TestResults = $TestData | 
    Measure-Object -Property TotalMilliseconds -Average -Maximum -Minimum |
    Select-Object -Property @{Name = "Tests";Expression={$_.Count}},
    @{Name = "TestInterval";Expression = {$TestInterval}},
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

    Write-Verbose "Inserting a new type name"
    $TestResults.psobject.typenames.insert(0,"my.TestResult")

    if ($IncludeExpression) {
        Write-host "Adding expression to output"
        $TestResults | Add-Member -MemberType Noteproperty -Name Expression -Value $Expression -PassThru
    }
    else {
        $TestResults
    }

} #_TestMe function


If ($AsJob) {
    Write-Verbose "Running as a background job"
    $PSBoundParameters.remove("AsJob") | Out-Null
    start-job -ScriptBlock {
    Param([hashtable]$Testparams)
    
    <#
      PowerShell doesn't seem to like passing a scriptblock as an
      argument when using Invoke-Command. It appears to pass it as
      a string so I'm recreating it as a scriptblock here.
    #>
 
    $expression = [scriptblock]::Create($Testparams.Expression)
    $TestParams.Expression = $Expression
    Test-Expression @testparams 
    } -ArgumentList @($PSBoundParameters) -InitializationScript {Import-Module Test-Expression}

}
else {

   $PSBoundParameters.remove("AsJob") | Out-Null
   _TestMe @PSBoundParameters
}

Write-Verbose "Ending: $($MyInvocation.Mycommand)"

} #end function

#define an optional alias
Set-Alias -Name tex -Value Test-Expression

