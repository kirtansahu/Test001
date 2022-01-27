@ECHO OFF
@SETLOCAL 
FOR /F "tokens=1* delims==	 " %%G IN (CISupport\Sandbox\Sandbox_default.properties) DO (
	SET %%G=%%H
)
sfdx force:auth:jwt:grant -u %sfsb.username% -f "%jwtKeyFile%" -i %clientId% --json --loglevel TRACE -r %sfsb.instanceurl%
@ENDLOCAL