@REM ----------------------------------------------------------------------------
@REM Licensed to the Apache Software Foundation (ASF) under one
@REM or more contributor license agreements.  See the NOTICE file
@REM distributed with this work for additional information
@REM regarding copyright ownership.  The ASF licenses this file
@REM to you under the Apache License, Version 2.0 (the
@REM "License"); you may not use this file except in compliance
@REM with the License.  You may obtain a copy of the License at
@REM
@REM    https://www.apache.org/licenses/LICENSE-2.0
@REM
@REM Unless required by applicable law or agreed to in writing,
@REM software distributed under the License is distributed on an
@REM "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
@REM KIND, either express or implied.  See the License for the
@REM specific language governing permissions and limitations
@REM under the License.
@REM ----------------------------------------------------------------------------

@REM ----------------------------------------------------------------------------
@REM Apache Maven Wrapper startup batch script, version 3.2.0
@REM ----------------------------------------------------------------------------

@IF "%__MVNW_ARG0_NAME__%"=="" (SET __MVNW_ARG0_NAME__=%~nx0)
@SET __MVNW_CMD__=
@SET __MVNW_ERROR__=
@SET __MVNW_PSMODULEP_SAVE=%PSModulePath%
@SET PSModulePath=
@FOR /F "usebackq tokens=1,2 delims==" %%A IN (`powershell -noprofile "& {$scriptDir='%~dp0'; $proxy=''; [Net.WebRequest]::DefaultWebProxy.Headers.Add('User-Agent','mvn-w/3.2.0'); $mvnwVer='3.2.0'; try {Invoke-WebRequest -Uri ('https://repo.maven.apache.org/maven2/org/apache/maven/wrapper/maven-wrapper/'+$mvnwVer+'/maven-wrapper-'+$mvnwVer+'.jar') -OutFile (''+$scriptDir+'maven-wrapper.jar') -Proxy $proxy} catch {if ($_.Exception.Response.StatusCode -eq 404) {Write-Output ('maven-wrapper.jar not found at '+$_.Exception.Response.ResponseUri)} else {Write-Output $_.Exception.Message}}}"`) DO @(
    IF "%%A"=="MVN_CMD" (set __MVNW_CMD__=%%~B) else IF "%%B"=="" (echo.%%A) else (echo.%%A=%%B)
)
@SET PSModulePath=%__MVNW_PSMODULEP_SAVE%
@SET __MVNW_PSMODULEP_SAVE=
@SET __MVNW_ARG0_NAME__=
@REM If MVN_CMD is set, use it
@IF NOT "%__MVNW_CMD__%"=="" (%__MVNW_CMD__% %*)
@echo.
@echo Cannot run mvnw without Maven. Please install Maven or check your PATH.
@echo You can also download Maven from https://maven.apache.org/download.cgi
@echo.
@exit /b 1
