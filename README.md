# MiniBot
An OpenAI compatible Powershell console client.

1.) Set your configuration values at the top of the script:

```
[string]$BaseUrl = "http://127.0.0.1:8080/v1",
[string]$Model = "Qwen3.6-35B-A3B-uncensored-heretic-Native-MTP-Preserved-Q8_0",
[string]$ApiKey = "none",
[int]$MaxTokens = 8192,
[double]$Temperature = 0.15,
[int]$MaxTurns = 25,
[string]$AgentName = "MiniBot",
[string]$Version = "0.0.3",
[bool]$AutoApproveEnabled = $false,
[bool]$StoreCredentials = $false
```

2.) Run the script and interact with your agent ;P

(If you use NPMPlus ACL for your host, the script will automatically prompt for credentials. Make sure to set 'Satisfy Any/Pass Auth to Upstream' in NPM's settings for this to work properly. You may also want to add the following to your custom settings -> proxy_buffering off; proxy_request_buffering off; so that model streaming looks correct)

<p align="center"><img src="https://raw.githubusercontent.com/illsk1lls/MiniBot/refs/heads/main/.readme/MiniBot.png"></p>
*NOTE: There is a whitelist(array) of pre-approved commands/command-prefixes near the top of the script. Any commands that arent in the whitelist(s) will require user approval before proceeding.*
