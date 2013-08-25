---
author: idunning
comments: false
date: 2013-05-13 07:17:12+00:00
layout: post
slug: experiences-with-xmonad-and-ubuntu-12
title: Experiences with Setting Up Xmonad on Ubuntu 12
---

After being impressed with a friends [Xmonad](http://xmonad.org/) setup, I decided to give it a go for myself. [Xmonad](http://xmonad.org/), in short, is a [window manager](http://en.wikipedia.org/wiki/Window_manager) that automatically tiles and aligns all your windows - the idea being that you shouldn't mess around with these things manually yourself, because you usually want your windows to fill up the screen anyway. Before switching to Ubuntu+XMonad I primarily used Windows 7. I used the Windows-Left and Windows-Right key combinations to align two windows side-by-side all the time, so this appealed to me. I had also been meaning to use Linux on a more full-time basis, as I previously only used it when needed, usually as a virtual machine guest. This summer I will be using it a lot more so I figured why not fully embrace it. So here is my journey to going from a Windows installation to a dual-boot Ubuntu/Win7 install with Xmonad as my window manager, written mostly in real-time as I did it. Hopefully it may help someone get started - there are many posts about this sort of thing on the internet, but maybe this simpler step-by-step guide will be easier to understand than downloading a configuration file.

_Update_: After writing this post and its updates, I posted my configuration files on Github: [https://github.com/IainNZ/dotfiles](https://github.com/IainNZ/dotfiles). I'm also aware that there are posts/configs that include the Ubuntu panel - I haven't bothered to figure that out yet, but I hope to one day get around to it.

## Initial Setup: Install Ubuntu, xmonad, Xmobar, simple configs

  * Luckily I had partitioned my harddrive into a 120Gb and a ~60Gb partition beforehand, so the first thing I did was move everything I wanted off the 60Gb into the 120Gb partition.
  * Next, I downloaded the ISO file for [Ubuntu 12.04 LTS 64-bit](http://www.ubuntu.com/download/desktop) and a program to "burn" the [ISO to a USB stick](http://www.pendrivelinux.com/universal-usb-installer-easy-as-1-2-3/). I'd never done this before, used to just use CDs, so was pleased to see how easy it was.
  * After doing that, I rebooted and hit F12 to change the device boot order to start from the USB stick.
   Ubuntu starts up. I used Gparted to remove the 60Gb partition and then started the installer. It automatically detects the empty space and uses it up, allocating exactly 4Gb for a swap partition. I learnt that having a big enough swap partition matters quite a bit even if you don't plan to be in a situation where you will be swapping to disk: when you hibernate, [it saves memory to the swap space](http://www.howtogeek.com/113923/how-to-re-enable-hibernate-in-ubuntu-12.04/), rather than a file in the normal filesystem (as in Windows).
  * After rebooting again, we are presented with a choice of operating systems. Windows still works, so thats nice (I've managed to nuke my Windows install before...). Booting into Ubuntu, we arrive in the default desktop environment.
  * I started up a terminal (in case you were initially confused by the Unity interface, like me, you click the icon in the top left and type in what you want, in this case _terminal_) and installed xmonad through the package manager: _sudo apt-get install xmonad_
  * I then logged out. Now, to log-in with xmonad as my window manager, I click the little Ubuntu icon next to my name and selected "XMonad" (not "GNOME with Xmonad" - the subtleties escape me at the moment...). After typing in my password and hitting enter, nothing seem to happen except the log-in screen goes away.
  * Its not broken - there is just nothing open. Hitting _alt-shift-enter_ opens a terminal, and hitting it again opens another, putting them side-by-side. You can move the mouse to shift focus, or press _alt-j_ and _alt-k_ to cycle between windows. For more shortcuts, I found [this tour](http://xmonad.org/tour.html) really helpful. Helpful tip, if you need to bail out of XMonad before going on: to log out, _alt-shift-q_ will work.
  * If you are anything like me, you'll find the idea of using alt for managing windows like this a bit unnatural. Given that the Windows key is on my keyboard, makes sense to me to use that instead. Fortunately this is pretty easy to do and is my first customization of xmonad. Apparently customization is another of the virtues of Xmonad, and you actually write the configuration file as a [Haskell](http://en.wikipedia.org/wiki/Haskell_(programming_language)) script!
    * First we need a directory to store our configuration (``mkdir ~/.xmonad``), and to create and edit the config file itself (e.g. ``nano ~/.xmonad/xmonad.hs``)
    * The code we'll use is as follows (from [here](http://www.haskell.org/haskellwiki/xmonad/Frequently_asked_questions#Rebinding_the_mod_key_.28Alt_conflicts_with_other_apps.3B_I_want_the_____key.21.29)):
{% highlight haskell %}
import XMonad

main = xmonad defaultConfig
         { modMask = mod4Mask
         }
{% endhighlight %}
  * The above code says to run xmonad according to the default values except for the modifications listed in this key-value structure. _mod4Mask_ indicates the Windows key for most keyboards. To use the new settings, press _alt-q_ to reload xmonad.hs. Test it out by creating a new terminal with _win-shift-enter_, and close it with _win-shift-c_
  * This is all rather barebones, although I kind of like how clean it is. I installed two packages that seem to come fairly highly recommended: [dmenu](http://tools.suckless.org/dmenu/), a progam launcher, and [xmobar](http://projects.haskell.org/xmobar/), a status bar progam.
    * First up, dmenu: ``sudo apt-get install suckless-tools``
    * Press _win-p_ to bring it up. We're presented with a list of program names. Start typing a name, e.g. firefox, to get auto-suggestions. Easy!
    * Next, xmobar: ``sudo apt-get install xmobar``
    * We need to create a configuration file, much like we did for xmonad itself. There is an example file [here](http://www.haskell.org/haskellwiki/Xmonad/Config_archive/John_Goerzen%27s_Configuration#Configuring_xmobar), which is pretty intense at first but you can break it down. Create the file with, e.g. ``nano ~/.xmobarrc`` and copy-paste the default config from above. For now, I just changed the weather station from EGPF to KBOS (for Boston Logan International Airport).
    * Finally we extend our xmonad.hs to connect it to xmobar. I used the relevant sections from [here](http://www.haskell.org/haskellwiki/xmonad/Config_archive/John_Goerzen%27s_Configuration#Configuring_xmonad_to_use_xmobar).

{% img /images/xmonadsshot.png Screenshot showing a typical Xmonad layout with Xmobar %}

## Adventures with Multiple Monitors

At my office I use a dual monitor setup. Unfortunately it was not a matter of plug-and-play, but it wasn't too hard to get it working:

  * I logged into Unity, and setup my screens so they weren't cloned. Not sure if this was necessary/helped
  * I logged into xmonad, and the screens were cloned - not good!
  * Running the xrandr command listed my screens - now I know what they are called, I can change them!
  * The following command solved my issues: ``xrandr --output HDMI-1 --auto --left-of LVDS-1``
    * ``--output`` is the screen we want to deal with (in this case, I'm connected via HDMI)
    * ``--auto`` means to use the default resolution for that monitor
    * ``--left-of LVDS-1`` means that the screen is physically to the left of my laptop's screen
  * Now, unfortunately, xmobar only shows up on my laptop screen. I haven't quite figured out how to make it appear on both, but you can make it appear on the main screen using ``xrandr --output HDMI-1 --primary`` (via [this post](http://blog.ezyang.com/2011/06/multi-monitor-xmobar-placement-on-nome/))

## Volume Control in Xmonad/Xmobar

So after getting set up and using the system a bit, I realized I had no idea a) how to see what the volume is, and b) how to change it. I'm going to deal with (b) first, using the info [here](http://superuser.com/questions/389737/how-do-you-make-volume-keys-and-mute-key-work-in-xmonad).

  * First we need to add a new import to allow us to configure some new key combinations at the top of xmonad.hs, that is very common in a lot of configs: ``import XMonad.Util.EZConfig(additionalKeys)``
  * Next we import some user-friendly names for the "special" keys on our keyboard: ``import Graphics.X11.ExtraTypes.XF86``
  * The ``additionalKeys`` is going to go after our ``defaultConfig`` section, and will look like this:
{% highlight haskell %}
`additionalKeys`
    [ ((0 , xF86XK_AudioLowerVolume), spawn "amixer set Master on && amixer set Headphone on && amixer set Master 2-"), 
      ((0 , xF86XK_AudioRaiseVolume), spawn "amixer set Master on && amixer set Headphone on && amixer set Master 2+"),
      ((0 , xF86XK_AudioMute), spawn "amixer set Master toggle && amixer set Headphone toggle") ]
    ]
{% endhighlight %}
  * The above is pretty complicated, but there is a reason: the problem seems to be that toggling the Master volume control turns Headphone off, but toggling it again does not turn it on, see [here](http://ubuntuforums.org/showthread.php?t=1796713) or [here](http://askubuntu.com/questions/65764/how-do-i-toggle-sound-with-amixer). Something is still not totally right with the unmute button, it seems to work after after a random time, but pressing a volume key to unmute works fine.
  * Now we want to display the volume in Xmobar. It seems the best way is to have a little script that takes the output of amixer and parses the volume from it.  Lets break it down:
    * ``amixer get master`` spits out the volume info, including a volume percentage.
    * We pipe that into ``awk``, this (crazy/awesome) command line text processing tool
    * We are going to pass the command ``-F'[\[\]]'`` to ``awk`` first. ``-F`` is the field seperator argument - this is what we are going to "split" on (the square brackets)
    * Next we want to get out the percentage - the second field: ``'{print $2}'``
    * If you run what we have so far, you notice we get a lot of blank lines - this is from the lines that didn't match our pattern (I think). We pipe the output into ``tail -n 1`` to just get the last line
    * What happens if we mute it? It still shows the volume... But, ``$6`` (the sixth field) has the on/off info we need. So lets modify our print statement to ``'{if ($6 == "off") { print "MUT"; } else { print $2; }}'``
    * Putting it all together: ``amixer get Master | awk -F'[\[\]]' '{if ($6 == "off") {print "MUT"; } else { print $2; }}' | tail -n 1``
  * I put this in a script ``getvolume.sh``, and modified my ``.xmobarrc`` to have the following line which is pretty self explanatory (the 10 is the refresh rate):  ``Run Com "/home/idunning/getvolume.sh" [] "vol" 10``
  * Finally put ``%vol%`` in your formatting string and restart Xmonad/Xmobar with Win-q - looks good!

## Putting my dotfiles on Github

Many people on Github have "dotfiles" repositories - basically a repo for all the little configuration files that you see above, as well as others. This [post](http://blog.smalleycreative.com/tutorials/using-git-and-github-to-manage-your-dotfiles/) really says it all better than I can, but basically its a cool idea and not only provides a backup for your configs, it also makes your experience homogenous across computers. The second factor was actually what motivated me to finally do it, as I just started an internship at Google. My repository is at [https://github.com/IainNZ/dotfiles](https://github.com/IainNZ/dotfiles) - there is nothing in there that is too fancy, but it might make the above more understandable. The best thing about it is in installation script, which puts symlinks to the dotfiles rather than copying them - allowing easy updates with a simple ``git pull``.
