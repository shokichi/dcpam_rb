#!/usr/bin/env ruby
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


# DCL
clrmp = 14  # カラーマップ
DCL.sgscmn(clrmp)
DCL::swlset('lwnd',false)
#DCL.swpset('lalt',true) if save == false
DCL.gropn(4)
DCL.sgpset('lcntl',false)
#DCL.sgpset('lfull',true)
DCL.uzfact(0.7)
#DCL::gllset('LMISS', true)
#DCL::glrget('RMISS')
#rmiss = DCL.glpget('rmiss')

# GGraph
draw(gp,"min"=>0,"max"=>2000,"nlev"=>40)
DCL.grcls
print "dcl files created\n"


# make movie
Dir::mkdir("movie") if !Dir::entries("./").include?("movie")
dt = 17.6
`mv dcl_*.png movie/`
`mogrify -format gif movie/*.png`
`convert -delay #{dt} movie/dcl_*.gif movie/#{File.basename(filename).sub(".nc")}.gif`
`rm movie/dcl_*.gif`
  

