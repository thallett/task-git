#!/bin/bash

LOGFILE=/dev/null

# Get task command
TASK_COMMAND="task ${@}"

# Get data dir
DATA_RC=$(task _show | grep data.location)
DATA=(${DATA_RC//=/ })
DATA_DIR=${DATA[1]}

# Need to expand home dir ~
eval DATA_DIR=$DATA_DIR

# Exit if we don't have a tasks data directory
if [ ! -e "$DATA_DIR" ]; then
    echo "Could not load data directory $DATA_DIR."
    exit 1
fi

# Check if git repo exists
if ! [ -d "$DATA_DIR/.git" ]; then
    echo "Initializing git repo"
    pushd $DATA_DIR
    git init
    git add *
    git commit -m "Initial Commit"
    popd
fi

# Push by default
PUSH=1
PULL=0

# Check if --no-push is passed as an argument.
for i in $@
do
    if [ "$i" == "--no-push" ]; then
        # Set the PUSH flag, and remove this from the arguments list.
        PUSH=0
        shift
    fi
done

# Check if we are passing something that doesn't do any modifications
for i in $1
do
    case $i in
        add|append|completed|delete|done|due|duplicate|edit|end|modify|prepend|rm|start|stop)
            echo "Push"
            ;;
        push)
            echo "Push"
            ;;
        pull)
            echo "Pull"
            PULL=1
            ;;
        *)
            PUSH=0
            ;;
    esac
done

# Check if we are passing a command for the second arg (filter for the first)
if [ $PUSH -eq 0 ]
then
    for i in $2
    do
        case $i in
            add|append|completed|delete|done|due|duplicate|edit|end|modify|prepend|rm|start|stop)
                PUSH=1
                echo "Push"
                ;;
            *)
                ;;
        esac
    done
fi



pushd $DATA_DIR > $LOGFILE
# Check if we have a place to push to
GIT_REMOTE=$(git remote -v | grep push | grep origin | awk '{print $2}')
if [ -z $GIT_REMOTE ]; then
    # No place to push to
    PUSH=0
fi


if [ "$PULL" == 1 ]; then
    echo "Fetching & Applying updates from $GIT_REMOTE"
    git fetch && git pull
    exit 0
fi

# Add to git
git add .  > $LOGFILE
git commit -m "$TASK_COMMAND" > $LOGFILE

# Push
if [ "$PUSH" == 1 ]; then
    echo "Pushing updates to $GIT_REMOTE"
    git push origin master > $LOGFILE
fi

# Call task
/usr/bin/task $@

popd > $LOGFILE

exit 0
