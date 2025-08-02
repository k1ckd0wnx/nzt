# 🎲 Icon Troubleshooting Guide

## Issue: Premium Casino app has no icon in fd_laptop

### 🔧 **What This Version Does:**

This version automatically tries **6 different icon paths** when registering with fd_laptop:

1. `nui://your-resource-name/assets/icon.svg`
2. `nui://your-resource-name/dice.svg` 
3. `dice.svg`
4. `assets/icon.svg`
5. `https://cfx-nui-your-resource-name/dice.svg`
6. `https://cfx-nui-your-resource-name/assets/icon.svg`

### 📋 **Check Server Console:**

When you restart your server, look for these messages:

```
[Casino] Trying icon path 1: nui://your-resource/assets/icon.svg
[Casino] Icon path 1 failed: [error message]
[Casino] Trying icon path 2: nui://your-resource/dice.svg
[Casino] Icon loaded successfully with path: nui://your-resource/dice.svg
```

### ✅ **If Icon Still Doesn't Show:**

1. **Check resource name**: Make sure your folder is named correctly
2. **Check file permissions**: Ensure `dice.svg` and `assets/icon.svg` are readable
3. **Try different format**: Some systems prefer PNG over SVG
4. **Check fd_laptop version**: Older versions might handle icons differently

### 🎨 **Icon Files Included:**

- `dice.svg` - Main blue dice icon (64x64)
- `assets/icon.svg` - Backup copy in assets folder
- `assets/icon.png` - Placeholder for PNG version (you can replace this)

### 🔄 **Manual Icon Fix:**

If automatic detection fails, you can manually edit `server/main.lua` line ~28 and set:

```lua
icon = "your-working-icon-path-here",
```

Common working paths:
- `"dice.svg"`
- `"nui://your-resource-name/dice.svg"`
- `"assets/icon.svg"`

### 📞 **Still Need Help?**

Share the server console output showing which icon paths were tried - this will help identify the correct format for your fd_laptop version.