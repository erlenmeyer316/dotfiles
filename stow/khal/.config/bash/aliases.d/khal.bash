if [ $(command -v "khal") ]; then
    alias cal='khal interactive'
    alias agenda='khal list today 30d'   # 30-day lookahead
    alias today='khal list'
fi
