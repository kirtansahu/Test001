SFDX_USE_GENERIC_UNIX_KEYCHAIN=true sfdx force:auth:jwt:grant -u %sfsb.username% -f Certificate/server.key -i %clientId% --json --loglevel TRACE -r https://test.salesforce.com
