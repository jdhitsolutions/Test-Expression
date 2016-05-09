
NAME
    Test-Expression
    
SYNOPSIS
    Test a PowerShell expression.
    
SYNTAX
    Test-Expression [-Expression] <ScriptBlock> [-ArgumentList <Object[]>] [-Count <Int32>] [-Interval <Double>] 
    [-IncludeScriptblock] [-AsJob] [<CommonParameters>]
    
    
DESCRIPTION
    This command will test a PowerShell expression or scriptblock for a specified number of times and calculate the 
    average runtime, in milliseconds, over all the tests. 
    The output will also show the median and trimmed values. The median is calculated by sorting the values in ascending 
    order and selecting the value in the center of the array. If the array has an even number of elements then the median 
    is the average of the two values in the center.
    The trimmed value will toss out the lowest and highest values and average the remaining values. This may be the most 
    accurate indication as it will eliminate any small values which might come from caching and any large values which 
    may come a temporary shortage of resources. You will only get a value if you run more than 1 test.
    

PARAMETERS
    -Expression <ScriptBlock>
        The scriptblock you want to test. This parameter has an alias of sb.
        
        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -ArgumentList <Object[]>
        An array of parameters to pass to the scriptblock. Arguments are positional.
        
        Required?                    false
        Position?                    named
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -Count <Int32>
        The number of times to test the scriptblock.
        
        Required?                    false
        Position?                    named
        Default value                1
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -Interval <Double>
        How much time to sleep in seconds between each test. Maximum is 60. You may want to use a sleep interval to 
        mitigate possible caching effects.
        
        Required?                    false
        Position?                    named
        Default value                0.5
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -IncludeScriptblock [<SwitchParameter>]
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -AsJob [<SwitchParameter>]
        Run the tests as a background job.
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216). 
    
INPUTS
    None   
    
OUTPUTS
    Custom measurement object  
    
    
NOTES
    
    
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
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>$cred = Get-credential globomantics\administrator
    PS C:\> Test-Expression {param($cred) get-wmiobject win32_logicaldisk -computer chi-dc01 -credential $cred } 
    -argumentList $cred
    
    
    Tests        : 1
    TestInterval : 0.5
    AverageMS    : 1990.6779
    MinimumMS    : 1990.6779
    MaximumMS    : 1990.6779
    MedianMS     : 1990.6779
    TrimmedMS    : 
    
    Test a command once passing an argument to the scriptblock.
    
    
    -------------------------- EXAMPLE 2 --------------------------
    
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
    
    These examples are testing two different approaches that yield the same results over a span of 10 test runs, pausing 
    for 2 seconds between each test. The values for Average, Minimum and Maximum are in milliseconds.
    
    
    -------------------------- EXAMPLE 3 --------------------------
    
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
    
    
    
RELATED LINKS
    Measure-Command
    Measure-Object 

