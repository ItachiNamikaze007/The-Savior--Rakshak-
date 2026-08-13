# App Icon Setup

## Current Status
The project uses default Android launcher icons. For a production app, you should create custom icons.

## Creating Custom Icons

### Option 1: Android Studio Asset Studio
1. Right-click on `res` folder
2. New → Image Asset
3. Choose icon type: Launcher Icons
4. Select foreground asset (image or clipart)
5. Customize background color
6. Click "Next" → "Finish"

### Option 2: Manual Creation
Create PNG files in these sizes and place in respective folders:

- `mipmap-mdpi/ic_launcher.png` - 48x48 px
- `mipmap-hdpi/ic_launcher.png` - 72x72 px
- `mipmap-xhdpi/ic_launcher.png` - 96x96 px
- `mipmap-xxhdpi/ic_launcher.png` - 144x144 px
- `mipmap-xxxhdpi/ic_launcher.png` - 192x192 px

### Recommended Icon Design
For Emergency Mesh, consider:
- **Red/Orange color** - Emergency alert feel
- **Signal waves** - Mesh network representation
- **SOS symbol** - Clear emergency indication
- **Simple design** - Recognizable at small size

### Free Icon Tools
- **Android Asset Studio**: https://romannurik.github.io/AndroidAssetStudio/
- **Icon Kitchen**: https://icon.kitchen/
- **Figma**: Free design tool with icon templates

## Current Default
The app currently uses the standard Android robot icon. This works for development/testing but should be replaced before any real deployment.

## Note
Icons are purely cosmetic and do not affect the app's functionality. The mesh networking, SOS, and voice features all work with the default icon.
