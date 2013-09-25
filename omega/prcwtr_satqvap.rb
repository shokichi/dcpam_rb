#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 可降水量と
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/utiles_omega.rb")
require 'optparse'
include Utiles_spe
include NumRu
include Math

opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("--ps") { IWS = 2}
opt.on("--png") { 
  DCL::swlset('lwnd',false)
  IWS = 4
}

ES0 = UNumeric[611,"Pa"]

def get_prcwtr(dir)
  var_name = "PrcWtr"
  prc = gpopen list.dir+var_name+".nc", var_name
  prc = cut_and_mean(prc)
  return prc
end

def get_satQVap(dir)
  temp = gpopen list.dir + "Temp.nc"
  temp = cut_and_mean(temp)
  # 飽和水蒸気圧の計算
  satqvap = 
    ES0 * ( LatentHeat / (GasRUniv/MolWtWet) * ( 1/273.0 - 1/temp ) ).exp
  return satqvap
end

def cut_and_mean(gp)
  return gp
end

def create_clm(list,prc,qvap)
  fin = File.open(list.id.sub(".list","_clm.dat","w") )
  fin.print "# "
  fin.print "legend\t"
  fin.print "PrcWtr\t"
  fin.print "Es\n"
  list.name.each_index{ |n|
    fin.print "#{list.name[n]}\t"
    fin.print "#{glmean(prc[n])}\t"
    fin.print "#{glmean(qvap[n])}\n"
  }
end

def draw_scatter(list,prc,qvap,hash={})
  list.dir.each_index{ |n| 
    if n == 0 then
      GGraph.scatter glmean(prc[n]),glmean(qvap[n]),true,hash
    else
      GGraph.scatter glmean(prc[n]),glmean(qvap[n]),false,hash
    end
  }
end

prc = []
qvap = []
list = Explist.new(ARGV[0])
list.dir.each{ |dir| 
  prc << get_prcwtr(dir)
  qvap << get_satQVap(dir)
}
#draw_scatter(list,prc,qvap)
create_clm(list,prc,qvap)
