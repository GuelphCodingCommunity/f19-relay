#!/usr/bin/env bash

DEBUG_ENABLED=0

# Will disable prints if DEBUG_ENABLED is 0.
function debug() {
    if (( DEBUG_ENABLED != 0 )); then
        echo "debug: $@"
    fi
}

# will attempt to use a package manager to install the missing program, will still stop the script
# but it should be installed
function installProg() {
    progName=$1

    echo "You are missing '$progName', attempting to install...."


    # try to install using apt-get
    if command -v apt-get &>/dev/null; then
        echo "Using 'apt-get' to install '$progName'"

        sudo apt-get update
        sudo apt-get install -y "$progName"
        exit 1
    fi

    # try to install using apt-get
    if command -v dnf &>/dev/null; then
        echo "Using 'dnf' to install '$progName'"

        sudo dnf install -y "$progName"
        exit 1
    fi

    # try to install using homebrew
    if  command -v brew &>/dev/null; then
        echo "Using 'homebrew' to install '$progName'"

        brew install "$progName"
        exit 1
    fi

    # try to install using macports
    if  command -v port &>/dev/null; then
        echo "Using 'port' to install '$progName'"

        sudo port install "$progName"
        exit 1
    fi

    printf "\e[31mCould not find a package manager. $progName is not installed. Please install it manually!\e[0m\n"
    exit 1
}

if ! command -v python3 &>/dev/null; then
    installProg 'python3'

    printf "\e[31mRe-run this script to try again\e[0m\n"
    exit 1
fi

# check if git is installed on the platform
if ! command -v git &>/dev/null; then
    installProg 'git'
    printf "\e[31mRe-run this script to try again\e[0m\n"
    exit 1
fi

isEmail=$(git config -l | grep "user\.email" | wc -l)
isName=$(git config -l | grep "user\.name" | wc -l)


if [ $isEmail -eq 0 ]; then
    echo "Git does not know your email"
    read -p "Please enter your email address: " email

    printf "\e[96mrunning: 'git config --global user.email \"$email\"'\e[0m..."
    git config --global user.email "$email"
    echo "done."
    echo ""
fi


if [ $isName -eq 0 ]; then
    echo "Git does not know your name"
    read -p "Please enter your name: " name

    printf "\e[96mrunning: 'git config --global user.name \"$name\"'\e[0m..."
    git config --global user.name "$name"
    echo "done."
    echo ""
fi



cat <<EOF

                          GGGGGGGGGGGGG        CCCCCCCCCCCCC       CCCCCCCCCCCCC
>>>>>>>                GGG::::::::::::G     CCC::::::::::::C    CCC::::::::::::C
 >:::::>             GG:::::::::::::::G   CC:::::::::::::::C  CC:::::::::::::::C
  >:::::>           G:::::GGGGGGGG::::G  C:::::CCCCCCCC::::C C:::::CCCCCCCC::::C
   >:::::>         G:::::G       GGGGGG C:::::C       CCCCCCC:::::C       CCCCCC
    >:::::>       G:::::G              C:::::C             C:::::C
     >:::::>      G:::::G              C:::::C             C:::::C
      >:::::>     G:::::G    GGGGGGGGGGC:::::C             C:::::C
     >:::::>      G:::::G    G::::::::GC:::::C             C:::::C
    >:::::>       G:::::G    GGGGG::::GC:::::C             C:::::C
   >:::::>        G:::::G        G::::GC:::::C             C:::::C
  >:::::>          G:::::G       G::::G C:::::C       CCCCCCC:::::C       CCCCCC
 >:::::>            G:::::GGGGGGGG::::G  C:::::CCCCCCCC::::C C:::::CCCCCCCC::::C
>>>>>>>              GG:::::::::::::::G   CC:::::::::::::::C  CC:::::::::::::::C
                       GGG::::::GGG:::G     CCC::::::::::::C    CCC::::::::::::C
                          GGGGGG   GGGG        CCCCCCCCCCCCC       CCCCCCCCCCCCC


Welcome to the GCC Fall 2019 Relay Programming Competition!

I'm going to ask you some questions before we get started.

EOF

valid=0
while ((valid == 0 )); do
    printf "Has each of your teammates forked \e[35mhttps://github.com/GuelphCodingCommunity/f19-relay\e[0m and added you as a collaborator? [y/n]:"


    read yn
    case $yn in
        y* | Y*)
            valid=1
            ;;
        n* | N*)
            echo 'Please do so before continuing.'
            exit 1
            ;;
    esac
done

valid=0
while (( valid == 0 )); do
    read -p 'What challenge number have you been assigned? [1/2/3]: ' challenge
    if (( challenge < 1 )) || (( challenge > 3)); then
        echo "Enter 1, 2, or 3" >&2
    fi
    valid=1
done;

read -p 'What is your GitHub user name? ' me

other_challenges=(1 2 3)
program_names=("timeline.py" "rle.py" "pathfix.py")
team=()

my_program=${program_names[$((challenge - 1))]}

# Remove myself from the other challenges.
# Array indices will be fixed later, they are useful as is right now.
unset "other_challenges[$((challenge - 1))]"
debug "other_challenges=${other_challenges[@]}"

for i in ${!other_challenges[@]}; do
    read -p "What is the GitHub username of your teammate doing challenge #${other_challenges[i]}? " team[i]
done


if [ "${team[0]}" == "${team[1]}" ]; then
    printf "\e[31mTeam members can not have the same GitHub username\e[0m\n"
    exit 1
fi

if [ "${team[1]}" == "$me" ]; then
    printf "\e[31mTeam members can not have the same GitHub username\e[0m\n"
    exit 1
fi

if [ "${team[0]}" == "$me" ]; then
    printf "\e[31mTeam members can not have the same GitHub username\e[0m\n"
    exit 1
fi


debug "challenge=$challenge"
debug "team=${team[@]}"
debug "me=$me"

echo 'I am about to clone some repositories.'

valid=0
while (( valid == 0 )); do
    echo 'Would you like to clone using SSH or HTTPS?'
    read -p "Pick HTTPS if you don't know what this means. [SSH/HTTPS]: " protocol

    case "$protocol" in
        "ssh" | "SSH")
            protocol="ssh"
            valid=1
            ;;
        "https" | "http" | "HTTPS" | "HTTP")
            protocol="https"
            valid=1
            ;;
        *)
            echo "Unrecognized. Try again." >&2
            ;;
    esac
    debug "protocol=$protocol"
done
echo ''

mkdir -p 'f19-relay'

# Fix the array indices.
other_challenges=("${other_challenges[@]}")
team=("${team[@]}")

# Clone the repositories.
baseurl=''
case "$protocol" in
    "ssh")
        baseurl='git@github.com:'
        ;;
    "https")
        baseurl='https://github.com/'
        ;;
    *)
        echo 'Internal script error. This should not have happened.' >&2
        exit 1
        ;;
esac

echo 'Cloning team mate repositories...'
git clone "$baseurl$me/f19-relay.git" "f19-relay/challenge_$challenge"
debug git clone "$baseurl$me/f19-relay.git" "f19-relay/challenge_$challenge"

git clone "$baseurl${team[0]}/f19-relay.git" "f19-relay/challenge_${other_challenges[0]}"
debug git clone "$baseurl${team[0]}/f19-relay.git" "f19-relay/challenge_${other_challenges[0]}"

git clone "$baseurl${team[1]}/f19-relay.git" "f19-relay/challenge_${other_challenges[1]}"
debug git clone "$baseurl${team[1]}/f19-relay.git" "f19-relay/challenge_${other_challenges[1]}"

echo 'Cloned.'
echo ''

echo 'removing non challenge files'
rm "f19-relay/challenge_$challenge/setup.sh"
rm "f19-relay/challenge_$challenge/challenge_0${other_challenges[0]}.pdf"
rm "f19-relay/challenge_$challenge/challenge_0${other_challenges[1]}.pdf"

echo "Bootstrapping your project for challenge $challenge..."
dir=$PWD
cd "f19-relay/challenge_$challenge"

cat <<EOF > $my_program
#!/usr/bin/env python3

import sys

def main(args):
    print("Hello world!")

    return 0

if __name__ == "__main__":
    main(sys.argv)

EOF

chmod +x $my_program

cd $dir

# check that all 3 challenges were cloned successfully
num=$(ls f19-relay | wc -l)
if [ $num -ne "3" ]; then

    printf "\e[1;31mERROR: Not all the challenges were downloaded \e[0m\n"
    printf "\e[1;93mPlease check that all the repositories have been cloned and that you entered the user names correctly\e[0m\n"

    echo "Challenge $challenge: $me"
    echo "Challenge ${other_challenges[0]}: ${team[0]}"
    echo "Challenge ${other_challenges[1]}: ${team[1]}"

    echo ""
else

    printf "\e[92mBootstrapped!\e[0m\n"
    printf "\e[1;93mPlease wait for further instruction!\e[0m\n"
    echo ""
    printf "\e[34mRun 'cd f19-relay/challenge_$challenge' to go to the challenge folder\e[0m\n"

    echo ""
    echo "When it's time, open $my_program and start coding!"
    echo ""
fi
