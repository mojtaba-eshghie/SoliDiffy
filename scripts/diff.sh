
 output={\"contracts\":{
for filename in ../contracts/mutants/*; do
    split=($(echo $filename | tr "/" "\n"))
    output+=\"${split[3]}\":{
    mutants=()
    for mutant in $filename/*; do
        if [ "$mutant" = $filename/original ]; then
            original=$mutant/*
        else
            mutants+=" "$mutant/*
        fi
    done
    for m in $mutants; do
        split=($(echo $m | tr "/" "\n"))
        output+=\"${split[4]}\":
        diff_res=$(diff $original $m)
        count=0
        while IFS= read -r line ; do 
            re=^\< #re=^\>
            if [[ $line =~ $re ]]; then
                count=$(expr ${#line} + $count - 2)
            fi
        done <<< "$diff_res"
        output+=$count,
    done
    output+=},
done
output+=}}
echo $output >> diff_res.json