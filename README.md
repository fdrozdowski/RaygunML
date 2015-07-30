RaygunML
========
 
[Raygun.io](https://raygun.io/) provider for [MarkLogic](http://www.marklogic.com/).

Installation
------------
  - Copy raygun folder into your modules database, file system, or
    into MarkLogic/Modules/MarkLogic.
  - If you placed raygun folder in the filesystem or modules database of
    one of your app servers, you can execute HTTP GET request on
    raygun-init.xqy (the script is meant to be executed by admin MarkLogic
    user) with the following parameters:
    - **isconfig**: boolean - If set to false, arguments **api-key**,
      **mode**, **database**, and  **user** have to be provided; 
      otherwise argument **config** has to be provided.
    - **api-key**: Your Raygun api key can be found in Raygun.io web
      application under Plan Settings --> Application Settings.
   - **mode**: Valid modes are development/qa/production - in development
     mode reporting to raygun is turned off.
    - **database**: One or more database names. RaygunML init script will
      insert into the listed databases an xml config file in the following
      format: 
      ```xml  
      <raygun>
        <api-key>raygun-api-key</api-key>
        <mode>raygun-mode</mode>
      </raygun>
      ```
    - **user**: One or more MarkLogic users. RaygunML creates two
      MarkLogic roles: *raygun-read* and *raygun-update*. By default, 
      listed database users get only *raygun-read* role assigned to them.
      Therefore, listed users will not be able to change raygun api key or
      raygun mode. If you want the specified database users to be able to
      change raygun api key or raygun mode in the configuration file
      inserted into the listed databases, you have to assign them 
      *raygun-update* role in MarkLogic admin interface or
      programmatically.
    - **config**: raygun initialization config xml file in the following
      format:
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
Say I have an app server at port 8080 with modules in the file system and
I placed raygun folder in the root ("/") directory of that server.
Here's an example of RaygunML installation without config.xml:
``` 
http://localhost:8080/raygun/raygun-init.xqy?&api-key=apikey&mode=development&database=database1&database=database2&user=user1&user=user2&isconfig=false
```
Installation with config.xml.  
```
http://localhost:8080/raygun/raygun-init.xqy?config=<raygun><api-key>apikey</api-key><mode>development</mode><usernames><user>user1</user><user>user2</user></usernames><databases><database>database1</database><database>database2</database></databases></raygun>&isconfig=true
```

Powershell script to initialize RaygunML. Make sure to place this 
Powershell script in the same directory as config.xml (see **config**).
```PowerShell
$file = Get-Content config.xml
$file = $file -replace '\s',''
$req = "http://localhost:8080/raygun/raygun-init.xqy?config=" + $file +
        "&isconfig=true"
$cred = Get-Credential

Write-Output $req
Invoke-WebRequest -Uri $req -Credential $cred
```

You can always initialize RaygunML in QConsole. Say you placed raygun
folder in .../MarkLogic/Modules/MarkLogic. You can execute the following
code in QConsole to initialize RaygunML:
```XQuery
xquery version "1.0-ml";

import module namespace raygun-deploy = "http://raygun.io" at
  "/MarkLogic/raygun/raygun-deploy.xqm";

raygun-deploy:init(
  <raygun>
    <api-key>raygun-api-key</api-key>
    <mode>raygun-mode</mode>
    <usernames>
      <user>user1</user>
      <user>user2</user>
    </usernames>
    <databases>
      <database>database1</database>
      <database>database2</database>
    </databases>
  </raygun>)

```
Usage
-----
In order to report an exception to Raygun, you can use the following code:
```XQuery  
import module namespace raygun = "http://raygun.io" at
  "/raygun/raygun.xqm";

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
