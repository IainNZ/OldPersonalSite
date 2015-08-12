infp = open(ARGS[1],"r")
outfp = open(ARGS[1]*".dedent","w")

for line in readlines(infp)
    if length(line) >= 4
        if line[1:4] == "    "
            print(outfp, line[5:end])
        else
            print(outfp, line)
        end
    else
        print(outfp, line)
    end
end

close(infp)
close(outfp)