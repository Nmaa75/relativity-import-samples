#import
. "$global:rootDir\Helpers\EndpointsClass.ps1"

$workspaceId = 1000000
$loadFilePath = "C:\DefaultFileRepository\samples\load_file_01.dat"

$importId = New-Guid
$sourceId = New-Guid
$global:Endpoints = [Endpoints]::new($workspaceId)

Context "Sample19 Get import job progress" {
    Describe "Create job" {
        $uri = $global:Endpoints.importJobCreateUri($importId)

        $body = @{
            applicationName = "Import-service-sample-app"
            correlationID = "Sample-job-0019"
        } | ConvertTo-Json -Depth 10
		
        $response = $global:WebRequest.callPost($uri, $body)
        $global:WebRequest.checkIfSuccess($response)
        Write-Information -MessageData "Job $importId created" -InformationAction Continue
    }

    Describe "Create document configuration" {
        $uri = $global:Endpoints.documentConfigurationUri($importId)
        $jobConfigurationBody = '{
            "importSettings" :
            {
                "Overlay":null,
                "Native":{
                    "FilePathColumnIndex": "22",
                    "FileNameColumnIndex": "13"
                },
                "Image":null,
                "Production":null,
                "Fields": {
                    "FieldMappings": [
                        {
                            "ColumnIndex": 0,
                            "Field": "Control Number",
                            "ContainsID": false,
                            "ContainsFilePath": false
                        },
                        {
                            "ColumnIndex": 1,
                            "Field": "Custodian - Single Choice",
                            "ContainsID": false,
                            "ContainsFilePath": false
                        },
                        {
                            "ColumnIndex": 11,
                            "Field": "Email To",
                            "ContainsID": false,
                            "ContainsFilePath": false
                        },
                        {
                            "ColumnIndex": 5,
                            "Field": "Date Sent",
                            "ContainsID": false,
                            "ContainsFilePath": false
                        }
                    ]
                },
                "Folder":null
            }
        }'
        $response = $global:WebRequest.callPost($uri, $jobConfigurationBody)
        $global:WebRequest.checkIfSuccess($response)
        Write-Information -MessageData "Job configuration created" -InformationAction Continue
    }

    Describe "Add Source" {
        $uri = $global:Endpoints.importSourceAddUri($importId, $sourceId)
        $dataSourceConfigurationBody = @{
            dataSourceSettings = @{
                path = $loadFilePath
                firstLineContainsColumnNames = $true
                startLine = 0
                columnDelimiter = "|"
                quoteDelimiter = "^"
                newLineDelimiter = "#"
                nestedValueDelimiter = "&"
                multiValueDelimiter = "$"
                endOfLine = 0
                encoding = $null
                cultureInfo = "en-us"
                type = 2
            }
        } | ConvertTo-Json -Depth 10
		
        $response = $global:WebRequest.callPost($uri, $dataSourceConfigurationBody)
        $global:WebRequest.checkIfSuccess($response)
        Write-Information -MessageData "Source $sourceId added" -InformationAction Continue
    }

    Describe "Begin job" {
        $uri = $global:Endpoints.importJobBeginUri($importId)
        $beginBody = ""
		
        $response = $global:WebRequest.callPost($uri, $beginBody)
        $global:WebRequest.checkIfSuccess($response)
        Write-Information -MessageData "Job began" -InformationAction Continue
    }

    Describe "End job" {
        $uri = $global:Endpoints.importJobEndUri($importId)
        $endBody = ""
		
        $response = $global:WebRequest.callPost($uri, $endBody)
        $global:WebRequest.checkIfSuccess($response)
        Write-Information -MessageData "End job called" -InformationAction Continue
    }

    Describe "Wait for import to complete" {
        $uri = $global:Endpoints.importJobDetailsUri($importId)
        $jobDetailsResponse = $global:WebRequest.callGet($uri)
        $isJobFinished = $jobDetailsResponse."Value"."IsFinished"

        [int]$sleepTime = 5

        while($isJobFinished -ne $true)
        {
            Start-Sleep -Seconds $sleepTime
            $jobDetailsResponse = $global:WebRequest.callGet($uri)
            $isJobFinished = $jobDetailsResponse."Value"."IsFinished"
            $state = $jobDetailsResponse."Value"."State"
            Write-Information -MessageData "Current job status: $state" -InformationAction Continue
        }

        $name = $jobDetailsResponse."Value"."ApplicationName"
        Write-Information -MessageData "Job status: $state, Application Name: $name" -InformationAction Continue
    }

    Describe "Imported records info" {
        $uri = $global:Endpoints.importJobProgressUri($importId)
        $jobDetailsResponse = $global:WebRequest.callGet($uri)
        $totalRecords = $jobDetailsResponse."Value"."TotalRecords"
        $importedRecords = $jobDetailsResponse."Value"."ImportedRecords"
        $erroredRecords = $jobDetailsResponse."Value"."ErroredRecords"

        Write-Information -MessageData "Import progress: Total records: $totalRecords, Imported records: $importedRecords, Records with errors: $erroredRecords" -InformationAction Continue

        #Expected output
        #Job status: Completed, Application Name: Import-service-sample-app
        #Import progress: Total records: 4, Imported records: 4, Records with errors: 0
    }
}