Здесь должна быть папка Assets с файлами русификации (тексты, озвучка, шрифты, Lua).
В публичный репозиторий она не входит — это файлы самой игры. Без неё install.sh не
работает, а «1. Установить или обновить» пропускает шаг русификации.

The Russian payload (Assets/...) goes here. It is not published: it contains the
game's own files. Without it, install.sh won't run and the installer skips that step.
