#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# make standerd figure 
# 子午面断面
#

require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
include Utiles_spe
include NumRu

def merid_fig(var_name,dir,name,hash)
  for n in 0..dir.length-1
    begin
      gp = GPhys::IO.open(Utiles_spe.str_add(dir[n],var_name)+'.nc',var_name)
    rescue
      print "[#{var_name}](#{dir[n]}) is not exist\n"
      next
    end
    if gp.rank == 4 
      gp = gp.mean(0,-1)
    elsif gp.rank == 3
      gp = gp.mean(0)
    end
    fig_opt = {'color_bar'=>true,'title'=>gp.long_name + " " + name[n],'annotate'=>false,'nlev'=>20}
    GGraph.tone_and_contour(gp, true,fig_opt.merge(hash))
  end
end

def merid_fig_strm(dir,name)
  var_name = "Strm"
  for n in 0..dir.length-1
    begin
#      gp = GPhys::IO.open(dir[n].sub("local_","") + var_name + '.nc',var_name)
      gp = GPhys::IO.open(dir[n] + var_name + '.nc',var_name)
    rescue
      print "[#{var_name}](#{dir[n]}) is not exist\n"
      next
    end
    if gp.rank != 2 then
      gp = gp.mean(0,-1)
    end
    GGraph.next_linear_tone_options("min"=>-50,'max'=>50,'interval'=>5)
    GGraph.tone(gp*1e-10,true,'title'=>gp.long_name + " " + name[n],'annotate'=>false,"nlev"=>2)
    GGraph.contour(gp,false,'interval'=>4*1e+10)
  end
end

# 
list=ARGV[0]
dir, name = Utiles_spe.explist(list)
if list != nil then
  id_exp = list.split("/")[-1].sub(".list","")
end

# DCL open
if ARGV.index("-ps")
  iws = 2
elsif ARGV.index("-png")
  DCL::swlset('lwnd',false)
  iws = 4
else
  iws = 1
end

# DCL set
clrmp = 14  # カラーマップ
DCL.sgscmn(clrmp)
DCL.gropn(iws)
# DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(0.9) # 文字の大きさ
  
GGraph.set_axes("xlabelint"=>30,'xside'=>'bt', 'yside'=>'lr')
GGraph.set_fig('window'=>[-90,90,nil,nil])


merid_fig('Temp',dir,name,"min"=>120,"max"=>320,"interval"=>10)
merid_fig('U',dir,name,"min"=>-80,"max"=>80,"interval"=>5)
merid_fig('V',dir,name,"min"=>-8,"max"=>8)
merid_fig('RH',dir,name,"min"=>0,"max"=>100)
merid_fig('SigDot',dir,name,"min"=>-1.5e-6,"max"=>1.5e-6)
merid_fig('QVap',dir,name,"min"=>0,"max"=>0.015)
merid_fig_strm(dir,name)


DCL.grcls

if ARGV.index("-ps") 
  system("mv dcl.ps #{id_exp}_merid.ps")
elsif ARGV.index("-png")
  system("rename 's/dcl_/#{id_exp}_merid_/' dcl_*.png")
end
