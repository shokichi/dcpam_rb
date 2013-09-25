#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# histogram
# ヒストグラムの作成 
#

require 'numru/ggraph'
require 'numru/gphys'
require 'numru/ganalysis'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
require 'narray'
include Utiles_spe
include NumRu
include Math

def hist_fig(data_name,min,max,nbins,dir,name)
  for n in 0..dir.length-1
    begin
      gp = GPhys::IO.open(dir[n] + data_name + ".nc",data_name)
    rescue
      print "[#{data_name}](#{dir[n]}) is not exist\n"
      next
    end
    if data_name[0..3]=="Rain" then
      if gp.units.to_s != "mm.h-1" then
        # 降水量の単位変換
      end
    end
    gh = histogram_div(gp.cut("sig"=>1),min,max,nbins)
    if n == 0 
      lc = 13
      vx = 0.82
      vy = 0.8
      GGraph.line(gh, true, "title"=>gp.long_name + " " + name[n],'index'=>lc,'legend'=>false,'annotate'=>false)
      DCL.sgtxzv(vx+0.05,vy,name[n],0.015,0,-1,3)
      DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc)
    else
      lc = lc + 10
      vy = vy - 0.025
      GGraph.line(gh, false,'index'=>lc)
      DCL.sgtxzv(vx+0.05,vy,name[n],0.015,0,-1,3)
      DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc)
    end
  end
end

def histogram_div(gphys,min,max,nbins)
  ntime = gphys.coord('time').length
  range={'min'=>min, 'max'=>max, 'nbins'=>nbins}
  gh = 0

  GPhys.each_along_dims(gphys,"time") do |gp|
    gh = gh + gp.histogram(range)
  end

  gh = gh/gphys.total
  return gh
end

def histogram_div_rain(gphys,min,max,nbins)
  ntime = gphys.coord('time').length
  range={'min'=>min, 'max'=>max, 'nbins'=>nbins}
  gh = 0

  GPhys.each_along_dims(gphys,"time"){|gp|
    gh = gh + gp.histogram(range)
  }

  gh = gh/gphys.total
  return gh
end

# 
list=ARGV[0]
dir, name = Utiles_spe.explist(list)
if list != nil then
  id_exp = list.split("/")[-1].sub(".list","")
end


if ARGV.index("-ps")
  DCL.gropn(2)
elsif ARGV.index("-png")
  DCL::swlset('lwnd',false)
  DCL.gropn(4)
else
  DCL.gropn(1)
end
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(0.9)

make_hist_fig("RH",0,120,120,dir,name)

DCL.grcls

if ARGV.index("-ps") 
  system("mv dcl.ps #{id_exp}_hist.ps")
elsif ARGV.index("-png")
  system("rename 's/dcl_/#{id_exp}_hist_/' dcl_*.png")
end
