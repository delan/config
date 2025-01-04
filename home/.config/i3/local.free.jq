def split:
    def f:
        input as $x
        | if [$x | length, $x[0] | length] == [1, 2]
            then . + [$x]
            else . + [$x] | f
            end

    ; [.] | f as $x
    | 1 | [truncate_stream($x[])]
    | fromstream(.[])

; split
