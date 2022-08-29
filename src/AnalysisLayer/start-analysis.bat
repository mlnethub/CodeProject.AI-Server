:: CodeProject.AI Analysis services (DeepStack module) startup script for Windows
::
:: Usage:
::   start.bat
::
:: We assume we're in the /src/AnalysisLayer directory

@echo off
SetLocal EnableDelayedExpansion

set verbosity=info

:: Assume platform
set platform="windows"

:: Move into the working directory
:: if not "%1" == "" (
::    cd "%1"
::)
set embedded=false
if "%1" == "--embedded" (
    set embedded="true"
) else (
    cls
)

:: Get some common env vars
set APPDIR=%cd%

:: ===============================================================================================
:: 1. Load environment variables

:: If calling from another script then assume parent script has set some env vars
:: NOTE: Environement variables aren't being maintained so manually setting them
:: if "%embedded%" == "false" (

    echo Setting Environment variables...

    REM API server
    set CPAI_PORT=5000

    REM Text module
    set NLTK_DATA=!APPDIR!\TextSummary\nltk_data

    REM Deepstack stuff
    set DATA_DIR=!APPDIR!\Vision\datastore
    set TEMP_PATH=!APPDIR!\Vision\tempstore
    set MODELS_DIR=!APPDIR!\Vision\assets
    set PROFILE=desktop_gpu
    set USE_CUDA=True
    set MODE=Medium
:: )

if "%verbosity%" == "info" (
    echo:
    echo CPAI_PORT = !CPAI_PORT!
    echo APPDIR    = !APPDIR!
    echo NLTK_DATA = !NLTK_DATA!
    echo PROFILE   = !PROFILE!
    echo USE_CUDA =  !USE_CUDA!
    echo DATA_DIR  = !DATA_DIR!
    echo TEMP_PATH = !TEMP_PATH!
    echo MODE      = !MODE!
)

:: ===============================================================================================
:: 2. Start each module

echo:
echo Starting Analysis Services...

:: Python 3.7
set python37Path=!APPDIR!\src\AnalysisLayer\bin\windows\Python37\venv\Scripts\Python
set python39Path=!APPDIR!\src\AnalysisLayer\bin\windows\Python39\venv\Scripts\Python

START "CodeProject.AI" /B /i "!python39Path!" "!APPDIR!\TextSummary\textsummary.py"
START "CodeProject.AI" /B /i "!python39Path!" "!APPDIR!\BackgroundRemover\rembg_adapter.py"

START "CodeProject.AI" /B /i "!python37Path!" "!APPDIR!\Vision\intelligencelayer\detection.py"
START "CodeProject.AI" /B /i "!python37Path!" "!APPDIR!\Vision\intelligencelayer\face.py"
START "CodeProject.AI" /B /i "!python37Path!" "!APPDIR!\Vision\intelligencelayer\scene.py"

:: Wait forever. We need these processes to stay alive
if "%embedded%" == "false" (
    pause > NUL
)