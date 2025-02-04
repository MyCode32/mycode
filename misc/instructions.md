### mycode instructions
Blackarch and arch strike already include this tool, kali doesn't. But you could try to mycode with: `./mycode`

#### Step 1: Cloning the git repository
`git clone https://github.com/MyCode32/mycode`

#### Step 2: Execute mycode
Just navigate to the mycode directory or the directory containing the scripts in case you downloaded them manually. If you are following the terminal commands I'm using, then it's just a simple change directory command for you. After you can execute the script.
```
cd mycode
./mycode -i 
```

Your unmet dependencies will be resolved, and then you can use mycode.<br>
**Note** You can try parameter `-i` which allows mycode, auto install dependencies.

#### Step 3: Select language
Make sure your select the right language. mycode does support over 10+ languages. If there are any spelling errors, let us know or submit a pull request. 

#### Step 4: Select interface
Select a prober interface make sure that it support AP mode and master mode. Both are required for mycode. You can check both if you run the diagnostic script, located inside the scripts folder. You only has to do as root `./diagnostic [interface]`.

#### Step 5: Gather handshake
In order to make sure that mycode can check if there is a valid password you have to make sure that you gather handshake first. Run the handshake snooper attack first. Select and deauth option and a delay.

#### Step 6: Start ap mode
Now, after gathering the handshake you can run the AP. Select the ssl option and your favorite login site. Generic sites and custom router sites are supported. You can also use your own by running the router.sh script.

#### Exit codes
**Check exit code with:** `echo $?`

| Exit codes  |  Reason  |  Solution  |
| :--: |---|---|
| **1** |  Aborted, please execute the script as root. |  `sudo ./mycode` |
| **2** |  Aborted, X (graphical) session unavailable. |  Run mycode in a grafical session |
| **3**  | Aborted, xdpyinfo is unavailable.  | ```apt-get install xdpyinfo```   |
| **4** | Aborted, xterm test session failed. | Run mycode in a grafical session |
| **5** | Aborted, enhanced getopt isn't available. | Depend on your package manager |
| **6** | Aborted, can't generate a workspace directory. | Make sure you have some diskspace left |
