xquery version "1.0-ml";

import module namespace sec = "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

(: Create a role that will be used to execute Raygun module. :)
sec:create-role("raygun-read", "Read access to Raygun provider configuration file", (), (), ()),
sec:create-role("raygun-update", "Update access to Raygun provider configuration file", (), (), ());
xdmp:commit();

xquery version "1.0-ml";
import module namespace sec = "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

(: Add required privileges to the raygun roles to enable execution of the module. :)
sec:privilege-add-roles("http://marklogic.com/xdmp/privileges/xdmp-http-post", "execute", ("raygun-read")),
xdmp:commit();

xquery version "1.0-ml";
import module namespace sec = "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

sec:privilege-add-roles("http://marklogic.com/xdmp/privileges/xdmp-http-post", "execute", ("raygun-update")),
xdmp:commit();

xquery version "1.0-ml";
import module namespace sec = "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare variable $usernames as json:array external; 

(: Add Raygun role to specified users. By default, add only the role with read access. :)
sec:user-add-roles(json:array-values($usernames), ("raygun-read"));
xdmp:commit();