#requires -version 4.0

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
        Write-Verbose "Adding expression to output"
        $TestResults | Add-Member -MemberType Noteproperty -Name Expression -Value $Expression -PassThru
    }
    else {
        $TestResults
    }

} #_TestMe function

Function Test-Expression {

[cmdletbinding(DefaultParameterSetName="Interval")]
Param(
[Parameter(
    Position = 0,
    Mandatory,
    HelpMessage = "Enter a scriptblock to test"
    )]
[Alias("sb")]
[scriptblock]$Expression,

[object[]]$ArgumentList,

[ValidateScript({$_ -ge 1})]
[int]$Count = 1,

[Parameter(ParameterSetName = "Interval")]
[ValidateRange(0,60)]
[Alias("sleep")]
[double]$Interval = .5,

[Parameter(
    ParameterSetName = "Random",
    Mandatory
    )]
[Alias("min")]
[double]$RandomMinimum,

[Parameter(
    ParameterSetName = "Random",
    Mandatory
    )]
[Alias("max")]
[double]$RandomMaximum,

[Alias("ie")]
[switch]$IncludeExpression,

[switch]$AsJob

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

