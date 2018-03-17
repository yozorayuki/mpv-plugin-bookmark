# mpv-plugin-bookmark
#### mpv plugin for recording last play in current playing folder and you can resume to play
this plugin will also load the playlist from the playing folder automatically

###### Usage
* Copy `bookmark.lua` script to `~/.config/mpv/scripts/`
* You can config the shortcut key for playlist-next and playlist-prev which is "end" and "home" by default<br>
  save_period mean how many seconds the this will plugin save playback progress, quit and puse alse trigger saving<br>
  the config file path is `~/.config/mpv/lua-settings/bookmark.conf` , you may need to create it, for example:
```
playlist_prev=home
playlist_next=end
save_period=30
```
