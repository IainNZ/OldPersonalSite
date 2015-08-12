infp = open(ARGS[1],"r")
outfp = open(ARGS[1]*".dedent","w")

for line in readlines(infp)
    if length(line) >= 4
        if line[1:4] == "    "
            print(outfp, line[5:end])
        elseif line[1:4] == "![pn"
            print(outfp,
                replace(line,
                    "JuliaIssueCount_files",
                    "/images/JuliaIssueCount"))
        else
            print(outfp, line)
        end
    else
        print(outfp, line)
    end
end

close(infp)
close(outfp)