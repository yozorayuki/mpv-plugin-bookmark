# mpv-plugin-bookmark
#### mpv plugin to record your playing history for each folder and you can choose resume to play next time.<br>
this is the light version, if you also want it loading play list automatically, switch to master branch for the advanced version.

###### Usage
* copy `bookmark.lua` script to `~/.config/mpv/scripts/`
* you can config the value of `save_period` which means how many seconds the it will save play progress. quit and puse also trigger saving<br>
the config file's path is `~/.config/mpv/lua-settings/bookmark.conf` , you may need to create it, for example:
```
save_period=30
```
