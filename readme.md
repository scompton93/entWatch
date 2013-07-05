# entWatch
A Sourcemod plugin capable of watching custom map entities and displaying chat/hud messages when the entities are picked up, dropped and used. Intended to be used for materias on Mako and Predator.

![image](http://i.imgur.com/sn6X4ze.png)
![image](http://i.imgur.com/WNaYvnR.png)
![image](http://i.imgur.com/2bBKSRj.png)

## Features

* Displays a list of users holding the first 9 defined entities on the HUD.
* Dynamic entity finding, specify the weapon_elites classname in the config along with button type and the plugin does the rest.
* Prints a message to all users in chat when a defined entity is picked up, dropped, used.
* **Dynamic entity finding gives you:**
  * Finds the entities every round for maps that like to delete entities and change entities often.
  * Allows partial names in the config for maps like ze_predator that have terrible names.
  * Supports multiples of entities, just list the entity twice in the config.

## Notes
* While this mod is very hacky, it appears to be very safe in all tests as long as the config is correct. Your best bet when using this is to be 100% your config is correct.
* **This plugin features 2 console commands:**
  * entW_dumpmap - Dumps all the entities it has loaded into memory. (-1 Is the value of an entity until it finds the entity. entities are not found until they are picked up).
  * entW_find - Usage: "entw_find weapon_elite" this will output every entity matching weapon_elite on the map, use the classnames for configs.
  * There is also no reason why this wouldn't support other gamemodes featuring map weapons.
* Theres no real support for this but if you email me (sean.compton@mail.ru) I will do my best to help.

## Credits
* Prometheum - Coding.
* Bauxe - Map configs/testing/idea.