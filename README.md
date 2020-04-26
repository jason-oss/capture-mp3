# capture-mp3
Powershell script to archive files from a continous mp3 stream to local storage and/or AWS S3.   This script was created to regularly capture files created by the [Proscan](https://www.proscan.org/) application in order to reguarly archive files to AWS S3 to be published as a podcast using the [lambda-podcast project](https://github.com/marekq/lambda-podcast).


## Prerequistes:

### Target system
- Powershell 5.1 (the script may work with other versions but has been tested with Powershell 5.1 on Windows 10)
- An application continuously recording mp3 files (this was designed to work with [Proscan](https://www.proscan.org/))
- source mp3 files recorded to path similar to:  [parentpath]/[date]/[mp3file] 

### AWS S3 (optional)
- AWS account with target S3 bucket
- AWS IAM identity / group / policy to allow write access to target s3 bucket
- Install AWS tools for powershell (S3) on recording machine
  ```
     Install-Module -name AWSPowerShell.NetCore
     Import-Module AWSPowerShell.NetCore
  ```
- [Configure AWS key/secret in to be used by aws tools for Powershell](https://aws.amazon.com/blogs/developer/handling-credentials-with-aws-tools-for-windows-powershell/)

## Setup:
- clone repository
- configure a scheduled task in windows to execute at desired frequency


### Scheduled task configuration

Sample command for execution within task scheduler
```
powershell.exe -executionpolicy bypass -file {YourPathToScriptFile}\capture-mp3.ps1 -sourcedir {PathToSourceDirectory} -destdir {PathToDestDirectory} -s3bucket {S3bucket} -retainlocaldays 1 -retrywaitseconds 3 -maxretries 15
```

### Command line arguments

| Argument | Required | Default | Description |
| --------- | --- | ---- | ------------------------------------------------------------------- |
| sourcedir | Yes | None | Directory **above** directory (ex date) containing target recordings|
| destdir | Yes | None | local directory to hold recording snapshots on each execution |
| s3bucket | No | None | target AWS S3 Bucket. Leave as '' if copy to s3 is not desired |
| retainlocaldays | No | 1 | Number of days data to retain locally in the destdir structure |
| retrywaitseconds | No | 3 | Number of seconds to wait between retries if the file is in use |
| maxretries | No | 15 | Maximum number of times to attempt retry if file is in use |


## Proscan recorder settings
The following settings are recommended if recording from Proscan
- VOX recording mode
- Max Recording time:  None
  