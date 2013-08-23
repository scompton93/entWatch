# entWatch
A Sourcemod plugin capable of watching custom map entities and displaying chat/hud messages when the entities are picked up, dropped and used. Intended to be used for materias on Mako and Predator.

![image](http://i.imgur.com/sn6X4ze.png)
![image](http://i.imgur.com/WNaYvnR.png)
![image](http://i.imgur.com/2bBKSRj.png)
![image](http://i.imgur.com/eB0zMxi.png)

## Features

* Customizable
* Displays a list of users holding the first 9 defined entities on the HUD.
* Dynamic entity finding, specify the weapon_elites classname in the config along with button type and the plugin does the rest.
* Prints a message to all users in chat when a defined entity is picked up, dropped, used.
* **Dynamic entity finding gives you:**
  * Finds the entities every round for maps that like to delete entities and change entities often.
  * Allows partial names in the config for maps like ze_predator that have terrible names.
  * Supports multiples of entities, just list the entity twice in the config.

## Notes
* Mod is currently solid as a rock. No reported crashes.
* **This plugin features 2 console commands:**
  * entW_dumpmap - Dumps all the entities it has loaded into memory. (-1 Is the value of an entity until it finds the entity. entities are not found until they are picked up).
  * entW_find - Usage: "entw_find weapon_elite" this will output every entity matching weapon_elite on the map, use the classnames for configs.
  * There is also no reason why this wouldn't support other gamemodes featuring map weapons.
* Theres no real support for this but if you email me (sean.compton@mail.ru) I will do my best to help.
* Use Hammer to find entities. Use BSPSrc to decompile instead of vmex.
## Credits
* Prometheum - Coding.
* Bauxe - Map configs/testing/idea.

## Translations
These were submitted by the community:
French: https://forums.alliedmods.net/showpost.php?p=2003654&postcount=38
Chinese: https://forums.alliedmods.net/showpost.php?p=1991021&postcount=31