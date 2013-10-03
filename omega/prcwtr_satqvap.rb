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


def get_prcwtr(dir)
  var_name = "PrcWtr"
  prc = gpopen list.dir+var_name+".nc", var_name
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

def draw_scatter(lists,data,hash={})
  lists.each_index{ |n| 
    if n == 0 then
      GGraph.scatter data.axis(0).to_gphys,data,true,hash
    else
      GGraph.scatter data.axis(0).to_gphys,data,false,hash
    end
  }
end

def set_data(list)
  prc = []
  qvap = []
  list.dir.each{ |dir| 
    prc << get_prcwtr(dir)
    qvap << get_satQVap(dir)
  }
  return ary2gp(prc,qvap)
end

a_list = "/home/ishioka/link/all/fig/list/omega_all_MTlocal.list"
d_list = "/home/ishioka/link/diurnal/fig/list/omega_diurnal_MTlocal.list"
c_list = "/home/ishioka/link/coriolis/fig/list/omega_coriolis_MTlocal.list"
lists={
  :all=>Utiles_spe::Explist.new(a_list),
  :diurnal=>Utiles_spe::Explist.new(d_list),
  :coriolis=>Utiles_spe::Explist.new(c_list)
}

data = []
data <<  set_data(lists[:all])
data <<  set_data(lists[:diurnal])
data <<  set_data(lists[:coriolis])
draw_scatter(lists,data,)
#create_clm(list,prc,qvap)
