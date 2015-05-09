---
author: idunning
date: 2014-09-05 12:00:00+00:00
layout: post
category: julia
title: MetadataTools.jl
---

This is my first attempt at turning an [IJulia Notebook](https://github.com/JuliaLang/IJulia.jl) into a blog post. I gave a lightning talk at the [Cambridge Area Julia Users Group (CAJUN)](http://www.meetup.com/julia-cajun/) on Sept. 4th 2014 about some fun things you can do with [MetadataTools.jl](https://github.com/IainNZ/MetadataTools.jl) and used the following notebook as my "slides". Here is that notebook, converted to Markdown for my site. It works fairly well, although I've had to a little bit of manual editing to make it look correct.


## MetadataTools.jl Demo

    using MetadataTools

### Getting information about packages

`MetadataTools` defines a `PkgMeta` type that represents a package's METADATA entry, and contains a `PkgMetaVersion` for each tagged version.

    pkgs = get_all_pkg()  # Returns a Dict{String,PkgMeta}
    pkgs["DataArrays"]

Output:

    DataArrays   git://github.com/JuliaStats/DataArrays.jl.git
      0.0.0,a6ce00,julia 0.2-,StatsBase 0.2.5 0.3-,SortingAlgorithms
      0.0.1,0001ff,julia 0.2-,StatsBase 0.2.5 0.3-,SortingAlgorithms
      0.0.2,7a61d2,julia 0.2-,StatsBase 0.2.5 0.3-,SortingAlgorithms
      0.0.3,613ca1,julia 0.2- 0.3-,StatsBase 0.3.8-
      0.1.0,ae7d82,julia 0.3-,StatsBase 0.3-,SortingAlgorithms
      0.1.1,3fe861,julia 0.3-,StatsBase 0.3
      0.1.2,d0a0b3,julia 0.3-,StatsBase 0.3
      0.1.3,d9ad97,julia 0.3-,StatsBase 0.3
      0.1.4,4742f2,julia 0.3.0-prerelease+1942,StatsBase 0.3
      0.1.5,833e53,julia 0.3.0-,StatsBase 0.3
      0.1.6,4be6c8,julia 0.3.0-,StatsBase 0.3
      0.1.7,fc8a8a,julia 0.3.0-,StatsBase 0.3
      0.1.8,511e2c,julia 0.3.0-,StatsBase 0.3
      0.1.9,9c281b,julia 0.3.0-,StatsBase 0.3
      0.1.10,440fb0,julia 0.3.0-,StatsBase 0.3
      0.1.11,623147,julia 0.3.0-,StatsBase 0.3
      0.1.12,e0e4a7,julia 0.3.0-,StatsBase 0.3
      0.2.0,d78a6d,julia 0.3.0-,StatsBase 0.3

We can check that maximum supported Julia version using `get_upper_limit` - useful for checking if a package is deprecated.

Input:

    get_upper_limit(get_pkg("Monads"))

Output:

    v"0.3.0"

Input:

    get_upper_limit(get_pkg("DataFrames"))

Output:

    v"0.0.0"

We can also request information about a package from GitHub (or wherever it is hosted - only GitHub needed right now!)


    gadfly_info = get_pkg_info(get_pkg("Gadfly"))
    Base.isless(a::MetadataTools.Contributor,b::MetadataTools.Contributor) =
        isless(a.username,b.username)
    sort(gadfly_info.contributors, rev=true)[1:10]

Output:

    10-element Array{(Int64,Contributor),1}:
     (428,Contributor("dcjones","https://github.com/dcjones"))        
     (8,Contributor("dchudz","https://github.com/dchudz"))            
     (7,Contributor("darwindarak","https://github.com/darwindarak"))  
     (6,Contributor("timholy","https://github.com/timholy"))          
     (5,Contributor("kleinschmidt","https://github.com/kleinschmidt"))
     (5,Contributor("aviks","https://github.com/aviks"))              
     (5,Contributor("Keno","https://github.com/Keno"))                
     (4,Contributor("jverzani","https://github.com/jverzani"))        
     (4,Contributor("inq","https://github.com/inq"))                  
     (4,Contributor("IainNZ","https://github.com/IainNZ"))            


I pulled all the data about a week ago and serialized it for later use.

    f = open("metadata.jldata","r")
    pkg_info = deserialize(f)
    close(f)
    pkg_info["Dates"]

Output:

    PkgInfo("https://github.com/quinnj/Dates.jl","Date/DateTime Implementation for the Julia Language; Successor to Datetime.jl","",5,2,[(2,Contributor("jiahao","https://github.com/jiahao")),(131,Contributor("quinnj","https://github.com/quinnj"))])

Input:

    # Calculate commits stats
    total_coms = Dict()
    total_pkgs = Dict()
    
    for pkg in values(pkg_info)
        for contrib in pkg.contributors
            commits, c = contrib
            total_coms[c.username] = get(total_coms,c.username,0) + commits
            total_pkgs[c.username] = get(total_pkgs,c.username,0) + 1
        end
    end
    
    # Turn dicts into sorted (num,username) vectors
    total_pkgs = sort([(total_pkgs[n],n) for n in keys(total_pkgs)],rev=true)
    total_coms = sort([(total_coms[n],n) for n in keys(total_coms)],rev=true)
    
    println("Number of packages contributed to")
    map(println, total_pkgs[1:20])
    
    println("Number of commits across all packages")
    map(println, total_coms[1:20]);

Output:

    Number of packages contributed to
    (51,"timholy")
    (45,"johnmyleswhite")
    (40,"kmsquire")
    (37,"StefanKarpinski")
    (35,"Keno")
    (34,"lindahua")
    (30,"simonster")
    (29,"IainNZ")
    (25,"mlubin")
    (24,"staticfloat")
    (24,"aviks")
    (21,"vtjnash")
    (20,"stevengj")
    (20,"ihnorton")
    (18,"quinnj")
    (17,"tanmaykm")
    (17,"dcjones")
    (17,"carlobaldassi")
    (16,"tkelman")
    (16,"powerdistribution")

    Number of commits across all packages
    (1734,"lindahua")
    (1427,"jakebolewski")
    (1178,"timholy")
    (893,"johnmyleswhite")
    (821,"dcjones")
    (788,"simonster")
    (749,"mlubin")
    (678,"milktrader")
    (462,"stevengj")
    (435,"dmbates")
    (415,"nolta")
    (402,"one-more-minute")
    (398,"quinnj")
    (397,"IainNZ")
    (372,"joehuchette")
    (353,"powerdistribution")
    (350,"WestleyArgentum")
    (340,"Keno")
    (336,"scidom")
    (330,"tanmaykm")


### Package Ecosystem

`MetadataTools` has a dependency on `Graphs` to enable an analysis of how
packages rely on each other.


    using Graphs
    # Get a directed graph where PkgA -> PkgB iff 
    # PkgA directly requires PkgB
    g = get_pkgs_dep_graph(get_all_pkg())

Output:

    Directed Graph (418 vertices, 496 edges)

Input:

    g_gadfly = get_pkg_dep_graph(get_pkg("Gadfly"),g)

Output:

    Directed Graph (24 vertices, 36 edges)


To plot the dependency graph for a package, we can use my GraphLayout.jl package which uses Compose.jl internally for drawing. I haven't got around to adding Graphs.jl support to GraphLayout.jl just yet though...

    using GraphLayout
    for pkg_name in ["Gadfly","QuantEcon","JuMP","Twitter"]
        # Extract graph
        g_pkg = get_pkg_dep_graph(get_pkg(pkg_name),g)
        # Extract adjacency matrix
        adj_mat = adjacency_matrix(g_pkg)
        # Build layout
        locs_x,locs_y = layout_spring_adj(adj_mat)
        # Extract name for each vertex
        vert_names = map(pm->pm.name, vertices(g_pkg))
        # Draw as an SVG
        draw_layout_adj(adj_mat, locs_x, locs_y, labels=vert_names)
    end

{% img /images/metadatatools_16_0.svg %}

{% img /images/metadatatools_16_1.svg %}

{% img /images/metadatatools_16_2.svg %}

{% img /images/metadatatools_16_3.svg %}

We can also look at which packages depend on the most packages


    num_pkg_req = [
        (num_vertices(get_pkg_dep_graph(pkg, g)), pkg.name)
            for pkg in values(pkgs)]
    sort!(num_pkg_req, rev=true)  # Sort descending
    println("Top 10 packages by number of packages depended on:")
    for i in 1:10
        println(rpad(num_pkg_req[i][2],20," "), num_pkg_req[i][1]-1)
    end

Output:

    Top 10 packages by number of packages depended on:
    RobustStats         30
    MachineLearning     30
    Quandl              26
    Twitter             25
    Lumira              24
    Gadfly              23
    QuantEcon           22
    ProfileView         22
    ImageView           21
    Etcd                21


We can also reverse the graph - now an arc from PkgA to PkgB means PkgB requires PkgA

    g_rev = get_pkgs_dep_graph(pkgs, reverse=true)
    # Count size of every subgraphs like above
    num_pkg_req = [
        (num_vertices(get_pkg_dep_graph(pkg, g_rev)), pkg.name)
            for pkg in values(pkgs)]
    sort!(num_pkg_req, rev=true)  # Sort descending
    println("Top 10 packages by number of packages that depend on them:")
    for i in 1:10
        println(rpad(num_pkg_req[i][2],20," "), num_pkg_req[i][1]-1)
    end

Output:

    Top 10 packages by number of packages that depend on them:
    URIParser           89
    SHA                 88
    BinDeps             87
    ArrayViews          76
    JSON                71
    StatsBase           66
    Homebrew            58
    Zlib                49
    URLParse            40
    Reexport            40

