# Nati DCS Tools

**IMPORTANT**
All of my script depends on MIST scripting tools.


Before using these tools make sure that you have an updated version of [MIST](https://github.com/mrSkortch/MissionScriptingTools) loaded into your mission, before loading any of these scripts.  
Loading [MIST](https://github.com/mrSkortch/MissionScriptingTools) into **INITIALIZATION SCRIPT** part (triggers page) is preferable.

## Simple Radar Detection
(Using polling of detecting status)
### How to use
1. Save the file: [natidcs-radar-detection.lua](https://raw.githubusercontent.com/nati-mask/natidcs/main/natidcs-radar-detection.lua) and load it as a `ONCE MISSION START`, `DO SCRIPT FILE` trigger.
1. Add another action of `DO SCRIPT` to the `ONCE MISSION START` event (right after the last `DO SCRIPT FILE`).
1. Example code, to call the script:
    ```lua
    -- Add Radar Detection...

    natidcs.isGroupsRadarDetectedBy(

    {
    'SAM-SA6-1-TR',
    'SAM-SA6-1-2'
    },

    {
    'Aerial-1'
    },

    10

    )
    ```
    Explanation:
    - In the **first** curly brackets pair you put one or more **Detecting Units** **NAMES**, for each unit you want the script to check what it's detecting, separated with commas.
    - In the **second** curly brackets pair you put one or more **Detected Groups** **NAMES**, here you put group names of the units you want to be checked for detection.  
    The flag will get true only when units from these groups are detected.
    - The number (`10`, in the example) will be the **flag** number which will becomes true after the first unit is detected.

## Zones Units Type Counters
![Zones Units Type Counters](img/zones-count-units.jpg)
### How to use
1. Create one or more zones with the Property `COUNT_UNIT_TYPES`.
1. Save the file: [natidcs-zones-count-units.lua](https://raw.githubusercontent.com/nati-mask/natidcs/main/natidcs-zones-count-units.lua) and load it as a `ONCE MISSION START`, `DO SCRIPT FILE` trigger.
1. That's it! The script will count units by types on each zone, and add F10 menu to query the counts.
1. Optional - If you want to not report counts on unit dead event, please remove the last(?) line of the script, the one which says
    ```lua
    mist.addEventHandler(...
    ```

---
Thank you :)

Nati Mask

