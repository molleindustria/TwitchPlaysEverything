# Twitch Plays Everything

A simple Processing/java template for Twitch-plays-pokemon type of projects.
It creates a chatbot that connects to your Twitch channel and lets users interact with **your** computer through text commands.

* Requires [Processing](https://processing.org/) a free Java-based environment for creative coding.

* Uses [PircBot](http://www.jibble.org/pircbot.php) an IRC library for java (included in code/)

* Uses Java's [Robots](https://docs.oracle.com/javase/7/docs/api/java/awt/Robot.html) class to emulate mouse and keyboard events. There is no gamepad support.


# Setup

*Traditionally* Twitch-plays games run on dedicated machines that are streaming the output of the game through [OBS](https://obsproject.com/) or other applications. This program listens to Twitch chat messages and interprets them as input on your computer. A Twitch chat mostly functions like an IRC channel, so your bot can both receive or send messages.

1. Add your Twitch credentials to Bot.pde.
2. Add the applicationPath and applicationName if you want to manage the game launch and shutdown via Processing (not necessary)
3. Add your own keypresses in the arraylist "keys" with the associated commands
4. Add/remove other kind of commands in the parseCommand function 
5. If using mouse controls change the mouse area to your active area (MIN_X etc.)
6. Press play, make sure your game is *focused* (otherwise the commands will affect other programs)
7. Start streaming the output
8. ???
9. Profit!

You don't have to be live to test the chat functionalities, just open your offline channel and type in the chat.

# Notes

* Twitch-plays are meant to be miserable experiences but only 0.001% of the games can be successfully played in this format. Consider hybrid experiences with spectators interacting/trolling the streamer instead of playing 100% of the game.

* There is a lag of a couple of seconds between video and chat commands so choose slow, forgiving games.

* Keep in mind that the bot will never know the internal state of the game (unless it's a custom made game). 

* TwitchPlaysEverything has no built-in voting system but you can implement one with some programming. Check the [Twitch IRC specifications](https://dev.twitch.tv/docs/irc/guide).

* Twitch hides the channel description at the bottom of the page so users don't generally see the instructions. Consider setting up a stream overlay with some information on how to interact. You can use Processing's graphical capabilities for that. Check the simple scrolling text example.