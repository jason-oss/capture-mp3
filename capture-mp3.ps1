
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
# vars
#sourcedir=                     #directory containing source recordings.  Ideally this is a continuous recording.
#$destdir=                      #local directory to hold recording snapshots each time script is executed
#$s3bucket=                        #target AWS S3 bucket, leave as '' if copy to s3 bucket is not desired
#$retainlocaldays=1                              #number of days data to retain the the destdir structure
#$retrywaitseconds=3                             #number of seconds to wait between retries if file is in use
#$maxretries=15                                  #number of times to attempt retry if file if is in use
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------


param (
    [Parameter(Mandatory=$true)][string]$sourcedir,
    [Parameter(Mandatory=$true)][string]$destdir,
    [Parameter(Mandatory=$false)][string]$s3bucket='',
    [Parameter(Mandatory=$false)][int]$retainlocaldays=1,
    [Parameter(Mandatory=$false)][int]$retrywaitseconds=3,
    [Parameter(Mandatory=$false)][int]$maxretries=15
)








function get-numericdaterange {
    param($file)
    $create=$file.CreationTime.ToString("yyyyMMdd-HHmmss")
    $lastwrite=$file.LastWriteTime.ToString("HHmmss")
    return $create+"-"+$lastwrite
}


function get-relativedestpath {
    param($file,$sourcedir)
    
    #return relative path below $sourcedir
    $sourcedir = $sourcedir -replace "\\","\\"
    $shortpath = $file.DirectoryName
    $shortpath = $shortpath -replace $sourcedir,""
    if (-Not $shortpath.StartsWith("\")) {$shortpath = "\"+$shortpath}
    if (-Not $shortpath.EndsWith("\"))   {$shortpath = $shortpath+"\"}
    return $shortpath
}

function get-newfile {
    param ($file,$sourcedir,$destdir)
   
    $shortpath = get-relativedestpath $file $sourcedir
    $numericdate = get-numericdaterange $file
    $extension = $file.Extension 

    return  $destdir+$shortpath+$numericdate+$extension
}



function get-sourcemp3s {
    param ($sourcedir)
    $files = Get-ChildItem -Path $sourcedir -Include *.mp3 -Recurse
    return $files
}


function create-destdir {
    param($newfile)
    $fullparentpath = Split-Path -Path $newfile
    $fullparentpath = $fullparentpath + "\"

    if (!(Test-Path $fullparentpath)) {
        New-Item -ItemType Directory -Path $fullparentpath -Force
    }
}


function move-file {
    param($file,$newfile,$retrywaitseconds,$maxretries)
 
    create-destdir $newfile

    $stoploop=$false
    [int]$retrycount=1

    do{
        try {
            Write-host "Moving: " $file.FullName " --> " $newfile "attempt: " $retrycount.ToString()
            Move-Item  -Path $file -Destination $newfile -Force -ErrorAction Stop
            Write-Host "Sucessfully moved to " $newfile
            $movedfile = get-item $newfile
            return $movedfile
            $stoploop=$true
        }
        catch {
            if ($retrycount -gt $maxretries) {
                Write-Host "could not move file.  error:" 
                Write-Host $_
                $stoploop=$true
                }
            else {
                Write-Host "could not move file, retrying in 15 times.  Current attempt: " $retrycount
                Start-Sleep -Seconds $retrywaitseconds
                $retrycount = $retrycount + 1
            }
        }
    }
    while ($stoploop -eq $false)
}


function move-filetoS3 {
    param(
        $s3bucket,
        $movedfile
    )
    
    if ($s3bucket) {
        $directoryname = $movedfile.Directory.Name
        $filename = $movedfile.name
        $key = $directoryname + "/" +  $filename
        write-s3object -bucketname $s3bucket -File $movedfile -key $key
        write-host "file copied to S3"
    }
}


function remove-olderfiles {
    param (
        $destdir,
        $retainlocaldays
    )

    if ($retainlocaldays -gt 0) {$retainlocaldays=$retainlocaldays*-1}
    $currentdate = get-date
    $deletedate = $currentdate.AddDays($retainlocaldays)

    get-childitem $destdir -recurse | where-object {$_.lastwritetime -lt $deletedate} | remove-item -force -confirm:$false

}







$files = get-sourcemp3s $sourcedir

foreach ($file in $files) {
    $newfile = get-newfile $file $sourcedir $destdir
    $movedfile = move-file $file $newfile $retrywaitseconds $maxretries
    move-filetos3 $s3bucket $movedfile
}

remove-olderfiles $destdir $retainlocaldays






