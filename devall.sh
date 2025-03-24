tmux new -s brDev -d

# 2x2 grid
tmux split-window -h
tmux split-window -v
tmux select-pane -t 0
tmux split-window -v

tmux send-keys -t 0 'podman-compose -f containers/development.yaml up' C-m
tmux send-keys -t 1 '(cd page && npm run dev)' C-m
tmux send-keys -t 2 'nimble run -d:powNumberAlwaysZero brApi' C-m
tmux send-keys -t 3 'nimble run brPage'

tmux attach -t brDev
