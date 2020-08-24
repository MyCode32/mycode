#!/usr/bin/env bash

# ============================================================ #
# ================== < mycode Parameters > ================== #
# ============================================================ #
# Path to directory containing the mycode executable script.
readonly mycodePath=$(dirname $(readlink -f "$0"))

# Path to directory containing the mycode library (scripts).
readonly mycodeLibPath="$mycodePath/lib"

# Path to the temp. directory available to mycode & subscripts.
readonly mycodeWorkspacePath="/tmp/mycodespace"
readonly mycodeIPTablesBackup="$mycodePath/iptables-rules"

# Path to mycode's preferences file, to be loaded afterward.
readonly mycodePreferencesFile="$mycodePath/preferences/preferences.conf"

# Constants denoting the reference noise floor & ceiling levels.
# These are used by the the wireless network scanner visualizer.
readonly mycodeNoiseFloor=-90
readonly mycodeNoiseCeiling=-60

readonly mycodeVersion=6
readonly mycodeRevision=9

# Declare window ration bigger = smaller windows
mycodeWindowRatio=4

# Allow to skip dependencies if required, not recommended
mycodeSkipDependencies=1

# Check if there are any missing dependencies
mycodeMissingDependencies=0

# Allow to use 5ghz support
mycodeEnable5GHZ=0

# ============================================================ #
# ================= < Script Sanity Checks > ================= #
# ============================================================ #
if [ $EUID -ne 0 ]; then # Super User Check
  echo -e "\\033[31mAborted, please execute the script as root.\\033[0m"; exit 1
fi

# ===================== < XTerm Checks > ===================== #
# TODO: Run the checks below only if we're not using tmux.
if [ ! "${DISPLAY:-}" ]; then # Assure display is available.
  echo -e "\\033[31mAborted, X (graphical) session unavailable.\\033[0m"; exit 2
fi

if ! hash xdpyinfo 2>/dev/null; then # Assure display probe.
  echo -e "\\033[31mAborted, xdpyinfo is unavailable.\\033[0m"; exit 3
fi

if ! xdpyinfo &>/dev/null; then # Assure display info available.
  echo -e "\\033[31mAborted, xterm test session failed.\\033[0m"; exit 4
fi

# ================ < Parameter Parser Check > ================ #
getopt --test > /dev/null # Assure enhanced getopt (returns 4).
if [ $? -ne 4 ]; then
  echo "\\033[31mAborted, enhanced getopt isn't available.\\033[0m"; exit 5
fi

# =============== < Working Directory Check > ================ #
if ! mkdir -p "$mycodeWorkspacePath" &> /dev/null; then
  echo "\\033[31mAborted, can't generate a workspace directory.\\033[0m"; exit 6
fi

# Once sanity check is passed, we can start to load everything.

# ============================================================ #
# =================== < Library Includes > =================== #
# ============================================================ #
source "$mycodeLibPath/installer/InstallerUtils.sh"
source "$mycodeLibPath/InterfaceUtils.sh"
source "$mycodeLibPath/SandboxUtils.sh"
source "$mycodeLibPath/FormatUtils.sh"
source "$mycodeLibPath/ColorUtils.sh"
source "$mycodeLibPath/IOUtils.sh"
source "$mycodeLibPath/HashUtils.sh"
source "$mycodeLibPath/HelpUtils.sh"

# NOTE: These are configured after arguments are loaded (later).

# ============================================================ #
# =================== < Parse Parameters > =================== #
# ============================================================ #
if ! mycodeCLIArguments=$(
    getopt --options="vdk5rinmthb:e:c:l:a:r" \
      --longoptions="debug,version,killer,5ghz,installer,reloader,help,airmon-ng,multiplexer,target,test,auto,bssid:,essid:,channel:,language:,attack:,ratio,skip-dependencies" \
      --name="mycode V$mycodeVersion.$mycodeRevision" -- "$@"
  ); then
  echo -e "${CRed}Aborted$CClr, parameter error detected..."; exit 5
fi

AttackCLIArguments=${mycodeCLIArguments##* -- }
readonly mycodeCLIArguments=${mycodeCLIArguments%%-- *}
if [ "$AttackCLIArguments" = "$mycodeCLIArguments" ]; then
  AttackCLIArguments=""
fi


# ============================================================ #
# ================== < Load Configurables > ================== #
# ============================================================ #

# ============= < Argument Loaded Configurables > ============ #
eval set -- "$mycodeCLIArguments" # Set environment parameters.

#[ "$1" != "--" ] && readonly mycodeAuto=1 # Auto-mode if using CLI.
while [ "$1" != "" ] && [ "$1" != "--" ]; do
  case "$1" in
    -v|--version) echo "mycode V$mycodeVersion.$mycodeRevision"; exit;;
    -h|--help) mycode_help; exit;;
    -d|--debug) readonly mycodeDebug=1;;
    -k|--killer) readonly mycodeWIKillProcesses=1;;
    -5|--5ghz) mycodeEnable5GHZ=1;;
    -r|--reloader) readonly mycodeWIReloadDriver=1;;
    -n|--airmon-ng) readonly mycodeAirmonNG=1;;
    -m|--multiplexer) readonly mycodeTMux=1;;
    -b|--bssid) mycodeTargetMAC=$2; shift;;
    -e|--essid) mycodeTargetSSID=$2;
      # TODO: Rearrange declarations to have routines available for use here.
      mycodeTargetSSIDClean=$(echo "$mycodeTargetSSID" | sed -r 's/( |\/|\.|\~|\\)+/_/g'); shift;;
    -c|--channel) mycodeTargetChannel=$2; shift;;
    -l|--language) mycodeLanguage=$2; shift;;
    -a|--attack) mycodeAttack=$2; shift;;
    -i|--install) mycodeSkipDependencies=0; shift;;
    --ratio) mycodeWindowRatio=$2; shift;;
    --auto) readonly mycodeAuto=1;;
    --skip-dependencies) readonly mycodeSkipDependencies=1;;
  esac
  shift # Shift new parameters
done

shift # Remove "--" to prepare for attacks to read parameters.
# Executable arguments are handled after subroutine definition.

# =================== < User Preferences > =================== #
# Load user-defined preferences if there's an executable script.
# If no script exists, prepare one for the user to store config.
# WARNING: Preferences file must assure no redeclared constants.
if [ -x "$mycodePreferencesFile" ]; then
  source "$mycodePreferencesFile"
else
  echo '#!/usr/bin/env bash' > "$mycodePreferencesFile"
  chmod u+x "$mycodePreferencesFile"
fi

# ================ < Configurable Constants > ================ #
if [ "$mycodeAuto" != "1" ]; then # If defined, assure 1.
  readonly mycodeAuto=${mycodeAuto:+1}
fi

if [ "$mycodeDebug" != "1" ]; then # If defined, assure 1.
  readonly mycodeDebug=${mycodeDebug:+1}
fi

if [ "$mycodeAirmonNG" != "1" ]; then # If defined, assure 1.
  readonly mycodeAirmonNG=${mycodeAirmonNG:+1}
fi

if [ "$mycodeWIKillProcesses" != "1" ]; then # If defined, assure 1.
  readonly mycodeWIKillProcesses=${mycodeWIKillProcesses:+1}
fi

if [ "$mycodeWIReloadDriver" != "1" ]; then # If defined, assure 1.
  readonly mycodeWIReloadDriver=${mycodeWIReloadDriver:+1}
fi

# mycodeDebug [Normal Mode "" / Developer Mode 1]
if [ $mycodeDebug ]; then
  :> /tmp/mycode.debug.log
  readonly mycodeOutputDevice="/tmp/mycode.debug.log"
  readonly mycodeHoldXterm="-hold"
else
  readonly mycodeOutputDevice=/dev/null
  readonly mycodeHoldXterm=""
fi

# ================ < Configurable Variables > ================ #
readonly mycodePromptDefault="$CRed[${CSBlu}mycode$CSYel@$CSWht$HOSTNAME$CClr$CRed]-[$CSYel~$CClr$CRed]$CClr "
mycodePrompt=$mycodePromptDefault

readonly mycodeVLineDefault="$CRed[$CSYel*$CClr$CRed]$CClr"
mycodeVLine=$mycodeVLineDefault

# ================== < Library Parameters > ================== #
readonly InterfaceUtilsOutputDevice="$mycodeOutputDevice"

readonly SandboxWorkspacePath="$mycodeWorkspacePath"
readonly SandboxOutputDevice="$mycodeOutputDevice"

readonly InstallerUtilsWorkspacePath="$mycodeWorkspacePath"
readonly InstallerUtilsOutputDevice="$mycodeOutputDevice"
readonly InstallerUtilsNoticeMark="$mycodeVLine"

readonly PackageManagerLog="$InstallerUtilsWorkspacePath/package_manager.log"

declare  IOUtilsHeader="mycode_header"
readonly IOUtilsQueryMark="$mycodeVLine"
readonly IOUtilsPrompt="$mycodePrompt"

readonly HashOutputDevice="$mycodeOutputDevice"

# ============================================================ #
# =================== < Default Language > =================== #
# ============================================================ #
# Set by default in case mycode is aborted before setting one.
source "$mycodePath/language/en.sh"

# ============================================================ #
# ================== < Startup & Shutdown > ================== #
# ============================================================ #
mycode_startup() {
  if [ "$mycodeDebug" ]; then return 1; fi

  # Make sure that we save the iptable files
  iptables-save >"$mycodeIPTablesBackup"
  local banner=()

 format_center_literals " 888b     d888         .d8888b.              888         .d8888b. "; local banner+=("$FormatCenterLiterals");  
format_center_literals " 8888b   d8888        d88P  Y88b             888        d88P  Y88b "; local banner+=("$FormatCenterLiterals");
format_center_literals " 88888b.d88888        888    888             888             .d88P "; local banner+=("$FormatCenterLiterals");
format_center_literals " 888Y88888P888888  888888        .d88b.  .d88888 .d88b.     8888" "; local banner+=("$FormatCenterLiterals"); 
format_center_literals " 888 Y888P 888888  888888       d88""88bd88" 888d8P  Y8b     "Y8b. "; local banner+=("$FormatCenterLiterals");
format_center_literals " 888  Y8P  888888  888888    888888  888888  88888888888888    888 "; local banner+=("$FormatCenterLiterals");
format_center_literals " 888   "   888Y88b 888Y88b  d88PY88..88PY88b 888Y8b.    Y88b  d88P "; local banner+=("$FormatCenterLiterals");
format_center_literals " 888       888 "Y88888 "Y8888P"  "Y88P"  "Y88888 "Y8888  "Y8888P"  "; local banner+=("$FormatCenterLiterals");
format_center_literals "                   888  										   "; local banner+=("$FormatCenterLiterals");                                           
 format_center_literals "             Y8b d88P                                             "; local banner+=("$FormatCenterLiterals");                                           
 format_center_literals "              "Y88P"                                              "; local banner+=("$FormatCenterLiterals"); 

  clear

  if [ "$mycodeAuto" ]; then echo -e "$CBlu"; else echo -e "$CRed"; fi

  for line in "${banner[@]}"; do
    echo "$line"; sleep 0.05
  done

  echo # Do not remove.

  sleep 0.1
  local -r mycodeRepository="https://github.com/mycodeNetwork/mycode"
  format_center_literals "${CGrn}Site: ${CRed}$mycodeRepository$CClr"
  echo -e "$FormatCenterLiterals"

  sleep 0.1
  local -r versionInfo="${CSRed}mycode $mycodeVersion$CClr"
  local -r revisionInfo="rev. $CSBlu$mycodeRevision$CClr"
  local -r credits="by$CCyn mycodeNetwork$CClr"
  format_center_literals "$versionInfo $revisionInfo $credits"
  echo -e "$FormatCenterLiterals"

  sleep 0.1
  local -r mycodeDomain="raw.githubusercontent.com"
  local -r mycodePath="mycodeNetwork/mycode/master/mycode.sh"
  local -r updateDomain="github.com"
  local -r updatePath="mycodeNetwork/mycode/archive/master.zip"
  if installer_utils_check_update "https://$mycodeDomain/$mycodePath" \
    "mycodeVersion=" "mycodeRevision=" \
    $mycodeVersion $mycodeRevision; then
    if installer_utils_run_update "https://$updateDomain/$updatePath" \
      "mycode-V$mycodeVersion.$mycodeRevision" "$mycodePath"; then
      mycode_shutdown
    fi
  fi

  echo # Do not remove.

  local requiredCLITools=(
    "aircrack-ng" "bc" "awk:awk mawk"
    "curl" "cowpatty" "7zr:p7zip" "hostapd" "lighttpd"
    "iwconfig:wireless-tools" "macchanger" "mdk4" "dsniff" "mdk3" "nmap" "openssl"
    "php-cgi" "xterm" "rfkill" "unzip" "route:net-tools"
    "fuser:psmisc" "killall:psmisc"
  )

    while ! installer_utils_check_dependencies requiredCLITools[@]; do
        if ! installer_utils_run_dependencies InstallerUtilsCheckDependencies[@]; then
            echo
            echo -e "${CRed}Dependency installation failed!$CClr"
            echo    "Press enter to retry, ctrl+c to exit..."
            read -r bullshit
        fi
    done
    if [ $mycodeMissingDependencies -eq 1 ]  && [ $mycodeSkipDependencies -eq 1 ];then
        echo -e "\n\n"
        format_center_literals "[ ${CSRed}Missing dependencies: try to install using ./mycode.sh -i${CClr} ]"
        echo -e "$FormatCenterLiterals"; sleep 3

        exit 7
    fi

  echo -e "\\n\\n" # This echo is for spacing
}

mycode_shutdown() {
  if [ $mycodeDebug ]; then return 1; fi

  # Show the header if the subroutine has already been loaded.
  if type -t mycode_header &> /dev/null; then
    mycode_header
  fi

  echo -e "$CWht[$CRed-$CWht]$CRed $mycodeCleanupAndClosingNotice$CClr"

  # Get running processes we might have to kill before exiting.
  local processes
  readarray processes < <(ps -A)

  # Currently, mycode is only responsible for killing airodump-ng, since
  # mycode explicitly uses it to scan for candidate target access points.
  # NOTICE: Processes started by subscripts, such as an attack script,
  # MUST BE TERMINATED BY THAT SCRIPT in the subscript's abort handler.
  local -r targets=("airodump-ng")

  local targetID # Program identifier/title
  for targetID in "${targets[@]}"; do
    # Get PIDs of all programs matching targetPID
    local targetPID
    targetPID=$(
      echo "${processes[@]}" | awk '$4~/'"$targetID"'/{print $1}'
    )
    if [ ! "$targetPID" ]; then continue; fi
    echo -e "$CWht[$CRed-$CWht] `io_dynamic_output $mycodeKillingProcessNotice`"
    kill -s SIGKILL $targetPID &> $mycodeOutputDevice
  done

  # Assure changes are reverted if installer was activated.
  if [ "$PackageManagerCLT" ]; then
    echo -e "$CWht[$CRed-$CWht] "$(
      io_dynamic_output "$mycodeRestoringPackageManagerNotice"
    )"$CClr"
    # Notice: The package manager has already been restored at this point.
    # InstallerUtils assures the manager is restored after running operations.
  fi

  # If allocated interfaces exist, deallocate them now.
  if [ ${#mycodeInterfaces[@]} -gt 0 ]; then
    local interface
    for interface in "${!mycodeInterfaces[@]}"; do
      # Only deallocate mycode or airmon-ng created interfaces.
      if [[ "$interface" == "flux"* || "$interface" == *"mon"* || "$interface" == "prism"* ]]; then
        mycode_deallocate_interface $interface
      fi
    done
  fi

  echo -e "$CWht[$CRed-$CWht] $mycodeDisablingCleaningIPTablesNotice$CClr"
  if [ -f "$mycodeIPTablesBackup" ]; then
    iptables-restore <"$mycodeIPTablesBackup" \
      &> $mycodeOutputDevice
  else
    iptables --flush
    iptables --table nat --flush
    iptables --delete-chain
    iptables --table nat --delete-chain
  fi

  echo -e "$CWht[$CRed-$CWht] $mycodeRestoringTputNotice$CClr"
  tput cnorm

  if [ ! $mycodeDebug ]; then
    echo -e "$CWht[$CRed-$CWht] $mycodeDeletingFilesNotice$CClr"
    sandbox_remove_workfile "$mycodeWorkspacePath/*"
  fi

  if [ $mycodeWIKillProcesses ]; then
    echo -e "$CWht[$CRed-$CWht] $mycodeRestartingNetworkManagerNotice$CClr"

    # TODO: Add support for other network managers (wpa_supplicant?).
    if [ ! -x "$(command -v systemctl)" ]; then
        if [ -x "$(command -v service)" ];then
        service network-manager restart &> $mycodeOutputDevice &
        service networkmanager restart &> $mycodeOutputDevice &
        service networking restart &> $mycodeOutputDevice &
      fi
    else
      systemctl restart network-manager.service &> $mycodeOutputDevice &
    fi
  fi

  echo -e "$CWht[$CGrn+$CWht] $CGrn$mycodeCleanupSuccessNotice$CClr"
  echo -e "$CWht[$CGrn+$CWht] $CGry$mycodeThanksSupportersNotice$CClr"

  sleep 3

  clear

  exit 0
}


# ============================================================ #
# ================== < Helper Subroutines > ================== #
# ============================================================ #
# The following will kill the parent proces & all its children.
mycode_kill_lineage() {
  if [ ${#@} -lt 1 ]; then return -1; fi

  if [ ! -z "$2" ]; then
    local -r options=$1
    local match=$2
  else
    local -r options=""
    local match=$1
  fi

  # Check if the match isn't a number, but a regular expression.
  # The following might
  if ! [[ "$match" =~ ^[0-9]+$ ]]; then
    match=$(pgrep -f $match 2> $mycodeOutputDevice)
  fi

  # Check if we've got something to kill, abort otherwise.
  if [ -z "$match" ]; then return -2; fi

  kill $options $(pgrep -P $match 2> $mycodeOutputDevice) \
    &> $mycodeOutputDevice
  kill $options $match &> $mycodeOutputDevice
}


# ============================================================ #
# ================= < Handler Subroutines > ================== #
# ============================================================ #
# Delete log only in Normal Mode !
mycode_conditional_clear() {
  # Clear iff we're not in debug mode
  if [ ! $mycodeDebug ]; then clear; fi
}

mycode_conditional_bail() {
  echo ${1:-"Something went wrong, whoops! (report this)"}
  sleep 5
  if [ ! $mycodeDebug ]; then
    mycode_handle_exit
    return 1
  fi
  echo "Press any key to continue execution..."
  read -r bullshit
}

# ERROR Report only in Developer Mode
if [ $mycodeDebug ]; then
  mycode_error_report() {
    echo "Exception caught @ line #$1"
  }

  trap 'mycode_error_report $LINENO' ERR


mycode_handle_abort_attack() {
  if [ $(type -t stop_attack) ]; then
    stop_attack &> $mycodeOutputDevice
    unprep_attack &> $mycodeOutputDevice
  else
    echo "Attack undefined, can't stop anything..." > $mycodeOutputDevice
  fi

  mycode_target_tracker_stop
}

# In case of abort signal, abort any attacks currently running.
trap mycode_handle_abort_attack SIGABRT

mycode_handle_exit() {
  mycode_handle_abort_attack
  mycode_shutdown
  exit 1
}

# In case of unexpected termination, run mycode_shutdown.
trap mycode_handle_exit SIGINT SIGHUP


mycode_handle_target_change() {
  echo "Target change signal received!" > $mycodeOutputDevice

  local targetInfo
  readarray -t targetInfo < <(more "$mycodeWorkspacePath/target_info.txt")

  mycodeTargetMAC=${targetInfo[0]}
  mycodeTargetSSID=${targetInfo[1]}
  mycodeTargetChannel=${targetInfo[2]}

  mycodeTargetSSIDClean=$(mycode_target_normalize_SSID)

  if ! stop_attack; then
    mycode_conditional_bail "Target tracker failed to stop attack."
  fi

  if ! unprep_attack; then
    mycode_conditional_bail "Target tracker failed to unprep attack."
  fi

  if ! load_attack "$mycodePath/attacks/$mycodeAttack/attack.conf"; then
    mycode_conditional_bail "Target tracker failed to load attack."
  fi

  if ! prep_attack; then
    mycode_conditional_bail "Target tracker failed to prep attack."
  fi

  if ! mycode_run_attack; then
    mycode_conditional_bail "Target tracker failed to start attack."
  fi
}

# If target monitoring enabled, act on changes.
trap mycode_handle_target_change SIGALRM


# ============================================================ #
# =============== < Resolution & Positioning > =============== #
# ============================================================ #
mycode_set_resolution() { # Windows + Resolution

  # Get dimensions
  # Verify this works on Kali before commiting.
  # shopt -s checkwinsize; (:;:)
  # SCREEN_SIZE_X="$LINES"
  # SCREEN_SIZE_Y="$COLUMNS"

  SCREEN_SIZE=$(xdpyinfo | grep dimension | awk '{print $4}' | tr -d "(")
  SCREEN_SIZE_X=$(printf '%.*f\n' 0 $(echo $SCREEN_SIZE | sed -e s'/x/ /'g | awk '{print $1}'))
  SCREEN_SIZE_Y=$(printf '%.*f\n' 0 $(echo $SCREEN_SIZE | sed -e s'/x/ /'g | awk '{print $2}'))

  # Calculate proportional windows
  if hash bc ;then
    PROPOTION=$(echo $(awk "BEGIN {print $SCREEN_SIZE_X/$SCREEN_SIZE_Y}")/1 | bc)
    NEW_SCREEN_SIZE_X=$(echo $(awk "BEGIN {print $SCREEN_SIZE_X/$mycodeWindowRatio}")/1 | bc)
    NEW_SCREEN_SIZE_Y=$(echo $(awk "BEGIN {print $SCREEN_SIZE_Y/$mycodeWindowRatio}")/1 | bc)

    NEW_SCREEN_SIZE_BIG_X=$(echo $(awk "BEGIN {print 1.5*$SCREEN_SIZE_X/$mycodeWindowRatio}")/1 | bc)
    NEW_SCREEN_SIZE_BIG_Y=$(echo $(awk "BEGIN {print 1.5*$SCREEN_SIZE_Y/$mycodeWindowRatio}")/1 | bc)

    SCREEN_SIZE_MID_X=$(echo $(($SCREEN_SIZE_X + ($SCREEN_SIZE_X - 2 * $NEW_SCREEN_SIZE_X) / 2)))
    SCREEN_SIZE_MID_Y=$(echo $(($SCREEN_SIZE_Y + ($SCREEN_SIZE_Y - 2 * $NEW_SCREEN_SIZE_Y) / 2)))

    # Upper windows
    TOPLEFT="-geometry $NEW_SCREEN_SIZE_Xx$NEW_SCREEN_SIZE_Y+0+0"
    TOPRIGHT="-geometry $NEW_SCREEN_SIZE_Xx$NEW_SCREEN_SIZE_Y-0+0"
    TOP="-geometry $NEW_SCREEN_SIZE_Xx$NEW_SCREEN_SIZE_Y+$SCREEN_SIZE_MID_X+0"

    # Lower windows
    BOTTOMLEFT="-geometry $NEW_SCREEN_SIZE_Xx$NEW_SCREEN_SIZE_Y+0-0"
    BOTTOMRIGHT="-geometry $NEW_SCREEN_SIZE_Xx$NEW_SCREEN_SIZE_Y-0-0"
    BOTTOM="-geometry $NEW_SCREEN_SIZE_Xx$NEW_SCREEN_SIZE_Y+$SCREEN_SIZE_MID_X-0"

    # Y mid
    LEFT="-geometry $NEW_SCREEN_SIZE_Xx$NEW_SCREEN_SIZE_Y+0-$SCREEN_SIZE_MID_Y"
    RIGHT="-geometry $NEW_SCREEN_SIZE_Xx$NEW_SCREEN_SIZE_Y-0+$SCREEN_SIZE_MID_Y"

    # Big
    TOPLEFTBIG="-geometry $NEW_SCREEN_SIZE_BIG_Xx$NEW_SCREEN_SIZE_BIG_Y+0+0"
    TOPRIGHTBIG="-geometry $NEW_SCREEN_SIZE_BIG_Xx$NEW_SCREEN_SIZE_BIG_Y-0+0"
  fi
}


# ============================================================ #
# ================= < Sequencing Framework > ================= #
# ============================================================ #
# The following lists some problems with the framework's design.
# The list below is a list of DESIGN FLAWS, not framework bugs.
# * Sequenced undo instructions' return value is being ignored.
# * A global is generated for every new namespace being used.
# * It uses eval too much, but it's bash, so that's not so bad.
# TODO: Try to fix this or come up with a better alternative.
declare -rA mycodeUndoable=( \
  ["set"]="unset" \
  ["prep"]="unprep" \
  ["run"]="halt" \
  ["start"]="stop" \
)

# Yes, I know, the identifiers are fucking ugly. If only we had
# some type of mangling with bash identifiers, that'd be great.
mycode_do() {
  if [ ${#@} -lt 2 ]; then return -1; fi

  local -r __mycode_do__namespace=$1
  local -r __mycode_do__identifier=$2

  # Notice, the instruction will be adde to the Do Log
  # regardless of whether it succeeded or failed to execute.
  eval FXDLog_$__mycode_do__namespace+=\("$__mycode_do__identifier"\)
  eval ${__mycode_do__namespace}_$__mycode_do__identifier "${@:3}"
  return $?
}

mycode_undo() {
  if [ ${#@} -ne 1 ]; then return -1; fi

  local -r __mycode_undo__namespace=$1

  # Removed read-only due to local constant shadowing bug.
  # I've reported the bug, we can add it when fixed.
  eval local __mycode_undo__history=\("\${FXDLog_$__mycode_undo__namespace[@]}"\)

  eval echo \$\{FXDLog_$__mycode_undo__namespace[@]\} \
    > $mycodeOutputDevice

  local __mycode_undo__i
  for (( __mycode_undo__i=${#__mycode_undo__history[@]}; \
    __mycode_undo__i > 0; __mycode_undo__i-- )); do
    local __mycode_undo__instruction=${__mycode_undo__history[__mycode_undo__i-1]}
    local __mycode_undo__command=${__mycode_undo__instruction%%_*}
    local __mycode_undo__identifier=${__mycode_undo__instruction#*_}

    echo "Do ${mycodeUndoable["$__mycode_undo__command"]}_$__mycode_undo__identifier" \
      > $mycodeOutputDevice
    if eval ${__mycode_undo__namespace}_${mycodeUndoable["$__mycode_undo__command"]}_$__mycode_undo__identifier; then
      echo "Undo-chain succeded." > $mycodeOutputDevice
      eval FXDLog_$__mycode_undo__namespace=\("${__mycode_undo__history[@]::$__mycode_undo__i}"\)
      eval echo History\: \$\{FXDLog_$__mycode_undo__namespace[@]\} \
        > $mycodeOutputDevice
      return 0
    fi
  done

  return -2 # The undo-chain failed.
}

mycode_done() {
  if [ ${#@} -ne 1 ]; then return -1; fi

  local -r __mycode_done__namespace=$1

  eval "mycodeDone=\${FXDLog_$__mycode_done__namespace[-1]}"

  if [ ! "$mycodeDone" ]; then return 1; fi
}

mycode_done_reset() {
  if [ ${#@} -ne 1 ]; then return -1; fi

  local -r __mycode_done_reset__namespace=$1

  eval FXDLog_$__mycode_done_reset__namespace=\(\)
}

mycode_do_sequence() {
  if [ ${#@} -ne 2 ]; then return 1; fi

  # TODO: Implement an alternative, better method of doing
  # what this subroutine does, maybe using for-loop itemycodeWindowRation.
  # The for-loop implementation must support the subroutines
  # defined above, including updating the namespace tracker.

  local -r __mycode_do_sequence__namespace=$1

  # Removed read-only due to local constant shadowing bug.
  # I've reported the bug, we can add it when fixed.
  local __mycode_do_sequence__sequence=("${!2}")

  if [ ${#__mycode_do_sequence__sequence[@]} -eq 0 ]; then
    return -2
  fi

  local -A __mycode_do_sequence__index=()

  local i
  for i in $(seq 0 $((${#__mycode_do_sequence__sequence[@]} - 1))); do
    __mycode_do_sequence__index["${__mycode_do_sequence__sequence[i]}"]=$i
  done

  # Start sequence with the first instruction available.
  local __mycode_do_sequence__instructionIndex=0
  local __mycode_do_sequence__instruction=${__mycode_do_sequence__sequence[0]}
  while [ "$__mycode_do_sequence__instruction" ]; do
    if ! mycode_do $__mycode_do_sequence__namespace $__mycode_do_sequence__instruction; then
      if ! mycode_undo $__mycode_do_sequence__namespace; then
        return -2
      fi

      # Synchronize the current instruction's index by checking last.
      if ! mycode_done $__mycode_do_sequence__namespace; then
        return -3;
      fi

      __mycode_do_sequence__instructionIndex=${__mycode_do_sequence__index["$mycodeDone"]}

      if [ ! "$__mycode_do_sequence__instructionIndex" ]; then
        return -4
      fi
    else
      let __mycode_do_sequence__instructionIndex++
    fi

    __mycode_do_sequence__instruction=${__mycode_do_sequence__sequence[$__mycode_do_sequence__instructionIndex]}
    echo "Running next: $__mycode_do_sequence__instruction" \
      > $mycodeOutputDevice
  done
}


# ============================================================ #
# ================= < Load All Subroutines > ================= #
# ============================================================ #
mycode_header() {
  format_apply_autosize "[%*s]\n"
  local verticalBorder=$FormatApplyAutosize

  format_apply_autosize "[%*s${CSRed}mycode $mycodeVersion${CSWht}.${CSBlu}$mycodeRevision$CSRed    <$CIRed F${CIYel}luxion$CIRed I${CIYel}s$CIRed T${CIYel}he$CIRed F${CIYel}uture$CClr$CSYel >%*s$CSBlu]\n"
  local headerTextFormat="$FormatApplyAutosize"

  echo -e "$(printf "$CSRed$verticalBorder" "" | sed -r "s/ /~/g")"
  printf "$CSRed$verticalBorder" ""
  printf "$headerTextFormat" "" ""
  printf "$CSBlu$verticalBorder" ""
  echo -e "$(printf "$CSBlu$verticalBorder" "" | sed -r "s/ /~/g")$CClr"
  echo
  echo
}

# ======================= < Language > ======================= #
mycode_unset_language() {
  mycodeLanguage=""

  if [ "$mycodePreferencesFile" ]; then
    sed -i.backup "/mycodeLanguage=.\+/ d" "$mycodePreferencesFile"
  fi
}

mycode_set_language() {
  if [ ! "$mycodeLanguage" ]; then
    # Get all languages available.
    local languageCodes
    readarray -t languageCodes < <(ls -1 language | sed -E 's/\.sh//')

    local languages
    readarray -t languages < <(
      head -n 3 language/*.sh |
      grep -E "^# native: " |
      sed -E 's/# \w+: //'
    )

    io_query_format_fields "$mycodeVLine Select your language" \
      "\t$CRed[$CSYel%d$CClr$CRed]$CClr %s / %s\n" \
      languageCodes[@] languages[@]

    mycodeLanguage=${IOQueryFormatFields[0]}

    echo # Do not remove.
  fi

  # Check if all language files are present for the selected language.
  find -type d -name language | while read language_dir; do
    if [ ! -e "$language_dir/${mycodeLanguage}.sh" ]; then
      echo -e "$mycodeVLine ${CYel}Warning${CClr}, missing language file:"
      echo -e "\t$language_dir/${mycodeLanguage}.sh"
      return 1
    fi
  done

  if [ $? -eq 1 ]; then # If a file is missing, fall back to english.
    echo -e "\n\n$mycodeVLine Falling back to English..."; sleep 5
    mycodeLanguage="en"
  fi

  source "$mycodePath/language/$mycodeLanguage.sh"

  if [ "$mycodePreferencesFile" ]; then
    if more $mycodePreferencesFile | \
      grep -q "mycodeLanguage=.\+" &> /dev/null; then
      sed -r "s/mycodeLanguage=.+/mycodeLanguage=$mycodeLanguage/g" \
      -i.backup "$mycodePreferencesFile"
    else
      echo "mycodeLanguage=$mycodeLanguage" >> "$mycodePreferencesFile"
    fi
  fi
}

# ====================== < Interfaces > ====================== #
declare -A mycodeInterfaces=() # Global interfaces' registry.

mycode_deallocate_interface() { # Release interfaces
  if [ ! "$1" ] || ! interface_is_real $1; then return 1; fi

  local -r oldIdentifier=$1
  local -r newIdentifier=${mycodeInterfaces[$oldIdentifier]}

  # Assure the interface is in the allocation table.
  if [ ! "$newIdentifier" ]; then return 2; fi

  local interfaceIdentifier=$newIdentifier
  echo -e "$CWht[$CSRed-$CWht] "$(
    io_dynamic_output "$mycodeDeallocatingInterfaceNotice"
  )"$CClr"

  if interface_is_wireless $oldIdentifier; then
    # If interface was allocated by airmon-ng, deallocate with it.
    if [[ "$oldIdentifier" == *"mon"* || "$oldIdentifier" == "prism"* ]]; then
      if ! airmon-ng stop $oldIdentifier &> $mycodeOutputDevice; then
        return 4
      fi
    else
      # Attempt deactivating monitor mode on the interface.
      if ! interface_set_mode $oldIdentifier managed; then
        return 3
      fi

      # Attempt to restore the original interface identifier.
      if ! interface_reidentify "$oldIdentifier" "$newIdentifier"; then
        return 5
      fi
    fi
  fi

  # Once successfully renamed, remove from allocation table.
  unset mycodeInterfaces[$oldIdentifier]
  unset mycodeInterfaces[$newIdentifier]
}

# Parameters: <interface_identifier>
# ------------------------------------------------------------ #
# Return 1: No interface identifier was passed.
# Return 2: Interface identifier given points to no interface.
# Return 3: Unable to determine interface's driver.
# Return 4: mycode failed to reidentify interface.
# Return 5: Interface allocation failed (identifier missing).
mycode_allocate_interface() { # Reserve interfaces
  if [ ! "$1" ]; then return 1; fi

  local -r identifier=$1

  # If the interface is already in allocation table, we're done.
  if [ "${mycodeInterfaces[$identifier]+x}" ]; then
    return 0
  fi

  if ! interface_is_real $identifier; then return 2; fi


  local interfaceIdentifier=$identifier
  echo -e "$CWht[$CSGrn+$CWht] "$(
    io_dynamic_output "$mycodeAllocatingInterfaceNotice"
  )"$CClr"


  if interface_is_wireless $identifier; then
    # Unblock wireless interfaces to make them available.
    echo -e "$mycodeVLine $mycodeUnblockingWINotice"
    rfkill unblock all &> $mycodeOutputDevice

    if [ "$mycodeWIReloadDriver" ]; then
      # Get selected interface's driver details/info-descriptor.
      echo -e "$mycodeVLine $mycodeGatheringWIInfoNotice"

      if ! interface_driver "$identifier"; then
        echo -e "$mycodeVLine$CRed $mycodeUnknownWIDriverError"
        sleep 3
        return 3
      fi

      # Notice: This local is function-scoped, not block-scoped.
      local -r driver="$InterfaceDriver"

      # Unload the driver module from the kernel.
      rmmod -f $driver &> $mycodeOutputDevice

      # Wait while interface becomes unavailable.
      echo -e "$mycodeVLine "$(
        io_dynamic_output $mycodeUnloadingWIDriverNotice
      )
      while interface_physical "$identifier"; do
        sleep 1
      done
    fi

    if [ "$mycodeWIKillProcesses" ]; then
      # Get list of potentially troublesome programs.
      echo -e "$mycodeVLine $mycodeFindingConflictingProcessesNotice"

      # Kill potentially troublesome programs.
      echo -e "$mycodeVLine $mycodeKillingConflictingProcessesNotice"

      # TODO: Make the loop below airmon-ng independent.
      # Maybe replace it with a list of network-managers?
      # WARNING: Version differences could break code below.
      for program in "$(airmon-ng check | awk 'NR>6{print $2}')"; do
        killall "$program" &> $mycodeOutputDevice
      done
    fi

    if [ "$mycodeWIReloadDriver" ]; then
      # Reload the driver module into the kernel.
      modprobe "$driver" &> $mycodeOutputDevice

      # Wait while interface becomes available.
      echo -e "$mycodeVLine "$(
        io_dynamic_output $mycodeLoadingWIDriverNotice
      )
      while ! interface_physical "$identifier"; do
        sleep 1
      done
    fi

    # Set wireless flag to prevent having to re-query.
    local -r allocatingWirelessInterface=1
  fi

  # If we're using the interface library, reidentify now.
  # If usuing airmon-ng, let airmon-ng rename the interface.
  if [ ! $mycodeAirmonNG ]; then
    echo -e "$mycodeVLine $mycodeReidentifyingInterface"

    # Prevent interface-snatching by renaming the interface.
    if [ $allocatingWirelessInterface ]; then
      # Get next wireless interface to add to mycodeInterfaces global.
      mycode_next_assignable_interface fluxwl
    else
      # Get next ethernet interface to add to mycodeInterfaces global.
      mycode_next_assignable_interface fluxet
    fi

    interface_reidentify $identifier $mycodeNextAssignableInterface

    if [ $? -ne 0 ]; then # If reidentifying failed, abort immediately.
      return 4
    fi
  fi

  if [ $allocatingWirelessInterface ]; then
    # Activate wireless interface monitor mode and save identifier.
    echo -e "$mycodeVLine $mycodeStartingWIMonitorNotice"

    # TODO: Consider the airmon-ng flag is set, monitor mode is
    # already enabled on the interface being allocated, and the
    # interface identifier is something non-airmon-ng standard.
    # The interface could already be in use by something else.
    # Snatching or crashing interface issues could occur.

    # NOTICE: Conditionals below populate newIdentifier on success.
    if [ $mycodeAirmonNG ]; then
      local -r newIdentifier=$(
        airmon-ng start $identifier |
        grep "monitor .* enabled" |
        grep -oP "wl[a-zA-Z0-9]+mon|mon[0-9]+|prism[0-9]+"
      )
    else
      # Attempt activating monitor mode on the interface.
      if interface_set_mode $mycodeNextAssignableInterface monitor; then
        # Register the new identifier upon consecutive successes.
        local -r newIdentifier=$mycodeNextAssignableInterface
      else
        # If monitor-mode switch fails, undo rename and abort.
        interface_reidentify $mycodeNextAssignableInterface $identifier
      fi
    fi
  fi

  # On failure to allocate the interface, we've got to abort.
  # Notice: If the interface was already in monitor mode and
  # airmon-ng is activated, WE didn't allocate the interface.
  if [ ! "$newIdentifier" -o "$newIdentifier" = "$oldIdentifier" ]; then
    echo -e "$mycodeVLine $mycodeInterfaceAllocationFailedError"
    sleep 3
    return 5
  fi

  # Register identifiers to allocation hash table.
  mycodeInterfaces[$newIdentifier]=$identifier
  mycodeInterfaces[$identifier]=$newIdentifier

  echo -e "$mycodeVLine $mycodeInterfaceAllocatedNotice"
  sleep 3

  # Notice: Interfaces are accessed with their original identifier
  # as the key for the global mycodeInterfaces hash/map/dictionary.
}

# Parameters: <interface_prefix>
# Description: Prints next available assignable interface name.
# ------------------------------------------------------------ #
mycode_next_assignable_interface() {
  # Find next available interface by checking global.
  local -r prefix=$1
  local index=0
  while [ "${mycodeInterfaces[$prefix$index]}" ]; do
    let index++
  done
  mycodeNextAssignableInterface="$prefix$index"
}

# Parameters: <interfaces:lambda> [<query>]
# Note: The interfaces lambda must print an interface per line.
# ------------------------------------------------------------ #
# Return -1: Go back
# Return  1: Missing interfaces lambda identifier (not passed).
mycode_get_interface() {
  if ! type -t "$1" &> /dev/null; then return 1; fi

  if [ "$2" ]; then
    local -r interfaceQuery="$2"
  else
    local -r interfaceQuery=$mycodeInterfaceQuery
  fi

  while true; do
    local candidateInterfaces
    readarray -t candidateInterfaces < <($1)
    local interfacesAvailable=()
    local interfacesAvailableInfo=()
    local interfacesAvailableColor=()
    local interfacesAvailableState=()

    # Gather information from all available interfaces.
    local candidateInterface
    for candidateInterface in "${candidateInterfaces[@]}"; do
      if [ ! "$candidateInterface" ]; then
        local skipOption=1
        continue
      fi

      interface_chipset "$candidateInterface"
      interfacesAvailableInfo+=("$InterfaceChipset")

      # If it has already been allocated, we can use it at will.
      local candidateInterfaceAlt=${mycodeInterfaces["$candidateInterface"]}
      if [ "$candidateInterfaceAlt" ]; then
        interfacesAvailable+=("$candidateInterfaceAlt")

        interfacesAvailableColor+=("$CGrn")
        interfacesAvailableState+=("[*]")
      else
        interfacesAvailable+=("$candidateInterface")

        interface_state "$candidateInterface"

        if [ "$InterfaceState" = "up" ]; then
          interfacesAvailableColor+=("$CPrp")
          interfacesAvailableState+=("[-]")
        else
          interfacesAvailableColor+=("$CClr")
          interfacesAvailableState+=("[+]")
        fi
      fi
    done

    # If only one interface exists and it's not unavailable, choose it.
    if [ "${#interfacesAvailable[@]}" -eq 1 -a \
      "${interfacesAvailableState[0]}" != "[-]" -a \
      "$skipOption" == "" ]; then mycodeInterfaceSelected="${interfacesAvailable[0]}"
      mycodeInterfaceSelectedState="${interfacesAvailableState[0]}"
      mycodeInterfaceSelectedInfo="${interfacesAvailableInfo[0]}"
      break
    else
      if [ $skipOption ]; then
        interfacesAvailable+=("$mycodeGeneralSkipOption")
        interfacesAvailableColor+=("$CClr")
      fi

      interfacesAvailable+=(
        "$mycodeGeneralRepeatOption"
        "$mycodeGeneralBackOption"
      )

      interfacesAvailableColor+=(
        "$CClr"
        "$CClr"
      )

      format_apply_autosize \
        "$CRed[$CSYel%1d$CClr$CRed]%b %-8b %3s$CClr %-*.*s\n"

      io_query_format_fields \
        "$mycodeVLine $interfaceQuery" "$FormatApplyAutosize" \
        interfacesAvailableColor[@] interfacesAvailable[@] \
        interfacesAvailableState[@] interfacesAvailableInfo[@]

      echo

      case "${IOQueryFormatFields[1]}" in
        "$mycodeGeneralSkipOption")
          mycodeInterfaceSelected=""
          mycodeInterfaceSelectedState=""
          mycodeInterfaceSelectedInfo=""
          return 0;;
        "$mycodeGeneralRepeatOption") continue;;
        "$mycodeGeneralBackOption") return -1;;
        *)
          mycodeInterfaceSelected="${IOQueryFormatFields[1]}"
          mycodeInterfaceSelectedState="${IOQueryFormatFields[2]}"
          mycodeInterfaceSelectedInfo="${IOQueryFormatFields[3]}"
          break;;
      esac
    fi
  done
}


# ============== < mycode Target Subroutines > ============== #
# Parameters: interface [ channel(s) [ band(s) ] ]
# ------------------------------------------------------------ #
# Return 1: Missing monitor interface.
# Return 2: Xterm failed to start airmon-ng.
# Return 3: Invalid capture file was generated.
# Return 4: No candidates were detected.
mycode_target_get_candidates() {
  # Assure a valid wireless interface for scanning was given.
  if [ ! "$1" ] || ! interface_is_wireless "$1"; then return 1; fi

  echo -e "$mycodeVLine $mycodeStartingScannerNotice"
  echo -e "$mycodeVLine $mycodeStartingScannerTip"

  # Assure all previous scan results have been cleared.
  sandbox_remove_workfile "$mycodeWorkspacePath/dump*"

  #if [ "$mycodeAuto" ]; then
  #  sleep 30 && killall xterm &
  #fi

  # Begin scanner and output all results to "dump-01.csv."
if ! xterm -title "$mycodeScannerHeader" $TOPLEFTBIG \
    -bg "#000000" -fg "#FFFFFF" -e \
    "airodump-ng -Mat WPA "${2:+"--channel $2"}" "${3:+"--band $3"}" -w \"$mycodeWorkspacePath/dump\" $1" 2> $mycodeOutputDevice; then
    echo -e "$mycodeVLine$CRed $mycodeGeneralXTermFailureError"
    sleep 5
    return 2
fi

  # Sanity check the capture files generated by the scanner.
  # If the file doesn't exist, or if it's empty, abort immediately.
  if [ ! -f "$mycodeWorkspacePath/dump-01.csv" -o \
    ! -s "$mycodeWorkspacePath/dump-01.csv" ]; then
    sandbox_remove_workfile "$mycodeWorkspacePath/dump*"
    return 3
  fi

  # Syntheize scan opemycodeWindowRation results from output file "dump-01.csv."
  echo -e "$mycodeVLine $mycodePreparingScannerResultsNotice"
  # WARNING: The code below may break with different version of airmon-ng.
  # The times matching operator "{n}" isn't supported by mawk (alias awk).
  # readarray mycodeTargetCandidates < <(
  #   gawk -F, 'NF==15 && $1~/([A-F0-9]{2}:){5}[A-F0-9]{2}/ {print $0}'
  #   $mycodeWorkspacePath/dump-01.csv
  # )
  # readarray mycodeTargetCandidatesClients < <(
  #   gawk -F, 'NF==7 && $1~/([A-F0-9]{2}:){5}[A-F0-9]{2}/ {print $0}'
  #   $mycodeWorkspacePath/dump-01.csv
  # )
  local -r matchMAC="([A-F0-9][A-F0-9]:)+[A-F0-9][A-F0-9]"
  readarray mycodeTargetCandidates < <(
    awk -F, "NF==15 && length(\$1)==17 && \$1~/$matchMAC/ {print \$0}" \
    "$mycodeWorkspacePath/dump-01.csv"
  )
  readarray mycodeTargetCandidatesClients < <(
    awk -F, "NF==7 && length(\$1)==17 && \$1~/$matchMAC/ {print \$0}" \
    "$mycodeWorkspacePath/dump-01.csv"
  )

  # Cleanup the workspace to prevent potential bugs/conflicts.
  sandbox_remove_workfile "$mycodeWorkspacePath/dump*"

  if [ ${#mycodeTargetCandidates[@]} -eq 0 ]; then
    echo -e "$mycodeVLine $mycodeScannerDetectedNothingNotice"
    sleep 3
    return 4
  fi
}


mycode_get_target() {
  # Assure a valid wireless interface for scanning was given.
  if [ ! "$1" ] || ! interface_is_wireless "$1"; then return 1; fi

  local -r interface=$1

  local choices=( \
    "$mycodeScannerChannelOptionAll (2.4GHz)" \
    "$mycodeScannerChannelOptionAll (5GHz)" \
    "$mycodeScannerChannelOptionAll (2.4GHz & 5Ghz)" \
    "$mycodeScannerChannelOptionSpecific" "$mycodeGeneralBackOption"
  )

  io_query_choice "$mycodeScannerChannelQuery" choices[@]

  echo

  case "$IOQueryChoice" in
    "$mycodeScannerChannelOptionAll (2.4GHz)")
      mycode_target_get_candidates $interface "" "bg";;

    "$mycodeScannerChannelOptionAll (5GHz)")
      mycode_target_get_candidates $interface "" "a";;

    "$mycodeScannerChannelOptionAll (2.4GHz & 5Ghz)")
      mycode_target_get_candidates $interface "" "abg";;

    "$mycodeScannerChannelOptionSpecific")
      mycode_header

      echo -e "$mycodeVLine $mycodeScannerChannelQuery"
      echo
      echo -e "     $mycodeScannerChannelSingleTip ${CBlu}6$CClr               "
      echo -e "     $mycodeScannerChannelMiltipleTip ${CBlu}1-5$CClr             "
      echo -e "     $mycodeScannerChannelMiltipleTip ${CBlu}1,2,5-7,11$CClr      "
      echo
      echo -ne "$mycodePrompt"

      local channels
      read channels

      echo

      mycode_target_get_candidates $interface $channels;;

    "$mycodeGeneralBackOption")
      return -1;;
  esac

  # Abort if errors occured while searching for candidates.
  if [ $? -ne 0 ]; then return 2; fi

  local candidatesMAC=()
  local candidatesClientsCount=()
  local candidatesChannel=()
  local candidatesSecurity=()
  local candidatesSignal=()
  local candidatesPower=()
  local candidatesESSID=()
  local candidatesColor=()

  # Gather information from all the candidates detected.
  # TODO: Clean up this for loop using a cleaner algorithm.
  # Maybe try using array appending & [-1] for last elements.
  for candidateAPInfo in "${mycodeTargetCandidates[@]}"; do
    # Strip candidate info from any extraneous spaces after commas.
    candidateAPInfo=$(echo "$candidateAPInfo" | sed -r "s/,\s*/,/g")

    local i=${#candidatesMAC[@]}

    candidatesMAC[i]=$(echo "$candidateAPInfo" | cut -d , -f 1)
    candidatesClientsCount[i]=$(
      echo "${mycodeTargetCandidatesClients[@]}" |
      grep -c "${candidatesMAC[i]}"
    )
    candidatesChannel[i]=$(echo "$candidateAPInfo" | cut -d , -f 4)
    candidatesSecurity[i]=$(echo "$candidateAPInfo" | cut -d , -f 6)
    candidatesPower[i]=$(echo "$candidateAPInfo" | cut -d , -f 9)
    candidatesColor[i]=$(
      [ ${candidatesClientsCount[i]} -gt 0 ] && echo $CGrn || echo $CClr
    )

    # Parse any non-ascii characters by letting bash handle them.
    # Escape all single quotes in ESSID and let bash's $'...' handle it.
    local sanitizedESSID=$(
      echo "${candidateAPInfo//\'/\\\'}" | cut -d , -f 14
    )
    candidatesESSID[i]=$(eval "echo \$'$sanitizedESSID'")

    local power=${candidatesPower[i]}
    if [ $power -eq -1 ]; then
      # airodump-ng's man page says -1 means unsupported value.
      candidatesQuality[i]="??"
    elif [ $power -le $mycodeNoiseFloor ]; then
      candidatesQuality[i]=0
    elif [ $power -gt $mycodeNoiseCeiling ]; then
      candidatesQuality[i]=100
    else
      # Bash doesn't support floating point division, work around it...
      # Q = ((P - F) / (C - F)); Q-quality, P-power, F-floor, C-Ceiling.
      candidatesQuality[i]=$(( \
        (${candidatesPower[i]} * 10 - $mycodeNoiseFloor * 10) / \
        (($mycodeNoiseCeiling - $mycodeNoiseFloor) / 10) \
      ))
    fi
  done

  format_center_literals "WIFI LIST"
  local -r headerTitle="$FormatCenterLiterals\n\n"

  format_apply_autosize "$CRed[$CSYel ** $CClr$CRed]$CClr %-*.*s %4s %3s %3s %2s %-8.8s %18s\n"
  local -r headerFields=$(
    printf "$FormatApplyAutosize" \
      "ESSID" "QLTY" "PWR" "STA" "CH" "SECURITY" "BSSID"
  )

  format_apply_autosize "$CRed[$CSYel%03d$CClr$CRed]%b %-*.*s %3s%% %3s %3d %2s %-8.8s %18s\n"
  io_query_format_fields "$headerTitle$headerFields" \
   "$FormatApplyAutosize" \
    candidatesColor[@] \
    candidatesESSID[@] \
    candidatesQuality[@] \
    candidatesPower[@] \
    candidatesClientsCount[@] \
    candidatesChannel[@] \
    candidatesSecurity[@] \
    candidatesMAC[@]

  echo

  mycodeTargetMAC=${IOQueryFormatFields[7]}
  mycodeTargetSSID=${IOQueryFormatFields[1]}
  mycodeTargetChannel=${IOQueryFormatFields[5]}

  mycodeTargetEncryption=${IOQueryFormatFields[6]}

  mycodeTargetMakerID=${mycodeTargetMAC:0:8}
  mycodeTargetMaker=$(
    macchanger -l |
    grep ${mycodeTargetMakerID,,} 2> $mycodeOutputDevice |
    cut -d ' ' -f 5-
  )

  mycodeTargetSSIDClean=$(mycode_target_normalize_SSID)

  # We'll change a single hex digit from the target AP's MAC address.
  # This new MAC address will be used as the rogue AP's MAC address.
  local -r rogueMACHex=$(printf %02X $((0x${mycodeTargetMAC:13:1} + 1)))
  mycodeTargetRogueMAC="${mycodeTargetMAC::13}${rogueMACHex:1:1}${mycodeTargetMAC:14:4}"
}

mycode_target_normalize_SSID() {
  # Sanitize network ESSID to make it safe for manipulation.
  # Notice: Why remove these? Some smartass might decide to name their
  # network "; rm -rf / ;". If the string isn't sanitized accidentally
  # shit'll hit the fan and we'll have an extremly distressed user.
  # Replacing ' ', '/', '.', '~', '\' with '_'
  echo "$mycodeTargetSSID" | sed -r 's/( |\/|\.|\~|\\)+/_/g'
}

mycode_target_show() {
  format_apply_autosize "%*s$CBlu%7s$CClr: %-32s%*s\n"

  local colorlessFormat="$FormatApplyAutosize"
  local colorfullFormat=$(
    echo "$colorlessFormat" | sed -r 's/%-32s/%-32b/g'
  )

  printf "$colorlessFormat" "" "ESSID" "\"${mycodeTargetSSID:-[N/A]}\" / ${mycodeTargetEncryption:-[N/A]}" ""
  printf "$colorlessFormat" "" "Channel" " ${mycodeTargetChannel:-[N/A]}" ""
  printf "$colorfullFormat" "" "BSSID" " ${mycodeTargetMAC:-[N/A]} ($CYel${mycodeTargetMaker:-[N/A]}$CClr)" ""

  echo
}

mycode_target_tracker_daemon() {
  if [ ! "$1" ]; then return 1; fi # Assure we've got mycode's PID.

  readonly mycodePID=$1
  readonly monitorTimeout=10 # In seconds.
  readonly capturePath="$mycodeWorkspacePath/tracker_capture"

  if [ \
    -z "$mycodeTargetMAC" -o \
    -z "$mycodeTargetSSID" -o \
    -z "$mycodeTargetChannel" ]; then
    return 2 # If we're missing target information, we can't track properly.
  fi

  while true; do
    echo "[T-Tracker] Captor listening for $monitorTimeout seconds..."
    timeout --preserve-status $monitorTimeout airodump-ng -aw "$capturePath" \
      -d "$mycodeTargetMAC" $mycodeTargetTrackerInterface &> /dev/null
    local error=$? # Catch the returned status error code.

    if [ $error -ne 0 ]; then # If any error was encountered, abort!
      echo -e "[T-Tracker] ${CRed}Error:$CClr Operation aborted (code: $error)!"
      break
    fi

    local targetInfo=$(head -n 3 "$capturePath-01.csv" | tail -n 1)
    sandbox_remove_workfile "$capturePath-*"

    local targetChannel=$(
      echo "$targetInfo" | awk -F, '{gsub(/ /, "", $4); print $4}'
    )

    echo "[T-Tracker] $targetInfo"

    if [ "$targetChannel" -ne "$mycodeTargetChannel" ]; then
      echo "[T-Tracker] Target channel change detected!"
      mycodeTargetChannel=$targetChannel
      break
    fi

    # NOTE: We might also want to check for SSID changes here, assuming the only
    # thing that remains constant is the MAC address. The problem with that is
    # that airodump-ng has some serious problems with unicode, apparently.
    # Try feeding it an access point with Chinese characters and check the .csv.
  done

  # Save/overwrite the new target information to the workspace for retrival.
  echo "$mycodeTargetMAC" > "$mycodeWorkspacePath/target_info.txt"
  echo "$mycodeTargetSSID" >> "$mycodeWorkspacePath/target_info.txt"
  echo "$mycodeTargetChannel" >> "$mycodeWorkspacePath/target_info.txt"

  # NOTICE: Using different signals for different things is a BAD idea.
  # We should use a single signal, SIGINT, to handle different situations.
  kill -s SIGALRM $mycodePID # Signal mycode a change was detected.

  sandbox_remove_workfile "$capturePath-*"
}

mycode_target_tracker_stop() {
  if [ ! "$mycodeTargetTrackerDaemonPID" ]; then return 1; fi
  kill -s SIGABRT $mycodeTargetTrackerDaemonPID &> /dev/null
  mycodeTargetTrackerDaemonPID=""
}

mycode_target_tracker_start() {
  if [ ! "$mycodeTargetTrackerInterface" ]; then return 1; fi

  mycode_target_tracker_daemon $$ &> "$mycodeOutputDevice" &
  mycodeTargetTrackerDaemonPID=$!
}

mycode_target_unset_tracker() {
  if [ ! "$mycodeTargetTrackerInterface" ]; then return 1; fi

  mycodeTargetTrackerInterface=""
}

mycode_target_set_tracker() {
  if [ "$mycodeTargetTrackerInterface" ]; then
    echo "Tracker interface already set, skipping." > $mycodeOutputDevice
    return 0
  fi

  # Check if attack provides tracking interfaces, get & set one.
  if ! type -t attack_tracking_interfaces &> /dev/null; then
    echo "Tracker DOES NOT have interfaces available!" > $mycodeOutputDevice
    return 1
  fi

  if [ "$mycodeTargetTrackerInterface" == "" ]; then
    echo "Running get interface (tracker)." > $mycodeOutputDevice
    local -r interfaceQuery=$mycodeTargetTrackerInterfaceQuery
    local -r interfaceQueryTip=$mycodeTargetTrackerInterfaceQueryTip
    local -r interfaceQueryTip2=$mycodeTargetTrackerInterfaceQueryTip2
    if ! mycode_get_interface attack_tracking_interfaces \
      "$interfaceQuery\n$mycodeVLine $interfaceQueryTip\n$mycodeVLine $interfaceQueryTip2"; then
      echo "Failed to get tracker interface!" > $mycodeOutputDevice
      return 2
    fi
    local selectedInterface=$mycodeInterfaceSelected
  else
    # Assume user passed one via the command line and move on.
    # If none was given we'll take care of that case below.
    local selectedInterface=$mycodeTargetTrackerInterface
    echo "Tracker interface passed via command line!" > $mycodeOutputDevice
  fi

  # If user skipped a tracker interface, move on.
  if [ ! "$selectedInterface" ]; then
    mycode_target_unset_tracker
    return 0
  fi

  if ! mycode_allocate_interface $selectedInterface; then
    echo "Failed to allocate tracking interface!" > $mycodeOutputDevice
    return 3
  fi

  echo "Successfully got tracker interface." > $mycodeOutputDevice
  mycodeTargetTrackerInterface=${mycodeInterfaces[$selectedInterface]}
}

mycode_target_unset() {
  mycodeTargetMAC=""
  mycodeTargetSSID=""
  mycodeTargetChannel=""

  mycodeTargetEncryption=""

  mycodeTargetMakerID=""
  mycodeTargetMaker=""

  mycodeTargetSSIDClean=""

  mycodeTargetRogueMAC=""

  return 1 # To trigger undo-chain.
}

mycode_target_set() {
  # Check if attack is targetted & set the attack target if so.
  if ! type -t attack_targetting_interfaces &> /dev/null; then
    return 1
  fi

  if [ \
    "$mycodeTargetSSID" -a \
    "$mycodeTargetMAC" -a \
    "$mycodeTargetChannel" \
  ]; then
    # If we've got a candidate target, ask user if we'll keep targetting it.

    mycode_header
    mycode_target_show
    echo
    echo -e  "$mycodeVLine $mycodeTargettingAccessPointAboveNotice"

    # TODO: This doesn't translate choices to the selected language.
    while ! echo "$choice" | grep -q "^[ynYN]$" &> /dev/null; do
      echo -ne "$mycodeVLine $mycodeContinueWithTargetQuery [Y/n] "
      local choice
      read choice
      if [ ! "$choice" ]; then break; fi
    done

    echo -ne "\n\n"

    if [ "${choice,,}" != "n" ]; then
      return 0
    fi
  elif [ \
    "$mycodeTargetSSID" -o \
    "$mycodeTargetMAC" -o \
    "$mycodeTargetChannel" \
  ]; then
    # TODO: Survey environment here to autofill missing fields.
    # In other words, if a user gives incomplete information, scan
    # the environment based on either the ESSID or BSSID, & autofill.
    echo -e "$mycodeVLine $mycodeIncompleteTargettingInfoNotice"
    sleep 3
  fi

  if ! mycode_get_interface attack_targetting_interfaces \
    "$mycodeTargetSearchingInterfaceQuery"; then
    return 2
  fi

  if ! mycode_allocate_interface $mycodeInterfaceSelected; then
    return 3
  fi

  if ! mycode_get_target \
    ${mycodeInterfaces[$mycodeInterfaceSelected]}; then
    return 4
  fi
}


# =================== < Hash Subroutines > =================== #
# Parameters: <hash path> <bssid> <essid> [channel [encryption [maker]]]
mycode_hash_verify() {
  if [ ${#@} -lt 3 ]; then return 1; fi

  local -r hashPath=$1
  local -r hashBSSID=$2
  local -r hashESSID=$3
  local -r hashChannel=$4
  local -r hashEncryption=$5
  local -r hashMaker=$6

  if [ ! -f "$hashPath" -o ! -s "$hashPath" ]; then
    echo -e "$mycodeVLine $mycodeHashFileDoesNotExistError"
    sleep 3
    return 2
  fi

  if [ "$mycodeAuto" ]; then
    local -r verifier="cowpatty"
  else
    mycode_header

    echo -e "$mycodeVLine $mycodeHashVerificationMethodQuery"
    echo

    mycode_target_show

    local choices=( \
      "$mycodeHashVerificationMethodAircrackOption" \
      "$mycodeHashVerificationMethodCowpattyOption" \
    )

    # Add pyrit to the options is available.
    if [ -x "$(command -v pyrit)" ]; then
      choices+=("$mycodeHashVerificationMethodPyritOption")
    fi

    options+=("$mycodeGeneralBackOption")

    io_query_choice "" choices[@]

    echo

    case "$IOQueryChoice" in
      "$mycodeHashVerificationMethodPyritOption")
        local -r verifier="pyrit" ;;

      "$mycodeHashVerificationMethodAircrackOption")
        local -r verifier="aircrack-ng" ;;

      "$mycodeHashVerificationMethodCowpattyOption")
        local -r verifier="cowpatty" ;;

      "$mycodeGeneralBackOption")
        return -1 ;;
    esac
  fi

  hash_check_handshake \
    "$verifier" \
    "$hashPath" \
    "$hashESSID" \
    "$hashBSSID"

  local -r hashResult=$?

  # A value other than 0 means there's an issue with the hash.
  if [ $hashResult -ne 0 ]; then
    echo -e "$mycodeVLine $mycodeHashInvalidError"
  else
    echo -e "$mycodeVLine $mycodeHashValidNotice"
  fi

  sleep 3

  if [ $hashResult -ne 0 ]; then return 1; fi
}

mycode_hash_unset_path() {
  if [ ! "$mycodeHashPath" ]; then return 1; fi
  mycodeHashPath=""

  # Since we're auto-selecting when on auto, trigger undo-chain.
  if [ "$mycodeAuto" ]; then return 2; fi
}

# Parameters: <hash path> <bssid> <essid> [channel [encryption [maker]]]
mycode_hash_set_path() {
  if [ "$mycodeHashPath" ]; then return 0; fi

  mycode_hash_unset_path

  local -r hashPath=$1

  # If we've got a default path, check if a hash exists.
  # If one exists, ask users if they'd like to use it.
  if [ "$hashPath" -a -f "$hashPath" -a -s "$hashPath" ]; then
    if [ "$mycodeAuto" ]; then
      echo "Using default hash path: $hashPath" > $mycodeOutputDevice
      mycodeHashPath=$hashPath
      return
    else
      local choices=( \
        "$mycodeUseFoundHashOption" \
        "$mycodeSpecifyHashPathOption" \
        "$mycodeHashSourceRescanOption" \
        "$mycodeGeneralBackOption" \
      )

      mycode_header

      echo -e "$mycodeVLine $mycodeFoundHashNotice"
      echo -e "$mycodeVLine $mycodeUseFoundHashQuery"
      echo

      io_query_choice "" choices[@]

      echo

      case "$IOQueryChoice" in
        "$mycodeUseFoundHashOption")
          mycodeHashPath=$hashPath
          return ;;

        "$mycodeHashSourceRescanOption")
          mycode_hash_set_path "$@"
          return $? ;;

        "$mycodeGeneralBackOption")
          return -1 ;;
      esac
    fi
  fi

  while [ ! "$mycodeHashPath" ]; do
    mycode_header

    echo
    echo -e "$mycodeVLine $mycodePathToHandshakeFileQuery"
    echo -e "$mycodeVLine $mycodePathToHandshakeFileReturnTip"
    echo
    echo -ne "$mycodeAbsolutePathInfo: "
    read mycodeHashPath

    # Back-track when the user leaves the hash path blank.
    # Notice: Path is cleared if we return, no need to unset.
    if [ ! "$mycodeHashPath" ]; then return 1; fi

    echo "Path given: \"$mycodeHashPath\"" > $mycodeOutputDevice

    # Make sure the path points to a valid generic file.
    if [ ! -f "$mycodeHashPath" -o ! -s "$mycodeHashPath" ]; then
      echo -e "$mycodeVLine $mycodeEmptyOrNonExistentHashError"
      sleep 5
      mycode_hash_unset_path
    fi
  done
}

# Paramters: <defaultHashPath> <bssid> <essid>
mycode_hash_get_path() {
  # Assure we've got the bssid and the essid passed in.
  if [ ${#@} -lt 2 ]; then return 1; fi

  while true; do
    mycode_hash_unset_path
    if ! mycode_hash_set_path "$@"; then
      echo "Failed to set hash path." > $mycodeOutputDevice
      return -1 # WARNING: The recent error code is NOT contained in $? here!
    else
      echo "Hash path: \"$mycodeHashPath\"" > $mycodeOutputDevice
    fi

    if mycode_hash_verify "$mycodeHashPath" "$2" "$3"; then
      break;
    fi
  done

  # At this point mycodeHashPath will be set and ready.
}


# ================== < Attack Subroutines > ================== #
mycode_unset_attack() {
  local -r attackWasSet=${mycodeAttack:+1}
  mycodeAttack=""
  if [ ! "$attackWasSet" ]; then return 1; fi
}

mycode_set_attack() {
  if [ "$mycodeAttack" ]; then return 0; fi

  mycode_unset_attack

  mycode_header

  echo -e "$mycodeVLine $mycodeAttackQuery"
  echo

  mycode_target_show

  local attacks
  readarray -t attacks < <(ls -1 "$mycodePath/attacks")

  local descriptions
  readarray -t descriptions < <(
    head -n 3 "$mycodePath/attacks/"*"/language/$mycodeLanguage.sh" | \
    grep -E "^# description: " | sed -E 's/# \w+: //'
  )

  local identifiers=()

  local attack
  for attack in "${attacks[@]}"; do
    local identifier=$(
      head -n 3 "$mycodePath/attacks/$attack/language/$mycodeLanguage.sh" | \
      grep -E "^# identifier: " | sed -E 's/# \w+: //'
    )
    if [ "$identifier" ]; then
      identifiers+=("$identifier")
    else
      identifiers+=("$attack")
    fi
  done

  attacks+=("$mycodeGeneralBackOption")
  identifiers+=("$mycodeGeneralBackOption")
  descriptions+=("")

  io_query_format_fields "" \
    "\t$CRed[$CSYel%d$CClr$CRed]$CClr%0.0s $CCyn%b$CClr %b\n" \
    attacks[@] identifiers[@] descriptions[@]

  echo

  if [ "${IOQueryFormatFields[1]}" = "$mycodeGeneralBackOption" ]; then
    return -1
  fi

  if [ "${IOQueryFormatFields[1]}" = "$mycodeAttackRestartOption" ]; then
    return 2
  fi


  mycodeAttack=${IOQueryFormatFields[0]}
}

mycode_unprep_attack() {
  if type -t unprep_attack &> /dev/null; then
    unprep_attack
  fi

  IOUtilsHeader="mycode_header"

  # Remove any lingering targetting subroutines loaded.
  unset attack_targetting_interfaces
  unset attack_tracking_interfaces

  # Remove any lingering restoration subroutines loaded.
  unset load_attack
  unset save_attack

  mycodeTargetTrackerInterface=""

  return 1 # Trigger another undo since prep isn't significant.
}

mycode_prep_attack() {
  local -r path="$mycodePath/attacks/$mycodeAttack"

  if [ ! -x "$path/attack.sh" ]; then return 1; fi
  if [ ! -x "$path/language/$mycodeLanguage.sh" ]; then return 2; fi

  # Load attack parameters if any exist.
  if [ "$AttackCLIArguments" ]; then
    eval set -- "$AttackCLIArguments"
    # Remove them after loading them once.
    unset AttackCLIArguments
  fi

  # Load attack and its corresponding language file.
  # Load english by default to overwrite globals that ARE defined.
  source "$path/language/en.sh"
  if [ "$mycodeLanguage" != "en" ]; then
    source "$path/language/$mycodeLanguage.sh"
  fi
  source "$path/attack.sh"

  # Check if attack is targetted & set the attack target if so.
  if type -t attack_targetting_interfaces &> /dev/null; then
    if ! mycode_target_set; then return 3; fi
  fi

  # Check if attack provides tracking interfaces, get & set one.
  # TODO: Uncomment the lines below after implementation.
  if type -t attack_tracking_interfaces &> /dev/null; then
    if ! mycode_target_set_tracker; then return 4; fi
  fi

  # If attack is capable of restoration, check for configuration.
  if type -t load_attack &> /dev/null; then
    # If configuration file available, check if user wants to restore.
    if [ -f "$path/attack.conf" ]; then
      local choices=( \
        "$mycodeAttackRestoreOption" \
        "$mycodeAttackResetOption" \
      )

      io_query_choice "$mycodeAttackResumeQuery" choices[@]

      if [ "$IOQueryChoice" = "$mycodeAttackRestoreOption" ]; then
        load_attack "$path/attack.conf"
      fi
    fi
  fi

  if ! prep_attack; then return 5; fi

  # Save the attack for user's convenience if possible.
  if type -t save_attack &> /dev/null; then
    save_attack "$path/attack.conf"
  fi
}

mycode_run_attack() {
  start_attack
  mycode_target_tracker_start

  local choices=( \
    "$mycodeSelectAnotherAttackOption" \
    "$mycodeGeneralExitOption" \
  )

  io_query_choice \
    "$(io_dynamic_output $mycodeAttackInProgressNotice)" choices[@]

  echo

  # IOQueryChoice is a global, meaning, its value is volatile.
  # We need to make sure to save the choice before it changes.
  local choice="$IOQueryChoice"

  mycode_target_tracker_stop


  # could execute twice
  # but mostly doesn't matter
  if [ ! -x "$(command -v systemctl)" ]; then
    if [ "$(systemctl list-units | grep systemd-resolved)" != "" ];then
        systemctl restart systemd-resolved.service
    fi
  fi

  if [ -x "$(command -v service)" ];then
    if service --status-all | grep -Fq 'systemd-resolved'; then
      sudo service systemd-resolved.service restart
    fi
  fi

  stop_attack

  if [ "$choice" = "$mycodeGeneralExitOption" ]; then
    mycode_handle_exit
  fi

  mycode_unprep_attack
  mycode_unset_attack
}

# ============================================================ #
# ================= < Argument Executables > ================= #
# ============================================================ #
eval set -- "$mycodeCLIArguments" # Set environment parameters.
while [ "$1" != "" -a "$1" != "--" ]; do
  case "$1" in
    -t|--target) echo "Not yet implemented!"; sleep 3; mycode_shutdown;;
  esac
  shift # Shift new parameters
done

# ============================================================ #
# ===================== < mycode Loop > ===================== #
# ============================================================ #
mycode_main() {
  mycode_startup

  mycode_set_resolution

  # Removed read-only due to local constant shadowing bug.
  # I've reported the bug, we can add it when fixed.
  local sequence=(
    "set_language"
    "set_attack"
    "prep_attack"
    "run_attack"
  )

  while true; do # mycode's runtime-loop.
    mycode_do_sequence mycode sequence[@]
  done

  mycode_shutdown
}

mycode_main # Start mycode

# mycodeSCRIPT END
