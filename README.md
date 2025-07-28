# 🚗 FiveM Vehicle Spawner Script

A complete, modern, and feature-rich vehicle spawner script for FiveM servers. This script includes a beautiful NUI interface, comprehensive vehicle categories, and both client/server-side functionality.

## ✨ Features

- **Modern NUI Interface**: Beautiful, responsive web-based UI with smooth animations
- **Vehicle Categories**: Organized vehicle categories (Sports Cars, Super Cars, Motorcycles, Aircraft, Emergency)
- **Search Functionality**: Real-time search through vehicles
- **Permission System**: Built-in permission checking with ACE support
- **ESX Compatibility**: Optional ESX framework integration
- **Multiple Spawn Methods**: Commands, NUI menu, and key bindings
- **Vehicle Management**: Automatic cleanup, spawn upgrades, and deletion
- **Admin Commands**: Server management and status commands
- **Logging System**: Comprehensive vehicle spawn logging

## 📋 Requirements

- **FiveM Server** (Build 2189 or higher recommended)
- **Basic server setup** with resource loading capability
- **Optional**: ESX Framework (if using ESX features)

## 🚀 Installation

1. **Download/Copy** all the script files to your server
2. **Place** the script folder in your server's `resources` directory
3. **Rename** the folder to `vehiclespawner` (or your preferred name)
4. **Add** the resource to your `server.cfg`:
   ```
   ensure vehiclespawner
   ```
5. **Restart** your server or use `refresh` and `start vehiclespawner`

## 📁 File Structure

```
vehiclespawner/
├── fxmanifest.lua          # Resource manifest
├── shared/
│   └── config.lua          # Configuration file
├── client/
│   └── main.lua           # Client-side script
├── server/
│   └── main.lua           # Server-side script
├── html/
│   ├── index.html         # NUI HTML
│   ├── style.css          # NUI Styling
│   └── script.js          # NUI JavaScript
└── README.md              # This file
```

## ⚙️ Configuration

Edit `shared/config.lua` to customize the script:

### Basic Settings
```lua
Config.Debug = true                    -- Enable/disable debug messages
Config.UseESX = false                  -- Enable ESX integration
```

### Commands
```lua
Config.Commands = {
    spawnVehicle = 'spawnveh',         -- Spawn vehicle command
    deleteVehicle = 'dv',              -- Delete vehicle command
    openMenu = 'vehspawner'            -- Open menu command
}
```

### Permissions
```lua
Config.AllowedGroups = {
    'admin',
    'mod',
    'superadmin'
}
```

### Spawn Settings
```lua
Config.SpawnSettings = {
    deleteOldVehicle = true,           -- Delete previous vehicle
    spawnInVehicle = true,             -- Put player in spawned vehicle
    spawnUpgraded = false,             -- Spawn with max upgrades
    maxDistance = 5.0                  -- Spawn distance from player
}
```

## 🎮 Usage

### For Players

#### Key Bindings
- **F6**: Open/Close vehicle spawner menu
- **ESC**: Close menu

#### Commands
- `/spawnveh [model]` - Spawn a specific vehicle by model name
- `/dv` - Delete your current vehicle
- `/vehspawner` - Open the vehicle menu

#### NUI Menu
1. Press **F6** to open the menu
2. Browse categories or use the search bar
3. Click on any vehicle to spawn it
4. Use the "Delete Current Vehicle" button to remove your vehicle

### For Admins

#### Admin Commands
- `/givecar [player_id] [model]` - Give a vehicle to another player
- `/vehspawner_reload` - Reload the resource
- `/vehspawner_status` - Check script status

#### Console Commands
- `givecar [player_id] [model]` - Give vehicle from server console

## 🔐 Permissions

### ACE Permissions
Add to your `server.cfg`:
```
add_ace group.admin vehiclespawner.use allow
add_ace group.mod vehiclespawner.use allow
```

### ESX Integration
If using ESX, the script checks for admin groups defined in the config.

### Development Mode
By default, the script allows everyone to use it for testing. Change the `hasPermission()` function in `server/main.lua` for production use.

## 🚗 Vehicle Categories

The script includes 5 pre-configured categories:

1. **Sports Cars**: High-performance sports vehicles
2. **Super Cars**: Exotic supercars and hypercars
3. **Motorcycles**: Various motorcycle models
4. **Aircraft**: Helicopters and planes
5. **Emergency**: Police, ambulance, and fire vehicles

### Adding Custom Vehicles

Edit the `Config.VehicleCategories` in `shared/config.lua`:

```lua
{
    name = 'Custom Category',
    vehicles = {
        {name = 'Vehicle Display Name', model = 'vehicle_model'},
        {name = 'Another Vehicle', model = 'another_model'}
    }
}
```

## 🎨 Customization

### UI Themes
Modify `html/style.css` to change colors, fonts, and animations.

### Vehicle Lists
Add or remove vehicles in `shared/config.lua` under `Config.VehicleCategories`.

### Spawn Behavior
Adjust spawn settings in the config file to change how vehicles are spawned.

## 🐛 Troubleshooting

### Common Issues

**Menu not opening:**
- Check F6 key binding conflicts
- Verify NUI files are loading correctly
- Check console for JavaScript errors

**Vehicles not spawning:**
- Verify vehicle model names are correct
- Check permissions
- Ensure player has space to spawn vehicle

**Permission errors:**
- Check ACE permissions setup
- Verify ESX configuration if using ESX
- Check server console for permission logs

### Debug Mode
Enable debug mode in config to see detailed console output:
```lua
Config.Debug = true
```

## 📝 Changelog

### Version 1.0.0
- Initial release
- Complete NUI interface
- Vehicle categories and search
- Permission system
- ESX compatibility
- Admin commands
- Comprehensive logging

## 🤝 Support

For support, issues, or feature requests:
1. Check the troubleshooting section
2. Enable debug mode for detailed logs
3. Create an issue with detailed information

## 📄 License

This project is open source. Feel free to modify and distribute according to your needs.

## 🙏 Credits

- **UI Design**: Modern gradient themes and animations
- **Vehicle Models**: Standard GTA V vehicle models
- **Framework**: Built for FiveM/CitizenFX

---

**Enjoy your new vehicle spawner! 🚗💨**