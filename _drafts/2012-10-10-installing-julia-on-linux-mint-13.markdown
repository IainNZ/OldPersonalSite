---
author: idunning
date: 2012-10-10 02:30:07+00:00
layout: post
title: Installing Julia on Linux Mint 13
---

**Update in 2013**: [Julia 0.2](http://julialang.org/downloads/) works quite well on Windows - I'd recommend using that directly. If you are on Linux Mint 13, you can download the binaries for the nightly build by adding the package information - its all on the download page.

I recently decided to check out [Julia](http://julialang.org/), a new "high-level, high-performance dynamic programming language for technical computing", but it wasn't really Windows-friendly yet. No problem! Here is a quick guide to getting started on Windows by using a virtual machine:

  1. Install [VirtualBox](https://www.virtualbox.org/) - VirtualBox lets you create "virtual machines", or in other words, a "operating system - in - a - operating system".

  2. Get a copy of Linux - I like [Mint](http://linuxmint.com/) because it is pretty simple but functional. I am using Linux Mint 13, 32-bit MATE edition.
	
  3. Create a new virtual machine in VirtualBox, use the Ubuntu default, most of the default settings are fine (maybe give it more RAM if you can).
	
  4. Start the VM - it'll prompt you to point it towards a CD image, so just browse to the ISO file you downloaded in Step 2.
	
  5. Install Mint by following the prompts, and restart.
	
  6. Download the Julia source code from [GitHub](https://github.com/JuliaLang/julia). The best way to do this is to open a Terminal window and enter the following commands:

    * mkdir Development
    * git clone git://github.com/JuliaLang/julia.git
	
  7. This will install the source to a folder ~/Development/julia
	
  8. You need to install some dependent files, which you can do with the Software Manager (click in bottom left on the cog in Mint). Install the following packages:
	
    * build-essentials
    * gfortran
    * libncurses5-dev
	
  9. Go back to the Terminal window and run the following commands

    * cd julia	
    * make
	
  10. This will take a while. When its done, try out Julia by typing ./julia to start Julia in interactive mode.

Hopefully this helps. The confusing/annoying bit for me really was the packages - it hits the lack of g++ quickly, and gfortran a bit later, but doesn't hit libncurses5-dev until the end.
