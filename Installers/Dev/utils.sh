# :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

# CodeProject.AI Server Utilities
#
# Utilities for use with Linux/macOS Development Environment install scripts
# 
# We assume we're in the source code /Installers/Dev directory.
# 
# :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

# Returns a color code for the given foreground/background colors
# This code is echoed to the terminal before outputing text in
# order to generate a colored output.
#
# string foreground color name. Optional if no background provided.
#        Defaults to "Default" which uses the system default
# string background color name.  Optional. Defaults to $color_background
#        which is set based on the current terminal background
# returns a string
function Color () {

    local foreground=$1
    local background=$2

    if [ "$foreground" == "" ]; then foreground='Default'; fi
    if [ "$background" == "" ]; then background="$color_background"; fi

    if [ "$foreground" == 'Contrast' ]; then
        foreground=$(ContrastForeground ${background})
    fi
    
    local colorString='\033['

    # Foreground Colours
    case "$foreground" in
        'Default')      colorString='\033[0;39m';;
        'Black' )       colorString='\033[0;30m';;
        'DarkRed' )     colorString='\033[0;31m';;
        'DarkGreen' )   colorString='\033[0;32m';;
        'DarkYellow' )  colorString='\033[0;33m';;
        'DarkBlue' )    colorString='\033[0;34m';;
        'DarkMagenta' ) colorString='\033[0;35m';;
        'DarkCyan' )    colorString='\033[0;36m';;
        'Gray' )        colorString='\033[0;37m';;
        'DarkGray' )    colorString='\033[1;90m';;
        'Red' )         colorString='\033[1;91m';;
        'Green' )       colorString='\033[1;92m';;
        'Yellow' )      colorString='\033[1;93m';;
        'Blue' )        colorString='\033[1;94m';;
        'Magenta' )     colorString='\033[1;95m';;
        'Cyan' )        colorString='\033[1;96m';;
        'White' )       colorString='\033[1;97m';;
        *)              colorString='\033[0;39m';;
    esac

    # Background Colours
    case "$background" in
        'Default' )     colorString="${colorString}\033[49m";;
        'Black' )       colorString="${colorString}\033[40m";;
        'DarkRed' )     colorString="${colorString}\033[41m";;
        'DarkGreen' )   colorString="${colorString}\033[42m";;
        'DarkYellow' )  colorString="${colorString}\033[43m";;
        'DarkBlue' )    colorString="${colorString}\033[44m";;
        'DarkMagenta' ) colorString="${colorString}\033[45m";;
        'DarkCyan' )    colorString="${colorString}\033[46m";;
        'Gray' )        colorString="${colorString}\033[47m";;
        'DarkGray' )    colorString="${colorString}\033[100m";;
        'Red' )         colorString="${colorString}\033[101m";;
        'Green' )       colorString="${colorString}\033[102m";;
        'Yellow' )      colorString="${colorString}\033[103m";;
        'Blue' )        colorString="${colorString}\033[104m";;
        'Magenta' )     colorString="${colorString}\033[105m";;
        'Cyan' )        colorString="${colorString}\033[106m";;
        'White' )       colorString="${colorString}\033[107m";;
        *)              colorString="${colorString}\033[49m";;
    esac

    echo "${colorString}"
}

# Returns the name of a color that will providing a contrasting foreground
# color for the given background color. This function assumes $darkmode has
# been set globally.
#
# string background color name. 
# returns a string representing a contrasting foreground colour name
function ContrastForeground () {

    local color=$1
    if [ "$color" == '' ]; then color='Default'; fi

    if [ "$darkmode" == 'true' ]; then
        case "$color" in
            'Default' )     echo 'White';;
            'Black' )       echo 'White';;
            'DarkRed' )     echo 'White';;
            'DarkGreen' )   echo 'White';;
            'DarkYellow' )  echo 'White';;
            'DarkBlue' )    echo 'White';;
            'DarkMagenta' ) echo 'White';;
            'DarkCyan' )    echo 'White';;
            'Gray' )        echo 'Black';;
            'DarkGray' )    echo 'White';;
            'Red' )         echo 'White';;
            'Green' )       echo 'White';;
            'Yellow' )      echo 'Black';;
            'Blue' )        echo 'White';;
            'Magenta' )     echo 'White';;
            'Cyan' )        echo 'Black';;
            'White' )       echo 'Black';;
            *)              echo 'White';;
        esac
    else
        case "$color" in
            'Default' )     echo 'Black';;
            'Black' )       echo 'White';;
            'DarkRed' )     echo 'White';;
            'DarkGreen' )   echo 'White';;
            'DarkYellow' )  echo 'White';;
            'DarkBlue' )    echo 'White';;
            'DarkMagenta' ) echo 'White';;
            'DarkCyan' )    echo 'White';;
            'Gray' )        echo 'Black';;
            'DarkGray' )    echo 'White';;
            'Red' )         echo 'White';;
            'Green' )       echo 'Black';;
            'Yellow' )      echo 'Black';;
            'Blue' )        echo 'White';;
            'Magenta' )     echo 'White';;
            'Cyan' )        echo 'Black';;
            'White' )       echo 'Black';;
            *)              echo 'White';;
        esac
    fi
    
    echo "${colorString}"
}


# Gets the terminal background color. It's a very naive guess 
# returns an RGB triplet, values from 0 - 64K
function getBackground () {

    if [[ $OSTYPE == 'darwin'* ]]; then
        osascript -e \
        'tell application "Terminal"
           get background color of selected tab of window 1
        end tell'

        # Sure, we can ask and be polite. Or we can go in and clobber things. Except this doesn't actually work
        # osascript -e \
        #'tell application "Terminal"
        #    set background color of selected tab of window 1 to {65535, 65533, 65534}
        #end tell'        

    else

        # See https://github.com/rocky/shell-term-background/blob/master/term-background.bash
        # for a comprehensive way to test for background colour. For now we're
        # just going to assume that non-macOS terminals have a black background.

        echo '0,0,0' # we're making assumptions here
    fi
}

# Determines whether or not the current terminal is in dark mode (dark 
# background, light text). 
# returns "true" if running in dark mode; false otherwise
function isDarkMode () {

    local bgColor=$(getBackground)
    
    IFS=','; colors=($bgColor); IFS=' ';

    # Is the background more or less dark?
    if [ ${colors[0]} -lt 2000 ] && [ ${colors[1]} -lt 2000 ] && [ ${colors[2]} -lt 2000 ]; then
        echo 'true'
    else
        echo 'false'
    fi
}

function errorNoPython () {
    writeLine
    writeLine
    writeLine "----------------------------------------------------------------------" $color_primary
    writeLine "Error: Python not installed" $color_error
    writeLine 
    writeLine
    
    quit
}

function spin () {

    local pid=$1

    spin[0]='-'
    spin[1]='\\'
    spin[2]='|'
    spin[3]='/'

    while kill -0 $pid 2> /dev/null; do
        for i in "${spin[@]}"
        do
            echo -ne "$i\b"
            sleep 0.1
        done
    done

    echo -ne ' \b'
}

# Outputs a line, including linefeed, to the terminal using the given foreground
# / background colors 
#
# string The text to output. Optional if no foreground provided. Default is 
#        just a line feed.
# string Foreground color name. Optional if no background provided. Defaults to
#        "Default" which uses the system default
# string Background color name.  Optional. Defaults to $color_background which 
#        is set based on the current terminal background
function writeLine () {

    local resetColor='\033[0m'

    local str=$1
    local forecolor=$2
    local backcolor=$3

    if [ "$str" == "" ]; then
        printf '\n'
        return;
    fi

    # Note the use of the format placeholder %s. This allows us to pass "--" as
    # strings without error
    if [ "$useColor" == "true" ]; then
        local colorString=$(Color ${forecolor} ${backcolor})
        printf "${colorString}%s${resetColor}\n" "${str}"
    else
        printf "%s\n" "${str}"
    fi
}

# Outputs a line without a linefeed to the terminal using the given foreground
# / background colors 
#
# string The text to output. Optional if no foreground provided. Default is 
#        just a line feed.
# string Foreground color name. Optional if no background provided. Defaults to
#        "Default" which uses the system default
# string Background color name.  Optional. Defaults to $color_background which 
#        is set based on the current terminal background
function write () {

    local resetColor='\033[0m'

    local str=$1
    local forecolor=$2
    local backcolor=$3

    if [ "$str" == "" ];  then
        return;
    fi

    # Note the use of the format placeholder %s. This allows us to pass "--" as
    # strings without error
    if [ "$useColor" == 'true' ]; then
        local colorString=$(Color ${forecolor} ${backcolor})
        printf "${colorString}%s${resetColor}" "${str}"
    else
        printf "%s" "$str"
    fi
}

function checkForTool () {

    local name=$1

    if command -v ${name} &> /dev/null; then
        return
    fi

    writeLine
    writeLine
    writeLine "------------------------------------------------------------------------"
    writeLine "Error: ${name} is not installed on your system" $color_error

    if [ "$platform" == "macos" ] || [ "$platform" == "macos-arm" ]; then
        writeLine "       Please run 'brew install ${name}'" $color_error

        if ! command -v brew &> /dev/null; then
            writeLine
            writeLine "Error: It looks like you don't have brew installed either" $color_warn
            writeLine "       Please run:" $color_warn
            writeLine "       /bin/bash -c '$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)'" $color_warn
            quit
        fi
    else
        writeLine "       Please run 'sudo apt install ${name}'" $color_error
    fi

    writeLine
    writeLine
    quit
}

function setupPython () {

    # M1 macs are trouble for python
    if [ "$platform" == "macos-arm" ]; then
        writeLine "ARM (Apple silicon) Mac detected, but we are not running under Rosetta. " $color_warn
        if [ $(/usr/bin/pgrep oahd >/dev/null 2>&1; echo $?) -gt 0 ]; then
        #if [ "$(pkgutil --files com.apple.pkg.RosettaUpdateAuto)" == "" ]; then 
    	    writeLine 'Rosetta is not installed' $color_error
            needRosettaAndiBrew
        else
    	    writeLine 'All Good! Rosetta is installed. We can continue.' $color_success
        fi
    fi

    local pythonVersion=$1

    # Version with ".'s removed
    local pythonName="python${pythonVersion/./}"

    installPath="${analysisLayerPath}/bin/${platform}/${pythonName}"

    if [ "${forceOverwrite}" == "true" ]; then

        writeLine "Cleaning Python directory to force re-install of Python VENV" $color_info
        writeLine "This will mean any previous PIP installs wwill be lost." $color_error

        # Force Re-download. Except we don't actually. We have a x64 version of
        # python for macOS in our S3 bucket but it's easier simply to install 
        # python natively
        # if [ -d "${downloadPath}/${platform}/${pythonName}" ]; then 
        #    rm -rf "${downloadPath}/${platform}/${pythonName}"
        # fi

        # Force overwrite
        if [ -d "${installPath}" ]; then 
            rm -rf "${installPath}"
        fi
    fi

    # =========================================================================
    # 1. Install Python. Using deadsnakes for Linux (not macOS), so be aware if
    #    you have concerns about potential late adoption of security patches.

     if [ $verbosity == "loud" ]; then
        writeLine "Python install path is ${installPath}" $color_info
     fi

     if [ ! -d "${installPath}" ]; then
        if [ "$platform" == "macos" ] || [ "$platform" == "macos-arm" ]; then
            mkdir -p "${installPath}"
        else
            mkdir -p "${installPath}"
        fi
     fi

     pythonCmd="python${pythonVersion}"
     if command -v $pythonCmd &> /dev/null; then
         writeLine "Python ${pythonVersion} is already installed" $color_success
     else

        # For macOS we'll use brew to install python
        if [ "$platform" == "macos" ] || [ "$platform" == "macos-arm" ]; then

            # We first need to ensure GCC is installed. 
            write "Checking for GCC and xcode tools..." $color_primary
            xcode-select -p >/dev/null  2>/dev/null
            if [ $? -ne 0 ]; then
                writeLine "Requesting install." $color_info
                xcode-select --install
            else
                writeLine "present" $color_success
            fi

            write "Installing Python ${pythonVersion}..." $color_primary

            if [ "$platform" == "macos-arm" ]; then

                # Apple silicon requires Rosetta2 for python to run, so use the
                # x86 version of Brew we installed earlier
                if [ "${verbosity}" == "quiet" ]; then
                    arch -x86_64 /usr/local/bin/brew install python@${pythonVersion}  >/dev/null 2>/dev/null &
                    spin $!
                else
                    arch -x86_64 /usr/local/bin/brew install python@${pythonVersion}
                fi

                # Note that we only need the specific location of the python 
                # interpreter to setup  the virtual environment. After it's 
                # setup, all python calls are relative to the same venv no 
                # matter the location of the original python interpreter
                pythonCmd="/usr/local/opt/python@${pythonVersion}/bin/python${pythonVersion}"

            else

                # We have a x64 version of python for macOS in our S3 bucket
                # but it's easier simply to install python natively

                # Download $storageUrl $downloadPath "python3.7.12-osx64.tar.gz" \
                #                   "${platform}/${pythonDir}" "Downloading Python interpreter..."
                # cp -R "${downloadPath}/${platform}/${pythonDir}" "${analysisLayerPath}/bin/${platform}"

                if [ "${verbosity}" == "quiet" ]; then
                    brew install python@${pythonVersion}  >/dev/null 2>/dev/null &
                    spin $!
                else
                    brew install python@${pythonVersion}
                fi

                # Brew specific path
                pythonCmd="/usr/local/opt/python@${pythonVersion}/bin/python${pythonVersion}"

            fi

            writeLine "Done" $color_success

        # For Linux we'll use apt-get the deadsnakes PPA to get the old version
        # of python. Deadsnakes? Old python? Get it? Get it?! And who said 
        # developers have no sense of humour.
        else

            if [ ! "${verbosity}" == "loud" ]; then

                write "Installing Python ${pythonVersion}..." $color_primary

                if [ "${verbosity}" == "info" ]; then writeLine "Updating apt-get" $color_info; fi;
                sudo apt-get update -y >/dev/null 2>/dev/null &
                spin $!

                if [ "${verbosity}" == "info" ]; then writeLine "Installing software-properties-common" $color_info; fi;
                sudo apt install software-properties-common -y >/dev/null 2>/dev/null &
                spin $!

                if [ "${verbosity}" == "info" ]; then writeLine "Adding deadsnakes as a Python install source (PPA)" $color_info; fi;
                sudo add-apt-repository ppa:deadsnakes/ppa -y >/dev/null 2>/dev/null &
                spin $!

                if [ "${verbosity}" == "info" ]; then writeLine "Updating apt" $color_info; fi;
                apt update -y >/dev/null 2>/dev/null &
                spin $!

                if [ "${verbosity}" == "info" ]; then writeLine "Installing Python ${pythonVersion}" $color_info; fi;
                sudo apt-get install python${pythonVersion} -y >/dev/null 2>/dev/null &
                spin $!

                # apt-get install python3-pip
                writeLine "Done" $color_success
            else
                writeLine "Updating apt-get" $color_info
                sudo apt-get update -y
                writeLine "Installing software-properties-common" $color_info
                sudo apt install software-properties-common -y
                writeLine "Adding deadsnakes as a Python install source (PPA)" $color_info
                sudo add-apt-repository ppa:deadsnakes/ppa -y
                writeLine "Updating apt" $color_info
                sudo apt update -y
                writeLine "Installing Python ${pythonVersion}" $color_primary
                sudo apt-get install python${pythonVersion} -y
                sudo apt-get install python3-pip
                writeLine "Done" $color_success
            fi
        fi
    fi

    # =========================================================================
    # 2. Create Virtual Environment

    if [ -d  "${installPath}/venv" ]; then
        writeLine "Virtual Environment already present" $color_success
    else

        # Before we start we need to ensure we can create a Virtual environment
        # that has the the correct tools, pip being the most important.
        #
        # The process is different between macOS and Ubuntu due to how we've 
        # installed python, The following code is messy (sorry) in order to 
        # handle both cases as well as quiet / not quiet output. Critical when 
        # trying to debug issues.
        #
        # If venv creation fails, ensure you remove the old venv folder before 
        # trying again

        if [ "$platform" == "macos" ] || [ "$platform" == "macos-arm" ]; then
            if [ "${verbosity}" == "quiet" ]; then
                write "Installing Virtual Environment tools for mac..." $color_primary
                pip3 $pipFlags install virtualenv virtualenvwrapper >/dev/null &
                spin $!
                writeLine "Done" $color_success

            else
                writeLine "Installing Virtual Environment tools for mac..." $color_primary
        
                # regarding the warning: See https://github.com/Homebrew/homebrew-core/issues/76621
                if [ $(versionCompare "${pythonVersion}" '3.10.2') == "-1" ]; then
                    writeLine "Ignore the DEPRECATION warning. See https://github.com/Homebrew/homebrew-core/issues/76621 for details" $color_info
                fi

                pip3 $pipFlags install virtualenv virtualenvwrapper
            fi
        else
            if [ "${verbosity}" == "quiet" ]; then
                write "Installing Virtual Environment tools for Linux..." $color_primary

                # just in case - but doesn't seem to be effective
                # writeLine
                # writeLine "First: correcting broken installs".
                # apt --fix-broken install

                apt install python3-pip python3-setuptools python${pythonVersion}-venv >/dev/null 2>/dev/null &
                spin $!
                writeLine "Done" $color_success
            else
                writeLine "Installing Virtual Environment tools for Linux..." $color_primary
                apt install python3-pip python3-setuptools python${pythonVersion}-venv
            fi
        fi

        # Create the virtual environments. All sorts of things can go wrong here
        # but if you have issues, make sure you delete the venv directory before
        # retrying.
        write "Creating Virtual Environment..." $color_primary
        
        if [ $verbosity == "loud" ]; then
            writeLine "Install path is ${installPath}"
        fi

        if [ "$platform" == "macos" ] || [ "$platform" == "macos-arm" ]; then
            ${pythonCmd} -m venv "${installPath}/venv"
        else          
            ${pythonCmd} -m venv "${installPath}/venv" &
            spin $! # process ID of the python install call
        fi
        writeLine "Done" $color_success
    fi

    # our DIY version of Python 'Activate' for virtual environments
    pushd "${installPath}" >/dev/null
    venvPath="$(pwd)/venv"
    pythonInterpreterPath="${venvPath}/bin/python3"
    popd >/dev/null

    # Ensure Python Exists
    write "Checking for Python ${pythonVersion}..." $color_primary
    pyVersion=$($pythonInterpreterPath --version)
    write "Found ${pyVersion}. " $color_mute

    echo $pyVersion | grep "${pythonVersion}" >/dev/null
    if [ $? -ne 0 ]; then
        errorNoPython
    fi 
    writeLine "present" $color_success
}

function installPythonPackages () {

    # Whether or not to install all python packages in one step (ie use 
    # -r requirements.txt) or step by step
    oneStepPIP="false"

    pythonVersion=$1
    requirementsDir=$2
    testForPipExistanceName=$3

    # Version with ".'s removed
    local pythonName="python${pythonVersion/./}"
    pythonCmd="python${pythonVersion}"

    # Brew doesn't set PATH by default (nor do we need it to) which means we 
    # just have to be careful
    if [ "$platform" == "macos" ] || [ "$platform" == "macos-arm" ]; then
        
        # If running "PythonX.Y" doesn't actually work, then let's adjust the
        # command to point to where we think the python launcher should be
        python${pythonVersion} --version >/dev/null  2>/dev/null
        if [ $? -ne 0 ]; then
            # writeLine "Did not find python in default location"
            pythonCmd="/usr/local/opt/python@${pythonVersion}/bin/python${pythonVersion}"
        fi
    fi

    # Check for requirements.platform.[CUDA].txt first, then fall back to
    # requirements.txt

    requirementsFilename=""

    if [ "!enableGPU!" == "true" ]; then
        if [ "$hasCUDA" == "true" ]; then
            if [ -f "${requirementsDir}/requirements.${platform}.cuda.txt" ]; then
                requirementsFilename="requirements.${platform}.cuda.txt"
            elif [ -f "${requirementsDir}/requirements.cuda.txt" ]; then
                requirementsFilename="requirements.cuda.txt"
            fi
        fi

        if [ "$requirementsFilename" == "" ]; then
            if [ -f "${requirementsDir}/requirements.${platform}.gpu.txt" ]; then
                requirementsFilename="requirements.${platform}.gpu.txt"
            elif [ -f "${requirementsDir}/requirements.gpu.txt" ]; then
                requirementsFilename="requirements.gpu.txt"
            fi
        fi
    fi

    if [ "$requirementsFilename" == "" ]; then
        if [ -f "${requirementsDir}/requirements.${platform}.txt" ]; then
            requirementsFilename="requirements.${platform}.txt"
        elif [ -f "${requirementsDir}/requirements.txt" ]; then
            requirementsFilename="requirements.txt"
        fi
    fi

    if [ "$requirementsFilename" != "" ]; then
        requirementsPath="${requirementsDir}/${requirementsFilename}"
    fi

    if [ "$requirementsFilename" == "" ]; then
        writeLine "No suitable requirements.txt file found." $color_warn
        return
    fi

    if [ ! -f "$requirementsPath" ]; then
        writeLine "Can't find ${requirementsPath} file." $color_warn
        return
    fi

    virtualEnv="${analysisLayerPath}/bin/${platform}/${pythonName}/venv"

    pushd "${virtualEnv}/bin"  >/dev/null

    # Before installing packages, check to ensure PIP is installed and up to 
    # date. This slows things down a bit, but it's worth it in the end.
    if [ "${verbosity}" == "quiet" ]; then

        # Ensure we have pip (no internet access - ensures we have the current
        # python compatible version.
        write "Ensuring PIP is installed..." $color_primary
        ./python3 -m ensurepip  >/dev/null 2>/dev/null &
        spin $!
        writeLine "Done" $color_success

        write "Updating PIP..." $color_primary
        ./python3 -m pip install --upgrade pip >/dev/null 2>/dev/null &
        spin $!
        writeLine "Done" $color_success
    else
        writeLine "Ensuring PIP is installed and up to date..." $color_primary
    
       if [ "$platform" == "macos" ] || [ "$platform" == "macos-arm" ]; then
            # regarding the warning: See https://github.com/Homebrew/homebrew-core/issues/76621
            if [ $(versionCompare "${pythonVersion}" '3.10.2') == "-1" ]; then
                writeLine "Ignore the DEPRECATION warning. See https://github.com/Homebrew/homebrew-core/issues/76621 for details" $color_info
            fi
        fi
    
        ./python3 -m ensurepip
        ./python3 -m pip install --upgrade pip
    fi 
    popd  >/dev/null

    # =========================================================================
    # Install PIP packages

    # debug
    # writeLine "Installing PIP from ${requirementsPath}" $color_error
    # writeLine "Checking ${packagesPath}/${testForPipExistanceName}" $color_error

    write "Checking for required packages..." $color_primary

    # ASSUMPTION: If a folder by the name of "testForPipExistanceName" exists
    # in the site-packages directory then we assume the requirements.txt file 
    # has already been processed.
    # TODO: Each module has its own venv

    packagesPath="${virtualEnv}/lib/python${pythonVersion}/site-packages/"

    if [ "${testForPipExistanceName}" == "" ] || [ ! -d "${packagesPath}/${testForPipExistanceName}" ]; then

        writeLine "Installing packages in ${requirementsFilename}" $color_info

        pushd "${virtualEnv}/bin"  >/dev/null
        if [ "${oneStepPIP}" == "true" ]; then

            # Install the Python Packages in one fell swoop. Not much feedback, but it works
            write "Installing Packages into Virtual Environment..." $color_primary
            if [ "${verbosity}" != "loud" ]; then
                # writeLine "${pythonCmd} -m pip install $pipFlags -r ${requirementsPath} --target ${packagesPath}" $color_info
                ./pip install $pipFlags -r ${requirementsPath} --target ${packagesPath} > /dev/null &
                spin $!
            else
                ./pip install $pipFlags -r ${requirementsPath} --target ${packagesPath}
            fi
            writeLine "Success" $color_success

        else

            # Open requirements.txt and grab each line. We need to be careful with --find-links lines
            # as this doesn't currently work in Linux
            currentOption=""

            IFS=$'\n' # set the Internal Field Separator as end of line
            cat "${requirementsPath}" | while read -r line
            do

                line="$(echo $line | tr -d '\r\n')"    # trim newlines / CRs

                if [ "${line}" == "" ]; then
                    currentOption=""
                elif [ "${line:0:1}" == "#" ]; then
                    currentOption=""
                elif [ "${line:0:1}" == "-" ]; then
                    currentOption="${currentOption} ${line}"
                else
            
                    module="${line}"
                    description=""

                    # breakup line into module name and description
                    IFS='#'; tokens=($module); IFS=$'\n';

                    if [ ${#tokens[*]} -gt 1 ]; then
                        module="${tokens[0]}"
                        description="${tokens[1]}"
                    fi

                    if [ "${description}" == "" ]; then
                        description="Installing ${module}"
                    fi
        
                    # remove all whitespaces
                    module="${module// /}"

                    if [ "${module}" != "" ]; then

                        # writeLine "./pip install ${pipFlags} $module ${currentOption}" $color_error
                        write "  -${description}..." $color_primary

                        # TODO: We should test first. Alter the requirements file to provide the 
                        # name of a module (module_import) to be tested before we import
                        # if python3 -c "import ${module_import}"; then echo "Found ${module}. Skipping."; fi;

                        if [ "${verbosity}" != "loud" ]; then
                            # I have NO idea why it's necessary to use eval to get this to work without errors
                            # ./pip3 install ${module} ${currentOption} >/dev/null & # 2>/dev/null &
                            eval "./pip3 install ${module} ${currentOption}" >/dev/null &
                            spin $!
                        else
                            # ./pip3 install $module ${currentOption}
                            eval "./pip3 install ${module} ${currentOption}"
                        fi

                        status=$?    
                        if [ $status -eq 0 ]; then
                            writeLine "Done" $color_success
                        else
                            writeLine "Failed" $color_error
                        fi
                    fi

                    currentOption=""

                fi

            done
            unset IFS
        fi
        popd  >/dev/null

    else
        writeLine "${testForPipExistanceName} present." $color_success
    fi
}

function getFromServer () {

    # eg packages_for_gpu.zip
    local fileToGet=$1

    # eg assets
    local moduleAssetsDir=$2

    # output message
    local message=$3

    # Clean up directories to force a re-copy if necessary
    if [ "${forceOverwrite}" == "true" ]; then
        # if [ $verbosity -ne "quiet" ]; then echo "Forcing overwrite"; fi

        rm -rf "${downloadPath}/${moduleDir}"
        rm -rf "${modulePath}/${moduleAssetsDir}"
    fi

    # Download !$storageUrl$fileToGet to $downloadPath and extract into $downloadPath/$moduleDir
    # Params are: S3 storage bucket | fileToGet     | downloadToDir     | dirToSaveTo | message
    # eg           "$S3_bucket"   "rembg-models.zip" /downloads/module/"    "assets"    "Downloading Background Remover models..."
    downloadAndExtract $storageUrl $fileToGet "${downloadPath}" "${moduleDir}" "${message}"

    # Copy contents of downloadPath\moduleDir to analysisLayerPath\moduleDir\moduleAssetsDir
    if [ -d "${downloadPath}/${moduleDir}" ]; then

        if [ ! -d "${modulePath}/${moduleAssetsDir}" ]; then
            mkdir -p "${modulePath}/${moduleAssetsDir}"
        fi;

        # pushd then cp to stop "cannot stat" error
        pushd "${downloadPath}/${moduleDir}/" >/dev/null 2>/dev/null

        # This code will have issues if you download more than 1 zip to a download folder.
        # 1. Copy *everything* over (including the downloaded zip)        
        # 2. Remove the original download archive which was copied over along with everything else.
        # 3. Delete all but the downloaded archive from the downloads dir
        # cp * "${modulePath}/${moduleAssetsDir}/"
        # rm "${modulePath}/${moduleAssetsDir}/${fileToGet}"  #>/dev/null 2>/dev/null
        # ls | grep -xv *.zip | xargs rm

        # Safer.
        # 1. Copy all non-zip files to the module's installation dir
        # 2. Delete all non-zip files in the download dir
        find . -type f -not -name '*.zip' -not -name '.DS_Store' | xargs -I %f cp %f "${modulePath}/${moduleAssetsDir}/"
        find . -type f -not -name '*.zip' | xargs rm

        popd >/dev/null 2>/dev/null
    fi
}

function downloadAndExtract () {

    local storageUrl=$1
    local fileToGet=$2
    local downloadToDir=$3
    local dirToSave=$4
    local message=$5

    # storageUrl = 'https://codeproject-ai.s3.ca-central-1.amazonaws.com/sense/installer/dev/'
    # downloadToDir = 'downloads/' - relative to the current directory
    # fileToGet = packages_for_gpu.zip
    # dirToSave = packages
   
    if [ "${fileToGet}" == "" ]; then
        writeLine 'No download file was specified' $color_error
        quit    # no point in carrying on
    fi

    if [ "${message}" == "" ]; then
        message="Downloading ${fileToGet}..."
    fi

    if [ $verbosity != "quiet" ]; then 
        writeLine "Downloading ${fileToGet} to ${downloadToDir}/${dirToSave}" $color_info
    fi
    
    write "$message" $color_primary

    extension="${fileToGet:(-3)}"
    if [ ! "${extension}" == ".gz" ]; then
        extension="${fileToGet:(-4)}"
        if [ ! "${extension}" == ".zip" ]; then
            writeLine "Unknown and unsupported file type for file ${fileToGet}" $color_error
            quit    # no point in carrying on
        fi
    fi

    if [ -f  "${downloadToDir}/${dirToSave}/${fileToGet}" ]; then     # To check for the download itself
        write " already exists..." $color_info
    else
        # writeLine "Downloading ${fileToGet} to ${dirToSave}.zip in ${downloadToDir}"  $color_warn
        # wget $wgetFlags --show-progress -O "${downloadToDir}/${dirToSave}/${fileToGet}" -P "${downloadToDir}/${dirToSave}" \
        #                                   "${storageUrl}${fileToGet}"

        wget $wgetFlags --show-progress -P "${downloadToDir}/${dirToSave}" "${storageUrl}${fileToGet}"
        status=$?    
        if [ $status -ne 0 ]; then
            writeLine "The wget command failed for file ${fileToGet}." $color_error
            quit    # no point in carrying on
        fi
    fi

    if [ ! -f  "${downloadToDir}/${dirToSave}/${fileToGet}" ]; then
        writeLine "The downloaded file '${fileToGet}' doesn't appear to exist." $color_error
        quit    # no point in carrying on
    fi

    write 'Expanding...' $color_info

    pushd "${downloadToDir}/${dirToSave}" >/dev/null
  
    if [ "${extension}" == ".gz" ]; then
        tar $tarFlags "${fileToGet}" &  # execute and continue
    else
        unzip $unzipFlags -u "${fileToGet}" &  # execute and continue
    fi
    
    spin $! # process ID of the unzip/tar call

    if [ ! "$(ls -A .)" ]; then # Is the download dir empty?
        writeLine "Unable to extract download. Can you please check you have write permission to "${dirToSave}"." $color_error
        popd >/dev/null
        quit    # no point in carrying on
    fi
    
    # Remove thw downloaded zip
    # rm -f "${fileToGet}" >/dev/null

    popd >/dev/null

    writeLine 'Done.' $color_success
}

# Thanks: https://stackoverflow.com/a/4025065 with mods
# compares two version numbers (eg 3.9.12 < 3.10.1)
versionCompare () {
 
      # trivial equal case
    if [[ $1 == $2 ]]; then
        echo "0"
        return 0
    fi
 
    local IFS=.
    local i ver1=($1) ver2=($2)

    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done

    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi

        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            echo "1" # $1 > $2
            return 0
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            echo "-1" # $1 < $2
            return 0
        fi
    done

    echo "0"
}

function getDisplaySize () {
    # See https://linuxcommand.org/lc3_adv_tput.php some great tips around this
    echo "Rows=$(tput lines) Cols=$(tput cols)"
}

function displayMacOSDirCreatePermissionError () {
    writeLine
    writeLine "Unable to Create a Directory"  $color_error

    if [[ $OSTYPE == 'darwin'* ]]; then

       local commonDir=$1

        writeLine
        writeLine "But we may be able to suggest something:"  $color_info

        # Note that  will appear as the Apple symbol on macOS, but probably not on Windows or Linux
        writeLine '1. Pull down the  Apple menu and choose "System Preferences"'
        writeLine '2. Choose “Security & Privacy” control panel'
        writeLine '3. Now select the “Privacy” tab, then from the left-side menu select'
        writeLine '   “Full Disk Access”'
        writeLine '4. Click the lock icon in the lower left corner of the preference '
        writeLine '   panel and authenticate with an admin level login'
        writeLine '5. Now click the [+] plus button so we can full disk access to Terminal'
        writeLine "6. Navigate to the /Applications/Utilities/ folder and choose 'Terminal'"
        writeLine '   to grant Terminal Full Disk Access privileges'
        writeLine '7. Relaunch Terminal, the “Operation not permitted” error messages should'
        writeLine '   be gone'
        writeLine
        writeLine 'Thanks to https://osxdaily.com/2018/10/09/fix-operation-not-permitted-terminal-error-macos/'
    fi

    quit
}

function needRosettaAndiBrew () {

    writeLine
    writeLine "You're on an Mx Mac running ARM but Python3 only works on Intel."  $color_error
    writeLine "You will need to install Rosetta2 to continue."  $color_error
    writeLine
    read -p 'Install Rosetta2 (Y/N)?' installRosetta
    if [ "${installRosetta}" == "y" ] || [ "${installRosetta}" == "Y" ]; then
        /usr/sbin/softwareupdate --install-rosetta --agree-to-license
    else
        quit
    fi

    writeLine "Then you need to install brew under Rosetta (We'll alias it as ibrew)"
    read -p 'Install brew for x86 (Y/N)?' installiBrew
    if [ "${installiBrew}" == "y" ] || [ "${installiBrew}" == "Y" ]; then
        arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    else
        quit
    fi
}


function quit () {

    if [ "${useColor}" == "true" ] && [ "${darkmode}" == "true" ]; then
        # this resets the terminal, but also clears the screen which isn't great
        # tput reset
        echo
    fi
    exit
}


# Platform can define where things are located
if [[ $OSTYPE == 'darwin'* ]]; then
    if [[ $(uname -p) == 'arm' ]]; then
        platform='macos-arm'
    else
        platform='macos'
    fi
else
    platform='linux'
fi

darkmode=$(isDarkMode)
echo "Darkmode? ${darkmode}"

# Setup some predefined colours. Note that we can't reliably determine the background 
# color of the terminal so we avoid specifically setting black or white for the foreground
# or background. You can always just use "White" and "Black" if you specifically want
# this combo, but test thoroughly
if [ "$darkmode" == "true" ]; then
    color_primary='White'
    color_mute='Gray'
    color_info='Yellow'
    color_success='Green'
    color_warn='DarkYellow'
    color_error='Red'
else
    color_primary='Black'
    color_mute='Gray'
    color_info='Magenta'
    color_success='DarkGreen'
    color_warn='DarkYellow'
    color_error='Red'
fi