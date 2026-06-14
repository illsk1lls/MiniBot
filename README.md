# MiniBot
An OpenAI compatible Powershell console client.

1.) Set your configuration values at the top of the script:

```
$BaseUrl	  = "http://192.168.1.50:8080/v1" # Point to an OpenAI compatible endpoint
$Model		  = "Qwen3.6-35B-A3B-uncensored-heretic-Native-MTP-Preserved-Q8_0" # This needs to match the model name you want to connect with
$ApiKey		  = "none" # this usually doesnt matter but if you have it set enter it here

$MaxTokens	  = 4096
$Temperature  = 0.2
$maxTurns	  = 12

$AgentName	  = "MiniBot-Agent" # This is the agents display name in the chat
$DisplayModel = $Model # Displays the model name, or anything you want in the console header at launch e.g. Powered By: 'This value'
$Version	  = "0.0.1" # Displays this script version in the console header at launch
```

Support for NPMPlus 'Access' lists is present, for outside access. Set $Protected = $true and you will be prompted for credentials during first run. (Hold CTRL during launch to reset/refresh credentials)

```
$Protected	  = $false # Set $true to use NPMPlus access control credentials for outside access (Make sure to set 'Satisfy Any/Pass Auth to Upstream' in the access list for this to work properly.)
```

2.) Run the script and interact with your agent ;P

<p align="center"><img src="https://github.com/illsk1lls/MiniBot/blob/main/.readme/MiniBot.png?raw=true"></p>
*NOTE: There is a whitelist(array) of pre-approved commands/command-prefixes near the top of the script. Any commands that arent in the whitelist(s) will require user approval before proceeding.*