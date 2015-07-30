xquery version "1.0-ml";

module namespace raygun-deploy = "http://raygun.io";
import module namespace sec = "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
declare variable $READ_PERMISSIONS as element()* := 
  (xdmp:permission("raygun-read", "read"));
declare variable $UPDATE_PERMISSIONS as element()* :=
  (xdmp:permission("raygun-update", "read"), xdmp:permission("raygun-update", "update"));

(:
 : Initializes Raygun provider for MarkLogic.
 : 
 : @param $user-names Sequence of database user-names
 : @param $databases Sequence of database names
 : @param $api-key Raygun application api key
 : @param $mode Raygun mode: development/qa/production
 : @return Empty sequence if suceeded 
 :)
declare function raygun-deploy:init(
  $usernames as xs:string+,
  $databases as xs:string+,
  $api-key as xs:string,
  $mode as xs:string)
{
  let $result := xdmp:invoke(
    "raygun-init-security.xqy", 
    (xs:QName("usernames"), json:to-array($usernames)),        
    <options xmlns="xdmp:eval">
      <database>{xdmp:security-database()}</database>
      <transaction-mode>update</transaction-mode>
    </options>)
  return (),
  
  (: Insert a Raygun.io configuration file with default mode = development. :)
  for $database-name in $databases
  return xdmp:invoke-function(
    function() {      
      xdmp:document-insert("/raygun.xml", 
        <raygun>
          <api-key>{$api-key}</api-key>
          <mode>{$mode}</mode>
        </raygun>, 
        ($READ_PERMISSIONS, $UPDATE_PERMISSIONS)), 
      xdmp:commit() },
    <options xmlns="xdmp:eval">
      <database>{xdmp:database($database-name)}</database>
      <transaction-mode>update</transaction-mode>
    </options>
  )
};

(:
 : Initializes Raygun provider for MarkLogic.
 :  
 : @param $config Raygun configuration file the following form:
 :                <raygun>
 :                  <api-key>...</api-key>
 :                  <mode>...</mode>
 :                  <user-names>
 :                    <user>...</user>
 :                    <user>...</user>
 :                    ...
 :                  </user-names>
 :                  <databases>
 :                    <database>...</database>
 :                    <database>...</database>
 :                    ...
 :                  </databases>
 :                </raygun>   
 : @return Empty sequence if suceeded 
 :)
declare function raygun-deploy:init(
  $config as element(raygun))
{
  raygun-deploy:init(
    $config/usernames/user/string(),
    $config/databases/database/string(),
    $config/api-key/string(),
    $config/mode/string()
  )
};

(: 
 : Changes the error reporting mode. Depending on the mode, reporting to Raygun is on/off. 
 : Possible are following modes: 
 : - development: reporting is off
 : - qa: reporting is on
 : - production: reporting is on
 :   
 : @param $mode Valid modes: "development", "qa", "production"
 : @return Empty sequence if succeeded, error otherwise
 :)    
declare function raygun-deploy:change-config-mode(
  $mode as xs:string)
{
  let $raygun-api-key := doc("/raygun.xml")/raygun/api-key/string()
  let $permissions := xdmp:document-get-permissions("/raygun.xml")
  let $config := 
    <raygun>
      <api-key>{$raygun-api-key}</api-key>
      <mode>{$mode}</mode>
    </raygun>
  
  return switch ($mode)
    case "development"              
    case "qa" 
    case "production" 
      return xdmp:document-insert("/raygun.xml", $config, $permissions)
    default return error((), "Invalid mode provided.")
};
 
(: 
 : Changes Raygun api key in the configuration file.
 :   
 : @param $api-key Raygun api key
 : @return Empty sequence if succeeded
 :)    
declare function raygun-deploy:change-config-api-key(
  $api-key as xs:string)
{
  let $mode := doc("/raygun.xml")/raygun/mode/string()
  let $permissions := xdmp:document-get-permissions("/raygun.xml")
  return xdmp:document-insert(
    "/raygun.xml", 
    <raygun>
      <api-key>{$api-key}</api-key>
      <mode>{$mode}</mode>
    </raygun>, 
    $permissions)
};