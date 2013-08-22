#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 動画作成
# make animation
#

require 'numru/ggraph'
require 'numru/gphys'
include NumRu
include Math


def draw(gp,figopt={})
  intval = 5
  for n in 0..gp.axis("time").length/intval-1 
    figopt["keep"] = true if n != 0
    GGraph.tone gp[false,n*intval], true, figopt
  end
end

# file open
file = ARGV[0]

if file.include?(",")
  file = file.split(",")[0]
  data = file.split(",")[1]
else 
  data = file.gsub(".nc","")
  data = data.split("/")[-1] if data.include?("/")
end

gp = GPhys::IO.open(file,data)

if ARGV.index("--save") 
  save = true
else
  save = false
end

# DCL
clrmp = 14  # カラーマップ
DCL.sgscmn(clrmp)
DCL::swlset('lwnd',false) if save == true
DCL.swpset('lalt',true) if save == false
DCL.gropn(4)
DCL.sgpset('lcntl',false)
#DCL.sgpset('lfull',true)
DCL.uzfact(0.7)
#DCL::gllset('LMISS', true)
#DCL::glrget('RMISS')
#rmiss = DCL.glpget('rmiss')

# GGraph
draw(gp,"min"=>0,"max"=>2000,"nlev"=>40)
p "dcl files created\n"
DCL.grcls

if save then
  # make movie
  Dir::mkdir("movie") if !Dir::entries("./").include?("movie")
  dt = 8.8
  `mv dc_*.png movie/`
  `mogrify -format gif *.png`
  `convert -delay #{dt} dcl_*.gif output.gif`
  `rm dcl_*.gif`
end  

