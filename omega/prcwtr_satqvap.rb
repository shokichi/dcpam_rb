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



def get_prcwtr(dir)
  var_name = "PrcWtr"
  prc = gpopen dir+var_name+".nc", var_name
  prc = cut_and_mean(prc)
  return prc
end

def get_satQVap(dir)
  satqvap = gpopen dir + "Es.nc"
  satqvap = cut_and_mean(satqvap)
  return satqvap
end

def cut_and_mean(gp)
  gp = glmean(gp)
  return gp
end

def set_data(list)
  prc = []
  qvap = []
  list.dir.each{ |dir| 
    prc << get_prcwtr(dir)
    qvap << get_satQVap(dir)
  }
  return Utiles_spe.array2gp(prc,qvap)
end

def draw_scatter(lists,data,hash={})
  lists.length.times{ |n| 
    if n == 0 then
      GGraph.scatter data[n].axis(0).to_gphys,data[n],true,hash
    else
      GGraph.scatter data[n].axis(0).to_gphys,data[n],false,hash
    end
  }
end

def create_clm(lists,data)
  lists.each_value{ |list|
    fin = File.open(list.id.sub(".list","_clm.dat","w") )
    fin.print "# "
    fin.print "legend\t"
    fin.print "PrcWtr\t"
    fin.print "Es\n"
    list.name.each_index{ |n|
      fin.print "#{list.name[n]}\t"
      fin.print "#{data[n].axis(0).to_gphys.val.to_f}\t"
      fin.print "#{data[n].val.to_f}\n"
    }
    fin.close
  }
end

a_list = "/home/ishioka/link/all/fig/list/omega_all_MTlocal.list"
d_list = "/home/ishioka/link/diurnal/fig/list/omega_diurnal_MTlocal.list"
c_list = "/home/ishioka/link/coriolis/fig/list/omega_coriolis_MTlocal.list"
lists={
  :all=>Utiles_spe::Explist.new(a_list),
  :diurnal=>Utiles_spe::Explist.new(d_list),
  :coriolis=>Utiles_spe::Explist.new(c_list)
}

opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("--ps") { IWS = 2}
opt.on("--png") { 
  DCL::swlset('lwnd',false)
  IWS = 4
}
opt.parse!(ARGV)


data = []
data << set_data(lists[:all])
data << set_data(lists[:diurnal])
data << set_data(lists[:coriolis])

create_clm(lists,data)
=begin
# DCL set
IWS = 1 if !defined?(IWS)
clrmp = 14  # カラーマップ
DCL.sgscmn(clrmp)
DCL.gropn(IWS)
# DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(0.8) # 文字の大きさ

GGraph.set_fig('window'=>[0,1000,0,1000])
draw_scatter(lists,data)
DCL.grcls
rename_img_file("omega",__FILE__)
=end
