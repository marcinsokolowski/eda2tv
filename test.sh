pipe=merged_hdf5_list.txt

while :; do
    while read -r cmd; do
        if [ "$cmd" ]; then
            printf 'Running %s ...\n' "$cmd"
        fi
    done <"$pipe"
done