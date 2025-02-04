#!/usr/bin/env bash

mycode_help(){
  echo " mycode(1)                       User Manuals                       mycode(1)



  NAME
         mycode  -  mycode  is  a  security  auditing  and  social-engineering
         research tool

  SYNOPSIS
         mycode [-debug] [-l language ] attack ...

  DESCRIPTION
         mycode is a security auditing and  social-engineering  research  tool.
         It  is  a remake of linset by vk496 with (hopefully) less bugs and more
         functionality. The script attempts to retrieve the WPA/WPA2 key from  a
         target  access point by means of a social engineering (phising) attack.
         It's compatible with the latest release of  Kali  (rolling).  mycode's
         attacks'  setup  is  mostly  manual, but experimental auto-mode handles
         some of the attacks' setup parameters.

  OPTIONS
         -v     Print version number.

         --help Print help page and exit with 0.

         -m     Run mycode in manual mode instead of auto mode.

         -k     Kill wireless connection if it is connected.

         -d     Run mycode in debug mode.

         -x     Try to run mycode with xterm terminals instead of tmux.

         -r     Reload driver.

         -l <language>
                Define a certain language.

         -e <essid>
                Select the target network based on the ESSID.

         -c <channel>
                Indicate the channel(s) to listen to.

         -a <attack>
                Define a certain attack.

         --ratio <ratio>
                Define the windows size. Bigger ratio ->  smaller  window  size.
                Default is 4.

         -b <bssid>
                Select the target network based on the access point MAC address.

         -j <jamming interface>
                Define a certain jamming interface.

         -a <access point interface>
                Define a certain access point interface.

  FILES
         /tmp/fluxspace/
                The system wide tmp directory.
         $mycode/attacks/
                Folder where handshakes and passwords are stored in.

  ENVIRONMENT
         mycodeAuto
                Automatically run mycode in auto mode if exported.

         mycodeDebug
                Automatically run mycode in debug mode if exported.

         mycodeWIKillProcesses
                Automatically kill any interfering process(es).

  DIAGNOSTICS
         Please checkout the other log files or use the debug mode.

  BUGS
         Please  report  any  bugs  at:  https://github.com/mycodeNetwork/flux-
         ion/issues

  AUTHOR
         Cyberfee, l3op, dlinkproto, vk496, MPX4132

  SEE ALSO
         aircrack-ng(8),


  Linux                             MARCH 2018                        mycode(1)"

}
