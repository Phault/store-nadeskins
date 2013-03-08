store-nadeskins
============

### Description
Store module that allows players to buy custom models for their grenades in the store.

### Requirements

* [Store](https://forums.alliedmods.net/showthread.php?t=207157)
* [SDKHooks](http://forums.alliedmods.net/showthread.php?t=106748) 
* [SMJansson](https://forums.alliedmods.net/showthread.php?t=184604)

### Features

* **Customizable** - You can have any amount of models you want.
* **Models are downloaded automatically** - You don't need to configure that.

### Installation

Download the `store-nadetrails.zip` archive from the plugin thread and extract to your `sourcemod` folder intact. Then open your store web panel, navigate to Import/Export System under the Tools menu, and import configs/store/json-import/nadetrails.json.

### Adding More Skins

You can use the web panel to add nadeskins. Open the web panel, navigate to Add New Item under the Items menu. In type and loadout_slot, type nadeskin. Change name, display_name, description and attrs to customize the new trail. 

The attrs field should look like:

    {
        "model": "models/props/de_tides/Vending_turtle.mdl"
    }

