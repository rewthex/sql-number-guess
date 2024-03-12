#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guessing_game -t --no-align -c"
RANDOM_NUMBER=$((1 + RANDOM % 1000))
GUESSES=0

VALIDATE_USERNAME() {
  local USERNAME_LENGTH=${#1}
  if [[ USERNAME_LENGTH -gt 22 ]]; then
    echo "Username can't be greater than 22 characters."
    MAIN_MENU
  fi
}

CREATE_USER() {
  $PSQL "INSERT INTO users(username) VALUES('$1')" > /dev/null
  echo "Welcome, $1! It looks like this is your first time here."
}

GET_USER_INFO() {
  local USER_INFO=$($PSQL "SELECT username, games_played, best_game FROM users WHERE username = '$1'")
  echo "$USER_INFO"
}

WELCOME_BACK_MESSAGE() {
  IFS='|' read -r NAME GAMES_PLAYED BEST_GAME <<< "$1"
  echo "Welcome back, $NAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
}

MAIN_MENU() {
  # prompt user for valid username
  echo "$RANDOM_NUMBER"
  echo "Enter your username:"
  read USERNAME
  VALIDATE_USERNAME $USERNAME
  USER_INFO=$(GET_USER_INFO $USERNAME)

  # create user if none exists
  if [[ -z $USER_INFO ]]
  then
    CREATE_USER $USERNAME
  else
    WELCOME_BACK_MESSAGE $USER_INFO
  fi
  echo "Guess the secret number between 1 and 1000:"
  PLAY_GAME $USERNAME
}

PLAY_GAME() {
  read GUESS
  # check for valid integer
  if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    PLAY_GAME $1
  fi
  ((GUESSES++))
  if [[ $GUESS -eq $RANDOM_NUMBER ]]; then
    echo "You guessed it in $GUESSES tries. The secret number was $RANDOM_NUMBER. Nice job!"
    $PSQL "UPDATE users SET games_played = games_played + 1 WHERE username = '$1'" > /dev/null
    BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE username = '$1'")
    if [[ $GUESSES -lt $BEST_GAME || $BEST_GAME -eq 0 ]]; then
      $PSQL "UPDATE users SET best_game = '$GUESSES' WHERE username = '$1'" > /dev/null
    fi
  elif [[ $GUESS -lt $RANDOM_NUMBER ]]; then
    echo "It's higher than that, guess again:"
    PLAY_GAME $1
  elif [[ $GUESS -gt $RANDOM_NUMBER ]]; then
    echo "It's lower than that, guess again:"
    PLAY_GAME $1
  fi
}

MAIN_MENU