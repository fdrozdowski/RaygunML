RaygunML
========
 
[Raygun.io](https://raygun.io/) provider for [MarkLogic](http://www.marklogic.com/).

Installation
------------
  - Copy raygun folder into MarkLogic/Modules/MarkLogic.
  - Copy raygun-init.xqy into the directory of one of your database
    endpoints.
  - Execute HTTP GET on raygun-init.xqy (the script is meant to be executed
    by admin MarkLogic user) with the following parameters:
    - **isconfig**: true/false - If set to false, arguments **api-key**,
      **mode**, **user**, and **database** have to be provided; 
    otherwise **config** argument has to be provided.
    - **api-key**: Your Raygun api key can be found in Raygun.io web
      application under Plan Settings --> Application Settings.
   - **mode**: Valid modes are development/qa/production - in development
     mode reporting to raygun is turned off.
    - **user**: One or more users in the following format:
      ```<user>user</user>```. RaygunML creates two MarkLogic roles:
      *raygun-read* and *raygun-update*. By default, listed database users
      get only *raygun-read* role assigned to them. Therefore, listed users
      will not be able to change raygun api key or raygun mode. If you want
      the specified database users to be able to change raygun api key or
      raygun mode, you have to assign them *raygun-update* role in MarkLogic
      admin interface ir programmatically.
    - **database**: One or more database names in the following format:
      ```<database>database</database>```. RaygunML init script will insert
      into the listed databases an xml config file in the following format: 
      ```xml  
      <raygun>
        <api-key>raygun-api-key</api-key>
        <mode>raygun-mode</mode>
      </raygun>
      ```
    - **config**: raygun configuration xml file in the following format:
```xml    
 <raygun>
	    <api-key>raygun-api-key</api-key>
        <mode>raygun-mode</mode>
        <usernames>
		  <user>user1</user>
		  <user>user2</user>
		        ....
	    </usernames>
	    <databases>
		  <database>database1</database>
		  <database>database2</database>
	                  ....
	    </databases>
</raygun>
```  
  
**Installation Examples**  
RaygunML installation without config.xml:
``` 
http://localhost:9001/raygun-init.xqy?&api-key=apikey&mode=development&database=database1&database=database2&user=user1&user=user2&isconfig=false
```
Installation with config.xml:
```
http://localhost:9001/raygun-init.xqy?config=<raygun><api-key>apikey</api-key><mode>development</mode><usernames><user>user1</user><user>user2</user></usernames><databases><database>database1</database><database>database2</database></databases></raygun>&isconfig=true
```

Powershell script to initialize RaygunML: 
```PowerShell
$file = Get-Content config.xml
$file = $file -replace '\s',''
$req = "http://localhost:9001/raygun-init.xqy?config=" + $file +
        "&isconfig=true"
$cred = Get-Credential

Write-Output $req
Invoke-WebRequest -Uri $req -Credential $cred
```
My raygun-init.xqy is located in the root directory of my MarkLogic HTTP
server located at localhost:9001. Make sure to place your config.xml, in
the form of **config**, in the same directory as initialzation script.

Usage
-----
In order to report an exception to Raygun, you can use the following code:
```XQuery  
import module namespace raygun = "http://raygun.io" at "/raygun/raygun.xqm";

try
{ 
  // some code causing error
catch($error) 
{ 
  raygun:report-error($error)
}

```
Version
-------

Alpha. 
