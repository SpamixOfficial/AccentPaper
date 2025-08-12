# AccentPaper - Automatically set your accent color based on your wallpaper

AccentPaper is an application to automatically match your accent color against your wallpaper, since this (somehow) isn't a feature yet in macOS!

## Why?

When developing I always got a bit annoyed with the fact that the dynamic wallpaper changed colors automatically, but the accent color didn't. Of course I could set a static color for the wallpaper so I didn't have to update my accent color, but that was a mediocre solution since we all need some variation in our lives, don't we?

So, the "idea" (aka non-existent basic feature) of AccentPaper was born!

## Installing

The app is currently available to install from github releases.

Simply download the dmg file and drag the app into your applications folder, now you're done!

**Homebrew is planned!**

## Running the app

Just launch the app, and you should see a pretty little rainbow appear in your taskbar. Click it, and there you'll have some basic options for the application.

### Why the hell is the app asking for screenshot permissions?

Oh boy do I have a reasonable explanation!

When I was coding this thing the plan was to simply snatch the wallpaper, get the colors out of it and choose the most prominent one. Though it turns out that the inbuilt API doesn't return the path for dynamic wallpapers, and it is filled with funny quirks. So I fell back to a niche plist file located in your home library.

Well, AGAIN it turns out that - nope, no path for the dynamic wallpapers there either, and no information about the current state.

With little to no options left, the only option was to go "primal mode" and take a 1x1 pixel screenshot of the taskbar to get the background color. 

So, to summarize: No, the app has no malicious intent whatsoever, you don't need to worry! All it does is take a 1x1 screenshot of the taskbar to get the color.


## Like the project?

Then consider giving this repository a star, it really helps 🌟