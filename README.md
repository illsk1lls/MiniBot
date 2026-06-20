# MiniBot
An OpenAI compatible Powershell console client.

1.) Set your configuration values at the top of the script:

```
$BaseUrl	  = "http://127.0.0.1:8080/v1" # Point to an OpenAI compatible endpoint
$Model		  = "Qwen3.6-35B-A3B-uncensored-heretic-Native-MTP-Preserved-Q8_0" # This needs to match the model name you want to connect with
$ApiKey		  = "none" # this usually doesnt matter but if you have it set enter it here

$MaxTokens	  = 4096
$Temperature  = 0.2
$maxTurns	  = 12

$AgentName	  = "MiniBot-Agent" # This is the agents display name in the chat
$DisplayModel = $Model # Displays the model name, or anything you want in the console header at launch e.g. Powered By: 'This value'
$Version	  = "0.0.2" # Displays this script version in the console header at launch
```

2.) Run the script and interact with your agent ;P

(If you use NPMPlus ACL for your host, the script will automatically prompt for credentials. Make sure to set 'Satisfy Any/Pass Auth to Upstream' in NPM's settings for this to work properly.)

<p align="center"><img src="https://raw.githubusercontent.com/illsk1lls/MiniBot/refs/heads/main/.readme/MiniBot.png"></p>
*NOTE: There is a whitelist(array) of pre-approved commands/command-prefixes near the top of the script. Any commands that arent in the whitelist(s) will require user approval before proceeding.*
